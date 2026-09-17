extends CanvasLayer
const INFO=preload("res://scripts/build_info.gd")
var label: Label
func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	layer=3500
	label=Label.new()
	label.text="v%s · build %d"%[INFO.VERSION,INFO.BUILD]
	label.add_theme_font_size_override("font_size",12)
	label.add_theme_color_override("font_color",Color(1,1,1,.38))
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(label)
	get_viewport().size_changed.connect(layout)
	layout()
func layout():
	label.position=Vector2(get_viewport().get_visible_rect().size.x-label.get_minimum_size().x-12,7)
