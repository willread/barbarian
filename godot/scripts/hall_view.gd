extends CanvasLayer
signal closed
signal begin
var art: CairnArt
var runs: Array=[]
var current_id=""
var selected=0
var headers: Array=[]
var sort_key="score"
var descending=true
const COLUMNS=[["rank","RANK",.0,.08],["score","SCORE",.08,.20],["reached","REACHED",.28,.28],["difficulty","DIFFICULTY",.56,.16],["time","TIME",.72,.12],["date","DATE",.84,.16]]
var scroll: ScrollContainer
var content: Control
var backdrop: Node2D
var actions: Node2D
var viewport_size=Vector2.ZERO
var compact=false
var row_height=58.0
var text_size=24
var font=preload("res://art/controls/cinzel.ttf")
var title_texture=preload("res://art/controls/hall-of-legends.png")
var title_lines=[preload("res://art/controls/hall-of.png"),preload("res://art/controls/legends.png")]
var ink=Color("e4ddc9")
var gold=Color("bdaa7d")

func _ready():
	layer=2200
	font.multichannel_signed_distance_field=false
	font.oversampling=2.0
	backdrop=Node2D.new()
	add_child(backdrop)
	backdrop.draw.connect(draw_backdrop)
	scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	content=Control.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scroll.add_child(content)
	content.draw.connect(draw_table)
	content.resized.connect(func():content.queue_redraw())
	actions=load("res://scripts/menu.gd").new()
	add_child(actions)
	actions.setup(art)
	actions.action_height=96.0
	actions.show_items(["BEGIN","BACK"] if runs.is_empty() else ["BACK"],false,false)
	actions.activated.connect(func(label):
		if label=="BEGIN":begin.emit()
		else:closed.emit())
	actions.sound_requested.connect(func(id):get_parent().audio.play(id,-8))
	for i in runs.size():
		runs[i]["table_rank"]=i+1
		if runs[i].get("id")==current_id:selected=i
	for column in COLUMNS:
		var button=Button.new()
		button.flat=true
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_override("font",font)
		button.add_theme_color_override("font_color",gold)
		button.pressed.connect(func():sort_by(column[0]))
		button.draw.connect(func():draw_sort_indicator(button,column[0]))
		add_child(button)
		headers.append(button)
	update_headers()
	get_viewport().size_changed.connect(layout)
	layout()
	actions.drop_actions()
	reveal_selected.call_deferred()

func layout():
	var pixels=get_viewport().get_visible_rect().size
	var width=minf(1920,pixels.x)
	viewport_size=Vector2(width,pixels.y*width/maxf(1,pixels.x))
	transform=Transform2D(0,Vector2.ZERO).scaled(Vector2.ONE*(get_viewport().get_visible_rect().size.x/width))
	compact=width<760
	text_size=clampi(int(width/52),20,30)
	var top=158.0 if compact else clampf(viewport_size.y*.20,120,205)
	var table_width=width-40 if compact else width*.90
	scroll.position=Vector2((width-table_width)*.5,top)
	scroll.size=Vector2(table_width,maxf(60,viewport_size.y-top-158))
	row_height=110 if compact else clampf(scroll.size.y/maxi(1,runs.size()),44,86)
	content.custom_minimum_size=Vector2(0,scroll.size.y if runs.is_empty() else runs.size()*row_height)
	# Match the title menu's 1.0 lettering size (these items are created at .71).
	var factor=minf(1.0/.71,width*.8/maxf(1,actions.items[0].width))
	if runs.is_empty():
		actions.layout_actions(Rect2(width*.1,viewport_size.y-140,width*.8,128))
	else:
		var item=actions.items[0]
		actions.scale=Vector2.ONE*factor
		actions.position=Vector2(width*.5,viewport_size.y-78)-Vector2(item.x,item.y+item.height*.5)*factor
	for i in headers.size():
		var column=COLUMNS[i]
		headers[i].visible=not runs.is_empty()
		headers[i].position=Vector2(scroll.position.x+table_width*column[2]+8,top-36)
		headers[i].size=Vector2(table_width*column[3]-8,32)
		headers[i].add_theme_font_size_override("font_size",10 if compact else 16)
	backdrop.queue_redraw()
	content.queue_redraw()
	reveal_selected.call_deferred()

