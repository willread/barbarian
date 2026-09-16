extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.records=CairnRunRecords.new("")
	game.audio.set_process(false)
	game.loading_menu=false
	game.audio.unlocked=true;game.muted=false;game.music_enabled=true
	game.current_episode=1
	game.audio.tracks[0].play()
	game.begin_episode()
	var intro=game.episode_intro
	intro.set_process(false)
	assert(is_instance_valid(intro) and not game.audio.music_preview)
	assert(game.audio.tracks[0].playing,"Existing music continues through the intro")
	game.audio._process(2.0)
	var normal_db=-10.0+game.audio.volumes.get("music_menu",0.0)
	assert(is_equal_approx(db_to_linear(game.audio.tracks[0].volume_db-normal_db),.7),"Music plays at 70 percent amplitude")
	var before=game.clock
	game._process(.2)
	assert(game.clock==before,"Gameplay stays frozen under the opening")
	assert(intro.caption_at(-.1)=="" and intro.caption_at(.5)=="They took my goat...")
	assert(intro.caption_at(5.5)=="Now I'm going to take their lives!")
	intro.age=1
	intro._process(.01)
	assert(intro.player.playing and intro.voice_started)
	intro.age=5.93;intro._process(0)
	assert(not intro.sting_started,"Guitar waits for the pause before the second line")
	intro.age=5.94;intro._process(.001)
	assert(intro.sting_started and intro.sting.playing)
	intro.age=6.5;intro._process(0)
	assert(intro.second_line_started and intro.player.stream.resource_path.ends_with("revenge-line-two.ogg"))
	assert(intro.caption_at(3.0)=="","Subtitles clear between the separated lines")
	assert(intro.sting.volume_db<=-17,"Guitar tail ducks below the spoken threat")
	if "--capture" in OS.get_cmdline_user_args():
		for time in [1.5,4.0,6.5,9.0]:
			intro.age=time
			intro._process(0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/intro-%.1f.png"%time)
	intro.age=10.49
	intro._process(.02)
	assert(intro.done and not intro.player.playing and not intro.sting.playing)
	assert(not is_instance_valid(game.episode_intro) and game.phase=="playing" and game.wave==1)
	assert(not game.audio.music_preview and game.audio.cutscene_music_gain==1.0)
	await process_frame
	game.begin_episode()
	intro=game.episode_intro
	intro.age=1
	var skip=InputEventJoypadButton.new()
	skip.button_index=JOY_BUTTON_RIGHT_SHOULDER;skip.pressed=true
	game._input(skip)
	assert(intro.done and not is_instance_valid(game.episode_intro))
	await process_frame
	# The actual death-menu action must bypass the opening on every retry.
	for retry in 2:
		game.hero.hp=0
		game.change_phase("lost")
		game.menu_action("RISE AGAIN")
		assert(not is_instance_valid(game.episode_intro),"Death restart never replays the cutscene")
		assert(game.phase=="playing" and game.wave==1 and game.hero.hp>0)
	# A fresh episode selection still plays it, even after a previous run.
	game.change_phase("title")
	game.menu_action("EP 1: THE FALLEN CITADEL")
	game.menu_action("NORMAL")
	assert(is_instance_valid(game.episode_intro),"Fresh menu selection plays the opening")
	game.episode_intro.finish()
	await process_frame
	game.current_episode=2
	game.begin_episode()
	assert(not is_instance_valid(game.episode_intro) and game.phase=="playing")
	game.queue_free()
	await process_frame
	await create_timer(.15).timeout
	print("CAIRN_INTRO_OK: episode gate, frozen gameplay, continuous ducked music, subtitles, completion and controller skip")
	quit()
