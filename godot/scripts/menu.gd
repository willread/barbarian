extends Node2D
signal activated(label: String)
signal sound_requested(id: String)
var art: CairnArt
var items: Array=[]
var selected=0
var clock=0.0
var switching=false
var title_mode=true
var screen_size=Vector2(1440,810)

func setup(source: CairnArt):
	art=source
	z_index=2100

func show_items(labels: Array, is_title: bool=true, animate: bool=true):
	for item in items: item.node.queue_free()
	items.clear()
	selected=0
	title_mode=is_title
	var options=not labels.has("BEGIN") and labels.size()>2 or labels.has("FULLSCREEN: ON") or labels.has("FULLSCREEN: OFF")
	var size=1.0 if is_title and labels.has("BEGIN") else .58 if labels.size()>3 else .71
	var center=417.6 if is_title else 720.0
	var top=380.7 if is_title else 430.0
	for i in labels.size():
		var label=labels[i]
		var meta=art.data.menu[label]
		var group=Node2D.new()
		var y=top+i*(meta.height*size-(20.16 if not options else 15.84))*.75
		group.position=Vector2(center,y)
		add_child(group)
		var fire=ContourFire.new()
		group.add_child(fire)
		fire.setup(art.texture("menu-"+meta.id+"-fuel.png"),Vector2(meta.fw,meta.fh),Vector2(-meta.fw*.5,-meta.pad))
		fire.scale=Vector2.ONE*size
		var face=Sprite2D.new()
		face.centered=false
		face.texture=art.texture("menu-"+meta.id+".png")
		face.position=Vector2(-meta.width*.5*size,0)
		face.scale=Vector2(meta.width,meta.height)*size/face.texture.get_size()
		group.add_child(face)
		fire.heat_face(face,Rect2(Vector2(-meta.width*.5,0),Vector2(meta.width,meta.height)))
		items.append({"node":group,"label":label,"fire":fire,"face":face,"x":center,"y":y,"width":meta.width*size,"height":meta.height*size})
		if animate:
			group.position.y=y-1224
			var tween=create_tween()
			tween.tween_interval((labels.size()-1-i)*.24)
			tween.tween_property(group,"position:y",y,.3264).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_callback(func():sound_requested.emit("menu_land"))
			tween.tween_property(group,"position:y",y+2.6,.024)
			tween.tween_property(group,"position:y",y-4.9,.048).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(group,"position:y",y,.0816).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	select(0,false)
	layout_screen(screen_size,is_title)

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
		items[i].fire.emitting=i==selected
	if shake:
		quake()
		sound_requested.emit("menu_select")

func quake():
	if items.is_empty(): return
	var item=items[selected]
	var tween=create_tween()
	for x in [-2,2,-1.5,1,-.5,0]: tween.tween_property(item.node,"position:x",item.x+x,.035)

func activate():
	if switching or items.is_empty(): return
	quake()
	sound_requested.emit("menu_activate")
	activated.emit(items[selected].label)

func handle(event: InputEvent):
	if switching: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_DOWN,KEY_S,KEY_TAB]: select(selected+(-1 if event.shift_pressed else 1))
		if event.keycode in [KEY_UP,KEY_W]: select(selected-1)
		if event.keycode in [KEY_ENTER,KEY_SPACE]: activate()
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var mouse=get_local_mouse_position()
		for i in items.size():
			var item=items[i]
			if Rect2(item.node.position-Vector2(item.width*.5,0),Vector2(item.width,item.height)).has_point(mouse):
				if selected!=i: select(i)
				if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed: activate()
				break

func _process(dt: float):
	clock+=dt
	if not visible: return
	for item in items: item.fire.set_process(visible)


func layout_screen(size: Vector2,is_title: bool):
	screen_size=size
	var tall=size.y>1200
	var factor=clamp(size.y/810.,.55,1.45)
	var bounds=Rect2()
	for item in items:
		var rect=Rect2(Vector2(item.x-item.width*.5,item.y),Vector2(item.width,item.height))
		bounds=rect if bounds.size==Vector2.ZERO else bounds.merge(rect)
	if not is_title: factor=min(factor,min(size.x*.86/max(1.,bounds.size.x),size.y*.8/max(1.,bounds.size.y)))
	scale=Vector2.ONE*factor
	var anchor=Vector2(size.x*.5 if tall or not is_title else size.x*.32,size.y*.48 if is_title else size.y*.54)
	position=anchor-Vector2(417.6 if is_title else 720.,380.7 if is_title else 430.)*factor
	if not is_title: position=size*.5-bounds.get_center()*factor
