extends CanvasLayer
var game: Node2D
var canvas: Node2D
var hover=false
var font=preload("res://art/controls/cinzel.ttf")
const SPACING=preload("res://scripts/ui_spacing.gd")
const TEXT="Share anonymous statistics"
var toggle=Rect2()
var check=Rect2()
var text_origin=Vector2.ZERO

func _ready():
	layer=2150
	canvas=Node2D.new();add_child(canvas);canvas.draw.connect(paint)
	game.telemetry.changed.connect(func():canvas.queue_redraw())
	get_viewport().size_changed.connect(layout);layout()

func layout():
	var size=get_viewport().get_visible_rect().size
	var factor=minf(size.x/1440,size.y/810)
	transform=Transform2D(0,Vector2.ONE*factor,0,Vector2.ZERO)
	var logical=size/factor
	var width=font.get_string_size(TEXT,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
	check=Rect2(logical.x-SPACING.SCREEN_EDGE-width-30,logical.y-SPACING.SCREEN_EDGE-20,20,20)
	text_origin=Vector2(check.end.x+10,check.position.y+(20-font.get_height(17))*.5+font.get_ascent(17))
	toggle=Rect2(check.position,Vector2(width+30,20)).grow(4)
	canvas.queue_redraw()

func available() -> bool:
	return game.phase in ["title","paused"] and game.menu.visible and not game.loading_menu and not is_instance_valid(game.episode_intro) and not is_instance_valid(game.hall_view) and not is_instance_valid(game.upgrade_view) and not game.controls_hint.active

func _process(_dt: float):
	visible=available()
	if not visible:hover=false
	canvas.queue_redraw()

func paint():
	var ink=Color("fff1ce") if hover else Color("d8cdb8")
	canvas.draw_rect(check,Color("151411"))
	canvas.draw_rect(check,ink,false,1.0)
	if game.telemetry.enabled:
		canvas.draw_polyline(PackedVector2Array([check.position+Vector2(4,10),check.position+Vector2(9,15),check.position+Vector2(16,5)]),ink,2.0,true)
	canvas.draw_string(font,text_origin,TEXT,HORIZONTAL_ALIGNMENT_LEFT,-1,17,ink)

func handle(event: InputEvent) -> bool:
	if not available():return false
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var point=canvas.get_global_transform_with_canvas().affine_inverse()*event.position
		hover=toggle.has_point(point)
		if hover and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			game.telemetry.set_enabled(not game.telemetry.enabled)
			game.audio.play("menu_select",-8)
			return true
	return false
