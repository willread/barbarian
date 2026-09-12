extends Node2D
signal activated(label: String)
var art: CairnArt
var items: Array=[]
var selected=0
var clock=0.0
var switching=false
var title_mode=true

func setup(source: CairnArt):
	art=source
	z_index=2100

func show_items(labels: Array, is_title: bool=true, animate: bool=true):
	for item in items: item.node.queue_free()
	items.clear()
	selected=0
	title_mode=is_title
	var options=labels.size()==3 and str(labels[0]).begins_with("SOUND:")
	var size=1.0 if is_title and not options else .71 if is_title else .55
	var center=417.6 if is_title else 720.0
	var top=380.7 if is_title else 430.0
	for i in labels.size():
		var label=labels[i]
		var meta=art.data.menu[label]
		var group=Node2D.new()
		var y=top+i*(meta.height*size-(20.16 if not options else 15.84))
		group.position=Vector2(center,y)
		add_child(group)
		var fire=Sprite2D.new()
		fire.centered=false
		fire.texture=art.texture("menu-"+meta.id+"-fuel.png")
		fire.position=Vector2(-meta.fw*.5*size,-meta.pad*size)
		fire.scale=Vector2(meta.fw,meta.fh)*size/fire.texture.get_size()
		var mat=ShaderMaterial.new()
		mat.shader=load("res://shaders/menu_fire.gdshader")
		mat.set_shader_parameter("pixels",fire.texture.get_size())
		fire.material=mat
		group.add_child(fire)
		var face=Sprite2D.new()
		face.centered=false
		face.texture=art.texture("menu-"+meta.id+".png")
		face.position=Vector2(-meta.width*.5*size,0)
		face.scale=Vector2(meta.width,meta.height)*size/face.texture.get_size()
		group.add_child(face)
		items.append({"node":group,"label":label,"fire":fire,"face":face,"x":center,"y":y,"width":meta.width*size,"height":meta.height*size})
		if animate:
			group.position.y=y-1224
			var tween=create_tween()
			tween.tween_interval((labels.size()-1-i)*.24)
			tween.tween_property(group,"position:y",y,.3264).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(group,"position:y",y+2.6,.024)
			tween.tween_property(group,"position:y",y-4.9,.048).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(group,"position:y",y,.0816).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	select(0,false)

func switch_items(labels: Array,is_title: bool=true):
	if switching: return
	switching=true
	var duration=.26+max(0,items.size()-1)*.06
	for i in items.size():
		var item=items[i]
		var tween=create_tween()
		tween.tween_interval((items.size()-1-i)*.06)
		tween.tween_property(item.node,"position:y",item.y+1008,.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(duration).timeout
	show_items(labels,is_title)
	switching=false

func select(index: int, shake: bool=true):
	if items.is_empty(): return
	selected=posmod(index,items.size())
	for i in items.size():
		items[i].fire.visible=i==selected
		items[i].face.modulate=Color(1.25,1.25,1.25) if i==selected else Color.WHITE
	if shake: quake()

func quake():
	if items.is_empty(): return
	var item=items[selected]
	var tween=create_tween()
	for x in [-2,2,-1.5,1,-.5,0]: tween.tween_property(item.node,"position:x",item.x+x,.035)

func activate():
	if switching or items.is_empty(): return
	quake()
	activated.emit(items[selected].label)

func handle(event: InputEvent):
	if switching: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_DOWN,KEY_S,KEY_TAB]: select(selected+(-1 if event.shift_pressed else 1))
		if event.keycode in [KEY_UP,KEY_W]: select(selected-1)
		if event.keycode in [KEY_ENTER,KEY_SPACE]: activate()
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var mouse=get_global_mouse_position()
		for i in items.size():
			var item=items[i]
			if Rect2(item.node.position-Vector2(item.width*.5,0),Vector2(item.width,item.height)).has_point(mouse):
				if selected!=i: select(i)
				if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed: activate()
				break

func _process(dt: float):
	clock+=dt
	if not visible: return
	for item in items: item.fire.material.set_shader_parameter("clock",clock)

