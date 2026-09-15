extends CanvasLayer
signal closed
var game: Node2D
var canvas: Node2D
var player: AudioStreamPlayer
var selected=0
var current=-1
var names: Array=[]
var saved_pauses: Array=[]
const STONE=preload("res://art/stone-border-v1.png")
var font=preload("res://art/controls/cinzel.ttf")
const PLACES=["MAIN MENU","EP I / THE FALLEN CITADEL","EP II / THE SUNKEN WILDS","EP III / THE ASHEN DEPTHS"]
const PANEL=Rect2(300,230,840,530)
const SEEK=Rect2(370,652,700,20)
func _ready():
 layer=2200
 canvas=Node2D.new();add_child(canvas);canvas.draw.connect(paint)
 canvas.position=Vector2(43.2,45);canvas.scale=Vector2.ONE*.94
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
func _process(_dt: float):
 player.volume_db=-60 if game.muted else -10+game.audio.volumes.get("music_menu" if current==0 else "music_game",0.0)
 canvas.queue_redraw()
func play_track(index: int):
 selected=wrapi(index,0,names.size());current=selected
 player.stream=game.audio.tracks[selected].stream
 player.stream_paused=false;player.play()
 game.audio.unlocked=true
func toggle():
 if current<0 or current!=selected:play_track(selected)
 elif player.playing:player.stream_paused=not player.stream_paused
 else:play_track(selected)
func seek_to(seconds: float):
 if current>=0:player.seek(clampf(seconds,0,player.stream.get_length()-.01))
func handle(event: InputEvent):
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_ESCAPE:closed.emit()
   KEY_UP: selected=wrapi(selected-1,0,4);game.audio.play("menu_select")
   KEY_DOWN:selected=wrapi(selected+1,0,4);game.audio.play("menu_select")
   KEY_ENTER,KEY_SPACE:toggle()
   KEY_LEFT:seek_to(player.get_playback_position()-5)
   KEY_RIGHT:seek_to(player.get_playback_position()+5)
 elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  var point=canvas.transform.affine_inverse()*(transform.affine_inverse()*event.position)
  for i in 4:
   if Rect2(340,312+i*68,760,59).has_point(point):play_track(i);return
  if Rect2(605,595,230,44).has_point(point):toggle()
  elif Rect2(410,595,125,44).has_point(point):play_track(selected-1)
  elif Rect2(905,595,125,44).has_point(point):play_track(selected+1)
  elif SEEK.has_point(point) and current>=0:seek_to((point.x-SEEK.position.x)/SEEK.size.x*player.stream.get_length())
  elif Rect2(620,710,200,42).has_point(point):closed.emit()
func text(value: String,point: Vector2,size: int,color: Color=Color("d5c9aa"),center: bool=false):
 if center:point.x-=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5
 canvas.draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func plate(rect: Rect2,active: bool=false):
 canvas.draw_rect(rect,Color("1c211e"))
 canvas.draw_texture_rect_region(STONE,rect,Rect2(rect.position,rect.size),Color(1,1,1,.15))
 canvas.draw_rect(rect,Color("b6a06d") if active else Color("595643"),false,1.5)
 canvas.draw_line(rect.position+Vector2(2,2),Vector2(rect.end.x-2,rect.position.y+2),Color("706b55"),2)
 canvas.draw_line(Vector2(rect.position.x+2,rect.end.y-2),rect.end-Vector2(2,2),Color("090d0b"),3)
func paint():
 canvas.draw_rect(Rect2(0,210,1440,600),Color(0,0,0,.3))
 plate(PANEL)
 canvas.draw_rect(PANEL.grow(-7),Color("756442"),false,1)
 for point in [PANEL.position+Vector2(15,15),Vector2(PANEL.end.x-15,PANEL.position.y+15),PANEL.end-Vector2(15,15),Vector2(PANEL.position.x+15,PANEL.end.y-15)]:
  canvas.draw_circle(point,4,Color("a18a59"));canvas.draw_line(point-Vector2(2,0),point+Vector2(2,0),Color("302b20"),1)
 text("SONGS OF CAIRN",Vector2(720,279),31,Color("dec998"),true)
 for i in 4:
  plate(Rect2(340,312+i*68,760,59),selected==i)
  text("%02d"%(i+1),Vector2(359,347+i*68),23,Color("a18f67"))
  text(PLACES[i],Vector2(414,332+i*68),12,Color("a7ac98"))
  text(names[i],Vector2(414,358+i*68),23)
  if current==i and player.playing and not player.stream_paused:
   for bar in 5:
    var height=6+absf(sin(Time.get_ticks_msec()*.004+bar*1.7))*17
    canvas.draw_rect(Rect2(1020+bar*8,355+i*68-height,4,height),Color("c9b078"))
 for spec in [[Rect2(410,595,125,44),"PREV"],[Rect2(605,595,230,44),"PAUSE" if current==selected and player.playing and not player.stream_paused else "PLAY"],[Rect2(905,595,125,44),"NEXT"]]:
  plate(spec[0]);text(spec[1],spec[0].get_center()+Vector2(0,7),20,Color("dec998"),true)
 canvas.draw_rect(Rect2(SEEK.position+Vector2(0,8),Vector2(SEEK.size.x,4)),Color("070b08"))
 if current>=0:
  var position_seconds=player.get_playback_position();var length=player.stream.get_length()
  canvas.draw_rect(Rect2(SEEK.position+Vector2(0,8),Vector2(SEEK.size.x*position_seconds/length,4)),Color("c2a365"))
  text("%d:%02d / %d:%02d"%[int(position_seconds)/60,int(position_seconds)%60,int(length)/60,int(length)%60],Vector2(720,695),14,Color("adae99"),true)
 else:text("SELECT A TRACK",Vector2(720,695),14,Color("adae99"),true)
 text("BACK",Vector2(720,740),25,Color("dec998"),true)
 text("SOUND MUTED" if game.muted else "LOOPING / ENTER TO PLAY / ARROWS TO SELECT & SEEK",Vector2(720,789),12,Color("b6baa4"),true)
