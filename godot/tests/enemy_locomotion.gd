extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	game.start_game();game.transition=-1;game.stage_walk=""
	game.pending_enemies.clear()
	game.hero.x=1150;game.hero.y=660
	var left=game.make_actor(500,660,100)
	var right=game.make_actor(500,660,100)
	left.aiRest=120;right.aiRest=120
	game.enemies=[left,right]
	game.tick(game.m.STEP)
	assert(left.x<500 and right.x>500,"Overlapping idle enemies separate")
	for actor in [left,right]:
		assert(actor.moving and actor.stride>0,"Crowd corrections advance walking instead of sliding in idle")
		assert(game.art.enemy_frame(actor) in [1,2,3,4])
	game.tick(game.m.STEP)
	assert(not left.moving and not right.moving,"Settled actors stop walking")
	var enemy=game.make_actor(720,660,100)
	enemy.kind="shield";enemy.turnTicks=10;enemy.brace=10
	game.e_ai.update_locomotion(enemy,Vector2(30,0))
	assert(game.art.enemy_frame(enemy)!=15,"Repositioning must not slide in the planted guard pose")
	var stride=enemy.stride
	game.e_ai.update_locomotion(enemy,Vector2.ZERO)
	assert(not enemy.moving and enemy.stride==stride,"Blocked movement does not treadmill")
	assert(game.art.enemy_frame(enemy)==15,"A stationary guard retains its authored pose")
	enemy.hurtTicks=10
	game.e_ai.update_locomotion(enemy,Vector2(20,0))
	assert(not enemy.moving and game.art.enemy_frame(enemy)==11,"Knockback retains the hurt pose")
	enemy.hurtTicks=0;enemy.brace=0
	game.episode_combat.hazards=[{"kind":"clinker","landed":true,"age":1.0,"life":3.0,"p":Vector2(720,660),"target":Vector2(720,660),"velocity":Vector2.ZERO,"reflected":false}]
	var escape=game.episode_combat.avoid_bombs(game,enemy)
	assert(escape!=null and escape.length()>0)
	assert(enemy.turnTicks==0,"Bomb escape clears a frozen turn pose")
	game.e_ai.update_locomotion(enemy,escape*5)
	assert(enemy.moving)
	var saint=game.make_actor(900,660,100)
	saint.kind="saint";saint.dir=1
	game.e_ai.update_locomotion(saint,Vector2(-22,0))
	assert(is_equal_approx(saint.stride,.9),"Saint backsteps preserve reverse distance-based animation")
	game.queue_free();await process_frame
	print("CAIRN_LOCOMOTION_OK: crowd steps, blocked feet, guarded turns, reactions and bomb escape")
	quit()
