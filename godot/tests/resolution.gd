extends SceneTree
func _init():call_deferred("check")
func check():
	var shell=load("res://presentation.tscn").instantiate()
	root.add_child(shell)
	current_scene=shell
	await create_timer(2.0).timeout
	var game=shell.scene
	assert(game.has_method("start_game"),"Boot scene transitions inside the presentation viewport")
	for dimensions in [Vector2i(1280,720),Vector2i(1600,700),Vector2i(900,900),Vector2i(640,960)]:
		root.size=dimensions
		await create_timer(.15).timeout
		assert(is_equal_approx(shell.frame.size.x/shell.frame.size.y,16.0/9))
		assert(shell.frame.position.x>=0 and shell.frame.position.y>=0)
		assert(shell.game_view.get_visible_rect().size==Vector2(1440,810))
		game.change_phase("title")
		await create_timer(1.6).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/resolution-menu-%d.png"%dimensions.x)
		game.start_game()
		game.transition=-1
		game.stage_walk=""
		await create_timer(.1).timeout
		game.change_phase("paused")
		await create_timer(1.6).timeout
		assert(game.screen_size==Vector2(1440,810))
		game.change_phase("playing")
		await create_timer(.8).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/resolution-game-%d.png"%dimensions.x)
	# Keyboard events must reach the console through the SubViewportContainer.
	var key=InputEventKey.new()
	key.pressed=true
	key.keycode=KEY_QUOTELEFT
	key.physical_keycode=KEY_QUOTELEFT
	root.push_input(key)
	await process_frame
	assert(game.debug_console.visible and paused,"Console input reaches the game viewport")
	game.debug_console.close()
	game.change_phase("title")
	await create_timer(2.0).timeout
	var item=game.menu.items[0]
	var logical=game.menu.to_global(item.node.position+Vector2(0,item.height*.5))
	var location=shell.container.position+logical*shell.container.size/Vector2(1440,810)
	var motion=InputEventMouseMotion.new()
	motion.position=location
	root.push_input(motion)
	var click=InputEventMouseButton.new()
	click.position=location
	click.button_index=MOUSE_BUTTON_LEFT
	click.pressed=true
	root.push_input(click)
	await create_timer(.5).timeout
	assert(game.chapter_select,"Mouse clicks map correctly through centered viewport")
	var prefs=root.get_node("WindowPreferences")
	for requested in [Vector2i(1000,700),Vector2i(640,960),Vector2i(5000,2000)]:
		var fitted=prefs.fit_window_size(requested,Vector2i(1920,1032))
		assert(fitted.x*9==fitted.y*16 and fitted.x<=1920 and fitted.y<=1032)
	prefs.enabled=true
	root.size=Vector2i(1100,800)
	prefs.constrain_window()
	assert(root.size.x*9==root.size.y*16,"Native window resize is constrained to 16:9")
	prefs.enabled=false
	print("CAIRN_RESOLUTION_OK: boot, fixed composition, wide/tall masonry, pause, keyboard input and window constraint")
	quit()
