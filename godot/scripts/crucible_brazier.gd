extends Node2D
var clock=0.0
var fire: ShaderMaterial
func _ready():
	position=Vector2(758,0)
	var sprite=Sprite2D.new()
	sprite.texture=load("res://assets/crucible-brazier.png")
	sprite.centered=false
	# The extracted layer is registered back to the original 200px-wide vessel.
	sprite.scale=Vector2(.414,.414)
	sprite.position=Vector2(-908*.414,0)
	fire=ShaderMaterial.new()
	fire.shader=preload("res://shaders/crucible_brazier.gdshader")
	sprite.material=fire
	add_child(sprite)
func advance(t: float):
	clock=t
	# Slow, small rigid pendulum motion; the bowl never deforms with the backdrop.
	rotation=sin(t*.78)*.025+sin(t*.31+1.7)*.003
	if fire:fire.set_shader_parameter("clock",t)
