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
	for labels in [["RETURN TO BATTLE","OPTIONS","QUIT TO TITLE"],["SOUND","DISPLAY","BACK"],["SOUND: ON","MUSIC: ON","VOLUME: 100","BACK"],["FULLSCREEN: OFF","BACK"]]:
		menu.show_items(labels,false,false)
		for viewport in [Vector2(1440,810),Vector2(810,1440),Vector2(1920,810)]:
			menu.layout_screen(viewport,false)
			var bounds=Rect2()
			for item in menu.items:
				var rect=Rect2(menu.to_global(Vector2(item.x-item.width*.5,item.y)),Vector2(item.width,item.height)*menu.scale)
				bounds=rect if bounds.size==Vector2.ZERO else bounds.merge(rect)
			assert(bounds.get_center().distance_to(viewport*.5)<.01)
			assert(bounds.position.x>=0 and bounds.end.x<=viewport.x)
			assert(bounds.position.y>=0 and bounds.end.y<=viewport.y)
	assert(art.data.menu.has("QUIT TO DESKTOP"))
	menu.free()
	print("CAIRN_SETTINGS_OK: nested menus and 101 distinct stone volume labels")
	quit()
