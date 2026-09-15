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
func combo_band(value: int) -> int:
 return 0 if value<=4 else 1 if value<=6 else 2 if value<=8 else 3
func combo_color(value: int) -> Color:
 return [Color(1.25,1.2,1.1),Color(2.5,2.1,.30),Color(2.5,1.15,.20),Color(2.5,.42,.30)][combo_band(value)]
func flame_color(value: int) -> Color:
 return [Color.TRANSPARENT,Color("ffe12b"),Color("ff8614"),Color("ff3322")][combo_band(value)]
func stone(label: String,center: Vector2,height: float,max_width: float=280.0,color=Color(1.25,1.2,1.1),right_aligned: bool=false,left_aligned: bool=false):
 var meta=game.art.data.menu["HUD "+label]
 var texture=game.art.texture("menu-"+meta.id+".png")
 if not bounds.has(label):bounds[label]=texture.get_image().get_used_rect()
 var rect=bounds[label]
 var factor=minf(height/rect.size.y,max_width/rect.size.x)
 var size=Vector2(rect.size)*factor
 var origin=center-Vector2(0.0 if left_aligned else size.x if right_aligned else size.x*.5,size.y*.5)
 draw_texture_rect_region(texture,Rect2(origin,size),rect,color)

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
  if tier>=5:
   var meta=game.art.data.menu["HUD x%d"%tier]
   fire=ContourFire.new()
   fire.menu_palette=true
   fire.accent_color=flame_color(tier)
   add_child(fire)
   fire.show_behind_parent=true
   var mask=game.art.texture("menu-"+meta.id+".png").get_image()
   var used=mask.get_used_rect()
   mask=mask.get_region(used)
   var target_height=36
   mask.resize(maxi(1,int(float(used.size.x)*target_height/used.size.y)),target_height,Image.INTERPOLATE_LANCZOS)
   fire_height=target_height
   fire.setup(ImageTexture.create_from_image(mask),Vector2(mask.get_size()),-Vector2(mask.get_size())*.5,false)
 if fire:
  fire.scale=Vector2.ONE*combo_height()/fire_height
  fire.position=Vector2(162,55-combo_height()*.5)+unrest()
  fire.strength=.3+(tier-5)*.06+exp(-impact_age*7.)*.15
  fire.interior=.025+(tier-5)*.025
  fire.animation_speed=1.0+(tier-5)*.04
  fire.emitting=game.combo.remaining>0
 queue_redraw()
func combo_height() -> float:
 var kick=exp(-impact_age*8.)*cos(impact_age*24.)
 var label="x%d"%game.combo.multiplier()
 if not bounds.has(label):
  var meta=game.art.data.menu["HUD "+label]
  bounds[label]=game.art.texture("menu-"+meta.id+".png").get_image().get_used_rect()
 var ink=bounds[label]
 # Fit x10 before positioning so its baseline stays identical to x1 and the score.
 return minf((27.+min(tier,10)*.25)*(1.+kick*.045),54.0*ink.size.y/ink.size.x)
func unrest() -> Vector2:
 var burst=exp(-impact_age*7.)*(1.+tier*.6)
 var idle=maxf(0.,tier-4)*.15
 return Vector2(sin(time*43),cos(time*37)*.6)*(burst+idle)
func _draw():
 if not game or game.phase=="title":return
 var ink=Color(1.8,1.7,1.35)
 # Both label and first digit start at x=0, using cropped glyph ink bounds.
 stone("AREA %d/4"%game.screen_for_wave(game.wave),Vector2(0,8),12,125,ink,false,true)
 var digits="%07d"%game.score
 var advance=minf(17.0,126.0/digits.length())
 var widest=0.0
 for digit in "0123456789":
  var meta=game.art.data.menu["HUD "+digit]
  if not bounds.has(digit):bounds[digit]=game.art.texture("menu-"+meta.id+".png").get_image().get_used_rect()
  widest=maxf(widest,float(bounds[digit].size.x)/bounds[digit].size.y)
 var height=minf(25.0,(advance-2.0)/widest)
 for i in digits.length():stone(digits[i],Vector2(i*advance,55-height*.5),height,advance,ink,false,true)
 stone("x%d"%game.combo.multiplier(),Vector2(162,55-combo_height()*.5)+unrest(),combo_height(),54,combo_color(tier))
 if game.combo.hits>0 or game.combo.bonus_multiplier>1:
  var fraction=clampf(game.combo.remaining/game.combo.timeout,0.,1.)
  draw_rect(Rect2(0,62,186,2),Color(.08,.035,.025,.8))
  draw_rect(Rect2(0,62,186*fraction,2),Color(.6,.45,.25,.9) if tier<=4 else flame_color(tier))
