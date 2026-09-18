extends SceneTree
var frame=0
func _init():
	root.size=Vector2i(630,500)
	call_deferred("setup")
func setup():
	seed(730)
	var fuel=Image.create(420,100,false,Image.FORMAT_RGBA8)
	for x in 420:
		var edge=75 # Keep the fuel boundary entirely below the crop; turbulence shapes the flames.
		for y in range(edge,100):fuel.set_pixel(x,y,Color.WHITE)
	var fire=load("res://scripts/contour_fire.gd").new()
	root.add_child(fire)
	fire.position=Vector2(0,185)
	fire.scale=Vector2(1.5,4.5) # Triple the visible flame height, anchored at the bottom edge.
	fire.strength=1.1
	fire.interior=.15
	fire.clock=73.0
	fire.setup(ImageTexture.create_from_image(fuel),Vector2(420,100))
func _process(_dt):
	frame+=1
	if frame>300:quit()
	return false

