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
	# Reflected projectiles rise, descend and settle; their landing tell stays fixed.
	var arc={"kind":"clinker","owner":owner,"p":Vector2(400,670),"target":Vector2(400,670),"age":.8,"life":3.0,"reflected":true,"velocity":Vector2(650,0),"strikes":[],"flight_age":0.0,"launch_height":0.0,"launch_speed":430.0}
	combat.hazards=[arc]
	owner.x=1300;owner.hp=30;owner.invTicks=0;owner.down={};owner.attack={}
	hero.attack={}
	var landing=combat.bomb_landing(arc)
	combat.step(game,.2)
	var rise=combat.bomb_height(arc)
	assert(rise>60)
	combat.step(game,.2)
	assert(combat.bomb_height(arc)>rise,"Bomb rises after reflection")
	assert(combat.bomb_landing(arc).distance_to(landing)<.01,"Landing warning tracks the ballistic endpoint")
	var peak=combat.bomb_height(arc)
	combat.step(game,.35)
	assert(combat.bomb_height(arc)<peak,"Bomb falls after its apex")
	combat.step(game,.25)
	assert(arc.p.distance_to(landing)<.01)
	assert(combat.bomb_height(arc)==0 and arc.velocity==Vector2.ZERO,"Bomb settles on the floor")
	# Other enemies avoid a bearer's throw, even before it lands.
	var thrown={"kind":"clinker","owner":owner,"p":Vector2(1000,670),"target":Vector2(720,670),"age":.3,"life":2.25,"reflected":false}
	combat.hazards=[thrown]
	var dodger=game.make_actor(720,670,100)
	dodger.kind="bone";dodger.attack={};dodger.down={};dodger.hurtTicks=0;dodger.recovering=false
	var escape=combat.avoid_bombs(game,dodger)
	assert(escape is Vector2 and escape.length()>.9,"Nearby enemy must seek an escape")
	for tick in 100:
		escape=combat.avoid_bombs(game,dodger)
		if escape==null:break
		dodger.x+=escape.x*3;dodger.y+=escape.y*3
	assert(((Vector2(dodger.x,dodger.y)-thrown.target)/combat.BOMB_RADIUS).length()>1,"Escape actually clears the blast")
	assert(dodger.y>=560 and dodger.y<=755)
	dodger.x=720;dodger.y=560;thrown.target=Vector2(720,560)
	escape=combat.avoid_bombs(game,dodger)
	assert(escape.y>=0,"Do not evade into the upper wall")
	dodger.hurtTicks=10
	assert(combat.avoid_bombs(game,dodger)==null,"Stunned enemies cannot evade")
	combat.clear()
	game.queue_free()
	await process_frame
	print("CAIRN_BOMBS_OK: fuse, damage, radial knockdown, ellipse, invulnerability, reflection, pause and cleanup")
	quit()

