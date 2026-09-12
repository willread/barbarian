class_name BurningSprite
extends Node2D
var mask_view: SubViewport
var burn: ShaderMaterial
var fire: ContourFire
var anchor=Vector2.ZERO
const SPEED=1.3
static func finished_at(engulf: float) -> float:
	return .15+engulf+.6+.45
func setup(texture: Texture2D,rect: Rect2,flip: bool,seed_value: float):
	mask_view=SubViewport.new()
	mask_view.size=Vector2i(rect.size.ceil())
	mask_view.disable_3d=true
	mask_view.transparent_bg=true
	mask_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(mask_view)
	var source=Sprite2D.new()
	source.centered=false
	source.texture=texture
	source.flip_h=flip
	source.scale=Vector2(mask_view.size)/texture.get_size()
	burn=ShaderMaterial.new()
	burn.shader=load("res://shaders/burn.gdshader")
	burn.set_shader_parameter("seed",seed_value)
	source.material=burn
	mask_view.add_child(source)
	var body=Sprite2D.new()
	body.centered=false
	body.texture=mask_view.get_texture()
	body.position=rect.position
	add_child(body)
	anchor=rect.get_center()
	fire=ContourFire.new()
	fire.animation_speed=SPEED
	add_child(fire)
	fire.setup(mask_view.get_texture(),Vector2(mask_view.size),rect.position,false)
func update_burn(age: float,engulf: float):
	burn.set_shader_parameter("burn_age",age)
	burn.set_shader_parameter("engulf",engulf)
	var end=.15+engulf+.6
	fire.emitting=age>0 and age<end
	fire.strength=1.8*(1.-smoothstep(end-.6,end,age))
	# The live body mask recedes downward; never scale or move the flame field.
	fire.interior=1.0
	fire.opacity=1.-smoothstep(end-.2,finished_at(engulf),age)
