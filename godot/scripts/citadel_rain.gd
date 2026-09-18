extends Node2D
# Deterministic trajectories keep each ground impact attached to its falling drop.
var clock=0.0
var pass_kind="near"
var area=1
var drops: Array=[]

func configure(polygon: Array,screen_number: int,kind: String):
	drops.clear()
	area=screen_number
	pass_kind=kind
	var floor_shape=PackedVector2Array()
	for point in polygon:floor_shape.append(Vector2(point[0]*1440,point[1]*810))
	var rng=RandomNumberGenerator.new()
	rng.seed=91873+area*317
	for i in (1050 if area==4 else 330):
		var point=Vector2(rng.randf_range(12,1428),rng.randf_range(540,795))
		if not Geometry2D.is_point_in_polygon(point,floor_shape):continue
		var depth=clampf((point.y-510)/290,0,1)
		drops.append({"p":point,"depth":depth,"speed":lerpf(620,1220,depth)*rng.randf_range(.85,1.15),"phase":rng.randf()*3,"period":rng.randf_range(1.1,2.3),"length":rng.randf_range(12,23),"alpha":rng.randf_range(.13,.30)})
	if kind=="distant":
		drops.clear()
		for i in (540 if area==4 else 180):
			drops.append({"p":Vector2(rng.randf_range(-30,1470),rng.randf_range(440,560)),"depth":.05,"speed":rng.randf_range(450,650),"phase":rng.randf()*3,"period":rng.randf_range(1.1,2.1),"length":rng.randf_range(6,12),"alpha":rng.randf_range(.055,.12)})
	if area==4:
		for drop in drops:
			drop.speed*=1.35
			drop.period*=.72
			drop.length*=1.5
	set_meta("continuous_clock",true)

func advance(time: float):
	clock=time
	queue_redraw()

func _draw():
	var wind=(155 if area==4 else 85)+sin(clock*.37+area)*(48 if area==4 else 28)+sin(clock*.91)*12
	var strength=[1.0,.85,.7,1.25][area-1]
	for drop in drops:
		var age=fposmod(clock+drop.phase,drop.period)
		var impact=drop.p
		var velocity=Vector2(wind*(.6+drop.depth),drop.speed)
		var fall_time=(impact.y+40)/drop.speed
		if pass_kind!="ground":
			if age>fall_time:continue
			var head=impact-velocity*(fall_time-age)
			var tail=head-velocity.normalized()*drop.length*(.6+drop.depth)
			var tint=Color(.69,.77,.82,drop.alpha*strength)
			draw_line(tail,head,tint,.65+drop.depth*.45,true)
			if pass_kind=="near":
				tint.a*=.45
				draw_line(tail-velocity.normalized()*drop.length*.4,tail,tint,.6,true)
		else:
			var splash_age=age-fall_time
			if splash_age<0 or splash_age>.22:continue
			var progress=splash_age/.22
			var fade=(1-progress)*strength
			var radius=(1+progress*4)*(.5+drop.depth)
			# Short, broken elliptical ripples and ballistic micro-droplets on stone.
			for side in [-1,1]:
				var offset=Vector2(side*progress*5, -sin(progress*PI)*3)*(.5+drop.depth)
				draw_line(impact+offset,impact+offset+Vector2(.2,.9),Color(.73,.79,.82,fade*.26),.65,true)
				var points=PackedVector2Array()
				for j in 7:
					var angle=float(j)/6*PI*.72+(0 if side==1 else PI)
					points.append(impact+Vector2(cos(angle)*radius,sin(angle)*radius*.26))
				draw_polyline(points,Color(.64,.72,.77,fade*.15),.6,true)
