extends Node2D
var game: Node2D
var fire: ContourFire
var tier=-1
var time=0.0
var bounds={}
var fire_height=1.0
func stone(label: String,center: Vector2,height: float,max_width: float=280.0):
 var meta=game.art.data.menu[label]
 var texture=game.art.texture("menu-"+meta.id+".png")
 if not bounds.has(label):bounds[label]=texture.get_image().get_used_rect()
 var rect=bounds[label]
 var factor=minf(height/rect.size.y,max_width/rect.size.x)
 var size=Vector2(rect.size)*factor
 draw_texture_rect_region(texture,Rect2(center-size*.5,size),rect,Color(1.8,1.7,1.5))

func _process(dt):
 if not game:return
 visible=game.phase!="title"
 if not visible:return
 time+=dt
 var current=game.combo.multiplier()
 if tier!=current:
  tier=current
  if is_instance_valid(fire):fire.queue_free()
  fire=null
  if tier>=4:
   var meta=game.art.data.menu["%dX"%tier]
   fire=ContourFire.new()
   fire.menu_palette=true
   add_child(fire)
   fire.show_behind_parent=true
   var mask=game.art.texture("menu-"+meta.id+"-fuel.png").get_image()
   var used=mask.get_used_rect()
   fire_height=used.size.y
   fire.setup(ImageTexture.create_from_image(mask.get_region(used)),Vector2(used.size),-Vector2(used.size)*.5,false)
 if fire:
  var meta=game.art.data.menu["%dX"%tier]
  fire.scale=Vector2.ONE*(40.+tier*3.)/fire_height
  fire.position=Vector2(0,133)+unrest()
  fire.strength=.8+(tier-4)*.4
  fire.emitting=game.combo.remaining>0
 queue_redraw()
func unrest() -> Vector2:
 var amount=maxf(0.,tier-2)*.35
 return Vector2(sin(time*23)+sin(time*37)*.35,cos(time*29)*.65)*amount
func _draw():
 if not game or game.phase=="title":return
 stone("AREA %d/4"%game.screen_for_wave(game.wave),Vector2(-78,10),19,125)
 stone("BOSS" if game.wave==game.encounters.size() else "WAVE %d/3"%(1+(game.wave-1)%3),Vector2(76,10),19,125)
 var digits="%06d"%game.score
 var width=minf(32.,260./digits.length())
 for i in digits.length():stone(digits[i],Vector2((i-(digits.length()-1)*.5)*width,57),39,width)
 if game.combo.hits>0:
  stone("%dX"%game.combo.multiplier(),Vector2(0,133)+unrest(),40.+game.combo.multiplier()*3.,150)
  draw_rect(Rect2(-75,174,150,3),Color(.08,.035,.025,.8))
  draw_rect(Rect2(-75,174,150*game.combo.remaining/game.combo.timeout,3),Color(.6,.25,.08,.9))
