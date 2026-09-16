extends RefCounted
# Episode hazards share the normal damage path, but keep their own visible tells.
var hazards: Array=[]
const BOMB_RADIUS=Vector2(250,180)
const BOMB_GRAVITY=900.0
const BOMB_FLIGHT=.45
const BOMB_FUSE=.7875
const SAINT_BOMB_FUSE=1.6 # Midpoint tuning: about 1.15 seconds on the floor.
const SAINT_THROW_INTERVAL=18 # Three tenths of a second: grab, load, release, return.

static func bomb_height(h: Dictionary) -> float:
	if h.reflected or h.get("bouncing",false):
		var t=h.get("flight_age",0.0)
		return maxf(0,h.get("launch_height",0.0)+h.get("launch_speed",430.0)*t-.5*h.get("gravity",BOMB_GRAVITY)*t*t)
	var progress=minf(h.age/BOMB_FLIGHT,1)
	return lerpf(h.get("throw_height",0.0),0,progress)+sin(progress*PI)*h.get("arc_height",160.0)

var bomb_views: Array=[]
var explosions: Array=[]
var scream_views: Dictionary={}
var furnace_views: Dictionary={}
var root_views: Array=[]
var root_sequences: Array=[]
var root_warning_views: Dictionary={}
const ROOT_INTERVAL=.72
const ROOT_PHASE_TWO_INTERVAL=.60
const ROOT_WARNING=.55
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
	for view in scream_views.values():view.queue_free()
	scream_views.clear()
	for view in furnace_views.values():view.queue_free()
	furnace_views.clear()
	for view in bomb_views+explosions:
		if is_instance_valid(view):view.queue_free()
	bomb_views.clear()
	explosions.clear()
	root_sequences.clear()
	for view in root_warning_views.values():
		if is_instance_valid(view):view.queue_free()
	root_warning_views.clear()
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
	var blasting=[]
	for enemy in game.enemies:
		if enemy.hp<=0 or enemy.attack.get("type","")!="furnaceBlast":continue
		blasting.append(enemy.id)
		if not furnace_views.has(enemy.id):
			var view=preload("res://scripts/saint_flame.gd").new()
			game.arena_clip.add_child(view)
			furnace_views[enemy.id]=view
		furnace_views[enemy.id].configure(enemy)
	for id in furnace_views.keys():
		if id not in blasting:
			furnace_views[id].queue_free()
			furnace_views.erase(id)
	var screaming=[]
	for enemy in game.enemies:
		if enemy.hp<=0 or enemy.attack.get("type","")!="hellScream":continue
		screaming.append(enemy.id)
		if not scream_views.has(enemy.id):
			var view=preload("res://scripts/bearer_scream.gd").new()
			game.arena_clip.add_child(view)
			scream_views[enemy.id]=view
		scream_views[enemy.id].configure(enemy)
	for id in scream_views.keys():
		if id not in screaming:
			scream_views[id].queue_free()
			scream_views.erase(id)
	for h in hazards:
		if h.kind!="clinker":continue
		if not h.has("bomb_view"):
			h.bomb_view=preload("res://scripts/clinker_visual.gd").new()
			game.arena_clip.add_child(h.bomb_view)
			bomb_views.append(h.bomb_view)
		h.bomb_view.configure(h)
	for i in range(bomb_views.size()-1,-1,-1):
		var view=bomb_views[i]
		if not hazards.any(func(h):return h.get("bomb_view")==view):
			view.queue_free()
			bomb_views.remove_at(i)
	for i in range(explosions.size()-1,-1,-1):
		explosions[i].advance(dt)
		if explosions[i].age>=2.4:
			explosions[i].queue_free()
			explosions.remove_at(i)
	var warning_ids=[]
	for enemy in game.enemies:
		var a=enemy.attack
		if enemy.hp>0 and a.get("type","")=="rootSlam" and a.age<a.from:
			var id="tell-%d"%enemy.id
			show_root_warning(game,id,a.target,float(a.age)/a.from,1.0)
			warning_ids.append(id)
	for h in hazards:
		if h.kind!="root" or h.owner.hp<=0:continue
		if not h.has("warning_id"):
			next_mire_id+=1
			h.warning_id="root-%d"%next_mire_id
		show_root_warning(game,h.warning_id,h.p,clampf(1+h.age/ROOT_WARNING,0,1),clampf((h.life-h.age)/.4,0,1))
		warning_ids.append(h.warning_id)
	for id in root_warning_views.keys():
		if id not in warning_ids:
			root_warning_views[id].queue_free()
			root_warning_views.erase(id)
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
		if enemy.hp>0 and a.get("type","")=="kingCharge":step_king_charge(game,enemy,a,dt)
		if a.get("type","")=="hellScream":step_scream(game,enemy,a)
		if a.get("type","")=="furnaceBlast":step_furnace(game,enemy,a)
		if a.get("type","")=="saintVolley":step_saint_volley(game,enemy,a)
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
			"clinkerThrow":hazards.append({"kind":"clinker","owner":enemy,"p":Vector2(enemy.x,enemy.y),"start":Vector2(enemy.x,enemy.y),"target":target,"age":0.0,"life":BOMB_FUSE,"reflected":false,"velocity":Vector2.ZERO,"strikes":[]})
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
			if h.age>=.18 and h.age<h.life-.12 and h.age>=h.get("next_hit",0.0) and victim.hp>0 and victim.invTicks==0 and victim.down.is_empty() and victim.height*4.5<size.y*rise-12 and absf(victim.x-h.p.x)<size.x*.40 and absf(victim.y-h.p.y)<52:
				game.damage(victim,{"type":"rootEruption","damage":9,"direction":1 if victim.x>=h.owner.x else -1,"knock":false,"no_stun":true},h.owner)
				# One escape window shared across every root, including later eruptions.
				if victim.hp>0:victim.invTicks=maxi(victim.invTicks,45)
				h.next_hit=h.age+.65
		if h.kind in ["mire","root","rootSweep"] and h.owner.hp<=0:h.life=h.age
		if h.kind!="clinker":continue
		if h.reflected:
			var before=h.p
			var old_height=bomb_height(h)
			advance_bomb(h,dt)
			for enemy in game.enemies:
				var body_radius=Vector2(100,48) if enemy.kind=="saint" else Vector2(65,35)
				var point=Vector2(enemy.x,enemy.y)/body_radius
				var nearest=Geometry2D.get_closest_point_to_segment(point,before/body_radius,h.p/body_radius)
				if enemy.hp>0 and point.distance_to(nearest)<1 and minf(old_height,bomb_height(h))<game.art.HEIGHTS.get(enemy.kind,270)*enemy.size-27:
					h.p=nearest*body_radius
					h.direct_target=enemy.id
					h.life=h.age
					break
		else:
			if h.age<BOMB_FLIGHT:h.p=h.start.lerp(h.target,h.age/BOMB_FLIGHT)
			else:
				var motion_dt=dt
				if not h.get("bouncing",false):
					h.bouncing=true
					h.landed=true
					h.bounce_count=1
					h.p=h.target
					h.flight_age=0.0
					h.launch_height=0.0
					h.launch_speed=120.0
					h.velocity=Vector2(signf(h.target.x-h.start.x)*85,0)
					motion_dt=minf(dt,h.age-BOMB_FLIGHT)
				advance_bomb(h,motion_dt)
		var hero=game.hero
		var a=hero.attack
		if h.age<h.life and not a.is_empty() and a.age>=a.from and a.age<=a.to and not a in h.strikes and h.age>.18 and bomb_height(h)<100+hero.height*4.5:
			var dx=(h.p.x-hero.x)*a.direction
			if dx>=-35 and dx<max(100,a.reach*game.m.SCALE) and abs(hero.y-h.p.y)<42:
				strike_bomb(game,h,a)

		if h.life-h.age<.45 and not h.get("warned",false):
			h.warned=true
			game.audio.play("fire",-12,1.6)
		if h.age>=h.life:detonate(game,h)

	hazards=hazards.filter(func(h):return h.age<h.life)
	var mire=mire_at(game.hero)
	if not mire.is_empty() and game.hero.hp>0:
		game.damage(game.hero,{"type":"mireDrain","damage":MIRE_DRAIN*dt,"direction":1 if game.hero.x>=mire.owner.x else -1,"continuous":true,"no_stun":true,"knock":false},mire.owner)


