extends Node2D
# A single grounded burst: randomized once, then smoothly expanding and settling.
var age=0.0
var strength=1.0
var motes: Array=[]
var cloud: GradientTexture2D

func setup(point: Vector2, heavy: bool):
	position=point
	z_index=int(point.y)*2+1
	strength=1.0 if heavy else .75
	var gradient=Gradient.new()
	gradient.set_color(0,Color(1,1,1,.55))
	gradient.add_point(.35,Color(1,1,1,.28))
	gradient.set_color(gradient.get_point_count()-1,Color(1,1,1,0))
	cloud=GradientTexture2D.new()
	cloud.gradient=gradient
	cloud.width=64
	cloud.height=64
	cloud.fill=GradientTexture2D.FILL_RADIAL
	cloud.fill_from=Vector2(.5,.5)
	cloud.fill_to=Vector2(.5,0)
	for i in 16:
		var angle=TAU*(i+randf()*.8)/16.0
		motes.append({"direction":Vector2(cos(angle),sin(angle)*.24),"speed":randf_range(75,150),"radius":randf_range(13,24),"lift":randf_range(18,42),"life":randf_range(.48,.76)})

func advance(dt: float):
	age+=dt
	if age>.8:queue_free()
	else:queue_redraw()

func _draw():
	if not cloud:return
	# Ground-plane ellipse, softened across several narrow bands.
	var progress=clampf(age/.32,0,1)
	var radius=(12+115*(1-pow(1-progress,2)))*strength
	var opacity=pow(1-progress,2)*.34
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.25))
	for band in 4:
		draw_arc(Vector2.ZERO,radius+band*2,0,TAU,72,Color(.72,.65,.52,opacity/(band+1)),2.0,true)
	draw_set_transform(Vector2.ZERO)
	for mote in motes:
		var t=clampf(age/mote.life,0,1)
		var p=mote.direction*mote.speed*(1-exp(-age*4))*.45*strength
		p.y-=mote.lift*age
		var r=mote.radius*(.45+t*1.15)*strength
		var alpha=smoothstep(0,.055,age)*pow(1-t,1.5)*.65
		draw_texture_rect(cloud,Rect2(p-Vector2(r,r*.7),Vector2(r*2,r*1.4)),false,Color(.49,.43,.34,alpha))
