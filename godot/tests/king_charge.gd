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
  assert(a.arrived and absf(king.x-origin)>600,"Escape reaches the far side without leaving the arena")
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
 # Aim outward as well as inward, and above/below, locking before launch.
 for offset in [Vector2(220,55),Vector2(-220,-55),Vector2(0,60)]:
  king.x=800;king.y=670;king.attack={};king.aiRest=0;king.corner_ticks=0;king.escape_cooldown=0;king.roam_charge_wait=1;king.hurtTicks=0;king.recovering=0
  game.hero.x=800+offset.x;game.hero.y=670+offset.y;game.hero.hp=100;game.hero.invTicks=0;game.hero.down={}
  game.e_ai.king_intent(king,game.hero)
  var a=king.attack
  var aim=(a.target-Vector2(800,670)).normalized()
  assert(aim.dot(offset.normalized())>.999,"Charge aims directly toward the player in both axes")
  var locked=a.target
  game.hero.x+=20
  game.e_ai.king_intent(king,game.hero)
  assert(a.target==locked,"Warning locks direction rather than homing")
  game.hero.x-=20
  for age in range(a.from,110):
   a.age=age;game.episode_combat.step(game,1.0/60)
  assert(a.arrived and game.hero.hp<100,"Diagonal and vertical charges make contact and finish")
 # Repositioning is also available in open ground, without corner pressure.
 king.x=800;king.y=670;king.attack={};king.aiRest=0;king.corner_ticks=0;king.escape_cooldown=0;king.roam_charge_wait=1
 game.hero.x=650;game.hero.y=670
 game.e_ai.king_intent(king,game.hero)
 assert(king.attack.type=="kingCharge","Periodic charge must also trigger away from corners")
 king.attack={}
 game.e_ai.finish(king,{},game.hero)
 var intent=game.e_ai.king_intent(king,game.hero)
 assert(intent.length()>0,"King steps to a new position during attack recovery")
 # Exercise real AI, attack completion and recovery scheduling, not just direct intent calls.
 king.x=350;king.y=670;king.hp=65;king.attack={};king.aiRest=0;king.hurtTicks=0;king.recovering=0;king.escape_cooldown=0;king.corner_ticks=0;king.roam_charge_wait=300
 game.hero.x=520;game.hero.y=670;game.hero.hp=100;game.hero.invTicks=9999;game.hero.down={};game.hero.height=0
 game.stage_walk="";game.transition=-1;game.phase="playing"
 var charged=false
 var completed=false
 for tick in 600:
  game.tick(1.0/60)
  if king.attack.get("type","")=="kingCharge":charged=true
  if charged and king.attack.get("arrived",false):
   completed=true
   break
 assert(charged and completed,"Normal combat loop must trigger and complete a corner escape")
 for depth in [-60,-45,45,60]:
  game.episode_combat.clear()
  game.hero.x=700;game.hero.y=670+depth;game.hero.height=0;game.hero.hp=100;game.hero.invTicks=0;game.hero.down={}
  king.attack={}
  game.episode_combat.spawn_root(king,Vector2(700,670),.5)
  game.episode_combat.step(game,.01)
  assert((game.hero.hp<100)==(abs(depth)<52),"Root depth includes nearby feet but preserves a dodge outside its footprint")
 # Phase two advances both charge timers twice as fast, including an existing wait.
 king.attack={"type":"rootSlam"};king.roam_charge_wait=400;king.escape_cooldown=300;king.phaseTwo=false;king.hp=king.max
 game.e_ai.king_intent(king,game.hero)
 assert(king.roam_charge_wait==399 and king.escape_cooldown==299)
 king.hp=king.max*.5
 game.e_ai.king_intent(king,game.hero)
 assert(king.phaseTwo and king.roam_charge_wait==397 and king.escape_cooldown==297,"Phase two doubles charge timer speed immediately")
 # King has regular depth but a broad, symmetric horizontal receiving body.
 king.attack={};king.hurtTicks=0;king.down={};king.invTicks=0;king.hp=65;king.x=760;king.y=670
 game.hero.x=700;game.hero.height=0;game.hero.dir=1
 var strike={"type":"light","reach":40,"direction":1}
 for depth in [-65,-48,-47,47,48,65]:
  game.hero.y=670+depth
  assert(game.m.can_hit(game.hero,king,strike)==(abs(depth)<48),"King uses normal vertical hit tolerance")
 game.hero.y=670
 for facing in [-1,1]:
  king.dir=facing
  for side in [-1,1]:
   strike.direction=-side
   for pose in [0,1,2]:
    king.hurtTicks=10 if pose==1 else 0
    king.attack={"type":"rootSlam"} if pose==2 else {}
    game.hero.x=king.x+side*300
    assert(game.m.can_hit(game.hero,king,strike),"Attacks reach his visible body from either side in every pose")
    game.hero.x=king.x+side*350
    assert(not game.m.can_hit(game.hero,king,strike),"Hits still require horizontal weapon contact")
 king.attack={}
 game.queue_free();await process_frame;await create_timer(.15).timeout
 print("CAIRN_KING_CHARGE_OK: sustained pressure, warning, both directions, swept hit, knockdown, recovery and cooldown")
 quit()
