extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.start_game();game.set_process(false)
 game.menu.visible=false;game.transition=-1;game.stage_walk=""
 game.hero.x=650;game.hero.y=660
 var shield=game.make_actor(790,660,30)
 shield.kind="shield";shield.dir=-1
 var spin={"type":"spin","spin":true,"damage":2.0,"direction":1,"knock":true}
 for side in [1,-1]:
  shield.x=790;shield.dir=side
  var hp=shield.hp
  game.magic=0;game.combo.reset()
  game.damage(shield,spin,game.hero)
  assert(shield.hp==hp and shield.x==832,"Closed shield takes pushback only, from either side")
  assert(game.magic==0 and game.combo.hits==0)
 game.m.begin(shield,"shieldBash")
 shield.attack.age=shield.attack.from-13
 var hp=shield.hp
 game.damage(shield,spin,game.hero)
 assert(shield.hp==hp,"Guard remains closed until the visible lowering window")
 shield.attack.age+=1
 game.damage(shield,spin,game.hero)
 assert(shield.hp<hp,"Spin can punish the guard-down window")
 var target=game.make_actor(900,660,100)
 target.kind="bone"
 game.magic=0;game.combo.reset()
 game.damage(target,{"damage":1.0,"direction":1},game.hero)
 assert(is_equal_approx(game.magic,3.6),"Base mana gain reduced by exactly 40 percent")
 target.hp=.01;target.invTicks=0;target.down={}
 game.magic=0;game.combo.reset()
 game.damage(target,{"damage":1.0,"direction":1},game.hero)
 assert(is_equal_approx(game.magic,8.4),"Kill mana bonus receives the same reduction")
 for kind in ["legion","archer","witch","bearer","king","shield","bone","marauder"]:
  var probe=game.make_actor(800,660,100)
  probe.kind=kind;probe.dir=1;probe.aiRest=100;probe.entered_arena=true
  for tick in range(90):
   game.hero.x=800+(-8 if tick%2 else 8)
   game.e_ai.intent(probe,game.hero,false)
   assert(probe.dir==1,"Overlap must not shake facing: "+kind)
  assert(game.e_ai.facing_target(probe,740)==-1,"A real side change must still turn the enemy")
 game.enemies.clear()
 game.hero.x=280
 for i in range(3):
  var foe=game.make_actor(600+i*270,680,30)
  foe.kind=["legion","shield","bone"][i];foe.dir=-1
  game.enemies.append(foe)
 game._process(0)
 var minotaur=game.views[game.enemies[0].id]
 assert(is_equal_approx(minotaur.burn_material.get_shader_parameter("exposure"),1.4))
 assert(is_equal_approx(game.views[game.hero.id].burn_material.get_shader_parameter("exposure"),1.0),"Player lighting stays unchanged")
 if "--balance-capture" in OS.get_cmdline_user_args():
  await create_timer(.25).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/combat-balance.png")
 game.queue_free()
 await process_frame
 print("CAIRN_COMBAT_BALANCE_OK: shield spin window, push-only blocks, 40% mana reduction, stable facing and minotaur lighting")
 quit()
