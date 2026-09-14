extends Node2D
const Fire=preload("res://scripts/contour_fire.gd")
var art: CairnArt
var fires: Array=[]
var faces: Array=[]
var selected=0
var strength=0.6
var dark=false
func _ready():
	art=CairnArt.new()
	for i in 2:
		var meta=art.data.menu[["BEGIN","OPTIONS"][i]]
		var group=Node2D.new()
		group.position=Vector2(417.6,380.7+i*110)
		add_child(group)
		var fire=Fire.new()
		group.add_child(fire)
		fire.setup(art.texture("menu-"+meta.id+"-fuel.png"),Vector2(meta.fw,meta.fh),Vector2(-meta.fw*.5,-meta.pad))
		fires.append(fire)
		var face=Sprite2D.new()
		face.centered=false
		face.texture=art.texture("menu-"+meta.id+".png")
		face.position=Vector2(-meta.width*.5,0)
		face.scale=Vector2(meta.width,meta.height)/face.texture.get_size()
		group.add_child(face)
		fire.heat_face(face,Rect2(face.position,Vector2(meta.width,meta.height)))
		faces.append(face)
	select(0)
	if "--study-capture" in OS.get_cmdline_user_args(): capture.call_deferred()
func select(index: int):
	selected=posmod(index,2)
	for i in 2:
		fires[i].emitting=i==selected
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_UP,KEY_DOWN,KEY_TAB]:select(selected+1)
		if event.keycode==KEY_B:dark=not dark;queue_redraw()
		if event.keycode in [KEY_LEFT,KEY_RIGHT]:
			strength=clamp(strength+(.1 if event.keycode==KEY_RIGHT else -.1),.5,1.4)
			for fire in fires:fire.strength=strength
			queue_redraw()
		if event.keycode==KEY_ESCAPE:WindowPreferences.open_scene("res://main.tscn")
	if event is InputEventMouseMotion:
		var p=get_global_mouse_position()
		if p.x>200 and p.x<640 and p.y>390 and p.y<635:select(0 if p.y<510 else 1)
func _draw():
	if not art:return
	if dark:draw_rect(Rect2(0,0,1440,810),Color("090a0b"))
	else:draw_texture_rect(art.texture("cairn-title-v1.png"),Rect2(0,0,1440,810),false)
	draw_string(ThemeDB.fallback_font,Vector2(35,765),"FIRE STUDY  ·  Up/down or hover: select  ·  Left/right: intensity %.1f  ·  B: black background"%strength,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("d5c8ae"))
func capture():
	await get_tree().create_timer(3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/fire-study.png")
	print("FIRE_STUDY_OK")
	get_tree().quit()
