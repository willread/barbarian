extends Node2D
var picture: AtlasTexture
var elapsed=0.0
func _ready():
	# Browser has an HTML splash while the engine itself downloads.
	if OS.has_feature("web") or (not OS.get_cmdline_user_args().is_empty() and not "--splash-capture" in OS.get_cmdline_user_args()):
		get_tree().change_scene_to_file.call_deferred("res://main.tscn")
		return
	picture=AtlasTexture.new()
	picture.atlas=load("res://art/maximum-force-reference.png")
	var source=picture.atlas.get_size()
	picture.region=Rect2(0,source.y*.125,source.x*.5,source.y*.75)
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
	if elapsed>=2.0 and ResourceLoader.load_threaded_get_status("res://main.tscn")==ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get("res://main.tscn"))
func _draw():
	if not picture:return
	var screen=get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,screen),Color.BLACK)
	var ratio=min(screen.x*.9/picture.get_width(),screen.y*.86/picture.get_height())
	var size=picture.get_size()*ratio
	draw_texture_rect(picture,Rect2((screen-size)*.5,size),false)
	var radius=clamp(min(screen.x,screen.y)*.035,18.,35.)
	var center=screen-Vector2.ONE*(radius+32.)
	draw_arc(center,radius*.75,0,TAU,64,Color("777671"),radius*.23,true)
	for i in 12:
		var angle=elapsed*TAU/1.8+i*TAU/12.
		var tip=center+Vector2.from_angle(angle)*radius*1.25
		var a=center+Vector2.from_angle(angle-.13)*radius*.85
		var b=center+Vector2.from_angle(angle+.13)*radius*.85
		draw_colored_polygon(PackedVector2Array([a,tip,b]),Color("b2afa6"))
