extends Node
# Native window state is independent of audio preferences and survives scene changes.
var enabled=false
var elapsed=0.0
var last_state={}
var windowed_size=Vector2i(1280,720)
var windowed_position=Vector2i.ZERO
func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	enabled=not OS.has_feature("web") and DisplayServer.get_name()!="headless" and OS.get_cmdline_user_args().is_empty()
	if not enabled:return
	var saved=ConfigFile.new()
	var window=get_window()
	if saved.load("user://display.cfg")==OK:
		var area=DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen())
		windowed_size=saved.get_value("window","size",window.size)
		windowed_size=windowed_size.clamp(Vector2i(640,360).min(area.size),area.size)
		windowed_position=saved.get_value("window","position",area.position+(area.size-windowed_size)/2)
		windowed_position=windowed_position.clamp(area.position,area.end-windowed_size)
		window.size=windowed_size
		window.position=windowed_position
		var mode=int(saved.get_value("window","mode",Window.MODE_WINDOWED))
		if mode in [Window.MODE_MAXIMIZED,Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]: window.mode=mode
	else:
		windowed_size=window.size
		windowed_position=window.position
	last_state=current_state()
	window.close_requested.connect(save_window)
func current_state() -> Dictionary:
	var window=get_window()
	if window.mode==Window.MODE_WINDOWED:
		windowed_size=window.size
		windowed_position=window.position
	return {"size":windowed_size,"position":windowed_position,"mode":window.mode}
func save_window():
	if not enabled or get_window().mode==Window.MODE_MINIMIZED:return
	var state=current_state()
	var saved=ConfigFile.new()
	for key in state:saved.set_value("window",key,state[key])
	saved.save("user://display.cfg")
	last_state=state
func _process(dt: float):
	if not enabled:return
	elapsed+=dt
	if elapsed<.5:return
	elapsed=0
	if current_state()!=last_state:save_window()
