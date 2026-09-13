extends CanvasLayer
signal closed
signal begin
var art: CairnArt
var runs: Array=[]
var current_id=""
var selected=0
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
	content.mouse_filter=Control.MOUSE_FILTER_PASS
	scroll.add_child(content)
	content.draw.connect(draw_table)
	content.gui_input.connect(row_input)
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
		if runs[i].get("id")==current_id:selected=i
	get_viewport().size_changed.connect(layout)
	layout()
	actions.drop_actions()
	reveal_selected.call_deferred()

func layout():
	var pixels=Vector2(get_window().size)
	var width=minf(1920,pixels.x)
	viewport_size=Vector2(width,pixels.y*width/maxf(1,pixels.x))
	transform=Transform2D(0,Vector2.ZERO).scaled(Vector2.ONE*(get_viewport().get_visible_rect().size.x/width))
	compact=width<760
	text_size=clampi(int(width/52),20,30)
	var top=122.0 if compact else clampf(viewport_size.y*.20,120,205)
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
	if not compact and not runs.is_empty():
		var w=scroll.size.x
		for col in [["RANK",.018],["SCORE",.17],["REACHED",.36],["TIME",.68],["DATE",.84]]:
			text(backdrop,col[0],Vector2(scroll.position.x+w*col[1],scroll.position.y-23),18,gold)

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
		if i==selected:
			content.draw_rect(Rect2(0,y,w,row_height),Color(.7,.48,.15,.12))
			if not compact:
				var marker=Vector2(w*.016,y+row_height*.5)
				content.draw_colored_polygon(PackedVector2Array([marker+Vector2(-3,-7),marker+Vector2(5,0),marker+Vector2(-3,7)]),Color("eab95d"))
		elif i%2==0:content.draw_rect(Rect2(0,y,w,row_height),Color(.7,.65,.48,.025))
		content.draw_line(Vector2(0,y),Vector2(w,y),Color(.40,.34,.24,.45))
		var reached="EP %d · AREA %d/4"%[run.get("episode",1),run.get("area",1)]
		var time=CairnRunRecords.duration(run.get("time",0))
		var date=display_date(str(run.get("date","")))
		if compact:
			text(content,str(i+1),Vector2(18,y+22),22,ink)
			var score=CairnRunRecords.number(run.score)
			var score_size=24
			while score_size>1 and font.get_string_size(score,HORIZONTAL_ALIGNMENT_LEFT,-1,score_size).x>w-90:score_size-=1
			text(content,score,Vector2(w-18-font.get_string_size(score,HORIZONTAL_ALIGNMENT_LEFT,-1,score_size).x,y+22),score_size,ink)
			text(content,reached,Vector2(18,y+55),18,ink,false,w-36)
			text(content,time+" · "+date,Vector2(18,y+81),16,ink,false,w-36)
		else:
			var values=[str(i+1),CairnRunRecords.number(run.score),reached,time,date]
			for j in values.size():text(content,values[j],Vector2(w*[.048,.17,.36,.68,.84][j],y+row_height*.5),text_size,ink,false,w*[.122,.19,.32,.16,.16][j]-16)
	content.draw_line(Vector2(0,runs.size()*row_height),Vector2(w,runs.size()*row_height),gold)

func reveal_selected():
	if runs.is_empty():return
	var top=selected*row_height
	if top<scroll.scroll_vertical:scroll.scroll_vertical=int(top)
	elif top+row_height>scroll.scroll_vertical+scroll.size.y:scroll.scroll_vertical=int(top+row_height-scroll.size.y)

func row_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and not runs.is_empty():
		selected=clampi(int(event.position.y/row_height),0,runs.size()-1)
		content.queue_redraw()

func handle(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE:closed.emit();return
		if not runs.is_empty():
			var step=0
			if event.keycode in [KEY_UP,KEY_W]:step=-1
			if event.keycode in [KEY_DOWN,KEY_S]:step=1
			if event.keycode==KEY_PAGEUP:step=-maxi(1,int(scroll.size.y/row_height))
			if event.keycode==KEY_PAGEDOWN:step=maxi(1,int(scroll.size.y/row_height))
			if event.keycode==KEY_HOME:step=-runs.size()
			if event.keycode==KEY_END:step=runs.size()
			if step!=0:
				selected=clampi(selected+step,0,runs.size()-1)
				reveal_selected()
				content.queue_redraw()
				return
	actions.handle(event)
