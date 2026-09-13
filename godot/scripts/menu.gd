extends Node2D
signal activated(label: String)
signal sound_requested(id: String)
var art: CairnArt
var yellow_flames=false
var action_emphasis: Dictionary={}
var action_height=64.0
var centered_action=""
var items: Array=[]
const LOCKED=["EP 2: THE SUNKEN WILDS","EP 3: THE ASHEN DEPTHS"]
var unavailable: Callable
var selected=0
var compact_pause=false
var clock=0.0
var switching=false
var title_mode=true
var screen_size=Vector2(1440,810)

func setup(source: CairnArt):
	art=source
	z_index=2100

func is_locked(label: String) -> bool:
	return label in LOCKED or (unavailable.is_valid() and unavailable.call(label))

func show_items(labels: Array, is_title: bool=true, animate: bool=true):
	for item in items: item.node.queue_free()
	items.clear()
	selected=0
	title_mode=is_title
	var options=not labels.has("BEGIN") and labels.size()>2 or labels.has("FULLSCREEN: ON") or labels.has("FULLSCREEN: OFF")
	var base_size=1.0 if is_title and labels.has("BEGIN") else .58 if labels.size()>3 else .71
	var center=417.6 if is_title else 720.0
	var top=380.7 if is_title else 430.0
	for i in labels.size():
		var label=labels[i]
		var size=base_size*float(action_emphasis.get(label,1.0))
		var meta=art.data.menu[label]
		var group=Node2D.new()
		var spacing=.75 if is_title and labels.has("BEGIN") else (.83 if compact_pause else 1.0)
		var y=top+i*(meta.height*size-(20.16 if not options else 15.84))*spacing
		group.position=Vector2(center,y)
		add_child(group)
		var fire=ContourFire.new()
		fire.menu_palette=true
		fire.yellow_palette=yellow_flames
		group.add_child(fire)
		fire.setup(art.texture("menu-"+meta.id+"-fuel.png"),Vector2(meta.fw,meta.fh),Vector2(-meta.fw*.5,-meta.pad))
		fire.scale=Vector2.ONE*size
		var face=Sprite2D.new()
		face.centered=false
		face.texture=art.texture("menu-"+meta.id+".png")
		face.position=Vector2(-meta.width*.5*size,0)
		face.scale=Vector2(meta.width,meta.height)*size/face.texture.get_size()
		group.add_child(face)
		if is_locked(label):group.modulate=Color(1,1,1,.48)
		# Locked text uses the ordinary sprite material so inherited alpha is respected.
		if not is_locked(label):fire.heat_face(face,Rect2(Vector2(-meta.width*.5,0),Vector2(meta.width,meta.height)))
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

# Footer items land individually after their responsive positions are known.
# Animate an offset so resizing cannot leave a tween targeting an obsolete row.
func drop_actions():
	for i in items.size():
		var item=items[i]
		item.drop_offset=-maxf(1224,get_viewport_rect().size.y/maxf(.01,scale.y)*2)
		item.node.position.y=item.y+item.drop_offset
		var move=func(offset):
			item.drop_offset=offset
			item.node.position.y=item.y+offset
		var tween=create_tween()
		tween.tween_interval(i*.50)
		tween.tween_method(move,float(item.drop_offset),0.0,.3264).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():sound_requested.emit("menu_land"))
		tween.tween_method(move,0.0,2.6,.024)
		tween.tween_method(move,2.6,-4.9,.048).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_method(move,-4.9,0.0,.0816).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func select(index: int, shake: bool=true):
	if items.is_empty(): return
	selected=posmod(index,items.size())
	for i in items.size():
		items[i].fire.emitting=i==selected and not is_locked(items[i].label)
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
	if is_locked(items[selected].label):
		quake()
		sound_requested.emit("resist")
		return
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

# Reuse the same baked letters, hit targets and contour fire in screen footers.
func layout_actions(rect: Rect2,vertical: bool=false):
	if items.is_empty():return
	for item in items:
		if not item.has("action_width"):
			item.action_width=item.width
			item.action_height=item.height
		var emphasis=1.0/float(action_emphasis.get(item.label,1.0)) if vertical else 1.0
		item.node.scale=Vector2.ONE*emphasis
		item.width=item.action_width*emphasis
		item.height=item.action_height*emphasis
	var widest=0.0
	var tallest=0.0
	var total=0.0
	for item in items:
		widest=maxf(widest,item.width)
		tallest=maxf(tallest,item.height)
		total+=item.width
	var centered=not vertical and items.size()==3 and items[1].label==centered_action
	var required=items[1].width+2*(maxf(items[0].width,items[2].width)+80) if centered else total+80*(items.size()-1)
	var factor=minf(60.0/tallest,minf(rect.size.x/widest,rect.size.y/(items.size()*(tallest+18)))) if vertical else minf(action_height/tallest,minf(rect.size.x/required,rect.size.y/tallest))
	scale=Vector2.ONE*factor
	position=rect.position
	var cursor=(rect.size.x/factor-total-80*(items.size()-1))*.5
	for i in items.size():
		var item=items[i]
		item.x=rect.size.x/factor*.5 if vertical else cursor+item.width*.5
		if centered:
			item.x=rect.size.x/factor*.5
			if i!=1:item.x+=(-1 if i==0 else 1)*(items[1].width*.5+80+item.width*.5)
		item.y=(rect.size.y/factor/items.size())*(i+.5)-item.height*.5 if vertical else (rect.size.y/factor-item.height)*.5
		item.node.position=Vector2(item.x,item.y+item.get("drop_offset",0.0))
		cursor+=item.width+80
