extends Node
const Mix=preload("res://scripts/audio_mix.gd")
const BURN_GAIN_DB=6.0206 # Twice the original amplitude, before shared bus processing.
const CLIP_IDS=["gulp","sword","axe","flesh","heavy_hit","charge_hit","death_fire","bone","shield","resist","body_fall","landing","bow_release","arrow_hit","hero_effort","magic_shout","hero_pain","roar","death","lightning","fire","chicken","chicken_hit","pickup","menu_land","menu_select","transition","music_menu","music_game"]
var game: Node2D
var clips: Dictionary={}
var originals: Dictionary={}
var choices: Dictionary={}
var pools: Dictionary={}
var last_pool_pick: Dictionary={}
var volumes: Dictionary={}
var voices: Array=[]
var tracks: Array=[]
var gates: Dictionary={}
var unlocked=false
var last_spell=-1
var chicken_clock=0.0
var watched: Dictionary={}

func setup(source: Node2D):
	game=source
	Mix.setup()
	unlocked=not OS.has_feature("web") and DisplayServer.get_name()!="headless"
	# Imported audio is listed as .ogg.import in exports. Load resource paths directly.
	for id in CLIP_IDS+["egg_lay"]:
		clips[id]=load("res://audio/"+("slam_boom" if id=="landing" else id)+".ogg")
	clips["menu_activate"]=clips["menu_land"]
	clips["enemy_impact"]=clips["flesh"]
	originals=clips.duplicate()
	pools["enemy_impact"]=[]
	for i in 12:pools.enemy_impact.append("enemy-impact-"+str(i+1))
	var defaults=JSON.parse_string(FileAccess.get_file_as_string("res://audio_defaults.json"))
	for id in defaults.get("choices",{}): set_variant(id,defaults.choices[id],false)
	for id in defaults.get("volumes",{}): set_volume(id,float(defaults.volumes[id]),false)
	for id in defaults.get("pools",{}):pools[id]=defaults.pools[id]
	var saved=ConfigFile.new()
	if saved.load("user://soundboard.cfg")==OK:
		for id in saved.get_section_keys("choices"):
			set_variant(id,saved.get_value("choices",id),false)
	if saved.has_section("pools"):
		for id in saved.get_section_keys("pools"):pools[id]=saved.get_value("pools",id)
	if saved.has_section("volumes"):
		for id in saved.get_section_keys("volumes"):volumes[id]=clampf(float(saved.get_value("volumes",id)), -30,6)
	for i in 16:
		var player=AudioStreamPlayer.new()
		player.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player)
		voices.append(player)
	for id in ["music_menu","music_game"]:
		var player=AudioStreamPlayer.new()
		player.bus=Mix.bus_for(id)
		player.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player)
		if clips.get(id)!=null:
			player.stream=clips[id]
			player.stream.loop=true
		player.volume_db=-60
		tracks.append(player)

func set_variant(id: String,variant: String,persist: bool=true):
	if not originals.has(id):return
	var path="res://audio_options/"+variant+".ogg"
	if not ResourceLoader.exists(path):path="res://audio_options/"+variant+".mp3"
	if variant not in ["original","none"] and not ResourceLoader.exists(path):return
	clips[id]=null if variant=="none" else originals[id] if variant=="original" else load(path)
	choices[id]=variant
	if id in ["music_menu","music_game"] and not tracks.is_empty():
		var track=tracks[0 if id=="music_menu" else 1]
		track.stop()
		track.stream=clips[id]
		if track.stream:track.stream.loop=true
	if persist:save_choices()

func set_pool_variant(id: String,variant: String,enabled: bool):
	if not pools.has(id):pools[id]=[]
	if enabled and variant not in pools[id]:pools[id].append(variant)
	if not enabled:pools[id].erase(variant)
	save_choices()

func pool_clip(id: String):
	var candidates=pools.get(id,[]).duplicate()
	if candidates.is_empty():return null
	if candidates.size()>1:candidates.erase(last_pool_pick.get(id,""))
	var variant=candidates.pick_random()
	last_pool_pick[id]=variant
	return load("res://audio_options/"+variant+".ogg")

func set_volume(id: String,db: float,persist: bool=true):
	volumes[id]=clampf(db,-30,6)
	for voice in voices:
		if voice.get_meta("sound_id","")==id:voice.volume_db=voice.get_meta("base_db",-4)+volumes[id]
	if persist:save_choices()

