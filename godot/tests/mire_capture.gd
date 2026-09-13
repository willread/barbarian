extends SceneTree
func _init():call_deferred("capture")
func capture():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.current_episode=2
	game.start_game()
	game.transition=-1;game.stage_walk=""
	game.enemies.clear();game.pending_enemies.clear()
	game.hero.x=690;game.hero.y=680
	var hag=game.make_actor(1090,680,9)
	hag.kind="witch";hag.dir=-1;hag.hazard_live=true
	game.enemies=[hag]
	for active in [false,true]:
		if active:
			hag.attack={}
			game.episode_combat.hazards=[{"kind":"mire","owner":hag,"p":Vector2(660,680),"age":.5,"life":5.0}]
		else:
			game.m.begin(hag,"mireCast")
			hag.attack.target=Vector2(660,680);hag.attack.age=40
		game._process(0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/mire-%s.png"%("active" if active else "warning"))
	print("CAIRN_MIRE_CAPTURE_OK")
	quit()
