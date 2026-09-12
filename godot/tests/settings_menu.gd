extends SceneTree
func _init():call_deferred("check")
func check():
	var art=load("res://scripts/art.gd").new()
	for value in 101:
		assert(art.data.menu.has("VOLUME: %d"%value))
	var menu=load("res://scripts/menu.gd").new()
	root.add_child(menu)
	menu.setup(art)
	for labels in [["SOUND","DISPLAY","BACK"],["SOUND: ON","MUSIC: ON","VOLUME: 100","BACK"],["FULLSCREEN: OFF","BACK"]]:
		menu.show_items(labels,true,false)
		assert(menu.items.size()==labels.size())
		for item in menu.items:assert(item.face.texture!=null)
		if "--capture" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("E:/Cairn-build-tools/settings-"+str(labels.size())+".png")
	menu.free()
	print("CAIRN_SETTINGS_OK: nested menus and 101 distinct stone volume labels")
	quit()
