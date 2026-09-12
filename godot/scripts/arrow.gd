extends Node2D
const GRAVITY=540.0
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
	game=source
	owner_actor=archer
	point=Vector3(archer.x+archer.dir*60,archer.y,165)
	var target=game.hero
	var travel=clampf(abs(target.x-point.x)/640.0,.25,1.2)
	velocity=Vector3((target.x-point.x)/travel,(target.y-point.y)/travel,(115+target.height*4.5-point.z+.5*GRAVITY*travel*travel)/travel)
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
		if stuck>=1.0:queue_free()
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
			game.damage(h,{"damage":8.5,"direction":1 if velocity.x>0 else -1,"knock":false},owner_actor)
			if h.hp<before:
				point=probe
				stuck=0.0
				attached=true
				facing=h.dir
				attachment=Vector2((point.x-h.x)*h.dir,point.z-h.height*4.5)
		if point.z<=0:
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
	# Arrow tip is the contact point; shaft trails behind it.
	draw_line(Vector2(-49,0),Vector2(-5,0),Color("896648"),2.2,true)
	draw_line(Vector2(-48,-.5),Vector2(-6,-.5),Color("c5a274"),.7,true)
	draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(-9,-3),Vector2(-7,0),Vector2(-9,3)]),Color("a6aba9"))
	for side in [-1,1]:
		draw_colored_polygon(PackedVector2Array([Vector2(-48,0),Vector2(-50,side*4),Vector2(-39,side*3),Vector2(-36,0)]),Color("9b9a81"))
