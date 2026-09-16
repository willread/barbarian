extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.current_episode=1
	game.start_game()
	game.transition=-1
	game.stage_walk=""
	for area in range(1,5):
		game.background.setup(game.art,"citadel-%d"%area)
		await process_frame
		var rain=game.background.get_node("CitadelRainNear")
		var ground=game.background.get_node("CitadelRainGround")
		assert(rain.drops.size()>40)
		assert(rain.drops==ground.drops,"Splashes and falling drops share impact positions and timing")
		assert(ground.z_index<0 and rain.z_index<game.hud.z_index)
		game.background.advance(61.7)
		assert(rain.clock==61.7)
		if "--rain-capture" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/citadel-rain-%d.png"%area)
	game.background.setup(game.art,"swamp-1")
	assert(not game.background.has_node("CitadelRainNear"))
	game.queue_free()
	await process_frame
	print("CAIRN_RAIN_OK: four screens, paired impacts, depth, HUD exclusion and episode cleanup")
	quit()
