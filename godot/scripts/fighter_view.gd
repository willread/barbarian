extends Node2D
var actor: Dictionary
var art: CairnArt
var pose: Array=[]
var burn_material: ShaderMaterial
var burning: BurningSprite
var burn_finished=false
var whirl_turn=1.0
static var dust_texture: Texture2D
func _ready():
	burn_material=ShaderMaterial.new()
	burn_material.shader=load("res://shaders/burn.gdshader")
	material=burn_material
	if actor.get("kind","")=="champion":prepare_dust()
func update_view(spell: int):
	pose=art.pose(actor,spell)
	# Set the basis directly: decomposing negative X scale during reparenting can
	# leave a PI rotation behind, which a later scale assignment turns upside down.
	transform=Transform2D(Vector2(actor.dir*actor.size,0),Vector2(0,actor.size),Vector2(actor.x,actor.y-actor.height*4.5))
	whirl_turn=1.0
	if actor.attack.get("whirlwind",false) and actor.attack.age>=actor.attack.from and actor.attack.age<=actor.attack.to:
		var turn=cos((actor.attack.age-actor.attack.from)*.43)
		whirl_turn=(1 if turn>=0 else -1)*(.72+.28*absf(turn))
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

static func prepare_dust():
	if dust_texture:return
	var noise=FastNoiseLite.new()
	noise.seed=7149
	noise.frequency=.095
	noise.fractal_octaves=3
	var image=Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var distance=Vector2(x-31.5,y-31.5).length()/31.5
			var density=pow(maxf(0,1-distance*distance),2.3)*clampf(.58+noise.get_noise_2d(x,y)*.8,0,1)
			image.set_pixel(x,y,Color(1,1,1,density))
	dust_texture=ImageTexture.create_from_image(image)

func paint_whirlwind(front: bool):
	var a=actor.attack
	var active=a.age>=a.from and a.age<=a.to
	var strength=smoothstep(0,18,a.age-a.from) if active else 0.0
	var settle=1.0-smoothstep(a.to,a.to+36,a.age)
	if a.age<a.from:strength=smoothstep(a.from-24,a.from,a.age)*.22
	elif a.age>a.to:strength=settle
	if strength<=0:return
	prepare_dust()
	# Keep dust in world orientation while the body turns inside it.
	draw_set_transform(Vector2.ZERO,0,Vector2(1.0/(whirl_turn*actor.dir),1))
	var time=float(a.age-a.from)/60.0
	var travel: Vector2=a.get("travel",Vector2.ZERO)
	for mote in 46:
		var life=fposmod(time*.95+mote*.618,1.0)
		var angle=mote*2.399+time*(3.0+fmod(mote*1.37,2.0))
		var radius=40+life*125
		var depth=sin(angle)
		if (depth>0)!=front:continue
		var point=Vector2(cos(angle)*radius-travel.x*life*3.0,depth*radius*.22-life*(45+fmod(mote*17.0,155.0)))
		var size=Vector2(68+life*85,40+life*65)
		var opacity=sin(life*PI)*(.62 if front else .82)*strength
		draw_texture_rect(dust_texture,Rect2(point-size*.5,size),false,Color(.67,.58,.44,opacity))
		# A few heavy chips stay low instead of orbiting in perfect rings.
		if mote%4==0 and life<.65:
			var chip=point+Vector2(0,life*life*30)
			draw_line(chip,chip-Vector2(travel.x*.15,2.0),Color(.40,.32,.23,(1-life)*strength),2,true)
	if active:
		# Short, tapered motion blur follows the blade sweep; no stacked hoops.
		var phase=(a.age-a.from)*.43
		for segment in 24:
			var tail=float(segment)/24
			var angle=phase-tail*1.55
			var next=angle-1.55/24
			if (sin(angle)>0)!=front:continue
			var center=Vector2(cos(angle)*192,-172+sin(angle)*43)
			var end=Vector2(cos(next)*192,-172+sin(next)*43)
			var width=(1-tail)*13.0
			var color=Color(.82,.80,.72,pow(1-tail,1.8)*smoothstep(0,.12,tail)*.50*strength)
			var edge=Color(color,0)
			for side in [-1,1]:
				draw_polygon(PackedVector2Array([center+Vector2(0,width*side),end+Vector2(0,width*.93*side),end,center]),PackedColorArray([edge,edge,color,color]))
	draw_set_transform(Vector2.ZERO)
