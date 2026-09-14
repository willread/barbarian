class_name CairnEnemies
extends RefCounted
var m: CairnMechanics
var roster: Dictionary
const HEALTH_SCALE={"legion":0.70,"shield":0.70}
func _init(mechanics: CairnMechanics, data: Dictionary):
	m=mechanics
	roster=data.duplicate(true)
	roster["archer"]={"hp":6,"speed":1.05}
	roster.merge({"witch":{"hp":9,"speed":.85},"bearer":{"hp":13,"speed":.9},"king":{"hp":65,"speed":.8},"saint":{"hp":120,"speed":.8}})
	for attack in [
		["mireCast",132,84,-1,0,0],["hagClaw",54,20,27,5,43],["clinkerThrow",92,48,-1,0,0],
		["rootSlam",108,56,62,9,64],["kingSweep",82,38,45,8,72],
		["saintSweep",102,52,60,10,76],["furnaceBlast",110,60,-1,0,0]]:
		m.attacks[attack[0]]={"ticks":attack[1],"from":attack[2],"to":attack[3],"damage":attack[4],"reach":attack[5],"knock":false}

var unlock_order: Array=[]
var variant_order: Array=[]
var wave_variants: Array=[]

func plan(episode: int=1) -> Array:
	unlock_order=["shield","archer","marauder"]
	unlock_order.shuffle()
	variant_order=["brute","swift"]
	variant_order.shuffle()
	wave_variants.clear()
	var result: Array=[]
	var pool=["bone","legion"]
	var newcomer="witch" if episode==2 else "bearer"
	if episode>1:pool.append(newcomer)
	var previous=""
	var seen: Array=[]
	var costs={"bone":1,"legion":2,"shield":3,"archer":3,"marauder":3,"witch":3,"bearer":3}
	for screen in 4:
		if screen>0:pool.append(unlock_order[screen-1])
		for local_wave in 3:
			var focus=pool.pick_random()
			if focus==previous:focus=pool[(pool.find(focus)+1+randi()%(pool.size()-1))%pool.size()]
			# Guarantee unlocked types by the area end, preserving random mixes otherwise.
			var missing=pool.filter(func(kind):return kind not in seen)
			if local_wave==2 and not missing.is_empty():focus=missing.pick_random()
			if episode>1 and screen==0 and local_wave==0:focus=newcomer
			previous=focus
			var budget=6+screen*3+local_wave+randi_range(0,2)
			var encounter: Array=[focus]
			budget-=costs[focus]
			var population_cap=local_wave+2 if screen==0 else 9
			while budget>0 and encounter.size()<population_cap:
				var choices=pool.filter(func(kind):return costs[kind]<=budget and encounter.count(kind)<(3 if kind=="shield" else (2 if kind in ["archer","marauder","witch","bearer"] else 4)))
				if choices.is_empty():break
				var kind=choices.pick_random()
				encounter.append(kind)
				budget-=costs[kind]
			for kind in encounter:
				if kind not in seen:seen.append(kind)
			encounter.shuffle()
			result.append(encounter)
			wave_variants.append([] if screen<2 else ([variant_order[0]] if screen==2 else variant_order.duplicate()))
	result.append([["champion","king","saint"][episode-1]])
	wave_variants.append([])
	return result

static func arena_margin(e: Dictionary) -> float:
	return 140.0*e.size

static func keep_in_arena(e: Dictionary):
	var margin=arena_margin(e)
	if e.x>=margin and e.x<=1440.-margin:e["entered_arena"]=true
	if e.get("entered_arena",false):e.x=clampf(e.x,margin,1440.-margin)

static func shield_limit(area: int) -> int:
	return clampi(area-1,0,3)

func variant(e: Dictionary, allowed: Array=[]):
	if e.kind in ["archer","witch","bearer"]:return
	if e.boss:
		e.speedFactor=.75
		return
	e.variant=allowed.pick_random() if not allowed.is_empty() and randf()<.25 else "regular"
	e.size=1.18 if e.variant=="brute" else (.54 if e.variant=="swift" else 1.0)
	e.speedFactor=2.5625 if e.variant=="swift" else (.68 if e.variant=="brute" else 1.0)
	e.hp=round(e.hp*(1.45 if e.variant=="brute" else (.85 if e.variant=="swift" else 1.0)))
	# Apply after variant rounding so every size receives exactly the same reduction.
	e.hp*=HEALTH_SCALE.get(e.kind,1.0)
	e.max=e.hp

static func damage_scale(e: Dictionary) -> float:
	return .65 if e.get("variant", "regular")=="swift" else (1.35 if e.get("variant", "regular")=="brute" else 1.0)

static func heavy(e: Dictionary) -> bool:
	return e.boss or e.size>=1.15

static func guard_open(e: Dictionary) -> bool:
	return e.kind=="shield" and not e.attack.is_empty() and e.attack.age>=e.attack.from-12

