extends Node2D
const GRAVITY=540.0
const SPEED=1050.0
var game: Node2D
var owner_actor: Dictionary
var point=Vector3.ZERO
var velocity=Vector3.ZERO
var age=0.0
var stuck=-1.0
var attached=false
var attachment=Vector2.ZERO
var facing=1
var angle=0.0

func setup(source: Node2D,archer: Dictionary):
	modulate=Color(.82,.82,.82,1)
	game=source
	owner_actor=archer
	# Registered to the release cel's bow/arrow junction in source-pixel space.
	var cel=game.art.data.atlases["enemy-archer-v1"].cels[6]
	var scale=255.0/game.art.data.atlases["enemy-archer-v1"].cels[0].height*archer.size
	point=Vector3(archer.x+(320-192)*scale*archer.dir,archer.y,(cel.top+cel.height-184)*scale)
	var target=game.hero
	var travel=maxf(.15,abs(target.x-point.x)/SPEED)
	# Leave the horizontal bow straight and fast; gravity supplies the downward arc.
	velocity=Vector3(archer.dir*SPEED,clampf((target.y-point.y)/travel,-90,90),0)
	update_position()

func advance(dt: float):
	age+=dt
	if stuck>=0:
		stuck+=dt
		if attached:
			var h=game.hero
			point=Vector3(h.x+attachment.x*h.dir,h.y,attachment.y+h.height*4.5)
			if h.dir!=facing:
				angle=PI-angle
				facing=h.dir
		if stuck>=.5:queue_free()
	else:
		var previous=point
		point+=velocity*dt+Vector3(0,0,-.5*GRAVITY*dt*dt)
		velocity.z-=GRAVITY*dt
		angle=atan2(-velocity.z,velocity.x)
		var h=game.hero
		# Swept projectile test prevents tunneling through the torso at high speed.
		var fraction=clampf((h.x-previous.x)/(point.x-previous.x),0,1) if abs(point.x-previous.x)>.001 else 1.0
		var probe=previous.lerp(point,fraction)
		if h.hp>0 and h.down.is_empty() and not h.invTicks and abs(probe.x-h.x)<29 and abs(probe.y-h.y)<24 and probe.z>h.height*4.5+35 and probe.z<h.height*4.5+230:
			var before=h.hp
			game.damage(h,{"damage":5.95,"no_stun":true,"direction":1 if velocity.x>0 else -1,"knock":false},owner_actor)
			if h.hp<before:
				point=probe
				stuck=0.0
				attached=true
				facing=h.dir
				attachment=Vector2((point.x-h.x)*h.dir,point.z-h.height*4.5)
		if point.z<=0:
			game.audio.play("arrow_hit")
			point.z=0
			stuck=0.0
		if age>3.0:queue_free()
	update_position()

func update_position():
	position=Vector2(point.x,point.y-point.z)
	z_index=int(point.y)*2+2
	rotation=angle
	queue_redraw()

func _draw():
	# Consistent material palette: dark ash shaft, forged iron, muted goose feathers.
	# Embedded arrows terminate at the surface: the point and socket are buried.
	var buried=26.0 if stuck>=0 else 0.0
	draw_set_transform(Vector2(buried,0))
	var end=-buried if stuck>=0 else -12.0
	draw_line(Vector2(-87,1),Vector2(end,1),Color("281d16"),3.2,true)
	draw_line(Vector2(-87,0),Vector2(end,0),Color("5c432b"),2.4,true)
	draw_line(Vector2(-86,-.65),Vector2(end,-.65),Color("8c6c44"),.65,true)
	# Narrow nock and tightly bound feather roots.
	draw_line(Vector2(-92,0),Vector2(-86,0),Color("51432d"),2.0,true)
	for x in [-84,-82,-64,-62]:
		draw_line(Vector2(x,-1.3),Vector2(x,1.3),Color("9f906b"),.65,true)
	for side in [-1,1]:
		var edge=PackedVector2Array([Vector2(-86,side*.8),Vector2(-87,side*5),Vector2(-80,side*6),Vector2(-66,side*3.4),Vector2(-62,side*.7)])
		draw_colored_polygon(edge,Color("706952") if side<0 else Color("514c3c"))
		for i in 8:
			var x=-84+i*2.4
			var width=5.2-float(i)*.4
			draw_line(Vector2(x,side*.9),Vector2(x-2.4,side*width),Color("92876c") if side<0 else Color("756b53"),.55,true)
	if stuck<0:
		# Three shaded facets keep the broadhead metallic without a bright white triangle.
		draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(-15,-4),Vector2(-12,0)]),Color("74786e"))
		draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(-12,0),Vector2(-15,4)]),Color("414541"))
		draw_line(Vector2(-16,0),Vector2(-11,0),Color("64675e"),2.5,true)
