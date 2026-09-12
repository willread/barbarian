extends SceneTree
func _init():
	var source=Node2D.new()
	var audio=load("res://scripts/audio.gd").new()
	source.add_child(audio)
	audio.setup(source)
	assert(audio.clips.size()==28,"Expected 26 SFX and two music tracks")
	for id in audio.clips:
		var stream=audio.clips[id]
		assert(stream is AudioStreamOggVorbis and stream.get_length()>.08,"Invalid audio: "+id)
		if id.begins_with("music_"):assert(stream.get_length()>50,"Music loop unexpectedly short")
	assert(audio.tracks.size()==2 and audio.tracks[0].stream and audio.tracks[1].stream)
	source.free()
	print("CAIRN_AUDIO_OK: runtime loader resolves all 28 Ogg assets and both music tracks")
	quit()
