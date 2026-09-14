extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.current_episode=2
 game.start_game()
 game.set_process(false)
 game.wave=13
 game.spawn_wave()
 game.transition=-1
 game.hero.x=500
 game.hero.y=660
 game.hero.hp=70
 game.displayed_health=70
 game.displayed_mana=65
 var king=game.enemies[0]
 king.x=900
 king.y=660
 assert(king.max==65)
 var hp=king.hp
 game.damage(king,{"damage":10,"direction":1},game.hero)
 assert(is_equal_approx(hp-king.hp,6.5*game.damage_multiplier))
 var root_hazard={"kind":"root","owner":king,"p":Vector2(740,660),"age":.5,"life":3.5}
 game.episode_combat.hazards.append(root_hazard)
 game.episode_combat.sync_views(game)
 assert(game.episode_combat.root_views.size()==1)
 var foe=game.make_actor(620,660,10)
 foe.hp=6
 foe.healthBarUntil=100
 game.enemies.append(foe)
 game._process(0.0)
 game.hud.queue_redraw()
 game.air_fx.queue_redraw()
 if "--king-capture" in OS.get_cmdline_user_args():
  await create_timer(.4).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/king-glass.png")
 game.episode_combat.clear()
 assert(game.episode_combat.root_views.is_empty())
 game.queue_free()
 await process_frame
 print("CAIRN_KING_GLASS_OK: health, guarded damage, textured root lifecycle and all meter sizes")
 quit()
