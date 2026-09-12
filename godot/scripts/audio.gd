extends Node
const CLIP_IDS=["sword","axe","flesh","heavy_hit","bone","shield","body_fall","foot_stone","foot_earth","landing","bow_draw","bow_release","arrow_hit","arrow_ground","hero_effort","hero_pain","roar","death","lightning","fire","chicken","chicken_hit","pickup","menu_land","menu_select","transition","music_menu","music_game"]
var game: Node2D
var clips: Dictionary={}
var voices: Array=[]
var tracks: Array=[]
var gates: Dictionary={}
var unlocked=false
var step_distance=0.0
var last_position=Vector2.ZERO
var last_spell=-1
var chicken_clock=0.0
var watched: Dictionary={}

func setup(source: Node2D):
	game=source
	unlocked=not OS.has_feature("web") and DisplayServer.get_name()!="headless"
	# Imported audio is listed as .ogg.import in exports. Load resource paths directly.
	for id in CLIP_IDS:
		clips[id]=load("res://audio/"+id+".ogg")
	for i in 16:
		var player=AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
	for id in ["music_menu","music_game"]:
		var player=AudioStreamPlayer.new()
		add_child(player)
		if clips.has(id):
			player.stream=clips[id]
			player.stream.loop=true
		player.volume_db=-60
		tracks.append(player)

func play(id: String,db: float=-4,pitch: float=1.0):
	if not unlocked or game.muted or not clips.has(id):return
	var now=Time.get_ticks_msec()
	if now-gates.get(id,-1000)<65:return
	gates[id]=now
	for voice in voices:
		if not voice.playing:
			voice.stream=clips[id]
			voice.volume_db=db
			voice.pitch_scale=pitch*randf_range(.965,1.035)
			voice.play()
			return

func _process(dt: float):
	if not game or game.hero.is_empty():return
	var audible=unlocked and not game.muted and not game.loading_menu
	for i in tracks.size():
		var track=tracks[i]
		var selected=(game.phase=="title")== (i==0)
		var target=-10.0 if audible and selected else -60.0
		if game.phase in ["paused","dying","lost","won"]:target-=8
		track.volume_db=move_toward(track.volume_db,target,dt*35)
		if audible and selected and track.stream and not track.playing:track.play()
		if track.volume_db<=-59 and track.playing:track.stop()
	if game.muted:
		for voice in voices:voice.stop()
	if game.phase=="paused":return
	var h=game.hero
	var point=Vector2(h.x,h.y)
	var distance=point.distance_to(last_position)
	last_position=point
	if h.moving and h.height<=0 and distance<30:
		step_distance+=distance
		if step_distance>55:
			step_distance=0
			play("foot_earth" if game.background.key=="swamp" else "foot_stone",-15)
	if game.spell>=0 and last_spell<0:play("hero_effort",-6,.85)
	if game.spell>=20 and last_spell<20:play("lightning",-5)
	last_spell=game.spell
	for actor in [h]+game.enemies:
		var key=str(actor.id)
		var state=watched.get(key,{"burn":false,"ground":false,"attack":""})
		var burning=actor.burnAge>0
		var ground=not actor.down.is_empty() and actor.down.ground>0
		var attack=actor.attack.get("type","")
		if burning and not state.burn:play("fire",-15)
		if ground and not state.ground:play("body_fall",-8)
		if attack!=state.attack:
			if attack=="archerShot":play("bow_draw",-13)
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
