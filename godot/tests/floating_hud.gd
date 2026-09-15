extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.current_episode=2
 game.start_game()
 game.set_process(false)
 game.menu.visible=false
 game.wave=13;game.spawn_wave()
 game.transition=-1;game.stage_walk=""
 game.hero.x=580;game.hero.y=690
 var king=game.enemies[0]
 king.x=1030;king.y=690
 game.hero.hp=80;game.displayed_health=80;game.displayed_mana=65
 game.score=1234567
 for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(800,450)]:
  root.size=dimensions
  game.last_window_size=Vector2i.ZERO
  game.responsive_layout()
  assert(game.position.is_zero_approx(),"World must not be cropped or enlarged to make room for HUD")
  assert(game.scale==Vector2.ONE and game.background.scale==Vector2.ONE)
  assert(game.hud.position==Vector2(352,16) and game.hud.scale==Vector2.ONE)
  assert(game.art.data.menu.has("HUD x1") and game.art.data.menu.has("HUD x10"))
  game.m.begin(king,"rootSlam")
  king.attack.target=Vector2(580,690);king.attack.age=44
  game._process(0)
  assert(game.background.position.is_zero_approx())
  assert(game.art.body_rect(king,game.art.pose(king)).position.y+king.y>140,"Tall attack must clear the floating boss meter")
  if "--hud-capture" in OS.get_cmdline_user_args():
   await create_timer(.4).timeout
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("E:/Cairn-build-tools/floating-hud-%d.png"%dimensions.x)
 game.combo.hits=27;game.combo.remaining=5
 game.score_panel._process(.1)
 var ink=game.score_panel.bounds["x10"]
 assert(game.score_panel.combo_height()*ink.size.x/ink.size.y<=54.01,"Two-digit multiplier must fit without shifting its baseline")
 if "--hud-capture" in OS.get_cmdline_user_args():
  root.size=Vector2i(1280,720)
  game.last_window_size=Vector2i.ZERO
  game.responsive_layout()
  game._process(0)
  await create_timer(.3).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/floating-hud-x10.png")
 game.queue_free()
 await process_frame
 print("CAIRN_FLOATING_HUD_OK: centered half-width panel, x-prefix labels, full world framing and tall boss clearance")
 quit()
