extends Node2D
const MScript=preload("res://scripts/mechanics.gd")
const EScript=preload("res://scripts/enemies.gd")
const ArtScript=preload("res://scripts/art.gd")
const FighterView=preload("res://scripts/fighter_view.gd")
const EnvironmentView=preload("res://scripts/environment.gd")
const BloodScript=preload("res://scripts/blood.gd")
const MenuScript=preload("res://scripts/menu.gd")
const DeathWipe=preload("res://scripts/death_wipe.gd")
var art: CairnArt
var m: CairnMechanics
var e_ai: CairnEnemies
var blood: CairnBlood
var background: Node2D
var menu: Node2D
var hud: Node2D
var overlay: Node2D
var air_fx: Node2D
var ground_fx: Node2D
var views: Dictionary={}
var flame_views: Dictionary={}
var hero: Dictionary
var enemies: Array=[]
var encounters: Array=[]
var gear: Array=[]
var scorches: Array=[]
var sparks: Array=[]
var chicken: Dictionary={}
var chicken_node: Node2D
var used_chickens: Array=[]
var phase="title"
var options=false
var muted=true
var weapon="axe"
var wave=1
var score=0
var kills=0
var magic=0.0
var displayed_health=100.0
var displayed_mana=0.0
var spell=-1
var next_id=0
var clock=0.0
var wave_time=0.0
var accumulator=0.0
var keys: Dictionary={}
var pressed: Dictionary={}
var stage_walk=""
var transition=-1.0
var swapped=false
var wipe: Node2D
var shake=0.0
var font: Font
var serif: Font
var skull_node: Sprite2D
var heat_node: ColorRect
var sound_player: AudioStreamPlayer
var scenery_shade: Node2D
const CLOSE=.35/.49
const OPEN=.45/.49
const HOLD=.15

func _ready():
	if "--enemy-fire-study" in OS.get_cmdline_user_args() or (OS.has_feature("web") and JavaScriptBridge.eval("new URLSearchParams(location.search).has('enemy-fire-study')")):
		get_tree().change_scene_to_file.call_deferred("res://enemy_fire_study.tscn")
		return
	if "--fire-study" in OS.get_cmdline_user_args() or (OS.has_feature("web") and JavaScriptBridge.eval("new URLSearchParams(location.search).has('fire-study')")):
		get_tree().change_scene_to_file.call_deferred("res://fire_study.tscn")
		return
	art=ArtScript.new()
	# Finish loading battle cels before exposing the menu, avoiding first-hit stalls.
	for atlas in art.data.atlases.values():
		for cel in atlas.cels: art.texture(cel.file)
	for i in 48: art.texture("hero-idle-%d.png"%i)
	m=MScript.new(art.data.attacks)
	e_ai=EScript.new(m,art.data.roster)
	font=load("res://assets/anton.ttf")
	serif=load("res://assets/cinzel.ttf")
	background=EnvironmentView.new()
	add_child(background)
	background.setup(art,"valley")
	heat_node=ColorRect.new()
	heat_node.size=Vector2(1440,810)
	heat_node.z_index=-90
	heat_node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	heat_node.material=ShaderMaterial.new()
	heat_node.material.shader=load("res://shaders/heat.gdshader")
	add_child(heat_node)
	scenery_shade=Node2D.new()
	scenery_shade.z_index=-80
	scenery_shade.draw.connect(func():
		var dark=Color("080b0f77")
		var clear=Color("080b0f00")
		var bottom=Color("080b0f44")
		scenery_shade.draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(1440,0),Vector2(1440,243),Vector2(0,243)]),PackedColorArray([dark,dark,clear,clear]))
		scenery_shade.draw_polygon(PackedVector2Array([Vector2(0,243),Vector2(1440,243),Vector2(1440,810),Vector2(0,810)]),PackedColorArray([clear,clear,bottom,bottom])))
	add_child(scenery_shade)
	sound_player=AudioStreamPlayer.new()
	add_child(sound_player)
	blood=BloodScript.new()
	add_child(blood)
	ground_fx=Node2D.new()
	ground_fx.z_index=-5
	ground_fx.draw.connect(draw_ground)
	add_child(ground_fx)
	air_fx=Node2D.new()
	air_fx.z_index=1801
	air_fx.draw.connect(draw_air)
	add_child(air_fx)
	hud=Node2D.new()
	hud.z_index=1900
	hud.draw.connect(draw_hud)
	add_child(hud)
	overlay=Node2D.new()
	overlay.z_index=2000
	overlay.draw.connect(draw_overlay)
	add_child(overlay)
	menu=MenuScript.new()
	add_child(menu)
	menu.setup(art)
	menu.activated.connect(menu_action)
	skull_node=Sprite2D.new()
	skull_node.texture=art.texture("skull-mask.png")
	skull_node.centered=false
	skull_node.scale=Vector2(1440.0/512,810.0/512)
	skull_node.z_index=2040
	skull_node.material=ShaderMaterial.new()
	skull_node.material.shader=load("res://shaders/skull.gdshader")
	skull_node.material.set_shader_parameter("skull",skull_node.texture)
	add_child(skull_node)
	hero=make_actor(720,660,100,true)
	change_phase("title")
	if "--smoke-test" in OS.get_cmdline_user_args(): smoke_test.call_deferred()
	if "--capture" in OS.get_cmdline_user_args(): capture_test.call_deferred()
	if "--effects-test" in OS.get_cmdline_user_args(): effects_test.call_deferred()
	if "--integration-test" in OS.get_cmdline_user_args(): integration_test.call_deferred()

