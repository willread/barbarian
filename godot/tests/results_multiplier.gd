extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	var view=load("res://scripts/results_view.gd").new()
	view.art=game.art
	view.result={"score":1000,"peak_multiplier":1,"outcome":"lost"}
	game.add_child(view)
	for value in [1,3,10]:
		view.result.peak_multiplier=value
		view.content.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		for ch in "X%d"%value:
			assert(view.lettering.textures.has(view.lettering.data.glyphs.stat[ch].file),"Multiplier uses the same carved stat glyphs")
	view.result.peak_multiplier=1
	view.content.queue_redraw()
	await create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	if "--multiplier-capture" in OS.get_cmdline_user_args():root.get_texture().get_image().save_png("E:/Cairn-build-tools/results-multiplier.png")
	game.queue_free();await process_frame
	print("CAIRN_RESULTS_MULTIPLIER_OK: Matching stat lettering used for X1, X3 and X10")
	quit()
