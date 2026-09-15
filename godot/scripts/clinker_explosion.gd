extends Node2D
var age=0.0
func _init():
	material=ShaderMaterial.new()
	material.shader=preload("res://shaders/clinker_explosion.gdshader")
func advance(dt: float):
	age+=dt
	material.set_shader_parameter("age",age)
	queue_redraw()
func _draw():
	draw_rect(Rect2(-330,-410,660,540),Color.WHITE)
