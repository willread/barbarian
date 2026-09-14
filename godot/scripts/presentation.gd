extends Control
# Render the entire game, including CanvasLayer menus, inside one fixed composition.
const DESIGN=Vector2i(1440,810)
var container: SubViewportContainer
var game_view: SubViewport
var scene: Node
var frame=Rect2()
var stone: Texture2D
var masonry: ColorRect

func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	get_window().content_scale_size=Vector2i.ZERO
	stone=load("res://art/stone-border-v1.png")
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	masonry=ColorRect.new()
	masonry.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material=ShaderMaterial.new()
	material.shader=load("res://shaders/stone_frame.gdshader")
	material.set_shader_parameter("stone",stone)
	masonry.material=material
	add_child(masonry)
	container=SubViewportContainer.new()
	container.stretch=true
	container.mouse_filter=Control.MOUSE_FILTER_PASS
	add_child(container)
	game_view=SubViewport.new()
	game_view.size=DESIGN
	game_view.size_2d_override=DESIGN
	game_view.size_2d_override_stretch=true
	game_view.handle_input_locally=true
	game_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	container.add_child(game_view)
	# The frame must redraw while paused; the game retains normal pause behavior.
	game_view.process_mode=Node.PROCESS_MODE_PAUSABLE
	get_window().size_changed.connect(layout)
	layout()
	# Last child receives shortcuts before the game container can consume them.
	var shortcuts=Node.new()
	shortcuts.set_script(load("res://scripts/window_shortcuts.gd"))
	add_child(shortcuts)
	show_scene(load("res://boot.tscn"))

func show_scene(packed: PackedScene):
	if is_instance_valid(scene):
		game_view.remove_child(scene)
		scene.queue_free()
	scene=packed.instantiate()
	game_view.add_child(scene)

static func fit_rect(dimensions: Vector2) -> Rect2:
	var factor=minf(dimensions.x/DESIGN.x,dimensions.y/DESIGN.y)
	var fitted=Vector2(DESIGN)*factor
	return Rect2((dimensions-fitted)*.5,fitted)

func layout():
	size=Vector2(get_window().size)
	frame=fit_rect(size)
	container.position=frame.position.round()
	container.size=frame.size.round()
	masonry.size=size
	masonry.material.set_shader_parameter("screen_size",size)
	masonry.material.set_shader_parameter("opening",Vector4(frame.position.x,frame.position.y,frame.end.x,frame.end.y))
	masonry.material.set_shader_parameter("game_scale",frame.size.y/DESIGN.y)

