extends CanvasLayer
var game: Node2D
var canvas: Node2D
var focused=false
var details=false
var hover=false
var glow=0.0
var font=preload("res://art/controls/cinzel.ttf")
const PANEL=Rect2(970,668,434,108)
const TOGGLE=Rect2(981,690,408,44)
const INFO=Rect2(1301,739,86,26)
const DETAIL=Rect2(370,208,700,394)

func _ready():
	layer=2150
	canvas=Node2D.new();add_child(canvas);canvas.draw.connect(paint)
	game.telemetry.changed.connect(func():canvas.queue_redraw())
	get_viewport().size_changed.connect(layout);layout()

func layout():
	var size=get_viewport().get_visible_rect().size
	var factor=minf(size.x/1440, size.y/810)
	transform=Transform2D(0,Vector2.ONE*factor,0,(size-Vector2(1440,810)*factor)*.5)

func available() -> bool:
	return game.phase in ["title","paused"] and game.menu.visible and not game.loading_menu and not is_instance_valid(game.episode_intro) and not is_instance_valid(game.hall_view) and not is_instance_valid(game.upgrade_view) and not game.controls_hint.active

func _process(dt: float):
	visible=available()
	if not visible:focused=false;details=false
	glow=move_toward(glow,1.0 if focused or hover else 0.0,dt*5)
	canvas.queue_redraw()

func text(value: String,point: Vector2,size: int,color: Color):
	canvas.draw_string(font,point+Vector2(0,1),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(0,0,0,.9))
	canvas.draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func frame(rect: Rect2):
	canvas.draw_style_box(style(Color("171615ed"),Color("766044").lerp(Color("dca262"),glow)),rect)
	canvas.draw_line(rect.position+Vector2(12,3),Vector2(rect.end.x-12,rect.position.y+3),Color("b3874d66"),1,true)
	for x in [rect.position.x+8,rect.end.x-8]:
		for y in [rect.position.y+8,rect.end.y-8]:
			canvas.draw_circle(Vector2(x,y),2,Color("9c8051"))

func style(bg: Color,border: Color) -> StyleBoxFlat:
	var box=StyleBoxFlat.new();box.bg_color=bg;box.border_color=border;box.set_border_width_all(1);box.set_corner_radius_all(3)
	box.shadow_color=Color(0,0,0,.65);box.shadow_size=8
	return box

func paint():
	frame(PANEL)
	text("HELP SHAPE CAIRN",Vector2(990,688),12,Color("b99b71"))
	var check=Rect2(990,701,22,22)
	if game.telemetry.enabled:
		canvas.draw_style_box(style(Color("5c321b"),Color("eab875")),check)
		canvas.draw_polyline(PackedVector2Array([Vector2(994,712),Vector2(999,717),Vector2(1008,706)]),Color("ffe0a1"),2.5,true)
	else:canvas.draw_style_box(style(Color("090b0d"),Color("827459")),check)
	text("Share anonymous statistics",Vector2(1024,719),17,Color("eee0c5").lerp(Color("fff1ce"),glow))
	text("Gameplay totals. No player profiles.",Vector2(990,748),12,Color("c0b8a9"))
	text("DETAILS",Vector2(1312,756),12,Color("d6ad72"))
	if focused:text("← DETAILS   •   ENTER / A TO TOGGLE",Vector2(990,793),11,Color("dcc59c"))
	if details:
		canvas.draw_rect(Rect2(0,0,1440,810),Color(0,0,0,.8));frame(DETAIL)
		text("A SMALL PART IN THE LEGEND",Vector2(407,253),24,Color("f2d09a"))
		var lines=["Share counts of moves, level outcomes and features used,","plus broad ranges for playtime and score.","","We combine reports into totals to improve Cairn.","No names, device IDs or player histories are stored.","Network addresses are processed for abuse prevention.","","Switch off at any time here, including from the pause menu.","Already combined totals cannot be traced back to you."]
		for i in lines.size():text(lines[i],Vector2(407,289+i*25),15,Color("d3c7b4"))
		text("ESC / B OR CLICK TO RETURN",Vector2(407,573),14,Color("e8b975"))

func handle(event: InputEvent) -> bool:
	if not available():return false
	if details:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_ENTER,KEY_SPACE,KEY_LEFT]:details=false
		if event is InputEventMouseButton and event.pressed:details=false
		return true
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var point=canvas.get_global_transform_with_canvas().affine_inverse()*event.position
		hover=PANEL.has_point(point)
		if event is InputEventMouseMotion and not hover:focused=false
		if hover and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			focused=true
			if INFO.has_point(point):details=true
			else:game.telemetry.set_enabled(not game.telemetry.enabled)
			game.audio.play("menu_select",-8)
			return true
		return hover
	if event is InputEventKey and event.pressed and not event.echo:
		if focused:
			match event.keycode:
				KEY_ENTER,KEY_SPACE:game.telemetry.set_enabled(not game.telemetry.enabled);game.audio.play("menu_select",-8)
				KEY_LEFT,KEY_RIGHT:details=true
				KEY_UP:focused=false;game.menu.select(game.menu.items.size()-1)
				KEY_DOWN,KEY_TAB:focused=false;game.menu.select(0)
				KEY_ESCAPE:focused=false
			return true
		if not game.menu.switching and ((event.keycode in [KEY_DOWN,KEY_TAB] and not event.shift_pressed and game.menu.selected==game.menu.items.size()-1) or (event.keycode==KEY_UP and game.menu.selected==0)):
			focused=true
			return true
	return false
