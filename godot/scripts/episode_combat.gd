extends RefCounted
# Episode hazards share the normal damage path, but keep their own visible tells.
var hazards: Array=[]

func clear():
	hazards.clear()

func step(game,dt: float):
	for enemy in game.enemies:
		enemy["open_ticks"]=max(0,enemy.get("open_ticks",0)-1)
		enemy["hazard_live"]=hazards.any(func(h):return h.owner.id==enemy.id)
		var a=enemy.attack
		if enemy.hp<=0 or a.is_empty() or a.age!=a.from:continue
		var target=a.get("target",Vector2(enemy.x,enemy.y))
		match a.type:
			"mireCast":hazards.append({"kind":"mire","owner":enemy,"p":target,"age":0.0,"life":5.0})
			"clinkerThrow":hazards.append({"kind":"clinker","owner":enemy,"p":Vector2(enemy.x,enemy.y),"start":Vector2(enemy.x,enemy.y),"target":target,"age":0.0,"life":2.25,"reflected":false,"velocity":Vector2.ZERO,"strikes":[]})
			"rootSlam":hazards.append({"kind":"root","owner":enemy,"p":Vector2(enemy.x+enemy.dir*210,enemy.y),"age":0.0,"life":3.5})
			"furnaceBlast":
				# The Saint ejects slag so reflection also works in the solo boss encounter.
				if not hazards.any(func(h):return h.kind=="clinker" and h.owner.id==enemy.id):
					hazards.append({"kind":"clinker","owner":enemy,"p":Vector2(enemy.x,enemy.y),"start":Vector2(enemy.x,enemy.y),"target":target,"age":0.0,"life":2.25,"reflected":false,"velocity":Vector2.ZERO,"strikes":[]})
				var hero=game.hero
				if hero.invTicks==0 and hero.down.is_empty() and abs(hero.y-target.y)<26 and (hero.x-enemy.x)*a.direction>0:
					game.damage(hero,{"type":"furnaceBlast","damage":10,"direction":a.direction,"knock":false},enemy)
				hazards.append({"kind":"blast","owner":enemy,"p":Vector2(enemy.x,target.y),"dir":a.direction,"age":0.0,"life":.3})
	for h in hazards:
		h.age+=dt
		if h.kind in ["mire","root"] and h.owner.hp<=0:h.life=min(h.life,h.age+.18)
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

func movement(actor: Dictionary,before: Vector2):
	if actor.height>12 or not actor.down.is_empty():return
	for h in hazards:
		if h.kind=="mire" and h.owner.hp>0 and abs(actor.x-h.p.x)<120 and abs(actor.y-h.p.y)<46:
			actor.x=lerpf(before.x,actor.x,.45)
			actor.y=lerpf(before.y,actor.y,.45)
		if h.kind=="root" and h.owner.hp>0 and abs(actor.y-h.p.y)<60 and abs(actor.x-h.p.x)<28:
			actor.x=h.p.x+(28 if before.x>=h.p.x else -28)

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
		if a.type in ["mireCast","clinkerThrow"]:
			ellipse(node,p,Vector2(120,46) if a.type=="mireCast" else Vector2(105,42),Color(.9,.65,.25,pulse))
			ellipse(node,p,Vector2(120,46)*(1.-float(a.age)/a.from),Color(.9,.7,.3,pulse))
		elif a.type=="furnaceBlast":
			node.draw_rect(Rect2(e.x if a.direction>0 else 0,p.y-26,1440-e.x if a.direction>0 else e.x,52),Color(1,.38,.08,pulse*.32))
		elif a.type=="rootSlam":
			ellipse(node,Vector2(e.x+a.direction*210,e.y),Vector2(28,60),Color(.75,.78,.35,pulse))
	for h in hazards:
		var fade=minf(1,(h.life-h.age)*4)
		match h.kind:
			"mire":
				ellipse(node,h.p,Vector2(120,46),Color(.19,.29,.09,.65*fade),true)
				for i in 4:ellipse(node,h.p+Vector2(sin(i*18.)*65,cos(i*7.)*20),Vector2(20,7)*(1+sin(h.age*3+i)*.12),Color(.65,.68,.3,.4*fade))
			"clinker":ellipse(node,h.p,Vector2(105,42),Color(1,.4,.07,(.25+.15*sin(h.age*15))*fade))
			"root":
				for i in 7:
					var p=h.p+Vector2(sin(i*8.)*13,(i-3)*16)
					node.draw_line(p,p+Vector2(sin(i*9.)*24,-55),Color(.22,.28,.12,fade),9,true)
			"blast":node.draw_rect(Rect2(h.p.x if h.dir>0 else 0,h.p.y-26,1440-h.p.x if h.dir>0 else h.p.x,52),Color(1,.55,.12,fade*.8))

func draw_air(node: Node2D):
	for h in hazards:
		if h.kind!="clinker":continue
		var lift=sin(minf(h.age/.65,1)*PI)*160 if not h.reflected else 70.0
		var p=h.p-Vector2(0,16+lift)
		node.draw_circle(p,15,Color("713622"))
		node.draw_arc(p,12,0,TAU,12,Color("ffc075"),3,true)
		node.draw_line(p+Vector2(-7,-7),p+Vector2(5,8),Color("ffe0a0"),2,true)
