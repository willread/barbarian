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
var button_sprites: Array[Sprite2D]=[]

func _ready():
	for i in 2:
		var sprite=Sprite2D.new()
		sprite.texture=plaque
		sprite.region_enabled=true
		sprite.region_rect=Rect2(Vector2(.513,.612)*plaque.get_size(),Vector2(.41,.225)*plaque.get_size())
		sprite.material=ShaderMaterial.new()
		sprite.material.shader=preload("res://shaders/dialog_button.gdshader")
		add_child(sprite)
		button_sprites.append(sprite)
		# Labels render after the button surface and are never shaded with the stone.
		var label=Node2D.new()
		sprite.add_child(label)
		label.draw.connect(draw_button_label.bind(i,label))

func draw_button_label(i: int,label: Node2D):
	if i>=buttons.size():return
	var rect=button_rect(i)
	var size=19
	var width=font.get_string_size(buttons[i],HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	if width>rect.size.x-30:
		size=int(size*(rect.size.x-30)/width)
		width=font.get_string_size(buttons[i],HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	label.draw_set_transform(Vector2.ZERO,0,Vector2.ONE/button_sprites[i].scale)
	label.draw_string(font,Vector2(-width*.5,7),buttons[i],HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("bdb5a6").lerp(Color("ffe1a5"),heat[i]))

func button_rect(index: int) -> Rect2:
	return Rect2(597,433,246,56) if buttons.size()==1 else BUTTONS[index]

func _process(dt: float):
	for i in 2:heat[i]=move_toward(heat[i],1.0 if i==selected else 0.0,dt*7)
	for i in button_sprites.size():
		var sprite=button_sprites[i]
		sprite.visible=i<buttons.size()
		if not sprite.visible:continue
		var rect=button_rect(i)
		sprite.position=rect.get_center()
		sprite.scale=rect.size/sprite.region_rect.size
		sprite.material.set_shader_parameter("heat",heat[i])
		sprite.get_child(0).queue_redraw()
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
	# Remove both baked buttons, including their glow, before drawing shared surfaces.
	draw_texture_rect_region(plaque,Rect2(465,425,515,76),Rect2(Vector2(.1,.36)*pixels,Vector2(.8,.16)*pixels))
	line(title,344,29,Color("f5e3bd"))
	line(body,383,18,Color("bab4a9"))
	line(detail,410,20,Color("dcc398"))

func select_button(index: int):
	if selected==index:return
	selected=index
	sound_requested.emit("menu_select")

func activate():
	sound_requested.emit("menu_select")
	chosen.emit(selected)

func handle(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:cancelled.emit()
		elif event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_TAB,KEY_A,KEY_D,KEY_W,KEY_S]:
			var direction=-1 if event.keycode in [KEY_LEFT,KEY_UP,KEY_A,KEY_W] or (event.keycode==KEY_TAB and event.shift_pressed) else 1
			select_button(wrapi(selected+direction,0,buttons.size()))
		elif event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:activate()
	elif event is InputEventMouseMotion or event is InputEventMouseButton:
		var point=get_global_transform_with_canvas().affine_inverse()*event.position
		for i in buttons.size():
			if button_rect(i).has_point(point):
				select_button(i)
				if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:activate()
				return
		if event is InputEventMouseButton and event.pressed and not PANEL.has_point(point):cancelled.emit()
