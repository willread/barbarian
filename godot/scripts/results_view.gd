extends CanvasLayer
signal activated(label: String)
var art: CairnArt
var result: Dictionary={}
var save_failed=false
var age=0.0
var backdrop: Node2D
var shade: Node2D
var scroll: ScrollContainer
var content: Control
var actions: Node2D
var viewport_size=Vector2.ZERO
var compact=false
var panel_height=360.0
var heading_y=50.0
var heading_height=40.0
var lettering=preload("res://scripts/results_art.gd").new()
var slate=preload("res://art/results/slate-fine.png")
var font=preload("res://art/controls/cinzel.ttf")
var caption_font=FontVariation.new()
var ink=Color("e7d5b0")
var gold=Color("bda06d")
const STATS=[["kills","ENEMIES SLAIN"],["time","TIME SURVIVED"],["best_combo","BEST COMBO"],["peak_multiplier","PEAK MULTIPLIER"],["damage_dealt","DAMAGE DEALT"],["damage_taken","DAMAGE TAKEN"]]

func _ready():
	layer=2150
	font.multichannel_signed_distance_field=false
	font.oversampling=2.0
	caption_font.base_font=font
	caption_font.variation_embolden=.7
	shade=Node2D.new()
	add_child(shade)
	shade.draw.connect(draw_shade)
	backdrop=Node2D.new()
	add_child(backdrop)
	backdrop.draw.connect(draw_heading)
	scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	content=Control.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scroll.add_child(content)
	content.draw.connect(draw_panel)
	content.resized.connect(func():content.queue_redraw())
	actions=load("res://scripts/menu.gd").new()
	add_child(actions)
	actions.setup(art)
	actions.yellow_flames=true
	actions.compact_pause=true
	actions.show_items(["RISE AGAIN","HALL OF LEGENDS","QUIT TO TITLE"],false,false)
	actions.select(0,false)
	actions.activated.connect(func(label):activated.emit(label))
	actions.sound_requested.connect(func(id):get_parent().audio.play(id,-8))
	get_viewport().size_changed.connect(layout)
	layout()
	actions.drop_actions()

func layout():
	viewport_size=Vector2(1440,810)
	var available=get_viewport().get_visible_rect().size
	var fit=minf(available.x/viewport_size.x,available.y/viewport_size.y)
	transform=Transform2D(0,Vector2.ONE*fit,0,(available-viewport_size*fit)*.5)
	compact=false
	heading_y=58
	heading_height=56
	var top=96.0 if result.get("outcome")=="won" else 28.0
	scroll.position=Vector2(144,top)
	scroll.size=Vector2(1152,498-top)
	panel_height=scroll.size.y
	content.custom_minimum_size=Vector2(0,panel_height)
	actions.layout_standard_stack(Rect2(270,516,900,270))
	shade.queue_redraw()
	backdrop.queue_redraw()
	content.queue_redraw()

func label(node: CanvasItem,value: String,center: Vector2,size: int,color: Color=ink,max_width: float=10000):
	var actual=size
	while actual>12 and caption_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual).x>max_width:actual-=1
	node.draw_string(caption_font,center-Vector2(caption_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual).x*.5,-actual*.34),value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual,color)

func draw_heading():
	if result.get("outcome")!="won":return
	var title="THE VALLEY IS FREE."
	lettering.label(backdrop,title,Vector2(viewport_size.x*.5,heading_y),heading_height,viewport_size.x*.78,Color(1.95,2.05,2.15))

func draw_shade():
	var inverse=transform.affine_inverse()
	var full=Rect2(inverse*Vector2.ZERO,get_viewport().get_visible_rect().size/transform.get_scale())
	shade.draw_rect(full,Color(0,0,0,.42))
	var bottom=Rect2(full.position.x,482,full.size.x,maxf(0,full.end.y-482))
	shade.draw_polygon(PackedVector2Array([bottom.position,Vector2(bottom.end.x,bottom.position.y),bottom.end,Vector2(bottom.position.x,bottom.end.y)]),PackedColorArray([Color(0,0,0,0),Color(0,0,0,0),Color(0,0,0,.65),Color(0,0,0,.65)]))

func rule(a: Vector2,b: Vector2,bright=false):
	content.draw_line(a+Vector2(0,1),b+Vector2(0,1),Color(.05,.02,.005,.9),2)
	content.draw_line(a,b,Color("bf9758") if bright else Color("927341"),1)
	content.draw_circle(a,1.5,Color("e0b978"))
	content.draw_circle(b,1.5,Color("e0b978"))

func record_label(key: String,at: Vector2,large=false):
	if key not in result.get("new_stats",[]) or age<.9:return
	var width=130.0 if large else 82.0
	# Wide reflected light and a tighter bloom following the stone letter shapes.
	for i in range(12,0,-1):
		var alpha=(.028 if large else .020)*(1.+.4*exp(-(age-.9)*5.))
		content.draw_set_transform(at,0,Vector2(1,.28))
		content.draw_circle(Vector2.ZERO,width*i/12,Color(1,.22,.005,alpha))
	content.draw_set_transform(Vector2.ZERO)
	lettering.glow(content,at,20 if large else 12,.9)
	lettering.label(content,"NEW",at,20 if large else 12,100,Color(2.6,1.9,.8))

