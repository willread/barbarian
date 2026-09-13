extends SceneTree
func _init():call_deferred("capture")
func capture():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.start_game()
 game.transition=-1
 game.stage_walk=""
 game.hero.x=720
 game.enemies.clear()
 game.score=0
 game.wave=8
 game._process(0.)
 for i in 15:await process_frame
 for frame in 600:
  if frame%18==0 and frame<=486:
   game.combo.hit()
   game.score+=10*game.combo.multiplier()
   if frame%54==0:game.score+=250*game.combo.multiplier()
  game.score_panel.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  var img=root.get_texture().get_image()
  var size=Vector2(img.get_size())
  var crop=Rect2i(Vector2i(size*Vector2(.785,.782)),Vector2i(size*Vector2(.21,.215)))
  img.get_region(crop).save_png("E:/Cairn-build-tools/hud-progression-frames/%04d.png"%frame)
 quit()