func make_actor(x: float,y: float,hp: float,player: bool=false) -> Dictionary:
	var f=m.make(next_id,x,y,hp,player)
	next_id+=1
	return f

func change_phase(next: String):
	phase=next
	overlay.z_index=2090 if next in ["lost","won","paused"] else 2000
	keys.clear()
	pressed.clear()
	accumulator=0
	menu.visible=phase in ["title","paused","lost","won"]
	if phase=="title":
		get_window().content_scale_size=Vector2i(1440,810)
		options=false
		menu.show_items(["BEGIN","OPTIONS"])
	else:
		get_window().content_scale_size=Vector2i(1440,1062)
		if phase=="paused": menu.show_items(["RESUME BATTLE","SOUND: OFF" if muted else "SOUND: ON","RETURN TO TITLE"],false)
		if phase in ["lost","won"]: menu.show_items(["RISE AGAIN"],false)
	for view in views.values(): view.visible=phase!="title"
	hud.visible=phase!="title"
	blood.visible=phase!="title"
	background.visible=phase!="title"

func menu_action(label: String):
	match label:
		"BEGIN","RISE AGAIN": start_game()
		"OPTIONS":
			options=true
			menu.switch_items(option_labels())
		"BACK":
			options=false
			menu.switch_items(["BEGIN","OPTIONS"])
		"SOUND: ON","SOUND: OFF":
			muted=not muted
			beep(280,.2)
			menu.show_items(option_labels() if phase=="title" else ["RESUME BATTLE","SOUND: OFF" if muted else "SOUND: ON","RETURN TO TITLE"],phase=="title",false)
			menu.select(0 if phase=="title" else 1,false)
		"FULLSCREEN: ON","FULLSCREEN: OFF":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
			menu.show_items(option_labels(),true,false)
			menu.select(1,false)
		"RESUME BATTLE": change_phase("playing")
		"RETURN TO TITLE":
			clear_world()
			if is_instance_valid(wipe): wipe.queue_free()
			wipe=null
			transition=-1
			change_phase("title")

func option_labels() -> Array:
	return ["SOUND: OFF" if muted else "SOUND: ON","FULLSCREEN: ON" if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else "FULLSCREEN: OFF","BACK"]

func clear_world():
	for view in views.values(): view.queue_free()
	for view in flame_views.values(): view.queue_free()
	views.clear()
	flame_views.clear()
	for item in gear: item.node.queue_free()
	gear.clear()
	if is_instance_valid(chicken_node): chicken_node.queue_free()
	chicken={}
	enemies.clear()
	scorches.clear()
	sparks.clear()
	blood.reset()

func start_game():
	clear_world()
	if is_instance_valid(wipe): wipe.queue_free()
	wipe=null
	hero=make_actor(-140,660,100,true)
	hero.weapon=weapon
	wave=1
	score=0
	kills=0
	magic=0
	spell=-1
	displayed_health=100
	displayed_mana=0
	used_chickens.clear()
	encounters=e_ai.plan()
	change_phase("playing")
	spawn_wave()
	begin_walk("enter")
	transition=CLOSE+HOLD
	swapped=true

func spawn_wave():
	for enemy in enemies:
		if views.has(enemy.id): views[enemy.id].queue_free();views.erase(enemy.id)
		if flame_views.has(enemy.id): flame_views[enemy.id].queue_free();flame_views.erase(enemy.id)
	for item in gear: item.node.queue_free()
	gear.clear()
	enemies.clear()
	var next=["valley","swamp","cinder"].pick_random()
	if next!=background.key:
		blood.reset()
		scorches.clear()
	background.setup(art,next)
	for kind in encounters[wave-1]:
		var i=enemies.size()
		var left=wave!=encounters.size() and randf()<.5
		var f=make_actor(-80-i*90 if left else 1520+i*90,660 if wave==encounters.size() else 570+randf()*150,e_ai.roster[kind].hp)
		f.kind=kind
		f.boss=kind=="champion"
		f.dir=1 if left else -1
		e_ai.variant(f)
		enemies.append(f)
	wave_time=0

func begin_walk(kind: String):
	stage_walk=kind
	keys.clear()
	pressed.clear()
	spell=-1
	hero.attack={}
	hero.air={}
	hero.down={}
	hero.pickup={}
	hero.hurtTicks=0
	hero.recovering=0
	hero.recoil=0
	hero.height=0
	hero.running=false
	hero.dir=1
	hero.moving=true
	hero.velocityX=0
	hero.velocityY=0
	if kind=="enter":
		hero.x=-140
		hero.y=660

func can_cast() -> bool:
	return phase=="playing" and magic>=100 and spell<0 and hero.air.is_empty() and hero.attack.is_empty() and hero.down.is_empty() and hero.pickup.is_empty()

