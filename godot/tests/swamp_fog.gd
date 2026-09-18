extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.current_episode=2
 game.start_game()
 game.transition=-1
 for area in range(1,5):
  game.background.setup(game.art,"swamp-%d"%area)
  await process_frame
  assert(game.background.has_node("DriftingFog"),"Drifting fog is present on every E2 screen")
  var fog=game.background.get_node("DriftingFog")
  assert(not fog.z_as_relative and fog.z_index==1810,"Fog drifts in front of the arena")
  assert(is_equal_approx(fog.material.get_shader_parameter("density"),1.85 if area==4 else 1.0),"Screen 4 has much heavier fog")
  game.background.advance(8.0)
  assert(is_equal_approx(fog.material.get_shader_parameter("clock"),8.0),"Fog animation receives the environment clock")
  game.tick(0)
  assert(is_equal_approx(game.m.lane_min,.63*810) and is_equal_approx(game.m.lane_max,.95*810),"Shared E2 lane margins reach actual movement limits")
  var actor=game.m.make(999,720,650,100,true)
  for frame in 180:game.m.motion(actor,0,-1,0,true)
  game.background.constrain(actor)
  assert(is_equal_approx(actor.y,.63*810+2),"Player can reach the expanded shoreline edge with normal boundary padding")
  for frame in 180:game.m.motion(actor,0,1,0,true)
  game.background.constrain(actor)
  assert(is_equal_approx(actor.y,.95*810-2),"Player can reach the shared bottom edge with normal boundary padding")
  if "--fog-capture" in OS.get_cmdline_user_args():
   await create_timer(.3).timeout
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("E:/Cairn-build-tools/swamp-fog-%d.png"%area)
  await process_frame
 game.current_episode=3
 for area in range(1,5):
  game.background.setup(game.art,"ashen-%d"%area)
  game.tick(0)
  var actor=game.m.make(999,720,650,100,true)
  for frame in 180:game.m.motion(actor,0,1,0,true)
  game.background.constrain(actor)
  assert(is_equal_approx(actor.y,.95*810-2),"Every E3 screen shares the reachable E2 bottom margin")
 await process_frame
 assert(not game.background.has_node("DriftingFog"))
 game.queue_free()
 await process_frame
 print("CAIRN_SWAMP_LANES_OK: restored animated E2 fog with heavier screen 4; expanded E2 lanes and consistent reachable bottom margins across E2/E3")
 quit()
