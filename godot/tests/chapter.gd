extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.menu_action("BEGIN")
	await create_timer(.6).timeout
	assert(game.chapter_select and game.phase=="title")
	assert(game.menu.items.size()==4)
	assert(game.menu.items[1].node.modulate.a<1.0)
	assert(game.menu.items[1].face.material==null)
	var sounds=[]
	game.menu.sound_requested.connect(func(id):sounds.append(id))
	game.menu.select(1,false)
	game.menu.activate()
	assert(sounds.back()=="resist")
	assert(game.phase=="title" and game.chapter_select)
	game.menu_action("BACK")
	await create_timer(.6).timeout
	assert(not game.chapter_select and game.menu.items[0].label=="BEGIN")
	game.menu_action("BEGIN")
	await create_timer(.6).timeout
	game.menu_action("EP 1: THE FALLEN CITADEL")
	assert(game.phase=="playing" and game.background.key=="citadel-1")
	game.set_process(false)
	assert(game.scale==Vector2.ONE and game.position.x==0)
	assert(absf(game.position.y+810*(1.0-float(game.background.screen.get("framing",{}).get("bottom_crop",0.0)))-(game.screen_size.y-252*game.hud.scale.y))<1)
	for pair in [[1,1],[2,1],[3,1],[4,2],[5,2],[6,2],[7,3],[8,3],[9,3],[10,4],[11,4],[12,4],[13,4]]:
		game.wave=pair[0]
		game.spawn_wave()
		assert(game.background.key=="citadel-%d"%pair[1])
		var f={"x":720.0,"y":0.0}
		game.background.constrain(f)
		assert(f.y>480 and f.y<620)
		f.y=1000
		game.background.constrain(f)
		assert(f.y>630 and f.y<780)
		assert(game.background.layers.size()==2)
		var expected=game.encounters[game.wave-1].size()
		var spawned=game.enemies.size()
		for tick in 30:
			for enemy in game.enemies:enemy.hp=0
			game.step_reinforcements(4.0)
			spawned=game.enemies.size()
			if game.pending_enemies.is_empty():break
		assert(game.pending_enemies.is_empty() and spawned==expected)
	assert(game.enemies.size()==1 and game.enemies[0].boss)
	for area in [2,3,4]:
		game.wave=(area-1)*3+1
		game.enemies.clear()
		game.pending_enemies=["shield","shield","shield","shield"]
		for attempt in 4:game.spawn_encounter_enemy()
		assert(game.enemies.size()==area-1)
		game.reinforcement_wait=0
		game.step_reinforcements(5.0)
		assert(game.enemies.size()==area-1)
		game.enemies[0].hp=0
		game.step_reinforcements(5.0)
		assert(game.enemies.filter(func(enemy):return enemy.hp>0).size()==area-1)
	for run in 300:
		var encounters=game.e_ai.plan()
		var seen=[]
		for encounter in encounters:
			for kind in encounter:
				if kind not in seen:seen.append(kind)
		for kind in ["bone","legion","shield","archer","marauder","champion"]:assert(kind in seen)
	game.wave=10
	game.enemies.clear()
	game.pending_enemies=["bone","bone","bone","bone","bone","bone"]
	for attempt in 6:game.spawn_encounter_enemy()
	assert(game.enemies.size()==3 and game.pending_enemies.size()==3)
	game.step_reinforcements(10.)
	assert(game.enemies.size()==3)
	game.enemies[0].hp=0
	game.step_reinforcements(10.)
	assert(game.enemies.size()==4 and game.pending_enemies.size()==2)
	print("CAIRN_CHAPTER_OK: selection, locked chapters, ordered screens, walk limits and final boss")
	quit()
