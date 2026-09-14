extends RefCounted
const SPACING_RADIUS=Vector2(68,14)
const RADIUS=SPACING_RADIUS*1.3
static func spots(point: Vector2) -> Array:
 var rng=RandomNumberGenerator.new()
 rng.seed=absi(int(point.x*31+point.y*71))
 var count=rng.randi_range(3,4)
 var result=[{"offset":Vector2.ZERO,"seed":rng.randf()*1000}]
 var rotation=rng.randf()*TAU
 var spread=rng.randf_range(1.8,2.5) if count==3 else TAU/3.0
 for i in range(count-1):
  var angle=rotation+i*spread+rng.randf_range(-.16,.16)
  # Touch a central puddle by 5-14% of the diameter, in random directions.
  var distance=rng.randf_range(1.72,1.90)
  var offset=Vector2(cos(angle),sin(angle))*SPACING_RADIUS*distance
  result.append({"offset":offset,"seed":rng.randf()*1000})
 return result
static func contains(point: Vector2,target: Vector2) -> bool:
 for spot in spots(point):
  if ((target-point-spot.offset)/RADIUS).length_squared()<1:return true
 return false

static func overlaps(a: Vector2,b: Vector2) -> bool:
 for left in spots(a):
  for right in spots(b):
   if ((a+left.offset-b-right.offset)/(RADIUS*2.0+Vector2(6,4))).length_squared()<1:return true
 return false
