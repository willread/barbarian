extends Node
var game: Node
var player: AudioStreamPlayer
var definitions: Dictionary={}
var pending: Array=[]
var milestones: Dictionary={}
var cooldowns={}
var active=""
var time=0.0
var gap=0.0
var pain=0.0
var previous_hp=100.0
var glance=0
var glance_time=2.0
var atlas=preload("res://art/hero-portrait-v1.png")
func setup(source):
	game=source
	definitions=JSON.parse_string(FileAccess.get_file_as_string("res://voice/lines.json"))
	player=AudioStreamPlayer.new()
	add_child(player)
func request_line(id: String,delay: float=0.,expires: float=5.):
	if game.muted or not game.voice_enabled:return
	if not definitions.has(id) or id==active or cooldowns.get(id,0.)>time:return
	for item in pending:
		if item.id==id:return
	pending.append({"id":id,"due":time+delay,"expires":time+delay+expires})
	pending.sort_custom(func(a,b):return definitions[a.id].priority>definitions[b.id].priority)
func request_once(id: String):
	if milestones.has(id):return
	milestones[id]=true
	request_line(id,.25,10.)
func observe_milestones():
	if game.phase!="playing" or game.hero.hp<=0:return
	if game.magic>=100:request_once("mana_full")
	if milestones.has("big_enemy"):return
	for enemy in game.enemies:
		if enemy.hp>0 and enemy.x>=0 and enemy.x<=1440 and game.e_ai.heavy(enemy):
			request_once("big_enemy")
			break
func reset():
	pending.clear()
	player.stop()
	active=""
	gap=.35
	pain=0
	previous_hp=100
func _process(dt):
	if not game:return
	var paused=game.phase=="paused" or get_tree().paused
	player.stream_paused=paused
	if paused:return
	observe_milestones()
	time+=dt
	gap=max(0.,gap-dt)
	pain=max(0.,pain-dt)
	if game.hero.hp<previous_hp:
		pain=.45
		if player.playing:player.stop();active="";gap=.75
	previous_hp=game.hero.hp
	var menu_context=game.phase=="title"
	pending=pending.filter(func(item):return definitions[item.id].get("menu",false)==menu_context)
	if active!="" and definitions[active].get("menu",false)!=menu_context:player.stop();active=""
	if game.phase not in ["playing","dying","title"] or (game.hero.hp<=0 and not menu_context):
		player.stop();active="";pending.clear();return
	if game.muted or not game.voice_enabled:player.stop();active="";pending.clear();return
	glance_time-=dt
	if glance_time<=0:
		glance=randi_range(1,2) if glance==0 else 0
		glance_time=randf_range(.35,.65) if glance else randf_range(2.,4.)
	if active!="" and not player.playing:active="";gap=.45
	pending=pending.filter(func(item):return item.expires>time)
	# Spoken lines wait for effort/pain/magic vocals to finish; stale quips expire.
	var busy=false
	for voice in game.audio.voices:
		if voice.playing and voice.get_meta("sound_id","") in ["hero_effort","hero_pain","magic_shout"]:busy=true
	if player.playing or gap>0 or pain>0 or busy or not game.audio.unlocked:return
	for item in pending:
		if item.due>time:continue
		active=item.id
		player.stream=load(definitions[active].file)
		player.volume_db=-3
		player.play()
		cooldowns[active]=time+definitions[active].cooldown
		pending.erase(item)
		break
func interrupt():
	if player.playing:player.stop();active="";gap=.75
func draw_portrait(canvas: Node2D,rect: Rect2):
	var row=clampi(int((100.-game.hero.hp)/25.),0,3)
	var column=3 if pain>0 or game.hero.hp<=0 else glance
	if player.playing and active!="" and pain<=0:
		var line=definitions[active]
		var index=clampi(int(player.get_playback_position()*line.fps),0,line.envelope.size()-1)
		var energy=line.envelope[index]
		column=0 if energy<.08 else 4 if energy<.5 else 5
	var cell=atlas.get_size()/Vector2(6,4)
	var crop=Vector2(cell.y*rect.size.x/rect.size.y,cell.y)
	canvas.draw_texture_rect_region(atlas,rect,Rect2(Vector2(column,row)*cell+Vector2((cell.x-crop.x)*.5,0),crop))
