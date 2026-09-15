extends Sprite2D
func _init():
 texture=preload("res://art/king-crack-v1.png")
 material=ShaderMaterial.new()
 material.shader=preload("res://shaders/root_crack.gdshader")
 z_index=0
func configure(point: Vector2,progress: float,opacity: float):
 position=point
 scale=Vector2(224.0/texture.get_width(),84.0/texture.get_height())
 flip_h=sin(point.x*.13+point.y*.07)<0
 material.set_shader_parameter("progress",progress)
 material.set_shader_parameter("opacity",opacity)
