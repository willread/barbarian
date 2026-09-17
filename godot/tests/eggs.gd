extends SceneTree
func _init():check.call_deferred()
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_game()
	game.weapon_day="2026-04-04"
	game.hero.x=720
	game.hero.y=660
	game.hero.hp=40
	var egg=game.drop_egg(Vector2(720,660),false)
	assert(egg.fire==null,"Regular eggs have no flames")
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
	assert(egg.fire!=null and egg.fire.yellow_palette and egg.fire.menu_palette)
	assert(egg.fire.position==Vector2(0,-egg.height-16))
	egg.height=0
	egg.velocity=0
	egg.advance(.01)
	egg.advance(.93)
	assert(game.combo.multiplier()==10 and game.combo.hits==0 and game.combo.remaining==5)
	assert(not egg.fire.visible,"Flames disappear when the egg is consumed")
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
	var calendar=preload("res://scripts/seasonal_calendar.gd")
	for date in ["1818-03-22","2025-04-20","2026-04-05","2027-03-28","2028-04-16","2038-04-25"]:
		assert(calendar.is_easter(date),"Easter must follow the Gregorian calendar: "+date)
	assert(not calendar.is_easter("2026-04-04") and not calendar.is_easter("2026-04-06"))
	assert(is_equal_approx(game.egg_lay_chance(),.21) and game.egg_lay_limit()==2)
	game.weapon_day="2026-04-05"
	assert(is_equal_approx(game.egg_lay_chance(),.21*3) and game.egg_lay_limit()==6)
	egg=game.drop_egg(Vector2(900,660),false)
	assert(egg.easter and egg.shell!=null and egg.material==null and egg.fire==null,"Easter eggs use painted shells without sparkles or glow")
	game.hero.hp=40
	egg.position=Vector2(720,660);egg.height=0;egg.velocity=0
	egg.advance(.01);egg.advance(.93)
	assert(game.hero.hp==65,"Decorated egg retains normal healing")
	egg=game.drop_egg(Vector2(1000,660),true)
	assert(egg.golden and egg.shell.resource_path.ends_with("easter-eggs-v1-2.png") and egg.fire!=null,"Golden Easter eggs retain their flames")
	assert(egg.fire.yellow_palette and egg.fire.menu_palette)
	egg.advance(.3)
	game.hero.pickup={}
	egg.position=Vector2(720,660);egg.height=0;egg.velocity=0
	egg.advance(.01);egg.advance(.93)
	assert(game.combo.multiplier()==10,"Painted golden egg retains its bonus")
	game.clear_eggs()
	game.weapon_day="2026-04-06"
	egg=game.drop_egg(Vector2(900,660),false)
	assert(not egg.easter and egg.shell==null,"Ordinary shells return after Easter")
	game.enable_easter_session()
	assert(egg.easter and egg.shell!=null and game.easter_active(),"Cheat updates existing eggs")
	for i in 20:
		egg=game.drop_egg(Vector2(900,660),false)
		assert(egg.shell.resource_path.ends_with("easter-eggs-v1-0.png") or egg.shell.resource_path.ends_with("easter-eggs-v1-1.png"),"Only golden eggs use the gold shell")
	game.clear_eggs()
	game.queue_free()
	await process_frame
	await process_frame
	print("CAIRN_EGGS_OK: healing, cap, single collection, golden timer without fake hits, laying and cleanup")
	quit()