func damage(f: Dictionary,a: Dictionary,attacker: Dictionary):
	if f.hp<=0: return
	if not f.player and e_ai.block(f,a,attacker):
		f.x=clamp(f.x,70,1370)
		burst(f.x+f.dir*40,f.y-110,8,Color("cfbd94"))
		beep(380,.08)
		return
	if not f.player and not a.get("magic",false): f.hitGlow=.1
	f.hp=max(0,f.hp-a.damage*(100.0/48 if f.player else 1))
	if a.get("magic",false) and f.hp>0:
		f.attack={}
		f.electricTicks=9
		if f.down.is_empty():
			f.hurtTicks=9
			f.recovering=0
			f.stagger=0
			f.moving=false
			f.velocityX=0
			f.velocityY=0
	if not a.get("continuous",false) or f.hp<=0:
		var impact=f.duplicate()
		var committed=f.kind=="marauder" and not f.attack.is_empty() and f.attack.age>=f.attack.from and f.attack.age<=f.attack.to and not a.get("knock",false)
		var boss_committed=f.kind=="champion" and f.down.is_empty() and (f.attack.is_empty() or f.attack.age<=f.attack.to)
		var saved=f.attack
		var recovery=f.kind=="champion" and not f.attack.is_empty() and f.attack.age>f.attack.to
		var reaction=a.duplicate()
		if boss_committed: reaction.knock=false
		m.hurt(f,reaction)
		if f.hp>0 and (committed or boss_committed):
			f.hurtTicks=0
			f.recoil=0
			f.stagger=0
			f.recovering=0
			f.attack=saved
		elif f.hp>0 and recovery and not reaction.get("knock",false):
			f.hurtTicks=12
			f.recoil=12*m.STEP
			f.stagger=0
			f.aiRest=0
			f.invTicks=30
		if f.hp<=0 and not f.player and not f.down.is_empty(): f.down.vx*=.48
		impact.down=f.down
		blood.hit(impact,a.direction,f.hp<=0)
		if f.hp<=0 and not f.player:
			for i in (4 if f.boss else 1): blood.hit(impact,a.direction,true)
		burst(f.x,f.y-105,12,Color("e97b4f") if f.player else Color("ffc473"))
		shake=5 if a.get("knock",false) else 2
		beep(60 if f.player else 100,.12)
	if f.hp<=0:
		f.death=0
		f.burnAge=0
		f.engulf=.8+randf()*.5
		drop_gear(f)
		if f.player:
			stage_walk=""
			spell=-1
			change_phase("dying")
			wipe=DeathWipe.new()
			add_child(wipe)
		else:
			kills+=1
			score+=1500 if f.boss else 250
	if not f.player and attacker.player and not a.get("magic",false): magic=min(100,magic+6+(8 if f.hp<=0 else 0))

func burst(x: float,y: float,count: int,color: Color):
	for i in count: sparks.append({"x":x,"y":y,"vx":(randf()-.5)*460,"vy":(randf()-.65)*390,"life":.3+randf()*.4,"color":color})

func tick_actor(f: Dictionary,dt: float):
	f.hitGlow=max(0,f.hitGlow-dt)
	f.electricTicks=max(0,f.electricTicks-1)
	f.clock+=dt
	m.reaction(f)
	if not f.down.is_empty(): f.x=clamp(f.x,70,1370)
	if f.hp<=0:
		f.death+=dt
		f.moving=false
		if not f.player and not f.down.is_empty() and f.down.ground:
			f.burnAge+=dt
			if not f.scorched:
				f.scorched=true
				scorches.append({"x":f.x,"y":f.y,"r":(85 if f.boss else 45)*f.size})

func tick(dt: float):
	if stage_walk:
		hero.x+=322*dt
		hero.moving=true
		hero.dir=1
		hero.stride=fmod(hero.stride+1.4*dt/(40*m.STEP),1)
		pressed.clear()
		if stage_walk=="enter" and hero.x>=720:
			hero.x=720
			hero.moving=false
			stage_walk=""
		elif stage_walk=="exit" and hero.x>1580: stage_walk=""
		return
	if transition>=0 or phase not in ["playing","dying"]: return
	blood.step(dt,[hero]+enemies)
	step_gear(dt)
	if phase=="playing": step_chicken(dt)
	if pressed.has(KEY_K) and can_cast():
		if hero.hurtTicks or hero.recovering:
			hero.hurtTicks=0
			hero.hurtAge=0
			hero.recovering=0
			hero.recoil=0
			hero.stagger=0
			hero.invTicks=max(hero.invTicks,24)
		spell=0
		magic=0
	if spell>=0:
		spell+=1
		if spell>=20 and spell<77:
			for f in enemies:
				if f.hp>0 and f.x>=0 and f.x<=1440: damage(f,{"damage":.12,"knock":false,"magic":true,"continuous":true,"direction":1 if f.x>hero.x else -1},hero)
		if spell>=90: spell=-1
	tick_actor(hero,dt)
	for f in enemies: tick_actor(f,dt)
	if phase=="dying":
		pressed.clear()
		return
	var dx=int(keys.has(KEY_D))-int(keys.has(KEY_A))
	var dy=int(keys.has(KEY_S))-int(keys.has(KEY_W))
	var edge=-1 if pressed.has(KEY_A) else 1 if pressed.has(KEY_D) else 0
	if spell<0 and hero.pickup.is_empty():
		if pressed.has(KEY_J) and pressed.has(KEY_SPACE) and hero.air.is_empty(): m.begin(hero,"back")
		elif pressed.has(KEY_SPACE):
			if m.start_jump(hero): beep(160,.12)
		elif pressed.has(KEY_J):
			if m.begin(hero,m.select_strike(hero,enemies)): beep(230,.15)
	var busy=spell>=0 or not hero.pickup.is_empty()
	m.motion(hero,0 if busy else dx,0 if busy else dy,0 if busy else edge,true)
	if hero.attack.has("weapon"):
		var temp=hero.duplicate()
		temp.attack=hero.attack.duplicate()
		temp.attack.age+=1
		hero.attack.box=art.hit_box(hero,art.pose(temp))
	m.tick_attack(hero,enemies,damage)
	pressed.clear()
	var engaged=[]
	for side in [-1,1]:
		var nearest={}
		for f in enemies:
			if f.hp>0 and f.down.is_empty() and sign(f.x-hero.x)==side:
				if nearest.is_empty() or abs(f.x-hero.x)<abs(nearest.x-hero.x): nearest=f
		if not nearest.is_empty(): engaged.append(nearest.id)
	for f in enemies:
		if f.hp<=0: continue
		var intent=e_ai.intent(f,hero,f.id in engaged)
		if not f.attack.is_empty(): e_ai.motion(f)
		elif not f.hurtTicks and f.down.is_empty() and not f.recovering:
			var speed=e_ai.roster[f.kind].speed*f.speedFactor
			f.velocityX=intent.x*speed
			f.velocityY=intent.y*speed
			f.x+=f.velocityX*m.SCALE
			f.y=clamp(f.y+f.velocityY*m.SCALE,560,755)
			f.moving=intent!=Vector2.ZERO
			if f.moving: f.stride=fmod(f.stride+1.0/56,1)
		f.x=clamp(f.x,-180,1620)
		var finished=m.tick_attack(f,[hero],damage)
		if not finished.is_empty(): e_ai.finish(f,finished,hero)
		if phase!="playing": break
	if phase=="playing" and enemies.all(func(f):return f.hp<=0 and f.burnAge>3.4):
		begin_walk("exit")
		transition=0
		swapped=false

