class_name CairnArt
extends RefCounted
var data: Dictionary
var textures: Dictionary={}
var armory: Dictionary={}
const HEIGHTS={"legion":292,"archer":255,"bone":270,"shield":260,"marauder":250,"champion":310,"witch":250,"bearer":260,"king":390,"saint":420}
const NAMES={"bone":"bone-soldier","shield":"shield-revenant","marauder":"axe-marauder","champion":"cairn-champion"}
const ANGLES=[125,125,115,125,115,-35,95,135,-20,135,85,110,100,85,80,-40]
func _init():
	armory=JSON.parse_string(FileAccess.get_file_as_string("res://art/armory.json"))
	data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
	data.atlases["enemy-archer-v1"]=JSON.parse_string(FileAccess.get_file_as_string("res://art/archer-atlas.json"))
	data.atlases["enemy-legion-v1"]=JSON.parse_string(FileAccess.get_file_as_string("res://art/minotaur-atlas.json"))
	data.atlases["hero-eat"]=JSON.parse_string(FileAccess.get_file_as_string("res://art/eat-atlas.json"))
	for kind in ["witch","bearer","king","saint"]:
		data.atlases["enemy-"+kind+"-v1"]=JSON.parse_string(FileAccess.get_file_as_string("res://art/"+kind+"-atlas.json"))
	data.atlases["hero-spin"]=JSON.parse_string(FileAccess.get_file_as_string("res://art/spin-atlas.json"))
	for action in ["walk","attacks"]:
		data.atlases["king-"+action]=JSON.parse_string(FileAccess.get_file_as_string("res://art/king-"+action+"-atlas.json"))

func texture(file: String) -> Texture2D:
	if not textures.has(file): textures[file]=load("res://assets/"+file)
	return textures[file]

