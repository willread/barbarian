extends Node2D
var clock=0.0
var clumps: Array[Node2D]=[]
func _ready():
 var texture=load("res://art/scenery/swamp-reeds.png")
 # Low, irregular fringe; taller plants frame the edges without covering combat.
 for placement in [Vector3(20,828,.43),Vector3(102,841,.34),Vector3(213,844,.27),Vector3(365,848,.21),Vector3(550,854,.17),Vector3(770,858,.18),Vector3(938,849,.23),Vector3(1112,842,.31),Vector3(1240,835,.40),Vector3(1394,830,.48)]:
  var pivot=Node2D.new()
  pivot.position=Vector2(placement.x,placement.y)
  add_child(pivot)
  var sprite=Sprite2D.new()
  sprite.texture=texture
  sprite.centered=false
  sprite.scale=Vector2.ONE*placement.z
  sprite.position=Vector2(-143,-395)*placement.z
  sprite.flip_h=clumps.size()%2==1
  sprite.modulate=Color(.70,.74,.64,1)
  pivot.add_child(sprite)
  clumps.append(pivot)
 advance(clock)
func advance(t: float):
 clock=t
 for i in clumps.size():
  clumps[i].rotation=sin(t*(.64+i*.019)+i*2.37)*.027+sin(t*1.13+i*.71)*.009
