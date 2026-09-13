extends Node2D
var art: CairnArt
var key="valley"
var layers: Array=[]
var clock=0.0
var screen: Dictionary={}
var chapter_screens=JSON.parse_string(FileAccess.get_file_as_string("res://worlds/citadel.json"))
func setup(source: CairnArt,name: String):
	art=source
	key=name
	for child in get_children(): child.queue_free()
	layers.clear()
	screen={}
	if name.begins_with("citadel-"):
		screen=chapter_screens[int(name.get_slice("-",1))-1]
		var painting=Sprite2D.new()
		painting.texture=art.texture(key+"-base.png")
		painting.centered=false
		painting.scale=Vector2(1440,810)/painting.texture.get_size()
		add_child(painting)
		for region in screen.regions:
			var a=region.animation
			var sprite=Sprite2D.new()
			sprite.centered=false
			sprite.texture=art.texture(a.atlas)
			sprite.position=Vector2(a.rect[0],a.rect[1])*1.125
			sprite.scale=Vector2(a.rect[2],a.rect[3])*1.125/sprite.texture.get_size()
			var mat=ShaderMaterial.new()
			mat.shader=preload("res://shaders/region_loop.gdshader")
			sprite.material=mat
			add_child(sprite)
			layers.append(mat)
		var foreground=Sprite2D.new()
		foreground.centered=false
		foreground.texture=art.texture(key+"-foreground.png")
		foreground.scale=Vector2(1.125,1.125)
		foreground.z_as_relative=false
		foreground.z_index=1805
		add_child(foreground)
		z_index=-100
		return
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
			mat.set_shader_parameter("painting",sprite.texture)
			sprite.material=mat
			add_child(sprite)
			layers.append(mat)
	z_index=-100

func advance(t: float):
	clock=t
	for mat in layers: mat.set_shader_parameter("clock",fmod(t,24))
	queue_redraw()

func _draw():
	if not art or not screen.is_empty(): return
	for splash in art.data.environments[key].splashes:
		for i in 44:
			var a=fmod(clock/.75+i/44.0,1)
			var radius=splash[2]*1440
			var p=Vector2(splash[0]*1440+sin(i*21.73)*radius*a,splash[1]*810-radius*.8*a+radius*a*a)
			draw_circle(p,.8,Color(.84,.88,.87,pow(sin(a*PI),2)*.45))


func constrain(f: Dictionary):
	if screen.is_empty():return
	# Use actual interior intervals, including concave boundaries. Offscreen
	# entrances use the nearest slice but keep their horizontal spawn position.
	var poly=screen.walkable.polygon
	var min_x=1.0
	var max_x=0.0
	for point in poly:
		min_x=minf(min_x,point[0])
		max_x=maxf(max_x,point[0])
	var x=clampf(f.x/1440.0,min_x+.00001,max_x-.00001)
	var ys: Array=[]
	for i in poly.size():
		var a=poly[i]
		var b=poly[(i+1)%poly.size()]
		if (a[0]<=x and x<b[0]) or (b[0]<=x and x<a[0]):
			ys.append(lerpf(a[1],b[1],(x-a[0])/(b[0]-a[0]))*810)
	ys.sort()
	var nearest=f.y
	var distance=INF
	for i in range(0,ys.size()-1,2):
		var padding=minf(2,(ys[i+1]-ys[i])*.25)
		var candidate=clampf(f.y,ys[i]+padding,ys[i+1]-padding)
		if absf(candidate-f.y)<distance:
			nearest=candidate
			distance=absf(candidate-f.y)
	f.y=nearest
	if f.get("entered_arena",false):f.x=x*1440.0
