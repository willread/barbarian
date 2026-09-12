extends SceneTree
func _init(): run.call_deferred()
func run():
	var wipe=load("res://scripts/death_wipe.gd").new()
	root.add_child(wipe)
	var start=Time.get_ticks_usec()
	for i in 120: wipe.advance(1.0/60)
	print("WIPE_MS_PER_FRAME=",(Time.get_ticks_usec()-start)/120000.0)
	quit()