func text(node: CanvasItem,value: String,at: Vector2,size: int,color: Color,center=false,max_width=10000.0):
	while size>1 and font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>max_width:size-=1
	if center:at.x-=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5
	node.draw_string(font,at+Vector2(0,size*.34),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func draw_backdrop():
	backdrop.draw_rect(Rect2(Vector2.ZERO,viewport_size),Color(0,0,0,.9))
	# Same stone Cinzel title treatment as the controls view.
	var factor=minf(44.0/title_texture.get_height(),viewport_size.x*.86/title_texture.get_width())
	var size=title_texture.get_size()*factor
	if compact:
		for i in title_lines.size():
			var line_texture=title_lines[i]
			var line_size=line_texture.get_size()*minf(38./line_texture.get_height(),viewport_size.x*.8/line_texture.get_width())
			backdrop.draw_texture_rect(line_texture,Rect2(Vector2(viewport_size.x*.5,37+i*42)-line_size*.5,line_size),false,Color(1.3,1.3,1.3))
	else:
		backdrop.draw_texture_rect(title_texture,Rect2(Vector2(viewport_size.x*.5,scroll.position.y*.40)-size*.5,size),false,Color(1.3,1.3,1.3))

func display_date(value: String) -> String:
	var parts=value.left(10).split("-")
	if parts.size()!=3:return value
	var month=int(parts[1])
	if month<1 or month>12:return value
	return "%d %s %s"%[int(parts[2]),["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][month-1],parts[0]]

func draw_table():
	var w=content.size.x
	if w<=0:return
	if runs.is_empty():
		text(content,"No scores yet.",Vector2(w*.5,content.size.y*.4),26,ink,true)
		var size=16 if compact else 20
		text(content,"Finish your first run",Vector2(w*.5,content.size.y*.4+40),size,ink,true)
		text(content,"to set a score.",Vector2(w*.5,content.size.y*.4+66),size,ink,true)
		return
	for i in runs.size():
		var run=runs[i]
		var y=i*row_height
		if run.get("id")==current_id:
			content.draw_rect(Rect2(0,y,w,row_height),Color(.7,.48,.15,.12))

		elif i%2==0:content.draw_rect(Rect2(0,y,w,row_height),Color(.7,.65,.48,.025))
		content.draw_line(Vector2(0,y),Vector2(w,y),Color(.40,.34,.24,.45))
		var reached="EP %d - BEAT"%run.get("episode",1) if run.get("outcome","")=="won" else "EP %d · AREA %d/4"%[run.get("episode",1),run.get("area",1)]
		var time=CairnRunRecords.duration(run.get("time",0))
		var date=display_date(str(run.get("date","")))
		if compact:
			text(content,str(run.table_rank),Vector2(18,y+22),22,ink)
			var score=CairnRunRecords.number(run.score)
			var score_size=24
			while score_size>1 and font.get_string_size(score,HORIZONTAL_ALIGNMENT_LEFT,-1,score_size).x>w-90:score_size-=1
			text(content,score,Vector2(w-18-font.get_string_size(score,HORIZONTAL_ALIGNMENT_LEFT,-1,score_size).x,y+22),score_size,ink)
			text(content,reached+" / "+str(run.get("difficulty","normal")).capitalize(),Vector2(18,y+55),18,ink,false,w-36)
			text(content,time+" · "+date,Vector2(18,y+81),16,ink,false,w-36)
		else:
			var values=[str(run.table_rank),CairnRunRecords.number(run.score),reached,str(run.get("difficulty","normal")).capitalize(),time,date]
			for j in values.size():text(content,values[j],Vector2(w*COLUMNS[j][2]+8,y+row_height*.5),text_size,ink,false,w*COLUMNS[j][3]-16)
	content.draw_line(Vector2(0,runs.size()*row_height),Vector2(w,runs.size()*row_height),gold)

func reveal_selected():
	if runs.is_empty():return
	var top=selected*row_height
	if top<scroll.scroll_vertical:scroll.scroll_vertical=int(top)
	elif top+row_height>scroll.scroll_vertical+scroll.size.y:scroll.scroll_vertical=int(top+row_height-scroll.size.y)

func sort_value(run: Dictionary,key: String):
	match key:
		"rank":return run.table_rank
		"reached":return int(run.get("episode",1))*100+int(run.get("area",1))*2+int(run.get("outcome","")=="won")
		"difficulty":return ["easy","normal","hard"].find(run.get("difficulty","normal"))
		"date":return str(run.get("date",""))
	return float(run.get(key,0))
func sort_by(key: String):
	if sort_key==key:descending=not descending
	else:
		sort_key=key
		descending=key not in ["rank","time"]
	runs.sort_custom(func(a,b):
		var av=sort_value(a,key)
		var bv=sort_value(b,key)
		if av==bv:return a.table_rank<b.table_rank
		return av>bv if descending else av<bv)
	scroll.scroll_vertical=0
	content.queue_redraw()
	update_headers()
func update_headers():
	for i in headers.size():
		var column=COLUMNS[i]
		headers[i].text=column[1]
		headers[i].queue_redraw()
func draw_sort_indicator(button: Button,key: String):
	if key!=sort_key:return
	var size=button.get_theme_font_size("font_size")
	var x=font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x+12
	var center=Vector2(x,button.size.y*.5)
	var flip=-1.0 if descending else 1.0
	button.draw_polyline(PackedVector2Array([center+Vector2(-4,2.5*flip),center+Vector2(0,-2.5*flip),center+Vector2(4,2.5*flip)]),gold,1.5,true)

func handle(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE:closed.emit();return
		if not runs.is_empty():
			var focused=get_viewport().gui_get_focus_owner()
			if event.keycode==KEY_TAB:
				headers[posmod(headers.find(focused)+(-1 if event.shift_pressed else 1),headers.size())].grab_focus()
				return
			if event.keycode in [KEY_ENTER,KEY_SPACE] and focused in headers:
				focused.pressed.emit()
				return
			match event.keycode:
				KEY_UP,KEY_W:scroll.scroll_vertical-=int(row_height);return
				KEY_DOWN,KEY_S:scroll.scroll_vertical+=int(row_height);return
				KEY_PAGEUP:scroll.scroll_vertical-=int(scroll.size.y);return
				KEY_PAGEDOWN:scroll.scroll_vertical+=int(scroll.size.y);return
				KEY_HOME:scroll.scroll_vertical=0;return
				KEY_END:scroll.scroll_vertical=int(content.size.y);return
	actions.handle(event)
