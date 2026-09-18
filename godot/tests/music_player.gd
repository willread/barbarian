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
 assert(game.audio.tracks[2].stream==null and game.audio.tracks[3].stream==null,"Opening the player must load unvisited episode music")
 game.menu_action("MUSIC PLAYER")
 var view=game.music_player_view
 assert(view.names.size()==5 and view.names[2]=="Roots Below")
 assert(view.names[3]=="Furnace Heart IV — Overdrive")
 assert(view.back_menu.scale==Vector2.ONE,"Back uses the standard menu button scale")
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
 assert(view.player.stream.loop_offset>2.0,"Overdrive keeps its opening and repeats from its musical loop point")
 for i in range(4,5):
  view.play_track(i)
  assert(view.player.playing and not view.player.stream.loop)
  assert(view.player.stream.get_length()>21 and view.player.stream.get_length()<23)
  assert(view.names[i]=="Last Light" and view.places[i]=="EP III / EPILOGUE")
  for track in game.audio.tracks:
   if track.playing:assert(track.stream_paused,"Candidates play without background music")
 if "--capture" in OS.get_cmdline_user_args():
  await create_timer(.3).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/music-player.png")
 var down=InputEventKey.new();down.keycode=KEY_DOWN;down.pressed=true
 view.handle(down)
 assert(view.selected==view.names.size(),"Down from the last track selects the standard Back button")
 var enter=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true
 view.handle(enter)
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
 print("CAIRN_MUSIC_PLAYER_OK: four themes, selected Last Light epilogue, exclusive playback, standard Back and restoration")
 quit()
