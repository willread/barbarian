extends Node2D
var actor: Dictionary
var art: CairnArt
var pose: Array=[]
var burn_material: ShaderMaterial
func _ready():
	burn_material=ShaderMaterial.new()
	burn_material.shader=load("res://shaders/burn.gdshader")
	material=burn_material
func update_view(spell: int):
	pose=art.pose(actor,spell)
	position=Vector2(actor.x,actor.y-actor.height*4.5)
	scale=Vector2(actor.dir*actor.size,actor.size)
	z_index=int(actor.y)*2
	burn_material.set_shader_parameter("burn_age",actor.burnAge if not actor.player else 0.0)
	burn_material.set_shader_parameter("engulf",actor.engulf)
	burn_material.set_shader_parameter("seed",actor.burnSeed)
	burn_material.set_shader_parameter("electric",float(actor.electricTicks))
	burn_material.set_shader_parameter("hit_glow",actor.hitGlow)
	queue_redraw()
func _draw():
	if pose.is_empty(): return
	art.paint_weapon(self,actor,pose,true)
	art.paint_body(self,actor,pose)
	art.paint_weapon(self,actor,pose,false)
