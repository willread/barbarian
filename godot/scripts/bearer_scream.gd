extends Node2D
func _init():
	material=ShaderMaterial.new()
	material.shader=preload("res://shaders/bearer_scream.gdshader")
func configure(enemy: Dictionary):
	position=Vector2(enemy.x,enemy.y)
	scale=Vector2(enemy.attack.direction,1)*enemy.size
	z_index=int(enemy.y)*2+2
	material.set_shader_parameter("age",enemy.attack.age/60.0)
	queue_redraw()
func _draw():
	draw_rect(Rect2(-170,-340,480,350),Color.WHITE)
