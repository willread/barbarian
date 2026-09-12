class_name CairnMechanics
extends RefCounted

# Deliberately retain the ROM-derived fixed clock and scene-unit conversion.
const HZ = 59.92274340431231
const STEP = 1.0 / HZ
const SCALE = 4.5
const WEAPONS = {"axe":{"speed":1.22,"damage":1.5,"reach":35},"sword":{"speed":.78,"damage":1.0,"reach":48}}
var attacks: Dictionary

func _init(data: Dictionary = {}):
	attacks = data

func make(id: int, x: float, y: float, hp: float, player: bool = false) -> Dictionary:
	return {"id":id,"x":x,"y":y,"hp":hp,"max":hp,"player":player,"dir":1,"weapon":"axe","kind":"legion","boss":false,"size":1.0,"speedFactor":1.0,"variant":"regular",
	"velocityX":0.0,"velocityY":0.0,"running":false,"runDir":0,"tapDir":0,"tapTicks":-1,"air":{},"height":0.0,"jump":null,"jumpLaunch":5.5,"stagger":0,"hurtTicks":0,"hurtAge":0,"down":{},"recovering":0,"invTicks":0,"attack":{},"lastSlash":0,"aiClock":0,"aiRest":0,"aiChain":0,"aiChargeRest":0,"aiDx":0,"aiDy":0,"moving":false,"stride":0.0,"clock":randf()*4.8,"death":0.0,"recoil":0.0,"hitGlow":0.0,"electricTicks":0,"pickup":{},"gearDropped":false,"burnAge":0.0,"engulf":1.0,"burnSeed":randf()*100,"burnPoints":[],"scorched":false,"trail":0.0,"bootDistance":0.0,"bootCoat":0.0,"bootSide":1,"bootPos":Vector2(x,y),"turnTicks":0,"brace":0,"moveIndex":0,"phaseTwo":false,"hopCooldown":90+randf()*90,"hopTicks":0,"thinkTicks":0,"tactic":0.0,"rushCooldown":50,"rushCombo":false}

func standing(f: Dictionary) -> bool:
	return f.hp > 0 and f.down.is_empty() and f.recovering == 0

func start_jump(f: Dictionary) -> bool:
	if not f.air.is_empty() or not f.attack.is_empty() or f.hurtTicks or not f.down.is_empty() or f.recovering:
		return false
	f.jumpLaunch=5.5
	f.air={"age":0,"launch":5.5,"vz":0.0,"land":0}
	f.jump=0
	f.velocityX=0.0
	f.velocityY=0.0
	f.running=false
	return true

func motion(f: Dictionary, dx: float, dy: float, edge: int = 0, bounded: bool = false):
	if f.hurtTicks or not f.down.is_empty() or f.recovering:
		f.moving=false
		return
	if not f.air.is_empty():
		var a=f.air
		a.age+=1
		f.jump=a.age*STEP
		if a.age==3: a.vz=-a.launch
		elif a.age>3 and f.height>0:
			a.vz=min(8,a.vz+.25)
			f.velocityX=move_toward(f.velocityX,dx*1.5,.0625) if dx else 0.0
		if a.age>=3 and not a.land:
			f.height=max(0,f.height-a.vz)
			f.x+=f.velocityX*SCALE
		if a.age>=3 and f.height==0 and a.vz>=0:
			if not a.land: a.land=3
			if a.land<3:
				f.velocityX=0.0
				a.vz=0.0
			a.land-=1
			if a.land==0:
				f.air={}
				f.jump=null
				f.velocityX=0.0
				f.attack={}
		f.moving=false
	elif not f.attack.is_empty():
		f.moving=false
		var a=f.attack
		if a.type in ["charge","enemyCharge"]:
			f.velocityX=0.0 if a.connected else move_toward(f.velocityX,a.direction*4,.5)
			f.x+=f.velocityX*SCALE
			if a.type=="enemyCharge" or a.age>=1:
				if not a.has("vz"): a.vz=-2.125 if a.type=="charge" else -4.0
				else: a.vz+=.25 if a.type=="enemyCharge" else (.125 if a.vz<0 or a.vz>=2 else .25)
				f.height=max(0,f.height-a.vz)
	else:
		var just_ran=false
		if f.running and dx!=f.runDir:
			f.running=false
			just_ran=true
		if edge:
			if edge==f.tapDir and f.tapTicks>=0:
				f.running=true
				f.runDir=edge
				f.tapDir=0
				f.tapTicks=-1
			elif f.tapDir:
				f.tapDir=0
				f.tapTicks=-1
			else:
				f.tapDir=edge
				f.tapTicks=16
		else:
			f.tapTicks-=1
			if f.tapTicks<0: f.tapDir=0
		if not just_ran:
			var target=dx*(4 if f.running else 1.5)
			if dx and sign(f.velocityX)==dx and abs(f.velocityX)>abs(target): f.velocityX=target
			else: f.velocityX=move_toward(f.velocityX,target,.5)
		f.velocityY=0.0 if f.running or just_ran else dy
		var vx=f.velocityX
		if f.velocityY and vx: vx-=sign(vx)*.5
		f.x+=vx*SCALE
		f.y+=f.velocityY*SCALE
		f.moving=bool(dx or dy or f.velocityX)
		if f.moving: f.stride=fmod(f.stride+1.0/(32 if f.running else 40),1)
		if dx: f.dir=int(dx)
	if bounded:
		var x=clamp(f.x,70,1370)
		if x!=f.x:
			f.velocityX=0.0
			f.running=false
		f.x=x
		f.y=clamp(f.y,560,755)

