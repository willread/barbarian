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
var eating=false
var draw_scale=1.0
func _ready():
	material=ShaderMaterial.new()
	material.shader=preload("res://shaders/egg_shell.gdshader")
	material.set_shader_parameter("golden",golden)
func advance(dt: float):
	age+=dt
	var h=game.hero
	if eating:
		if h.pickup.is_empty() or h.hp<=0 or not h.down.is_empty() or h.hurtTicks:
			eating=false
			height=0
			draw_scale=1.
			if h.pickup.get("egg")==self:h.pickup={}
			if collected:expired=true
		else:
			var point=game.advance_food_pickup(dt)
			var p=h.pickup
			position.x=point.x
			height=h.y-point.y
			draw_scale=lerpf(1.,.08,smoothstep(.68,.92,p.age))
			if p.age>=.92 and not collected:
				collected=true
				p.collected=true
				if golden:
					game.combo.golden_egg()
					if not game.run_stats.is_empty():game.run_stats.peak_multiplier=game.combo.max_multiplier
				else:h.hp=minf(h.max,h.hp+h.max*.25)
				game.audio.play("gulp",-3)
			if p.age>=1.2:
				h.pickup={}
				expired=true
	elif height>0 or velocity>0:
		position.x=clampf(position.x+drift*dt,45,1395)
		height=maxf(0.,height+velocity*dt)
		velocity-=500*dt
		if height==0:velocity=0
	elif h.hp>0 and h.down.is_empty() and h.air.is_empty() and h.attack.is_empty() and game.spell<0 and h.height<=0 and h.pickup.is_empty() and not h.hurtTicks and abs(h.x-position.x)<38 and abs(h.y-position.y)<24:
		eating=true
		h.dir=1 if position.x>=h.x else -1
		h.pickup={"age":0.0,"collected":false,"start_x":position.x,"egg":self}
	if age>=25. and not eating:expired=true
	z_index=int(position.y)*2+1
	queue_redraw()
func _draw():
	if collected:return
	var opacity=minf(1.,(25.-age)/2.) if not eating else 1.
	draw_set_transform(Vector2(0,-height-16),0,Vector2.ONE*draw_scale)
	draw_rect(Rect2(-16,-20,32,40),Color(1,1,1,opacity))
