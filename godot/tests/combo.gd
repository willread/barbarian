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
 assert(c.multiplier()==8)
 c.reset()
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.start_game()
 var enemy=game.make_actor(900,660,100)
 enemy.kind="bone"
 for i in 3:game.damage(enemy,{"damage":1,"direction":1},game.hero)
 assert(game.score==40 and game.combo.multiplier()==2)
 var points=game.score
 var mana=game.magic
 game.damage(enemy,{"damage":.1,"direction":1,"magic":true,"continuous":true},game.hero)
 assert(game.score==points and game.combo.hits==3 and game.magic==mana)
 game.damage(game.hero,{"damage":1,"direction":-1},enemy)
 assert(game.combo.hits==0)
 game.settings_page="game"
 for mode in ["off","christmas","halloween"]:
  game.holiday=mode
  game.hero.holiday=mode
  assert(game.option_labels()[1]=="HOLIDAY: "+mode.to_upper())
  assert(game.art.weapon_data(game.hero).length>0)
 print("CAIRN_COMBO_OK: tiers, mana, healing, timeout, hit scores, magic exclusion, damage reset and holiday choices")
 quit()
