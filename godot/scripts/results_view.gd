extends CanvasLayer
signal activated(label: String)
var art: CairnArt
var result: Dictionary={}
var save_failed=false
var age=0.0
var backdrop: Node2D
var scroll: ScrollContainer
var content: Control
var actions: Node2D
var viewport_size=Vector2.ZERO
var compact=false
var panel_height=360.0
var lettering=preload("res://scripts/results_art.gd").new()
var slate=preload("res://art/results/slate.png")
var font=preload("res://art/controls/cinzel.ttf")
var ink=Color("e7d5b0")
var gold=Color("bda06d")
const STATS=[["kills","ENEMIES SLAIN"],["time","TIME SURVIVED"],["best_combo","BEST COMBO"],["peak_multiplier","PEAK MULTIPLIER"],["damage_dealt","DAMAGE DEALT"],["damage_taken","DAMAGE TAKEN"]]

func _ready():
	layer=2150
	font.multichannel_signed_distance_field=false
	font.oversampling=2.0
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
	actions.show_items(["HALL OF LEGENDS","RISE AGAIN","QUIT TO TITLE"],false,false)
	actions.select(1,false)
	actions.activated.connect(func(label):activated.emit(label))
	actions.sound_requested.connect(func(id):get_parent().audio.play(id,-8))
	get_viewport().size_changed.connect(layout)
	layout()

func layout():
	var pixels=Vector2(get_window().size)
	var width=minf(1920,pixels.x)
	viewport_size=Vector2(width,pixels.y*width/maxf(1,pixels.x))
	transform=Transform2D(0,Vector2.ZERO).scaled(Vector2.ONE*(get_viewport().get_visible_rect().size.x/width))
	compact=width<900
	var vertical=width<600
	var footer=164.0 if vertical else clampf(viewport_size.y*.22,100,190)
	var top=112.0 if compact else clampf(viewport_size.y*.265,130,270)
	var gutter=.055 if compact else .098
	scroll.position=Vector2(width*gutter,top)
	scroll.size=Vector2(width*(1.-gutter*2),maxf(60,viewport_size.y-top-footer))
	panel_height=maxf(552,scroll.size.y-8) if compact else maxf(340,viewport_size.y*.47)
	content.custom_minimum_size=Vector2(0,panel_height)
	actions.layout_actions(Rect2(width*.085,viewport_size.y-footer,width*.83,footer-42),vertical)
	backdrop.queue_redraw()
	content.queue_redraw()

func label(node: CanvasItem,value: String,center: Vector2,size: int,color: Color=ink,max_width: float=10000):
	var actual=size
	while actual>12 and font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual).x>max_width:actual-=1
	node.draw_string(font,center-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual).x*.5,-actual*.34),value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual,color)

func draw_heading():
	var title="THE VALLEY IS FREE." if result.get("outcome")=="won" else "EVEN HEROES FALL."
	var y=50.0 if compact else scroll.position.y*.52
	lettering.label(backdrop,title,Vector2(viewport_size.x*.5,y),34 if compact else clampf(viewport_size.x*.044,40,80),viewport_size.x*.78)
	label(backdrop,"CITADEL  ·  AREA %d OF 4"%result.get("area",1),Vector2(viewport_size.x*.5,88 if compact else scroll.position.y*.82),18 if compact else 21,ink)

func rule(a: Vector2,b: Vector2,bright=false):
	content.draw_line(a+Vector2(0,1),b+Vector2(0,1),Color(.05,.02,.005,.9),2)
	content.draw_line(a,b,Color("bf9758") if bright else Color("927341"),1)
	content.draw_circle(a,1.5,Color("e0b978"))
	content.draw_circle(b,1.5,Color("e0b978"))

func record_label(key: String,at: Vector2,large=false):
	if key not in result.get("new_stats",[]) or age<.9:return
	var width=130.0 if large else 82.0
	# Warm, restrained halo behind the raised amber lettering.
	for i in range(12,0,-1):
		var alpha=(.008 if large else .005)*(1.+.4*exp(-(age-.9)*5.))
		content.draw_set_transform(at,0,Vector2(1,.18))
		content.draw_circle(Vector2.ZERO,width*i/12,Color(1,.22,.005,alpha))
	content.draw_set_transform(Vector2.ZERO)
	lettering.label(content,"NEW",at,20 if large else 12,100,Color(1.2,.70,.12))

