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
 assert(game.hero.hp==hp,"Contact cooldown prevents rapid repeat hits")
 # Leaving and returning to an already emerged root still hurts.
 combat.root_sequences.clear()
 game.hero.x=1100
 combat.step(game,.6)
 game.hero.x=target.x;game.hero.invTicks=0
 combat.step(game,.06)
 assert(game.hero.hp<hp,"Established roots must damage on contact")
 hp=game.hero.hp
 game.hero.invTicks=60
 combat.step(game,.7)
 assert(game.hero.hp==hp,"Invulnerability protects against contact")
 combat.clear()
 # Both phases send exactly three separately targeted roots.
 for phase in [false,true]:
  king.phaseTwo=phase;king.moveIndex=0;king.aiRest=0
  game.hero.height=100;game.hero.x=620
  game.e_ai.king_intent(king,game.hero)
  king.attack.age=king.attack.from
  combat.step(game,.01)
  king.attack={}
  assert(combat.hazards.size()==1)
  game.hero.x=820
  combat.step(game,.18)
  assert(combat.hazards.size()==2)
  var second=combat.hazards[1]
  assert(second.p.x==820 and second.age<0,"Second target warns before emerging")
  assert(second.variant!=combat.hazards[0].variant,"Consecutive silhouettes differ")
  game.hero.x=1060
  combat.step(game,.48)
  assert(combat.hazards.size()==3 and combat.hazards[2].p.x==1060)
  assert(second.p.x==820,"Warnings lock instead of following the player")
  assert(combat.root_sequences.is_empty())
  combat.step(game,.3)
  assert(game.hero.hp==hp,"High jump clears roots")
  combat.clear()
 combat.spawn_root(king,Vector2(740,670),.5)
 combat.root_sequences.append({"owner":king,"remaining":2,"wait":.1,"variant":0})
 king.hp=0
 combat.step(game,.01)
 assert(combat.hazards.is_empty() and combat.root_sequences.is_empty(),"King death clears roots and pending attacks")
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
  for i in range(4):
   combat.spawn_root(king,Vector2(300+i*260,700),.5)
   var h=combat.hazards.back()
   h.variant=i
   var t=preload("res://scripts/king_roots.gd").TEXTURES[i]
   var height=[135,265,215,245][i]
   h.size=Vector2(float(height)*t.get_width()/t.get_height(),height)
  game._process(0)
  await create_timer(.3).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/king-polish.png")
 game.queue_free()
 await process_frame
 print("CAIRN_KING_POLISH_OK: locked tells, timed damage, jump escape, phase two, death cleanup, recovery and eight strides")
 quit()
