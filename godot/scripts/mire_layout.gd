extends RefCounted
const RADIUS=Vector2(68,14)
static func spots(point: Vector2) -> Array:
 var rng=RandomNumberGenerator.new()
 rng.seed=absi(int(point.x*31+point.y*71))
 var count=rng.randi_range(3,4)
 var vertical=rng.randf()<.5
 var result=[]
 for i in count:
  var along=i-(count-1)*.5
  var offset=Vector2(rng.randf_range(-9,9),along*24) if vertical else Vector2(along*120,rng.randf_range(-3,3))
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
