extends RefCounted
# Shared visual and collision envelope, in the bearer's local painted coordinates.
const START=36
const FADE=60
const END=78
const JETS=[Vector4(86,-166,205,64),Vector4(11,-137,225,83),Vector4(14,-207,88,70)]
const DIRECTIONS=[Vector2(1,.15),Vector2(.9,.35),Vector2(.1,-1)]
static func power(tick: float) -> float:
	if tick<START or tick>=END:return 0.0
	return lerpf(.1,1.0,smoothstep(START,START+5,tick))*(1-smoothstep(FADE,END,tick))
static func hits(enemy: Dictionary,hero: Dictionary,tick: float) -> bool:
	var strength=power(tick)
	if strength<=0 or absf(hero.y-enemy.y)>90*enemy.size:return false
	var centre=Vector2((hero.x-enemy.x)*enemy.attack.direction,hero.y-enemy.y-hero.height*4.5)/enemy.size
	var body=Rect2(centre+Vector2(-25,-190)/enemy.size,Vector2(50,175)/enemy.size)
	var box=PackedVector2Array([body.position,Vector2(body.end.x,body.position.y),body.end,Vector2(body.position.x,body.end.y)])
	for i in JETS.size():
		var jet=JETS[i]
		var origin=Vector2(jet.x,jet.y)
		var direction=DIRECTIONS[i].normalized()
		var normal=Vector2(-direction.y,direction.x)
		var tip=origin+direction*jet.z*strength
		var start_width=jet.w*.25*strength
		var end_width=jet.w*(.25+strength*.8)*strength
		var polygon=PackedVector2Array([origin-normal*start_width,tip-normal*end_width,tip+normal*end_width,origin+normal*start_width])
		if not Geometry2D.intersect_polygons(box,polygon).is_empty():return true
	return false
