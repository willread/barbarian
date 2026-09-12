extends Node2D
const W=320
const H=180
var age=-.5
var deposits: Array=[]
var viewport: SubViewport
var fluid: ShaderMaterial
var surface: Sprite2D
var started=false
func _ready():
	z_index=2050
	var bursts=[]
	for i in 5: bursts.append({"at":.06+randf()*.5,"width":.012+randf()*.07})
	for n in 280:
		var burst=bursts.pick_random()
		var arrival=.03+randf()*.62 if randf()<.24 else clamp(burst.at+(randf()+randf()-1)*burst.width,.03,.65)
		deposits.append({"x":randf()*W,"y":randf()*H,"rx":9+randf()*19 if n<72 else 1+randf()*6,"ry":6+randf()*12 if n<72 else 1+randf()*4,"angle":randf()*PI,"phase":randf()*TAU,"lobes":2+randi()%4,"roughness":pow(randf(),1.7),"amount":1.7+randf()*2 if n<72 else .3+randf()*1.1,"at":arrival})
	deposits.sort_custom(func(a,b):return a.at<b.at)
	viewport=SubViewport.new()
	viewport.size=Vector2i(W,H)
	viewport.disable_3d=true
	viewport.transparent_bg=true
	viewport.render_target_clear_mode=SubViewport.CLEAR_MODE_ONCE
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var buffer=BackBufferCopy.new()
	buffer.copy_mode=BackBufferCopy.COPY_MODE_VIEWPORT
	viewport.add_child(buffer)
	var rect=ColorRect.new()
	rect.size=Vector2(W,H)
	fluid=ShaderMaterial.new()
	fluid.shader=load("res://shaders/blood_flow.gdshader")
	rect.material=fluid
	viewport.add_child(rect)
	surface=Sprite2D.new()
	surface.centered=false
	surface.texture=viewport.get_texture()
	surface.scale=Vector2(1440.0/W,1062.0/H)
	surface.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var shade=ShaderMaterial.new()
	shade.shader=load("res://shaders/blood_surface.gdshader")
	surface.material=shade
	add_child(surface)
	surface.visible=false
func advance(dt: float):
	var old=age
	age=min(3.8,age+dt)
	if age<0: return
	surface.visible=true
	var positions=PackedVector4Array()
	var shapes=PackedVector4Array()
	var amounts=PackedFloat32Array()
	var count=0
	while not deposits.is_empty() and deposits[0].at<=age and count<64:
		var d=deposits.pop_front()
		positions.append(Vector4(d.x,d.y,d.rx,d.ry))
		shapes.append(Vector4(d.angle,d.phase,d.lobes,d.roughness))
		amounts.append(d.amount)
		count+=1
	positions.resize(64)
	shapes.resize(64)
	amounts.resize(64)
	fluid.set_shader_parameter("positions",positions)
	fluid.set_shader_parameter("shapes",shapes)
	fluid.set_shader_parameter("amounts",amounts)
	fluid.set_shader_parameter("count",count)
	fluid.set_shader_parameter("clear",not started)
	fluid.set_shader_parameter("age",age)
	fluid.set_shader_parameter("ticks",min(3.0,dt*60))
	if old<3.8: viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	started=true
	queue_redraw()
func _draw():
	if age<0: return
	var fade=clamp((age-.25)/1.3,0,1)
	draw_rect(Rect2(0,0,1440,1062),Color(.439,.035,.063,fade*fade*(3-2*fade)))

