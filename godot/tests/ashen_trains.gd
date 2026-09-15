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
	assert(not trains.active and trains.next_departure>=102 and trains.next_departure<=106)
	var waits=[]
	var directions=[]
	for i in 20:
		var start=trains.next_departure
		trains.advance(start)
		assert(trains.active and trains.wagon_count>=3 and trains.wagon_count<=6)
		assert(trains.speed>=48 and trains.speed<=76)
		directions.append(trains.direction)
		var x=trains.lead_x(start)
		trains.advance(start+1)
		assert(is_equal_approx(trains.lead_x(start+1)-x,trains.direction*trains.speed))
		var end=start+trains.duration()+.01
		trains.advance(end)
		assert(not trains.active)
		var wait=trains.next_departure-end
		assert(wait>=9 and wait<=24)
		waits.append(wait)
	assert(1.0 in directions and -1.0 in directions)
	assert(waits.max()-waits.min()>5,"Crossings must not run on a fixed loop")
	assert(trains.completed==20)
	if "--train-capture" in OS.get_cmdline_user_args():
		trains.active=true
		trains.departure=0
		trains.direction=1
		trains.speed=60
		trains.wagon_count=5
		for x in [340,690,890,1250]:
			game.clock=(x+80)/60.0
			game.background.advance(game.clock)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/ashen-train-%d.png"%x)
	game.background.setup(game.art,"ashen-2")
	await process_frame
	assert(not game.background.has_node("OreTrains"))
	game.queue_free()
	await process_frame
	print("CAIRN_ASHEN_TRAINS_OK: 20 varied crossings, continuous motion, random idle gaps, both directions, area cleanup")
	quit()
