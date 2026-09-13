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
	game.enemies.clear()
	var foe=game.make_actor(-300,660,100,false)
	foe.size=1.4
	foe.boss=false
	game.enemies.append(foe)
	voice.observe_milestones()
	assert(not voice.milestones.has("big_enemy"))
	foe.x=300
	voice.observe_milestones()
	voice.observe_milestones()
	assert(voice.pending.size()==1 and voice.pending[0].id=="big_enemy")
	foe.variant="swift"
	foe.size=.72
	foe.x=-200
	voice.observe_milestones()
	assert(not voice.milestones.has("tiny_enemy"))
	foe.x=300
	voice.observe_milestones()
	voice.observe_milestones()
	assert(voice.pending.size()==2 and voice.milestones.has("tiny_enemy"))
	game.magic=100
	voice.observe_milestones()
	assert(voice.pending.size()==3)
	voice.reset()
	voice.observe_milestones()
	assert(voice.pending.is_empty())
	game.start_game()
	assert(voice.milestones.is_empty())
	game.voice_enabled=false
	voice.request_once("mana_full")
	assert(voice.pending.is_empty())
	for id in voice.definitions:
		assert(load(voice.definitions[id].file).get_length()>0)
		assert(voice.definitions[id].envelope.size()>1)
	print("CAIRN_VOICE_OK: clip, envelope, deduplication, damage reaction, pause, expiration and reset")
	quit()
