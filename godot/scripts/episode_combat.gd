extends RefCounted
# Episode hazards share the normal damage path, but keep their own visible tells.
var hazards: Array=[]
var root_views: Array=[]
var root_sequences: Array=[]
const ROOT_INTERVAL=.48
const ROOT_PHASE_TWO_INTERVAL=.38
const ROOT_WARNING=.30
const MireLayout=preload("res://scripts/mire_layout.gd")
const MIRE_SPEED=.10
const MIRE_JUMP_SCALE=.4
const MIRE_DRAIN=2.2+48.0/(100.0*.65) # +1 HP/s at default tuning; about 4 HP/s total.
var mire_views: Dictionary={}
var retiring_mire: Array=[]
var next_mire_id=0

func mire_id(h: Dictionary) -> String:
	if not h.has("mire_id"):
		next_mire_id+=1
		h.mire_id="patch-%d"%next_mire_id
	return h.mire_id

func mire_at(actor: Dictionary) -> Dictionary:
	if actor.height>12:return {}
	for h in hazards:
		if h.kind=="mire" and h.owner.hp>0 and h.age<h.life and MireLayout.contains(h.p,Vector2(actor.x,actor.y)):return h
	return {}

func prepare_actor(actor: Dictionary):
	actor["mire_jump_scale"]=MIRE_JUMP_SCALE if not mire_at(actor).is_empty() else 1.0

func clear():
	hazards.clear()
	root_sequences.clear()
	for view in root_views:
		if is_instance_valid(view):view.queue_free()
	root_views.clear()
	for view in mire_views.values():
		if is_instance_valid(view):view.queue_free()
	mire_views.clear()
	for view in retiring_mire:
		if is_instance_valid(view):view.queue_free()
	retiring_mire.clear()

func sync_views(game,dt: float=0.0):
	for h in hazards:
		if h.kind not in ["root","rootSweep"]:continue
		if not h.has("view"):
			h.view=preload("res://scripts/king_roots.gd").new()
			game.arena_clip.add_child(h.view)
			root_views.append(h.view)
		h.view.position=h.p
		h.view.z_index=int(h.p.y)*2
		h.view.configure(h.age,h.life,h.kind=="rootSweep",h.get("flip",h.owner.dir),h.get("variant",0),h.get("size",Vector2(140,210)))
	for i in range(root_views.size()-1,-1,-1):
		var view=root_views[i]
		if not hazards.any(func(h):return h.get("view")==view):
			view.queue_free()
			root_views.remove_at(i)
	var visible_ids=[]
	for enemy in game.enemies:
		var a=enemy.attack
		if enemy.hp>0 and a.get("type","")=="mireCast" and a.age<a.from:
			var id="warning-%d"%enemy.id
			show_mire(game,id,a.target,0,float(a.age)/a.from,game.clock)
			visible_ids.append(id)
	for h in hazards:
		if h.kind!="mire":continue
		if h.owner.hp<=0:continue
		var warning="warning-%d"%h.owner.id
		if not mire_views.has(mire_id(h)) and mire_views.has(warning):
			mire_views[mire_id(h)]=mire_views[warning]
			mire_views.erase(warning)
		show_mire(game,mire_id(h),h.p,1,h.life-h.age,h.age)
		visible_ids.append(mire_id(h))
	for id in mire_views.keys():
		if id not in visible_ids:
			mire_views[id].retire()
			retiring_mire.append(mire_views[id])
			mire_views.erase(id)
	for view in mire_views.values():view.advance(dt)
	for view in retiring_mire:view.advance(dt)
	for i in range(retiring_mire.size()-1,-1,-1):
		if retiring_mire[i].finished:
			retiring_mire[i].queue_free()
			retiring_mire.remove_at(i)

func show_mire(game,id: String,p: Vector2,mode: int,progress: float,time: float):
	if not mire_views.has(id):
		var view=preload("res://scripts/mire_effect.gd").new()
		view.texture=game.art.texture("mire-oil-v2.png")
		view.position=p
		game.arena_clip.add_child(view)
		mire_views[id]=view
	var view=mire_views[id]
	view.position=p
	view.z_index=0
	view.configure(mode,progress,time)

