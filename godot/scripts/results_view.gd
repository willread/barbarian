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
var font=preload("res://art/controls/cinzel.ttf")
var ink=Color("e7d5b0")
var gold=Color("bda06d")
const STATS=[["kills","ENEMIES SLAIN"],["time","TIME SURVIVED"],["best_combo","BEST COMBO"],["peak_multiplier","PEAK MULTIPLIER"],["damage_dealt","DAMAGE DEALT"],["damage_taken","DAMAGE TAKEN"]]

func _ready():
	layer=2150
	font.multichannel_signed_distance_field=true
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
	var footer=164.0 if vertical else 100.0
	var top=112.0 if width>=900 else 92.0
	scroll.position=Vector2(width*.055,top)
	scroll.size=Vector2(width*.89,maxf(60,viewport_size.y-top-footer))
	panel_height=maxf(552 if compact else 330,scroll.size.y-8)
	content.custom_minimum_size=Vector2(0,panel_height)
	actions.layout_actions(Rect2(width*.045,viewport_size.y-footer+12,width*.91,footer-28),vertical)
	backdrop.queue_redraw()
	content.queue_redraw()

func label(node: CanvasItem,value: String,center: Vector2,size: int,color: Color=ink,max_width: float=10000):
	var actual=size
	while actual>12 and font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual).x>max_width:actual-=1
	node.draw_string(font,center-Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual).x*.5,-actual*.34),value,HORIZONTAL_ALIGNMENT_LEFT,-1,actual,color)

func draw_heading():
	label(backdrop,"THE VALLEY IS FREE." if result.get("outcome")=="won" else "EVEN HEROES FALL.",Vector2(viewport_size.x*.5,40),48 if not compact else 30,ink,viewport_size.x*.92)
	label(backdrop,"CITADEL · AREA %d OF 4"%result.get("area",1),Vector2(viewport_size.x*.5,79 if not compact else 70),18,gold)

func record_label(key: String,at: Vector2):
	if key in result.get("new_stats",[]) and age>=.9:
		var pulse=1.+.25*exp(-(age-.9)*5.)
		label(content,"NEW",at,18,Color(1.,.63,.16)*pulse)

func draw_panel():
	var w=content.size.x
	if w<=0:return
	var reveal=smoothstep(0,.3,age)
	content.draw_set_transform(Vector2(0,(1.-reveal)*8))
	var rect=Rect2(2,2,w-4,panel_height-12)
	content.draw_texture_rect(art.texture("menu-stone-material-v1.png"),rect,false,Color(.12,.12,.12,reveal))
	content.draw_rect(rect,Color(.015,.018,.016,.45*reveal))
	content.draw_rect(rect,Color(gold,reveal),false,1)
	var score_h=230.0 if compact else rect.size.y
	var score_w=w if compact else w*.44
	var cx=score_w*.5
	label(content,"FINAL SCORE",Vector2(cx,35),22,gold)
	var t=1.-pow(1.-clampf(age/.9,0,1),3)
	label(content,CairnRunRecords.number(float(result.get("score",0))*t),Vector2(cx,score_h*.43),92 if compact else int(clampf(w*.112,70,170)),ink,score_w*.9)
	record_label("score",Vector2(cx,score_h*.70))
	var best=int(result.get("previous_best",0))
	var score=int(result.get("score",0))
	var comparison="First score recorded" if result.get("first",true) else "Personal best matched" if score==best else "Previous best %s · +%s"%[CairnRunRecords.number(best),CairnRunRecords.number(score-best)] if score>best else "Personal best %s"%CairnRunRecords.number(best)
	label(content,comparison,Vector2(cx,score_h*.82),18,ink,score_w*.93)
	var rank=int(result.get("rank",0))
	var detail="%s from your best"%CairnRunRecords.number(best-score) if score<best else ""
	if rank==0:detail+=" · Outside your top 10" if not detail.is_empty() else "Outside your top 10"
	elif score<best:detail+=" · #%d run"%rank
	if save_failed:detail="Could not save this run on this device"
	label(content,detail,Vector2(cx,score_h*.92),14,gold,score_w*.93)
	var left=0.0 if compact else score_w
	var top=score_h if compact else 0.0
	var sw=w-left
	if compact:content.draw_line(Vector2(18,top),Vector2(w-18,top),Color(gold,.5))
	else:content.draw_line(Vector2(left,22),Vector2(left,rect.end.y-22),Color(gold,.5))
	label(content,"THIS RUN",Vector2(left+sw*.5,top+32),22,gold)
	var row=(rect.end.y-top-62)/3
	for i in STATS.size():
		var col=i%2
		var y=top+60+int(i/2)*row
		var x=left+sw*(.25+.5*col)
		var key=STATS[i][0]
		var title="RUN TIME" if key=="time" and result.get("outcome")=="won" else STATS[i][1]
		label(content,title,Vector2(x,y+14),16,gold,sw*.46)
		var value=CairnRunRecords.duration(result.get(key,0)) if key=="time" else CairnRunRecords.number(result.get(key,0))
		if key=="best_combo":value+=" HITS"
		if key=="peak_multiplier":value+="×"
		label(content,value,Vector2(x,y+row*.51),36 if compact else 46,ink,sw*.44)
		record_label(key,Vector2(x,y+row*.83))
		if i<4:content.draw_line(Vector2(left+sw*.5*col+12,y+row),Vector2(left+sw*.5*(col+1)-12,y+row),Color(gold,.3))
	content.draw_set_transform(Vector2.ZERO)

func _process(dt: float):
	if not visible:return
	age+=dt
	var reveal=smoothstep(0,.3,age)
	backdrop.modulate.a=reveal
	backdrop.position.y=(1.-reveal)*8
	content.modulate.a=reveal
	if age<2.5:content.queue_redraw()

func handle(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE:activated.emit("QUIT TO TITLE");return
		if event.keycode in [KEY_PAGEUP,KEY_PAGEDOWN]:scroll.scroll_vertical+=-180 if event.keycode==KEY_PAGEUP else 180;return
		if event.keycode in [KEY_LEFT,KEY_RIGHT]:actions.select(actions.selected+(-1 if event.keycode==KEY_LEFT else 1));return
	actions.handle(event)
