extends Node2D
# Authored mud and hands, sorted with fighters so foreground hands catch their legs.
var texture: Texture2D
var mode=0
var progress=0.0
var clock=0.0
func _draw():
	if not texture:return
	var frame=0
	var alpha=1.0
	var rise=1.0
	if mode==0:
		alpha=.35+.65*progress
	else:
		frame=1+int(clock/.65)%2
		rise=smoothstep(0,.22,clock)
		if progress<.35:
			frame=3
			alpha=clampf(progress/.25,0,1)
			rise=clampf(progress/.35,.25,1)
	var cell=texture.get_size()/2
	var sway=sin(clock*TAU/1.3)*2 if mode==1 else sin(clock*TAU*2)*1.5
	var height=240*(.7+.3*rise)
	var rect=Rect2(-240,-height+58+sway,480,height)
	draw_texture_rect_region(texture,rect,Rect2(Vector2(frame%2,int(frame/2))*cell,cell),Color(1,1,1,alpha))