func frame(e: Dictionary) -> int:
	if not e.down.is_empty(): return (14 if e.hp>0 and e.down.ground<=20 else 13) if e.down.ground else 12
	if e.hp<=0: return 13
	if e.hurtTicks or e.recovering: return 11
	if guard_open(e) and e.attack.age<e.attack.from:return 5
	if e.brace and (e.attack.is_empty() or e.attack.age<e.attack.from): return 15
	if e.turnTicks: return 2
	if not e.attack.is_empty():
		var a=e.attack
		if a.age<a.from: return 8 if a.get("overhead",false) else (15 if a.get("bash",false) else 5)
		if a.age<=a.to: return 9 if a.get("overhead",false) else 6
		return 10 if a.get("overhead",false) else 7
	if e.hopTicks: return 3
	return 1+int(e.stride*4)%4 if e.moving else 0

func guarding(e: Dictionary) -> bool:
	return e.kind=="shield" and not guard_open(e) and e.hp>0 and not e.hurtTicks and e.down.is_empty() and not e.recovering and not e.turnTicks and frame(e) in [0,1,2,3,4,15] and (e.attack.is_empty() or e.attack.get("bash",false) and e.attack.age<e.attack.from)

func block(e: Dictionary, a: Dictionary, h: Dictionary) -> bool:
	if not guarding(e) or a.get("magic",false) or (a.get("origin_x",h.x)-e.x)*e.dir<=0: return false
	e.x-=e.dir*(35 if a.get("knock",false) else 10)
	e.brace=14
	e.aiRest=max(e.aiRest,12)
	return true

func intent(e: Dictionary,h: Dictionary,engaged: bool) -> Vector2:
	if e.kind in ["witch","bearer","king","saint"]:return episode_intent(e,h)
	if e.kind=="archer":return archer_intent(e,h)
	var swift=e.get("variant", "regular")=="swift"
	if swift:
		engaged=true
		e.aiRest=max(0,e.aiRest-1)
	# Heavy actors notice positional changes in slower beats; combat health/state stays current.
	if heavy(e):
		e["noticeTicks"]=max(0,e.get("noticeTicks",0)-1)
		if e.noticeTicks==0 or not e.has("noticedPosition"):
			e.noticedPosition=Vector2(h.x,h.y)
			e.noticeTicks=12
		h=h.duplicate()
		h.x=e.noticedPosition.x
		h.y=e.noticedPosition.y
	if e.kind=="legion":
		if heavy(e) and e.attack.is_empty() and not e.hurtTicks and e.down.is_empty():
			var face=1 if h.x>=e.x else -1
			if face!=e.dir:
				e.turnTicks+=1
				if e.turnTicks<24:return Vector2.ZERO
				e.dir=face
				e.aiRest=max(e.aiRest,12)
			e.turnTicks=0
		return m.legion_intent(e,h,engaged)
	for key in ["brace","hopCooldown","rushCooldown"]: e[key]=max(0,e[key]-1)
	if e.hopTicks and e.down.is_empty() and not e.hurtTicks:
		e.hopTicks-=1
		e.height=sin(e.hopTicks/20.0*PI)*9
		e.x-=e.dir*2.4*m.SCALE
		e.moving=true
		return Vector2.ZERO
	if e.hopTicks:
		e.hopTicks=0
		e.height=0
	if e.hp<=0 or not e.down.is_empty() or e.hurtTicks or e.recovering: return Vector2.ZERO
	if e.kind=="champion" and e.hp<=e.max*.5: e.phaseTwo=true
	var x=(h.x-e.x)/m.SCALE
	var y=(h.y-e.y)/m.SCALE
	var face=-1 if x<0 else 1
	if not e.attack.is_empty():
		if e.kind=="marauder" and not heavy(e) and not e.attack.get("rush",false) and not e.rushCombo and e.attack.age<e.attack.from-6:
			e.dir=face
			e.attack.direction=face
		return Vector2.ZERO
	if e.aiRest and e.kind=="marauder": return Vector2.ZERO
	if e.dir!=face:
		e.turnTicks+=1
		if e.turnTicks<(5 if swift else (22 if e.kind=="shield" else 10)+(14 if heavy(e) else 0)): return Vector2.ZERO
		e.dir=face
		e.turnTicks=0
		e.aiRest=max(e.aiRest,16 if heavy(e) else 8)
	else: e.turnTicks=0
	if e.aiRest or h.hp<=0 or not h.down.is_empty(): return Vector2.ZERO
	if not engaged: return Vector2(-face if abs(x)<75 else (face if abs(x)>95 else 0),(1 if e.id%2 else -1) if abs(y)<12 else (-sign(y) if abs(y)>24 else 0))
	if e.kind=="bone" and not swift:
		e.thinkTicks-=1
		if e.thinkTicks<=0:
			e.thinkTicks=25+randi()%45
			e.tactic=randf()
			if not e.hopCooldown and abs(x)<64 and abs(y)<12 and (not h.attack.is_empty() or h.velocityX*face<0) and randf()<.6:
				e.hopTicks=20
				e.hopCooldown=210+randf()*100
				return Vector2.ZERO
		if e.tactic<.2 and abs(x)>38: return Vector2.ZERO
		if e.tactic>.8 and abs(x)<58: return Vector2(-face,0)
	if e.kind=="marauder" and not e.rushCooldown and abs(y)<7 and abs(x)>38 and abs(x)<150:
		m.begin(e,"marauderRush")
		e.rushCooldown=260
		e.rushCombo=true
		return Vector2.ZERO
	var reach=48 if e.kind=="champion" else (34 if e.kind=="shield" else 43)
	if abs(y)<5 and abs(x)<reach:
		var type="boneCut" if e.kind=="bone" else ("shieldBash" if e.kind=="shield" else "marauderChop")
		if e.kind=="champion":
			type="championCheck" if abs(x)<23 else ("championExecution" if e.moveIndex%2 else "championCleave")
			if abs(x)>=23: e.moveIndex+=1
		m.begin(e,type)
		e.aiChain=0
		return Vector2.ZERO
	return Vector2(face if abs(x)>reach-4 else (-face if abs(x)<reach-12 else 0),sign(y) if abs(y)>2 else 0)

