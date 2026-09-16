extends SceneTree
func _init():call_deferred("check")
func check():
	assert(OS.has_feature("shareware"))
	for path in ["worlds/swamp.json","worlds/ashen.json","art/saint-v2-atlas.json"]:
		assert(not FileAccess.file_exists("res://"+path),"Shareware leaked metadata: "+path)
	for path in ["assets/swamp-1-base.png","assets/ashen-1-base.png","assets/enemy-witch-0.png","assets/enemy-bearer-0.png","assets/king-root-v2-0.png","art/saint-v2-0.png","art/ending/reunion-panorama-v1.png","audio_options/roots-below.ogg","audio_options/furnace-heart-overdrive.ogg","audio_options/homeward-lastlight.ogg","audio/mire_loop.ogg","voice/boss-king.ogg","voice/boss-saint.ogg"]:
		assert(not ResourceLoader.exists("res://"+path),"Shareware leaked: "+path)
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	assert(game.shareware and game.audio.tracks.size()==2)
	for child in game.get_children():
		assert(child.get_script()==null or not child.get_script().resource_path.ends_with("soundboard.gd"))
	game.menu_action("MUSIC PLAYER")
	assert(game.music_player_view.names.size()==2)
	for index in 2:
		game.music_player_view.play_track(index)
		assert(game.music_player_view.player.stream!=null)
	game.music_player_view.closed.emit()
	await process_frame
	game.start_game()
	for wave in range(1,14):
		game.wave=wave
		game.spawn_wave()
		game.transition=-1
		game._process(0)
		await process_frame
	for area in range(1,5):
		game.background.setup(game.art,"citadel-"+str(area))
		assert(game.background.get_child_count()>0)
		await process_frame
	for id in game.audio.clips:
		if game.audio.choices.get(id,"")!="none":assert(game.audio.clips[id]!=null,id)
	assert(game.audio.pool_clip("enemy_impact")!=null)
	game.queue_free()
	await process_frame
	await create_timer(.15).timeout
	print("CAIRN_SHAREWARE_ASSETS_OK: excluded paid assets, two music tracks, four playable backgrounds, active audio and no soundboard")
	quit()
