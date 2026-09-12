extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.menu_action("BEGIN")
	await create_timer(.6).timeout
	assert(game.chapter_select and game.phase=="title")
	assert(game.menu.items.size()==4)
	game.menu.select(1,false)
	game.menu.activate()
	assert(game.phase=="title" and game.chapter_select)
	game.menu_action("BACK")
	await create_timer(.6).timeout
	assert(not game.chapter_select and game.menu.items[0].label=="BEGIN")
	game.menu_action("BEGIN")
	await create_timer(.6).timeout
	game.menu_action("THE FALLEN CITADEL")
	assert(game.phase=="playing" and game.background.key=="citadel-1")
	game.set_process(false)
	for pair in [[1,1],[2,1],[3,2],[4,2],[5,3],[6,3],[7,4],[8,4],[9,4]]:
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
	assert(game.enemies.size()==1 and game.enemies[0].boss)
	print("CAIRN_CHAPTER_OK: selection, locked chapters, ordered screens, walk limits and final boss")
	quit()
