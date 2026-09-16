extends CanvasLayer
signal finished
const PAN_START=1.5
const PAN_END=22.0
const VOICE_START=20.0
const DURATION=26.0
var game: Node2D
var age=0.0
var done=false
var voice_started=false
var canvas: Node2D
var player: AudioStreamPlayer
var picture=preload("res://art/intro/revenge-panorama-v1.png")
var font=preload("res://art/controls/cinzel.ttf")
var captions: Array=[]

func _ready():
	layer=2300
	canvas=Node2D.new()
	add_child(canvas)
	canvas.draw.connect(paint)
	player=AudioStreamPlayer.new()
	player.stream=load("res://art/intro/revenge-voice.mp3")
	player.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
	player.bus=&"Voice"
	add_child(player)
	var subtitles=JSON.parse_string(FileAccess.get_file_as_string("res://art/intro/subtitles.json"))
	captions=subtitles
	game.audio.music_preview=true
	game.audio.stop_gameplay()
	game.hero_voice.reset()
	game.hero_voice.set_process(false)
	for track in game.audio.tracks:track.stop()
	Input.mouse_mode=Input.MOUSE_MODE_HIDDEN

func _process(dt: float):
	if done:return
	age+=dt
	if age>=VOICE_START and not voice_started:
		voice_started=true
		player.play()
	player.volume_db=-80 if game.muted or not game.voice_enabled else 0
	var size=get_viewport().get_visible_rect().size
	var scale_factor=minf(size.x/1440.0,size.y/810.0)
	transform=Transform2D(0,Vector2.ONE*scale_factor,0,(size-Vector2(1440,810)*scale_factor)*.5)
	canvas.queue_redraw()
	if age>=DURATION:finish()

func caption_at(time: float) -> String:
	for caption in captions:
		if time>=caption.start and time<caption.end:return caption.text
	return ""

func paint():
	canvas.draw_rect(Rect2(-2000,-2000,5440,4810),Color.BLACK)
	var progress=clampf((age-PAN_START)/(PAN_END-PAN_START),0,1)
	var pan=smoothstep(0,1,progress)*1440.0
	# Two screen widths of static artwork; only the camera moves.
	var height=2880.0*picture.get_height()/picture.get_width()
	canvas.draw_texture_rect(picture,Rect2(-pan,(810-height)*.5,2880,height),false)
	canvas.draw_rect(Rect2(0,710,1440,100),Color.BLACK)
	var subtitle=caption_at(age-VOICE_START)
	if not subtitle.is_empty():
		var width=font.get_string_size(subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,30).x
		canvas.draw_string(font,Vector2((1440-width)*.5,768),subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color.WHITE)
	canvas.draw_string(font,Vector2(1110,40),"ENTER / A TO SKIP",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(.8,.8,.8,.6))
	var fade=1.0-minf(clampf(age/.7,0,1),clampf((DURATION-age)/.7,0,1))
	canvas.draw_rect(Rect2(0,0,1440,810),Color(0,0,0,fade))

func handle(event: InputEvent):
	if age<.5:return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER,KEY_SPACE,KEY_ESCAPE]:finish()
	elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_START]:finish()

func finish():
	if done:return
	done=true
	player.stop()
	game.audio.music_preview=false
	finished.emit()

func _exit_tree():
	player.stop()
	if is_instance_valid(game):
		if is_instance_valid(game.audio):game.audio.music_preview=false
		if is_instance_valid(game.hero_voice):game.hero_voice.set_process(true)
