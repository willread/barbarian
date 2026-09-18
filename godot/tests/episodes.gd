extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for episode in [2,3]:
		var kind="witch" if episode==2 else "bearer"
		var boss="king" if episode==2 else "saint"
		for run in 150:
			var waves=game.e_ai.plan(episode)
			assert(waves.size()==13 and waves[12]==[boss])
			assert(kind in waves[0],"Episode regular must join the opening encounter")
			for i in 12:
				assert(waves[i].size()<=(i+2 if i<3 else 9))
				assert(waves[i].count(kind)<=2)
				if i<6:assert(game.e_ai.wave_variants[i].is_empty())
		game.menu_action("EP 2: THE SUNKEN WILDS" if episode==2 else "EP 3: THE ASHEN DEPTHS")
		assert(game.current_episode==episode and game.difficulty_select)
		game.menu_action("NORMAL")
		assert(game.phase=="playing")
		for area in 4:
			game.wave=area*3+1
			game.spawn_wave()
			assert(game.background.key==("swamp-" if episode==2 else "ashen-")+str(area+1))
			assert(game.background.get_children().any(func(n):return n is CanvasItem and n.z_index>=1805),"Foreground scenery or atmosphere must cover the arena")
		game.wave=13
		game.spawn_wave()
		assert(game.enemies.size()==1 and game.enemies[0].kind==boss and game.enemies[0].boss)
		var b=game.enemies[0]
		b.hp=b.max*.49
		game.e_ai.intent(b,game.hero,true)
		assert(b.phaseTwo and game.e_ai.boss_open(b))
		var p=game.art.pose(b)
		assert(game.art.texture(game.art.layout(p).cel.file)!=null)
	# Shared movement: mire affects both sides, airborne actors clear it.
	var owner=game.make_actor(400,670,9)
	owner.kind="witch"
	game.enemies=[owner]
	var combat=game.episode_combat
	combat.hazards=[{"kind":"mire","owner":owner,"p":Vector2(720,670),"age":0.0,"life":5.0}]
	for actor in [game.hero,owner]:
		actor.x=730.;actor.y=670.;actor.height=0.;actor.down={}
		combat.movement(actor,Vector2(720,670))
		assert(is_equal_approx(actor.x,721.0) and actor.mired)
		actor.x=730.;actor.height=30.
		combat.movement(actor,Vector2(720,670))
		assert(actor.x==730. and not actor.mired)
	owner.hp=0
	combat.step(game,.01)
	assert(combat.hazards.is_empty(),"Witch death removes every mire")
	combat.clear()
	owner.hp=9;owner.height=0;owner.x=400
	game.hero.height=0;game.hero.down={};game.hero.x=720;game.hero.y=670
	game.m.begin(owner,"mireCast")
	owner.attack.target=Vector2(720,670)
	owner.attack.age=51
	combat.step(game,.01)
	assert(combat.hazards.is_empty(),"Warning must precede active mire")
	game.m.interrupt_attack(owner)
	combat.step(game,.01)
	assert(combat.hazards.is_empty(),"Interrupted cast must not spawn a patch")
	owner.kind="bearer"
	game.m.begin(owner,"clinkerThrow")
	owner.attack.target=Vector2(780,670)
	owner.attack.age=owner.attack.from
	combat.step(game,.01)
	assert(combat.hazards.size()==1)
	owner.attack={}
	var clinker=combat.hazards[0]
	clinker.age=.7
	game.hero.dir=1
	game.hero.attack={"type":"charge","age":10,"from":8,"to":16,"reach":60,"direction":1}
	combat.step(game,.01)
	assert(clinker.reflected and clinker.velocity.x>=1100)
	game.hero.attack={}
	owner.x=clinker.p.x+clinker.velocity.x*.03
	var hp=owner.hp
	combat.step(game,.03)
	assert(owner.hp<hp,"Reflected clinker must hurt enemies")
	combat.clear()
	# Exercise real tick order, AI cooldowns, attack events and hazard lifecycle.
	for kind in ["witch","bearer","king","saint"]:
		game.current_episode=2 if kind in ["witch","king"] else 3
		game.start_game()
		game.transition=-1;game.stage_walk=""
		game.pending_enemies.clear()
		game.enemies.clear()
		var e=game.make_actor(1000,680,game.e_ai.roster[kind].hp)
		e.kind=kind;e.boss=kind in ["king","saint"]
		game.enemies.append(e)
		game.hero.x=720;game.hero.y=680
		var seen=[]
		var attacks_seen=[]
		for tick in 440:
			game.hero.invTicks=100
			game.tick(game.m.STEP)
			if not e.attack.is_empty() and e.attack.type not in attacks_seen:attacks_seen.append(e.attack.type)
			for hazard in combat.hazards:
				if hazard.kind not in seen:seen.append(hazard.kind)
		if kind=="saint":assert(not attacks_seen.is_empty() and attacks_seen.all(func(type):return type in ["furnaceBlast","saintVolley"]),"Saint randomly selects from his two attacks")
		else:assert(("mire" if kind=="witch" else "root" if kind=="king" else "clinker") in seen,"AI must actually emit its mechanic: "+kind)
	combat.clear()
	print("CAIRN_EPISODES_OK: 300 generated runs, selection, all areas, bosses, art, mire cancellation and clinker reflection")
	game.queue_free()
	await process_frame
	quit()
