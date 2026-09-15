extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.current_episode=2
 game.start_game()
 game.set_process(false)
 game.wave=13
 game.spawn_wave()
 game.transition=-1
 var king=game.enemies[0]
 king.x=910;king.y=670;king.aiRest=0
 game.hero.x=620;game.hero.y=670;game.hero.invTicks=0
 var combat=game.episode_combat
 game.e_ai.king_intent(king,game.hero)
 assert(king.attack.type=="rootSlam")
 var target=king.attack.target
 game.hero.x=640
 assert(king.attack.target==target,"Slam must not track after commitment")
 king.attack.age=king.attack.from
 combat.step(game,.01)
 king.attack={}
 assert(combat.hazards.size()==1)
 var hp=game.hero.hp
 combat.step(game,.10)
 assert(game.hero.hp==hp,"Roots must not damage during emergence")
 combat.step(game,.09)
 assert(game.hero.hp<hp,"Visible eruption must damage a grounded player")
 hp=game.hero.hp
 game.hero.invTicks=0
 combat.step(game,.1)
 assert(game.hero.hp==hp,"One eruption cannot hit repeatedly")
 combat.clear()
 king.phaseTwo=true;king.moveIndex=0;king.aiRest=0
 game.hero.height=40
 game.e_ai.king_intent(king,game.hero)
 king.attack.age=king.attack.from
 combat.step(game,.01)
 king.attack={}
 assert(combat.hazards.size()==3,"Phase two adds staggered roots")
 combat.step(game,.6)
 assert(game.hero.hp==hp,"Jump clears roots")
 king.hp=0
 combat.step(game,.01)
 assert(combat.hazards.is_empty(),"King death clears all roots")
 king.hp=65;king.phaseTwo=false;king.aiRest=0;king.moveIndex=1
 game.hero.height=0;game.hero.x=740
 game.e_ai.king_intent(king,game.hero)
 assert(king.attack.type=="kingSweep")
 king.attack.age=king.attack.from+12
 assert(game.e_ai.boss_open(king),"Follow through must expose King")
 assert(game.art.pose(king)==["king-attacks",3])
 king.attack={};king.moving=true
 for frame in range(8):
  king.stride=frame/8.0
  assert(game.art.pose(king)==["king-walk",frame])
 if "--king-capture" in OS.get_cmdline_user_args():
  king.moving=false;game.hero.invTicks=0;game.hero.hurtTicks=0;game.hero.recovering=0;game.hero.recoil=0
  game.menu.visible=false
  game.m.begin(king,"rootSlam");king.attack.target=Vector2(740,670);king.attack.age=44
  game._process(0)
  await create_timer(.3).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/king-polish.png")
 game.queue_free()
 await process_frame
 print("CAIRN_KING_POLISH_OK: locked tells, timed damage, jump escape, phase two, death cleanup, recovery and eight strides")
 quit()