func step_saint_volley(game,enemy: Dictionary,a: Dictionary):
	if enemy.hp<=0:return
	if not a.has("volley_targets"):
		a.volley_count=3 if enemy.phaseTwo else 2
		a.volley_targets=saint_volley_targets(game,a.volley_count)
		a.ticks=a.from+(a.volley_count-1)*SAINT_THROW_INTERVAL+38
		a.volley_released=0
	if a.age<a.from or (int(a.age-a.from)%SAINT_THROW_INTERVAL)<1:
		enemy.dir=1 if game.hero.x>=enemy.x else -1
		a.direction=enemy.dir
	if a.age<a.from:return
	var due=mini(a.volley_count,1+int(a.age-a.from)/SAINT_THROW_INTERVAL)
	while a.volley_released<due:
		var point=a.volley_targets[a.volley_released]
		var start=Vector2(enemy.x+enemy.dir*305*enemy.size,enemy.y)
		# Every core travels outward from the hand, never back through his body.
		point.x=maxf(point.x,start.x+30) if enemy.dir>0 else minf(point.x,start.x-30)
		hazards.append({"kind":"clinker","owner":enemy,"p":start,"start":start,"target":point,"age":0.0,"life":SAINT_BOMB_FUSE,"throw_height":325.0*enemy.size,"arc_height":55.0,"reflected":false,"velocity":Vector2.ZERO,"strikes":[]})
		a.volley_released+=1
		game.audio.play("heavy_hit",-8,1.15)

