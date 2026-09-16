extends Node2D
const ORIGIN=Vector2(65,-265)
const START=66.0
const END=138.0
var reach=1400.0
var light: PointLight2D
var chest: Sprite2D
var chest_light: PointLight2D
static func power(age: float) -> float:
	return smoothstep(START,START+12,age)*(1-smoothstep(END-12,END,age))
static func hits(enemy: Dictionary,hero: Dictionary) -> bool:
	var a=enemy.attack
	var strength=power(a.age)
	if strength<=.05 or absf(hero.y-enemy.y)>65:return false
	var length=(1440-enemy.x if a.direction>0 else enemy.x)/enemy.size-ORIGIN.x
	var along=(hero.x-enemy.x)*a.direction/enemy.size-ORIGIN.x
	if along<0 or along>length*strength:return false
	var width=(65+65*clampf(along/maxf(length,1),0,1))*strength*enemy.size
	var center=enemy.y+ORIGIN.y*enemy.size
	var top=hero.y-hero.height*4.5-190
	var bottom=hero.y-hero.height*4.5-15
	return bottom>center-width and top<center+width
func _init():
	material=ShaderMaterial.new()
	material.shader=preload("res://shaders/saint_flame.gdshader")
	var gradient=Gradient.new()
	gradient.colors=PackedColorArray([Color.WHITE,Color(1,1,1,0)])
	var falloff=GradientTexture2D.new()
	falloff.gradient=gradient;falloff.width=256;falloff.height=256
	falloff.fill=GradientTexture2D.FILL_RADIAL
	falloff.fill_from=Vector2(.5,.5);falloff.fill_to=Vector2(1,.5)
	light=PointLight2D.new()
	light.texture=falloff;light.color=Color(1,.29,.035)
	light.range_z_max=1806
	add_child(light)
	chest_light=PointLight2D.new()
	chest_light.texture=falloff;chest_light.color=Color(1,.42,.055)
	chest_light.range_z_max=1806
	chest_light.position=ORIGIN
	chest_light.scale=Vector2(1.2,1.5)
	add_child(chest_light)
	# Register the emissive pixels exactly over the existing open-door sprite.
	var atlas=JSON.parse_string(FileAccess.get_file_as_string("res://art/saint-v2-atlas.json"))
	var cel=atlas.cels[5]
	var ratio=420.0/atlas.referenceHeight
	chest=Sprite2D.new()
	chest.texture=load("res://art/saint-v2-5.png")
	chest.centered=false
	chest.position=Vector2((cel.left-atlas.cellWidth*.5)*ratio,-cel.height*ratio)
	chest.scale=Vector2.ONE*ratio
	chest.material=ShaderMaterial.new()
	chest.material.shader=preload("res://shaders/saint_chest_glow.gdshader")
	add_child(chest)
func configure(enemy: Dictionary):
	position=Vector2(enemy.x,enemy.y)
	scale=Vector2(enemy.attack.direction,1)*enemy.size
	z_index=int(enemy.y)*2+2
	reach=maxf(1,(1440-enemy.x if enemy.attack.direction>0 else enemy.x)/enemy.size-ORIGIN.x)
	var strength=power(enemy.attack.age)
	var door=smoothstep(42.,62.,enemy.attack.age)*(1-smoothstep(138.,166.,enemy.attack.age))
	chest.material.set_shader_parameter("heat",door*(.55+strength*.65))
	chest.material.set_shader_parameter("age",enemy.attack.age/60.0)
	chest_light.energy=door*(.4+strength*.65)
	material.set_shader_parameter("age",enemy.attack.age/60.0)
	material.set_shader_parameter("power",strength)
	material.set_shader_parameter("reach",reach)
	material.set_shader_parameter("origin",ORIGIN)
	light.position=ORIGIN+Vector2(reach*strength*.35,90)
	light.scale=Vector2(2+reach*strength/140,2.7)
	light.energy=.25+strength*1.1
	queue_redraw()
func _draw():
	draw_rect(Rect2(-20,-440,1500,400),Color.WHITE)
