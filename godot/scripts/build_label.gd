extends CanvasLayer
const INFO=preload("res://scripts/build_info.gd")
const SPACING=preload("res://scripts/ui_spacing.gd")
var label: Label
func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	layer=3500
	label=Label.new()
	label.text="v%s · build %d"%[INFO.VERSION,INFO.BUILD]
	label.add_theme_font_override("font",load("res://assets/cinzel.ttf"))
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",Color(1,1,1,.30))
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(label)
	get_viewport().size_changed.connect(layout)
	layout()
func _process(_dt: float):
	var game=get_tree().current_scene
	visible=is_instance_valid(game) and game.get("phase")=="title" and game.get("options")==false and game.get("chapter_select")==false and game.get("difficulty_select")==false and not game.get("loading_menu") and is_instance_valid(game.get("menu")) and game.menu.visible and not is_instance_valid(game.get("episode_intro"))
func layout():
	var size=get_viewport().get_visible_rect().size
	var factor=minf(size.x/1440.,size.y/810.)
	transform=Transform2D(0,Vector2.ONE*factor,0,Vector2.ZERO)
	label.position=Vector2(size.x/factor-label.get_minimum_size().x-SPACING.SCREEN_EDGE,SPACING.SCREEN_EDGE)
