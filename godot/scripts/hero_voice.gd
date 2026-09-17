extends Node
var game: Node
var player: AudioStreamPlayer
var definitions: Dictionary={}
var pending: Array=[]
var milestones: Dictionary={}
var played: Dictionary={}
var spoken_waves: Dictionary={}
var scheduled_wave=""
var was_knocked_down=false
func wave_key() -> String:
	return "%d:%d"%[game.current_episode,game.wave]
func encounter_key() -> String:
	return "%d:%s"%[game.current_episode,"boss" if game.wave>=13 else str(game.screen_for_wave(game.wave))]
func new_run():
	reset()
	milestones.clear()
	played.clear()
	spoken_waves.clear()
	cooldowns.clear()
	scheduled_wave=""
func schedule_wave():
	if game.phase!="playing" or game.hero.hp<=0:return
	var key=wave_key()
	if key==scheduled_wave:return
	scheduled_wave=key
	pending.clear()
	# Never carry a spoken quip into the next encounter.
	if player.playing:player.stop();active=""
	if game.wave>=13:return
	if (game.wave-1)%3==0 and randf()<.65:request_line("nice_place",randf_range(2.,4.),6.)
	if (game.wave-1)%3 in [1,2] and randf()<.65:request_line("waves_coming",randf_range(1.5,3.5),5.)
	var random_lines=["goat_search","goat_home"].filter(func(id):return not played.has(id))
	if not random_lines.is_empty() and randf()<.45:request_line(random_lines.pick_random(),randf_range(8.,22.),6.)
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
	player.bus=&"Voice"
	player.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
	add_child(player)
func request_line(id: String,delay: float=0.,expires: float=5.):
	if game.muted or not game.voice_enabled:return
	if not definitions.has(id) or id==active or cooldowns.get(id,0.)>time:return
	if not definitions[id].get("menu",false) and (played.has(id) or spoken_waves.has(encounter_key())):return
	for item in pending:
		if item.id==id:return
	pending.append({"id":id,"due":time+delay,"expires":time+delay+expires,"wave":wave_key()})
	pending.sort_custom(func(a,b):return definitions[a.id].priority>definitions[b.id].priority)
func request_once(id: String):
	if played.has(id):return
	request_line(id,.25,10.)
func observe_milestones():
	if game.phase!="playing" or game.hero.hp<=0:return
	var knocked_down=not game.hero.down.is_empty()
	if was_knocked_down and not knocked_down:request_once("knocked_aside")
	was_knocked_down=knocked_down
	if game.magic>=100:request_once("mana_full")
	if game.hero.hp<=25:request_once("low_health")
	for enemy in game.enemies:
		if enemy.hp>0 and enemy.x>=0 and enemy.x<=1440:
			if enemy.boss and enemy.kind in ["champion","king","saint"]:request_once("boss_"+enemy.kind)
			elif game.e_ai.heavy(enemy):request_once("big_enemy")
			elif enemy.get("variant","regular")=="swift":request_once("tiny_enemy")
func reset():
	was_knocked_down=false
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
	if game.phase=="playing" and (game.transition>=0 or game.stage_walk!=""):return
	schedule_wave()
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
	if not menu_context and not game.hero.down.is_empty():return
	for item in pending:
		if item.due>time:continue
		if not definitions[item.id].get("menu",false) and (item.wave!=wave_key() or spoken_waves.has(encounter_key()) or played.has(item.id)):continue
		active=item.id
		player.stream=load(definitions[active].file)
		player.volume_db=-3
		player.play()
		if not definitions[active].get("menu",false):
			played[active]=true
			milestones[active]=true
			spoken_waves[encounter_key()]=true
		cooldowns[active]=time+definitions[active].cooldown
		pending.erase(item)
		if not definitions[active].get("menu",false):pending.clear()
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
