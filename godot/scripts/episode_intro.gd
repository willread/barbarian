extends CanvasLayer
signal finished
var pan_start=.8
var pan_end=9.0
var voice_start=1.0
var second_line_start=6.4
var second_line_started=false
var duration=11.5
var ending=false
var game: Node2D
var age=0.0
var done=false
var voice_started=false
var sting_started=false
var sting: AudioStreamPlayer
var canvas: Node2D
var player: AudioStreamPlayer
var picture=preload("res://art/intro/revenge-panorama-v1.png")
var font=preload("res://art/controls/cinzel.ttf")
var captions: Array=[]

func _ready():
	if ending:
		picture=load("res://art/ending/reunion-panorama-v1.png")
		pan_start=1.5
		pan_end=18.0
		voice_start=18.5
		duration=22.0
	layer=2300
	canvas=Node2D.new()
	add_child(canvas)
	canvas.draw.connect(paint)
	player=AudioStreamPlayer.new()
	player.stream=load("res://art/ending/reunion-voice.mp3" if ending else "res://art/intro/revenge-line-one.ogg")
	player.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
	player.bus=&"Voice"
	add_child(player)
	sting=AudioStreamPlayer.new()
	sting.bus=&"Music"
	sting.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
	if not ending:sting.stream=load("res://art/intro/revenge-guitar.ogg")
	add_child(sting)
	var subtitles=JSON.parse_string(FileAccess.get_file_as_string("res://art/ending/subtitles.json" if ending else "res://art/intro/subtitles.json"))
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
	player.volume_db=-80 if game.muted or not game.voice_enabled else 0
	if age>=voice_start and not voice_started:
		voice_started=true
		player.play()
	if not ending and age>=second_line_start and not second_line_started:
		second_line_started=true
		player.stream=load("res://art/intro/revenge-line-two.ogg")
		player.play()
	# Hit the gap before "Now"; duck the ringing tail beneath the second line.
	var voice_time=age-second_line_start
	sting.volume_db=-80 if game.muted or not game.music_enabled else lerpf(-1,-17,smoothstep(-.15,.07,voice_time))
	if not ending and voice_started and voice_time>=-.46 and not sting_started:
		sting_started=true
		sting.play()
	var size=get_viewport().get_visible_rect().size
	var scale_factor=minf(size.x/1440.0,size.y/810.0)
	transform=Transform2D(0,Vector2.ONE*scale_factor,0,(size-Vector2(1440,810)*scale_factor)*.5)
	canvas.queue_redraw()
	if age>=duration:finish()

func caption_at(time: float) -> String:
	for caption in captions:
		if time>=caption.start and time<caption.end:return caption.text
	return ""

func paint():
	canvas.draw_rect(Rect2(-2000,-2000,5440,4810),Color.BLACK)
	var progress=clampf((age-pan_start)/(pan_end-pan_start),0,1)
	var pan=smoothstep(0,1,progress)*1440.0
	# Two screen widths of static artwork; only the camera moves.
	var height=2880.0*picture.get_height()/picture.get_width()
	var top=-height*.18 if ending else (810-height)*.5
	canvas.draw_texture_rect(picture,Rect2(-pan,top,2880,height),false)
	canvas.draw_rect(Rect2(0,710,1440,100),Color.BLACK)
	var subtitle=caption_at(age-voice_start)
	if not subtitle.is_empty():
		var width=font.get_string_size(subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,30).x
		canvas.draw_string(font,Vector2((1440-width)*.5,768),subtitle,HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color.WHITE)
	var fade=1.0-minf(clampf(age/.7,0,1),clampf((duration-age)/.7,0,1))
	canvas.draw_rect(Rect2(0,0,1440,810),Color(0,0,0,fade))

func handle(event: InputEvent):
	if age<.5:return
	if event is InputEventKey and event.pressed and not event.echo:finish()
	elif event is InputEventJoypadButton and event.pressed:finish()
	elif event is InputEventMouseButton and event.pressed:finish()
	elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT] and event.axis_value>.65:finish()

func finish():
	if done:return
	done=true
	player.stop()
	sting.stop()
	game.audio.music_preview=false
	finished.emit()

func _exit_tree():
	player.stop()
	sting.stop()
	if is_instance_valid(game):
		if is_instance_valid(game.audio):game.audio.music_preview=false
		if is_instance_valid(game.hero_voice):game.hero_voice.set_process(true)