func motion(e: Dictionary):
	if e.kind=="legion":
		m.motion(e,0,0)
		return
	var a=e.attack
	if a.is_empty(): return
	e.moving=false
	e.velocityX=0.0
	e.velocityY=0.0
	if a.get("lunge",0) and a.age>=(a.from if a.get("rush",false) else a.from-4) and a.age<=a.to:
		e.velocityX=a.direction*a.lunge
		e.x+=e.velocityX*m.SCALE

func finish(e: Dictionary,a: Dictionary,h: Dictionary):
	if e.kind in ["witch","bearer","king","saint"]:
		e.aiRest=40 if e.boss and e.phaseTwo else 85
		return
	if e.kind=="archer":
		e.aiRest=85+randi()%35
		return
	if e.kind=="legion":
		if a.connected and h.hp>0 and h.down.is_empty() and e.aiChain<2 and a.type!="enemyCharge":
			e.aiChain+=1
			m.begin(e,"enemyFollow" if e.aiChain==1 else "enemyFinish")
		else:
			e.aiChain=0
			e.aiRest=40
		return
	var next=""
	if h.hp>0:
		if a.type=="boneCut" and a.connected and h.down.is_empty(): next="boneFollow"
		if a.type=="shieldBash" and a.connected and randf()<.45 and h.down.is_empty(): next="shieldCut"
		if a.type=="marauderRush": next="marauderChop"
		if a.type=="marauderChop": next="marauderOverhead"
		if a.type=="championCleave" and e.phaseTwo: next="championExecution"
	if next: m.begin(e,next)
	else:
		e.rushCombo=false
		e.aiRest=72 if e.kind=="marauder" else (36 if e.kind=="champion" else 20+randi()%25)

func archer_intent(e: Dictionary,h: Dictionary) -> Vector2:
	if e.hp<=0 or not e.down.is_empty() or e.hurtTicks or e.recovering or not e.attack.is_empty():return Vector2.ZERO
	var dx=h.x-e.x
	var dy=h.y-e.y
	e.dir=1 if dx>=0 else -1
	if h.hp<=0:return Vector2.ZERO
	var margin=arena_margin(e)
	# Walk fully into view before choosing a firing or retreat position.
	if e.x<margin:return Vector2(1,0)
	if e.x>1440.-margin:return Vector2(-1,0)
	e["entered_arena"]=true
	if abs(dx)<310:
		if (e.dir==1 and e.x>margin+2) or (e.dir==-1 and e.x<1440.-margin-2):return Vector2(-e.dir,sign(dy)*.3)
	if abs(dx)>650:return Vector2(e.dir,sign(dy)*.5)
	if abs(dy)>28:return Vector2(0,sign(dy))
	if not e.aiRest:
		e.attack={"type":"archerShot","age":0,"elapsed":0.0,"ticks":58,"from":40,"to":-1,"direction":e.dir,"hits":[],"connected":false,"damage":0,"reach":0}
	return Vector2.ZERO