func select_strike(f: Dictionary, targets: Array) -> String:
	if not f.air.is_empty(): return "air"
	if f.running: return "charge"
	var nearest={}
	for e in targets:
		var distance=(e.x-f.x)*f.dir
		if standing(e) and abs(e.y-f.y)<8*SCALE and distance>=0 and distance<=WEAPONS[f.weapon].reach*SCALE:
			if nearest.is_empty() or distance<abs(nearest.x-f.x): nearest=e
	if not nearest.is_empty() and nearest.stagger>=2 and nearest.hurtTicks>0:
		if abs(nearest.x-f.x)/SCALE+4<44: return "kick" if nearest.stagger>=4 else "pommel"
		return "kick"
	return "slash"

func begin(f: Dictionary, type: String) -> bool:
	if not attacks.has(type) or not standing(f) or not f.attack.is_empty() or f.hurtTicks or (not f.air.is_empty() and type!="air"): return false
	if type=="air" and (f.air.is_empty() or (f.air.vz>=0 and f.height<24)): return false
	var direction=-f.dir if type=="back" else f.dir
	if type=="back": f.dir=direction
	var a=attacks[type].duplicate(true)
	a.merge({"type":type,"age":0,"elapsed":0.0,"direction":direction,"connected":false,"hits":[],"animationRate":1.0},true)
	f.attack=a
	if type=="slash":
		f.lastSlash=int(f.lastSlash)^1
		if not f.lastSlash: a.box=[20,32,-64,40]
	if f.player and type in ["slash","whiff","air","back"]:
		var w=WEAPONS[f.weapon]
		a.weapon=f.weapon
		a.animationRate=1.0/w.speed
		a.ticks=round(a.ticks*w.speed)
		a.from=round(a.from*w.speed)
		a.to=-1 if type=="whiff" else round(a.to*w.speed)
		a.damage*=w.damage
		a.reach=w.reach
		a.box=[0,w.reach,-64,64]
	if type not in ["air","charge"]:
		f.velocityX=0.0
		f.velocityY=0.0
	if type=="enemyCharge": f.velocityX=direction*4
	f.running=false
	f.tapDir=0
	f.tapTicks=-1
	f.moving=false
	return true

func rect(f: Dictionary, box: Array, direction: int) -> Rect2:
	var b=box.map(func(v):return v*f.size)
	return Rect2(f.x/SCALE+(b[0] if direction>0 else -b[0]-b[1]),f.y/SCALE-f.height+b[2],b[1],b[3])