func save_choices():
	var saved=ConfigFile.new()
	for key in pools:saved.set_value("pools",key,pools[key])
	for key in choices:saved.set_value("choices",key,choices[key])
	for key in volumes:saved.set_value("volumes",key,volumes[key])
	saved.set_value("settings","quiet_foley",true)
	saved.save("user://soundboard.cfg")

func stop_gameplay():
	for voice in voices:voice.stop()
	last_spell=-1
	chicken_clock=0.0

func play(id: String,db: float=-4,pitch: float=1.0):
	if game.get("phase") in ["dying","lost"] and id not in ["menu_select","menu_activate","menu_land","resist","death"]:return
	if game.get("voice_enabled")==false and id in ["hero_effort","hero_pain","magic_shout","roar","death"]:return
	if not unlocked or game.muted or clips.get(id)==null:return
	if game.get("hero_voice") and game.hero_voice.player.playing:
		if id=="hero_effort":return
		if id in ["hero_pain","magic_shout"]:game.hero_voice.interrupt()
	var now=Time.get_ticks_msec()
	if now-gates.get(id,-1000)<65:return
	gates[id]=now
	for voice in voices:
		if not voice.playing:
			voice.stream=pool_clip(id) if pools.has(id) else clips[id]
			# Reuse the selected player shout so death retains the same voice identity.
			if id=="death":voice.stream=clips.get("magic_shout",originals.get("magic_shout"))
			if voice.stream==null:return
			voice.bus=Mix.bus_for(id)
			voice.set_meta("sound_id",id)
			voice.set_meta("base_db",db)
			voice.volume_db=db+volumes.get(id,0.0)
			voice.pitch_scale=pitch*randf_range(.965,1.035)
			voice.play()
			return

func _process(dt: float):
	if not game or game.hero.is_empty():return
	var audible=unlocked and not game.muted and not game.loading_menu
	for i in tracks.size():
		var track=tracks[i]
		var selected=game.music_enabled and ((game.phase=="title")== (i==0))
		var target=-10.0+volumes.get("music_menu" if i==0 else "music_game",0.0) if audible and selected else -60.0
		if game.phase in ["paused","dying","lost","won"]:target-=8
		track.volume_db=move_toward(track.volume_db,target,dt*35)
		if audible and selected and track.stream and not track.playing:track.play()
		if track.volume_db<=-59 and track.playing:track.stop()
	if game.get("voice_enabled")==false:
		for voice in voices:
			if voice.get_meta("sound_id","") in ["hero_effort","hero_pain","magic_shout","roar","death"]:voice.stop()
	if game.muted:
		for voice in voices:voice.stop()
	if game.phase in ["paused","dying","lost"]:return
	var h=game.hero
	if game.spell>=13 and last_spell<13:play("magic_shout",-3,1.0)
	if game.spell>=20 and last_spell<20:play("lightning",-5)
	last_spell=game.spell
	for actor in [h]+game.enemies:
		var key=str(actor.id)
		var state=watched.get(key,{"burn":false,"ground":false,"attack":""})
		var burning=actor.burnAge>0
		var ground=not actor.down.is_empty() and actor.down.ground>0
		var attack=actor.attack.get("type","")
		if burning and not state.burn:play("death_fire",-10+BURN_GAIN_DB)
		if ground and not state.ground:play("body_fall",-8)
		if attack!=state.attack:
			if attack=="marauderRush":play("roar",-8)
			if attack=="spin":play("axe" if h.weapon=="axe" else "sword",-6,.85)
		watched[key]={"burn":burning,"ground":ground,"attack":attack}
	chicken_clock-=dt
	if not game.chicken.is_empty() and not game.chicken.roast and chicken_clock<=0:
		play("chicken",-12)
		chicken_clock=1.6+randf()

func _exit_tree():
	for player in voices+tracks:
		player.stop()
		player.stream=null
	clips.clear()

func export_choices() -> String:
	var preset={"version":2,"choices":{},"volumes":{},"pools":pools}
	for id in originals:
		preset.choices[id]=choices.get(id,"original")
		preset.volumes[id]=volumes.get(id,0.0)
	return JSON.stringify(preset,"\t",true)
