extends Node
signal changed
signal summary_ready(summary: Dictionary)
const ENDPOINT="https://cairn.haqt.com"
const MOVE_NAMES=["normal","charge","spin","slam","throw"]
const FEATURE_NAMES=["controls","intro_watched","intro_skipped","music_player","weapon_menu"]
var save_path="user://statistics.cfg"
var network_enabled=DisplayServer.get_name()!="headless" and not "--script" in OS.get_cmdline_args() and OS.get_cmdline_user_args().is_empty()
var enabled=false
var explicit_choice=false
var policy_resolved=false
var active: Dictionary={}
var pending_features: Dictionary={}
var elapsed=0.0
var score_start=0
var policy_request: HTTPRequest
var submission: HTTPRequest

func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	var config=ConfigFile.new()
	if network_enabled and config.load(save_path)==OK:
		explicit_choice=config.has_section_key("statistics","enabled")
		enabled=bool(config.get_value("statistics","enabled",false))
	policy_resolved=explicit_choice
	policy_request=HTTPRequest.new();policy_request.timeout=5;add_child(policy_request)
	submission=HTTPRequest.new();submission.timeout=3;add_child(submission)
	policy_request.request_completed.connect(policy_completed)
	if network_enabled and not explicit_choice:resolve_policy.call_deferred()

func resolve_policy():
	if not network_enabled or explicit_choice:return
	if policy_request.request(ENDPOINT+"/v1/policy")!=OK:policy_resolved=true;changed.emit()

func policy_completed(result: int,status: int,_headers: PackedStringArray,body: PackedByteArray):
	if explicit_choice or policy_resolved:return
	policy_resolved=true
	var data=JSON.parse_string(body.get_string_from_utf8()) if body.size()<1024 else null
	enabled=result==HTTPRequest.RESULT_SUCCESS and status==200 and data is Dictionary and data.get("default_enabled")==true
	changed.emit()

func lock_default():
	# Never silently switch on after the player has left the title screen.
	if not policy_resolved:
		policy_resolved=true
		policy_request.cancel_request()

func set_enabled(value: bool):
	explicit_choice=true;policy_resolved=true;enabled=value
	policy_request.cancel_request()
	# Toggling either direction starts fresh; never upload pre-choice activity.
	active.clear();pending_features.clear();elapsed=0
	if not enabled:submission.cancel_request()
	if network_enabled:
		var config=ConfigFile.new();config.set_value("statistics","enabled",enabled);config.save(save_path)
	changed.emit()

func begin_attempt(episode: int,level: int,difficulty: String,score: int):
	if not enabled:return
	active={"schema":1,"episode":episode,"level":level,"difficulty":difficulty,"moves":{},"features":pending_features.duplicate()}
	pending_features.clear();elapsed=0;score_start=score

func advance(dt: float):
	if enabled and not active.is_empty():elapsed+=maxf(0,dt)

func move_used(type: String):
	if not enabled or active.is_empty() or type not in MOVE_NAMES:return
	active.moves[type]=mini(10000,active.moves.get(type,0)+1)

func feature_used(type: String):
	if not enabled or type not in FEATURE_NAMES:return
	if active.is_empty():pending_features[type]=true
	else:active.features[type]=true

func finish_attempt(outcome: String,score: int):
	if active.is_empty():return
	var report=active.duplicate(true)
	active.clear()
	if not enabled:return
	report.outcome=outcome
	report.duration=duration_bucket(elapsed)
	report.score=score_bucket(maxi(0,score-score_start))
	summary_ready.emit(report)
	# Best effort, no offline queue, retry loop or install identifier.
	if network_enabled and submission.get_http_client_status()==HTTPClient.STATUS_DISCONNECTED:
		submission.request(ENDPOINT+"/v1/attempt",["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(report))

static func duration_bucket(seconds: float) -> String:
	var limits=[60,180,300,600,1200]
	var labels=["under_1m","1_3m","3_5m","5_10m","10_20m","20m_plus"]
	for i in limits.size():
		if seconds<limits[i]:return labels[i]
	return labels[-1]

static func score_bucket(value: int) -> String:
	var limits=[1000,5000,10000,25000,50000]
	var labels=["0_999","1000_4999","5000_9999","10000_24999","25000_49999","50000_plus"]
	for i in limits.size():
		if value<limits[i]:return labels[i]
	return labels[-1]
