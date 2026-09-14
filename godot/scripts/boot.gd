extends Node2D
var picture: AtlasTexture
var flat: Texture2D
var backdrop=preload("res://art/studio-background.png")
var stones=preload("res://art/branding/cairn-icon-256.png")
var elapsed=0.0
var white_layer: Node2D
func _ready():
	# Browser has an HTML splash while the engine itself downloads.
	if OS.has_feature("web") or (not OS.get_cmdline_user_args().is_empty() and not "--splash-capture" in OS.get_cmdline_user_args()):
		get_tree().change_scene_to_file.call_deferred("res://main.tscn")
		return
	get_window().size_changed.connect(fit_window)
	fit_window()
	picture=AtlasTexture.new()
	picture.atlas=load("res://art/maximum-force-logo.png")
	picture.region=Rect2(0,0,1774,887)
	flat=load("res://art/maximum-force-white-v2.png")
	white_layer=Node2D.new()
	var transparent_logo=ShaderMaterial.new()
	transparent_logo.shader=preload("res://shaders/white_logo.gdshader")
	white_layer.material=transparent_logo
	white_layer.draw.connect(draw_white_logo)
	add_child(white_layer)
	ResourceLoader.load_threaded_request("res://main.tscn")
	if "--splash-capture" in OS.get_cmdline_user_args():capture.call_deferred()
func capture():
	await get_tree().create_timer(3.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/studio-splash.png")
	get_tree().quit()
func _process(dt: float):
	if not picture:return
	elapsed+=dt
	white_layer.queue_redraw()
	queue_redraw()
	if elapsed>=6.0 and ResourceLoader.load_threaded_get_status("res://main.tscn")==ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get("res://main.tscn"))
func _draw():
	if not picture:return
	var screen=get_viewport_rect().size
	var cover=max(screen.x/backdrop.get_width(),screen.y/backdrop.get_height())
	var bg=backdrop.get_size()*cover
	draw_texture_rect(backdrop,Rect2((screen-bg)*.5,bg),false)
	var blend=smoothstep(3.0,4.2,elapsed)
	draw_rect(Rect2(Vector2.ZERO,screen),Color(0,0,0,blend))
	var ratio=min(screen.x*.476/picture.get_width(),screen.y*.364/picture.get_height())
	var size=picture.get_size()*ratio
	var bounds=Rect2((screen-size)*.5,size)
	draw_texture_rect(picture,bounds,false,Color(1,1,1,1.-blend))

	var edge=clampf(min(screen.x,screen.y)*.09,60.,96.)
	var origin=screen-Vector2.ONE*(edge+24.)
	var cycle=fmod(elapsed,2.8)/2.8
	var regions=[Rect2(0,158,256,98),Rect2(0,102,256,56),Rect2(0,0,256,102)]
	for i in 3:
		var t=cycle-i*.16
		if t<0 or cycle>.99:continue
		var drop=0.0
		if t<.12:drop=-256.*(1.-pow(t/.12,2.5))
		elif t<.17:drop=-7.*sin((t-.12)/.05*PI)
		elif t<.21:drop=-1.5*sin((t-.17)/.04*PI)
		if cycle>.82:drop=270.*pow((cycle-.82)/.17,2.)
		var region=regions[i]
		var target=Rect2(origin+(region.position+Vector2(0,drop))*edge/256.,region.size*edge/256.)
		# Clip motion to the loader square, just like the browser SVG viewport.
		var clipped=target.intersection(Rect2(origin,Vector2.ONE*edge))
		if clipped.has_area():
			var source=Rect2(region.position+(clipped.position-target.position)*256./edge,clipped.size*256./edge)
			draw_texture_rect_region(stones,clipped,source)

func draw_white_logo():
	var screen=get_viewport_rect().size
	var ratio=min(screen.x*.476/picture.get_width(),screen.y*.364/picture.get_height())
	var size=picture.get_size()*ratio
	white_layer.draw_texture_rect(flat,Rect2((screen-size)*.5,size),false,Color(1,1,1,smoothstep(3.0,4.2,elapsed)))

func fit_window():
	var dimensions=get_window().size
	var target=Vector2i(1440,roundi(1440.0*dimensions.y/maxi(1,dimensions.x)))
	if get_window().content_scale_size!=target:get_window().content_scale_size=target
	queue_redraw()
	if is_instance_valid(white_layer):white_layer.queue_redraw()
