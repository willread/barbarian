extends SceneTree
func key(code: int,down: bool) -> InputEventKey:
 var e=InputEventKey.new()
 e.keycode=code
 e.pressed=down
 return e
func _init():call_deferred("check")
func check():
 var b=CairnBindings.new()
 assert(b.gameplay(key(KEY_J,true))==[[KEY_J,true]])
 var mouse=InputEventMouseButton.new()
 mouse.button_index=MOUSE_BUTTON_LEFT
 mouse.pressed=true
 assert(b.gameplay(mouse).is_empty())
 assert(b.gameplay(key(KEY_J,false)).is_empty())
 mouse.pressed=false
 assert(b.gameplay(mouse)==[[KEY_J,false]])
 assert(b.gameplay(key(KEY_K,true))==[[KEY_SPACE,true]])
 assert(b.gameplay(key(KEY_L,true))==[[KEY_K,true]])
 b.clear()
 var pad=InputEventJoypadButton.new()
 pad.button_index=JOY_BUTTON_X
 pad.pressed=true
 assert(b.gameplay(pad)==[[KEY_J,true]])
 pad.button_index=JOY_BUTTON_A
 assert(b.menu_event(pad).keycode==KEY_ENTER)
 var axis=InputEventJoypadMotion.new()
 axis.axis=JOY_AXIS_LEFT_X
 axis.axis_value=.2
 assert(b.gameplay(axis).is_empty())
 axis.axis_value=.8
 assert(b.gameplay(axis)==[[KEY_D,true]])
 axis.axis_value=0
 assert(b.gameplay(axis)==[[KEY_D,false]])
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.loading_menu=false
 game.settings_page="game"
 assert("CONTROLS" in game.option_labels())
 game.options=true
 game.menu_action("CONTROLS")
 await process_frame
 assert(is_instance_valid(game.controls_view) and not game.menu.visible)
 game.menu_action("BACK")
 assert(game.settings_page=="game" and game.menu.visible)
 print("CAIRN_BINDINGS_OK: shared holds, key aliases, controller, dead zone, controls navigation")
 quit()