func can_hit(f: Dictionary, e: Dictionary, a: Dictionary) -> bool:
	if e.hp<=0 or not e.down.is_empty() or e.invTicks or abs(e.y-f.y)>=8*SCALE: return false
	var body=[-15,18,-47,47]
	if e.player:
		body=([-16,32,-56,56] if e.stagger==1 else [-8,24,-40,40]) if e.recovering or e.hurtTicks else [-16,28,-60,60]
	elif e.hurtTicks: body=[-19,25,-37,37]
	elif not e.attack.is_empty(): body=[-25,24,-45,45]
	var box=a.get("box",[-4,a.reach+4,-48,64 if a.type=="air" else 48])
	return rect(f,box,a.direction).intersects(rect(e,body,e.dir),true)

func tick_attack(f: Dictionary, targets: Array, hit: Callable) -> Dictionary:
	if f.attack.is_empty(): return {}
	var a=f.attack
	a.age+=1
	a.elapsed=a.age*STEP
	f.dir=a.direction
	if a.age>=a.from and a.age<=a.to:
		for e in targets:
			if not e.id in a.hits and can_hit(f,e,a):
				a.hits.append(e.id)
				a.connected=true
				hit.call(e,a,f)
	if a.age>=a.ticks:
		f.attack={}
		if f.air.is_empty(): f.height=0.0
		return a
	return {}

func hurt(f: Dictionary, a: Dictionary):
	f.attack={}
	f.running=false
	f.air={}
	f.jump=null
	f.height=0.0
	f.velocityX=0.0
	f.velocityY=0.0
	f.moving=false
	f.hurtAge=0
	f.aiChain=0
	f.recovering=0
	if a.get("knock",false) or f.hp<=0:
		f.down={"age":0,"vz":-4.25 if f.player else -4.0,"vx":a.direction*(2 if f.player else 3.375),"ground":0}
		f.hurtTicks=0
		f.stagger=0
		f.invTicks=0
	else:
		f.stagger=min(4,f.stagger+1)
		f.hurtTicks=(6 if f.stagger==1 else 11) if f.player else (36 if f.stagger==1 else 61)
		if f.player: f.recovering=65
	f.recoil=f.hurtTicks*STEP

func reaction(f: Dictionary):
	for key in ["invTicks","aiRest","aiChargeRest"]:
		if f[key]>0: f[key]-=1
	if not f.down.is_empty():
		var d=f.down
		d.age+=1
		if not d.ground:
			f.x+=d.vx*SCALE
			f.height=max(0,f.height-d.vz)
			d.vz=min(8,d.vz+.25)
			if not f.height and d.vz>=0: d.ground=62 if f.player else 32
		else:
			d.ground-=1
			if d.ground==0:
				if f.hp>0:
					f.down={}
					f.invTicks=96 if f.player else 30
					f.stagger=0
					f.aiRest=20
				else: d.ground=1
	elif f.hurtTicks>0:
		f.hurtTicks-=1
		f.hurtAge+=1
		if not f.hurtTicks and not f.player: f.stagger=0
	elif f.recovering>0:
		f.recovering-=1
		if not f.recovering: f.stagger=0
	f.recoil=f.hurtTicks*STEP

func legion_intent(e: Dictionary, h: Dictionary, engaged: bool) -> Vector2:
	if not standing(e) or e.hurtTicks or not e.attack.is_empty() or e.aiRest or not standing(h): return Vector2.ZERO
	var x=(h.x-e.x)/SCALE
	var y=(h.y-e.y)/SCALE
	e.dir=-1 if x<0 else 1
	var post=33 if engaged else 74
	if engaged and abs(y)<8 and abs(x)<=43:
		var a=attacks.enemy.duplicate(true)
		a.direction=e.dir
		a.type="enemy"
		if can_hit(e,h,a):
			begin(e,"enemy")
			e.aiChain=0
			return Vector2.ZERO
	if engaged and abs(x)>120 and abs(x)<200 and abs(y)<8 and not e.aiChargeRest and not h.invTicks:
		begin(e,"enemyCharge")
		e.aiChargeRest=240
		return Vector2.ZERO
	if e.aiClock%3==0:
		e.aiDx=sign(x) if abs(x)>post+7 else (-sign(x) if abs(x)<post-9 else 0)
		e.aiDy=sign(y) if abs(y)>2 else 0
	e.aiClock+=1
	return Vector2(e.aiDx,e.aiDy)
