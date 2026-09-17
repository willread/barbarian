extends Node2D
# Source positions are registered to the four 1440 x 810 paintings.
var area=1
var foreground=false
var clock=0.0
var smoke_texture: GradientTexture2D

func _ready():
	var gradient=Gradient.new()
	gradient.set_color(0,Color(1,1,1,.23))
	gradient.add_point(.35,Color(1,1,1,.13))
	gradient.set_color(gradient.get_point_count()-1,Color(1,1,1,0))
	smoke_texture=GradientTexture2D.new()
	smoke_texture.gradient=gradient
	smoke_texture.width=64
	smoke_texture.height=64
	smoke_texture.fill=GradientTexture2D.FILL_RADIAL
	smoke_texture.fill_from=Vector2(.5,.5)
	smoke_texture.fill_to=Vector2(1,.5)

func exhaust(origin: Vector2,spread: float,rise: float,seed_value: float,tint: Color):
	if not smoke_texture:return
	for i in 18:
		var age=fposmod(clock/(7.3+seed_value*.13)+i/18.0,1.0)
		var drift=sin(age*5.0+seed_value+clock*.17)*spread*age
		var p=origin+Vector2(drift+age*spread*.45,-age*rise)
		var size=Vector2(28+age*spread,18+age*spread*.65)
		var color=tint
		color.a*=pow(sin(age*PI),1.5)
		draw_texture_rect(smoke_texture,Rect2(p-size,size*2),false,color)

func embers(origin: Vector2,count: int,spread: float,rise: float,seed_value: float):
	for i in count:
		var age=fposmod(clock/(2.7+fmod(i*.37,2.1))+i/float(count),1.0)
		var p=origin+Vector2(sin(i*17.3+seed_value)*spread*age+sin(age*7+i)*9,-rise*age)
		var alpha=pow(sin(age*PI),2)*(.23+.17*sin(i*9.1+clock*3))
		draw_line(p,p+Vector2(-1,2+i%3),Color(1,.44+.1*sin(i),.10,alpha),.7+(i%3)*.25,true)

func sanctuary_sparks(origin: Vector2,seed_value: float):
	for i in 34:
		var period=5.7+seed_value*.13
		var age=fposmod(clock+i*.047+seed_value,period)
		if age>2.2:continue
		var t=age/2.2
		var spread=sin(i*37.1+seed_value)
		var p=origin+Vector2(spread*(24+34*t)*t,-(130+45*sin(i*13.7))*t+30*t*t)
		var alpha=sin(t*PI)*(.55+.3*sin(i*7.))
		draw_line(p,p+Vector2(-spread*1.5,3.5),Color(1,.43+.2*(1-t),.09,alpha),1.1,true)

func ash(count: int,front: bool):
	for i in count:
		var age=fposmod(clock/(13.1+i%7)+i/float(count),1.0)
		var x=fposmod(i*137.71+clock*(8.0 if area==1 else 2.3)+sin(age*7+i)*20,1500)-30
		var y=age*(850 if front else 555)-20
		var alpha=sin(age*PI)*(.15 if front else .25)
		var p=Vector2(x,y)
		var r=(1.1 if front else .55)+i%3*.23
		draw_line(p,p+Vector2(r*cos(clock+i),r*1.4),Color(.66,.62,.56,alpha),r,true)

func _draw():
	if foreground:
		ash(16 if area==1 else 9,true)
		# Sparse soft cinders skirt the corners; no solid objects cover fighters.
		if area>1:
			embers(Vector2(18,825),7,65,155,area)
			embers(Vector2(1412,830),6,52,130,area+3)
		return
	ash(72 if area==1 else 26,false)
	match area:
		1:
			exhaust(Vector2(1010,239),62,210,1,Color(.25,.24,.23,.6))
			exhaust(Vector2(1140,178),48,155,5,Color(.23,.22,.21,.55))
			exhaust(Vector2(795,300),38,145,8,Color(.30,.28,.26,.3))
			embers(Vector2(1123,201),12,28,76,2)
		2:
			# The two angled ducts have their own continuous turbulent exhaust shader.
			exhaust(Vector2(705,520),100,225,4,Color(.35,.30,.25,.38))
			embers(Vector2(727,520),30,85,235,4)
			embers(Vector2(253,387),14,38,113,8)
			embers(Vector2(1217,442),14,32,135,2)
		3:
			# Short ballistic spatters strike the receiving trough beneath the pour.
			for i in 28:
				var age=fposmod(clock/(1.1+i%3*.23)+i/28.0,1)
				var p=Vector2(584,423)+Vector2(sin(i*7.13)*78*age,-90*age+132*age*age)
				draw_line(p,p+Vector2(sin(i*7.13)*2,2+age*3),Color(1,.57,.17,sin(age*PI)*.58),1,true)
			exhaust(Vector2(601,453),95,247,3,Color(.42,.35,.28,.60))
			exhaust(Vector2(919,489),73,195,8,Color(.38,.33,.28,.48))
			embers(Vector2(558,150),22,42,124,5)
			embers(Vector2(1181,467),21,64,226,3)
		4:
			# Fine iron dust drops from the seal as its outer collar finishes indexing.
			var lock_phase=fposmod(clock,14.0)
			for i in 18:
				var dust_age=(lock_phase-9.7-i*.045)/2.5
				if dust_age>0 and dust_age<1:
					var origin=Vector2(594 if i%2==0 else 846,350)
					var p=origin+Vector2(sin(i*7.3)*dust_age*18,dust_age*dust_age*94)
					draw_circle(p,.65+i%3*.15,Color(.49,.43,.35,sin(dust_age*PI)*.27))
			sanctuary_sparks(Vector2(337,445),1.)
			sanctuary_sparks(Vector2(1101,445),9.)
			# The sealed sanctuary breathes slowly; side fires remain independent.
			var breath=.65+.2*sin(clock*.43)
			exhaust(Vector2(295,533),65,234,2,Color(.43,.39,.34,.52*breath))
			exhaust(Vector2(1137,536),68,218,9,Color(.43,.39,.34,.48*breath))
			embers(Vector2(284,510),20,42,210,1)
			embers(Vector2(1159,514),20,46,225,7)
			exhaust(Vector2(714,557),150,65,6,Color(.40,.35,.29,.22))