func _process(raw: float):
	if not art: return
	raw=min(raw,.25)
	if phase=="dying" and is_instance_valid(wipe):
		wipe.advance(raw)
		if wipe.age>=3.8 and not hero.down.is_empty() and hero.down.ground: change_phase("lost")
	if transition>=0 and phase!="paused":
		transition+=raw
		if not swapped and transition>=CLOSE:
			swapped=true
			if wave==encounters.size():
				stage_walk=""
				change_phase("won")
			else:
				wave+=1
				spawn_wave()
				begin_walk("enter")
		if transition>=CLOSE+HOLD+OPEN: transition=-1
	var frozen=phase in ["paused","lost","won"]
	var dt=0.0 if frozen else raw*(.3 if phase=="dying" and hero.death<1.3 else 1)
	clock+=dt
	if not frozen:
		accumulator+=dt
		while accumulator+1e-10>=m.STEP:
			tick(m.STEP)
			accumulator-=m.STEP
			if phase in ["lost","won"]: break
	displayed_health=lerpf(displayed_health,float(hero.hp),1-exp(-dt*12))
	displayed_mana=lerpf(displayed_mana,magic,1-exp(-dt*12))
	shake=max(0,shake-dt*35)
	background.advance(clock)
	heat_node.visible=background.key=="cinder" and phase!="title"
	scenery_shade.visible=phase!="title"
	heat_node.material.set_shader_parameter("clock",clock)
	skull_node.visible=transition>=0
	if transition>=0:
		var progress=1-transition/CLOSE if transition<CLOSE else 0.0 if transition<CLOSE+HOLD else (transition-CLOSE-HOLD)/OPEN
		skull_node.material.set_shader_parameter("progress",progress)
	for f in [hero]+enemies:
		if not views.has(f.id):
			var view=FighterView.new()
			view.actor=f
			view.art=art
			add_child(view)
			views[f.id]=view
		views[f.id].visible=phase!="title"
		views[f.id].update_view(spell if f.player else -1)
		if flame_views.has(f.id):
			flame_views[f.id].z_index=int(f.y)*2+1
			flame_views[f.id].queue_redraw()
	for s in sparks:
		s.life-=dt
		s.x+=s.vx*dt
		s.y+=s.vy*dt
		s.vy+=450*dt
	sparks=sparks.filter(func(s):return s.life>0)
	var offset=Vector2((randf()-.5)*shake,(randf()-.5)*shake) if phase!="paused" else Vector2.ZERO
	for node in [background,blood,ground_fx,air_fx]: node.position=offset
	for view in views.values(): view.position+=offset
	for node in flame_views.values(): node.position=offset
	for item in gear: item.node.position=offset
	if is_instance_valid(chicken_node): chicken_node.position=offset
	ground_fx.queue_redraw()
	air_fx.queue_redraw()
	hud.queue_redraw()
	overlay.queue_redraw()
	queue_redraw()

func _input(event: InputEvent):
	if event is InputEventKey:
		var code=event.keycode
		if event.pressed and not event.echo and code in [KEY_ESCAPE,KEY_P]:
			if phase=="playing": change_phase("paused")
			elif phase=="paused": change_phase("playing")
			elif phase=="title" and options: menu_action("BACK")
			return
	if phase in ["title","paused","lost","won"]:
		menu.handle(event)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var point=get_global_mouse_position()
		if point.y>810 and point.x>820 and point.x<1030: toggle_weapon()
	if event is InputEventKey:
		var code=event.keycode
		code={KEY_LEFT:KEY_A,KEY_RIGHT:KEY_D,KEY_UP:KEY_W,KEY_DOWN:KEY_S}.get(code,code)
		if not event.pressed: keys.erase(code)
		elif not event.echo and phase=="playing":
			if code==KEY_Q: toggle_weapon()
			if not keys.has(code): pressed[code]=true
			keys[code]=true

