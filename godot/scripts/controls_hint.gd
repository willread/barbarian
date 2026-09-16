extends CanvasLayer
const DELAY=3.0
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
var click: AudioStreamPlayer
var font=preload("res://art/controls/cinzel.ttf")

func _ready():
	layer=2600
	process_mode=Node.PROCESS_MODE_ALWAYS
	var config=ConfigFile.new()
	if config.load(save_path)==OK:dismissed=config.get_value("controls","dismissed",false)
	canvas=preload("res://scripts/stone_dialog.gd").new()
	canvas.title="View the controls?"
	canvas.body="You can find them any time under"
	canvas.detail="Options / Game / Controls"
	canvas.buttons.assign(["VIEW CONTROLS","NO THANKS"])
	add_child(canvas)
	canvas.chosen.connect(func(index):selected=index;choose())
	canvas.cancelled.connect(close)
	click=AudioStreamPlayer.new();click.bus=&"Foley";add_child(click)
	canvas.sound_requested.connect(func(id):
		if game.muted:return
		click.stream=game.audio.clips.get(id)
		click.volume_db=game.audio.volumes.get(id,0.0)
		if click.stream:click.play())
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
	canvas.selected=0;canvas.heat=[1.0,0.0];canvas.show()
	show()
	canvas.queue_redraw()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

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
	canvas.handle(event)

func _exit_tree():
	if active:get_tree().paused=previous_pause
