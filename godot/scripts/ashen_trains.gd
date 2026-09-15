extends Node2D
# The two original painted carts are composited inside the whole track region.
# No new convoy, alternate track, added lights, or independent scenery sprites.
var clock=0.0
var track_material: ShaderMaterial
var rng=RandomNumberGenerator.new()
var initialized=false
var phase="parked"
var phase_start=0.0
var phase_duration=5.0
var direction=1.0
var variant=0
var completed=0
var positions=Vector2(720,1180)
var starts=Vector2(720,1180)
var targets=Vector2(720,1180)
var delays=Vector2.ZERO
const PARKED=Vector2(720,1180)

func _ready():rng.randomize()

func begin_departure(t: float):
	phase="depart"
	phase_start=t
	variant=rng.randi_range(0,2)
	direction=-1.0 if variant==1 else 1.0
	starts=PARKED
	targets=PARKED+Vector2.ONE*(1120.0 if direction>0 else -1320.0)
	delays=Vector2(4.0 if variant==0 else 8.0,0) if direction>0 else Vector2(0,4.0)
	phase_duration=(rng.randf_range(26.0,33.0)+(7.0 if variant==2 else 0.0))*.5

func advance(t: float):
	clock=t
	if not initialized:
		initialized=true
		phase_start=t
		phase_duration=rng.randf_range(4.0,9.0)
	var elapsed=t-phase_start
	if phase=="parked" and elapsed>=phase_duration:
		begin_departure(t)
		elapsed=0
	elif phase=="depart" and elapsed>=phase_duration+maxf(delays.x,delays.y):
		positions=targets
		phase="empty"
		phase_start=t
		phase_duration=rng.randf_range(9.0,24.0)
		completed+=1
	elif phase=="empty" and elapsed>=phase_duration:
		phase="arrive"
		phase_start=t
		phase_duration=rng.randf_range(12.5,16.0)
		starts=Vector2(-360,-100) if direction>0 else Vector2(1772,2032)
		targets=PARKED
		delays=Vector2.ZERO
		positions=starts
		elapsed=0
	elif phase=="arrive" and elapsed>=phase_duration:
		phase="parked"
		positions=PARKED
		phase_start=t
		phase_duration=rng.randf_range(10.0,27.0)
	if phase in ["depart","arrive"]:
		for i in 2:
			var progress=clampf((elapsed-delays[i])/phase_duration,0,1)
			# Smooth acceleration/braking, with the whole wheel contact following the rail.
			positions[i]=lerpf(starts[i],targets[i],progress*progress*(3.0-2.0*progress))
	if track_material:track_material.set_shader_parameter("cart_positions",positions)
