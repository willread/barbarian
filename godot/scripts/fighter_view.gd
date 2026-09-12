extends Node2D
var actor: Dictionary
var art: CairnArt
var pose: Array=[]
var burn_material: ShaderMaterial
var burning: BurningSprite
var burn_finished=false
func _ready():
	burn_material=ShaderMaterial.new()
	burn_material.shader=load("res://shaders/burn.gdshader")
	material=burn_material
func update_view(spell: int):
	pose=art.pose(actor,spell)
	# Set the basis directly: decomposing negative X scale during reparenting can
	# leave a PI rotation behind, which a later scale assignment turns upside down.
	transform=Transform2D(Vector2(actor.dir*actor.size,0),Vector2(0,actor.size),Vector2(actor.x,actor.y-actor.height*4.5))
	z_index=int(actor.y)*2
	burn_material.set_shader_parameter("burn_age",actor.burnAge if not actor.player else 0.0)
	burn_material.set_shader_parameter("engulf",actor.engulf)
	burn_material.set_shader_parameter("seed",actor.burnSeed)
	burn_material.set_shader_parameter("electric",float(actor.electricTicks))
	burn_material.set_shader_parameter("hit_glow",actor.hitGlow)
	if not actor.player and actor.burnAge>0 and not burn_finished:
		if not burning:
			var layout=art.layout(pose)
			var rect=art.body_rect(actor,pose)
			if layout.atlas.facing<0:rect.position.x=-rect.end.x
			burning=BurningSprite.new()
			add_child(burning)
			burning.setup(art.texture(layout.cel.file),rect,layout.atlas.facing<0,actor.burnSeed)
		burning.update_burn(actor.burnAge,actor.engulf)
		if actor.burnAge>3.3:
			burning.queue_free()
			burning=null
			burn_finished=true
	queue_redraw()
func _draw():
	if pose.is_empty(): return
	if burning or burn_finished:return
	art.paint_weapon(self,actor,pose,true)
	art.paint_body(self,actor,pose)
	art.paint_weapon(self,actor,pose,false)
