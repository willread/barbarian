extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.current_episode=3
	game.start_game()
	game.transition=-1
	game.stage_walk=""
	for area in range(1,5):
		game.background.setup(game.art,"ashen-%d"%area)
		await process_frame
		assert(game.background.has_node("AshenVeil"))
		assert(game.background.has_node("FurnaceExhaust")== (area==2),"Dedicated exhaust belongs only to the furnace")
		assert(game.background.has_node("HangingBrazier")== (area==3))
		var veil=game.background.get_node("AshenVeil")
		assert(veil.mouse_filter==Control.MOUSE_FILTER_IGNORE and veil.z_index==1810)
		for time in [23.98,24.02,61.7]:
			game.background.advance(time)
			if area==3:assert(absf(game.background.get_node("HangingBrazier").rotation)<.029)
			for material in game.background.layers:
				assert(is_equal_approx(material.get_shader_parameter("clock"),time),"Atmosphere must not jump at the old 24-second loop boundary")
			for decoration in game.background.decorations:
				assert(is_equal_approx(decoration.clock,time))
			if "--ashen-capture" in OS.get_cmdline_user_args():
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("E:/Cairn-build-tools/ashen-motion-%d-%.2f.png"%[area,time])
	game.background.setup(game.art,"citadel-1")
	await process_frame
	assert(not game.background.has_node("AshenVeil"),"Episode transition must remove soot overlays")
	assert(game.background.decorations.is_empty())
	game.queue_free()
	await process_frame
	print("CAIRN_ASHEN_ATMOSPHERE_OK: four screens, continuous heat and ash, foreground input passthrough, transition cleanup")
	quit()
