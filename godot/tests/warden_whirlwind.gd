extends SceneTree
func _init():
	var art=CairnArt.new()
	var m=CairnMechanics.new(art.data.attacks)
	var ai=CairnEnemies.new(m,art.data.roster)
	var boss=m.make(2,1299,740,100)
	boss.kind="champion";boss.boss=true
	assert(not art.has_separate_weapon(boss),"Warden axe is painted into the body frames")
	assert(art.data.atlases["enemy-champion-v1"].cels.size()==16)
	for cel in art.data.atlases["enemy-champion-v1"].cels:
		assert(cel.file.begins_with("iron-warden-v1-") and art.texture(cel.file)!=null)
	assert(m.begin(boss,"wardenWhirlwind"))
	boss.attack.travel=Vector2(9,6)
	var origin=Vector2(boss.x,boss.y)
	ai.motion(boss)
	assert(Vector2(boss.x,boss.y)==origin,"Wind-up stays planted")
	boss.attack.age=boss.attack.from
	ai.motion(boss)
	assert(boss.attack.travel.x<0 and boss.attack.travel.y<0,"Both walls reflect travel")
	var hero=m.make(1,boss.x-70,boss.y,100,true)
	var enemy=m.make(3,boss.x+70,boss.y,20)
	var hits=[]
	var hit=func(target,strike,attacker):
		hits.append(target.id)
		assert(strike.knock and strike.damage==8 and strike.push==4.8)
		assert(strike.direction==sign(target.x-attacker.x))
		target.hp-=strike.damage
		m.hurt(target,strike)
	m.tick_attack(boss,[hero,enemy],hit)
	assert(hits==[1,3] and not hero.down.is_empty() and not enemy.down.is_empty(),"Whirlwind knocks away both sides and enemy allies")
	hero.down={};enemy.down={}
	m.tick_attack(boss,[hero,enemy],hit)
	assert(hits.size()==2,"No repeated hits within one whirlwind")
	for i in 170:
		ai.motion(boss)
		m.tick_attack(boss,[],hit)
		assert(boss.x>=140 and boss.x<=1300 and boss.y>=m.lane_min+12 and boss.y<=m.lane_max-12)
	boss.attack.age=boss.attack.to+1
	origin=Vector2(boss.x,boss.y)
	ai.motion(boss)
	assert(Vector2(boss.x,boss.y)==origin and art.enemy_frame(boss)==10,"Recovery stops movement and shows exhaustion")
	ai.finish(boss,boss.attack,hero)
	assert(boss.aiRest==24)
	print("CAIRN_WARDEN_WHIRLWIND_OK: warning, ricochets, friendly fire, outward knockback, single hits and recovery")
	call_deferred("check_game")
func check_game():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	game.start_game();game.transition=-1;game.stage_walk=""
	game.pending_enemies.clear()
	game.hero=game.m.make(1,720,700,100,true)
	game.m.begin(game.hero,"spin")
	var boss=game.make_actor(800,700,100)
	boss.kind="champion";boss.boss=true
	var bystander=game.make_actor(870,700,100)
	bystander.kind="bone"
	game.enemies=[boss,bystander]
	game.m.begin(boss,"wardenWhirlwind")
	boss.attack.travel=Vector2(-9,-3)
	boss.attack.age=boss.attack.from
	game.tick(game.m.STEP)
	assert(game.hero.hp<100 and not game.hero.down.is_empty(),"Real gameplay whirlwind damages and interrupts player spin")
	assert(bystander.hp<100 and not bystander.down.is_empty(),"Game loop includes enemy bystanders")
	game.queue_free();await process_frame
	print("CAIRN_WARDEN_GAMEPLAY_OK: real damage, player spin interruption and enemy knockdown")
	quit()
