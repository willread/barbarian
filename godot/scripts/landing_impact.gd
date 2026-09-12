extends Node2D
# Layered ground impact: fast dust front, trailing billows, ballistic grit.
var age=0.0
var strength=1.0
var motes: Array=[]
var grit: Array=[]
var cloud: GradientTexture2D

func setup(point: Vector2, heavy: bool):
	position=point
	z_index=int(point.y)*2+1
	strength=1.0 if heavy else .8
	var gradient=Gradient.new()
	gradient.set_color(0,Color.WHITE)
	gradient.add_point(.4,Color(1,1,1,.75))
	gradient.set_color(gradient.get_point_count()-1,Color(1,1,1,0))
	cloud=GradientTexture2D.new()
	cloud.gradient=gradient
	cloud.width=64
	cloud.height=64
	cloud.fill=GradientTexture2D.FILL_RADIAL
	cloud.fill_from=Vector2(.5,.5)
	cloud.fill_to=Vector2(.5,0)
	material=ShaderMaterial.new()
	material.shader=preload("res://shaders/impact_dust.gdshader")
	material.set_shader_parameter("seed",randf()*100)
	for i in 72:
		var front=i<44
		var angle=TAU*(i+randf()*.8)/(44.0 if front else 28.0)
		motes.append({"direction":Vector2(cos(angle),sin(angle)*.32),"reach":randf_range(275,335) if front else randf_range(55,205),"radius":randf_range(24,39) if front else randf_range(29,53),"lift":randf_range(4,15) if front else randf_range(30,65),"life":randf_range(.55,.85) if front else randf_range(.85,1.3),"front":front,"angle":randf_range(-.3,.3),"shade":randf_range(.8,1.12)})
	for i in 16:
		var angle=randf()*TAU
		grit.append({"velocity":Vector2(cos(angle)*randf_range(90,250),sin(angle)*35),"lift":randf_range(60,145),"r":randf_range(1.2,2.7)})

func advance(dt: float):
	age+=dt
	if age>1.4:queue_free()
	else:
		material.set_shader_parameter("age",age)
		queue_redraw()

func _draw():
	if not cloud:return
	for mote in motes:
		var t=clampf(age/mote.life,0,1)
		var spread=1-exp(-age*(5.5 if mote.front else 2.5))
		var p=mote.direction*mote.reach*1.25*spread*strength
		p.y-=mote.lift*(1-exp(-age*2))
		var r=mote.radius*(.45+t*.95)*strength
		var alpha=smoothstep(0,.035,age)*pow(1-t,1.2)*(.85 if mote.front else .68)
		draw_set_transform(p,mote.angle)
		draw_texture_rect(cloud,Rect2(-r,-r*.7,r*2,r*1.4),false,Color(.61*mote.shade,.55*mote.shade,.45*mote.shade,alpha))
	draw_set_transform(Vector2.ZERO)
	for bit in grit:
		var height=maxf(0,bit.lift*age-260*age*age)
		if height<=0:continue
		var p=bit.velocity*age*strength-Vector2(0,height)
		draw_circle(p,bit.r,Color(.24,.21,.17,1-age))
