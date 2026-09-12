extends SceneTree
func _init():
	var sheet=Image.load_from_file("res://art/minotaur-source.png")
	var cels=[]
	var w=sheet.get_width()/4
	for i in 16:
		var image=sheet.get_region(Rect2i(int(i%4*w)+3,int(i/4)*w+3,w-6,w-6))
		var b=image.get_used_rect()
		var file="minotaur-%d.png"%i
		image.get_region(b).save_png("res://art/"+file)
		cels.append({"file":"../art/"+file,"left":b.position.x+3,"top":b.position.y+3,"width":b.size.x,"height":b.size.y})
	FileAccess.open("res://art/minotaur-atlas.json",FileAccess.WRITE).store_string(JSON.stringify({"cellWidth":w,"cellHeight":w,"facing":1,"cels":cels}))
	sheet=Image.load_from_file("res://art/archer-death-source.png")
	var atlas=JSON.parse_string(FileAccess.get_file_as_string("res://art/archer-atlas.json"))
	atlas.cels.resize(9)
	var edges=[0,320,700,1110,1536]
	for i in 4:
		var image=sheet.get_region(Rect2i(edges[i],512,edges[i+1]-edges[i],512))
		image.convert(Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				var c=image.get_pixel(x,y)
				var magenta=minf(c.r,c.b)-c.g
				if magenta>.16:
					c.a*=1-smoothstep(.16,.55,magenta)
					c.r=minf(c.r,c.g+.16)
					c.b=minf(c.b,c.g+.16)
				image.set_pixel(x,y,c)
		var b=image.get_used_rect()
		var cropped=image.get_region(b)
		cropped.resize(roundi(b.size.x*1.12),roundi(b.size.y*1.12),Image.INTERPOLATE_LANCZOS)
		var file="archer-death-%d.png"%i
		cropped.save_png("res://art/"+file)
		atlas.cels.append({"file":"../art/"+file,"left":192-cropped.get_width()/2,"top":0,"width":cropped.get_width(),"height":cropped.get_height()})
	FileAccess.open("res://art/archer-atlas.json",FileAccess.WRITE).store_string(JSON.stringify(atlas))
	quit()
