extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_game()
	var voice=game.hero_voice
	voice.set_process(false)
	voice.request_line("dinner",.9,4)
	voice.request_line("dinner",.9,4)
	assert(voice.pending.size()==1)
	assert(voice.definitions.dinner.envelope.size()>0)
	assert(load(voice.definitions.dinner.file).get_length()>0)
	game.hero.hp=40
	voice._process(.1)
	assert(voice.pain==.45)
	game.phase="paused"
	var before=voice.time
	voice._process(1.)
	assert(voice.time==before)
	game.phase="playing"
	voice._process(6.)
	assert(voice.pending.is_empty())
	voice.reset()
	assert(voice.active=="" and not voice.player.playing)
	print("CAIRN_VOICE_OK: clip, envelope, deduplication, damage reaction, pause, expiration and reset")
	quit()
