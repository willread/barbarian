extends Node2D
const Fire=preload("res://scripts/contour_fire.gd")
const KINDS=["legion","bone","shield","marauder","champion"]
var art: CairnArt
var kind=0
var age=0.0
var strength=1.8
var fire: ContourFire
var corpse: Sprite2D
var mask_view: SubViewport
var burn: ShaderMaterial
var assembly: Node2D
func _ready():
	get_window().content_scale_size=Vector2i(1440,810)
	art=CairnArt.new()
	rebuild()
	if "--study-capture" in OS.get_cmdline_user_args():capture.call_deferred()
func rebuild():
	if assembly:
		remove_child(assembly)
		assembly.queue_free()
	age=0.0
	assembly=Node2D.new()
	assembly.position=Vector2(720,555)
	add_child(assembly)
	var atlas=art.data.atlases["enemy-combat-v3" if kind==0 else "enemy-"+KINDS[kind]+"-v1"]
	var cel=atlas.cels[15 if kind==0 else 13]
	var factor=292*atlas.scale/atlas.cellWidth if kind==0 else art.HEIGHTS[KINDS[kind]]/atlas.cels[0].height
	var size=Vector2(cel.width,cel.height)*factor
	mask_view=SubViewport.new()
	mask_view.size=Vector2i(size.ceil())
	mask_view.disable_3d=true
	mask_view.transparent_bg=true
	mask_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	assembly.add_child(mask_view)
	var source=Sprite2D.new()
	source.centered=false
	source.texture=art.texture(cel.file)
	source.scale=size/source.texture.get_size()
	burn=ShaderMaterial.new()
	burn.shader=load("res://shaders/burn.gdshader")
	burn.set_shader_parameter("seed",randf()*100)
	burn.set_shader_parameter("engulf",1.1)
	source.material=burn
	mask_view.add_child(source)
	# Live alpha feeds exactly the remaining corpse silhouette, including burn-away edges.
	fire=Fire.new()
	assembly.add_child(fire)
	fire.setup(mask_view.get_texture(),Vector2(mask_view.size),Vector2(-size.x*.5,-size.y),false)
	fire.strength=strength
	corpse=Sprite2D.new()
	corpse.centered=false
	corpse.texture=mask_view.get_texture()
	corpse.position=Vector2(-size.x*.5,-size.y)
	assembly.add_child(corpse)
	queue_redraw()
func _process(dt: float):
	if not fire:return
	age+=dt
	# The study starts grounded; ignition is deliberately after landing.
	var burning=max(0.0,age-.5)
	burn.set_shader_parameter("burn_age",burning)
	fire.emitting=burning>0 and burning<1.85
	fire.strength=strength*(1.0-smoothstep(1.15,1.85,burning))
	if age>4.5:rebuild()
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_SPACE:rebuild()
		if event.keycode in [KEY_UP,KEY_DOWN]:
			kind=posmod(kind+(1 if event.keycode==KEY_DOWN else -1),KINDS.size())
			rebuild()
		if event.keycode in [KEY_LEFT,KEY_RIGHT]:
			strength=clamp(strength+(.1 if event.keycode==KEY_RIGHT else -.1),.1,3.0)
			queue_redraw()
func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("151519"))
	draw_rect(Rect2(0,555,1440,255),Color("252326"))
	draw_string(ThemeDB.fallback_font,Vector2(50,70),"GROUNDED ENEMY FIRE  /  "+KINDS[kind].to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("d5c8ae"))
	draw_string(ThemeDB.fallback_font,Vector2(50,750),"Up/down: enemy   Space: replay   Left/right: intensity %.1f   /   Loops automatically"%strength,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("d5c8ae"))
func capture():
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/enemy-fire-study.png")
	print("ENEMY_FIRE_STUDY_OK")
	get_tree().quit()
