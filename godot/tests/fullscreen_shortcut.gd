extends SceneTree
func _init():call_deferred("check")
func check():
	var shell=load("res://presentation.tscn").instantiate()
	root.add_child(shell)
	current_scene=shell
	await create_timer(2.).timeout
	var key=InputEventKey.new()
	key.keycode=KEY_ENTER
	key.alt_pressed=true
	key.pressed=true
	root.mode=Window.MODE_WINDOWED
	root.push_input(key)
	assert(root.mode==Window.MODE_FULLSCREEN)
	key.echo=true
	root.push_input(key)
	assert(root.mode==Window.MODE_FULLSCREEN,"Holding Alt+Enter must not repeatedly toggle")
	key.echo=false
	paused=true
	root.push_input(key)
	assert(root.mode==Window.MODE_WINDOWED,"Shortcut works even while the game is frozen")
	paused=false
	assert(not shell.scene.chapter_select,"Fullscreen shortcut must not activate a menu item")
	print("CAIRN_FULLSCREEN_SHORTCUT_OK: toggle both ways, frozen game, no repeat or menu activation")
	quit()
