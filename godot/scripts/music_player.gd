extends CanvasLayer
signal closed
var game: Node2D
var canvas: Node2D
var player: AudioStreamPlayer
var selected=0
var current=-1
var names: Array=[]
var saved_pauses: Array=[]
var font=preload("res://art/controls/cinzel.ttf")
const PLACES=["MAIN MENU","EP I / THE FALLEN CITADEL","EP II / THE SUNKEN WILDS","EP III / THE ASHEN DEPTHS"]
const SEEK=Rect2(370,652,700,20)
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
   if Rect2(160,180+i*86,1120,86).has_point(point):play_track(i);return
  if Rect2(605,595,230,44).has_point(point):toggle()
  elif Rect2(410,595,125,44).has_point(point):play_track(selected-1)
  elif Rect2(905,595,125,44).has_point(point):play_track(selected+1)
  elif SEEK.has_point(point) and current>=0:seek_to((point.x-SEEK.position.x)/SEEK.size.x*player.stream.get_length())
  elif Rect2(620,710,200,42).has_point(point):closed.emit()
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
  canvas.draw_line(Vector2(160,y),Vector2(1280,y),Color(.40,.34,.24,.45))
  text(names[i],Vector2(178,y+50),27)
  text(PLACES[i],Vector2(720,y+50),20)
  if current==i:text("PAUSED" if player.stream_paused else "PLAYING",Vector2(1150,y+50),14,Color("bdaa7d"))
 canvas.draw_line(Vector2(160,524),Vector2(1280,524),Color("bdaa7d"))
 for spec in [[Rect2(410,595,125,44),"PREV"],[Rect2(605,595,230,44),"PAUSE" if current==selected and player.playing and not player.stream_paused else "PLAY"],[Rect2(905,595,125,44),"NEXT"]]:
  text(spec[1],spec[0].get_center()+Vector2(0,7),20,Color("e4ddc9"),true)
 canvas.draw_rect(Rect2(SEEK.position+Vector2(0,8),Vector2(SEEK.size.x,4)),Color("39372d"))
 if current>=0:
  var position_seconds=player.get_playback_position();var length=player.stream.get_length()
  canvas.draw_rect(Rect2(SEEK.position+Vector2(0,8),Vector2(SEEK.size.x*position_seconds/length,4)),Color("c2a365"))
  text("%d:%02d / %d:%02d"%[int(position_seconds)/60,int(position_seconds)%60,int(length)/60,int(length)%60],Vector2(720,695),14,Color("adae99"),true)
 else:text("SELECT A TRACK",Vector2(720,695),14,Color("adae99"),true)
 text("BACK",Vector2(720,740),25,Color("e4ddc9"),true)
 text("SOUND MUTED" if game.muted else "LOOPING / ENTER TO PLAY / ARROWS TO SELECT & SEEK",Vector2(720,789),12,Color("b6baa4"),true)
