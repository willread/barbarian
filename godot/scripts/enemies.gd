class_name CairnEnemies
extends RefCounted
var m: CairnMechanics
var roster: Dictionary
func _init(mechanics: CairnMechanics, data: Dictionary):
	m=mechanics
	roster=data.duplicate(true)
	roster["archer"]={"hp":6,"speed":1.05}

func plan() -> Array:
	var themes=["legion","bone","shield","marauder","archer","shield","archer"]
	themes.shuffle()
	var result=[]
	for i in themes.size():
		var wave=[themes[i],themes[i]]
		for j in 1+int(i/2): wave.append(["legion","bone","shield","marauder","archer"].pick_random())
		wave.shuffle()
		result.append(wave)
	# Guarantee a ranged enemy immediately without increasing first-wave population.
	result[0][0]="archer"
	result.append(["champion"])
	return result

func variant(e: Dictionary):
	if e.kind=="archer":return
	if e.boss:
		e.speedFactor=.75
		return
	var roll=randf()
	e.variant="brute" if roll<.18 else ("swift" if roll<.4 else "regular")
	e.size=1.18 if e.variant=="brute" else (.9 if e.variant=="swift" else 1.0)
	e.speedFactor=1.35 if e.variant=="swift" else (.68 if e.variant=="brute" else 1.0)
	e.hp=round(e.hp*(1.45 if e.variant=="brute" else (.85 if e.variant=="swift" else 1.0)))
	e.max=e.hp

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
	if e.kind=="archer":return archer_intent(e,h)
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
		if e.turnTicks<(22 if e.kind=="shield" else 10)+(14 if heavy(e) else 0): return Vector2.ZERO
		e.dir=face
		e.turnTicks=0
		e.aiRest=max(e.aiRest,16 if heavy(e) else 8)
	else: e.turnTicks=0
	if e.aiRest or h.hp<=0 or not h.down.is_empty(): return Vector2.ZERO
	if not engaged: return Vector2(-face if abs(x)<75 else (face if abs(x)>95 else 0),(1 if e.id%2 else -1) if abs(y)<12 else (-sign(y) if abs(y)>24 else 0))
	if e.kind=="bone":
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
	if abs(dx)<310:
		if (e.dir==1 and e.x> -120) or (e.dir==-1 and e.x<1560):return Vector2(-e.dir,sign(dy)*.3)
	if abs(dx)>650:return Vector2(e.dir,sign(dy)*.5)
	if abs(dy)>28:return Vector2(0,sign(dy))
	if not e.aiRest:
		e.attack={"type":"archerShot","age":0,"elapsed":0.0,"ticks":58,"from":40,"to":-1,"direction":e.dir,"hits":[],"connected":false,"damage":0,"reach":0}
	return Vector2.ZERO

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
