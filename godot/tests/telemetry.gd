extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate();root.add_child(game);game.set_process(false)
	var t=game.telemetry
	assert(not t.network_enabled,"Tests must never contact the collector")
	t.set_enabled(true)
	var reports=[]
	t.summary_ready.connect(func(report):reports.append(report))
	game.start_game();game.transition=-1;game.stage_walk="";game.hero.x=720
	t.advance(180)
	assert(game.m.begin(game.hero,"slash"));assert(not game.m.begin(game.hero,"slash"))
	game.score=6000
	game.change_phase("dying")
	assert(reports.size()==1 and reports[0].moves.normal==1 and reports[0].outcome=="died")
	assert(reports[0].duration=="3_5m" and reports[0].score=="5000_9999")
	game.change_phase("lost");assert(reports.size()==1)
	game.start_game();game.transition=-1;game.stage_walk=""
	t.advance(10);game.change_phase("paused");game._process(.25);assert(t.elapsed==10)
	t.set_enabled(false);assert(t.active.is_empty())
	game.change_phase("title");assert(reports.size()==1)
	t.set_enabled(true);game.start_game();game.wave=4;game.spawn_wave()
	assert(reports.size()==2 and reports[1].outcome=="completed" and t.active.level==2)
	game.change_phase("title");assert(reports.size()==3 and reports[2].outcome=="quit")
	t.policy_completed(0,200,[], '{"default_enabled":false}'.to_utf8_buffer());assert(t.enabled,"Late policy must not overwrite choice")
	game.change_phase("title");game.title_intro=1.25;game.statistics_panel.focused=false
	game.menu.selected=game.menu.items.size()-1
	var key=InputEventKey.new();key.pressed=true;key.keycode=KEY_DOWN
	assert(game.statistics_panel.handle(key) and game.statistics_panel.focused)
	key.keycode=KEY_ENTER;game.statistics_panel.handle(key);assert(not t.enabled)
	key.keycode=KEY_RIGHT;game.statistics_panel.handle(key);assert(game.statistics_panel.details)
	key.keycode=KEY_ESCAPE;game.statistics_panel.handle(key);assert(not game.statistics_panel.details)
	var controller=InputEventJoypadButton.new();controller.button_index=JOY_BUTTON_A;controller.pressed=true
	game._input(controller);assert(t.enabled,"Controller confirms the focused statistics toggle")
	t.save_path="user://statistics-test.cfg";t.network_enabled=true;t.set_enabled(false)
	var saved=ConfigFile.new();assert(saved.load(t.save_path)==OK and saved.get_value("statistics","enabled")==false)
	t.network_enabled=false
	if "--statistics-capture" in OS.get_cmdline_user_args():
		t.set_enabled(true);game.statistics_panel.focused=false
		game.transition=-1;game.pause_cover=0;game._process(0)
		game.menu.set_process(true)
		await create_timer(2.0).timeout
		game.overlay.queue_redraw()
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/statistics-title.png")
	game.queue_free();await process_frame
	print("Telemetry lifecycle and title controls passed");quit()