func place_clump(game,owner,target: Vector2) -> Variant:
	var occupied=[]
	for h in hazards:
		if h.kind=="mire":occupied.append(h.p)
	for view in retiring_mire:occupied.append(view.position)
	for enemy in game.enemies:
		if enemy!=owner and enemy.attack.get("type","")=="mireCast" and enemy.attack.get("placed",false):occupied.append(enemy.attack.target)
	var candidates=[target]
	for ring in range(1,7):
		for direction in [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1),Vector2(1,1),Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1)]:
			candidates.append(target+direction*Vector2(100,35)*ring)
	for point in candidates:
		var valid=true
		for spot in MireLayout.spots(point):
			var center=point+spot.offset
			if center.x<MireLayout.RADIUS.x+7 or center.x>1433-MireLayout.RADIUS.x:valid=false;break
			for edge in [Vector2(0,-MireLayout.RADIUS.y),Vector2(0,MireLayout.RADIUS.y)]:
				var probe={"x":center.x,"y":center.y+edge.y}
				game.background.constrain(probe)
				if absf(probe.y-center.y-edge.y)>1:valid=false
		if valid and not occupied.any(func(other):return MireLayout.overlaps(point,other)):return point
	return null

func step(game,dt: float):
	# Every patch is owned by its caster; none survive that caster's death.
	hazards=hazards.filter(func(h):return h.kind!="mire" or h.owner.hp>0)
	for enemy in game.enemies:
		enemy["open_ticks"]=max(0,enemy.get("open_ticks",0)-1)
		enemy["hazard_live"]=hazards.any(func(h):return h.owner.id==enemy.id)
		enemy["mire_count"]=hazards.filter(func(h):return h.kind=="mire" and h.owner.id==enemy.id).size()
		var a=enemy.attack
		if a.get("type","")=="mireCast" and not a.get("placed",false):
			var placement=place_clump(game,enemy,a.target)
			if placement==null:
				enemy.attack={}
				enemy.aiRest=60
				continue
			a.target=placement
			a.placed=true
		if enemy.hp<=0 or a.is_empty() or a.age!=a.from:continue
		var target=a.get("target",Vector2(enemy.x,enemy.y))
		match a.type:
			"mireCast":hazards.append({"kind":"mire","owner":enemy,"p":target,"age":0.0,"life":8.0})
			"clinkerThrow":hazards.append({"kind":"clinker","owner":enemy,"p":Vector2(enemy.x,enemy.y),"start":Vector2(enemy.x,enemy.y),"target":target,"age":0.0,"life":2.25,"reflected":false,"velocity":Vector2.ZERO,"strikes":[]})
			"kingSweep":
				enemy["open_ticks"]=64
				game.audio.play("axe",-5,.65)
				game.burst(enemy.x+a.direction*160,enemy.y-55,8,Color("847454"))
			"rootSlam":
				enemy["open_ticks"]=90
				game.audio.play("heavy_hit",-5,.7)
				game.shake=maxf(game.shake,4)
				spawn_root(enemy,target,0.0)
				var interval=ROOT_PHASE_TWO_INTERVAL if enemy.phaseTwo else ROOT_INTERVAL
				root_sequences.append({"owner":enemy,"wait":interval-ROOT_WARNING,"interval":interval,"remaining":3 if enemy.phaseTwo else 1,"variant":hazards.back().variant})
			"furnaceBlast":
				# The Saint ejects slag so reflection also works in the solo boss encounter.
				if not hazards.any(func(h):return h.kind=="clinker" and h.owner.id==enemy.id):
					hazards.append({"kind":"clinker","owner":enemy,"p":Vector2(enemy.x,enemy.y),"start":Vector2(enemy.x,enemy.y),"target":target,"age":0.0,"life":2.25,"reflected":false,"velocity":Vector2.ZERO,"strikes":[]})
				var hero=game.hero
				if hero.invTicks==0 and hero.down.is_empty() and abs(hero.y-target.y)<26 and (hero.x-enemy.x)*a.direction>0:
					game.damage(hero,{"type":"furnaceBlast","damage":10,"direction":a.direction,"knock":false},enemy)
				hazards.append({"kind":"blast","owner":enemy,"p":Vector2(enemy.x,target.y),"dir":a.direction,"age":0.0,"life":.3})
	# Each follow-up locks a fresh position, then gives a short ground tell.
	for sequence in root_sequences:
		if sequence.owner.hp<=0:continue
		sequence.wait-=dt
		if sequence.wait<=0 and sequence.remaining>0:
			var target=Vector2(clampf(game.hero.x,90,1350),game.hero.y)
			spawn_root(sequence.owner,target,-ROOT_WARNING,sequence.variant)
			sequence.variant=hazards.back().variant
			sequence.remaining-=1
			sequence.wait+=sequence.interval
	root_sequences=root_sequences.filter(func(s):return s.owner.hp>0 and s.remaining>0)
	for h in hazards:
		h.age+=dt
		if h.kind=="root" and h.owner.hp>0:
			if h.age>=.18 and not h.get("struck",false):
				h.struck=true
				game.burst(h.p.x,h.p.y-8,10,Color("716348"))
				game.audio.play("bone",-12,.65)
			var victim=game.hero
			var size=h.get("size",Vector2(140,210))
			var growth=minf(clampf(h.age/.20,0,1),clampf((h.life-h.age)/.30,0,1))
			var rise=1.0-pow(1.0-growth,3)
			# Keep contact live after eruption; regular invulnerability and a local cooldown prevent rapid repeated hits.
			if h.age>=.18 and h.age<h.life-.12 and h.age>=h.get("next_hit",0.0) and victim.hp>0 and victim.invTicks==0 and victim.down.is_empty() and victim.height*4.5<size.y*rise-12 and absf(victim.x-h.p.x)<size.x*.40 and absf(victim.y-h.p.y)<29:
				game.damage(victim,{"type":"rootEruption","damage":9,"direction":1 if victim.x>=h.owner.x else -1,"knock":false,"no_stun":true},h.owner)
				# One escape window shared across every root, including later eruptions.
				if victim.hp>0:victim.invTicks=maxi(victim.invTicks,45)
				h.next_hit=h.age+.65
		if h.kind in ["mire","root","rootSweep"] and h.owner.hp<=0:h.life=h.age
		if h.kind!="clinker":continue
		if h.reflected:
			h.p+=h.velocity*dt
			for enemy in game.enemies:
				if enemy.hp>0 and abs(enemy.x-h.p.x)<65 and abs(enemy.y-h.p.y)<35:
					enemy["open_ticks"]=90
					game.m.interrupt_attack(enemy)
					game.damage(enemy,{"type":"clinker","damage":15,"direction":int(sign(h.velocity.x)),"knock":false,"reflected":true},game.hero)
					h.life=h.age
					break
		else:h.p=h.start.lerp(h.target,minf(1,h.age/.65))
		var hero=game.hero
		var a=hero.attack
		if not a.is_empty() and a.age>=a.from and a.age<=a.to and not a in h.strikes and h.age>.3:
			var dx=(h.p.x-hero.x)*a.direction
			if dx>=-35 and dx<max(100,a.reach*game.m.SCALE) and abs(hero.y-h.p.y)<42:
				h.reflected=true
				h.strikes.append(a)
				h.velocity=Vector2(a.direction*(1050 if a.type=="charge" else 650),0)
				h.life=max(h.life,h.age+.75)
				game.burst(h.p.x,h.p.y-25,10,Color("ffbd69"))
		if h.age>=h.life:
			game.burst(h.p.x,h.p.y-20,20,Color("ff8b34"))
			if not h.reflected and hero.invTicks==0 and hero.down.is_empty() and hero.height<22 and abs(hero.x-h.p.x)<105 and abs(hero.y-h.p.y)<42:
				game.damage(hero,{"type":"clinker","damage":8,"direction":1 if hero.x>=h.p.x else -1,"knock":false},h.owner)
	hazards=hazards.filter(func(h):return h.age<h.life)
	var mire=mire_at(game.hero)
	if not mire.is_empty() and game.hero.hp>0:
		game.damage(game.hero,{"type":"mireDrain","damage":MIRE_DRAIN*dt,"direction":1 if game.hero.x>=mire.owner.x else -1,"continuous":true,"no_stun":true,"knock":false},mire.owner)