func toggle_weapon():
	weapon="sword" if weapon=="axe" else "axe"
	hero.weapon=weapon

func _notification(what: int):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and phase=="playing" and is_instance_valid(menu): change_phase("paused")

func drop_gear(f: Dictionary):
	f.gearDropped=true
	var pieces=[]
	if f.player or f.kind=="champion":
		var w=art.data.weapons[weapon if f.player else "axe"]
		pieces.append([art.data.atlases["weapons-v8"].cels[int(w.frame)].file,w.length if f.player else 182])
	else:
		pieces.append([art.data.atlases["enemy-equipment-v1"].cels[0 if f.kind=="bone" else 1 if f.kind=="shield" else 2].file,108 if f.kind=="shield" else 140])
		if f.kind=="shield": pieces.append([art.data.atlases["enemy-equipment-v1"].cels[3].file,158])
	for piece in pieces:
		var d={"owner":f,"file":piece[0],"h":piece[1],"x":f.x,"y":f.y,"z":90+f.height*4.5,"vx":f.down.get("vx",0)*180+(randf()-.5)*160,"vy":(randf()-.5)*60,"vz":110+randf()*100,"angle":randf()*6,"spin":sign(f.down.get("vx",f.dir))*(2+min(5,abs(f.down.get("vx",0))*1.3)+randf()*3),"ground":false,"points":[]}
		var node=Node2D.new()
		d.node=node
		node.draw.connect(func():draw_gear(d))
		add_child(node)
		gear.append(d)

func step_gear(dt: float):
	for d in gear:
		if not d.ground:
			d.x+=d.vx*dt
			d.y+=d.vy*dt
			d.z+=d.vz*dt
			d.vz-=700*dt
			d.angle+=d.spin*dt
			d.spin*=exp(-dt*.18)
			if d.z<=0:
				d.z=0
				d.ground=true
				d.y=clamp(d.y,555,752)
				d.x=clamp(d.x,30,1410)
		d.node.z_index=int(d.y)*2
		d.node.queue_redraw()
		if not d.owner.player and d.ground and d.owner.burnAge>=.15+d.owner.engulf+.6: d.node.queue_free()
	gear=gear.filter(func(d):return d.owner.player or not d.ground or d.owner.burnAge<.15+d.owner.engulf+.6)

func draw_gear(d: Dictionary):
	var tex=art.texture(d.file)
	var size=Vector2(d.h*tex.get_width()/tex.get_height(),d.h)
	var age=d.owner.burnAge if d.ground and not d.owner.player else 0.0
	var fade=1-clamp((age-.15-d.owner.engulf)/.6,0,1)
	d.node.draw_set_transform(Vector2(d.x,d.y-d.z),d.angle)
	d.node.draw_texture_rect(tex,Rect2(-size*.5,size),false,Color(1,1,1,fade))
	d.node.draw_set_transform(Vector2.ZERO)
	if age>0 and fade>0:
		if d.points.is_empty():
			var image=tex.get_image()
			for i in 3:
				for attempt in 100:
					var uv=Vector2(randf(),randf())
					if image.get_pixel(int(uv.x*(image.get_width()-1)),int(uv.y*(image.get_height()-1))).a>.7:
						d.points.append((uv*size-size*.5).rotated(d.angle))
						break
		for point in d.points: flame(d.node,Vector2(d.x,d.y-d.z)+point,age,fade,.24,1,1,int(d.owner.burnSeed)%4,19,0,0)

func draw_flames(node: Node2D,f: Dictionary):
	if f.hp>0 or f.player or f.burnAge<=0 or f.burnAge>3.3: return
	var age=f.burnAge
	var fade=1-clamp((age-.15-f.engulf)/.6,0,1)
	if f.burnPoints.is_empty():
		var p=art.pose(f)
		var rect=art.body_rect(f,p)
		var image=art.texture(art.layout(p).cel.file).get_image()
		for i in 4:
			for attempt in 100:
				var uv=Vector2(randf(),randf())
				if image.get_pixel(int(uv.x*(image.get_width()-1)),int(uv.y*(image.get_height()-1))).a>.7:
					f.burnPoints.append({"point":rect.position+uv*rect.size,"scale":.55*(.72+randf()*.56),"width":.7+randf()*.6,"stretch":.8+randf()*.5,"variant":(i+int(f.burnSeed))%4,"rate":17+randf()*5,"offset":randf()*8,"phase":randf()*TAU})
					break
	for p in f.burnPoints:
		var point=Vector2(f.x,f.y-f.height*4.5)+p.point*Vector2(f.dir*f.size,f.size)
		flame(node,point,age,fade,p.scale*f.size,p.width,p.stretch,p.variant,p.rate,p.offset,p.phase)

func flame(node: Node2D,point: Vector2,age: float,fade: float,s: float,width: float,stretch: float,variant: int,rate: float,offset: float,seed_value: float):
	var frame=min(63,int(age*rate+offset))
	var source=Rect2((frame%8)*128,int(frame/8)*192,128,192)
	var w=155*s*width*(1+.09*sin(age*3+seed_value))
	var h=230*s*stretch*(1+.12*sin(age*4.11+seed_value))*(.2+.8*fade)*min(1,age/.12)
	if fade>0: node.draw_texture_rect_region(art.texture("fluid-fire-v2-%d.png"%variant),Rect2(point.x-w/2,point.y-h*.95,w,h),source,Color(1,1,1,fade*.9))
	if age>.5:
		node.draw_texture_rect_region(art.texture("fluid-smoke-v1.png"),Rect2(point.x-w/2,point.y-h,w,h),source,Color(1,1,1,.65*(1-clamp(age-2.3,0,1))))

