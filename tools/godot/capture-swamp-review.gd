extends SceneTree
func _init():call_deferred("capture")
func capture():
	root.size=Vector2i(640,360)
	root.content_scale_size=Vector2i(1440,810)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var art=CairnArt.new()
	for area in range(1,5):
		var scenery=load("res://scripts/environment.gd").new()
		root.add_child(scenery)
		scenery.setup(art,"swamp-%d"%area)
		scenery.advance(5.3)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../studies/backgrounds/swamp-review/current-%d.png"%area))
		scenery.queue_free()
		await process_frame
	print("CAIRN_SWAMP_REVIEW_CAPTURED: four current native backgrounds")
	quit()
