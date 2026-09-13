extends SceneTree
func _init():call_deferred("capture")
func capture():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.start_game()
 game.transition=-1
 game.stage_walk=""
 game.change_phase("paused")
 game.pause_cover=1.0
 game._process(2.)
 for i in 110:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/will/Documents/will/barbarian/studies/grip-pause/pause-proposed.png")
 quit()
