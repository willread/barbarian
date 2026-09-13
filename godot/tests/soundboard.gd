extends SceneTree
func _init():call_deferred("check")
func check():
	var source=Node2D.new()
	root.add_child(source)
	var audio=load("res://scripts/audio.gd").new()
	source.add_child(audio)
	audio.setup(source)
	audio.set_process(false)
	var board=load("res://scripts/soundboard.gd").new()
	board.audio=audio
	source.add_child(board)
	assert(board.buttons.size()==30)
	for id in ["foot_stone","foot_earth","bow_draw","arrow_ground"]:
		assert(not audio.clips.has(id) and not board.buttons.has(id))
	assert(audio.originals.landing.resource_path.ends_with("slam_boom.ogg"))
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://audio_options/manifest.json"))
	assert(data.jobs.size()==148)
	for job in data.jobs:
		if job.group in ["foot_stone","foot_earth","bow_draw","arrow_ground"]:continue
		var clip=load("res://audio_options/"+job.id+(".ogg" if job.get("music",false) or job.group=="enemy_impact" else ".mp3"))
		assert(clip is AudioStream and clip.get_length()>.1)
		if job.get("music",false):assert(clip.get_length()>40)
	assert(board.buttons.enemy_impact.size()==12)
	audio.pools.enemy_impact=["enemy-impact-1","enemy-impact-2"]
	var prior=""
	for i in 20:
		var clip=audio.pool_clip("enemy_impact")
		assert(clip.resource_path!=prior,"Pool avoids immediate repeat")
		prior=clip.resource_path
	audio.pools.enemy_impact=[]
	assert(audio.pool_clip("enemy_impact")==null,"Empty selection silences impacts")
	audio.set_volume("resist",-12,false)
	assert(audio.volumes.resist==-12)
	audio.set_volume("resist",30,false)
	assert(audio.volumes.resist==6)
	board.toggle()
	assert(paused and board.opened)
	audio.set_variant("sword","sword-3",false)
	assert(audio.clips.sword.resource_path.ends_with("sword-3.mp3"))
	audio.set_variant("music_game","music_game-2",false)
	assert(audio.tracks[1].stream==audio.clips.music_game and audio.tracks[1].stream.loop)
	audio.set_variant("sword","none",false)
	assert(audio.clips.sword==null and audio.choices.sword=="none")
	audio.set_variant("music_game","none",false)
	assert(audio.tracks[1].stream==null)
	audio.set_variant("music_game","original",false)
	assert(audio.tracks[1].stream!=null)
	var exported=JSON.parse_string(audio.export_choices())
	assert(exported.pools.enemy_impact.is_empty())
	assert(exported.choices.sword=="none" and exported.volumes.resist==6)
	assert(exported.choices.size()==audio.originals.size())
	board.toggle()
	assert(not paused and not board.opened)
	paused=true
	board.toggle()
	audio.set_volume("resist",-12,false)
	assert(audio.volumes.resist==-12)
	audio.set_volume("resist",30,false)
	assert(audio.volumes.resist==6)
	board.toggle()
	assert(paused,"Closing lab preserves preexisting pause")
	paused=false
	if "--capture" in OS.get_cmdline_user_args():
		board.toggle()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/soundboard-check.png")
		board.toggle()
	source.free()
	print("CAIRN_SOUNDBOARD_OK: 148 retained options, 30 active groups, random impact pool, live effect/music replacement and pause restoration")
	quit()
