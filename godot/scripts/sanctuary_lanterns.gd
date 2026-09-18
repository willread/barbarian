extends Node2D
var clock=0.0
var lamps: Array=[]
func _ready():
 for i in 2:
  var pivot=Node2D.new()
  pivot.position=Vector2(170,-77) if i==0 else Vector2(1250,-62)
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
  lamps[i].pivot.rotation=sway(t,i)
  lamps[i].fire.set_shader_parameter("clock",t)

 queue_redraw()
func sway(t: float,i: int) -> float:
 return sin(t*(.57 if i==0 else .43)+i*2.1)*(.018 if i==0 else .013)+sin(t*.19+i)*.002
func random_value(seed_value: float) -> float:
 return fposmod(sin(seed_value*12.9898)*43758.5453,1.)
func _draw():
 # Evaluate released embers in world space: falling sparks do not rotate with the cage.
 # Analytic ages also preserve pause and preview seeking without frame-rate dependence.
 for i in lamps.size():
  var period=7.3 if i==0 else 9.1
  var offset=0.0 if i==0 else 2.8
  var cycle=int(floor((clock-offset)/period))
  var factor=.42 if i==0 else .40
  for previous in 2:
   var batch=cycle-previous
   for particle in 42:
    var seed_value=float(batch*97+particle*13+i*701)
    var birth=batch*period+offset+particle*.025+random_value(seed_value)*.16
    var age=clock-birth
    var life=1.5+random_value(seed_value+1)*.7
    if age<0 or age>=life:continue
    var side=-1. if particle%2==0 else 1.
    var socket=Vector2(side*(175+random_value(seed_value+2)*18)*factor,(1160+random_value(seed_value+3)*45)*factor)
    var origin=lamps[i].pivot.position+socket.rotated(sway(birth,i))
    var velocity=Vector2(side*(8+random_value(seed_value+4)*20),10+random_value(seed_value+5)*22)
    var p=origin+velocity*age+Vector2(sin(age*2.4+seed_value)*age*3,57*age*age)
    var motion=velocity+Vector2(0,114*age)
    var tail=motion.normalized()*clampf(motion.length()*.022,1.4,6.)
    var cooling=age/life
    var alpha=smoothstep(0.,.08,age)*(1.-smoothstep(.45,1.,cooling))*.95
    var color=Color(1.,lerpf(.72,.16,cooling),lerpf(.2,.015,cooling),alpha)
    draw_line(p-tail,p,color,1.+random_value(seed_value+6)*.65,true)
    if particle%4==0:draw_circle(p,1.7,Color(1,.28,.03,alpha*.12))
