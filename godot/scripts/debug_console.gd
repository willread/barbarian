extends CanvasLayer
var game: Node2D
var input: LineEdit
var output: Label
var panel: PanelContainer
var previous_pause=false
func _ready():
 process_mode=Node.PROCESS_MODE_ALWAYS
 layer=3000
 panel=PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 panel.offset_bottom=180
 var style=StyleBoxFlat.new()
 style.bg_color=Color(.025,.03,.025,.96)
 style.content_margin_left=24;style.content_margin_right=24
 style.content_margin_top=18;style.content_margin_bottom=18
 panel.add_theme_stylebox_override("panel",style)
 add_child(panel)
 var box=VBoxContainer.new()
 panel.add_child(box)
 var title=Label.new()
 title.text="DEBUG CONSOLE  |  ~ or Esc to close"
 box.add_child(title)
 output=Label.new()
 output.text="HEALME - restore health    FASTTRAVEL - next area"
 box.add_child(output)
 input=LineEdit.new()
 input.placeholder_text="Enter cheat code..."
 input.add_theme_font_size_override("font_size",22)
 box.add_child(input)
 input.text_submitted.connect(execute)
 hide()
func toggle():
 if visible:
  hide()
  get_tree().paused=previous_pause
  input.release_focus()
 else:
  previous_pause=get_tree().paused
  get_tree().paused=true
  show()
  input.clear()
  input.grab_focus()
 game.bindings.clear();game.keys.clear();game.pressed.clear()
func _input(event: InputEvent):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode==KEY_QUOTELEFT or event.keycode==KEY_QUOTELEFT or event.unicode==126:
   toggle()
   get_viewport().set_input_as_handled()
  elif visible and event.keycode==KEY_ESCAPE:
   toggle()
   get_viewport().set_input_as_handled()
func execute(text: String):
 var code=text.strip_edges().to_upper()
 input.clear()
 if game.phase not in ["playing","paused"]:
  output.text="Start or resume a run to use cheats."
  return
 match code:
  "HEALME":
   game.hero.hp=game.hero.max
   game.displayed_health=game.hero.max
   output.text="Health restored."
  "FASTTRAVEL":
   var area=game.screen_for_wave(game.wave)
   if area>=4:
    output.text="Already in the final area."
    return
   game.wave=area*3+1
   game.spawn_wave()
   game.begin_walk("enter")
   game.transition=game.CLOSE+game.HOLD
   game.swapped=true
   output.text="Travelled to area %d. Close the console to continue."%(area+1)
  _:output.text="Unknown code: "+code
func _exit_tree():
 if visible:get_tree().paused=previous_pause
