extends SceneTree
func _init():call_deferred("render_mask" if "--mask-render" in OS.get_cmdline_user_args() else "check")
func render_mask():
	var viewport=SubViewport.new()
	viewport.size=Vector2i(1440,810)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var backdrop=ColorRect.new()
	backdrop.color=Color.WHITE;backdrop.size=Vector2(1440,810);backdrop.z_index=-20
	viewport.add_child(backdrop)
	var blood=CairnBlood.new()
	viewport.add_child(blood)
	blood.set_walk_mask([[.25,.70],[.75,.70],[.75,.95],[.25,.95]])
	blood.stain(365,650,90)
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	var image=viewport.get_texture().get_image()
	image.save_png("E:/Cairn-build-tools/blood-mask-render.png")
	assert(image.get_pixel(345,650).r>.99,"No ground blood beyond mask edge")
	assert(image.get_pixel(370,650).g<.95,"Ground blood remains visible within mask")
	print("CAIRN_BLOOD_MASK_RENDER_OK")
	quit()
func check():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game);game.set_process(false);game.start_game()
	var blood=game.blood
	blood.reset()
	blood.set_walk_mask([[.25,.70],[.75,.70],[.75,.95],[.50,.95],[.50,.8],[.25,.8]])
	blood.stain(100,600,30);blood.stain(600,720,30)
	assert(blood.marks.is_empty(),"Outside points and concave notch must reject ground blood")
	blood.stain(800,730,100)
	assert(blood.marks.size()==1 and blood.ground_clip.clip_children==CanvasItem.CLIP_CHILDREN_ONLY)
	assert(blood.ground_clip.polygon==blood.walk_polygon,"Clip entire puddle and highlight to same mask")
	for cell in blood.wet:assert(blood.on_ground(Vector2(cell.x*16+8,cell.y*16+8)))
	blood.reset()
	var actor=game.make_actor(800,650,100)
	seed(417);blood.hit(actor,1,true)
	var normal=blood.drops.size()
	blood.reset();seed(417);blood.hit(actor,1,true,5,2.2)
	assert(blood.drops.size()==normal*5 and blood.drop_limit==3500)
	game.enemies=[actor]
	var hp=game.hero.hp
	game.kill_visible_enemies()
	assert(actor.hp==0 and game.hero.hp==hp and game.episode_combat.explosions.size()==1)
	game.queue_free();await process_frame
	print("CAIRN_BLOOD_MASK_OK: concave clipping, wet cells, fivefold blood and TNT explosion")
	quit()
