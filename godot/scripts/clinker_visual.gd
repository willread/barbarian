extends Node2D
var clock=0.0
var urgency=0.0
func _init():
	material=ShaderMaterial.new()
	material.shader=preload("res://shaders/clinker_body.gdshader")
func configure(h: Dictionary):
	clock=h.age
	urgency=clampf(1-(h.life-h.age)/1.6,0,1)
	position=h.p-Vector2(0,24+(70.0 if h.reflected else sin(minf(h.age/.65,1)*PI)*160))
	z_index=int(h.p.y)*2+3
	material.set_shader_parameter("age",clock)
	material.set_shader_parameter("urgency",urgency)
	queue_redraw()
func _draw():
	draw_rect(Rect2(-34,-40,68,76),Color.WHITE)
