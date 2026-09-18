extends SceneTree
func _init():check.call_deferred()
func check():
	var mix=load("res://scripts/audio_mix.gd")
	mix.setup()
	var count=AudioServer.bus_count
	mix.setup()
	assert(AudioServer.bus_count==count,"Reloading scenes must not stack effects")
	assert(mix.bus_for("enemy_impact")=="Combat" and mix.bus_for("death_fire")=="Combat")
	assert(mix.bus_for("magic_shout")=="Combat" and mix.bus_for("egg_lay")=="Foley")
	assert(AudioServer.get_bus_send(AudioServer.get_bus_index("Music"))=="Master")
	assert(AudioServer.get_bus_effect_count(AudioServer.get_bus_index("Music"))==0)
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_game()
	game.audio.unlocked=true
	game.muted=false
	game.audio.play("enemy_impact")
	var impact=game.audio.voices.filter(func(v):return v.playing and v.get_meta("sound_id","")=="enemy_impact")
	assert(impact.size()==1 and impact[0].bus=="Combat")
	assert(impact[0].playback_type==AudioServer.PLAYBACK_TYPE_STREAM)
	game.audio.stop_gameplay()
	var enemy=game.make_actor(900,660,0)
	enemy.burnAge=.1
	game.enemies=[enemy]
	game.audio._process(.01)
	var burns=game.audio.voices.filter(func(v):return v.playing and v.get_meta("sound_id","")=="death_fire")
	assert(burns.size()==1 and burns[0].bus=="Combat")
	assert(is_equal_approx(db_to_linear(burns[0].get_meta("base_db")+10),2.),"Burn gain must double independently of user volume settings")
	game.audio.stop_gameplay()
	game.voice_enabled=false
	game.audio.gates.clear()
	for id in mix.VOCALS:
		assert(mix.bus_for(id)=="Combat","Combat vocalizations are sound effects")
		if not game.audio.clips.has(id):continue
		game.audio.play(id)
		assert(game.audio.voices.any(func(v):return v.playing and v.get_meta("sound_id","")==id),"Voice OFF must allow shouts: "+id)
	game.audio._process(.01)
	assert(game.audio.voices.any(func(v):return v.playing and v.get_meta("sound_id","")=="magic_shout"),"Voice OFF must not stop an active shout")
	game.muted=true
	game.audio._process(.01)
	assert(not game.audio.voices.any(func(v):return v.playing),"Sound OFF stops combat shouts")
	game.audio.gates.clear()
	game.audio.play("hero_pain")
	assert(not game.audio.voices.any(func(v):return v.playing),"Sound OFF blocks new combat shouts")
	assert(game.hero_voice.player.bus=="Voice")
	for track in game.audio.tracks:assert(track.bus=="Music")
	game.process_mode=Node.PROCESS_MODE_DISABLED
	game.audio.stop_gameplay()
	for track in game.audio.tracks:track.stop()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(.1).timeout
	print("CAIRN_MIX_OK: shared processing, routing, browser streams, scene reloads and doubled burn gain")
	quit()
