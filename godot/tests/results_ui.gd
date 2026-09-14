extends SceneTree
var game
var capture=false
func _init():call_deferred("check")
func snap(name: String):
	if not capture:return
	await create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("E:/Cairn-build-tools/"+name+".png")
func key(code: int):
	var event=InputEventKey.new()
	event.keycode=code
	event.pressed=true
	game._input(event)
func check():
	capture="--capture-results" in OS.get_cmdline_user_args()
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.records=CairnRunRecords.new("")
	game.change_phase("title")
	game.menu.select(1,false)
	assert(game.menu.is_locked("HALL OF LEGENDS"))
	assert(game.menu.items[1].node.modulate.a<1.0 and not game.menu.items[1].fire.emitting)
	game.menu.activate()
	assert(game.hall_view==null)
	game.menu_action("HALL OF LEGENDS")
	await process_frame
	assert(game.hall_view.runs.is_empty() and game.hall_view.actions.items.size()==2)
	await snap("hall-empty")
	key(KEY_ESCAPE)
	assert(game.hall_view==null and game.menu.visible and game.menu.selected==1)
	game.start_game()
	var target=game.make_actor(900,660,100)
	game.damage(target,{"damage":10,"direction":1},game.hero)
	assert(game.run_stats.damage_dealt>0 and game.run_stats.best_combo==1)
	var enemy=game.make_actor(900,660,100)
	game.damage(game.hero,{"damage":2,"direction":1},enemy)
	assert(game.run_stats.damage_taken>0 and game.combo.hits==0 and game.run_stats.best_combo==1)
	for i in 20:
		game.records.finish({"id":"old-%d"%i,"score":116200-i*7000,"kills":50,"best_combo":20,"peak_multiplier":10,"damage_dealt":17000,"damage_taken":200,"time":700-i*20,"date":"2026-09-12","area":3,"outcome":"lost"})
	game.run_stats.merge({"time":768,"best_combo":36,"peak_multiplier":10,"damage_dealt":18640,"damage_taken":240},true)
	game.score=128450000000
	assert(not game.menu.is_locked("HALL OF LEGENDS"))
	game.kills=87
	game.wave=7
	game.change_phase("won")
	await process_frame
	assert(game.finished_run.rank==1 and "score" in game.finished_run.new_stats)
	assert(game.results_view.actions.items[0].label=="RISE AGAIN" and game.results_view.actions.selected==0)
	assert(game.results_view.actions.items[2].drop_offset<0)
	await create_timer(.42).timeout
	assert(absf(game.results_view.actions.items[0].drop_offset)<6)
	assert(game.results_view.actions.items[1].drop_offset<0)
	await create_timer(1.15).timeout
	var saved_id=game.finished_run.id
	for i in 40:
		game.wipe.advance(.12)
		await process_frame
	game.results_view.age=2
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(640,360),Vector2i(540,960)]:
		root.size=dimensions
		game.responsive_layout()
		game.results_view.layout()
		await process_frame
		var view=game.results_view
		assert(is_equal_approx(view.viewport_size.x/view.viewport_size.y,16.0/9.0))
		assert(is_equal_approx(view.transform.get_scale().x,view.transform.get_scale().y))
		assert(is_equal_approx(view.actions.position.x+view.actions.items[1].x*view.actions.scale.x,view.viewport_size.x*.5))
		for i in view.actions.items.size():
			var item=view.actions.items[i]
			assert(is_equal_approx(view.actions.position.x+item.x*view.actions.scale.x,view.viewport_size.x*.5))
			if i>0:assert(item.y>view.actions.items[i-1].y)
		assert(view.scroll.position.y+view.scroll.size.y<view.viewport_size.y)
		for item in view.actions.items:
			var rect=Rect2(view.actions.position+item.node.position*view.actions.scale,Vector2(item.width,item.height)*view.actions.scale)
			assert(rect.position.y>=view.scroll.position.y+view.scroll.size.y and rect.end.y<=view.viewport_size.y)
		await snap("results-%d"%dimensions.x)
		game.menu_action("HALL OF LEGENDS")
		await process_frame
		var hall=game.hall_view
		assert(hall.runs.size()==20 and hall.runs[hall.selected].id==saved_id)
		key(KEY_END)
		assert(hall.runs[hall.selected].id==saved_id,"Scrolling must not select rows")
		assert(hall.scroll.scroll_vertical+hall.scroll.size.y>=20*hall.row_height-2)
		await snap("hall-%d"%dimensions.x)
		key(KEY_ESCAPE)
		assert(game.results_view.visible and game.results_view.age>=2 and game.finished_run.id==saved_id)
		assert(game.records.board().runs.size()==20)
	game.menu_action("QUIT TO TITLE")
	assert(game.results_view==null and game.phase=="title")
	root.size=Vector2i(1280,720)
	game.responsive_layout()
	game.title_intro=1.25
	game.overlay.queue_redraw()
	await create_timer(1.5).timeout
	await snap("hall-title")
	# First defeat and a non-record repeat retain full stats without false NEW labels.
	game.records=CairnRunRecords.new("")
	for i in 2:
		game.start_game()
		game.score=100
		game.run_stats.best_combo=6
		game.damage(game.hero,{"damage":1000,"direction":1,"knock":true},game.make_actor(900,660,100))
		assert(game.phase=="dying" and game.run_stats.damage_taken==100)
		game.change_phase("lost")
		assert(game.finished_run.new_stats.is_empty() and game.finished_run.first==(i==0))
		assert(game.finished_run.best_combo==6)
		for frame in 34:
			game.wipe.advance(.13)
			await process_frame
		game.results_view.age=2
		game.results_view.content.queue_redraw()
		await snap("results-first" if i==0 else "results-tied")
	game.preview_results()
	assert(game.records.path.is_empty() and game.finished_run.score==1284500)
	for frame in 34:
		game.wipe.advance(.13)
		await process_frame
	game.results_view.age=2
	game.results_view.content.queue_redraw()
	await snap("results-final")
	if capture:
		game.menu_action("QUIT TO TITLE")
		game.menu_action("CONTROLS")
		await snap("controls-font-check")
	game.free()
	print("CAIRN_RESULTS_UI_OK: tracking, empty and populated navigation, responsive bounds, scrolling and stable results")
	quit()
