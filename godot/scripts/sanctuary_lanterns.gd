extends Node2D
var clock=0.0
var lamps: Array=[]
func _ready():
 for i in 2:
  var pivot=Node2D.new()
  pivot.position=Vector2(170,-22) if i==0 else Vector2(1250,-17)
  add_child(pivot)
  var sprite=Sprite2D.new()
  sprite.texture=load("res://assets/sanctuary-lantern.png")
  sprite.centered=false
  var factor=.42 if i==0 else .40
  sprite.scale=Vector2(factor,factor)
  sprite.position=Vector2(-512*factor,0)
  var fire=ShaderMaterial.new()
  fire.shader=preload("res://shaders/sanctuary_lantern.gdshader")
  fire.set_shader_parameter("seed",float(i)*17.3)
  sprite.material=fire
  pivot.add_child(sprite)
  lamps.append({"pivot":pivot,"fire":fire})
func advance(t: float):
 clock=t
 for i in lamps.size():
  lamps[i].pivot.rotation=sin(t*(.57 if i==0 else .43)+i*2.1)*(.018 if i==0 else .013)+sin(t*.19+i)*.002
  lamps[i].fire.set_shader_parameter("clock",t)
