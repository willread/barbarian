extends SceneTree
func _init():check.call_deferred()
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_game()
	game.hero.x=720
	game.hero.y=660
	game.hero.hp=40
	var egg=game.drop_egg(Vector2(720,660),false)
	egg.height=0
	egg.velocity=0
	egg.advance(.01)
	assert(egg.eating and not egg.collected and game.hero.hp==40)
	egg.advance(.93)
	assert(egg.collected and game.hero.hp==65,"Regular egg restores 25% of maximum health")
	egg.advance(.1)
	assert(game.hero.hp==65,"Egg cannot heal twice")
	egg.advance(.3)
	game.hero.hp=90
	egg=game.drop_egg(Vector2(720,660),false)
	egg.height=0
	egg.velocity=0
	egg.advance(.01)
	egg.advance(.93)
	assert(game.hero.hp==100)
	egg.advance(.3)
	game.combo.reset()
	egg=game.drop_egg(Vector2(720,660),true)
	egg.height=0
	egg.velocity=0
	egg.advance(.01)
	egg.advance(.93)
	assert(game.combo.multiplier()==10 and game.combo.hits==0 and game.combo.remaining==5)
	assert(game.run_stats.peak_multiplier==10 and game.run_stats.best_combo==0)
	egg.advance(.3)
	game.combo.suspend()
	game.combo.advance(10.)
	assert(game.combo.multiplier()==10)
	game.combo.resume()
	game.combo.hit()
	assert(game.combo.multiplier()==10 and game.combo.hits==1)
	game.combo.advance(5.)
	assert(game.combo.multiplier()==1)
	game.combo.golden_egg()
	game.combo.reset()
	assert(game.combo.multiplier()==1)
	game.clear_eggs()
	game.wave=2
	game.wave_time=6
	game.step_chicken(.01)
	game.chicken.lay=0.
	game.chicken.egg_check=10.
	var before=game.eggs.size()
	game.step_chicken(.33)
	assert(game.eggs.size()==before+1 and game.chicken.egg_count==1)
	game.step_chicken(.1)
	assert(game.eggs.size()==before+1,"Laying animation spawns exactly one egg")
	game.remove_chicken()
	assert(not game.eggs.is_empty(),"Eggs remain after chicken leaves")
	game.clear_eggs()
	assert(game.eggs.is_empty())
	game.queue_free()
	await process_frame
	await process_frame
	print("CAIRN_EGGS_OK: healing, cap, single collection, golden timer without fake hits, laying and cleanup")
	quit()
