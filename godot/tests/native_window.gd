extends SceneTree
func _init():
	root.title="CAIRN native resize test"
	create_timer(25.).timeout.connect(quit)
