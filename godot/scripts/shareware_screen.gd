extends CanvasLayer
signal closed
signal quit_requested
const STORE_URL="https://maxforcegames.itch.io/"
const DESIGN=Vector2(1672,941)
const BUTTONS=[Rect2(100,692,823,116),Rect2(337,817,329,46)]
var game: Node2D
var quitting=false
var selected=0
var previous_pause=false
var canvas: Node2D
var art=preload("res://art/shareware/upgrade.png")
var font=preload("res://art/controls/cinzel.ttf")
var heat=[0.0,0.0]
var clock=0.0
var faces: Array=[]

func _ready():
	layer=2400
	process_mode=Node.PROCESS_MODE_ALWAYS
	previous_pause=get_tree().paused
	get_tree().paused=true
	canvas=Node2D.new();add_child(canvas)
	canvas.draw.connect(paint)
	for rect in BUTTONS:
		var face=Sprite2D.new()
		face.centered=false
		var texture=AtlasTexture.new();texture.atlas=art;texture.region=rect
		face.texture=texture;face.position=rect.position
		var material=ShaderMaterial.new()
		material.shader=preload("res://shaders/shareware_button.gdshader")
		material.set_shader_parameter("region",Vector4(rect.position.x/DESIGN.x,rect.position.y/DESIGN.y,rect.size.x/DESIGN.x,rect.size.y/DESIGN.y))
		face.material=material
		canvas.add_child(face);faces.append(face)
	layout()
	get_viewport().size_changed.connect(layout)

func layout():
	var size=get_viewport().get_visible_rect().size
	var factor=minf(size.x/DESIGN.x,size.y/DESIGN.y)
	transform=Transform2D(0,Vector2.ONE*factor,0,(size-DESIGN*factor)*.5)

func _process(dt):
	clock+=dt
	for i in 2:
		heat[i]=move_toward(heat[i],1.0 if selected==i else 0.0,dt*5)
		faces[i].material.set_shader_parameter("highlight",heat[i])
	canvas.queue_redraw()

func centered(text: String,point: Vector2,size: int,color: Color):
	var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	canvas.draw_string(font,point-Vector2(width*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func paint():
	canvas.draw_rect(Rect2(-2000,-2000,6000,5000),Color.BLACK)
	canvas.draw_texture_rect(art,Rect2(Vector2.ZERO,DESIGN),false)
	centered("2 NEW EPISODES WITH NEW ENEMIES AND UNIQUE BOSSES",Vector2(515,672),20,Color("e8d8b5"))
	# Draw live text above the highlighted stone button face.
	queue_redraw_label()

func queue_redraw_label():
	if not canvas.has_node("Label"):
		var label=Node2D.new();label.name="Label";canvas.add_child(label)
		label.draw.connect(func():
			var text="QUIT GAME" if quitting else "BACK TO GAME"
			var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
			label.draw_string(font,Vector2(501-width*.5,847),text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff0cf")*(1+heat[1]*.25)))
	canvas.get_node("Label").queue_redraw()

func activate():
	if selected==0:
		OS.shell_open(STORE_URL)
	elif quitting:quit_requested.emit()
	else:closed.emit()

func handle(event: InputEvent):
	if event is InputEventJoypadMotion:
		var translated=game.bindings.menu_event(event)
		if translated:handle(translated)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_UP,KEY_DOWN,KEY_W,KEY_S,KEY_TAB]:selected=1-selected
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:activate()
		elif event.keycode==KEY_ESCAPE:closed.emit()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:selected=1-selected
		elif event.button_index==JOY_BUTTON_A:activate()
		elif event.button_index==JOY_BUTTON_B:closed.emit()
	elif event is InputEventMouseMotion or event is InputEventMouseButton:
		var point=transform.affine_inverse()*event.position
		for i in 2:
			if BUTTONS[i].has_point(point):
				selected=i
				if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:activate()

func _input(event: InputEvent):
	if not game.cursor_input.accept(event):
		get_viewport().set_input_as_handled()
		return
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if game.cursor_input.mouse_active else Input.MOUSE_MODE_HIDDEN
	handle(event)
	get_viewport().set_input_as_handled()

func _exit_tree():
	get_tree().paused=previous_pause
