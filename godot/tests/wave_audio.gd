extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.start_game()
 game.stage_walk=""
 game.transition=-1
 game.phase="playing"
 game.pending_enemies.clear()
 var old_ids=[]
 for enemy in game.enemies:
  old_ids.append(enemy.id)
  enemy.hp=0
  enemy.down={}
  enemy.burnAge=0
 for i in 45:game.tick(game.m.STEP)
 assert(game.wave==2,"Next wave should start before burn completion")
 assert(game.enemies.any(func(e):return e.id in old_ids),"Burning bodies must survive wave handoff")
 assert(game.enemies.any(func(e):return e.hp>0))
 game.audio.set_process(false)
 var track=game.audio.tracks[1]
 track.stream=AudioStreamGenerator.new()
 track.play()
 game.audio.stop_gameplay()
 assert(track.playing,"Death should stop effects, not the music stream")
 game.phase="lost"
 game.audio.unlocked=true
 game.muted=false
 game.loading_menu=false
 game.music_enabled=true
 game.audio._process(.1)
 assert(track.playing)
 print("CAIRN_WAVE_AUDIO_OK: overlapping burn and next wave; continuous music through death")
 quit()
