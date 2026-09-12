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
	var output=FileAccess.open("res://art/archer-atlas.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"cellWidth":384,"cellHeight":558,"facing":1,"cels":cels}))
	quit()
