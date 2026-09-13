extends SceneTree
func _init():
	var source=Node2D.new()
	var audio=load("res://scripts/audio.gd").new()
	source.add_child(audio)
	audio.setup(source)
	assert(audio.clips.size()==32,"Expected 32 active sound slots")
	for id in audio.originals:
		var stream=audio.originals[id]
		assert(stream is AudioStreamOggVorbis and stream.get_length()>.08,"Invalid audio: "+id)
		if id.begins_with("music_"):assert(stream.get_length()>40,"Music loop unexpectedly short")
	assert(audio.tracks.size()==2)
	source.free()
	print("CAIRN_AUDIO_OK: runtime loader resolves all active Ogg assets and both music tracks")
	quit()

