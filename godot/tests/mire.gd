extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.current_episode=2
	game.start_game()
	game.transition=-1;game.stage_walk=""
	game.enemies.clear();game.pending_enemies.clear()
	var hag=game.make_actor(1030,680,9)
	hag.kind="witch"
	game.enemies=[hag]
	game.hero.x=720;game.hero.y=680
	var combat=game.episode_combat
	var patch={"kind":"mire","owner":hag,"p":Vector2(720,680),"age":.5,"life":5.0}
	combat.hazards=[patch]
	# Full player-motion comparison: the slow must be observable in real ticks.
	game.hero.invTicks=9999
	game.keys[KEY_D]=true
	for i in 12:game.tick(game.m.STEP)
	var bog_distance=game.hero.x-720
	assert(game.hero.mired and bog_distance>0)
	combat.clear()
	game.hero.x=720
	for i in 12:game.tick(game.m.STEP)
	assert(game.hero.x-720>bog_distance*3,"Mire must materially reduce real movement")
	# Overlapping pools do not compound into a movement lock.
	combat.hazards=[patch,patch.duplicate()]
	game.hero.x=730
	combat.movement(game.hero,Vector2(720,680))
	assert(is_equal_approx(game.hero.x,722.8))
	# Corners outside the oval are free even inside its bounding rectangle.
	game.hero.x=900;game.hero.y=734
	combat.movement(game.hero,Vector2(890,734))
	assert(game.hero.x==900 and not game.hero.mired)
	game.hero.x=730;game.hero.y=680;game.hero.height=30
	combat.movement(game.hero,Vector2(720,680))
	assert(game.hero.x==730 and not game.hero.mired)
	game.hero.height=0
	combat.hazards=[patch]
	combat.sync_views(game)
	assert(combat.mire_views.size()==1)
	var view=combat.mire_views[hag.id]
	assert(view.z_index==1361 and view.mode==1,"Hands must sort above feet at the pool center")
	var pixels=view.texture.get_image()
	assert(pixels.get_pixel(0,0).a<.01,"Effect must have real alpha, not a checkerboard")
	hag.hp=0
	combat.step(game,.01)
	assert(patch.life<patch.age+.2)
	combat.step(game,.25)
	combat.sync_views(game)
	assert(combat.hazards.is_empty() and combat.mire_views.is_empty())
	print("CAIRN_MIRE_OK: real movement, oval bounds, jump escape, no stacking, depth, alpha and death cleanup")
	game.queue_free()
	await process_frame
	quit()
