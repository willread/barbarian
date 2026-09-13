extends SceneTree
func _init():call_deferred("capture")
func capture():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for episode in [2,3]:
		game.current_episode=episode
		game.start_game()
		for area in 4:
			game.wave=13 if area==3 else area*3+1
			game.encounters[game.wave-1]=[["king" if episode==2 else "saint"],["witch" if episode==2 else "bearer","bone"]][1 if area<3 else 0]
			game.spawn_wave()
			game.transition=-1
			game.stage_walk=""
			game.hero.x=560
			game.hero.y=680
			for i in game.enemies.size():
				game.enemies[i].x=950+i*230
				game.enemies[i].y=680+i*18
				game.enemies[i].dir=-1
			game.clock=3.0
			game._process(0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/episode-%d-area-%d.png"%[episode,area+1])
	print("CAIRN_EPISODE_CAPTURE_OK")
	quit()
