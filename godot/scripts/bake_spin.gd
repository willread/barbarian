extends SceneTree
func _init():
	var sheet=Image.load_from_file("res://art/hero-spin-neutral-source.png")
	var cels=[]
	var grips=[Vector2(327,192),Vector2(325,192),Vector2(335,192),Vector2(59,192),Vector2(49,166),Vector2(45,166),Vector2(51,166),Vector2(339,166)]
	for i in 8:
		var source=[0,1,2,1,4,5,6,5][i]
		var image=sheet.get_region(Rect2i((source%4)*384,(source/4)*512,384,512))
		image.convert(Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				var c=image.get_pixel(x,y)
				var green=c.g-max(c.r,c.b)
				if green>.12:
					c.a=1.-smoothstep(.12,.4,green)
					c.g=min(c.g,max(c.r,c.b))
				image.set_pixel(x,y,c)
		if i in [3,7]:image.flip_x()
		var bounds=image.get_used_rect()
		var factor=268.0/bounds.size.y
		var file="spin-%d.png"%i
		image.get_region(bounds).save_png("res://art/"+file)
		var grip=Vector2((grips[i].x-192)*factor,(grips[i].y-bounds.end.y)*factor)
		cels.append({"file":"../art/"+file,"left":bounds.position.x,"top":bounds.position.y,"width":bounds.size.x,"height":bounds.size.y,"rig":{"scale":factor,"grip":[grip.x,grip.y],"angle":PI*.5*cos(i*TAU/8),"behind":i in [1,2,3]}})
	var output=FileAccess.open("res://art/spin-atlas.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"cellWidth":384,"cellHeight":512,"facing":1,"cels":cels}))
	quit()
