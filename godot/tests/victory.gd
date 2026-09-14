extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.records=CairnRunRecords.new("")
 game.start_game()
 game.stage_walk=""
 game.transition=-1
 game.wave=game.encounters.size()
 game.spawn_wave()
 game.hero.x=550
 for enemy in game.enemies:
  enemy.hp=0
  enemy.burnAge=20
  enemy.down={}
 game.tick(game.m.STEP)
 assert(game.phase=="victory" and game.results_view==null and game.finished_run.is_empty())
 assert(game.art.pose(game.hero)==["hero-cast-unarmed-v1",0])
 var mana=game.magic
 var x=game.hero.x
 for i in 150:
  game._process(1.0/60)
  await process_frame
 assert(game.phase=="victory" and game.hero.x==x and game.results_view==null)
 assert(game.art.pose(game.hero)==["hero-cast-unarmed-v1",4],"Victory raises the weapon and holds it overhead")
 assert(game.spell==-1 and game.magic==mana,"Victory salute does not cast lightning or consume mana")
 if "--victory-capture" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/victory-blood.png")
 for i in 150:
  game._process(1.0/60)
  await process_frame
 assert(game.phase=="won" and game.results_view!=null and game.finished_run.outcome=="won")
 assert(not is_instance_valid(game.wipe),"Winning scores overlay the arena without a full-screen blood wipe")
 assert(game.records.board().runs.size()==1 and 1 in game.unlocked_episodes)
 game.queue_free()
 await process_frame
 print("CAIRN_VICTORY_OK: boss clear, frozen blood interlude, delayed scores and single victory reward")
 quit()
