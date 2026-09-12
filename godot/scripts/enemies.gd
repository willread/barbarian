class_name CairnEnemies
extends RefCounted
var m: CairnMechanics
var roster: Dictionary
func _init(mechanics: CairnMechanics, data: Dictionary):
	m=mechanics
	roster=data

func plan() -> Array:
	var themes=["legion","bone","shield","marauder","bone","shield","marauder"]
	themes.shuffle()
	var result=[]
	for i in themes.size():
		var wave=[themes[i],themes[i]]
		for j in 1+int(i/2): wave.append(["legion","bone","shield","marauder"].pick_random())
		wave.shuffle()
		result.append(wave)
	result.append(["champion"])
	return result

func variant(e: Dictionary):
	if e.boss: return
	var roll=randf()
	e.variant="brute" if roll<.18 else ("swift" if roll<.4 else "regular")
	e.size=1.18 if e.variant=="brute" else (.9 if e.variant=="swift" else 1.0)
	e.speedFactor=1.3 if e.variant=="swift" else (.85 if e.variant=="brute" else 1.0)
	e.hp=round(e.hp*(1.45 if e.variant=="brute" else (.85 if e.variant=="swift" else 1.0)))
	e.max=e.hp

static func guard_open(e: Dictionary) -> bool:
	return e.kind=="shield" and not e.attack.is_empty() and e.attack.age>=e.attack.from-6

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
	if not guarding(e) or a.get("magic",false) or (h.x-e.x)*e.dir<=0: return false
	e.x-=e.dir*(35 if a.get("knock",false) else 10)
	e.brace=14
	e.aiRest=max(e.aiRest,12)
	return true

func intent(e: Dictionary,h: Dictionary,engaged: bool) -> Vector2:
	if e.kind=="legion": return m.legion_intent(e,h,engaged)
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
		if e.kind=="marauder" and not e.attack.get("rush",false) and not e.rushCombo and e.attack.age<e.attack.from-6:
			e.dir=face
			e.attack.direction=face
		return Vector2.ZERO
	if e.aiRest and e.kind=="marauder": return Vector2.ZERO
	if e.dir!=face:
		e.turnTicks+=1
		if e.turnTicks<(22 if e.kind=="shield" else 10): return Vector2.ZERO
		e.dir=face
		e.turnTicks=0
		e.aiRest=max(e.aiRest,8)
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
