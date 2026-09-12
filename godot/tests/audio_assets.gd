extends SceneTree
func _init():
	var count=0
	for file in DirAccess.get_files_at("res://audio"):
		if not file.ends_with(".ogg"):continue
		var stream=load("res://audio/"+file)
		assert(stream is AudioStreamOggVorbis and stream.get_length()>.08,"Invalid audio: "+file)
		if file.begins_with("music_"):
			assert(stream.get_length()>50,"Music loop unexpectedly short")
		count+=1
	assert(count==28,"Expected 26 SFX and two music tracks")
	print("CAIRN_AUDIO_OK: all 28 Ogg assets decode, music loop lengths valid")
	quit()