func episode_intent(e: Dictionary,h: Dictionary) -> Vector2:
	if e.kind=="witch":return hag_intent(e,h)
	if e.boss and e.hp<=e.max*.5:e.phaseTwo=true
	if e.hp<=0 or not e.down.is_empty() or e.hurtTicks or e.recovering or not e.attack.is_empty() or h.hp<=0:return Vector2.ZERO
	var dx=h.x-e.x
	var dy=h.y-e.y
	e.dir=1 if dx>=0 else -1
	var ranged=e.kind in ["witch","bearer"]
	var reach=530.0 if ranged else 270.0
	if not e.aiRest and abs(dx)<reach and abs(dy)<(130 if e.kind=="witch" else 26):
		var type="mireCast" if e.kind=="witch" else "clinkerThrow" if e.kind=="bearer" else ("kingSweep" if e.phaseTwo and e.moveIndex%2 else "rootSlam") if e.kind=="king" else ("furnaceBlast" if e.moveIndex%2 else "saintSweep")
		if ranged and e.get("hazard_live",false):return Vector2.ZERO
		if m.begin(e,type):
			e.attack["target"]=Vector2(h.x,h.y)
			e.moveIndex+=1
		return Vector2.ZERO
	if e.aiRest and not e.phaseTwo and not ranged:return Vector2.ZERO
	var away=ranged and abs(dx)<250 and e.x>160 and e.x<1280
	return Vector2(-e.dir if away else e.dir if abs(dx)>reach-35 else 0,sign(dy) if abs(dy)>12 else 0)*(1.55 if e.phaseTwo else 1.0)

func hag_intent(e: Dictionary,h: Dictionary) -> Vector2:
	if e.hp<=0 or h.hp<=0 or not e.down.is_empty() or e.hurtTicks or e.recovering or not e.attack.is_empty():return Vector2.ZERO
	# Enter the arena, then defend the chosen position without chasing the hero.
	if not e.get("entered_arena",false):
		if e.x<170:return Vector2(1,0)
		if e.x>1270:return Vector2(-1,0)
	var dx=h.x-e.x
	var dy=h.y-e.y
	e.dir=1 if dx>=0 else -1
	e["hag_move_cooldown"]=max(0,e.get("hag_move_cooldown",120)-1)
	if not e.aiRest and abs(dx)<150 and abs(dy)<36:
		m.begin(e,"hagClaw")
		return Vector2.ZERO
	# Retreat while crowded; slip along the lane when a wall blocks backing away.
	if abs(dx)<300 and abs(dy)<65:
		var away=-e.dir
		if (away<0 and e.x<200) or (away>0 and e.x>1240):
			return Vector2(0,1 if e.y<h.y else -1)*.7
		return Vector2(away*.8,signf(e.y-h.y)*.25)
	if e.get("hag_move_ticks",0)>0:
		e.hag_move_ticks-=1
		return e.hag_move_direction
	if e.hag_move_cooldown==0:
		e.hag_move_cooldown=randi_range(150,270)
		e["hag_move_ticks"]=randi_range(25,50)
		var side=-e.dir if abs(dx)<430 else (-1 if e.x>720 else 1)
		e["hag_move_direction"]=Vector2(side*.55,randf_range(-.4,.4))
		return e.hag_move_direction
	if not e.aiRest and abs(dx)<650 and abs(dy)<140 and e.get("mire_count",0)<3:
		if m.begin(e,"mireCast"):e.attack["target"]=Vector2(h.x,h.y)
	return Vector2.ZERO

static func boss_open(e: Dictionary) -> bool:
	return e.phaseTwo or (not e.attack.is_empty() and e.attack.age>max(e.attack.to,e.attack.from+7)) or e.get("open_ticks",0)>0

func separate(actors: Array):
	# Elliptical footprints respect the shallow walkable lane and sprite width.
	# Grounded living enemies separate; airborne reactions and corpses remain free.
	var standing=actors.filter(func(e):return e.hp>0 and e.down.is_empty() and e.height<=0)
	for iteration in 4:
		for i in standing.size():
			for j in range(i+1,standing.size()):
				var a=standing[i]
				var b=standing[j]
				var size=(a.size+b.size)*.5
				var radius=Vector2(122,62)*size
				var delta=Vector2(b.x-a.x,b.y-a.y)/radius
				var distance=delta.length()
				if distance>=1:continue
				var direction=delta/distance if distance>.001 else Vector2(1 if a.id<b.id else -1,0)
				var correction=direction*(1-distance)*radius
				# Attacking/heavier actors yield less, preventing attacks being dragged sideways.
				var wa=(1.0 if a.attack.is_empty() else .2)/a.size
				var wb=(1.0 if b.attack.is_empty() else .2)/b.size
				if a.attack.get("rush",false) or b.attack.get("rush",false):
					correction=Vector2((1 if b.x>=a.x else -1)*(radius.x-abs(b.x-a.x)),0)
				a.x-=correction.x*wa/(wa+wb)
				b.x+=correction.x*wb/(wa+wb)
				a.y=clampf(a.y-correction.y*wa/(wa+wb),560,755)
				b.y=clampf(b.y+correction.y*wb/(wa+wb),560,755)
