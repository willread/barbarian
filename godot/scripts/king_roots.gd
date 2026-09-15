extends Node2D
const TEXTURES=[preload("res://assets/king-root-v2-0.png"),preload("res://assets/king-root-v2-1.png"),preload("res://assets/king-root-v2-2.png"),preload("res://assets/king-root-v2-3.png")]
var growth=0.0
var facing=1
var variant=0
var size=Vector2(200,240)
func configure(age: float,life: float,_sweep: bool,direction: int,shape: int=0,dimensions: Vector2=Vector2(200,240)):
 facing=direction
 variant=shape
 size=dimensions
 growth=minf(clampf(age/.20,0,1),clampf((life-age)/.30,0,1))
 queue_redraw()
func _draw():
 if growth<=0:return
 var texture=TEXTURES[variant]
 # Reveal solid wood rising through the ground, without squashing or crossfading it.
 var rise=1.0-pow(1.0-growth,3)
 var height=size.y*rise
 draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
 draw_texture_rect_region(texture,Rect2(-size.x*.5,-height+9,size.x,height),Rect2(0,0,texture.get_width(),texture.get_height()*rise))
 draw_set_transform(Vector2.ZERO)
