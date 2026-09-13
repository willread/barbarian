extends SceneTree
func _init():call_deferred("capture")
func capture():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.start_game()
 game.visible=false
 var panel=Node2D.new()
 root.add_child(panel)
 panel.draw.connect(func():
  panel.draw_rect(Rect2(0,0,2560,1440),Color(.08,.08,.08))
  for i in 4:
   var f=game.hero.duplicate(true)
   f.holiday="off"
   f.weapon_skin="gravecleaver"
   var holder=Node2D.new()
   holder.position=Vector2(245+i*320,630)
   holder.scale=Vector2.ONE*1.5
   panel.add_child(holder)
   var pose=["hero-walk-unarmed-v8",i]
   holder.draw.connect(func():
    game.art.paint_weapon(holder,f,pose,true)
    game.art.paint_body(holder,f,pose)
    game.art.paint_weapon(holder,f,pose,false))
 )
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/will/Documents/will/barbarian/studies/grip-pause/walk-proposed.png")
 quit()
