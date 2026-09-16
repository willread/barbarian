extends Node2D
var art: CairnArt
var key="valley"
var layers: Array=[]
var clock=0.0
var framing_offset=Vector2.ZERO
var screen: Dictionary={}
var chapter_screens=JSON.parse_string(FileAccess.get_file_as_string("res://worlds/citadel.json"))
var episode_screens={} if OS.has_feature("shareware") else {"swamp":JSON.parse_string(FileAccess.get_file_as_string("res://worlds/swamp.json")),"ashen":JSON.parse_string(FileAccess.get_file_as_string("res://worlds/ashen.json"))}
var decorations: Array=[]
func setup(source: CairnArt,name: String):
	art=source
	key=name
	for child in get_children():
		remove_child(child)
		child.queue_free()
	layers.clear()
	decorations.clear()
	position=Vector2.ZERO
	framing_offset=Vector2.ZERO
	scale=Vector2.ONE
	screen={}
	if name.get_slice("-",0) in ["citadel","swamp","ashen"]:
		var chapter=name.get_slice("-",0)
		screen=(chapter_screens if chapter=="citadel" else episode_screens[chapter])[int(name.get_slice("-",1))-1]
		var painting=Sprite2D.new()
		painting.texture=art.texture(key+"-base.png")
		painting.centered=false
		painting.scale=Vector2(1440,810)/painting.texture.get_size()
		if chapter=="ashen":
			var heat=ShaderMaterial.new()
			heat.shader=preload("res://shaders/ashen_heat.gdshader")
			heat.set_meta("continuous_clock",true)
			heat.set_shader_parameter("area",float(name.get_slice("-",1)))
			if name=="ashen-1":
				heat.set_shader_parameter("road_original",painting.texture)
				heat.set_shader_parameter("road_clear",art.texture("ashen-track-clear.png"))
			painting.material=heat
			layers.append(heat)
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
			mat.set_shader_parameter("grid",Vector2(a.get("columns",8),a.get("rows",8)))
			mat.set_shader_parameter("frame_count",float(a.get("count",60)))
			mat.set_shader_parameter("fps",float(a.get("fps",30)))
			mat.set_shader_parameter("blend_frames",a.get("blend",true))
			sprite.material=mat
			if region.get("foreground",false):
				sprite.z_as_relative=false
				sprite.z_index=1805
			add_child(sprite)
			layers.append(mat)
		if chapter=="citadel":
			var foreground=Sprite2D.new()
			foreground.centered=false
			foreground.texture=art.texture(key+"-foreground.png")
			foreground.scale=Vector2(1.125,1.125)
			foreground.z_as_relative=false
			foreground.z_index=1805
			add_child(foreground)
			for kind in ["distant","ground","near"]:
				var rain=preload("res://scripts/citadel_rain.gd").new()
				rain.name="CitadelRain"+kind.capitalize()
				rain.configure(screen.walkable.polygon,int(name.get_slice("-",1)),kind)
				rain.z_as_relative=false
				rain.z_index=1804 if kind=="near" else -40 if kind=="ground" else -50
				add_child(rain)
				decorations.append(rain)
		if name=="ashen-3":
			var brazier=preload("res://scripts/crucible_brazier.gd").new()
			brazier.name="HangingBrazier"
			brazier.set_meta("continuous_clock",true)
			add_child(brazier)
			decorations.append(brazier)
		if name=="ashen-2":
			var exhaust=ColorRect.new()
			exhaust.name="FurnaceExhaust"
			exhaust.size=Vector2(1440,810)
			exhaust.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var exhaust_material=ShaderMaterial.new()
			exhaust_material.shader=preload("res://shaders/furnace_exhaust.gdshader")
			exhaust_material.set_meta("continuous_clock",true)
			exhaust.material=exhaust_material
			add_child(exhaust)
			layers.append(exhaust_material)
		if name=="ashen-1":
			var trains=preload("res://scripts/ashen_trains.gd").new()
			trains.name="OreTrains"
			trains.track_material=painting.material
			trains.set_meta("continuous_clock",true)
			add_child(trains)
			decorations.append(trains)
		if chapter=="ashen":
			for front in [false,true]:
				var decoration=preload("res://scripts/ashen_scenery.gd").new()
				decoration.area=int(name.get_slice("-",1))
				decoration.foreground=front
				decoration.set_meta("continuous_clock",true)
				if front:
					decoration.z_as_relative=false
					decoration.z_index=1805
				add_child(decoration)
				decorations.append(decoration)
		if chapter=="ashen":
			var veil=ColorRect.new()
			veil.name="AshenVeil"
			veil.size=Vector2(1440,810)
			veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
			veil.z_as_relative=false
			veil.z_index=1810
			var veil_material=ShaderMaterial.new()
			veil_material.shader=preload("res://shaders/ashen_veil.gdshader")
			veil_material.set_meta("continuous_clock",true)
			veil_material.set_shader_parameter("area",float(name.get_slice("-",1)))
			veil.material=veil_material
			add_child(veil)
			layers.append(veil_material)
			# Explicitly recapture after fighters, projectiles and foreground effects.
			# Earlier screen-reading effects may already have populated the back buffer.
			var capture=BackBufferCopy.new()
			capture.name="AshenSceneCapture"
			capture.copy_mode=BackBufferCopy.COPY_MODE_VIEWPORT
			capture.z_as_relative=false
			capture.z_index=1811
			add_child(capture)
			var scene_heat=ColorRect.new()
			scene_heat.name="AshenSceneHeat"
			scene_heat.size=Vector2(1440,810)
			scene_heat.mouse_filter=Control.MOUSE_FILTER_IGNORE
			scene_heat.z_as_relative=false
			scene_heat.z_index=1812
			var scene_material=ShaderMaterial.new()
			scene_material.shader=preload("res://shaders/ashen_scene_heat.gdshader")
			scene_material.set_meta("continuous_clock",true)
			scene_material.set_shader_parameter("area",float(name.get_slice("-",1)))
			scene_heat.material=scene_material
			add_child(scene_heat)
			layers.append(scene_material)
		if chapter=="swamp":
			var foreground_layer=Node2D.new()
			foreground_layer.z_as_relative=false
			foreground_layer.z_index=1805
			add_child(foreground_layer)
			if screen.get("birds",false):
				var birds=preload("res://scripts/swamp_birds.gd").new()
				birds.set_meta("continuous_clock",true)
				add_child(birds)
				decorations.append(birds)
			var fog=ColorRect.new()
			fog.name="DriftingFog"
			fog.size=Vector2(1440,810)
			fog.mouse_filter=Control.MOUSE_FILTER_IGNORE
			fog.z_as_relative=false
			fog.z_index=1810
			var fog_material=ShaderMaterial.new()
			fog_material.set_meta("continuous_clock",true)
			fog_material.shader=preload("res://shaders/swamp_fog.gdshader")
			fog_material.set_shader_parameter("area",float(name.get_slice("-",1)))
			fog.material=fog_material
			add_child(fog)
			layers.append(fog_material)
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
	for mat in layers: mat.set_shader_parameter("clock",t if mat.get_meta("continuous_clock",false) else fmod(t,24))
	for decoration in decorations:
		if decoration.has_method("advance"):
			decoration.advance(t)
			continue
		decoration.clock=t if decoration.get_meta("continuous_clock",false) else fmod(t,24)
		decoration.queue_redraw()
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
