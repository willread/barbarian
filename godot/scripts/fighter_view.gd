extends Node2D
var actor: Dictionary
var art: CairnArt
var pose: Array=[]
var burn_material: ShaderMaterial
var burning: BurningSprite
var burn_finished=false
var whirl_turn=1.0
func _ready():
	burn_material=ShaderMaterial.new()
	burn_material.shader=load("res://shaders/burn.gdshader")
	material=burn_material
func update_view(spell: int):
	pose=art.pose(actor,spell)
	# Set the basis directly: decomposing negative X scale during reparenting can
	# leave a PI rotation behind, which a later scale assignment turns upside down.
	transform=Transform2D(Vector2(actor.dir*actor.size,0),Vector2(0,actor.size),Vector2(actor.x,actor.y-actor.height*4.5))
	whirl_turn=1.0
	if actor.attack.get("whirlwind",false) and actor.attack.age>=actor.attack.from and actor.attack.age<=actor.attack.to:
		var turn=cos((actor.attack.age-actor.attack.from)*.43)
		whirl_turn=(1 if turn>=0 else -1)*maxf(.28,absf(turn))
		transform.x*=whirl_turn
	z_index=int(actor.y)*2
	burn_material.set_shader_parameter("burn_age",actor.burnAge if not actor.player else 0.0)
	burn_material.set_shader_parameter("engulf",actor.engulf)
	burn_material.set_shader_parameter("seed",actor.burnSeed)
	burn_material.set_shader_parameter("electric",float(actor.electricTicks))
	burn_material.set_shader_parameter("hit_glow",actor.hitGlow)
	var minotaur=actor.kind=="legion" and not actor.player
	burn_material.set_shader_parameter("exposure",1.4 if minotaur else 1.0)
	burn_material.set_shader_parameter("shadow_lift",0.0)
	burn_material.set_shader_parameter("tonal_contrast",1.12 if minotaur else 1.0)
	if not actor.player and actor.burnAge>0 and not burn_finished:
		if not burning:
			var layout=art.layout(pose)
			var rect=art.body_rect(actor,pose)
			if layout.atlas.facing<0:rect.position.x=-rect.end.x
			burning=BurningSprite.new()
			add_child(burning)
			burning.setup(art.texture(layout.cel.file),rect,layout.atlas.facing<0,actor.burnSeed)
		burning.update_burn(actor.burnAge,actor.engulf)
		if actor.burnAge>=BurningSprite.finished_at(actor.engulf):
			burning.queue_free()
			burning=null
			burn_finished=true
	queue_redraw()
func _draw():
	if pose.is_empty(): return
	if burning or burn_finished:return
	if actor.attack.get("whirlwind",false):paint_whirlwind(false)
	art.paint_weapon(self,actor,pose,true)
	art.paint_body(self,actor,pose)
	art.paint_weapon(self,actor,pose,false)
	if actor.attack.get("whirlwind",false):paint_whirlwind(true)

func paint_whirlwind(front: bool):
	var a=actor.attack
	if a.age>a.to:return
	var strength=clampf(float(a.age)/a.from,0,1)
	var active=a.age>=a.from
	# Counter the body's turning squash so the wind keeps its circular footprint.
	draw_set_transform(Vector2.ZERO,0,Vector2(1.0/whirl_turn,1))
	for band in 6:
		var points=PackedVector2Array()
		var radius=lerpf(45,150,float(band)/5)*strength
		var phase=a.age*(.43 if active else .13)+band*1.7
		for step in 19:
			var angle=phase+float(step)/18*PI*1.35
			var point=Vector2(cos(angle)*radius,-18-band*36+sin(angle)*radius*.19)
			if (sin(angle)>0)==front:points.append(point)
			elif points.size()>1:
				draw_polyline(points,Color(.80,.73,.57,(.30 if active else .12)*strength),2.5,true)
				points=PackedVector2Array()
			else:points=PackedVector2Array()
		if points.size()>1:draw_polyline(points,Color(.88,.83,.69,(.38 if active else .16)*strength),2.5,true)
	if front:
		for fleck in 12:
			var angle=a.age*.19+fleck*2.4
			var radius=45+fmod(fleck*29.0,100)
			draw_circle(Vector2(cos(angle)*radius,-8-absf(sin(angle*1.3))*32),2.0,Color(.61,.49,.32,.55*strength))
	draw_set_transform(Vector2.ZERO)