func pose(f: Dictionary, spell: int = -1) -> Array:
	if not f.player and f.kind=="king" and f.hp>0 and f.down.is_empty() and not f.hurtTicks and not f.recovering:
		if not f.attack.is_empty():
			var a=f.attack
			if a.type=="kingCharge":
				return ["king-attacks",0 if a.age<a.from-16 else 1] if a.age<a.from else ["king-walk",int((a.age-a.from)*.6)%8] if not a.get("arrived",false) else ["king-attacks",3]
			var frame=0 if a.age<a.from-14 else 1 if a.age<a.from else 2 if a.age<a.from+10 else 3
			return ["king-attacks",frame+(4 if a.type=="rootSlam" else 0)]
		if f.moving:return ["king-walk",int(f.stride*8)%8]
	if f.player and f.get("victory_pose",-1)>=0:
		var salute=int(f.victory_pose)
		return ["hero-cast-unarmed-v1",0 if salute<5 else 1 if salute<9 else 2 if salute<13 else 3 if salute<17 else 4]
	if f.player and f.attack.get("spin",false):return ["hero-spin",min(15,int(max(0,f.attack.age-2)/2.0))%8]
	if f.player and f.diveUsed and not f.air.is_empty():return ["hero-extra-unarmed-v8",8 if f.diveAge<2 else 9 if f.diveAge<4 else 10 if f.weapon=="axe" else 11]
	if f.player and not f.pickup.is_empty() and f.down.is_empty() and not f.hurtTicks: return ["hero-eat",min(7,int(f.pickup.age/.15))]
	if f.player and spell>=0 and f.down.is_empty() and not f.hurtTicks:
		return ["hero-cast-unarmed-v1",0 if spell<5 else 1 if spell<9 else 2 if spell<13 else 3 if spell<17 else 4 if spell<45 else 5 if spell<77 else 6 if spell<84 else 7]
	if not f.player: return ["enemy-"+f.kind+"-v1",enemy_frame(f)]
	var reaction="hero-reactions-unarmed-v8" if f.player else "enemy-combat-v3"
	var offset=8 if f.player else 0
	if not f.down.is_empty():
		var d=f.down
		var frame=(14 if d.ground>10 else 13) if d.ground and f.hp>0 and d.ground<=20 else (15 if d.ground else (13 if d.vz<0 else 14))
		return [reaction,frame-offset]
	if f.hp<=0: return [reaction,12+min(3,int(f.death/(1.2 if f.player else 1.3)*4))-offset]
	if f.recoil>0: return [reaction,8+min(3,int(clamp(f.hurtAge/(11.0 if f.player else 25.0),0,1)*4))-offset]
	if f.recovering>0: return [reaction,11-offset]
	if not f.attack.is_empty():
		var a=f.attack
		var age=a.age*(a.animationRate if a.type in ["air","back"] else 1)
		match a.type:
			"charge","enemyCharge": return ["hero-extra-unarmed-v8",4 if age<3 else 5+min(2,int((age-3)/10))] if f.player else ["enemy-charge-v5",min(3,int(age/9))]
			"air": return ["hero-extra-unarmed-v8",8 if age<4 else 9 if age<7 else 10 if age<9 else 11]
			"pommel": return ["hero-close-unarmed-v8",0 if age<7 else 1 if age<13 else 2 if age<=17 else 3]
			"back": return ["hero-close-unarmed-v8",4 if age<14 else 5 if age<27 else 6 if age<=32 else 7]
			"kick": return ["hero-close-unarmed-v8",8 if age<8 else 9 if age<15 else 10 if age<=20 else 11]
		if f.player: return ["hero-actions-unarmed-v8",4+(0 if age<a.from else 1 if age<=a.to else 2 if age<a.ticks-2 else 3)]
		return ["enemy-attack-v4",0 if age<a.from-8 else 1 if age<a.from else 2 if age<=a.to else 3]
	if f.jump!=null:
		return [reaction,(12 if f.air.age<=2 else 15 if f.air.land else 13 if f.air.vz<0 else 14)-4] if f.player else [reaction,12]
	if f.moving:
		return ["hero-extra-unarmed-v8" if f.running else "hero-walk-unarmed-v8",int(f.stride*4)%4] if f.player else ["enemy-walk-v4",int(f.stride*4)%4]
	return ["hero-actions-unarmed-v8",0] if f.player else ["enemy-walk-v4",0]

func enemy_frame(e: Dictionary) -> int:
	if e.kind in ["witch","bearer","king","saint"]:
		if e.hp<=0:return 7
		if not e.down.is_empty() or e.hurtTicks or e.recovering:return 6
		if e.kind=="witch" and e.get("hazard_live",false) and not e.moving and e.attack.is_empty():return 4
		if not e.attack.is_empty():return 3 if e.attack.age<e.attack.from else 4 if e.attack.age<=e.attack.from+8 else 5
		if e.boss and e.phaseTwo and not e.moving:return 5
		return 1+int(e.stride*4)%2 if e.moving else 0
	if e.kind=="archer":
		if not e.down.is_empty():return 12 if e.down.ground else 10 if e.down.vz<0 else 11
		if e.hp<=0:return 12
		if e.hurtTicks or e.recovering:return 7
		if not e.attack.is_empty():return 8 if e.attack.age<12 else 4 if e.attack.age<22 else 5 if e.attack.age<40 else 6
		return 1+int(e.stride*4)%3 if e.moving else 0
	if not e.down.is_empty(): return (14 if e.hp>0 and e.down.ground<=20 else 13) if e.down.ground else 12
	if e.hp<=0: return 13
	if e.hurtTicks or e.recovering: return 11
	if CairnEnemies.guard_open(e) and e.attack.age<e.attack.from:return 5
	if e.kind=="legion" and e.attack.get("type","")=="enemyCharge":return 15
	if e.brace and (e.attack.is_empty() or e.attack.age<e.attack.from): return 15
	if e.turnTicks: return 2
	if not e.attack.is_empty():
		var a=e.attack
		if a.age<a.from: return 8 if a.get("overhead",false) else (15 if a.get("bash",false) else 5)
		if a.age<=a.to: return 9 if a.get("overhead",false) else 6
		return 10 if a.get("overhead",false) else 7
	if e.hopTicks: return 3
	return 1+int(e.stride*4)%4 if e.moving else 0

