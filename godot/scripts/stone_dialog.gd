extends Node2D
signal chosen(index: int)
signal cancelled
signal sound_requested(id: String)
var title=""
var body=""
var detail=""
var buttons: Array[String]=["OK","CANCEL"]
var selected=0
var heat=[1.0,0.0]
var font=preload("res://art/controls/cinzel.ttf")
var plaque=preload("res://art/controls/dialog-plaque.png")
const PANEL=Rect2(420,280,600,250)
const BUTTONS=[Rect2(471,433,246,56),Rect2(728,433,246,56)]

func button_rect(index: int) -> Rect2:
	return Rect2(597,433,246,56) if buttons.size()==1 else BUTTONS[index]

func _process(dt: float):
	for i in 2:heat[i]=move_toward(heat[i],1.0 if i==selected else 0.0,dt*7)
	queue_redraw()

func line(value: String,y: float,size: int,color: Color):
	var width=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	if width>520:
		size=maxi(12,int(size*520/width))
		width=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	draw_string(font,Vector2(720-width*.5,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw():
	draw_rect(Rect2(-2000,-2000,5440,4810),Color(0,0,0,.65))
	draw_texture_rect(plaque,PANEL,false)
	var pixels=plaque.get_size()
	var neutral=Rect2(Vector2(.513,.612)*pixels,Vector2(.41,.225)*pixels)
	var lit=Rect2(Vector2(.085,.612)*pixels,Vector2(.41,.225)*pixels)
	if buttons.size()==1:
		# Cover the baked button row with plain slate before drawing one centered action.
		draw_texture_rect_region(plaque,Rect2(465,430,515,64),Rect2(Vector2(.1,.36)*pixels,Vector2(.8,.16)*pixels))
	line(title,344,29,Color("f5e3bd"))
	line(body,383,18,Color("bab4a9"))
	line(detail,410,20,Color("dcc398"))
	for i in mini(2,buttons.size()):
		var rect=button_rect(i)
		draw_texture_rect_region(plaque,rect,neutral)
		draw_texture_rect_region(plaque,rect,lit,Color(1,1,1,heat[i]))
		var size=19
		var width=font.get_string_size(buttons[i],HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		if width>rect.size.x-30:
			size=int(size*(rect.size.x-30)/width)
			width=font.get_string_size(buttons[i],HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
		draw_string(font,Vector2(rect.get_center().x-width*.5,468),buttons[i],HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("bdb5a6").lerp(Color("ffe1a5"),heat[i]))

func activate():
	sound_requested.emit("menu_select")
	chosen.emit(selected)

func handle(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:cancelled.emit()
		elif event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_TAB,KEY_A,KEY_D,KEY_W,KEY_S]:
			var direction=-1 if event.keycode in [KEY_LEFT,KEY_UP,KEY_A,KEY_W] or (event.keycode==KEY_TAB and event.shift_pressed) else 1
			selected=wrapi(selected+direction,0,buttons.size())
		elif event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:activate()
	elif event is InputEventMouseMotion or event is InputEventMouseButton:
		var point=get_global_transform_with_canvas().affine_inverse()*event.position
		for i in buttons.size():
			if button_rect(i).has_point(point):
				selected=i
				if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:activate()
				return
		if event is InputEventMouseButton and event.pressed and not PANEL.has_point(point):cancelled.emit()
