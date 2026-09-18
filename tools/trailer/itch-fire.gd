extends SceneTree
var frame=0
func _init():
	root.size=Vector2i(630,500)
	call_deferred("setup")
func setup():
	seed(730)
	var fuel=Image.create(210,100,false,Image.FORMAT_RGBA8)
	for x in 210:
		var edge=65+int(sin(x*.14)*5+sin(x*.043)*9)
		for y in range(edge,100):fuel.set_pixel(x,y,Color.WHITE)
	var fire=load("res://scripts/contour_fire.gd").new()
	root.add_child(fire)
	fire.position=Vector2(0,220)
	fire.scale=Vector2.ONE*3
	fire.strength=1.3
	fire.interior=.48
	fire.clock=73.0
	fire.setup(ImageTexture.create_from_image(fuel),Vector2(210,100))
func _process(_dt):
	frame+=1
	if frame>300:quit()
	return false
