extends SceneTree
# Offline marketing compositor. Uses the production ContourFire and hot-stone shaders.
var config: Dictionary
var frame=0
var canvas: Node2D
var group: Node2D
var background: Texture2D
var last_frame: Texture2D
var t=0.0
var ready_capture=false

func texture(file: String) -> ImageTexture:
	return ImageTexture.create_from_image(Image.load_from_file(file))

func _init():
	config=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	root.size=Vector2i(1920,1080)
	call_deferred("setup")

func setup():
	seed(413)
	canvas=Node2D.new();root.add_child(canvas);canvas.draw.connect(paint)
	last_frame=texture(config.previous)
	group=Node2D.new();canvas.add_child(group)
	var image=Image.load_from_file(config.texture)
	var ratio=float(image.get_height())/image.get_width()
	var width=1300.0 if config.id=="logo" else 1420.0
	var height=width*ratio
	var mask=image.duplicate();mask.resize(int(width/3),int(height/3),Image.INTERPOLATE_LANCZOS)
	var fire=load("res://scripts/contour_fire.gd").new()
	fire.menu_palette=true
	fire.strength=1.45
	fire.interior=.12
	fire.clock=41.3
	group.add_child(fire)
	fire.scale=Vector2.ONE*3
	fire.setup(ImageTexture.create_from_image(mask),Vector2(mask.get_size()),-Vector2(mask.get_size())*.5)
	var face=Sprite2D.new();face.texture=ImageTexture.create_from_image(image)
	face.scale=Vector2.ONE*width/image.get_width();group.add_child(face)
	fire.heat_face(face,Rect2(-Vector2(mask.get_size())*.5,Vector2(mask.get_size())))
	group.position=Vector2(960,540)
	ready_capture=true

func _process(_dt):
	if not ready_capture:return false
	t=frame/60.0-1.0
	var index=clampi(int(maxf(t,0)*60)+1,1,int(config.duration*60))
	background=texture(config.frames+"/%04d.jpg"%index)
	var intro=smoothstep(0.,.3,t)
	var outro=1.0 if config.id=="logo" else smoothstep(0.,.25,float(config.duration)-t)
	group.modulate.a=intro*outro
	# Match the game's perspective approach, recoil and impact settle.
	var approach=clampf(t/.65,0.,1.)
	var travel=pow(approach,1.6)
	var landing=clampf((t-.65)/.45,0.,1.)
	var recoil=sin(landing*TAU*1.2)*exp(-landing*6.)*(1.-landing)
	var zoom=1./(1.+3.2*(1.-travel))+recoil*.10
	group.scale=Vector2.ONE*(zoom if config.id=="logo" else lerpf(.94,1.,smoothstep(0.,.3,t)))
	canvas.queue_redraw()
	frame+=1
	if frame>int((float(config.duration)+1)*60):quit()
	return false

func paint():
	if not background:return
	canvas.draw_texture_rect(background,Rect2(0,0,1920,1080),false)
	if t<.22:canvas.draw_texture_rect(last_frame,Rect2(0,0,1920,1080),false,Color(1,1,1,1.-smoothstep(0.,.22,t)))
	var a=smoothstep(0.,.45,t)
	if config.id=="logo":
		canvas.draw_rect(Rect2(0,0,1920,1080),Color(0,0,0,a*.30))
	else:
		canvas.draw_rect(Rect2(0,280,1920,520),Color(.025,.018,.012,a*.30))
