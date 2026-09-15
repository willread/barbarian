extends Node2D
const TEXTURE=preload("res://art/king-roots-v1.png")
var growth=0.0
var sweeping=false
var facing=1
var age_seconds=0.0
func configure(age: float,life: float,sweep: bool,direction: int):
 age_seconds=age
 sweeping=sweep
 facing=direction
 growth=minf(clampf(age/.20,0,1),clampf((life-age)/.30,0,1))
 queue_redraw()
func _draw():
 if growth<=0:return
 # Stagger three rooted silhouettes instead of stretching a single cardboard wall.
 for i in range(3):
  var size=Vector2(76,145+32*(i%2))
  var rise=1.0-pow(1.0-clampf(growth-i*.09,0,1),3)
  var visible_height=size.y*rise
  if visible_height<=0:continue
  var shade=.72+i*.09
  draw_set_transform(Vector2((i-1)*29,abs(i-1)*3),0,Vector2(facing if i!=1 else -facing,1))
  draw_texture_rect_region(TEXTURE,Rect2(-size.x*.5,-visible_height+12,size.x,visible_height),Rect2(0,0,TEXTURE.get_width(),TEXTURE.get_height()*rise),Color(shade,shade,shade))
 draw_set_transform(Vector2.ZERO)
