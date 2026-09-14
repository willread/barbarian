extends Node2D
const TEXTURE=preload("res://art/king-roots-v1.png")
var growth=0.0
var sweeping=false
var facing=1
func configure(age: float,life: float,sweep: bool,direction: int):
 sweeping=sweep
 facing=direction
 growth=minf(clampf(age/.20,0,1),clampf((life-age)/.30,0,1))
 queue_redraw()
func _draw():
 if growth<=0:return
 var size=Vector2(180,130) if sweeping else Vector2(115,195)
 # Reveal a rising complete silhouette through the ground, without stretching it.
 var rise=1.0-pow(1.0-growth,3)
 var visible_height=size.y*rise
 var source_height=TEXTURE.get_height()*rise
 draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
 draw_texture_rect_region(TEXTURE,Rect2(-size.x*.5,-visible_height+12,size.x,visible_height),Rect2(0,0,TEXTURE.get_width(),source_height))
 draw_set_transform(Vector2.ZERO)
