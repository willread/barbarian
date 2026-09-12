extends Node2D
var art: CairnArt
var key="valley"
var layers: Array=[]
var clock=0.0
func setup(source: CairnArt,name: String):
	art=source
	key=name
	for child in get_children(): child.queue_free()
	layers.clear()
	var base=Sprite2D.new()
	base.texture=art.texture(key+"-base.png")
	base.centered=false
	add_child(base)
	var config=art.data.environments[key]
	for pass_index in 3:
		if pass_index==2 and config.near:
			var near=Sprite2D.new()
			near.texture=art.texture(key+"-near.png")
			near.centered=false
			add_child(near)
		for i in config.layers.size():
			var l=config.layers[i]
			var pass_id=0 if not l.near else 1 if l.smoke else 2
			if pass_id!=pass_index: continue
			var sprite=Sprite2D.new()
			sprite.centered=false
			sprite.position=Vector2(l.x,l.y)
			sprite.texture=art.texture("%s-layer-%d.png"%[key,i])
			var mat=ShaderMaterial.new()
			mat.shader=load("res://shaders/environment.gdshader")
			mat.set_shader_parameter("region_mask",art.texture("%s-mask-%d.png"%[key,i]))
			mat.set_shader_parameter("travel",Vector2(l.dx/l.w,l.dy/l.h))
			mat.set_shader_parameter("period",float(l.period))
			mat.set_shader_parameter("smoke",l.smoke)
			sprite.material=mat
			add_child(sprite)
			layers.append(mat)
	z_index=-100

func advance(t: float):
	clock=t
	for mat in layers: mat.set_shader_parameter("clock",fmod(t,24))
	queue_redraw()

func _draw():
	if not art: return
	for splash in art.data.environments[key].splashes:
		for i in 44:
			var a=fmod(clock/.75+i/44.0,1)
			var radius=splash[2]*1440
			var p=Vector2(splash[0]*1440+sin(i*21.73)*radius*a,splash[1]*810-radius*.8*a+radius*a*a)
			draw_circle(p,.8,Color(.84,.88,.87,pow(sin(a*PI),2)*.45))
