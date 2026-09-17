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
		assert(game.background.has_node("SanctuaryAtmosphere")== (area==4),"Final-arena effects remain local to the sanctuary")
		assert(game.background.has_node("SanctuaryLanterns")== (area==4))
		if area==4:
			var lanterns=game.background.get_node("SanctuaryLanterns")
			assert(not lanterns.z_as_relative and lanterns.z_index>1805 and lanterns.z_index<game.hud.z_index,"Chains and cages sit in front of fighters but beneath HUD")
			assert(lanterns.lamps.size()==2)
			game.background.advance(12.)
			assert(not is_equal_approx(lanterns.lamps[0].pivot.rotation,lanterns.lamps[1].pivot.rotation),"Independent pendulum timing")
			for lamp in lanterns.lamps:
				assert(absf(lamp.pivot.rotation)<.025,"Foreground sway remains gentle")
				var sprite=lamp.pivot.get_child(0)
				var bottom=lamp.pivot.position.y+sprite.texture.get_height()*sprite.scale.y
				assert(bottom>570 and bottom<635,"Lantern tips hang just below the back edge of the floor")
		var heat=game.background.get_node("AshenSceneHeat")
		var capture=game.background.get_node("AshenSceneCapture")
		assert(capture.copy_mode==BackBufferCopy.COPY_MODE_VIEWPORT)
		assert(capture.z_index>1805 and heat.z_index>capture.z_index and heat.z_index<game.hud.z_index)
		assert(not heat.z_as_relative and heat.mouse_filter==Control.MOUSE_FILTER_IGNORE)
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
	assert(not game.background.has_node("AshenSceneHeat") and not game.background.has_node("AshenSceneCapture"))
	assert(not game.background.has_node("AshenVeil"),"Episode transition must remove soot overlays")
	assert(game.background.decorations.all(func(d):return d.name.begins_with("CitadelRain")))
	game.queue_free()
	await process_frame
	print("CAIRN_ASHEN_ATMOSPHERE_OK: four screens, continuous heat and ash, foreground input passthrough, transition cleanup")
	quit()
