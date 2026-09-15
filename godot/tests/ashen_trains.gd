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
	game.background.setup(game.art,"ashen-1")
	await process_frame
	var trains=game.background.get_node("OreTrains")
	trains.rng.seed=12345
	trains.advance(100)
	assert(trains.phase=="parked" and trains.positions==trains.PARKED)
	assert(trains.get_child_count()==0,"The track must be one shader region, with no extra convoy sprites")
	var variants=[]
	for i in 20:
		trains.advance(trains.phase_start+trains.phase_duration+.01)
		assert(trains.phase=="depart")
		assert(trains.positions==trains.PARKED,"Departure must not snap carts out of their painted positions")
		variants.append(trains.variant)
		trains.advance(trains.phase_start+12)
		assert(trains.positions.x<trains.positions.y,"Carts must never cross through one another")
		var before=trains.positions
		trains.advance(trains.clock+.01)
		assert(trains.positions.distance_to(before)<2,"Motion must remain continuous")
		trains.advance(trains.phase_start+trains.phase_duration+maxf(trains.delays.x,trains.delays.y)+.01)
		assert(trains.phase=="empty")
		assert(trains.phase_duration>=9 and trains.phase_duration<=24)
		trains.advance(trains.phase_start+trains.phase_duration+.01)
		assert(trains.phase=="arrive")
		trains.advance(trains.phase_start+trains.phase_duration*.5)
		assert(trains.positions.x<trains.positions.y)
		trains.advance(trains.phase_start+trains.phase_duration+.01)
		assert(trains.phase=="parked" and trains.positions==trains.PARKED)
	assert(0 in variants and 1 in variants and 2 in variants)
	assert(trains.completed==20)
	if "--train-capture" in OS.get_cmdline_user_args():
		var samples=[Vector2(720,1180),Vector2(880,1340),Vector2(530,990),Vector2(170,630)]
		for i in samples.size():
			trains.track_material.set_shader_parameter("cart_positions",samples[i])
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/ashen-track-region-%d.png"%i)
	game.background.setup(game.art,"ashen-2")
	await process_frame
	assert(not game.background.has_node("OreTrains"))
	game.queue_free()
	await process_frame
	print("CAIRN_ASHEN_TRAINS_OK: original carts, 20 regional sequences, three variants, no crossings or departure snaps, area cleanup")
	quit()
