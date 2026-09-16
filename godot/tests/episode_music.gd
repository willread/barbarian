extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.start_game()
 game.loading_menu=false
 game.muted=false
 game.music_enabled=true
 var audio=game.audio
 audio.set_process(false)
 audio.unlocked=true
 assert(audio.tracks[2].stream.resource_path.ends_with("roots-below.ogg"))
 assert(audio.tracks[3].stream.resource_path.ends_with("furnace-heart-overdrive.ogg"))
 assert(audio.tracks[3].stream.loop_offset>2.0)
 for episode in [1,2,3]:
  game.current_episode=episode
  game.phase="playing"
  audio._process(3.)
  for i in audio.tracks.size():assert(audio.tracks[i].playing==(i==episode))
  var stream=audio.tracks[episode].stream
  game.phase="paused"
  audio._process(.1)
  assert(audio.tracks[episode].playing and audio.tracks[episode].stream==stream)
  game.phase="lost"
  audio.stop_gameplay()
  audio._process(.1)
  assert(audio.tracks[episode].playing)
 game.phase="title"
 audio._process(3.)
 assert(audio.tracks[0].playing)
 for i in range(1,4):assert(not audio.tracks[i].playing)
 game.music_enabled=false
 audio._process(3.)
 for track in audio.tracks:assert(not track.playing)
 game.queue_free()
 await process_frame
 print("CAIRN_EPISODE_MUSIC_OK: separate looping tracks, transitions, pause/death continuity and mute")
 quit()
