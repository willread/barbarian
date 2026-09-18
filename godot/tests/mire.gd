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
	assert(game.hero.x-720>bog_distance*8,"Mire must heavily reduce real movement")
	# Overlapping pools do not compound into a movement lock.
	combat.hazards=[patch,patch.duplicate()]
	game.hero.x=730
	combat.movement(game.hero,Vector2(720,680))
	assert(is_equal_approx(game.hero.x,721.0))
	# Corners outside the oval are free even inside its bounding rectangle.
	game.hero.x=900;game.hero.y=734
	combat.movement(game.hero,Vector2(890,734))
	assert(game.hero.x==900 and not game.hero.mired)
	game.hero.x=730;game.hero.y=680;game.hero.height=30
	combat.movement(game.hero,Vector2(720,680))
	assert(game.hero.x==730 and not game.hero.mired)
	game.hero.height=0
	hag.attack={}
	combat.hazards=[patch]
	combat.sync_views(game)
	assert(combat.mire_views.size()==1)
	var view=combat.mire_views[combat.mire_id(patch)]
	assert(view.spots.size() in [3,4] and view.layers.size()==view.spots.size()*2)
	assert(view.DRAW_RECT.size==Vector2(144,130))
	for i in view.layers.size():
		assert(not view.layers[i].z_as_relative)
		if i%2==0:assert(view.layers[i].z_index==-4)
	for spot in view.spots:
		assert(combat.MireLayout.contains(patch.p,patch.p+spot.offset))
	var pixels=view.texture.get_image()
	assert(pixels.get_pixel(0,0).a<.01,"Effect must have real alpha, not a checkerboard")
	game.hero.x=720;game.hero.y=680;game.hero.hp=100
	game.hero.attack={"type":"slash","age":1,"to":12}
	var hp=game.hero.hp
	combat.mire_exposure=0
	var per_second=2.2*game.damage_multiplier*100./48.+game.damage_multiplier/.65
	for i in 59:combat.step(game,1.0/60)
	assert(game.hero.hp==hp,"Health holds steady between mire pulses")
	combat.step(game,1.0/60)
	assert(is_equal_approx(game.hero.hp,hp-per_second),"First real hit after one second")
	assert(game.hero.hurtTicks>0 and game.hero.recoil>0 and game.shake>0,"Puddle hits trigger normal stun, recoil and impact shake")
	assert(game.hero.attack.is_empty(),"Puddle hit interrupts an attack")
	var first_pulse=game.hero.hp
	for i in 59:combat.step(game,1.0/60)
	assert(game.hero.hp==first_pulse,"No continuous damage between pulses")
	combat.step(game,1.0/60)
	assert(abs(game.hero.hp-(hp-per_second*2))<.01,"Pulses preserve sustained damage per second")
	assert(game.hero.hurtTicks>0 and game.hero.down.is_empty(),"Each pulse stuns without forcing knockdown")
	for i in 12:game.m.reaction(game.hero)
	assert(game.hero.hurtTicks==0,"Normal hit stun ends well before the next one-second pulse")
	# Coarse updates and overlapping patches still deliver the same pulse.
	game.hero.hp=hp;combat.mire_exposure=0
	combat.hazards=[patch,patch.duplicate()]
	combat.step(game,1.)
	assert(abs(game.hero.hp-(hp-per_second))<.01,"Frame-rate independence and no overlap stacking")
	combat.hazards=[patch];combat.mire_exposure=0
	combat.step(game,.25)
	game.hero.x=1100;combat.step(game,.01)
	game.hero.x=720
	var before_return=game.hero.hp
	combat.step(game,.25)
	assert(game.hero.hp==before_return,"Leaving clears exposure instead of carrying a surprise pulse on re-entry")
	combat.clear();assert(combat.mire_exposure==0)
	combat.hazards=[patch]
	# A jump started in the grasp has a much lower apex, even with run held.
	var trapped=game.make_actor(720,680,100,true)
	var free=game.make_actor(1100,680,100,true)
	trapped.running=true
	combat.prepare_actor(trapped);combat.prepare_actor(free)
	assert(game.m.start_jump(trapped) and game.m.start_jump(free))
	assert(not trapped.air.carry)
	var low=0.0
	var high=0.0
	for i in 60:
		game.m.motion(trapped,0,0);game.m.motion(free,0,0)
		low=maxf(low,trapped.height);high=maxf(high,free.height)
	assert(low<high*.2 and low>0,"Mire allows only a short hop")
	trapped.x=1100
	combat.prepare_actor(trapped)
	assert(trapped.mire_jump_scale==1.0,"Leaving restores normal jump strength")
	# Multiple patches keep separate render nodes; killing their owner removes all.
	var other=game.make_actor(1200,680,9)
	other.kind="witch"
	var second={"kind":"mire","owner":hag,"p":Vector2(420,680),"age":0.0,"life":8.0}
	var unrelated={"kind":"mire","owner":other,"p":Vector2(1200,680),"age":0.0,"life":8.0}
	combat.hazards=[patch,second,unrelated]
	combat.sync_views(game)
	assert(combat.mire_views.size()==3)
	hag.hp=0
	combat.step(game,.01)
	combat.sync_views(game)
	assert(combat.hazards.size()==1 and combat.hazards[0].owner==other and combat.mire_views.size()==1)
	other.hp=0
	combat.step(game,.01)
	combat.sync_views(game)
	assert(combat.hazards.is_empty() and combat.mire_views.is_empty())
	# The hag defends at close range but never pursues a distant player.
	hag.hp=9;hag.x=1030;hag.aiRest=0;hag.attack={}
	game.hero=game.make_actor(900,680,100,true)
	var intent=game.e_ai.intent(hag,game.hero,true)
	assert(intent==Vector2.ZERO and hag.attack.type=="hagClaw")
	for i in 28:game.m.tick_attack(hag,[game.hero],game.damage)
	assert(game.hero.hp<100,"Defensive claw must actually connect")
	hag.attack={};hag.aiRest=0
	game.hero.x=100
	assert(game.e_ai.intent(hag,game.hero,true)==Vector2.ZERO and hag.attack.is_empty(),"Hag must not chase")
	hag.aiRest=60;game.hero.x=hag.x-220
	assert(game.e_ai.intent(hag,game.hero,true).x>0,"Hag retreats from nearby hero")
	hag.hag_move_cooldown=0;game.hero.x=100
	assert(game.e_ai.intent(hag,game.hero,true)!=Vector2.ZERO,"Hag periodically repositions")
	combat.hazards=[patch]
	var fresh=combat.place_clump(game,hag,patch.p)
	assert(fresh==null or not combat.MireLayout.overlaps(fresh,patch.p))
	for move in ["mireCast","hagClaw"]:
		game.e_ai.finish(hag,{"type":move},game.hero)
		var duration=game.m.attacks[move].ticks
		var previous_rest=35 if move=="mireCast" else 53
		var rate=1.25 if move=="mireCast" else 1.0
		assert(absf(float(duration+previous_rest)/float(duration+hag.aiRest)-rate)<.01,"Oil casts increase 25% while claw timing stays unchanged")
	hag.attack={};hag.aiRest=0;hag.mire_count=4;hag.hag_move_ticks=20
	game.hero.x=hag.x-400;game.hero.y=hag.y
	game.e_ai.hag_intent(hag,game.hero)
	assert(hag.attack.get("type")=="mireCast","Ready hag casts a fifth clump before strolling")
	hag.attack={};hag.mire_count=5
	game.e_ai.hag_intent(hag,game.hero)
	assert(hag.attack.is_empty(),"Keep the five-clump cap")
	print("CAIRN_MIRE_OK: heavy slow, one-second damage hits with stun, limited jump, independent patches, owner death and defensive claw")
	game.queue_free()
	await process_frame
	quit()
