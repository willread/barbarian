extends SceneTree
func _init(): call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_game()
	game.transition=-1
	game.stage_walk=""
	game.change_phase("paused")
	await create_timer(1.1).timeout
	assert(game.pause_cover==1.0)
	assert(game.menu.items[0].label=="RETURN TO BATTLE")
	if "--pause-capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/pause-menu.png")
	game.menu_action("OPTIONS")
	await create_timer(.6).timeout
	assert(not game.menu.title_mode and game.menu.items[0].label=="SOUND")
	game.menu_action("SOUND")
	await create_timer(.6).timeout
	assert(not game.menu.title_mode and game.menu.items.size()==4)
	game.menu_action("BACK")
	await create_timer(.6).timeout
	game.menu_action("BACK")
	await create_timer(.6).timeout
	assert(game.menu.items[0].label=="RETURN TO BATTLE")
	game.menu_action("RETURN TO BATTLE")
	await create_timer(.7).timeout
	assert(game.phase=="playing" and game.pause_cover==0.0)
	game.change_phase("paused")
	game.menu_action("QUIT TO TITLE")
	assert(game.phase=="title" and game.menu.items[2].label=="QUIT")
	print("CAIRN_PAUSE_OK: skull closure, nested centered options, resume and quit to title")
	quit()
