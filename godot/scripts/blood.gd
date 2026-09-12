class_name CairnBlood
extends Node2D
var drops: Array=[]
var marks: Array=[]
var wet: Dictionary={}
var air_view: Node2D
var floor_viewport: SubViewport
var ink: Node2D
var pending: Array=[]
func _ready():
	z_index=-10
	var ground_material=ShaderMaterial.new()
	ground_material.shader=preload("res://shaders/ground_blood.gdshader")
	material=ground_material
	floor_viewport=SubViewport.new()
	floor_viewport.size=Vector2i(1440,810)
	floor_viewport.disable_3d=true
	floor_viewport.transparent_bg=true
	floor_viewport.render_target_clear_mode=SubViewport.CLEAR_MODE_ONCE
	floor_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	add_child(floor_viewport)
	ink=Node2D.new()
	ink.draw.connect(draw_pending)
	floor_viewport.add_child(ink)
	RenderingServer.frame_post_draw.connect(finish_ink)
	air_view=Node2D.new()
	air_view.z_index=1800
	air_view.draw.connect(draw_air)
	add_child(air_view)
func reset():
	drops.clear()
	marks.clear()
	wet.clear()
	pending.clear()
	if floor_viewport:
		floor_viewport.render_target_clear_mode=SubViewport.CLEAR_MODE_ONCE
		floor_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
		ink.queue_redraw()
	queue_redraw()
func cell(x: float,y: float) -> Vector2i: return Vector2i(floor(x/16),floor(y/16))
func stain(x: float,y: float,r: float,amount: float=1,track: bool=false,angle: float=0):
	if x<0 or x>=1440 or y<535 or y>=810: return
	var points=PackedVector2Array()
	for i in 14:
		var a=i/14.0*TAU
		var rr=r*(.72+randf()*.4)
		points.append(Vector2(cos(a)*rr,sin(a)*rr*(.65 if track else .34)).rotated(angle)+Vector2(x,y))
	marks.append({"points":points,"x":x,"y":y,"r":r,"alpha":min(.86,amount*.8)})
	pending.append(marks.back())
	if floor_viewport:
		floor_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
		ink.queue_redraw()
	if not track:
		for yy in range(int((y-r*.34)/16),int((y+r*.34)/16)+1):
			for xx in range(int((x-r)/16),int((x+r)/16)+1): wet[Vector2i(xx,yy)]=65.0
	queue_redraw()
func hit(f: Dictionary,direction: int,fatal: bool):
	var count=(36+randi()%17) if fatal else (18+randi()%11)
	var units=4.5/CairnMechanics.STEP
	var launched=not f.down.is_empty() and not f.down.ground
	var horizontal=f.down.vx if launched else f.velocityX
	var vertical=f.down.vz if launched else f.air.get("vz",f.attack.get("vz",0))
	var force=(25 if launched else 80)+randf()*(65 if launched else 120)
	var fan=.65+randf()*1.1
	var lift=(10 if launched else 75)+randf()*(85 if launched else 160)
	var height=85+randf()*50+f.height*4.5
	stain(f.x,f.y,7 if launched else 42 if fatal else 19)
	for i in count:
		var angle=(randf()-.5)*fan
		var speed=force*(.5+randf()*.8)
		drops.append({"x":f.x+(randf()-.5)*18,"y":f.y+(randf()-.5)*12,"z":height+(randf()-.5)*65,"vx":horizontal*units*(1 if launched else .6)+direction*cos(angle)*speed,"vy":f.velocityY*units*.6+sin(angle)*speed*.9,"vz":-vertical*units*(1 if launched else .45)+lift+(randf()-.5)*530,"gravity":.25*units/CairnMechanics.STEP if launched else 850.0,"drag":0.0 if launched else .8,"r":1.5+pow(randf(),2.1)*(16 if fatal else 11)})
	while drops.size()>700: drops.pop_front()
func step(dt: float,fighters: Array):
	for d in drops:
		d.x+=d.vx*dt
		d.y+=d.vy*dt
		d.z+=d.vz*dt
		d.vz-=d.gravity*dt
		d.vx*=exp(-dt*d.drag)
		if d.z<=0: stain(d.x,clamp(d.y,540,790),d.r*2.3)
	drops=drops.filter(func(d):return d.z>0)
	for key in wet.keys():
		wet[key]-=dt
		if wet[key]<=0: wet.erase(key)
	for f in fighters:
		if not f.down.is_empty() and not f.down.ground:
			f.trail-=dt
			if f.trail<=0:
				f.trail=.02+randf()*.025
				for i in 2: drops.append({"x":f.x+(randf()-.5)*18,"y":f.y+(randf()-.5)*10,"z":60+f.height*4.5+randf()*25,"vx":f.down.vx*4.5/CairnMechanics.STEP*(.12+randf()*.18),"vy":(randf()-.5)*35,"vz":-f.down.vz*4.5/CairnMechanics.STEP*.12+(randf()-.5)*60,"gravity":850.0,"drag":1.6,"r":3+randf()*4})
		var now=Vector2(f.x,f.y)
		var delta=now-f.bootPos
		f.bootPos=now
		if not f.air.is_empty() or f.height>3:
			f.bootDistance=0
			continue
		f.bootCoat=max(f.bootCoat,wet.get(cell(f.x,f.y),0)/65.0)
		f.bootDistance+=min(delta.length(),40)
		if f.bootDistance>=20 and f.bootCoat>.05:
			f.bootDistance=0
			f.bootSide*=-1
			var angle=delta.angle()
			var point=now+Vector2(-sin(angle)*f.bootSide*9,cos(angle)*f.bootSide*5)
			stain(point.x,point.y,15 if not f.down.is_empty() else 7,f.bootCoat,true,angle)
			f.bootCoat*=.82
	while drops.size()>700: drops.pop_front()
	if air_view: air_view.queue_redraw()
func _draw():
	if floor_viewport: draw_texture(floor_viewport.get_texture(),Vector2.ZERO)
func draw_pending():
	for mark in pending:
		ink.draw_colored_polygon(mark.points,Color(.282,.027,.043,mark.alpha))
		ink.draw_set_transform(Vector2(mark.x,mark.y),0,Vector2(1,.34))
		ink.draw_circle(Vector2(-mark.r*.08,-mark.r*.04),mark.r*.56,Color(.45,.047,.07,mark.alpha*.65))
		ink.draw_set_transform(Vector2.ZERO)
func finish_ink():
	if not pending.is_empty():
		pending.clear()
		ink.queue_redraw()
func draw_air():
	for d in drops:
		var point=Vector2(d.x,d.y-d.z)
		var velocity=Vector2(d.vx,d.vy-d.vz)
		var tail=velocity.normalized()*min(d.r*2.4,velocity.length()*.009)
		air_view.draw_line(point-tail,point,Color("43060a"),max(1,d.r*.7),true)
		air_view.draw_circle(point,d.r*.5,Color("51090e"))
		if d.r>5:air_view.draw_circle(point+Vector2(-.12,-.16)*d.r,d.r*.13,Color(.38,.08,.09,.65))
