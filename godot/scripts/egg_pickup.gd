extends Node2D
var game: Node2D
var golden=false
var age=0.0
var height=20.0
var velocity=80.0
var drift=0.0
var collected=false
var collect_age=0.0
var expired=false
func advance(dt: float):
	age+=dt
	if collected:
		collect_age+=dt
		height+=160*dt
		if collect_age>=.35:expired=true
	elif height>0 or velocity>0:
		position.x=clampf(position.x+drift*dt,45,1395)
		height=maxf(0.,height+velocity*dt)
		velocity-=500*dt
		if height==0:velocity=0
	else:
		var h=game.hero
		if h.hp>0 and h.down.is_empty() and h.air.is_empty() and h.height<=0 and h.pickup.is_empty() and not h.hurtTicks and abs(h.x-position.x)<38 and abs(h.y-position.y)<24:
			collected=true
			if golden:
				game.combo.golden_egg()
				if not game.run_stats.is_empty():game.run_stats.peak_multiplier=game.combo.max_multiplier
			else:h.hp=minf(h.max,h.hp+h.max*.25)
			game.audio.play("pickup" if golden else "gulp",-6)
	if age>=25.:expired=true
	z_index=int(position.y)*2
	queue_redraw()
func _draw():
	var opacity=1.-collect_age/.35 if collected else minf(1.,(25.-age)/2.)
	# Ground shadow stays at the landing point while the egg bounces and is collected.
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.3))
	draw_circle(Vector2.ZERO,13,Color(0,0,0,.35*opacity))
	var center=Vector2(0,-height-15)
	if golden:
		for i in range(8,0,-1):
			draw_set_transform(center,0,Vector2.ONE)
			draw_circle(Vector2.ZERO,18+i*3,Color(1,.65,.08,.025*opacity))
	var scale=1.-collect_age/.5 if collected else 1.
	draw_set_transform(center,sin(age*9)*.12*maxf(0,1.-age),Vector2.ONE*scale)
	# Egg silhouette, tapered crown, shaded shell and small reflected highlights.
	var shell=PackedVector2Array()
	for i in 48:
		var angle=TAU*i/48.
		shell.append(Vector2(sin(angle)*12*(1.+.18*cos(angle)),cos(angle)*16))
	draw_colored_polygon(shell,Color("926111")*Color(1,1,1,opacity) if golden else Color("9f8763")*Color(1,1,1,opacity))
	for i in range(12,0,-1):
		draw_set_transform(center+Vector2(-2,-2)*scale,0,Vector2(.68,1.)*scale)
		var t=1.-i/12.
		var shade=Color("d99613").lerp(Color("fff0a0"),t) if golden else Color("c9b58b").lerp(Color("fff0cd"),t)
		shade.a=opacity
		draw_circle(Vector2.ZERO,i,shade)
	draw_set_transform(center+Vector2(-4,-7)*scale,-.3,Vector2(.5,1)*scale)
	draw_circle(Vector2.ZERO,3,Color(1,1,.88,.65*opacity))
	if golden:
		draw_set_transform(center+Vector2(8,-9),age*.6,Vector2.ONE)
		var glow=.55+.45*sin(age*5)
		draw_line(Vector2(-5,0),Vector2(5,0),Color(1,.95,.6,glow*opacity),1.5)
		draw_line(Vector2(0,-5),Vector2(0,5),Color(1,.95,.6,glow*opacity),1.5)
	draw_set_transform(Vector2.ZERO)
