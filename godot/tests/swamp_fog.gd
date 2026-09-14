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
  var fog=game.background.get_children().filter(func(node):return node is ColorRect and node.material.get_meta("continuous_clock",false))[0]
  assert(fog.z_index>1805 and not fog.z_as_relative)
  game.background.advance(24.1)
  assert(is_equal_approx(fog.material.get_shader_parameter("clock"),24.1))
  if area==1 and "--fog-capture" in OS.get_cmdline_user_args():
   await create_timer(.3).timeout
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("E:/Cairn-build-tools/swamp-fog.png")
  await process_frame
 game.background.setup(game.art,"ashen-1")
 await process_frame
 assert(not game.background.has_node("DriftingFog"))
 game.queue_free()
 await process_frame
 print("CAIRN_FOG_OK: all swamp areas, foreground depth, continuous drift, no fog in other episodes")
 quit()
