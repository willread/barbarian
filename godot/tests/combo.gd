extends SceneTree
func _init():call_deferred("check")
func check():
 var c=CairnCombo.new()
 for i in 3:c.hit()
 assert(c.multiplier()==2 and is_equal_approx(c.mana_multiplier(),1.2))
 for i in 9:c.hit()
 assert(c.multiplier()==5 and c.advance(1.)==1.5)
 c.advance(10.)
 assert(c.multiplier()==1 and c.hits==0)
 for i in 100:c.hit()
 assert(c.multiplier()==10)
 c.reset()
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.start_game()
 game.hero.pickup={"age":.4,"collected":false,"start_x":game.hero.x}
 var health=game.hero.hp
 var attacker=game.make_actor(900,660,100)
 for strike in [{"damage":100,"direction":1,"knock":true},{"damage":3,"direction":1,"no_stun":true}]:
  game.damage(game.hero,strike,attacker)
  assert(game.hero.hp==health and game.hero.hurtTicks==0 and game.hero.down.is_empty())
  assert(not game.hero.pickup.is_empty())
 game.hero.pickup={}
 var magic_target=game.make_actor(900,660,100)
 game.combo.reset()
 game.damage(magic_target,{"damage":.12,"direction":1,"magic":true,"continuous":true},game.hero)
 assert(game.combo.hits==1)
 var magic_score=game.score
 game.combo.remaining=.01
 game.damage(magic_target,{"damage":.12,"direction":1,"magic":true,"continuous":true},game.hero)
 assert(game.combo.hits==1 and game.score==magic_score and game.combo.remaining==game.combo.timeout)
 game.spell_combo_targets.clear()
 game.damage(magic_target,{"damage":.12,"direction":1,"magic":true,"continuous":true},game.hero)
 assert(game.combo.hits==2)
 game.combo.reset()
 game.score=0
 var enemy=game.make_actor(900,660,100)
 enemy.kind="bone"
 for i in 3:game.damage(enemy,{"damage":1,"direction":1},game.hero)
 assert(game.score==40 and game.combo.multiplier()==2)
 var points=game.score
 var mana=game.magic
 game.damage(enemy,{"damage":.1,"direction":1,"magic":true,"continuous":true},game.hero)
 assert(game.score==points+20 and game.combo.hits==4 and game.magic==mana)
 game.damage(game.hero,{"damage":1,"direction":-1},enemy)
 assert(game.combo.hits==0)
 game.settings_page="game"
 assert(game.option_labels()[1]=="CONTROLS")
 assert(game.art.weapon_data(game.hero).length>0)
 for i in 12:game.combo.hit()
 game.combo.remaining=.5
 game.hero.x=720
 game.hero.hp=50
 game.enemies.clear()
 game.step_combo(10.)
 assert(game.combo.remaining==.5 and game.hero.hp==50)
 enemy.hp=100
 enemy.x=-450
 game.enemies.append(enemy)
 game.step_combo(10.)
 assert(game.combo.remaining==.5)
 enemy.x=820
 enemy.y=game.hero.y
 game.step_combo(.1)
 assert(game.combo.remaining==3.25 and game.hero.hp==50)
 game.step_combo(1.)
 assert(game.combo.remaining==2.25 and game.hero.hp==51.5)
 enemy.x=-450
 game.step_combo(1.)
 assert(game.combo.remaining==1.25,"Retreat must not pause an active combo")
 # An offscreen reinforcement must not consume the previous foe's final timer.
 enemy.hp=0
 var incoming=game.make_actor(-300,660,20)
 incoming.kind="bone"
 game.enemies.append(incoming)
 game.step_combo(2.)
 assert(game.combo.remaining==1.25 and game.combo.waiting_for_combat)
 incoming.x=800
 incoming.y=game.hero.y
 game.step_combo(.1)
 assert(game.combo.remaining==3.25 and not game.combo.waiting_for_combat)
 print("CAIRN_COMBO_OK: tiers, mana, healing, timeout, hit scores, magic continuation, pickup protection, damage reset and holiday choices")
 quit()
