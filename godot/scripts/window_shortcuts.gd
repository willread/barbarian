extends Node
func _ready():process_mode=Node.PROCESS_MODE_ALWAYS
func _input(event: InputEvent):
	if event is InputEventKey and event.alt_pressed and event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
		if event.pressed and not event.echo:
			WindowPreferences.toggle_fullscreen()
			var game=get_parent().scene
			if is_instance_valid(game) and game.get("options")==true and game.get("settings_page")=="display":game.refresh_settings(0)
		get_viewport().set_input_as_handled()