func layout(p: Array) -> Dictionary:
	var atlas=data.atlases[p[0]]
	var cel=atlas.cels[int(p[1])]
	var rig=cel.get("rig",{})
	if p[0]=="hero-walk-unarmed-v8":
		rig=rig.duplicate(true)
		# Attack-hand carry sockets, authored in the original 512x768 cells.
		var sockets=[Vector2(145,403),Vector2(151,402),Vector2(157,410),Vector2(158,406)]
		var hand=sockets[int(p[1])]
		rig.grip=[(hand.x-atlas.cellWidth*.5)*rig.scale,(hand.y-cel.top-cel.height)*rig.scale]
		rig.angle=deg_to_rad([55.,58.,52.,56.][int(p[1])])
		rig.behind=false
	return {"atlas":atlas,"cel":cel,"rig":rig}

func weapon_data(f: Dictionary) -> Dictionary:
	if f.get("weapon_skin", "")=="candy_cane":
		var tex=texture("../art/holiday-candy.png")
		return {"file":"../art/holiday-candy.png","width":tex.get_width(),"height":tex.get_height(),"length":126.,"grip":.82,"pivot":.2}
	var skin=f.get("weapon_skin","")
	if f.weapon=="axe" and armory.has(skin):return armory[skin]
	return data.weapons[f.weapon]

func weapon_cel(w: Dictionary) -> Dictionary:
	return w if w.has("file") else data.atlases["weapons-v8"].cels[int(w.frame)]

func weapon_tip(f: Dictionary,p: Array) -> Vector2:
	var l=layout(p)
	var r=l.rig
	var w=weapon_data(f)
	return Vector2(f.x,f.y-f.height*4.5)+Vector2((r.grip[0]+sin(r.angle)*w.length*w.grip)*f.dir,r.grip[1]-cos(r.angle)*w.length*w.grip)

func hit_box(f: Dictionary,p: Array) -> Array:
	var r=layout(p).rig
	var w=weapon_data(f)
	var tip=Vector2(r.grip[0]+sin(r.angle)*w.length*w.grip,r.grip[1]-cos(r.angle)*w.length*w.grip)
	var radius=17 if f.weapon=="axe" else 7
	return [(min(r.grip[0],tip.x)-radius)/4.5,(abs(tip.x-r.grip[0])+radius*2)/4.5,(min(r.grip[1],tip.y)-radius)/4.5,(abs(tip.y-r.grip[1])+radius*2)/4.5]

func body_rect(f: Dictionary,p: Array) -> Rect2:
	var l=layout(p)
	var s=l.rig.scale if f.player else HEIGHTS[f.kind]/data.atlases[p[0]].get("referenceHeight",data.atlases[p[0]].cels[0].height)
	return Rect2((l.cel.left-l.atlas.cellWidth*.5)*s,-l.cel.height*s,l.cel.width*s,l.cel.height*s)

func paint_body(node: Node2D,f: Dictionary,p: Array):
	var l=layout(p)
	var rect=body_rect(f,p)
	var file=l.cel.file
	if f.player and p==["hero-actions-unarmed-v8",0] and f.attack.is_empty() and not f.moving: file="hero-idle-%d.png"%int(fmod(f.clock,4.8)/4.8*48)
	var facing=l.atlas.facing
	node.draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
	node.draw_texture_rect(texture(file),rect,false)
	node.draw_set_transform(Vector2.ZERO)

func has_separate_weapon(f: Dictionary) -> bool:
	return f.player or f.kind not in ["archer","legion","witch","bearer","king","saint"]