func draw_panel():
	var w=content.size.x
	if w<=0:return
	var rect=Rect2(3,3,w-6,panel_height-12)
	var source_size=rect.size*minf(slate.get_width()/rect.size.x,slate.get_height()/rect.size.y)
	content.draw_texture_rect_region(slate,rect,Rect2((slate.get_size()-source_size)*.5,source_size),Color(.65,.65,.65))
	# One narrow bevelled bronze edge, not nested frames.
	content.draw_line(rect.position,Vector2(rect.end.x,rect.position.y),Color("eed49a"),3)
	content.draw_line(rect.position,Vector2(rect.position.x,rect.end.y),Color("bc8a45"),3)
	content.draw_line(Vector2(rect.position.x,rect.end.y),rect.end,Color("a47235"),3)
	content.draw_line(Vector2(rect.end.x,rect.position.y),rect.end,Color("775025"),3)
	var score_h=240.0 if compact else rect.size.y
	var score_w=w if compact else w*.50
	var cx=score_w*.5
	lettering.label(content,"FINAL SCORE",Vector2(cx,32),17,score_w*.8)
	rule(Vector2(30,53),Vector2(score_w-30,53))
	var t=1.-pow(1.-clampf(age/.9,0,1),3)
	lettering.number(content,CairnRunRecords.number(float(result.get("score",0))*t),"score",Vector2(cx,score_h*.46),98 if compact else score_h*.35,score_w*.87)
	var new_score="score" in result.get("new_stats",[])
	if new_score and age>=.9:
		rule(Vector2(30,score_h*.78),Vector2(cx-43,score_h*.78),true)
		rule(Vector2(cx+43,score_h*.78),Vector2(score_w-30,score_h*.78),true)
	record_label("score",Vector2(cx,score_h*.78),true)
	var best=int(result.get("previous_best",0))
	var score=int(result.get("score",0))
	var comparison="First score recorded" if result.get("first",true) else "Personal best matched" if score==best else "Previous best %s · +%s"%[CairnRunRecords.number(best),CairnRunRecords.number(score-best)] if score>best else "Personal best %s"%CairnRunRecords.number(best)
	label(content,comparison,Vector2(cx,score_h*.9),18,ink,score_w*.93)
	var rank=int(result.get("rank",0))
	var detail="%s from your best"%CairnRunRecords.number(best-score) if score<best else ""
	if rank==0:detail+=" · Outside your top 10" if not detail.is_empty() else "Outside your top 10"
	elif score<best:detail+=" · #%d run"%rank
	if save_failed:detail="Could not save this run on this device"
	label(content,detail,Vector2(cx,score_h*.97),13,gold,score_w*.93)
	var left=0.0 if compact else score_w
	var top=score_h if compact else 0.0
	var sw=w-left
	if compact:rule(Vector2(20,top),Vector2(w-20,top))
	else:rule(Vector2(left,20),Vector2(left,rect.end.y-20))
	lettering.label(content,"THIS RUN",Vector2(left+sw*.5,top+32),17,sw*.8)
	rule(Vector2(left+20,top+53),Vector2(w-20,top+53))
	var row=(rect.end.y-top-62)/3
	rule(Vector2(left+sw*.5,top+62),Vector2(left+sw*.5,rect.end.y-15))
	for i in STATS.size():
		var col=i%2
		var y=top+60+int(i/2)*row
		var x=left+sw*(.25+.5*col)
		var key=STATS[i][0]
		var title="RUN TIME" if key=="time" and result.get("outcome")=="won" else STATS[i][1]
		lettering.label(content,title,Vector2(x,y+11),10 if compact else 11,sw*.43)
		var value=CairnRunRecords.duration(result.get(key,0)) if key=="time" else CairnRunRecords.number(result.get(key,0))
		if key=="best_combo":value+=" HITS"
		if key=="peak_multiplier":value+="×"
		lettering.number(content,value,"stat",Vector2(x,y+row*.50),32 if compact else minf(43,row*.43),sw*.41)
		record_label(key,Vector2(x,y+row*.83))
		if i<4:rule(Vector2(left+sw*.5*col+15,y+row),Vector2(left+sw*.5*(col+1)-15,y+row))

func _process(dt: float):
	if not visible:return
	age+=dt
	var reveal=smoothstep(0,.3,age)
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
