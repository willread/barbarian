extends CanvasLayer
signal closed
var box: VBoxContainer
var scroll: ScrollContainer
var columns: GridContainer
var section: VBoxContainer
func _ready():
 layer=2200
 var background=ColorRect.new()
 background.color=Color(.025,.022,.019,.98)
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var margin=MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
 add_child(margin)
 scroll=ScrollContainer.new()
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 margin.add_child(scroll)
 box=VBoxContainer.new()
 box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 box.add_theme_constant_override("separation",16)
 scroll.add_child(box)
 line("CONTROLS",34)
 line("All bindings work together. No preset switching required.",17)
 columns=GridContainer.new()
 columns.add_theme_constant_override("h_separation",48)
 columns.add_theme_constant_override("v_separation",24)
 box.add_child(columns)
 get_viewport().size_changed.connect(resize_columns)
 resize_columns()
 new_section()
 line("KEYBOARD + MOUSE",24)
 for text in ["MOVE   WASD / Arrow keys","ATTACK / HOLD TO SPIN   J / Z / Left mouse","JUMP   K / X / Space","MAGIC   L / C / Right mouse","RUN   Shift (double-tap movement also works)","PAUSE / BACK   Escape     CONFIRM   Enter","FULLSCREEN   Alt + Enter"]:line(text,20)
 new_section()
 line("CONTROLLER — XBOX / PLAYSTATION",24)
 for text in ["MOVE   Left stick / D-pad","ATTACK / HOLD TO SPIN   X / Square","JUMP   A / Cross","MAGIC   Y / Triangle","RUN   RB / R1","PAUSE   Start / Options","MENUS   Stick / D-pad • A / Cross: confirm • B / Circle: back"]:line(text,20)
 section=null
 line("Charge: run + attack. Jump attack: jump, then attack.",18)
 line("Bindings are currently fixed; remapping comes later.",16)
 var back=Button.new()
 back.text="BACK"
 back.custom_minimum_size.y=48
 back.pressed.connect(func():closed.emit())
 box.add_child(back)
func line(text: String,size: int):
 var label=Label.new()
 label.text=text
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",Color(.82,.75,.61))
 (section if section else box).add_child(label)

func new_section():
 section=VBoxContainer.new()
 section.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 section.add_theme_constant_override("separation",16)
 columns.add_child(section)
func resize_columns():
 columns.columns=2 if get_viewport().get_visible_rect().size.x>=900 else 1
