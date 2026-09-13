extends Node2D
var area=1
var foreground=false
var clock=0.0

func chain(origin: Vector2,length: int,lean: float):
	for i in length:
		var p=origin+Vector2(lean*i+sin(clock*TAU/8+i*.12)*i*.12,i*16)
		draw_set_transform(p,lean*.04,Vector2(.65 if i%2 else 1,1))
		draw_arc(Vector2.ZERO,11,0,TAU,16,Color("080a0b"),8,true)
		draw_arc(Vector2(-1,-1),9,.5,3.8,12,Color("34312d"),2,true)
	draw_set_transform(Vector2.ZERO)

func _draw():
	if foreground:
		match area:
			1:
				chain(Vector2(1380,105),14,2.4)
				for i in 5:
					var p=Vector2(0,800-i*10)
					draw_line(p,Vector2(115+i*13,790-i*18),Color("101215"),13-i*2,true)
			2:
				chain(Vector2(30,90),25,.45)
				draw_colored_polygon(PackedVector2Array([Vector2(1390,810),Vector2(1440,810),Vector2(1440,300),Vector2(1410,300)]),Color("111315"))
				for i in 8:draw_circle(Vector2(1420,360+i*52),5,Color("393732"))
			3:
				draw_arc(Vector2(-60,820),170,0,TAU,48,Color("0c1012"),24,true)
				for i in 8:
					var a=i*TAU/8+clock*TAU/24
					draw_line(Vector2(-60,820),Vector2(-60,820)+Vector2(cos(a),sin(a))*165,Color("15191b"),9,true)
				chain(Vector2(1420,60),22,-.65)
			4:
				chain(Vector2(-12,650),13,4.8)
				chain(Vector2(1440,650),13,-4.8)
		return
	# All environmental particles stay behind the combat lane. Periods divide 24s.
	if area==1:
		for i in 90:
			var t=fposmod(clock/12+float(i)/90,1)
			var x=fposmod(i*133.7+t*95,1440)
			draw_circle(Vector2(x,60+t*490),.8+i%3*.35,Color(.7,.7,.68,sin(t*PI)*.45))
	elif area==2:
		for side in [0,1]:
			for i in 28:
				var t=fposmod(clock/6+i/28.0+side*.5,1)
				var p=Vector2(475 if side==0 else 1010,330)+Vector2((-1 if side==0 else 1)*t*105+sin(i*9.)*t*25,-t*65)
				draw_circle(p,5+t*17,Color(.48,.47,.43,pow(sin(t*PI),2)*.022))
	elif area==3:
		for i in 45:
			var t=fposmod(clock/3+i/45.0,1)
			var p=Vector2(580+sin(i*3.4)*t*20,220+t*225)
			draw_line(p,p+Vector2(2,7),Color(1,.5,.1,sin(t*PI)*.6),1.3,true)
	else:
		var pulse=(1-cos(clock*TAU/8))*.5
		for i in 35:
			var t=fposmod(clock/8+i/35.0,1)
			var p=Vector2(720+sin(i*6.3)*145,520-t*220)
			draw_circle(p,1.2,Color(1,.49,.16,sin(t*PI)*pulse*.6))
