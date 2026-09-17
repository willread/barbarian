extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_game();game.transition=-1;game.stage_walk=""
	game.pending_enemies.clear();game.enemies.clear()
	for area in [1,3]:
		game.wave=1 if area==1 else 7
		game.background.setup(game.art,"citadel-%d"%area)
		game.hero.x=720 if area==1 else 160
		game.hero.y=745;game.hero.height=0;game.hero.attack={}
		game.background.constrain(game.hero)
		assert(game.hero.y>730,"Expanded terrace permits foot positions nearer the foreground")
		if area==3:
			assert(game.background.screen.foreground.size()>=2,"Foundry rubble has foreground masks")
			var foreground=game.background.get_children().filter(func(node):return node is Sprite2D and node.z_index==1805)
			assert(foreground.size()==1 and foreground[0].texture.get_image().get_used_rect().has_area())
		game._process(0)
		if "--ground-capture" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/citadel-ground-%d.png"%area)
	game.queue_free();await process_frame
	print("CAIRN_GROUND_OK: extended foot positions and foreground occlusion layer")
	quit()
