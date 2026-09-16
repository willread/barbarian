extends SceneTree
func _init():call_deferred("check")
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_game()
	var hint=game.controls_hint
	hint.save_path="user://controls_hint_test.cfg"
	hint.enabled=true;hint.dismissed=false
	hint.advance(10)
	assert(not hint.active,"No prompt during skull reveal or entrance")
	game.transition=-1;game.stage_walk=""
	game.hero.x=720
	game._process(0)
	hint.advance(2.9)
	assert(not paused and not hint.active)
	hint.advance(.1)
	assert(paused and hint.active and hint.dismissed)
	var clock=game.clock
	game._process(.25)
	assert(game.clock==clock,"Prompt pauses gameplay")
	if "--hint-capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("E:/Cairn-build-tools/controls-hint.png")
	game.muted=false
	var sounds=[]
	hint.canvas.sound_requested.connect(func(id):sounds.append(id))
	var hover=InputEventMouseMotion.new()
	hover.position=hint.canvas.get_global_transform_with_canvas()*hint.canvas.button_rect(1).get_center()
	hint._input(hover)
	assert(hint.canvas.selected==1 and hint.click.playing and sounds==["menu_select"],"Hover moves focus and plays the menu select sound")
	hint._input(hover)
	assert(sounds.size()==1,"Remaining over a button must not repeat the sound")
	hover.position=hint.canvas.get_global_transform_with_canvas()*hint.canvas.button_rect(0).get_center()
	hint._input(hover)
	var key=InputEventKey.new();key.pressed=true;key.keycode=KEY_TAB
	hint._input(key)
	assert(hint.canvas.selected==1)
	key.shift_pressed=true;hint._input(key)
	assert(hint.canvas.selected==0)
	key.shift_pressed=false;key.keycode=KEY_ENTER;hint._input(key)
	assert(hint.click.playing and hint.click.stream==game.audio.clips.menu_select,"Keyboard activation plays menu select while paused")
	assert(is_instance_valid(hint.controls) and paused,"Viewing controls keeps gameplay paused")
	var cancel=InputEventKey.new();cancel.keycode=KEY_ESCAPE;cancel.pressed=true
	hint._input(cancel)
	await process_frame
	assert(not paused and not hint.active)
	var saved=ConfigFile.new();assert(saved.load(hint.save_path)==OK)
	assert(saved.get_value("controls","dismissed",false))
	var next_hint=load("res://scripts/controls_hint.gd").new()
	next_hint.game=game;next_hint.save_path=hint.save_path;next_hint.enabled=true
	game.add_child(next_hint)
	next_hint.advance(20)
	assert(next_hint.dismissed and not next_hint.active,"Dismissal survives a fresh instance")
	for method in ["decline","escape","outside","controller"]:
		hint.dismissed=false;hint.open()
		match method:
			"decline":hint.selected=1;hint.choose()
			"escape":hint._input(cancel)
			"outside":
				var click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=Vector2.ZERO
				hint._input(click)
			"controller":
				var button=InputEventJoypadButton.new();button.button_index=JOY_BUTTON_B;button.pressed=true
				hint._input(button)
		assert(not hint.active and not paused and hint.dismissed)
	game.queue_free();await process_frame
	await create_timer(.15).timeout
	DirAccess.remove_absolute("user://controls_hint_test.cfg")
	print("CAIRN_CONTROLS_HINT_OK: playable delay, pause, controls, all dismiss paths and persistent suppression")
	quit()