func movement(actor: Dictionary,before: Vector2):
	actor["mired"]=false
	if actor.height>12 or not actor.down.is_empty():return
	for h in hazards:
		if h.kind=="mire" and h.owner.hp>0 and not actor.mired and MireLayout.contains(h.p,Vector2(actor.x,actor.y)):
			actor.x=lerpf(before.x,actor.x,MIRE_SPEED)
			actor.y=lerpf(before.y,actor.y,MIRE_SPEED)
			actor.mired=true

func ellipse(node: Node2D,p: Vector2,r: Vector2,color: Color,filled: bool=false):
	node.draw_set_transform(p,0,r)
	if filled:node.draw_circle(Vector2.ZERO,1,color)
	else:node.draw_arc(Vector2.ZERO,1,0,TAU,48,color,.016,true)
	node.draw_set_transform(Vector2.ZERO)

func draw_ground(game,node: Node2D):
	for e in game.enemies:
		var a=e.attack
		if e.hp<=0 or a.is_empty() or a.age>=a.from or not a.has("target"):continue
		var p=a.target
		var pulse=.35+.35*float(a.age)/a.from
		if a.type=="clinkerThrow":
			ellipse(node,p,Vector2(105,42),Color(.9,.65,.25,pulse))
			ellipse(node,p,Vector2(105,42)*(1.-float(a.age)/a.from),Color(.9,.7,.3,pulse))
		elif a.type=="furnaceBlast":
			node.draw_rect(Rect2(e.x if a.direction>0 else 0,p.y-26,1440-e.x if a.direction>0 else e.x,52),Color(1,.38,.08,pulse*.32))
		elif a.type=="rootSlam":
			root_warning(node,a.target,float(a.age)/a.from)

	for h in hazards:
		var fade=minf(1,(h.life-h.age)*4)
		match h.kind:
			"root":
				if h.age<0:root_warning(node,h.p,clampf(1+h.age/ROOT_WARNING,0,1))
			"clinker":ellipse(node,h.p,Vector2(105,42),Color(1,.4,.07,(.25+.15*sin(h.age*15))*fade))
			"blast":node.draw_rect(Rect2(h.p.x if h.dir>0 else 0,h.p.y-26,1440-h.p.x if h.dir>0 else h.p.x,52),Color(1,.55,.12,fade*.8))

