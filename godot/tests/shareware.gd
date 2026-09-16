extends SceneTree
func _init():call_deferred("check")
func check():
	if "--expect-shareware" in OS.get_cmdline_user_args():assert(OS.has_feature("shareware"))
	if "--expect-full" in OS.get_cmdline_user_args():assert(not OS.has_feature("shareware"))
	var game=load("res://main.tscn").instantiate()
	game.shareware=true
	root.add_child(game)
	game.set_process(false)
	game.loading_menu=false;game.title_intro=1.25
	assert(not auto_accept_quit)
	if "--shareware-capture" in OS.get_cmdline_user_args():
		game._process(0)
		game.overlay.queue_redraw()
		await create_timer(1.8,true).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/shareware-title.png")
		game.menu_action("NEW JOURNEY")
		await create_timer(1.8,true).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/shareware-chapters.png")
	game.menu_action("EP 2: THE SUNKEN WILDS")
	assert(game.current_episode==1 and is_instance_valid(game.upgrade_view))
	assert(paused and not game.difficulty_select)
	var view=game.upgrade_view
	assert(view.STORE_URL=="https://maxforcegames.itch.io/")
	assert(not view.quitting)
	if "--shareware-capture" in OS.get_cmdline_user_args():
		await create_timer(.4,true).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/shareware-buy.png")
	view.selected=1
	if "--shareware-capture" in OS.get_cmdline_user_args():
		await create_timer(.4,true).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/shareware-back.png")
	view.activate()
	await process_frame
	assert(not paused and not is_instance_valid(game.upgrade_view))
	game.menu_action("EP 3: THE ASHEN DEPTHS")
	assert(is_instance_valid(game.upgrade_view) and game.current_episode==1)
	game.upgrade_view.closed.emit()
	await process_frame
	game.request_quit()
	assert(game.upgrade_view.quitting,"Quit first shows the upgrade screen")
	game.upgrade_view.closed.emit()
	await process_frame
	game.current_episode=3;game.start_game()
	assert(game.current_episode==1 and is_instance_valid(game.upgrade_view),"Direct episode start cannot bypass shareware")
	game.upgrade_view.closed.emit()
	await process_frame
	game.menu_action("EP 1: THE FALLEN CITADEL")
	assert(game.difficulty_select and not is_instance_valid(game.upgrade_view))
	game.menu_action("NORMAL")
	assert(is_instance_valid(game.episode_intro))
	game.episode_intro.finish()
	await process_frame
	assert(game.phase=="playing" and game.current_episode==1)
	game.change_phase("title")
	game.transition=-1;game.hit_stop=0;game.bomb_hit_pause=0
	game.title_intro=1.25
	game._process(0)
	game.shareware=false
	game.menu_action("EP 3: THE ASHEN DEPTHS")
	assert(game.current_episode==3 and game.difficulty_select,"Full edition retains all episodes")
	game.queue_free()
	await process_frame
	print("CAIRN_SHAREWARE_OK: locked episodes, modal buttons, quit routing, episode-one access and full-edition access")
	quit()

