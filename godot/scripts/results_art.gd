extends RefCounted
# Baked raster glyphs keep the carved face, bevel and baseline at any score value.
var data=JSON.parse_string(FileAccess.get_file_as_string("res://art/results/lettering.json"))
var textures: Dictionary={}

func texture(file: String) -> Texture2D:
	if not textures.has(file):textures[file]=load("res://art/results/"+file)
	return textures[file]

func label(node: CanvasItem,value: String,center: Vector2,height: float,max_width: float,color=Color(1.25,1.2,1.1)):
	var meta=data.labels[value]
	var factor=minf(height/meta.cap,max_width/meta.advance)
	var origin=center-Vector2(meta.advance*.5,meta.cap*.5)*factor
	node.draw_texture_rect(texture(meta.file),Rect2(origin-Vector2(meta.pad,meta.baseline-meta.cap)*factor,Vector2(meta.width,meta.height)*factor),false,color)

func glow(node: CanvasItem,center: Vector2,height: float,intensity: float):
	var meta=data.labels["NEW"]
	var factor=height/meta.cap
	var origin=center-Vector2(meta.advance*.5,meta.cap*.5)*factor
	node.draw_texture_rect(texture("new-glow.png"),Rect2(origin-Vector2(meta.pad,meta.baseline-meta.cap)*factor,Vector2(meta.width,meta.height)*factor),false,Color(1,1,1,intensity))

func number(node: CanvasItem,value: String,kind: String,center: Vector2,height: float,max_width: float):
	var glyphs=data.glyphs[kind]
	var width=0.0
	for ch in value:width+=glyphs[ch].advance
	var cap=glyphs["0"].cap
	var factor=minf(height/cap,max_width/maxf(1,width))
	var x=center.x-width*factor*.5
	for ch in value:
		var meta=glyphs[ch]
		var at=Vector2(x-meta.pad*factor,center.y-cap*factor*.5-(meta.baseline-cap)*factor)
		node.draw_texture_rect(texture(meta.file),Rect2(at,Vector2(meta.width,meta.height)*factor),false,Color(1.8,1.75,1.65) if kind=="score" else Color(1.65,1.75,1.9))
		x+=meta.advance*factor
