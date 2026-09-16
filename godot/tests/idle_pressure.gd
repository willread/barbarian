extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_game()
	game.transition=-1;game.stage_walk=""
	game.pending_enemies.clear()
	for facing in [-1,1]:
		for side in [-1,1]:
			game.hero=game.m.make(1,720,660,100,true)
			game.hero.dir=facing
			var enemy=game.make_actor(720+side*180,660,100)
			enemy.kind="legion";enemy.dir=-side
			game.enemies=[enemy]
			for frame in 360:
				game.tick(game.m.STEP)
				if game.hero.hp<100:break
			assert(game.hero.hp<100,"Idle player must be hit from either side and facing")
	var melee=game.make_actor(950,660,100)
	var archer=game.make_actor(800,660,100);archer.kind="archer"
	game.hero.x=720;game.enemies=[archer,melee]
	assert(melee.id in game.engaged_enemies(),"Ranged actors must not reserve melee engagement slots")
	if "--idle-hud-capture" in OS.get_cmdline_user_args():
		game.hero.hp=100;game.combo.hits=0;game.combo.bonus_multiplier=3
		game._process(0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/idle-hud.png")
	game.queue_free()
	await process_frame
	print("CAIRN_IDLE_PRESSURE_OK: stationary player attacked from both sides; ranged actors do not block melee")
	quit()
