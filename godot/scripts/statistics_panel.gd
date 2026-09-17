extends CanvasLayer
var game: Node2D
var canvas: Node2D
var hover=false
var font=preload("res://art/controls/cinzel.ttf")
const TOGGLE=Rect2(1080,760,336,30)
const CHECK=Rect2(1084,764,20,20)

func _ready():
	layer=2150
	canvas=Node2D.new();add_child(canvas);canvas.draw.connect(paint)
	game.telemetry.changed.connect(func():canvas.queue_redraw())
	get_viewport().size_changed.connect(layout);layout()

func layout():
	var size=get_viewport().get_visible_rect().size
	var factor=minf(size.x/1440,size.y/810)
	transform=Transform2D(0,Vector2.ONE*factor,0,(size-Vector2(1440,810)*factor)*.5)

func available() -> bool:
	return game.phase in ["title","paused"] and game.menu.visible and not game.loading_menu and not is_instance_valid(game.episode_intro) and not is_instance_valid(game.hall_view) and not is_instance_valid(game.upgrade_view) and not game.controls_hint.active

func _process(_dt: float):
	visible=available()
	if not visible:hover=false
	canvas.queue_redraw()

func paint():
	var ink=Color("fff1ce") if hover else Color("d8cdb8")
	canvas.draw_rect(CHECK,Color("151411"))
	canvas.draw_rect(CHECK,ink,false,1.0)
	if game.telemetry.enabled:
		canvas.draw_polyline(PackedVector2Array([Vector2(1088,774),Vector2(1093,779),Vector2(1100,769)]),ink,2.0,true)
	canvas.draw_string(font,Vector2(1114,780),"Share anonymous statistics",HORIZONTAL_ALIGNMENT_LEFT,-1,17,ink)

func handle(event: InputEvent) -> bool:
	if not available():return false
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var point=canvas.get_global_transform_with_canvas().affine_inverse()*event.position
		hover=TOGGLE.has_point(point)
		if hover and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			game.telemetry.set_enabled(not game.telemetry.enabled)
			game.audio.play("menu_select",-8)
			return true
	return false