func paint_weapon(node: Node2D,f: Dictionary,p: Array,behind: bool):
	if f.gearDropped or not has_separate_weapon(f) or (f.player and not f.pickup.is_empty()): return
	var l=layout(p)
	if f.player:
		if l.rig.behind!=behind: return
		var w=weapon_data(f)
		var cel=weapon_cel(w)
		var width=w.length*cel.width/cel.height*(1.0 if w.has("file") else w.get("width",1))
		node.draw_set_transform(Vector2(l.rig.grip[0],l.rig.grip[1]),l.rig.angle)
		node.draw_texture_rect(texture(cel.file),Rect2(-width*w.get("pivot",.5),-w.length*w.grip,width,w.length),false,Color(1.65,1.65,1.65) if f.get("weapon_skin", "")=="candy_cane" else Color.WHITE)
	elif f.kind!="legion":
		var meta=data.enemyArt.bodySheets[NAMES[f.kind]]
		var s=HEIGHTS[f.kind]/data.atlases[p[0]].cels[0].height
		var right=meta.rightGrip[int(p[1])]
		var left=meta.get("leftGrip",[])
		var shield_hand=left[int(p[1])] if not left.is_empty() else []
		if f.kind=="shield" and p[1]==6 and not f.attack.get("bash",false):
			var temp=right
			right=shield_hand
			shield_hand=temp
		var point=Vector2((right[0]-.5)*l.atlas.cellWidth*s,(right[1]*l.atlas.cellHeight-l.cel.top-l.cel.height)*s)
		var blade_behind=f.kind=="shield" and f.attack.get("bash",false)
		if blade_behind==behind:
			node.draw_set_transform(point,deg_to_rad(ANGLES[int(p[1])]))
			if f.kind=="champion":
				var cel=data.atlases["weapons-v8"].cels[0]
				node.draw_texture_rect(texture(cel.file),Rect2(-182*cel.width/cel.height*.5,-182*.76,182*cel.width/cel.height,182),false)
			else: draw_equipment(node,0 if f.kind=="bone" else 1 if f.kind=="shield" else 2,135 if f.kind=="bone" else 108 if f.kind=="shield" else 145)
		var shield_behind=f.kind=="shield" and ((not f.attack.is_empty() and not f.attack.get("bash",false)) or p[1] in [5,7,8,9,10,14])
		if not shield_hand.is_empty() and shield_behind==behind:
			point=Vector2((shield_hand[0]-.5)*l.atlas.cellWidth*s,(shield_hand[1]*l.atlas.cellHeight-l.cel.top-l.cel.height)*s)
			node.draw_set_transform(point,1.2 if not f.down.is_empty() else -.23 if f.brace else -.3 if f.attack.get("bash",false) and p[1]==6 else 0.0)
			draw_equipment(node,3,158)
	node.draw_set_transform(Vector2.ZERO)
	if f.player and p[0]!="hero-spin" and not behind and not l.rig.behind:
		if p[0]!="hero-walk-unarmed-v8":
			node.draw_texture_rect(texture(l.cel.file.replace(".png","-hands.png")),body_rect(f,p),false)
		if p[0]=="hero-walk-unarmed-v8":
			# Repaint the actual clenched fist over the shaft at the revised socket.
			var body=body_rect(f,p)
			var hand=Vector2(l.rig.grip[0],l.rig.grip[1])
			var patch=Rect2(hand-Vector2(9,9),Vector2(18,18))
			var source=Rect2((patch.position-body.position)/l.rig.scale,patch.size/l.rig.scale)
			node.draw_texture_rect_region(texture(l.cel.file),patch,source)

func draw_equipment(node: Node2D,index: int,height: float):
	var atlas=data.atlases["enemy-equipment-v1"]
	var cel=atlas.cels[index]
	var grip=data.enemyArt.equipment.grips[index]
	var s=height/cel.height
	node.draw_texture_rect(texture(cel.file),Rect2((cel.left-grip[0]*atlas.cellWidth)*s,(cel.top-grip[1]*atlas.cellHeight)*s,cel.width*s,height),false)
