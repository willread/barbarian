extends CanvasLayer
signal closed
var game: Node2D
var canvas: Node2D
var back_menu: Node2D
var player: AudioStreamPlayer
var selected=0
var current=-1
var names: Array=[]
var saved_pauses: Array=[]
var font=preload("res://art/controls/cinzel.ttf")
const PLACES=["MAIN MENU","EP I / THE FALLEN CITADEL","EP II / THE SUNKEN WILDS","EP III / THE ASHEN DEPTHS"]
func _ready():
 layer=2200
 canvas=Node2D.new();add_child(canvas);canvas.draw.connect(paint)
 player=AudioStreamPlayer.new();player.bus=&"Music";player.volume_db=-10;add_child(player)
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://audio_options/manifest.json"))
 for track in game.audio.tracks:
  saved_pauses.append(track.stream_paused)
  track.stream_paused=true
  var id=track.stream.resource_path.get_file().get_basename()
  var title="Roots Below" if id=="roots-below" else "Original Menu Theme" if id=="music_menu" else "Original Battle Theme"
  for job in manifest.get("jobs",[]):
   if job.get("id","")==id:title=job.get("name",title)
  names.append(title)
 back_menu=load("res://scripts/menu.gd").new()
 add_child(back_menu)
 back_menu.setup(game.art)
 back_menu.show_items(["BACK"],false,false)
 back_menu.activated.connect(func(_label):closed.emit())
 back_menu.sound_requested.connect(func(id):game.audio.play(id,-8))
 back_menu.items[0].fire.emitting=false
 back_menu.drop_actions()
 game.audio.music_preview=true
 get_viewport().size_changed.connect(layout)
 layout()
func _exit_tree():
 if is_instance_valid(game) and is_instance_valid(game.audio):
  game.audio.music_preview=false
  for i in mini(saved_pauses.size(),game.audio.tracks.size()):game.audio.tracks[i].stream_paused=saved_pauses[i]
func layout():
 var size=get_viewport().get_visible_rect().size
 var factor=minf(size.x/1440.0,size.y/810.0)
 transform=Transform2D(0,Vector2.ONE*factor,0,(size-Vector2(1440,810)*factor)*.5)
 var item=back_menu.items[0]
 var action_scale=1.0/.71
 back_menu.scale=Vector2.ONE*action_scale
 back_menu.position=Vector2(720,732)-Vector2(item.x,item.y+item.height*.5)*action_scale
func _process(_dt: float):
 player.volume_db=-60 if game.muted else -10+game.audio.volumes.get("music_menu" if current==0 else "music_game",0.0)
 back_menu.items[0].fire.emitting=selected==4
 canvas.queue_redraw()
func play_track(index: int):
 selected=wrapi(index,0,names.size());current=selected
 player.stream=game.audio.tracks[selected].stream
 player.stream_paused=false;player.play()
 game.audio.unlocked=true
func toggle():
 if selected==4:back_menu.activate();return
 if current<0 or current!=selected:play_track(selected)
 elif player.playing:player.stream_paused=not player.stream_paused
 else:play_track(selected)
func handle(event: InputEvent):
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_ESCAPE:closed.emit()
   KEY_UP:selected=wrapi(selected-1,0,5);game.audio.play("menu_select")
   KEY_DOWN:selected=wrapi(selected+1,0,5);game.audio.play("menu_select")
   KEY_ENTER,KEY_SPACE:toggle()
 elif event is InputEventMouseMotion or event is InputEventMouseButton:
  var point=transform.affine_inverse()*event.position
  for i in 4:
   if Rect2(160,180+i*86,1120,86).has_point(point):
    selected=i
    if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:toggle()
    return
  var local=back_menu.get_global_transform_with_canvas().affine_inverse()*event.position
  var item=back_menu.items[0]
  if Rect2(item.node.position-Vector2(item.width*.5,0),Vector2(item.width,item.height)).has_point(local):
   selected=4
   back_menu.handle(event)
func text(value: String,point: Vector2,size: int,color: Color=Color("e4ddc9"),center: bool=false):
 if center:point.x-=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5
 canvas.draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func paint():
 var corner=transform.affine_inverse()*Vector2.ZERO
 canvas.draw_rect(Rect2(corner,get_viewport().get_visible_rect().size/transform.get_scale()),Color(0,0,0,.9))
 text("MUSIC PLAYER",Vector2(720,87),40,Color("e4ddc9"),true)
 text("TRACK",Vector2(178,151),16,Color("bdaa7d"))
 text("USED IN",Vector2(720,151),16,Color("bdaa7d"))
 for i in 4:
  var y=180+i*86
  if selected==i:canvas.draw_rect(Rect2(160,y,1120,86),Color(.7,.48,.15,.12))
  elif i%2==0:canvas.draw_rect(Rect2(160,y,1120,86),Color(.7,.65,.48,.025))
  if current==i and player.stream:
   var progress=clampf(player.get_playback_position()/player.stream.get_length(),0,1)
   canvas.draw_rect(Rect2(160,y,1120*progress,86),Color(.7,.58,.30,.20))
  canvas.draw_line(Vector2(160,y),Vector2(1280,y),Color(.40,.34,.24,.45))
  text(names[i],Vector2(178,y+50),27)
  text(PLACES[i],Vector2(720,y+50),20)
  if current==i:text("PAUSED" if player.stream_paused else "PLAYING",Vector2(1150,y+50),14,Color("bdaa7d"))
 canvas.draw_line(Vector2(160,524),Vector2(1280,524),Color("bdaa7d"))
