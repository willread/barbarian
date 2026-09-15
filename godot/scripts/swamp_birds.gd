extends Node2D
var clock=0.0
func noise_value(i: float) -> float:
 return fposmod(sin(i*127.1+311.7)*43758.5453,1.0)
func _ready():
 scale=Vector2(1.125,1.125)
 var mat=ShaderMaterial.new()
 mat.shader=preload("res://shaders/swamp_bird_depth.gdshader")
 mat.set_shader_parameter("depth_mask",load("res://assets/swamp-bird-depth.png"))
 material=mat
func polygon(points: Array,origin: Vector2,size: float,direction: float,color: Color):
 var transformed=PackedVector2Array()
 for p in points:transformed.append(origin+Vector2(p.x*direction,p.y)*size)
 # Wing contours can fold during the downstroke. Explicit triangles remain
 # drawable at those poses instead of asking Godot to triangulate a crossing outline.
 for i in range(1,transformed.size()-1):
  var a=transformed[0]
  var b=transformed[i]
  var c=transformed[i+1]
  if absf((b-a).cross(c-a))>.001:draw_colored_polygon(PackedVector2Array([a,b,c]),color)
func _draw():
 var t=fposmod(clock,120.0)
 for group in range(3):
  var seed=31+group*19
  var start=3+group*40+noise_value(seed)*6
  var travel=12+noise_value(seed+1)*5
  var elapsed=t-start
  if elapsed<0 or elapsed>travel+3:continue
  var count=2+int(noise_value(seed+2)*3)
  var direction=1.0 if noise_value(seed+3)>.5 else -1.0
  for i in range(count):
   var bird_seed=seed+i*7
   var p=(elapsed-noise_value(bird_seed+4)*2)/travel
   var x=-90+p*1460 if direction>0 else 1370-p*1460
   var y=205+noise_value(seed+5)*60+noise_value(bird_seed+6)*35+sin(p*PI)*13
   var size=.42+noise_value(bird_seed+8)*.22
   var wing=18+noise_value(bird_seed+9)*6
   var flap=sin(elapsed*(6+noise_value(bird_seed+10)*3)+i*2.4)
   var color=Color("69695d")
   color.a=.46+.12*sin(x*.013+t*.3)
   var origin=Vector2(x,y)
   polygon([Vector2(-14,3),Vector2(-5,-2),Vector2(5,-2),Vector2(11,-4),Vector2(16,-3),Vector2(8,1),Vector2(3,3)],origin,size,direction,color)
   polygon([Vector2(-3,0),Vector2(-wing*.55,-7-flap*wing*.7),Vector2(-wing,-3-flap*wing),Vector2(-wing*.7,2-flap*wing*.75),Vector2(3,2)],origin,size,direction,color)
   polygon([Vector2(1,0),Vector2(wing*.3,-8-flap*wing*.55),Vector2(wing*.8,-3-flap*wing*.85),Vector2(wing*.6,3-flap*wing*.55),Vector2(0,2)],origin,size,direction,color)
