extends CanvasLayer
const TIPS=[
	"Dash to escape sticky situations",
	"Hold attack to spin and get yourself out of tight situations",
	"double tap a direction to dash, follow with an attack to charge",
	"remember to unleash your magic when the gauge is full",
	"grab a snack when your health is low",
	"build your score multiplier by landing hits without taking damage",
	"Big enemy variants are immune to some attacks",
	"If an enemy throws something at you, hit it right back",
	"It's rumored that chickens sometimes lay golden eggs with strange powers",
]
var current=""
var cover: ColorRect
var label: Label
func _ready():
	layer=5
	cover=ColorRect.new()
	cover.color=Color.BLACK
	cover.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(cover)
	label=Label.new()
	label.add_theme_font_override("font",preload("res://art/controls/cinzel.ttf"))
	label.add_theme_color_override("font_color",Color.WHITE)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	cover.add_child(label)
	cover.hide()
func choose():
	var candidates=TIPS.duplicate()
	candidates.erase(current)
	current=candidates.pick_random()
func update(age: float,close_time: float,hold: float,size: Vector2):
	cover.visible=age>=close_time and age<close_time+hold and current!=""
	cover.size=size
	label.position=Vector2(size.x*.05,size.y*.3)
	label.size=Vector2(size.x*.90,size.y*.4)
	label.add_theme_font_size_override("font_size",clampi(int(size.x/36),24,44))
	label.text=current
