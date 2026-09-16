extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.records=CairnRunRecords.new("")
	game.current_episode=3
	game.start_game()
	game.stage_walk="";game.transition=-1
	game.begin_victory()
	game.victory_age=4.7
	game._process(.2)
	var scene=game.episode_intro
	assert(is_instance_valid(scene) and scene.ending,"Episode 3 follows YOU WIN with the epilogue")
	scene.set_process(false)
	assert(game.finished_run.outcome=="won" and game.records.board(CairnRunRecords.episode_scope(3)).runs.size()==1,"Victory is saved before the ending")
	assert(scene.caption_at(.5)=="I missed you, kid.")
	for track in game.audio.tracks:assert(not track.playing)
	scene.age=18.5;scene._process(.01)
	assert(scene.player.playing)
	if "--capture" in OS.get_cmdline_user_args():
		for time in [1.5,10.0,19.0]:
			scene.age=time;scene._process(0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/ending-%.1f.png"%time)
	scene.age=21.99;scene._process(.02)
	assert(scene.done and not scene.player.playing and game.phase=="won")
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
	print("CAIRN_EPILOGUE_OK: after victory, saved result, exclusive narration, subtitle, finish and skip")
	quit()
