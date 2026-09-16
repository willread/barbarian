extends Node2D
const Shape=preload("res://scripts/scream_shape.gd")
func _init():
	material=ShaderMaterial.new()
	material.shader=preload("res://shaders/bearer_scream.gdshader")
func configure(enemy: Dictionary):
	position=Vector2(enemy.x,enemy.y)
	scale=Vector2(enemy.attack.direction,1)*enemy.size
	z_index=int(enemy.y)*2+2
	material.set_shader_parameter("age",enemy.attack.age/60.0)
	material.set_shader_parameter("flame_power",Shape.power(enemy.attack.age))
	for i in Shape.JETS.size():
		material.set_shader_parameter("jet_%d"%i,Shape.JETS[i])
		material.set_shader_parameter("direction_%d"%i,Shape.DIRECTIONS[i].normalized())
	queue_redraw()
func _draw():
	draw_rect(Rect2(-170,-340,480,350),Color.WHITE)
