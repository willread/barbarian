extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.start_game()
 var console=game.debug_console
 assert(not console.visible)
 console.toggle()
 assert(paused and console.visible)
 var clock=game.clock
 await create_timer(.1).timeout
 assert(game.clock==clock,"Console freezes gameplay")
 game.hero.hp=12
 console.execute(" healme ")
 assert(game.hero.hp==game.hero.max)
 for area in range(2,5):
  console.execute("FASTTRAVEL")
  assert(game.screen_for_wave(game.wave)==area)
  assert(game.background.key=="citadel-%d"%area)
  assert(paused,"Commands must not unfreeze the game")
 console.execute("FASTTRAVEL")
 assert(game.wave==10)
 console.execute("bogus")
 assert(console.output.text.begins_with("Unknown"))
 if "--console-capture" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/debug-console.png")
 console.toggle()
 assert(not paused and not console.visible)
 game.queue_free()
 await process_frame
 print("CAIRN_CONSOLE_OK: freeze, heal, area skipping, final-area guard and resume")
 quit()
