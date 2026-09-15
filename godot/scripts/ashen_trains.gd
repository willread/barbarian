extends Node2D
# Small ore trains use the painting's own iron wagon texture, on the rear rail.
# A private RNG keeps scenery scheduling independent of combat randomness.
var clock=0.0
var rng=RandomNumberGenerator.new()
var initialized=false
var next_departure=0.0
var departure=0.0
var speed=60.0
var direction=1.0
var wagon_count=4
var active=false
var completed=0
var painting: Texture2D
const SPACING=59.0
const WAGON_SCALE=.66
const SOURCE_ANCHOR=Vector2(720,500)
const WAGON= [Vector2(683,463),Vector2(716,468),Vector2(720,467),Vector2(727,470),Vector2(757,475),Vector2(760,479),Vector2(753,481),Vector2(750,495),Vector2(747,500),Vector2(744,504),Vector2(736,504),Vector2(731,500),Vector2(703,496),Vector2(699,500),Vector2(691,499),Vector2(687,494),Vector2(678,493),Vector2(677,489),Vector2(681,487),Vector2(685,468)]

func _ready():
	rng.randomize()
	painting=load("res://assets/ashen-1-base.png")
	var depth=ShaderMaterial.new()
	depth.shader=preload("res://shaders/ashen_train_depth.gdshader")
	material=depth

func advance(t: float):
	clock=t
	if not initialized:
		initialized=true
		next_departure=t+rng.randf_range(2.0,6.0)
	if active and t>=departure+duration():
		active=false
		completed+=1
		next_departure=t+rng.randf_range(9.0,24.0)
	if not active and t>=next_departure:
		active=true
		departure=t
		speed=rng.randf_range(48.0,76.0)
		direction=1.0 if rng.randf()>.5 else -1.0
		wagon_count=rng.randi_range(3,6)
	queue_redraw()

func duration() -> float:
	return (1600.0+(wagon_count-1)*SPACING)/speed

func lead_x(t: float) -> float:
	return -80+(t-departure)*speed if direction>0 else 1520-(t-departure)*speed

func rail_y(x: float) -> float:
	return 342.0+x*.130

func _draw():
	if not active or not painting:return
	var head=lead_x(clock)
	for i in wagon_count:
		var x=head-direction*i*SPACING
		if x < -100 or x > 1540:continue
		var origin=Vector2(x,rail_y(x))
		if i<wagon_count-1:
			var end=Vector2(x-direction*SPACING,rail_y(x-direction*SPACING))
			draw_line(origin+Vector2(0,-4),end+Vector2(0,-4),Color("332c26"),1.3,true)
		var points=PackedVector2Array()
		var uv=PackedVector2Array()
		for p in WAGON:
			points.append(origin+(p-SOURCE_ANCHOR)*WAGON_SCALE)
			uv.append(p/painting.get_size())
		draw_polygon(points,PackedColorArray([Color(.87,.87,.87,1)]),uv,painting)
		# Turning wheel spokes stay barely visible at this distance.
		for wheel in [Vector2(-16,-2),Vector2(13,2)]:
			var center=origin+wheel
			var spoke=Vector2.from_angle(clock*speed/3.0*direction)*1.7
			draw_line(center-spoke,center+spoke,Color(.32,.30,.27,.6),.6,true)
		if i==0:
			# Small amber running lamp distinguishes the active haulage train.
			var lamp=origin+Vector2(direction*21,-7)
			draw_circle(lamp,2.8,Color(.95,.46,.12,.10))
			draw_circle(lamp,1.0,Color(.98,.68,.29,.75))
