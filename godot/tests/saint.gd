extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.current_episode=3
	game.start_game()
	game.transition=-1;game.stage_walk=""
	game.background.setup(game.art,"ashen-4")
	var boss=game.make_actor(1040,690,120)
	boss.kind="saint";boss.boss=true;boss.dir=-1
	game.enemies=[boss];game.pending_enemies.clear()
	var hero=game.hero
	hero.x=670;hero.y=690;hero.hp=100;hero.max=100
	var combat=game.episode_combat
	boss.moving=true
	for frame in 8:
		boss.stride=frame/8.0
		var pose=game.art.pose(boss)
		assert(pose==["saint-walk",frame])
		assert(game.art.texture(game.art.layout(pose).cel.file)!=null)
	boss.moving=false
	assert(game.art.pose(boss)[0]=="enemy-saint-v1","Stopping returns to the standing pose")
	# Both batch sizes stay threatening together, with visible gaps and depth variation.
	for count in [2,3]:
		for sample in 100:
			var targets=combat.saint_volley_targets(game,boss,count)
			var min_depth=1000.0
			var max_depth=0.0
			for i in count:
				min_depth=minf(min_depth,targets[i].y)
				max_depth=maxf(max_depth,targets[i].y)
				assert(((targets[i]-Vector2(hero.x,hero.y))/combat.BOMB_RADIUS).length()<1,"Every bomb threatens the player's lane")
				for j in range(i):
					var gap=targets[i].distance_to(targets[j])
					assert(gap>70 and gap<235,"Cores are separated inside one compact batch")
			assert(max_depth-min_depth>1,"Batch has front-to-back variation")
	seed(712)
	var choices=[]
	for attempt in 40:
		boss.attack={};boss.aiRest=0;boss.moveIndex=0
		game.e_ai.saint_intent(boss,hero)
		choices.append(boss.attack.type)
	assert("saintVolley" in choices and "furnaceBlast" in choices,"Attack choice is random even with the same move index")
	for i in range(2,choices.size()):
		assert(choices.slice(i-2,i+1)!=["furnaceBlast","furnaceBlast","furnaceBlast"],"Never three fire blasts in a row")
	boss.attack={};boss.aiRest=0;boss.fire_streak=2
	game.e_ai.saint_intent(boss,hero)
	assert(boss.attack.type=="saintVolley" and boss.fire_streak==0,"Two fire blasts force a bomb attack and reset the streak")
	assert(choices[0]==choices[1] or range(1,choices.size()).any(func(i):return choices[i]==choices[i-1]),"Random choice allows consecutive repeats")
	boss.attack={}
	for second_phase in [false,true]:
		boss.phaseTwo=second_phase
		for attack in [{"type":"slash","damage":99,"direction":1},{"type":"clinker","reflected":true,"area_blast":true,"damage":99,"direction":1}]:
			game.damage(boss,attack,hero)
			assert(boss.hp==120,"Armor rejects melee and nearby explosions in both phases")
		assert(hero.hurtTicks>0,"Melee recoils against armor")
		boss.attack={};boss.x=720
		assert(game.m.begin(boss,"saintVolley"))
		var volley=boss.attack
		combat.step_saint_volley(game,boss,volley)
		assert(combat.hazards.is_empty())
		for shot in (3 if second_phase else 2):
			hero.x=300 if shot%2==0 else 1200
			volley.age=volley.from+shot*combat.SAINT_THROW_INTERVAL
			combat.step_saint_volley(game,boss,volley)
			assert(combat.hazards.size()==shot+1,"Release exactly one core per throw")
			var released=combat.hazards.back()
			assert(boss.dir==(-1 if hero.x<boss.x else 1) and volley.direction==boss.dir)
			assert((released.target.x-released.start.x)*boss.dir>0,"Bomb travels forward from the throwing hand")
			combat.step_saint_volley(game,boss,volley)
			assert(combat.hazards.size()==shot+1,"No duplicate release on repeated tick")
		assert(combat.hazards.size()==(3 if second_phase else 2))
		for bomb in combat.hazards:
			assert(bomb.life==combat.SAINT_BOMB_FUSE and combat.bomb_height(bomb)==325*boss.size)
			assert(bomb.target.x>=110 and bomb.target.x<=1330)
		combat.clear()
		boss.attack={}
	for second_phase in [false,true]:
		boss.phaseTwo=second_phase
		game.damage(boss,{"magic":true,"continuous":true,"damage":.12,"direction":1},hero)
		assert(boss.hp<120 and boss.electricTicks>0,"Lightning penetrates furnace armor in both phases")
		boss.hp=120
	game.damage(boss,{"type":"clinker","reflected":true,"direct_bomb":true,"area_blast":true,"damage":10.0,"direction":1},hero)
	assert(is_equal_approx(120-boss.hp,10.0*1.4*1.25*game.damage_multiplier*game.difficulty_damage(false)),"Direct bomb damage to Saint is increased by 40 percent")
	boss.hp=120;boss.down={};boss.invTicks=0
	boss.hurtTicks=0;boss.attack={};boss.dir=-1;boss.x=1040;hero.x=670
	boss.phaseTwo=false
	hero.hurtTicks=0;hero.recovering=0;hero.down={};hero.attack={}
	# Return a bomb during its extended fuse; swept contact must tag this boss.
	var bomb={"kind":"clinker","owner":boss,"p":Vector2(730,690),"start":Vector2(1040,690),"target":Vector2(730,690),"age":.50,"life":combat.SAINT_BOMB_FUSE,"reflected":false,"velocity":Vector2.ZERO,"strikes":[]}
	combat.strike_bomb(game,bomb,{"type":"slash","direction":1})
	combat.hazards=[bomb]
	for i in 18:combat.step(game,1.0/60)
	assert(boss.hp<120,"A returned bomb must reach and damage the Saint before its fuse expires")
	assert(bomb.get("direct_target",-1)==boss.id)
	assert(combat.avoid_bombs(game,boss)==null)
	combat.clear()
	boss.hp=120;boss.down={};boss.hurtTicks=0;boss.recovering=0;boss.invTicks=0;boss.attack={}
	assert(game.m.begin(boss,"furnaceBlast"))
	for facing in [-1,1]:
		boss.x=1040 if facing==-1 else 400
		boss.attack.direction=facing
		hero.x=boss.x+facing*700;hero.y=boss.y;hero.height=0
		hero.hp=100;hero.down={};hero.invTicks=0;hero.attack={}
		boss.attack.age=65
		combat.step_furnace(game,boss,boss.attack)
		assert(hero.hp==100,"Warning must not hurt")
		boss.attack.age=95
		combat.step_furnace(game,boss,boss.attack)
		assert(hero.hp<100,"Full room column damages in both directions")
		hero.hp=100;hero.invTicks=0;hero.down={};hero.y=boss.y-100
		combat.step_furnace(game,boss,boss.attack)
		assert(hero.hp==100,"Stepping out of the lane avoids the flame")
		boss.attack.age=139;hero.y=boss.y
		combat.step_furnace(game,boss,boss.attack)
		assert(hero.hp==100,"The visual tail and damage end together")
	if "--saint-capture" in OS.get_cmdline_user_args():
		game.hit_stop=0;game.bomb_hit_pause=0;game.shake=0
		boss.x=1040;boss.y=690;boss.dir=-1
		hero.x=540;hero.y=720;hero.hurtTicks=0;hero.recovering=0;hero.down={}
		for type in ["saintVolley","furnaceBlast"]:
			boss.attack={};game.m.begin(boss,type)
			for age in ([15,35,46,70] if type=="saintVolley" else [30,50,95,135]):
				boss.attack.age=age
				if type=="saintVolley":combat.step_saint_volley(game,boss,boss.attack)
				game._process(0)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("E:/Cairn-build-tools/saint-%s-%d.png"%[type,age])
		boss.attack={};boss.moving=true
		for frame in 8:
			boss.stride=frame/8.0
			game._process(0)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/saint-walk-%d.png"%frame)
	boss.hp=0
	combat.sync_views(game)
	assert(combat.furnace_views.is_empty(),"Death removes the flame and light")
	combat.clear()
	game.queue_free()
	await process_frame
	print("CAIRN_SAINT_OK: armor, direct bomb return, phase volleys, flame warning/damage/escape and cleanup")
	quit()
