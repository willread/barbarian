extends Node
# Native window state is independent of audio preferences and survives scene changes.
var enabled=false
var elapsed=0.0
var resize_pending=false
var resize_quiet=0.0
var correcting_size=false
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
	window.min_size=Vector2i(640,360)
	constrain_window()
	window.size_changed.connect(queue_window_constraint)
	last_state=current_state()
	window.close_requested.connect(save_window)
func current_state() -> Dictionary:
	var window=get_window()
	if window.mode==Window.MODE_WINDOWED and not resize_pending:
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
	if resize_pending:
		resize_quiet+=dt
		# Query native buttons, including the non-client resize border. Never
		# change the OS rectangle while its sizing drag still owns the pointer.
		if resize_quiet<.12 or DisplayServer.mouse_get_button_state() & MOUSE_BUTTON_MASK_LEFT:return
		constrain_window()
		resize_pending=false
	elapsed+=dt
	if elapsed<.5:return
	elapsed=0
	if current_state()!=last_state:save_window()

func queue_window_constraint():
	if not enabled or correcting_size:return
	resize_pending=true
	resize_quiet=0.0

# Quantize to whole 16x9 units: no stretched client area, even after OS snapping.
static func fit_window_size(requested: Vector2i, limit: Vector2i, previous: Vector2i=Vector2i.ZERO) -> Vector2i:
	var units=roundi(float(requested.x)/16.0)
	if previous!=Vector2i.ZERO and abs(requested.y-previous.y)>abs(requested.x-previous.x):
		units=roundi(float(requested.y)/9.0)
	var maximum=maxi(1,mini(limit.x/16,limit.y/9))
	return Vector2i(16,9)*clampi(units,mini(40,maximum),maximum)

func constrain_window():
	if not enabled:return
	var window=get_window()
	if window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN,Window.MODE_MINIMIZED]:return
	var area=DisplayServer.screen_get_usable_rect(window.current_screen)
	# Leave room for the native title bar and resize borders.
	var limit=area.size-Vector2i(16,48)
	var maximized=window.mode==Window.MODE_MAXIMIZED
	var target=fit_window_size(limit if maximized else window.size,limit,Vector2i.ZERO if maximized else windowed_size)
	var anchor=window.position
	if resize_pending and not maximized:
		if window.position.x!=windowed_position.x:anchor.x+=window.size.x-target.x
		if window.position.y!=windowed_position.y:anchor.y+=window.size.y-target.y
	correcting_size=true
	if maximized:window.mode=Window.MODE_WINDOWED
	if window.size!=target:
		window.size=target
		window.position=anchor
	if maximized:window.position=area.position+(area.size-target)/2
	windowed_size=target
	windowed_position=window.position
	correcting_size=false

func open_scene(path: String):
	var scene=get_tree().current_scene
	if is_instance_valid(scene) and scene.has_method("show_scene"):
		scene.show_scene(load(path))
	else:
		get_tree().change_scene_to_file(path)

func toggle_fullscreen():
	var window=get_window()
	var fullscreen=window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]
	window.mode=Window.MODE_WINDOWED if fullscreen else Window.MODE_FULLSCREEN