func saint_volley_targets(game,count: int) -> Array:
	var targets: Array=[]
	for i in count:
		# Stratified random spread; one counterable core stays near the player's lane.
		var point=Vector2(clampf(game.hero.x+randf_range(-100,100),110,1330),game.hero.y) if i==0 else Vector2(110+(1220.0/count)*(i+randf()),randf_range(600,735))
		for attempt in 12:
			if not targets.any(func(other):return (point-other).length()<115):break
			point=Vector2(randf_range(110,1330),randf_range(600,735))
		var probe={"x":point.x,"y":point.y}
		game.background.constrain(probe)
		point=Vector2(probe.x,probe.y)
		targets.append(point)
	return targets

func step_furnace(game,enemy: Dictionary,a: Dictionary):
	if enemy.hp<=0:return
	if not a.get("warned",false):
		a.warned=true
		game.audio.play("roar",-5,.55)
	if a.age==a.from:
		game.audio.play("death_fire",-2,.65)
		game.shake=maxf(game.shake,7)
	var hero=game.hero
	if hero.hp>0 and hero.invTicks==0 and hero.down.is_empty() and preload("res://scripts/saint_flame.gd").hits(enemy,hero):
		var before=hero.hp
		game.damage(hero,{"type":"furnaceBlast","damage":6,"direction":a.direction,"knock":true,"push":4.0},enemy)
		if hero.hp<before:hero.invTicks=maxi(hero.invTicks,55)

func step_scream(game,enemy: Dictionary,a: Dictionary):
	if enemy.hp<=0:return
	if a.age<a.from:
		if not a.get("warned",false):
			a.warned=true
			game.audio.play("roar",-9,.65)
		return
	if a.age==a.from:
		game.audio.play("death_fire",-4,.7)
		game.audio.play("roar",-3,.8)
		game.shake=maxf(game.shake,5)
	if a.age>a.to or a.get("scorched",false):return
	var hero=game.hero
	if hero.hp>0 and hero.invTicks==0 and hero.down.is_empty() and preload("res://scripts/scream_shape.gd").hits(enemy,hero,a.age):
		var before=hero.hp
		game.damage(hero,{"type":"hellScream","damage":11,"direction":a.direction,"knock":true,"push":3.5},enemy)
		if hero.hp<before:
			a.scorched=true
			hero.invTicks=maxi(hero.invTicks,45)

func strike_bomb(game,h: Dictionary,a: Dictionary):
	if a.get("dive",false):return
	var hero=game.hero
	var pose_actor=hero.duplicate()
	pose_actor.dir=a.direction
	var tip=game.art.weapon_tip(pose_actor,game.art.pose(pose_actor))
	var charge=a.type=="charge"
	var heavy=hero.weapon=="axe"
	# The visual centre leaves the actual animated weapon tip, at blade height.
	h.p=Vector2(tip.x+a.direction*18.0,hero.y)
	h.launch_height=maxf(0,hero.y-tip.y-27.0)
	h.reflected=true
	h.landed=false
	h.bounce_count=0
	h.flight_age=0.0
	h.gravity=3200.0
	h.launch_speed=330.0 if charge else (310.0 if heavy else 290.0)
	h.strikes.append(a)
	# Transfer swing and body momentum, while retaining a little incoming motion.
	var carry=clampf(hero.get("velocityX",0.0)*game.m.SCALE*60.0,-250,250)
	var speed=1180.0 if charge else (980.0 if heavy else 880.0)
	h.velocity=Vector2(a.direction*speed+carry*.35+h.velocity.x*.12,0)
	h.spin_velocity=a.direction*(11.0 if charge else 8.0)
	game.burst(tip.x,tip.y,18,Color("ffc17b"))
	game.audio.play("shield",-5,.65)
	game.audio.play("heavy_hit",-5,.72)
	game.shake=maxf(game.shake,6.0 if charge else 4.0)
	game.bomb_hit_pause=maxf(game.bomb_hit_pause,.045 if charge else .032)

