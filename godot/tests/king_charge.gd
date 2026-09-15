extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate();root.add_child(game)
 game.current_episode=2;game.start_game();game.set_process(false);game.wave=13;game.spawn_wave()
 var king=game.enemies[0]
 for direction in [1,-1]:
  king.x=350 if direction==1 else 1090;king.y=670;king.attack={};king.aiRest=999
  king.corner_ticks=0;king.escape_cooldown=0;king.hp=65;king.phaseTwo=false
  game.hero.x=king.x+direction*160;game.hero.y=670;game.hero.height=0;game.hero.invTicks=0;game.hero.down={};game.hero.hp=100
  for tick in 149:game.e_ai.king_intent(king,game.hero)
  assert(king.attack.is_empty(),"Brief corner pressure does not trigger an escape")
  king.hurtTicks=10;king.recovering=45
  game.e_ai.king_intent(king,game.hero)
  assert(king.attack.type=="kingCharge" and king.attack.direction==direction)
  assert(not game.e_ai.boss_open(king))
  var a=king.attack;var origin=king.x
  for age in range(a.from):
   a.age=age;game.episode_combat.step(game,1.0/60)
  assert(king.x==origin and game.hero.hp==100,"Roar windup locks position and does not damage")
  for age in range(a.from,110):
   a.age=age;game.episode_combat.step(game,1.0/60)
  assert(a.arrived and absf(king.x-a.target.x)<1,"Escape reaches the far side without leaving the arena")
  assert(game.hero.hp<85 and not game.hero.down.is_empty(),"Charge causes heavy damage and knockdown")
  assert(absf(game.hero.down.vx)==7 and a.charge_hit)
  assert(game.e_ai.boss_open(king),"King is exposed after the escape")
  var hp=game.hero.hp
  game.hero.invTicks=0;game.hero.down={};game.hero.x=king.x
  game.episode_combat.step(game,.1)
  assert(game.hero.hp==hp,"One charge cannot hit twice")
  king.attack={};king.corner_ticks=240;king.x=180;game.hero.x=300;king.aiRest=999
  game.e_ai.king_intent(king,game.hero)
  assert(king.attack.is_empty(),"Escape cooldown prevents spam")
 # Exercise real AI, attack completion and recovery scheduling, not just direct intent calls.
 king.x=350;king.y=670;king.hp=65;king.attack={};king.aiRest=0;king.hurtTicks=0;king.recovering=0;king.escape_cooldown=0;king.corner_ticks=0
 game.hero.x=520;game.hero.y=670;game.hero.hp=100;game.hero.invTicks=9999;game.hero.down={};game.hero.height=0
 game.stage_walk="";game.transition=-1;game.phase="playing"
 var charged=false
 for tick in 600:
  game.tick(1.0/60)
  if king.attack.get("type","")=="kingCharge":charged=true
  if charged and king.x>1100:break
 assert(charged and king.x>1100,"Normal combat loop must trigger and complete a corner escape")
 for depth in [-60,-45,45,60]:
  game.episode_combat.clear()
  game.hero.x=700;game.hero.y=670+depth;game.hero.height=0;game.hero.hp=100;game.hero.invTicks=0;game.hero.down={}
  king.attack={}
  game.episode_combat.spawn_root(king,Vector2(700,670),.5)
  game.episode_combat.step(game,.01)
  assert((game.hero.hp<100)==(abs(depth)<52),"Root depth includes nearby feet but preserves a dodge outside its footprint")
 game.queue_free();await process_frame;await create_timer(.15).timeout
 print("CAIRN_KING_CHARGE_OK: sustained pressure, warning, both directions, swept hit, knockdown, recovery and cooldown")
 quit()
