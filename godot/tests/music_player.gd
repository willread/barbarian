extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.audio.unlocked=true
 game.loading_menu=false
 game.title_intro=1.25
 game.menu_action("OPTIONS");game.menu_action("SOUND")
 assert("MUSIC PLAYER" in game.option_labels())
 assert(game.art.data.menu.has("MUSIC PLAYER"))
 game.audio.tracks[0].play()
 await process_frame
 game.menu_action("MUSIC PLAYER")
 var view=game.music_player_view
 assert(view.names.size()==4 and view.names[2]=="Roots Below")
 assert(game.audio.music_preview and not game.menu.visible)
 for track in game.audio.tracks:
  if track.playing:assert(track.stream_paused)
 view.play_track(2)
 await process_frame
 assert(view.player.stream==game.audio.tracks[2].stream and view.player.stream.loop)
 assert(view.player.bus==&"Music")
 view.toggle();assert(view.player.stream_paused)
 view.toggle();assert(not view.player.stream_paused)
 view.play_track(3);assert(view.current==3)
 if "--capture" in OS.get_cmdline_user_args():
  await create_timer(.3).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/music-player.png")
 game.menu_action("BACK")
 await process_frame
 assert(not game.audio.music_preview and game.settings_page=="sound" and game.menu.visible)
 for track in game.audio.tracks:assert(not track.stream_paused)
 game.start_game();game.change_phase("paused");game.pause_cover=1
 game.menu_action("OPTIONS");game.menu_action("SOUND");game.menu_action("MUSIC PLAYER")
 game._process(0)
 assert(not game.menu.visible and game.phase=="paused")
 game.menu_action("BACK")
 await process_frame
 assert(game.phase=="paused" and not game.audio.music_preview)
 game.queue_free();await process_frame
 await create_timer(.15).timeout
 print("CAIRN_MUSIC_PLAYER_OK: four active tracks, looping, pause, menu restoration and paused-game isolation")
 quit()