func advance_bomb(h: Dictionary,dt: float):
	# Resolve floor contacts analytically, retaining the rest of the frame for rolling.
	var remaining=dt
	var gravity=h.get("gravity",BOMB_GRAVITY)
	for contact in 5:
		if remaining<=0:break
		var height=bomb_height(h)
		var vertical=h.get("launch_speed",430.0)-gravity*h.get("flight_age",0.0)
		if height<=.01 and vertical<=1:
			var travel=h.velocity*(1-exp(-remaining*5.0))/5.0
			h.p+=travel
			h.rotation=h.get("rotation",0.0)+travel.x/24.0
			h.velocity*=exp(-remaining*5.0)
			break
		var impact=maxf(0,(vertical+sqrt(vertical*vertical+2*gravity*height))/gravity)
		var step_time=minf(remaining,impact)
		var travel=h.velocity*step_time
		h.p+=travel
		h.rotation=h.get("rotation",0.0)+h.get("spin_velocity",h.velocity.x/70.0)*step_time
		h.flight_age=h.get("flight_age",0.0)+step_time
		remaining-=step_time
		if step_time>=impact:
			h.landed=true
			h.bounce_count=h.get("bounce_count",0)+1
			var rebound=minf(absf(vertical-gravity*impact)*.52,sqrt(2*gravity*8.0))
			h.launch_height=0.0
			h.launch_speed=rebound if rebound>12 and h.bounce_count<5 else 0.0
			h.flight_age=0.0
			h.velocity*=.48
			h.spin_velocity=h.get("spin_velocity",0.0)*.65

func bomb_landing(h: Dictionary) -> Vector2:
	if not h.reflected and not h.get("bouncing",false):return h.target
	var height=bomb_height(h)
	var gravity=h.get("gravity",BOMB_GRAVITY)
	var vertical=h.get("launch_speed",430.0)-gravity*h.get("flight_age",0.0)
	var remaining=maxf(0,(vertical+sqrt(vertical*vertical+2*gravity*height))/gravity)
	return h.p+h.velocity*remaining

func avoid_bombs(game,enemy: Dictionary) -> Variant:
	if enemy.kind=="saint":return null # Armored boss holds his ground for bomb counters.
	# React only after actual floor contact, including during settling bounces.
	if enemy.hp<=0 or enemy.hurtTicks or enemy.recovering or not enemy.down.is_empty():return null
	var threats=[]
	for h in hazards:
		if h.kind=="clinker" and h.get("landed",false) and h.age<h.life:threats.append(bomb_landing(h))
	var point=Vector2(enemy.x,enemy.y)
	var footprint=BOMB_RADIUS+Vector2(40,25)
	var danger=Vector2.ZERO
	var nearest=INF
	for target in threats:
		var distance=((point-target)/footprint).length()
		if distance<1.0 and distance<nearest:
			nearest=distance
			danger=target
	if nearest==INF:return null
	if not enemy.attack.is_empty():
		if enemy.attack.age>=enemy.attack.from-6 and enemy.attack.age<=max(enemy.attack.from,enemy.attack.to):return null
		game.m.interrupt_attack(enemy)
	var best=point
	var cost=INF
	for i in 16:
		var angle=TAU*i/16.0
		var candidate=danger+Vector2(cos(angle),sin(angle))*footprint*1.12
		var probe={"x":clampf(candidate.x,game.e_ai.arena_margin(enemy),1440-game.e_ai.arena_margin(enemy)),"y":clampf(candidate.y,560,755)}
		game.background.constrain(probe)
		candidate=Vector2(probe.x,probe.y)
		var penalty=0.0
		for target in threats:
			penalty+=maxf(0,1.08-((candidate-target)/footprint).length())*3000
		var score=point.distance_to(candidate)+penalty
		if score<cost:
			cost=score
			best=candidate
	var direction=point.direction_to(best)
	if absf(direction.x)>.2:enemy.dir=1 if direction.x>0 else -1
	enemy.brace=0
	return direction*1.85

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

func draw_ground(_game,_node: Node2D):
	pass # Hazards own their textured, depth-sorted views.

func draw_air(_node: Node2D):
	pass # Bomb bodies now use a lit, textured procedural surface.

