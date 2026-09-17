extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.start_game()
	var voice=game.hero_voice
	voice.set_process(false)
	game.set_process(false)
	game.transition=-1;game.stage_walk=""
	voice.scheduled_wave=voice.wave_key()
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
	assert(voice.pending.size()==2)
	game.magic=100
	voice.observe_milestones()
	assert(voice.pending.size()==3)
	voice.reset()
	voice.observe_milestones()
	assert(voice.pending.size()==2)
	game.magic=0
	# Boss cues remain eligible after both ordinary enemy milestones have fired.
	for kind in ["champion","king","saint"]:
		voice.reset()
		foe.boss=true;foe.kind=kind;foe.size=1.8;foe.variant="regular"
		foe.x=-100
		voice.observe_milestones()
		assert(voice.pending.is_empty())
		foe.x=300
		voice.observe_milestones()
		voice.observe_milestones()
		assert(voice.pending.size()==1 and voice.pending[0].id=="boss_"+kind)
	game.start_game()
	assert(voice.milestones.is_empty() and voice.played.is_empty() and voice.spoken_waves.is_empty())
	game.transition=-1;game.stage_walk=""
	voice.scheduled_wave=voice.wave_key()
	game.voice_enabled=false
	voice.request_once("mana_full")
	assert(voice.pending.is_empty())
	for id in voice.definitions:
		assert(load(voice.definitions[id].file).get_length()>0)
		assert(voice.definitions[id].envelope.size()>1)
	game.voice_enabled=true
	game.muted=false
	game.audio.unlocked=true
	var saved_enemies=game.enemies.duplicate()
	game.enemies.clear();game.magic=0;game.hero.hp=100
	voice.new_run();voice.scheduled_wave=voice.wave_key();voice.gap=0
	voice.request_line("dinner")
	voice._process(.01)
	assert(voice.active=="dinner" and voice.played.has("dinner"))
	voice.interrupt()
	voice.request_line("goat_search")
	assert(voice.pending.is_empty(),"An interrupted line still consumes this wave's slot")
	voice.reset()
	voice.request_line("mana_full")
	assert(voice.pending.is_empty(),"Voice reset cannot reopen a spent wave")
	game.wave=2;voice.schedule_wave();voice.pending.clear();voice.gap=0
	voice.request_line("dinner")
	assert(voice.pending.is_empty(),"Spoken lines cannot repeat in later waves")
	voice.request_line("goat_search")
	voice._process(1.)
	assert(voice.active=="goat_search" and voice.played.size()==2)
	voice.interrupt();game.wave=13;voice.schedule_wave();voice.gap=0
	voice.request_line("boss_champion")
	voice._process(1.)
	assert(voice.active=="boss_champion")
	voice.request_line("low_health")
	assert(voice.pending.is_empty(),"Boss battle also allows only one line")
	voice.new_run();voice.scheduled_wave=voice.wave_key();voice.gap=0
	assert(voice.played.is_empty() and voice.spoken_waves.is_empty())
	game.hero.hp=25;voice.previous_hp=25
	voice.observe_milestones()
	assert(voice.pending.size()==1 and voice.pending[0].id=="low_health")
	voice._process(1.)
	assert(voice.active=="low_health")
	game.enemies.assign(saved_enemies)
	voice.new_run();voice.scheduled_wave=voice.wave_key();voice.gap=0
	game.hero.hp=100;voice.previous_hp=100
	game.hero.down={"ground":true}
	voice.observe_milestones()
	assert(voice.pending.is_empty(),"Retort waits until knockdown recovery")
	game.hero.down={}
	voice.observe_milestones()
	assert(voice.pending[0].id=="knocked_aside")
	game.damage(game.hero,{"damage":1000,"direction":-1,"knock":true},game.enemies[0])
	assert(game.phase=="dying")
	assert(game.audio.voices.any(func(v):return v.playing and v.get_meta("sound_id","")=="death" and v.stream==game.audio.clips.magic_shout),"Death shout must survive the dying transition and match the selected player voice")
	game.audio.stop_gameplay()
	game.process_mode=Node.PROCESS_MODE_DISABLED
	for track in game.audio.tracks:track.stop()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	await process_frame
	# Let the audio thread release the death stream before headless teardown.
	await create_timer(.1).timeout
	print("CAIRN_VOICE_OK: clip, envelope, deduplication, damage reaction, pause, expiration and reset")
	quit()
