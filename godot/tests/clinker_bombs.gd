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
	var owner=game.make_actor(1000,670,99)
	owner.kind="bearer"
	game.enemies=[owner]
	var combat=game.episode_combat
	var hero=game.hero
	hero.x=760.;hero.y=670.;hero.hp=100.;hero.height=0.;hero.invTicks=0;hero.down={};hero.attack={}
	var bomb={"kind":"clinker","owner":owner,"p":Vector2(720,670),"start":Vector2(720,670),"target":Vector2(720,670),"age":.7,"life":2.25,"reflected":false,"velocity":Vector2.ZERO,"strikes":[]}
	combat.hazards=[bomb]
	combat.step(game,1.0)
	assert(hero.hp==100 and hero.down.is_empty(),"Fuse cannot deal early damage")
	combat.sync_views(game,0)
	assert(combat.bomb_views.size()==1)
	if "--bomb-capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/bomb-warning.png")
	combat.step(game,.56)
	assert(hero.hp<100 and not hero.down.is_empty() and hero.slamPush.x>0,"Blast must hurt, knock down and push outward")
	var hp=hero.hp
	combat.detonate(game,bomb)
	assert(hero.hp==hp and combat.explosions.size()==1,"Exactly one explosion per bomb")
	combat.sync_views(game,0)
	assert(combat.bomb_views.is_empty() and combat.explosions[0].age==0,"Pause freezes effects")
	for time in [.12,.28,.65,1.3]:
		combat.explosions[0].age=0
		combat.explosions[0].advance(time)
		if "--bomb-capture" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/bomb-blast-%.2f.png"%time)
	for offset in [Vector2(221,0),Vector2(0,86),Vector2(200,70)]:
		hero.x=720+offset.x;hero.y=670+offset.y;hero.down={};hero.invTicks=0;hero.hp=100
		bomb.erase("detonated")
		combat.detonate(game,bomb)
		assert(hero.hp==100,"Damage must stay inside warning ellipse")
	hero.x=720;hero.y=670;hero.invTicks=30
	bomb.erase("detonated")
	combat.detonate(game,bomb)
	assert(hero.hp==100,"Respect invulnerability")
	owner.x=740;owner.invTicks=0;owner.down={};owner.hp=30
	bomb.reflected=true;bomb.erase("detonated")
	combat.detonate(game,bomb)
	assert(owner.hp<30 and owner.slamPush.x>0 and hero.hp==100,"Reflected blast hits enemies only")
	combat.clear()
	assert(combat.explosions.is_empty() and combat.bomb_views.is_empty())
	game.queue_free()
	await process_frame
	print("CAIRN_BOMBS_OK: fuse, damage, radial knockdown, ellipse, invulnerability, reflection, pause and cleanup")
	quit()