func step_chicken(dt: float):
	wave_time+=dt
	var schedule={2:5,4:7,6:6,8:9}
	if schedule.has(wave) and wave_time>=schedule[wave] and not wave in used_chickens and chicken.is_empty():
		used_chickens.append(wave)
		chicken={"x":90.0,"y":610.0,"dir":1,"age":0.0,"roast":false,"turn":0.0,"hop":0.0,"height":0.0,"flight":false,"picked":false}
		chicken_node=Node2D.new()
		chicken_node.draw.connect(draw_chicken)
		add_child(chicken_node)
	if chicken.is_empty(): return
	var c=chicken
	c.age+=dt
	if not hero.pickup.is_empty():
		var p=hero.pickup
		if hero.hp<=0 or not hero.down.is_empty() or hero.hurtTicks:
			if p.collected: remove_chicken()
			hero.pickup={}
			return
		p.age+=dt
		if p.age>=.28 and not p.collected:
			p.collected=true
			hero.hp=hero.max
		if p.collected:
			c.x=hero.x+hero.dir*52
			c.height=min(16,(p.age-.28)*90)
			c.picked=p.age>.43
		if p.age>=.58:
			remove_chicken()
			hero.pickup={}
			return
	elif c.roast:
		if c.flight:
			c.x+=c.vx*dt
			c.height+=c.vz*dt/4.5
			c.vz-=700*dt
			c.trail-=dt
			if c.trail<=0:
				c.trail=.035
				for i in 2: blood.drops.append({"x":c.x,"y":c.y,"z":max(5,c.height*4.5),"vx":c.vx*(.65+randf()*.25),"vy":(randf()-.5)*35,"vz":c.vz*.6+randf()*35,"gravity":700,"drag":.4,"r":3+randf()*3})
			if c.height<=0:
				c.height=0
				c.flight=false
				c.x=clamp(c.x,50,1390)
				blood.stain(c.x,c.y,16)
		elif hero.hp>0 and hero.down.is_empty() and hero.air.is_empty() and hero.attack.is_empty() and not hero.hurtTicks and spell<0 and abs(hero.x-c.x)<45 and abs(hero.y-c.y)<26:
			hero.dir=1 if c.x>=hero.x else -1
			hero.pickup={"age":0.0,"collected":false}
	else:
		if c.age>10:
			c.x+=c.dir*350*dt
			if c.x< -80 or c.x>1520: remove_chicken();return
		else:
			c.turn-=dt
			if c.turn<=0:
				c.turn=.65+randf()*.7
				c.dir=(1 if c.x>hero.x else -1) if abs(c.x-hero.x)<180 else (-c.dir if randf()<.2 else c.dir)
				c.targetY=575+randf()*150
				if randf()<.28: c.hop=.3
			if c.x<90: c.dir=1
			if c.x>1350: c.dir=-1
			c.x+=c.dir*235*dt
			c.y+=clamp(c.get("targetY",630)-c.y,-60,60)*dt
			c.hop=max(0,c.hop-dt)
			c.height=sin(c.hop/.3*PI)*5
		var a=hero.attack
		if not a.is_empty() and a.age>=a.from and a.age<=a.to and abs(c.y-hero.y)<32:
			var reach=(a.box[0]+a.box[1] if a.has("box") else a.reach)*4.5
			if (c.x-hero.x)*a.direction> -15 and (c.x-hero.x)*a.direction<reach+26:
				c.roast=true
				c.age=0
				c.height=10
				c.flight=true
				c.vx=a.direction*(180+randf()*90)
				c.vz=250+randf()*70
				c.trail=0
	if is_instance_valid(chicken_node):
		chicken_node.z_index=int(c.y)*2
		chicken_node.queue_redraw()

func remove_chicken():
	chicken={}
	if is_instance_valid(chicken_node): chicken_node.queue_free()

func draw_chicken():
	if chicken.is_empty() or chicken.picked: return
	var c=chicken
	var atlas=art.data.atlases["chicken-v1"]
	var cel=atlas.cels[10 if c.roast else 9 if c.hop else int(c.age*16)%8]
	var s=132/atlas.cellWidth
	chicken_node.draw_set_transform(Vector2(c.x,c.y-c.height*4.5),0,Vector2(c.dir,1))
	chicken_node.draw_texture_rect(art.texture(cel.file),Rect2((cel.left-atlas.cellWidth*.5)*s,-cel.height*s,cel.width*s,cel.height*s),false)
	chicken_node.draw_set_transform(Vector2.ZERO)

func draw_ground():
	if phase=="title": return
	for s in scorches: shadow(ground_fx,Vector2(s.x,s.y),s.r,.32,.9)
	for f in [hero]+enemies:
		if not f.player and f.burnAge>.15+f.engulf+.6: continue
		shadow(ground_fx,Vector2(f.x,f.y-2),292*.23+f.height*4.5*.035,.24,max(.12,1-f.height*4.5/450)*.72)

func shadow(node: Node2D,p: Vector2,radius: float,ratio: float,alpha: float):
	node.draw_set_transform(p,0,Vector2(1,ratio))
	for i in range(12,0,-1): node.draw_circle(Vector2.ZERO,radius*i/12.0,Color(.012,.016,.012,alpha*.12*(1.0-i/14.0)))
	node.draw_set_transform(Vector2.ZERO)

