extends SceneTree
# Manual visual review: all sixteen integrated weapon poses through the runtime renderer.
class Sheet extends Node2D:
	var art=CairnArt.new()
	func _draw():
		draw_rect(Rect2(0,0,1600,1600),Color("303035"))
		for i in 16:
			var origin=Vector2((i%4)*400+170,(i/4)*400+355)
			var actor={"player":false,"kind":"champion","gearDropped":false,"attack":{},"down":{},"brace":false}
			var pose=["enemy-champion-v1",i]
			var cell=Node2D.new()
			cell.position=origin
			add_child(cell)
			cell.draw.connect(func():
				art.paint_body(cell,actor,pose)
				art.paint_weapon(cell,actor,pose,false))
			draw_string(ThemeDB.fallback_font,origin+Vector2(-160,-325),str(i),HORIZONTAL_ALIGNMENT_LEFT,-1,24)
func _init():call_deferred("run")
func run():
	var viewport=SubViewport.new()
	viewport.size=Vector2i(1600,1600)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	if "--whirlwind" in OS.get_cmdline_user_args():
		var art=CairnArt.new()
		var m=CairnMechanics.new(art.data.attacks)
		CairnEnemies.new(m,art.data.roster)
		for i in 6:
			var actor=m.make(i+1,260+(i%3)*520,600+(i/3)*750,100)
			actor.kind="champion";actor.boss=true
			m.begin(actor,"wardenWhirlwind")
			actor.attack.age=[42,90,94,98,102,240][i]
			var view=load("res://scripts/fighter_view.gd").new()
			view.art=art;view.actor=actor
			viewport.add_child(view)
			view.update_view(-1)
	else:viewport.add_child(Sheet.new())
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("E:/Cairn-build-tools/warden-whirlwind.png" if "--whirlwind" in OS.get_cmdline_user_args() else "E:/Cairn-build-tools/champion-runtime.png")
	quit()
