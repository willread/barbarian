extends SceneTree
func _init():
	var sheet=Image.load_from_file("res://art/archer-keyed.png")
	var cels=[]
	for i in 8:
		var y=0 if i<4 else 466
		var height=466 if i<4 else sheet.get_height()-466
		var image=sheet.get_region(Rect2i((i%4)*384,y,384,height))
		image.convert(Image.FORMAT_RGBA8)
		for py in image.get_height():
			for px in image.get_width():
				var c=image.get_pixel(px,py)
				var magenta=minf(c.r,c.b)-c.g
				if magenta>.16:
					c.a*=1-smoothstep(.16,.55,magenta)
					c.r=minf(c.r,c.g+.16)
					c.b=minf(c.b,c.g+.16)
				image.set_pixel(px,py,c)
		var bounds=image.get_used_rect()
		var file="archer-%d.png"%i
		image.get_region(bounds).save_png("res://art/"+file)
		cels.append({"file":"../art/"+file,"left":bounds.position.x,"top":bounds.position.y,"width":bounds.size.x,"height":bounds.size.y})
	var reach=Image.load_from_file("res://art/archer-quiver-source.png")
	reach.convert(Image.FORMAT_RGBA8)
	for y in reach.get_height():
		for x in reach.get_width():
			var c=reach.get_pixel(x,y)
			var magenta=minf(c.r,c.b)-c.g
			if magenta>.16:
				c.a*=1-smoothstep(.16,.55,magenta)
				c.r=minf(c.r,c.g+.16)
				c.b=minf(c.b,c.g+.16)
			reach.set_pixel(x,y,c)
	var bounds=reach.get_used_rect()
	var factor=440.0/1123.0 # Skull-to-sole registration; raised hand can extend above skull.
	var cropped=reach.get_region(bounds)
	cropped.resize(roundi(bounds.size.x*factor),roundi(bounds.size.y*factor),Image.INTERPOLATE_LANCZOS)
	cropped.save_png("res://art/archer-8.png")
	cels.append({"file":"../art/archer-8.png","left":roundi((bounds.position.x-540)*factor+192),"top":0,"width":cropped.get_width(),"height":cropped.get_height()})
	var output=FileAccess.open("res://art/archer-atlas.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"cellWidth":384,"cellHeight":558,"facing":1,"cels":cels}))
	quit()