func lightning(node: Node2D,start: Vector2,end: Vector2,seed_value: int,progress: float=1):
	var rng=RandomNumberGenerator.new()
	rng.seed=seed_value
	var points=PackedVector2Array([start,end])
	var spread=190.0*.65
	for depth in 6:
		var next=PackedVector2Array()
		for i in points.size()-1:
			next.append(points[i])
			next.append((points[i]+points[i+1])*.5+Vector2((rng.randf()-.5)*spread,0))
		next.append(end)
		points=next
		spread*=.53
	points.resize(max(2,int(ceil(points.size()*clamp(progress,0,1)))))
	for layer in [[8,Color("89baff35")],[3,Color("bfe2ff99")],[1.3,Color("fff9dd")]]: node.draw_polyline(points,layer[1],layer[0],true)
	for i in range(5,points.size()-4,9):
		var side=1 if i%2 else -1
		var direction=sign(end.y-start.y)
		node.draw_polyline(PackedVector2Array([points[i],points[i]+Vector2(side*25,direction*12),points[i]+Vector2(side*38,direction*35)]),Color("c8e5ff88"),.7,true)

func draw_air():
	if phase=="title": return
	for s in sparks:
		var color=s.color
		color.a=clamp(s.life*2,0,1)
		air_fx.draw_rect(Rect2(s.x,s.y,4,2),color)
	for f in enemies:
		if f.hp>0 and f.hp<f.max:
			air_fx.draw_rect(Rect2(f.x-35,f.y-272,70,4),Color("180e0c"))
			air_fx.draw_rect(Rect2(f.x-35,f.y-272,70*f.hp/f.max,4),Color("d89969"))
	if spell>=17 and spell<77:
		var tip=art.weapon_tip(hero,["hero-cast-unarmed-v1",4 if spell<45 else 5])
		var elapsed=(spell-17)*m.STEP
		var cycle=int(elapsed/.16)
		lightning(air_fx,tip,Vector2(tip.x,-55),93417+cycle*104729,(spell-16)/3.0)
		if spell>=20:
			for f in enemies:
				if f.hp>0 and f.x>=0 and f.x<=1440: lightning(air_fx,Vector2(f.x,-55),Vector2(f.x,f.y-100),f.id*7919+cycle*104729,fmod(elapsed,.16)/.04)
	for f in enemies:
		if f.boss and f.hp>0:
			center_text(air_fx,"Cairn Champion · Unbound" if f.phaseTwo else "Cairn Champion",Vector2(720,43),20,Color("e6d2aa"))
			air_fx.draw_rect(Rect2(510,54,420,8),Color("160f0e"))
			air_fx.draw_rect(Rect2(510,54,420*f.hp/f.max,8),Color("ab4935") if f.phaseTwo else Color("9e7750"))

