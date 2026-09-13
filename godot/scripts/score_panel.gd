extends Node2D
var game: Node2D
var fire: ContourFire
var tier=-1
var time=0.0
var bounds={}
var fire_height=1.0
var impact_age=10.0
var score_age=10.0
var last_score=0.0
func stone(label: String,center: Vector2,height: float,max_width: float=280.0):
 var meta=game.art.data.menu["HUD "+label]
 var texture=game.art.texture("menu-"+meta.id+".png")
 if not bounds.has(label):bounds[label]=texture.get_image().get_used_rect()
 var rect=bounds[label]
 var factor=minf(height/rect.size.y,max_width/rect.size.x)
 var size=Vector2(rect.size)*factor
 draw_texture_rect_region(texture,Rect2(center-size*.5,size),rect,Color(1.25,1.2,1.1))

func _process(dt):
 if not game:return
 visible=game.phase!="title"
 if not visible:return
 time+=dt
 impact_age+=dt
 score_age+=dt
 if last_score!=game.score:
  last_score=game.score
  score_age=0.0
 var current=game.combo.multiplier()
 if tier!=current:
  if current>tier and tier>=1:impact_age=0.0
  tier=current
  if is_instance_valid(fire):fire.queue_free()
  fire=null
  if tier>=4:
   var meta=game.art.data.menu["HUD %dX"%tier]
   fire=ContourFire.new()
   fire.menu_palette=true
   add_child(fire)
   fire.show_behind_parent=true
   var mask=game.art.texture("menu-"+meta.id+".png").get_image()
   var used=mask.get_used_rect()
   mask=mask.get_region(used)
   var target_height=90
   mask.resize(maxi(1,int(float(used.size.x)*target_height/used.size.y)),target_height,Image.INTERPOLATE_LANCZOS)
   fire_height=target_height
   fire.setup(ImageTexture.create_from_image(mask),Vector2(mask.get_size()),-Vector2(mask.get_size())*.5,false)
 if fire:
  fire.scale=Vector2.ONE*combo_height()/fire_height
  fire.position=Vector2(0,151)+unrest()
  fire.strength=.65+(tier-4)*.23+exp(-impact_age*7.)*.5
  fire.emitting=game.combo.remaining>0
 queue_redraw()
func combo_height() -> float:
 var kick=exp(-impact_age*8.)*cos(impact_age*24.)
 return 1.25*(43.+tier*1.8)*(1.+kick*(.10+tier*.018))
func unrest() -> Vector2:
 var burst=exp(-impact_age*7.)*(1.+tier*.6)
 var idle=maxf(0.,tier-4)*.15
 return Vector2(sin(time*43),cos(time*37)*.6)*(burst+idle)
func _draw():
 if not game or game.phase=="title":return
 stone("AREA %d/4"%game.screen_for_wave(game.wave),Vector2(-72,25),17,120)
 stone("BOSS" if game.wave==game.encounters.size() else "WAVE %d/3"%(1+(game.wave-1)%3),Vector2(72,25),17,120)
 var digits="%06d"%game.score
 var width=minf(33.,230./digits.length())
 # One shared glyph scale preserves the numeral baseline and balanced tracking.
 var widest=0.0
 for digit in "0123456789":
  var meta=game.art.data.menu["HUD "+digit]
  if not bounds.has(digit):bounds[digit]=game.art.texture("menu-"+meta.id+".png").get_image().get_used_rect()
  widest=maxf(widest,float(bounds[digit].size.x)/bounds[digit].size.y)
 var height=minf(38.,(width-3.)/widest)*(1.+.025*exp(-score_age*12.))
 for i in digits.length():stone(digits[i],Vector2((i-(digits.length()-1)*.5)*width,69),height,width)
 stone("%dX"%game.combo.multiplier(),Vector2(0,151)+unrest(),combo_height(),187.5)
 if game.combo.hits>0:
  draw_rect(Rect2(-101,210,202,6),Color(.08,.035,.025,.8))
  draw_rect(Rect2(-100,211,200*game.combo.remaining/game.combo.timeout,4),Color(.6,.25,.08,.9))
