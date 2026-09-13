extends CanvasLayer
signal closed
var art: CairnArt
var scroll: ScrollContainer
var content: Control
var backdrop: Node2D
var back_menu: Node2D
var font=preload("res://art/controls/cinzel.ttf")
var textures={}
var viewport_size=Vector2.ZERO
var compact=false
var text_size=24
var row_height=58.0
const ROWS=[
 ["Move","W A S D / Arrow keys",["xbox_stick_l","/","xbox_dpad"],["playstation_stick_l","/","playstation_dpad"]],
 ["Attack","J / Z / Left mouse",["xbox_button_color_x_outline"],["playstation_button_color_square_outline"]],
 ["Jump","K / X / Space",["xbox_button_color_a_outline"],["playstation_button_color_cross_outline"]],
 ["Magic","L / C / Right mouse",["xbox_button_color_y_outline"],["playstation_button_color_triangle_outline"]],
 ["Run","Shift / double-tap movement",["xbox_rb"],["playstation_trigger_r1"]],
 ["Spin","Hold attack",["Hold","xbox_button_color_x_outline"],["Hold","playstation_button_color_square_outline"]],
 ["Charge","Run + attack",["xbox_rb","+","xbox_button_color_x_outline"],["playstation_trigger_r1","+","playstation_button_color_square_outline"]],
 ["Jump attack","Jump, then attack",["xbox_button_color_a_outline","then","xbox_button_color_x_outline"],["playstation_button_color_cross_outline","then","playstation_button_color_square_outline"]],
 ["Pause","Escape",["xbox_button_menu"],["playstation5_button_options"]]
]
func _ready():
 layer=2200
 font.multichannel_signed_distance_field=false
 font.oversampling=2.0
 backdrop=Node2D.new()
 add_child(backdrop)
 backdrop.draw.connect(draw_backdrop)
 scroll=ScrollContainer.new()
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 content=Control.new()
 content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 content.mouse_filter=Control.MOUSE_FILTER_IGNORE
 scroll.add_child(content)
 content.draw.connect(draw_table)
 content.resized.connect(func():content.queue_redraw())
 back_menu=load("res://scripts/menu.gd").new()
 add_child(back_menu)
 back_menu.setup(art)
 back_menu.show_items(["BACK"],false,false)
 back_menu.activated.connect(func(_label):closed.emit())
 back_menu.sound_requested.connect(func(id):get_parent().audio.play(id))
 get_viewport().size_changed.connect(layout)
 layout()
 back_menu.drop_actions()
func tex(name: String):
 if not textures.has(name):textures[name]=load("res://art/controls/"+name)
 return textures[name]
func layout():
 var pixels=Vector2(get_window().size)
 var logical_width=minf(1920,pixels.x)
 viewport_size=Vector2(logical_width,pixels.y*logical_width/maxf(1,pixels.x))
 transform=Transform2D(0,Vector2.ZERO).scaled(Vector2.ONE*(get_viewport().get_visible_rect().size.x/logical_width))
 compact=viewport_size.x<760
 text_size=clampi(int(viewport_size.x/64),18,26)
 row_height=132 if compact else clampf((viewport_size.y-249)/ROWS.size(),46,maxf(54,text_size*2.4))
 var width=viewport_size.x-32 if compact else minf(viewport_size.x*.84,1580)
 scroll.position=Vector2((viewport_size.x-width)*.5,100)
 scroll.size=Vector2(width,maxf(80,viewport_size.y-205))
 content.custom_minimum_size=Vector2(0,48+ROWS.size()*row_height)
 var item=back_menu.items[0]
 var factor=minf(96.0/item.height,viewport_size.x*.35/item.width)
 back_menu.scale=Vector2.ONE*factor
 back_menu.position=Vector2(viewport_size.x*.5,viewport_size.y-60)-Vector2(item.x,item.y+item.height*.5)*factor
 backdrop.queue_redraw()
 content.queue_redraw()
func stone(node: CanvasItem,label: String,center: Vector2,height: float,max_width: float):
 var image=tex(label.to_lower().replace(" ","-")+".png")
 var size=image.get_size()*minf(height/image.get_height(),max_width/image.get_width())
 node.draw_texture_rect(image,Rect2(center-size*.5,size),false)
func draw_backdrop():
 backdrop.draw_rect(Rect2(Vector2.ZERO,viewport_size),Color(.024,.027,.026,1))
 stone(backdrop,"CONTROLS",Vector2(viewport_size.x*.5,51),42,viewport_size.x*.75)
func text(value: String,point: Vector2,size: int,color=Color(.81,.78,.70),center=false):
 if center:point.x-=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5
 content.draw_string(font,point+Vector2(0,size*.34),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func prompts(values: Array,center: Vector2):
 var sizes=[]
 var total=0.0
 for value in values:
  var width=38.0 if value.contains("_") else font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
  sizes.append(width)
  total+=width+7
 var x=center.x-(total-7)*.5
 for i in values.size():
  var value=values[i]
  if value.contains("_"):content.draw_texture_rect(tex(value+".svg"),Rect2(x,center.y-19,38,38),false)
  else:text(value,Vector2(x,center.y),16)
  x+=sizes[i]+7
func draw_table():
 var w=content.size.x
 if w<=0:return
 var header=Color(.64,.58,.45)
 if not compact:
  text("ACTION",Vector2(w*.025,22),18,header)
  text("KEYBOARD / MOUSE",Vector2(w*.28,22),18,header)
  text("XBOX",Vector2(w*.71,22),18,header,true)
  text("PLAYSTATION",Vector2(w*.89,22),18,header,true)
 for i in ROWS.size():
  var row=ROWS[i]
  var top=44+i*row_height
  var center=top+row_height*.5
  if i%2==0:content.draw_rect(Rect2(0,top,w,row_height),Color(.7,.65,.48,.025))
  content.draw_line(Vector2(0,top),Vector2(w,top),Color(.40,.34,.24,.45))
  if compact:
   stone(content,row[0],Vector2(w*.5,top+20),23,w*.9)
   text(row[1],Vector2(w*.5,top+53),18,Color(.81,.78,.70),true)
   text("XBOX",Vector2(w*.25,top+80),12,header,true)
   text("PLAYSTATION",Vector2(w*.75,top+80),12,header,true)
   prompts(row[2],Vector2(w*.25,top+107))
   prompts(row[3],Vector2(w*.75,top+107))
  else:
   var image=tex(row[0].to_lower().replace(" ","-")+".png")
   var size=image.get_size()*minf(float(text_size)/image.get_height(),w*.235/image.get_width())
   content.draw_texture_rect(image,Rect2(Vector2(w*.025,center-size.y*.5),size),false)
   content.draw_multiline_string(font,Vector2(w*.28,center-text_size*.45+font.get_ascent(text_size)),row[1],HORIZONTAL_ALIGNMENT_LEFT,w*.34,text_size,2,Color(.81,.78,.70))
   prompts(row[2],Vector2(w*.71,center))
   prompts(row[3],Vector2(w*.89,center))
 content.draw_line(Vector2(0,44+ROWS.size()*row_height),Vector2(w,44+ROWS.size()*row_height),header)
func handle(event: InputEvent):
 if event is InputEventKey and event.pressed:
  if event.keycode==KEY_ESCAPE:closed.emit();return
  if event.keycode in [KEY_UP,KEY_W,KEY_DOWN,KEY_S]:
   scroll.scroll_vertical+=-80 if event.keycode in [KEY_UP,KEY_W] else 80
 back_menu.handle(event)
