extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.records=CairnRunRecords.new("")
	game.current_episode=3
	game.audio.unlocked=true;game.muted=false;game.music_enabled=true;game.loading_menu=false
	game.start_game()
	game.stage_walk="";game.transition=-1
	game.audio._process(2.0)
	assert(game.audio.tracks[3].playing)
	game.begin_victory()
	game.victory_age=4.7
	game._process(.2)
	var scene=game.episode_intro
	assert(is_instance_valid(scene) and scene.ending,"Episode 3 follows YOU WIN with the epilogue")
	scene.set_process(false)
	assert(game.finished_run.outcome=="won" and game.records.board(CairnRunRecords.episode_scope(3)).runs.size()==1,"Victory is saved before the ending")
	assert(not is_instance_valid(game.results_view),"Results and falling menu blocks must not exist during the epilogue")
	assert(scene.caption_at(.5)=="I missed you, kid.")
	for track in game.audio.tracks:assert(not track.playing)
	assert(scene.ending_music.playing and scene.ending_music.stream.resource_path.ends_with("homeward-lastlight.ogg"),"Last Light replaces combat music for the epilogue")
	game.audio._process(2.0)
	var normal_db=-10.0+game.audio.volumes.get("music_game",0.0)
	assert(is_equal_approx(db_to_linear(scene.ending_music.volume_db-normal_db),.7))
	scene.age=18.5;scene._process(.01)
	assert(scene.player.playing)
	assert(not is_instance_valid(game.results_view),"Results remain deferred throughout the cutscene")
	if "--capture" in OS.get_cmdline_user_args():
		for time in [1.5,10.0,19.0]:
			scene.age=time;scene._process(0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/ending-%.1f.png"%time)
	scene.age=21.99;scene._process(.02)
	assert(scene.done and not scene.player.playing and game.phase=="won")
	assert(not scene.ending_music.playing and not game.audio.music_preview)
	assert(game.audio.cutscene_music_gain==1.0,"Normal music gain returns after the cutscene")
	assert(is_instance_valid(game.results_view) and not is_instance_valid(game.episode_intro))
	assert(game.records.board(CairnRunRecords.episode_scope(3)).runs.size()==1,"Returning to results cannot duplicate the victory")
	await process_frame
	game.begin_epilogue()
	scene=game.episode_intro;scene.age=1
	var skip=InputEventKey.new();skip.keycode=KEY_ENTER;skip.pressed=true
	game._input(skip)
	assert(scene.done and game.phase=="won")
	game.queue_free()
	await process_frame
	print("CAIRN_EPILOGUE_OK: after victory, saved result, continuous ducked music, subtitle, finish and skip")
	quit()
