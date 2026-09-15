extends CanvasLayer
const LETTER_SPACING=64.0 # Fixed centers, independent of glyph width.
var game: Node2D
var previous_pause=false
var code=""
var letters: Array=[]
var tweens: Array=[]
var falls: Dictionary={}
var textures: Dictionary={}
var landing_count=0
var generation=0
var glyphs: Dictionary
func _ready():
 process_mode=Node.PROCESS_MODE_ALWAYS
 layer=3000
 glyphs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/cheat-letters.json")).menu
 for ch in glyphs:textures[ch]=game.art.texture("menu-"+glyphs[ch].id+".png")
 hide()
func toggle():
 if visible:
  close()
 elif game.phase=="playing":
  previous_pause=get_tree().paused
  get_tree().paused=true
  code=""
  landing_count=0
  show()
  for i in 3:
   var face=Sprite2D.new()
   face.texture=textures["?"]
   face.scale=Vector2(glyphs["?"].width,glyphs["?"].height)/face.texture.get_size()
   add_child(face);letters.append(face)
  arrange()
  for face in letters:drop(face,false)
 game.bindings.clear();game.keys.clear();game.pressed.clear()
func close():
 generation+=1
 for tween in tweens:
  if tween.is_valid():tween.kill()
 tweens.clear()
 falls.clear()
 for letter in letters:letter.queue_free()
 letters.clear()
 code=""
 hide()
 get_tree().paused=previous_pause
 game.bindings.clear();game.keys.clear();game.pressed.clear()
func _input(event: InputEvent):
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode==KEY_QUOTELEFT or event.keycode==KEY_QUOTELEFT or event.unicode==126:
   toggle()
   get_viewport().set_input_as_handled()
  elif visible:
   if event.keycode==KEY_ESCAPE:close()
   elif event.unicode>0:accept_letter(String.chr(event.unicode).to_upper())
   get_viewport().set_input_as_handled()
func accept_letter(ch: String):
 if not visible or code.length()>=3 or ch.length()!=1 or not glyphs.has(ch):return
 if ch=="?":return
 var face=letters[code.length()]
 code+=ch
 var meta=glyphs[ch]
 face.texture=textures[ch]
 face.scale=Vector2(meta.width,meta.height)/face.texture.get_size()
 drop(face,true)
func arrange():
 var center=get_viewport().get_visible_rect().size*.5
 for i in letters.size():
  letters[i].position.x=center.x+(i-1)*LETTER_SPACING
func drop(face: Sprite2D,count_landing: bool):
 var id=face.get_instance_id()
 if falls.has(id) and falls[id].is_valid():falls[id].kill()
 var center=get_viewport().get_visible_rect().size*.5
 face.position.y=0
 var tween=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
 tweens.append(tween)
 falls[id]=tween
 tween.tween_property(face,"position:y",center.y,.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
 tween.tween_callback(func():game.audio.play("menu_land"))
 tween.tween_property(face,"position:y",center.y+2.6,.024)
 tween.tween_property(face,"position:y",center.y-4.9,.048)
 tween.tween_property(face,"position:y",center.y,.0816)
 if count_landing:tween.tween_callback(landed)
func landed():
 landing_count+=1
 if code.length()==3 and landing_count==3:
  var token=generation
  await get_tree().create_timer(.08,true).timeout
  if visible and token==generation:execute(code)
func execute(text: String):
 if game.phase=="playing":
  match text.to_upper():
   "TNT":game.kill_visible_enemies()
   "HOH":game.unlock_candy_session()
   "EMT":
    game.hero.hp=game.hero.max
    game.displayed_health=game.hero.max
   "KFC":game.summon_chicken(Vector2(clampf(game.hero.x+120,90,1300),game.hero.y))
   "CEO":travel(game.encounters.size())
   "FWD":
    var area=game.screen_for_wave(game.wave)
    if area<4:travel(area*3+1)
 close()
func travel(wave: int):
 game.wave=wave
 game.spawn_wave()
 game.begin_walk("enter")
 game.transition=game.CLOSE+game.HOLD
 game.swapped=true
func _exit_tree():
 if visible:get_tree().paused=previous_pause
