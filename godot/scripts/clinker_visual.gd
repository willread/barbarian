extends Node2D
var CORE=load("res://art/ember-core-v1.png")
var clock=0.0
var urgency=0.0
var body: Sprite2D
var ground_light: PointLight2D
var object_light: PointLight2D
var halo: Sprite2D

func _init():
	var gradient=Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.12,.3,.55,.8,1])
	gradient.colors=PackedColorArray([Color.WHITE,Color(1,1,1,.8),Color(1,1,1,.38),Color(1,1,1,.11),Color(1,1,1,.018),Color(1,1,1,0)])
	var falloff=GradientTexture2D.new()
	falloff.gradient=gradient
	falloff.width=256;falloff.height=256
	falloff.fill=GradientTexture2D.FILL_RADIAL
	falloff.fill_from=Vector2(.5,.5);falloff.fill_to=Vector2(1,.5)
	ground_light=PointLight2D.new()
	ground_light.texture=falloff
	ground_light.color=Color(1,.30,.055)
	ground_light.range_z_min=-4096;ground_light.range_z_max=0
	ground_light.z_as_relative=false
	add_child(ground_light)
	object_light=PointLight2D.new()
	object_light.texture=falloff
	object_light.color=Color(1,.34,.085)
	object_light.range_z_min=1;object_light.range_z_max=1806
	object_light.z_as_relative=false
	add_child(object_light)
	halo=Sprite2D.new()
	halo.texture=falloff
	halo.scale=Vector2.ONE*.43
	halo.material=CanvasItemMaterial.new()
	halo.material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	halo.material.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
	add_child(halo)
	body=Sprite2D.new()
	body.texture=CORE
	body.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	body.scale=Vector2(74,82)/CORE.get_size()
	body.material=ShaderMaterial.new()
	body.material.shader=preload("res://shaders/clinker_body.gdshader")
	add_child(body)

func configure(h: Dictionary):
	clock=h.age
	urgency=clampf(1-(h.life-h.age)/.6,0,1)
	var height=preload("res://scripts/episode_combat.gd").bomb_height(h)
	position=h.p
	z_index=int(h.p.y)*2+3
	body.position=Vector2(0,-27-height)
	body.rotation=h.get("rotation",0.0)
	body.material.set_shader_parameter("age",clock)
	body.material.set_shader_parameter("urgency",urgency)
	var flutter=.85+.10*sin(clock*19.7)+.05*sin(clock*37.1+1.3)
	var warning=pow(urgency,3)*(.5+.5*sin(clock*(15+urgency*20)))
	var energy=flutter*(1.0+warning*.9)
	# A raised source spreads over more ground with less illuminance.
	ground_light.scale=Vector2(1.35+height*.004,.48+height*.002)
	ground_light.energy=energy*1.25/pow(1+height/95.0,2)
	object_light.position=body.position
	object_light.scale=Vector2.ONE*1.35
	object_light.energy=energy*.85
	halo.position=body.position
	halo.modulate=Color(1,.22,.025,.18*energy)
