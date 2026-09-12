extends Node2D
var picture: AtlasTexture
var flat_mark: AtlasTexture
var flat_text: AtlasTexture
var backdrop=preload("res://art/studio-background.png")
var elapsed=0.0
func _ready():
	# Browser has an HTML splash while the engine itself downloads.
	if OS.has_feature("web") or (not OS.get_cmdline_user_args().is_empty() and not "--splash-capture" in OS.get_cmdline_user_args()):
		get_tree().change_scene_to_file.call_deferred("res://main.tscn")
		return
	picture=AtlasTexture.new()
	picture.atlas=load("res://art/maximum-force-logo.png")
	picture.region=Rect2(78,41,1621,829)
	flat_mark=AtlasTexture.new()
	flat_mark.atlas=load("res://art/maximum-force-reference.png")
	flat_mark.region=Rect2(1041,216,627,326)
	flat_text=AtlasTexture.new()
	flat_text.atlas=flat_mark.atlas
	flat_text.region=Rect2(973,569,721,52)
	ResourceLoader.load_threaded_request("res://main.tscn")
	if "--splash-capture" in OS.get_cmdline_user_args():capture.call_deferred()
func capture():
	await get_tree().create_timer(.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/studio-splash.png")
	get_tree().quit()
func _process(dt: float):
	if not picture:return
	elapsed+=dt
	queue_redraw()
	if elapsed>=4.0 and ResourceLoader.load_threaded_get_status("res://main.tscn")==ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get("res://main.tscn"))
func _draw():
	if not picture:return
	var screen=get_viewport_rect().size
	var cover=max(screen.x/backdrop.get_width(),screen.y/backdrop.get_height())
	var bg=backdrop.get_size()*cover
	draw_texture_rect(backdrop,Rect2((screen-bg)*.5,bg),false)
	var blend=smoothstep(2.0,3.2,elapsed)
	draw_rect(Rect2(Vector2.ZERO,screen),Color(0,0,0,blend))
	var ratio=min(screen.x*.68/picture.get_width(),screen.y*.52/picture.get_height())
	var size=picture.get_size()*ratio
	var bounds=Rect2((screen-size)*.5,size)
	draw_texture_rect(picture,bounds,false,Color(1,1,1,1.-blend))
	# Register the monogram and wordmark independently to the metallic artwork.
	draw_texture_rect(flat_mark,Rect2(bounds.position+Vector2(228,0)*ratio,Vector2(1358,687)*ratio),false,Color(1,1,1,blend))
	draw_texture_rect(flat_text,Rect2(bounds.position+Vector2(0,701)*ratio,Vector2(1621,128)*ratio),false,Color(1,1,1,blend))
	var radius=clamp(min(screen.x,screen.y)*.035,18.,35.)
	var center=screen-Vector2.ONE*(radius+32.)
	draw_arc(center,radius*.75,0,TAU,64,Color("777671"),radius*.23,true)
	for i in 12:
		var angle=elapsed*TAU/1.8+i*TAU/12.
		var tip=center+Vector2.from_angle(angle)*radius*1.25
		var a=center+Vector2.from_angle(angle-.13)*radius*.85
		var b=center+Vector2.from_angle(angle+.13)*radius*.85
		draw_colored_polygon(PackedVector2Array([a,tip,b]),Color("b2afa6"))