func center_text(node: Node2D,text: String,p: Vector2,size: int,color: Color):
	node.draw_string(serif,p-Vector2(serif.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func draw_hud():
	if phase=="title": return
	var tex=art.texture("hud-bronze-v1.png")
	var s=1440.0/2172
	hud.draw_texture_rect(art.texture("hud-native-frame.png"),Rect2(0,766,1440,296),false)
	hud.draw_set_transform(Vector2(0,810),0,Vector2(s,252.0/380))
	for i in 2:
		var top=70+i*140
		var value=displayed_health if i==0 else displayed_mana
		var colors=[Color("bf221e"),Color("710807")] if i==0 else [Color("269bff"),Color("074891")]
		for row in 77:
			var color=colors[0].lerp(colors[1],row/78.0)
			var inset=max(0,7-min(row,76-row))
			hud.draw_rect(Rect2(298+inset,top+17+row,max(0,min(901-inset,901*clamp(value/100,0,1))-inset),1),color)
		if i==1 and can_cast(): hud.draw_rect(Rect2(298,top+17,901,77),Color(.6,.86,1,.5+.3*sin(clock*5)),false,4)
	var spec=art.data.weapons[weapon]
	var cel=art.data.atlases["weapons-v8"].cels[int(spec.frame)]
	hud.draw_set_transform(Vector2(1400*s,810+193*252.0/380),.5,Vector2(s,252.0/380))
	var width=245*cel.width/cel.height
	hud.draw_texture_rect(art.texture(cel.file),Rect2(-width/2,-122.5,width,245),false)
	hud.draw_set_transform(Vector2.ZERO)
	center_text(hud,"SCORE",Vector2(1758*s,810+83*252.0/380),22,Color("eedbb0"))
	center_text(hud,"%06d"%score,Vector2(1758*s,810+182*252.0/380),52,Color("eedbb0"))
	center_text(hud,"FINAL DUEL" if wave==8 else "THE VALLEY",Vector2(1758*s,810+281*252.0/380),22,Color("eedbb0"))

func draw_overlay():
	if phase=="title": overlay.draw_texture_rect(art.texture("cairn-title-v1.png"),Rect2(0,0,1440,810),false)
	if phase=="paused":
		overlay.draw_rect(Rect2(0,0,1440,1062),Color(.02,.025,.02,.85))
		center_text(overlay,"CAIRN",Vector2(720,260),48,Color("bda06d"))
		center_text(overlay,"The battle waits.",Vector2(720,330),40,Color("e7d5b0"))
	if phase in ["lost","won"]:
		if phase=="won": overlay.draw_rect(Rect2(0,0,1440,1062),Color(.02,.025,.02,.8))
		center_text(overlay,"THE LEGION ENDURES" if phase=="lost" else "THE VALLEY IS FREE",Vector2(720,250),24,Color("bda06d"))
		center_text(overlay,"Even heroes fall." if phase=="lost" else "A legend rises.",Vector2(720,340),66,Color("e7d5b0"))
		center_text(overlay,"%d enemies slain · %d points"%[kills,score],Vector2(720,385),24,Color("e7d5b0"))

func _draw():
	pass

func beep(frequency: float,duration: float):
	if muted: return
	var rate=22050
	var bytes=PackedByteArray()
	bytes.resize(int(rate*duration)*2)
	var phase_value=0.0
	for i in bytes.size()/2:
		var progress=float(i)/(bytes.size()/2)
		phase_value+=frequency*pow(.35,progress)/rate
		var sample=(fmod(phase_value,1)*2-1)*.035*pow(.001/.035,progress)
		bytes.encode_s16(i*2,int(sample*32767))
	var stream=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=rate
	stream.data=bytes
	sound_player.stream=stream
	sound_player.play()

func smoke_test():
	start_game()
	transition=-1
	stage_walk=""
	hero.x=720
	for i in 360: tick(m.STEP)
	print("CAIRN_SMOKE_OK actors=",enemies.size()," health=",hero.hp," mana=",magic)
	get_tree().quit()

func capture_test():
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/title.png")
	start_game()
	transition=-1
	stage_walk=""
	hero.x=620
	for i in enemies.size():
		enemies[i].x=900+i*150
		enemies[i].y=660+i*25
	change_phase("paused")
	phase="playing"
	menu.visible=false
	set_process(false)
	_process(0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/battle.png")
	print("CAIRN_CAPTURE_OK")
	get_tree().quit()

func effects_test():
	start_game()
	transition=-1
	stage_walk=""
	hero.x=500
	hero.weapon="sword"
	weapon="sword"
	for i in enemies.size():
		enemies[i].x=850+i*150
		enemies[i].y=640+i*25
		enemies[i].aiRest=1000
	magic=100
	pressed[KEY_K]=true
	await get_tree().create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/lightning.png")
	for f in enemies: damage(f,{"damage":100,"direction":1,"knock":true},hero)
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/fire.png")
	damage(hero,{"damage":100,"direction":-1,"knock":true},enemies[0])
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/wipe-mid.png")
	await get_tree().create_timer(3.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/wipe-end.png")
	print("CAIRN_EFFECTS_OK fps=",Engine.get_frames_per_second())
	get_tree().quit()

func integration_test():
	start_game()
	transition=-1
	stage_walk=""
	hero.x=600
	assert(magic==0)
	var shield=make_actor(720,660,16)
	shield.kind="shield"
	shield.dir=-1
	assert(e_ai.block(shield,{"damage":3,"direction":1},hero))
	m.begin(shield,"shieldCut")
	shield.attack.age=shield.attack.from
	assert(not e_ai.block(shield,{"damage":3,"direction":1},hero))
	var boss=make_actor(720,660,84)
	boss.kind="champion"
	boss.boss=true
	boss.dir=-1
	m.begin(boss,"championCleave")
	damage(boss,{"damage":3,"direction":1},hero)
	assert(not boss.attack.is_empty() and boss.hurtTicks==0)
	damage(boss,{"damage":.12,"direction":1,"magic":true,"continuous":true},hero)
	assert(boss.attack.is_empty() and boss.electricTicks==9)
	enemies=[shield,boss]
	magic=100
	hero.hurtTicks=8
	hero.recovering=65
	pressed[KEY_K]=true
	tick(m.STEP)
	assert(spell==1 and magic==0 and hero.hurtTicks==0 and hero.invTicks>0)
	for i in 89: tick(m.STEP)
	assert(spell<0)
	damage(shield,{"damage":100,"direction":-1,"knock":true,"magic":true},hero)
	assert(shield.hp==0 and shield.burnAge==0)
	tick_actor(shield,m.STEP)
	assert(shield.burnAge==0)
	for i in 50: tick_actor(shield,m.STEP)
	assert(shield.down.ground>0 and shield.burnAge>0)
	hero.hp=20
	wave=2
	wave_time=5
	step_chicken(m.STEP)
	assert(not chicken.is_empty())
	chicken.roast=true
	chicken.flight=false
	chicken.x=hero.x
	chicken.y=hero.y
	hero.attack={}
	hero.air={}
	hero.down={}
	hero.hurtTicks=0
	step_chicken(m.STEP)
	assert(not hero.pickup.is_empty())
	for i in 36: step_chicken(m.STEP)
	assert(hero.hp==100 and chicken.is_empty())
	begin_walk("enter")
	for i in 180: tick(m.STEP)
	assert(hero.x==720 and stage_walk=="")
	change_phase("paused")
	assert(phase=="paused" and menu.visible)
	change_phase("playing")
	damage(hero,{"damage":100,"direction":-1,"knock":true},boss)
	assert(phase=="dying" and wipe.age==-.5 and hero.gearDropped)
	print("CAIRN_INTEGRATION_OK: shield windows, boss commitment, stun escape, magic duration, grounded burn, chicken pickup, stage entry, pause and death")
	get_tree().quit()