func draw_panel():
	var w=content.size.x
	if w<=0:return
	var rect=Rect2(3,3,w-6,panel_height-12)
	var source_size=rect.size*minf(slate.get_width()/rect.size.x,slate.get_height()/rect.size.y)
	content.draw_texture_rect_region(slate,rect,Rect2((slate.get_size()-source_size)*.5,source_size),Color(.70,.70,.70))
	# One narrow bevelled bronze edge, not nested frames.
	content.draw_line(rect.position,Vector2(rect.end.x,rect.position.y),Color("eed49a"),3)
	content.draw_line(rect.position,Vector2(rect.position.x,rect.end.y),Color("bc8a45"),3)
	content.draw_line(Vector2(rect.position.x,rect.end.y),rect.end,Color("a47235"),3)
	content.draw_line(Vector2(rect.end.x,rect.position.y),rect.end,Color("775025"),3)
	var score_h=270.0 if compact else rect.size.y
	var score_w=w if compact else w*.50
	var cx=score_w*.5
	lettering.label(content,"FINAL SCORE",Vector2(cx,32),19 if compact else 22,score_w*.8,Color(1.7,1.6,1.35))
	rule(Vector2(30,53),Vector2(score_w-30,53))
	lettering.label(content,"AREA %d/4"%result.get("area",1),Vector2(cx,71),12 if compact else 14,score_w*.8)
	var t=1.-pow(1.-clampf(age/.9,0,1),3)
	var score_size=82.0 if compact else score_h*.32
	var score_center=(85.0+score_h*.9)*.5
	lettering.number(content,CairnRunRecords.number(float(result.get("score",0))*t),"score",Vector2(cx,score_center),score_size,score_w*.87)
	record_label("score",Vector2(cx,score_center+score_size*.5+18),true)
	var best=int(result.get("previous_best",0))
	var score=int(result.get("score",0))
	var baseline=score if result.get("first",true) else best
	var delta=score-baseline
	var comparison="Personal best %s (%s%s)"%[CairnRunRecords.number(baseline),"+" if delta>=0 else "-",CairnRunRecords.number(absi(delta))]
	label(content,comparison,Vector2(cx,score_h*.9),18,ink,score_w*.93)
	var rank=int(result.get("rank",0))
	var detail="Outside your top 10" if rank==0 else ""
	if save_failed:detail="Could not save this run on this device"
	label(content,detail,Vector2(cx,score_h*.97),13,gold,score_w*.93)
	var left=0.0 if compact else score_w
	var top=score_h if compact else 0.0
	var sw=w-left
	if compact:rule(Vector2(20,top),Vector2(w-20,top))
	else:rule(Vector2(left,20),Vector2(left,rect.end.y-20))
	lettering.label(content,"STATS",Vector2(left+sw*.5,top+32),19 if compact else 22,sw*.8,Color(1.7,1.6,1.35))
	rule(Vector2(left+20,top+53),Vector2(w-20,top+53))
	var row=(rect.end.y-top-62)/3
	rule(Vector2(left+sw*.5,top+62),Vector2(left+sw*.5,rect.end.y-15))
	for i in STATS.size():
		var col=i%2
		var y=top+60+int(i/2)*row
		var x=left+sw*(.25+.5*col)
		var key=STATS[i][0]
		var title="RUN TIME" if key=="time" and result.get("outcome")=="won" else STATS[i][1]
		lettering.label(content,title,Vector2(x,y+11),12 if compact else 14,sw*.43,Color(1.6,1.65,1.7))
		var value=CairnRunRecords.duration(result.get(key,0)) if key=="time" else CairnRunRecords.number(result.get(key,0))
		if key=="best_combo":value+=" HITS"
		if key=="peak_multiplier":value+="×"
		lettering.number(content,value,"stat",Vector2(x,y+row*.50),36 if compact else minf(46,row*.47),sw*.41)
		record_label(key,Vector2(x,y+row*.83))
		if i<4:rule(Vector2(left+sw*.5*col+20,y+row),Vector2(left+sw*.5*(col+1)-20,y+row))

func _process(dt: float):
	if not visible:return
	age+=dt
	var reveal=smoothstep(0,.3,age)
	shade.modulate.a=smoothstep(0,.8,age)
	backdrop.modulate.a=reveal
	backdrop.position.y=(1.-reveal)*8
	content.modulate.a=reveal
	content.position.y=(1.-reveal)*6
	if age<2.5:content.queue_redraw()

func handle(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE:activated.emit("QUIT TO TITLE");return
		if event.keycode in [KEY_PAGEUP,KEY_PAGEDOWN]:scroll.scroll_vertical+=-180 if event.keycode==KEY_PAGEUP else 180;return
		if event.keycode in [KEY_LEFT,KEY_RIGHT]:actions.select(actions.selected+(-1 if event.keycode==KEY_LEFT else 1));return
	actions.handle(event)
