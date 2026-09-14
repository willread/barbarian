extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.records=CairnRunRecords.new("")
 game.menu_action("EP 2: THE SUNKEN WILDS")
 assert(game.difficulty_select and game.phase=="title")
 game.menu_action("BACK")
 assert(game.chapter_select and not game.difficulty_select)
 for setting in ["easy","normal","hard"]:
  game.menu_action("EP 2: THE SUNKEN WILDS")
  game.menu_action(setting.to_upper())
  assert(game.phase=="playing" and game.difficulty==setting)
  var cap={"easy":2,"normal":3,"hard":4}[setting]
  assert(game.enemy_cap()==cap)
  game.wave=10
  game.enemies.clear()
  game.pending_enemies=["bone","bone","bone","bone","bone","bone"]
  for i in 6:game.spawn_encounter_enemy()
  assert(game.enemies.size()==cap and game.pending_enemies.size()==6-cap)
  var foe=game.make_actor(900,660,100)
  var outgoing={"easy":1.25,"normal":1.0,"hard":.75}[setting]
  var incoming={"easy":.75,"normal":1.0,"hard":1.25}[setting]
  game.damage(foe,{"damage":10,"direction":1},game.hero)
  assert(is_equal_approx(100-foe.hp,10*game.damage_multiplier*outgoing))
  game.damage(game.hero,{"damage":2,"direction":-1},foe)
  assert(is_equal_approx(100-game.hero.hp,2*game.damage_multiplier*100/48*incoming))
  game.score=1234
  game.finish_run("lost")
  assert(game.finished_run.difficulty==setting and game.finished_run.score==1234,"Difficulty is recorded without a score multiplier")
  game.menu_action("QUIT TO TITLE")
 var hall=load("res://scripts/hall_view.gd").new()
 hall.art=game.art
 for i in 20:
  hall.runs.append({"id":str(i),"score":10000-i*200,"time":200+i,"date":"2026-09-%02d"%(i+1),"episode":2,"area":1+i%4,"difficulty":["easy","normal","hard"][i%3]})
 game.add_child(hall)
 await process_frame
 assert(hall.content.mouse_filter==Control.MOUSE_FILTER_IGNORE)
 for column in hall.COLUMNS:
  hall.sort_by(column[0])
  for i in range(1,hall.runs.size()):
   var a=hall.sort_value(hall.runs[i-1],column[0])
   var b=hall.sort_value(hall.runs[i],column[0])
   assert(a>=b if hall.descending else a<=b)
  var direction=hall.descending
  hall.sort_by(column[0])
  assert(hall.descending!=direction)
 hall.sort_by("rank")
 if "--difficulty-capture" in OS.get_cmdline_user_args():
  await create_timer(.4).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/difficulty-hall.png")
 hall.queue_free()
 game.queue_free()
 await process_frame
 print("CAIRN_DIFFICULTY_OK: selection, both damage modifiers, unweighted scores, difficulty column, twenty rows and reversible column sorting")
 quit()
