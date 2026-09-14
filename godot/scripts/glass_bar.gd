class_name CairnGlassBar
extends RefCounted
# Shared curved glass, liquid depth and reflected light for every resource meter.
static var liquid: GradientTexture2D
static var glass: GradientTexture2D
static func gradient(stops: Array, colors: Array) -> GradientTexture2D:
 var ramp=Gradient.new()
 ramp.offsets=PackedFloat32Array(stops)
 ramp.colors=PackedColorArray(colors)
 var texture=GradientTexture2D.new()
 texture.gradient=ramp
 texture.width=8
 texture.height=128
 texture.fill_from=Vector2(.5,0)
 texture.fill_to=Vector2(.5,1)
 return texture
static func draw(node: Node2D,rect: Rect2,value: float,tint: Color):
 if liquid==null:
  liquid=gradient([0,.12,.36,.58,.82,1],[Color(.35,.35,.35),Color(.9,.9,.9),Color(.72,.72,.72),Color(.32,.32,.32),Color(.6,.6,.6),Color(.92,.92,.92)])
  glass=gradient([0,.04,.12,.30,.36,.48,.76,.92,1],[Color(1,1,1,.55),Color(.78,.89,1,.15),Color(1,1,1,.38),Color(1,1,1,.16),Color(1,1,1,.02),Color(0,0,0,.2),Color(1,1,1,0),Color(.65,.85,1,.18),Color(1,1,1,.38)])
 node.draw_rect(rect.grow(1),Color(.035,.027,.025,.95))
 node.draw_rect(rect,Color(.025,.035,.043,.95))
 var fill=Rect2(rect.position,Vector2(rect.size.x*clampf(value,0,1),rect.size.y))
 if fill.size.x>0:
  node.draw_texture_rect(liquid,fill,false,tint)
  var rim=minf(2.0,fill.size.x)
  node.draw_rect(Rect2(fill.end.x-rim,fill.position.y+1,rim,maxf(1,fill.size.y-2)),tint.lightened(.35)*Color(1,1,1,.6))
 node.draw_texture_rect(glass,rect,false)
 # Slim edge catches and a broad, slanted reflection make the glass read as a surface.
 var h=rect.size.y
 var x=rect.position.x
 var y=rect.position.y
 var w=rect.size.x
 node.draw_colored_polygon(PackedVector2Array([Vector2(x+w*.09,y+h*.07),Vector2(x+w*.23,y+h*.07),Vector2(x+w*.20,y+h*.33),Vector2(x+w*.06,y+h*.33)]),Color(1,1,1,.085))
 node.draw_line(Vector2(x+1,y+h-1),Vector2(x+w-1,y+h-1),Color(.7,.84,.9,.3),minf(1,h*.1),true)
