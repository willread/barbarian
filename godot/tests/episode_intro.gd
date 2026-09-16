extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.audio.set_process(false)
	game.loading_menu=false
	game.current_episode=1
	game.audio.tracks[0].play()
	game.begin_episode()
	var intro=game.episode_intro
	intro.set_process(false)
	assert(is_instance_valid(intro) and game.audio.music_preview)
	for track in game.audio.tracks:assert(not track.playing)
	var before=game.clock
	game._process(.2)
	assert(game.clock==before,"Gameplay stays frozen under the opening")
	assert(intro.caption_at(-.1)=="" and intro.caption_at(.5)=="They took my goat...")
	assert(intro.caption_at(2.1)=="Now I'm going to take their lives!")
	intro.age=20
	intro._process(.01)
	assert(intro.player.playing and intro.voice_started)
	intro.age=21.54;intro._process(0)
	assert(not intro.sting_started,"Guitar waits for the pause before the second line")
	intro.age=21.55;intro._process(.001)
	assert(intro.sting_started and intro.sting.playing)
	intro.age=22.1;intro._process(0)
	assert(intro.sting.volume_db<=-17,"Guitar tail ducks below the spoken threat")
	if "--capture" in OS.get_cmdline_user_args():
		for time in [1.5,12.0,20.5,22.5]:
			intro.age=time
			intro._process(0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/intro-%.1f.png"%time)
	intro.age=25.99
	intro._process(.02)
	assert(intro.done and not intro.player.playing and not intro.sting.playing)
	assert(not is_instance_valid(game.episode_intro) and game.phase=="playing" and game.wave==1)
	assert(not game.audio.music_preview)
	await process_frame
	game.begin_episode()
	intro=game.episode_intro
	intro.age=1
	var skip=InputEventJoypadButton.new()
	skip.button_index=JOY_BUTTON_A;skip.pressed=true
	game._input(skip)
	assert(intro.done and not is_instance_valid(game.episode_intro))
	await process_frame
	game.current_episode=2
	game.begin_episode()
	assert(not is_instance_valid(game.episode_intro) and game.phase=="playing")
	game.queue_free()
	await process_frame
	print("CAIRN_INTRO_OK: episode gate, frozen gameplay, exclusive narration, subtitles, completion and controller skip")
	quit()