func draw_air(node: Node2D):
	for h in hazards:
		if h.kind!="clinker":continue
		var lift=sin(minf(h.age/.65,1)*PI)*160 if not h.reflected else 70.0
		var p=h.p-Vector2(0,16+lift)
		node.draw_circle(p,15,Color("713622"))
		node.draw_arc(p,12,0,TAU,12,Color("ffc075"),3,true)
		node.draw_line(p+Vector2(-7,-7),p+Vector2(5,8),Color("ffe0a0"),2,true)

func root_warning(node: Node2D,p: Vector2,progress: float):
	# Earth-colored fissures open beneath the locked target; gold edges keep them readable.
	for i in range(7):
		var angle=TAU*i/7.0+.18
		var end=p+Vector2(cos(angle)*62,sin(angle)*31)
		var middle=p.lerp(end,.55)+Vector2(sin(i*3.1)*6,cos(i)*3)
		node.draw_polyline(PackedVector2Array([p,middle,end]),Color(.12,.11,.07,.45+progress*.45),2+progress*3,true)
		if progress>.5:node.draw_line(middle,end,Color(.7,.59,.32,(progress-.5)*1.3),1.5,true)

func spawn_root(owner: Dictionary,target: Vector2,age: float,previous: int=-1):
	var variant=randi_range(0,3)
	if variant==previous:variant=(variant+randi_range(1,3))%4
	var heights=[135.0,265.0,215.0,245.0]
	var texture=preload("res://scripts/king_roots.gd").TEXTURES[variant]
	var height=heights[variant]*randf_range(.94,1.08)
	var size=Vector2(height*texture.get_width()/texture.get_height(),height)
	hazards.append({"kind":"root","owner":owner,"p":target,"age":age,"life":1.75,"struck":false,"variant":variant,"flip":-1 if randf()<.5 else 1,"size":size})
