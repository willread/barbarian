extends SceneTree
func _init():call_deferred("check")
func check():
 var art=CairnArt.new()
 var m=CairnMechanics.new(art.data.attacks)
 var ai=CairnEnemies.new(m,art.data.roster)
 var hero=m.make(1,720,660,100,true)
 var small=m.make(2,580,660,16)
 small.variant="swift"
 small.dir=1
 ai.intent(small,hero,false)
 assert(not small.attack.is_empty(),"Swift minotaurs attack without an engagement slot")
 var regular=m.make(3,580,660,16)
 ai.intent(regular,hero,false)
 assert(regular.attack.is_empty(),"Regular enemies retain turn taking")
 var env=load("res://scripts/environment.gd").new()
 # Concave C shape: central gap must never count as walkable.
 env.screen={"walkable":{"polygon":[[0,0],[1,0],[1,.25],[.25,.25],[.25,.75],[1,.75],[1,1],[0,1]]}}
 var f={"x":720.0,"y":405.0,"entered_arena":true}
 env.constrain(f)
 assert(f.y<202.5 or f.y>607.5)
 for screen in env.chapter_screens:
  env.screen=screen
  var polygon=PackedVector2Array()
  for point in screen.walkable.polygon:polygon.append(Vector2(point[0]*1440,point[1]*810))
  for i in 1000:
   f={"x":randf_range(140,1300),"y":randf_range(400,850),"entered_arena":true}
   env.constrain(f)
   assert(Geometry2D.is_point_in_polygon(Vector2(f.x,f.y),polygon))
 env.free()
 var game=load("res://scripts/game.gd").new()
 var config=ConfigFile.new()
 config.set_value("game","weapon","blacktooth")
 game.initialize_weapon(config,"2026-12-25")
 assert(game.weapon_skin=="candy_cane" and game.regular_weapon=="blacktooth")
 config.set_value("game","holiday_seen_date",game.holiday_seen_date)
 game.initialize_weapon(config,"2026-12-25")
 assert(game.weapon_skin=="blacktooth" and game.holiday=="off")
 game.initialize_weapon(config,"2026-12-26")
 assert(game.weapon_skin=="candy_cane")
 game.settings_page="game"
 assert(game.option_labels().size()==3 and game.option_labels()[1]=="CONTROLS")
 assert(art.data.menu.has("WEAPON: CANDY CANE"))
 game.free()
 print("CAIRN_VARIANT_HOLIDAY_OK: opportunistic attacks, polygon containment, temporary daily weapon selection")
 quit()
