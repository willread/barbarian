extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.current_episode=2
 game.start_game()
 game.set_process(false)
 game.menu.visible=false
 game.transition=-1
 for area in range(4):
  game.wave=area*3+1
  game.spawn_wave()
  assert(game.background.screen.revision==4)
  for region in game.background.screen.regions:
   assert(region.animation.blend==false)
   assert(region.animation.fps==12 or region.animation.count==1)
   var texture=game.art.texture(region.animation.atlas)
   assert(texture.get_width()/region.animation.columns==region.animation.rect[2],"Full resolution detail frames")
  if area==0:
   assert(game.background.has_node("ForegroundReeds"))
   assert(game.background.get_node("ForegroundReeds").clumps.size()==10)
   game.background.advance(52)
   assert(game.background.decorations[-1].clock==52,"Bird timing must not reset every 24 seconds")
   for sample in range(40):
    game.background.advance(8+sample*.2)
    await process_frame
  assert(game.background.has_node("ForegroundTree")== (area==2),"Foreground tree belongs only to E2/3")
  var front=game.background.screen.regions.filter(func(r):return r.foreground)
  assert(front.size()==(1 if area==3 else 0),"Only painted throne rocks remain in foreground")
  if area==3:assert(front[0].animation.count==1,"Throne foreground is static rock occlusion")
  game.clock=12
  game.background.advance(12)
  game.stage_walk=""
  game.hero.x=100 if area==3 else 720
  game.hero.y=760
  game._process(0)
  assert(is_equal_approx(game.background.position.y,0.0),"Full world framing must remain unshifted")
  if "--swamp-capture" in OS.get_cmdline_user_args():
   await create_timer(.2).timeout
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("E:/Cairn-build-tools/swamp-v3-game-%d.png"%(area+1))
 game.queue_free()
 await process_frame
 print("CAIRN_SWAMP_V3_OK: four baked scenes, sharp frames, continuous birds, foreground crossing reeds and static throne rocks")
 quit()
