extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.start_game()
 game.audio.set_process(false)
 game.audio.unlocked=true
 game.muted=false
 game.loading_menu=false
 var hag=game.make_actor(900,680,9)
 hag.kind="witch"
 game.enemies=[hag]
 game.episode_combat.hazards=[{"kind":"mire","owner":hag,"p":Vector2(720,680),"age":.5,"life":8.}]
 game.episode_combat.sync_views(game)
 game.audio._process(.2)
 assert(game.audio.mire_loop.playing and game.audio.mire_loop.stream.loop)
 game.phase="paused"
 game.audio._process(.1)
 assert(game.audio.mire_loop.stream_paused)
 game.phase="playing"
 game.audio._process(.2)
 assert(not game.audio.mire_loop.stream_paused)
 hag.hp=0
 game.episode_combat.sync_views(game)
 game.audio._process(.5)
 assert(not game.audio.mire_loop.playing,"Owner death stops liquid loop")
 for player in game.audio.voices+game.audio.tracks:player.stop()
 game.audio.mire_loop.stop()
 game.clear_world()
 await process_frame
 game.queue_free()
 await process_frame
 await create_timer(.1).timeout
 print("CAIRN_MIRE_AUDIO_OK: looping, pause/resume and owner-death cleanup")
 quit()