func detonate(game,h: Dictionary):
	if h.get("detonated",false):return
	h.detonated=true
	var effect=preload("res://scripts/clinker_explosion.gd").new()
	effect.position=h.p-Vector2(0,bomb_height(h))
	effect.z_index=int(h.p.y)*2+2
	game.arena_clip.add_child(effect)
	explosions.append(effect)
	var victims=game.enemies.duplicate()
	if not h.reflected:victims.append(game.hero)
	for victim in victims:
		var direct=h.reflected and h.get("direct_target",-1)==victim.id
		if victim.kind=="saint" and not direct:continue
		var delta=Vector2(victim.x,victim.y)-h.p
		var distance=(delta/BOMB_RADIUS).length()
		if victim.hp<=0 or distance>1 or victim.invTicks>0 or not victim.down.is_empty() or victim.height>55:continue
		var before_hp=victim.hp
		if not victim.player:
			victim["open_ticks"]=90
			game.m.interrupt_attack(victim)
		var direction=1 if delta.x>=0 else -1
		game.damage(victim,{"type":"clinker","area_blast":true,"direct_bomb":direct,"damage":(2.0 if victim.player else 1.0)*lerpf(18 if h.reflected else 14,8,distance),"origin_x":h.p.x,"direction":direction,"knock":true,"push":3.0,"reflected":h.reflected},game.hero if h.reflected else h.owner)
		if victim.hp<before_hp:
			var outward=Vector2(delta.x,delta.y*2).normalized() if delta.length()>1 else Vector2(direction,0)
			victim.slamPush=outward*lerpf(700,350,distance)
			victim.invTicks=maxi(victim.invTicks,45)
	game.audio.play("landing",-1,.72)
	game.audio.play("death_fire",-5,.75)
	game.shake=maxf(game.shake,12)

func show_root_warning(game,id: String,p: Vector2,progress: float,opacity: float):
	if not root_warning_views.has(id):
		var view=preload("res://scripts/root_crack.gd").new()
		game.arena_clip.add_child(view)
		root_warning_views[id]=view
	root_warning_views[id].configure(p,progress,opacity)

func spawn_root(owner: Dictionary,target: Vector2,age: float,previous: int=-1):
	var variant=randi_range(0,3)
	if variant==previous:variant=(variant+randi_range(1,3))%4
	var heights=[135.0,265.0,215.0,245.0]
	var texture=preload("res://scripts/king_roots.gd").TEXTURES[variant]
	var height=heights[variant]*randf_range(.94,1.08)
	var size=Vector2(height*texture.get_width()/texture.get_height(),height)
	hazards.append({"kind":"root","owner":owner,"p":target,"age":age,"life":1.75,"struck":false,"variant":variant,"flip":-1 if randf()<.5 else 1,"size":size})

func step_king_charge(game,king: Dictionary,a: Dictionary,dt: float):
	if a.age<a.from:
		if not a.get("warned",false):
			a.warned=true
			game.audio.play("roar",-4,.7)
		if a.age%12==0:
			game.burst(king.x+king.dir*32,king.y-5,5,Color("827865"))
			game.audio.play("heavy_hit",-15,.6)
		return
	if a.get("arrived",false):return
	if not a.get("launched",false):
		a.launched=true
		game.audio.play("axe",-2,.55)
		game.shake=maxf(game.shake,5)
	var before=Vector2(king.x,king.y)
	var next=before.move_toward(a.target,1350*dt)
	king.x=next.x;king.y=next.y
	# Apply the same screen margin as the main loop before checking arrival.
	game.e_ai.keep_in_arena(king)
	game.background.constrain(king)
	var after=Vector2(king.x,king.y)
	king.dir=a.direction
	if a.age%4==0:
		game.burst(king.x-king.dir*45,king.y-5,6,Color("827865"))
		game.shake=maxf(game.shake,2)
	var hero=game.hero
	# Swept contact avoids skipping the player at charge speed; one hit per escape.
	var footprint=Vector2(95,55)
	var feet=Vector2(hero.x,hero.y)/footprint
	var nearest=Geometry2D.get_closest_point_to_segment(feet,before/footprint,after/footprint)
	if not a.charge_hit and hero.hp>0 and hero.invTicks==0 and hero.down.is_empty() and hero.height<48 and feet.distance_to(nearest)<1:
		a.charge_hit=true
		game.damage(hero,{"type":"kingCharge","damage":14,"direction":a.direction,"knock":true,"push":7.0},king)
		hero.invTicks=maxi(hero.invTicks,60)
		game.audio.play("heavy_hit",-2,.7)
		game.shake=maxf(game.shake,9)
	if after.distance_to(a.target)<1 or after.distance_to(before)<.1 or after.distance_to(next)>1:
		a.arrived=true
		king["open_ticks"]=90
		game.burst(king.x+king.dir*45,king.y-5,14,Color("827865"))
