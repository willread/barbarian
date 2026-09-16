extends CanvasLayer
const DELAY=3.0
const BUTTONS=[Rect2(380,440,330,64),Rect2(730,440,330,64)]
var game: Node2D
var save_path="user://controls_hint.cfg"
# Script-driven test/capture sessions must not consume the user's first-run prompt.
var enabled=not "--script" in OS.get_cmdline_args()
var dismissed=false
var elapsed=0.0
var active=false
var selected=0
var previous_pause=false
var canvas: Node2D
var controls: CanvasLayer
var font=preload("res://art/controls/cinzel.ttf")

func _ready():
	layer=2600
	process_mode=Node.PROCESS_MODE_ALWAYS
	var config=ConfigFile.new()
	if config.load(save_path)==OK:dismissed=config.get_value("controls","dismissed",false)
	canvas=Node2D.new();add_child(canvas)
	canvas.draw.connect(paint)
	hide()
	get_viewport().size_changed.connect(layout)
	layout()

func layout():
	var size=get_viewport().get_visible_rect().size
	var factor=minf(size.x/1440.,size.y/810.)
	transform=Transform2D(0,Vector2.ONE*factor,0,(size-Vector2(1440,810)*factor)*.5)
	canvas.queue_redraw()

func advance(dt: float):
	if not enabled or dismissed or active:return
	if game.phase!="playing" or game.transition>=0 or game.stage_walk!="" or game.hero.hp<=0 or game.pause_cover>0:return
	if is_instance_valid(game.episode_intro) or is_instance_valid(game.upgrade_view) or get_tree().paused:return
	elapsed+=dt
	if elapsed>=DELAY:open()

func open():
	if active or dismissed:return
	# Save before showing: even closing the application counts as dismissing it.
	dismissed=true
	var config=ConfigFile.new()
	config.set_value("controls","dismissed",true)
	config.save(save_path)
	active=true
	previous_pause=get_tree().paused
	get_tree().paused=true
	game.bindings.clear();game.keys.clear();game.pressed.clear()
	selected=0
	show()
	canvas.queue_redraw()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func text(value: String,y: float,size: int,color: Color):
	var width=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	canvas.draw_string(font,Vector2((1440-width)*.5,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func paint():
	canvas.draw_rect(Rect2(-2000,-2000,5440,4810),Color(0,0,0,.65))
	canvas.draw_rect(Rect2(260,250,920,290),Color("181716"))
	canvas.draw_rect(Rect2(260,250,920,290),Color("a9844c"),false,2)
	text("Would you like to view the controls?",321,29,Color("f2e2bf"))
	text("They're available under Options / Game / Controls",377,22,Color("d5cec0"))
	text("at any time.",409,22,Color("d5cec0"))
	for i in 2:
		canvas.draw_rect(BUTTONS[i],Color("51402a") if selected==i else Color("252321"))
		canvas.draw_rect(BUTTONS[i],Color("e0b976") if selected==i else Color("786344"),false,2)
		var label="VIEW CONTROLS" if i==0 else "NO THANKS"
		var width=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x
		canvas.draw_string(font,Vector2(BUTTONS[i].get_center().x-width*.5,480),label,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("f2e2bf"))

func choose():
	if selected==1:close();return
	canvas.hide()
	controls=preload("res://scripts/controls_view.gd").new()
	controls.art=game.art
	controls.process_mode=Node.PROCESS_MODE_ALWAYS
	game.add_child(controls)
	controls.layer=2601
	controls.closed.connect(close)

func close():
	if not active:return
	if is_instance_valid(controls):controls.queue_free();controls=null
	active=false
	hide()
	get_tree().paused=previous_pause
	game.bindings.clear();game.keys.clear();game.pressed.clear()
	game.update_mouse_cursor()

func _input(event: InputEvent):
	if not active:return
	get_viewport().set_input_as_handled()
	if not game.cursor_input.accept(event):return
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if game.cursor_input.mouse_active else Input.MOUSE_MODE_HIDDEN
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		event=game.bindings.menu_event(event)
		if not event:return
	if is_instance_valid(controls):
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			controls.scroll.scroll_vertical+=-80 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 80
		else:controls.handle(event)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:close()
		elif event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_TAB,KEY_A,KEY_D,KEY_W,KEY_S]:selected=1-selected
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:choose()
	elif event is InputEventMouseMotion or event is InputEventMouseButton:
		var point=transform.affine_inverse()*event.position
		var hit=false
		for i in 2:
			if BUTTONS[i].has_point(point):
				hit=true;selected=i
				if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:choose()
		if not hit and event is InputEventMouseButton and event.pressed:close()
	canvas.queue_redraw()

func _exit_tree():
	if active:get_tree().paused=previous_pause
