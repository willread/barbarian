extends Node2D
var game: Node2D
func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	hide()
func _process(_dt):
	visible=game.hitboxes_enabled and game.phase=="playing" and game.pause_cover<=0 and game.transition<0 and not game.menu.visible and not get_tree().paused
	if visible:queue_redraw()
func box(rect: Rect2,color: Color):
	draw_rect(rect,Color(color,.10),true)
	draw_rect(rect,color,false,2.)
func _draw():
	# Read-only projection of mechanics.can_hit; no actor or attack mutation.
	for f in [game.hero]+game.enemies:
		if f.is_empty() or f.hp<=0:continue
		var target=game.m.receiving_rect(f)
		box(Rect2(target.position*game.m.SCALE,target.size*game.m.SCALE),Color.GRAY if f.invTicks or not f.down.is_empty() else Color.CYAN)
		draw_circle(Vector2(f.x,f.y),3,Color.WHITE)
		if f.attack.is_empty():continue
		var a=f.attack
		if a.get("dive",false):continue
		var active=a.age>=a.from and a.age<=a.to
		var strike=game.m.rect(f,a.get("box",[-4,a.reach+4,-48,64 if a.type=="air" else 48]),a.direction)
		var color=Color.RED if active else Color(1,.7,.1,.65)
		box(Rect2(strike.position*game.m.SCALE,strike.size*game.m.SCALE),color)
		# Grounded hits use horizontal overlap plus this independent foot-depth band.
		var lane=minf(a.get("lane",game.m.MELEE_LANE),game.m.MELEE_LANE)
		draw_rect(Rect2(strike.position.x*game.m.SCALE,f.y-lane,strike.size.x*game.m.SCALE,lane*2),Color(color,.35),false,1.)
