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
	var view=combat.bomb_views[0]
	assert(view.body.texture!=null and view.ground_light.enabled and view.object_light.enabled)
	assert(view.ground_light.range_z_max==0 and view.object_light.range_z_max<game.hud.z_index,"Bomb lights exclude HUD")
	var low_energy=view.ground_light.energy
	var raised=bomb.duplicate()
	raised.reflected=true;raised.launch_height=150.0;raised.flight_age=0.0
	view.configure(raised)
	assert(view.ground_light.energy<low_energy*.3,"Airborne source dims its floor illumination")
	assert(view.object_light.position.y<-150,"Object lighting follows the airborne core")
	view.configure(bomb)
	if "--bomb-capture" in OS.get_cmdline_user_args():
		game._process(0)
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
	for offset in [Vector2(251,0),Vector2(0,181),Vector2(225,100)]:
		hero.x=720+offset.x;hero.y=670+offset.y;hero.down={};hero.invTicks=0;hero.hp=100
		bomb.erase("detonated")
		combat.detonate(game,bomb)
		assert(hero.hp==100,"Damage must stay inside blast footprint")
	# Depth is ground-plane distance, not jump height. Both sides of the bomb hurt.
	for depth in [-150.0,150.0,0.0]:
		hero.x=720;hero.y=670+depth;hero.hp=100;hero.down={};hero.invTicks=0;hero.height=0
		bomb.erase("detonated")
		combat.detonate(game,bomb)
		var expected=2.0*lerpf(14,8,absf(depth)/180.0)*game.damage_multiplier*game.difficulty_damage(true)*(100.0/48.0)*game.e_ai.damage_scale(owner)
		assert(is_equal_approx(100-hero.hp,expected),"Front/back reach and doubled damage must agree")
	hero.hp=100;hero.down={}
	hero.x=720;hero.y=670;hero.invTicks=30
	bomb.erase("detonated")
	combat.detonate(game,bomb)
	assert(hero.hp==100,"Respect invulnerability")
	owner.x=740;owner.invTicks=0;owner.down={};owner.hp=30
	bomb.reflected=true;bomb.erase("detonated")
	combat.detonate(game,bomb)
	assert(owner.hp<30 and owner.slamPush.x>0 and hero.hp==100,"Reflected blast hits enemies only")
	# Unreflected blasts also damage their thrower and nearby allies.
	owner.hp=50;owner.invTicks=0;owner.down={};owner.x=730
	var ally=game.make_actor(760,670,101)
	ally.kind="bone";ally.hp=50;ally.invTicks=0
	game.enemies=[owner,ally]
	bomb.reflected=false;bomb.erase("detonated")
	hero.invTicks=30
	combat.detonate(game,bomb)
	assert(owner.hp<50 and ally.hp<50,"Thrower and allies take friendly blast damage")
	game.enemies=[owner]
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
	assert(arc.p.x>landing.x,"Bomb continues forward through a small bounce")
	assert(arc.velocity.x>0 and arc.velocity.x<650,"Landing loses momentum")
	combat.advance_bomb(arc,1.0)
	assert(arc.bounce_count>=3,"Bomb makes several small settling contacts")
	assert(combat.bomb_height(arc)==0 and arc.velocity.x<30,"Bounces settle into a short roll")
	arc.p=Vector2(1435,670);arc.velocity=Vector2(1050,0);arc.flight_age=0.0;arc.launch_height=0.0;arc.launch_speed=520.0
	combat.advance_bomb(arc,.1)
	assert(arc.p.x>1440,"Knocked bombs can leave the screen")
	assert(combat.BOMB_FUSE-combat.BOMB_FLIGHT<=.61,"Short grounded reaction window")
	# Launch originates at the animated blade, with a brief impact beat and no fuse reset.
	hero.down={};hero.hurtTicks=0;hero.recovering=0;hero.attack={};hero.height=0;hero.x=500;hero.y=670;hero.dir=1
	game.m.begin(hero,"charge")
	hero.attack.age=hero.attack.from
	var tip=game.art.weapon_tip(hero,game.art.pose(hero))
	var fuse=arc.life
	combat.strike_bomb(game,arc,hero.attack)
	assert(absf(arc.p.x-tip.x-18)<.01)
	assert(absf((arc.p.y-27-combat.bomb_height(arc))-tip.y)<.01,"Launch must leave the weapon rather than the floor")
	assert(arc.launch_speed==330 and arc.velocity.x>1100 and game.bomb_hit_pause>0)
	assert(arc.life==fuse,"Harder strikes do not reset the short fuse")
	var shallow=arc.duplicate()
	var release_height=combat.bomb_height(shallow)
	combat.advance_bomb(shallow,.1)
	assert(combat.bomb_height(shallow)>release_height and combat.bomb_height(shallow)<release_height+20,"Short upward kick, no skyward launch")
	combat.advance_bomb(shallow,.16)
	assert(combat.bomb_height(shallow)<release_height,"Bomb must visibly descend within a quarter second")
	combat.advance_bomb(shallow,.3)
	assert(combat.bomb_height(shallow)<25,"Heavy lob returns to the floor quickly")
	var paused_clock=game.clock
	game._process(.01)
	assert(game.clock==paused_clock and game.bomb_hit_pause>0,"Impact beat briefly holds simulation")
	if "--bomb-capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/bomb-weapon-contact.png")
	hero.attack={}
	# Other enemies react only after physical ground contact.
	var thrown={"kind":"clinker","owner":owner,"p":Vector2(1000,670),"target":Vector2(720,670),"age":.5,"life":2.25,"reflected":false,"landed":true}
	combat.hazards=[thrown]
	var dodger=game.make_actor(720,670,100)
	dodger.kind="bone";dodger.attack={};dodger.down={};dodger.hurtTicks=0;dodger.recovering=false
	thrown.landed=false
	assert(combat.avoid_bombs(game,dodger)==null,"Airborne bombs must not trigger flight")
	thrown.landed=true
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
	owner.x=720;owner.y=560;owner.hp=50;owner.down={};owner.hurtTicks=0;owner.recovering=0;owner.attack={}
	game.m.begin(owner,"clinkerThrow")
	owner.attack.age=owner.attack.from+1
	assert(combat.avoid_bombs(game,owner)!=null and owner.attack.is_empty(),"Thrower can flee its own landed bomb during recovery")
	combat.clear()
	# Close pressure selects a warned fire scream, with one damaging blast.
	owner.x=900;owner.y=670;owner.hp=50;owner.down={};owner.hurtTicks=0;owner.recovering=0;owner.attack={};owner.aiRest=0
	hero.x=1000;hero.y=670;hero.hp=100;hero.height=0;hero.invTicks=0;hero.down={};hero.attack={}
	game.e_ai.intent(owner,hero,true)
	assert(owner.attack.type=="hellScream")
	owner.attack.age=owner.attack.from-1
	combat.step(game,.01)
	assert(hero.hp==100,"Scream windup gives time to escape")
	owner.attack.age=owner.attack.from
	combat.step(game,.01)
	assert(hero.hp<100 and not hero.down.is_empty())
	var scream_hp=hero.hp
	combat.step(game,.01)
	assert(hero.hp==scream_hp,"One hit per scream")
	combat.sync_views(game,0)
	assert(combat.scream_views.size()==1)
	if "--bomb-capture" in OS.get_cmdline_user_args():
		owner.attack.age=48
		game._process(0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/bearer-scream.png")
	for sample in [[48,260,true],[70,100,true],[78,100,false],[35,100,false],[48,-100,false],[48,360,false]]:
		owner.attack.age=sample[0];owner.attack.erase("scorched")
		hero.x=owner.x+sample[1];hero.hp=100;hero.down={};hero.invTicks=0;hero.attack={}
		combat.step_scream(game,owner,owner.attack)
		assert((hero.hp<100)==sample[2],"Flame envelope must cover its visible reach and fading tail")
	owner.attack={}
	combat.sync_views(game,0)
	assert(combat.scream_views.is_empty())
	game.queue_free()
	await process_frame
	print("CAIRN_BOMBS_OK: fuse, damage, radial knockdown, ellipse, invulnerability, reflection, pause and cleanup")
	quit()

