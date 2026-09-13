extends Node2D
# Global combat tuning: scales all incoming damage, for player and enemies.
@export_range(0.0, 3.0, 0.05) var damage_multiplier: float = 0.65
const MScript=preload("res://scripts/mechanics.gd")
const EScript=preload("res://scripts/enemies.gd")
const ArtScript=preload("res://scripts/art.gd")
const FighterView=preload("res://scripts/fighter_view.gd")
const EnvironmentView=preload("res://scripts/environment.gd")
const BloodScript=preload("res://scripts/blood.gd")
const MenuScript=preload("res://scripts/menu.gd")
const DeathWipe=preload("res://scripts/death_wipe.gd")
var combo=CairnCombo.new()
var holiday="off"
var regular_weapon="gravecleaver"
var holiday_seen_date=""
var score_panel: Node2D
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
var pending_enemies: Array=[]
var reinforcement_wait=0.0
var wave_clear_time=0.0
const WAVE_GAP=0.65
const NORMAL_ENEMY_CAP=3
var gear: Array=[]
var scorches: Array=[]
var arrows: Array=[]
var sparks: Array=[]
var landing_impacts: Array=[]
var chicken: Dictionary={}
var chicken_node: Node2D
var eggs: Array=[]
var used_chickens: Array=[]
var phase="title"
var options=false
var settings_page=""
var music_enabled=true
var voice_enabled=true
var master_volume=100
var loading_menu=false
var bindings=CairnBindings.new()
var controls_view: CanvasLayer
var results_view: CanvasLayer
var hall_view: CanvasLayer
var records=CairnRunRecords.new("")
var episode_combat=preload("res://scripts/episode_combat.gd").new()
var current_episode=1
var run_stats: Dictionary={}
var finished_run: Dictionary={}
var run_button_active=false
var muted=false
const WEAPON_CHOICES=["gravecleaver","blacktooth","barrow_star","gatebreaker","candy_cane"]
var weapon_skin="gravecleaver"
var weapon="axe"
var chapter_select=false
var wave=1
var score=0.0
var kills=0
var magic=0.0
var displayed_health=100.0
var displayed_mana=0.0
var spell=-1
var spell_combo_targets: Array=[]
var next_id=0
var hero_voice: Node
var title_intro=0.0
var clock=0.0
var wave_time=0.0
var accumulator=0.0
var keys: Dictionary={}
var pressed: Dictionary={}
var stage_walk=""
var transition=-1.0
var transition_tips: CanvasLayer
var swapped=false
var wipe: Node2D
var shake=0.0
var hit_stop=0.0
var font: Font
var serif: Font
var pause_cover=0.0
var pause_skull: Sprite2D
var skull_node: Sprite2D
var heat_node: ColorRect
var audio: Node
var scenery_shade: Node2D
var arena_clip: Control
var screen_backdrop: Node2D
var screen_size=Vector2(1440,810)
var last_window_size=Vector2i.ZERO
var title_background=preload("res://art/title-background.png")
var title_logo=preload("res://art/cairn-logo.png")
const CLOSE=.35/.49
const OPEN=.45/.49
const HOLD=3.0

func _ready():
	# Command-line test/capture runs never touch the player's records.
	if DisplayServer.get_name()!="headless" and OS.get_cmdline_user_args().is_empty():records=CairnRunRecords.new()
	Input.joy_connection_changed.connect(func(_device,connected):
		if not connected:
			bindings.clear()
			keys.clear()
			pressed.clear()
			if phase=="playing":change_phase("paused"))
	if "--enemy-fire-study" in OS.get_cmdline_user_args() or (OS.has_feature("web") and JavaScriptBridge.eval("new URLSearchParams(location.search).has('enemy-fire-study')")):
		get_tree().change_scene_to_file.call_deferred("res://enemy_fire_study.tscn")
		return
	if "--fire-study" in OS.get_cmdline_user_args() or (OS.has_feature("web") and JavaScriptBridge.eval("new URLSearchParams(location.search).has('fire-study')")):
		get_tree().change_scene_to_file.call_deferred("res://fire_study.tscn")
		return
	arena_clip=Control.new()
	arena_clip.size=Vector2(1440,810)
	arena_clip.clip_contents=true
	arena_clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(arena_clip)
	screen_backdrop=Node2D.new()
	screen_backdrop.top_level=true
	screen_backdrop.z_index=-200
	screen_backdrop.draw.connect(draw_screen_backdrop)
	add_child(screen_backdrop)
	art=ArtScript.new()
	# Load every packaged image, including menu fuel masks, HUD and all levels.
	for entry in DirAccess.get_files_at("res://assets"):
		var file=entry.trim_suffix(".remap")
		if file.ends_with(".png"): art.texture(file)
	# Also retain atlas resources stored outside the asset directory.
	for atlas in art.data.atlases.values():
		for cel in atlas.cels: art.texture(cel.file)
	for i in 48: art.texture("hero-idle-%d.png"%i)
	m=MScript.new(art.data.attacks)
	m.combat_extensions=true
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
	audio=preload("res://scripts/audio.gd").new()
	add_child(audio)
	audio.setup(self)
	hero_voice=preload("res://scripts/hero_voice.gd").new()
	add_child(hero_voice)
	hero_voice.setup(self)
	var settings=ConfigFile.new()
	if settings.load("user://settings.cfg")==OK:
		muted=settings.get_value("audio","muted",false)
		music_enabled=settings.get_value("audio","music",true)
		voice_enabled=settings.get_value("audio","voice",true)
		master_volume=clampi(settings.get_value("audio","volume",100),0,100)
	initialize_weapon(settings,Time.get_date_string_from_system())
	apply_settings()
	var soundboard=preload("res://scripts/soundboard.gd").new()
	soundboard.audio=audio
	add_child(soundboard)
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
	hud.top_level=true
	score_panel=preload("res://scripts/score_panel.gd").new()
	score_panel.game=self
	hud.add_child(score_panel)
	overlay=Node2D.new()
	overlay.z_index=2000
	overlay.draw.connect(draw_overlay)
	add_child(overlay)
	overlay.top_level=true
	menu=MenuScript.new()
	add_child(menu)
	menu.top_level=true
	menu.setup(art)
	menu.unavailable=func(label):return label=="HALL OF LEGENDS" and records.board(CairnRunRecords.episode_scope(current_episode)).runs.is_empty()
	menu.activated.connect(menu_action)
	menu.sound_requested.connect(func(id):
		audio.play(id,-8)
		if id=="resist":hero_voice.request_line("register_unlock",0.,2.)
	)
	transition_tips=preload("res://scripts/transition_tips.gd").new()
	add_child(transition_tips)
	skull_node=Sprite2D.new()
	skull_node.texture=art.texture("skull-mask.png")
	skull_node.centered=false
	skull_node.top_level=true
	skull_node.scale=Vector2(1440.0/512,810.0/512)
	skull_node.z_index=2040
	skull_node.material=ShaderMaterial.new()
	skull_node.material.shader=load("res://shaders/skull.gdshader")
	skull_node.material.set_shader_parameter("skull",skull_node.texture)
	add_child(skull_node)
	pause_skull=skull_node.duplicate()
	pause_skull.material=skull_node.material.duplicate()
	pause_skull.top_level=true
	pause_skull.z_index=2095
	add_child(pause_skull)
	hero=make_actor(720,660,100,true)
	loading_menu=OS.has_feature("web")
	change_phase("title")
	if loading_menu: reveal_browser_menu.call_deferred()
	if "--smoke-test" in OS.get_cmdline_user_args(): smoke_test.call_deferred()
	if "--capture" in OS.get_cmdline_user_args(): capture_test.call_deferred()
	if "--effects-test" in OS.get_cmdline_user_args(): effects_test.call_deferred()
	if "--integration-test" in OS.get_cmdline_user_args(): integration_test.call_deferred()
	if "--layout-test" in OS.get_cmdline_user_args(): layout_test.call_deferred()
	if "--moves-test" in OS.get_cmdline_user_args(): moves_test.call_deferred()
	if "--archer-test" in OS.get_cmdline_user_args(): archer_test.call_deferred()
	if "--results-preview" in OS.get_cmdline_user_args() or (OS.has_feature("web") and JavaScriptBridge.eval("new URLSearchParams(location.search).has('results-preview')")):preview_results.call_deferred()

func preview_results():
	# Explicit review mode: sample scores are isolated from real local records.
	records=CairnRunRecords.new("")
	for i in 10:
		records.finish({"id":"preview-%d"%i,"score":1162000-i*70000,"kills":50,"best_combo":20,"peak_multiplier":10,"damage_dealt":17000,"damage_taken":200,"time":700-i*20,"date":"2026-09-12","area":3,"outcome":"lost"})
	start_game()
	transition=-1
	stage_walk=""
	score=1284500
	kills=87
	wave=7
	run_stats.merge({"time":768,"best_combo":36,"peak_multiplier":10,"damage_dealt":18640,"damage_taken":240},true)
	wipe=DeathWipe.new()
	add_child(wipe)
	change_phase("lost")

func reveal_browser_menu():
	# Submit the first fully textured frame before releasing the HTML loading cover.
	menu.process_mode=Node.PROCESS_MODE_DISABLED
	await RenderingServer.frame_post_draw
	JavaScriptBridge.eval("window.cairnMenuReady=true; window.dispatchEvent(new Event('cairn-menu-ready'));")
	while JavaScriptBridge.eval("!!document.getElementById('cairn-loader')"):
		await get_tree().process_frame
	menu.process_mode=Node.PROCESS_MODE_INHERIT
	menu.clock=0.0
	loading_menu=false


func make_actor(x: float,y: float,hp: float,player: bool=false) -> Dictionary:
	var f=m.make(next_id,x,y,hp,player)
	next_id+=1
	return f

func change_phase(next: String):
	if next in ["lost","won"]:finish_run(next)
	elif is_instance_valid(results_view):
		results_view.queue_free()
		results_view=null
	menu.compact_pause=next=="paused"
	if next=="dying":
		combo.reset()
		audio.stop_gameplay()
		hero_voice.reset()
	if next=="paused":
		options=false
		settings_page=""
	if next=="title":
		pause_cover=0.0
		title_intro=0.0
	phase=next
	overlay.z_index=2090 if next in ["lost","won","paused"] else 2000
	bindings.clear()
	keys.clear()
	pressed.clear()
	accumulator=0
	menu.visible=phase in ["title","paused"]
	if phase=="title":

		options=false
		settings_page=""
		menu.show_items(["BEGIN","HALL OF LEGENDS","OPTIONS","QUIT"])
	else:

		if phase=="paused": menu.show_items(["RETURN TO BATTLE","OPTIONS","QUIT TO TITLE"],false)
	for view in views.values(): view.visible=phase!="title"
	hud.visible=phase!="title"
	blood.visible=phase!="title"
	background.visible=phase!="title"
	last_window_size=Vector2i.ZERO
	responsive_layout()

func menu_action(label: String):
	if label=="HALL OF LEGENDS":
		if is_instance_valid(hall_view):return
		menu.visible=false
		if is_instance_valid(results_view):results_view.visible=false
		hall_view=preload("res://scripts/hall_view.gd").new()
		hall_view.art=art
		hall_view.runs=records.board(CairnRunRecords.episode_scope(current_episode)).runs.duplicate(true)
		hall_view.current_id=finished_run.get("id","") if phase in ["lost","won"] else ""
		add_child(hall_view)
		hall_view.closed.connect(close_hall)
		hall_view.begin.connect(func():close_hall();start_game())
		return
	if label=="CONTROLS":
		settings_page="controls"
		menu.visible=false
		controls_view=preload("res://scripts/controls_view.gd").new()
		controls_view.art=art
		add_child(controls_view)
		controls_view.closed.connect(func():menu_action("BACK"))
		return
	if label=="BACK" and settings_page=="controls":
		controls_view.queue_free()
		controls_view=null
		settings_page="game"
		menu.visible=true
		refresh_settings(1)
		return
	if label.begins_with("WEAPON: "):
		cycle_weapon(1)
		refresh_settings(0)
		return
	match label:
		"BEGIN":
			chapter_select=true
			menu.switch_items(["EP 1: THE FALLEN CITADEL","EP 2: THE SUNKEN WILDS","EP 3: THE ASHEN DEPTHS","BACK"],true)
		"EP 1: THE FALLEN CITADEL","EP 2: THE SUNKEN WILDS","EP 3: THE ASHEN DEPTHS":
			current_episode=int(label.substr(3,1))
			chapter_select=false
			start_game()
		"RISE AGAIN": start_game()
		"OPTIONS":
			options=true
			settings_page="root"
			menu.switch_items(option_labels(),phase=="title")
		"SOUND","DISPLAY","GAME":
			settings_page=label.to_lower()
			menu.switch_items(option_labels(),phase=="title")
		"BACK":
			if chapter_select:
				chapter_select=false
				menu.switch_items(["BEGIN","HALL OF LEGENDS","OPTIONS","QUIT"],true)
				return
			if settings_page in ["sound","display","game"]:
				settings_page="root"
				menu.switch_items(option_labels(),phase=="title")
			else:
				options=false
				settings_page=""
				menu.switch_items(["BEGIN","HALL OF LEGENDS","OPTIONS","QUIT"] if phase=="title" else ["RETURN TO BATTLE","OPTIONS","QUIT TO TITLE"],phase=="title")
		"SOUND: ON","SOUND: OFF":
			muted=not muted
			apply_settings()
			refresh_settings(0)
		"MUSIC: ON","MUSIC: OFF":
			music_enabled=not music_enabled
			apply_settings()
			refresh_settings(1)
		"VOICE: ON","VOICE: OFF":
			voice_enabled=not voice_enabled
			if not voice_enabled:hero_voice.reset()
			apply_settings()
			refresh_settings(2)
		"FULLSCREEN: ON","FULLSCREEN: OFF":
			toggle_fullscreen()
		"RETURN TO BATTLE": change_phase("playing")
		"QUIT":
			if OS.has_feature("web"):
				JavaScriptBridge.eval("window.close(); setTimeout(() => alert('You can close this tab to quit Cairn.'), 100);")
			else:
				WindowPreferences.save_window()
				get_tree().quit()
		"QUIT TO TITLE":
			clear_world()
			if is_instance_valid(wipe): wipe.queue_free()
			wipe=null
			transition=-1
			change_phase("title")

func option_labels() -> Array:
	if settings_page=="sound":return ["SOUND: OFF" if muted else "SOUND: ON","MUSIC: ON" if music_enabled else "MUSIC: OFF","VOICE: ON" if voice_enabled else "VOICE: OFF","VOLUME: %d"%master_volume,"BACK"]
	if settings_page=="display":return ["FULLSCREEN: ON" if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else "FULLSCREEN: OFF","BACK"]
	if settings_page=="game":return ["WEAPON: "+weapon_skin.replace("_"," ").to_upper(),"CONTROLS","BACK"]
	return ["GAME","SOUND","DISPLAY","BACK"]

func close_hall():
	if is_instance_valid(hall_view):hall_view.queue_free()
	hall_view=null
	if is_instance_valid(results_view):
		results_view.visible=true
		results_view.age=3.0
		results_view.content.queue_redraw()
		results_view.actions.select(1,false)
	else:
		menu.visible=true
		menu.select(1,false)

func finish_run(outcome: String):
	if run_stats.is_empty():return
	if finished_run.is_empty():
		var snapshot=run_stats.duplicate(true)
		for key in ["damage_dealt","damage_taken"]:snapshot[key]=int(snapshot[key])
		snapshot.merge({"score":int(score),"kills":kills,"episode":current_episode,"area":mini(4,1+int((wave-1)/3)),"outcome":outcome},true)
		finished_run=records.finish(snapshot)
	if is_instance_valid(results_view):return
	results_view=preload("res://scripts/results_view.gd").new()
	results_view.art=art
	results_view.result=finished_run
	results_view.save_failed=records.save_error!=OK
	add_child(results_view)
	results_view.activated.connect(menu_action)
	if outcome=="won" and not is_instance_valid(wipe):
		wipe=DeathWipe.new()
		add_child(wipe)
		# Seed the same blood surface used by defeat; continue its settling below.
		wipe.advance(.8)

func refresh_settings(index: int):
	menu.show_items(option_labels(),phase=="title",false)
	menu.select(index,false)

func apply_settings(persist: bool=true):
	AudioServer.set_bus_volume_db(0,linear_to_db(master_volume/100.0) if master_volume>0 else -80)
	AudioServer.set_bus_mute(0,master_volume==0)
	if persist:
		var config=ConfigFile.new()
		config.set_value("game","weapon",regular_weapon)
		config.set_value("game","holiday_seen_date",holiday_seen_date)
		config.set_value("audio","muted",muted)
		config.set_value("audio","music",music_enabled)
		config.set_value("audio","voice",voice_enabled)
		config.set_value("audio","volume",master_volume)
		config.save("user://settings.cfg")

func clear_world():
	episode_combat.clear()
	clear_eggs()
	if hero_voice:hero_voice.reset()
	for view in views.values(): view.queue_free()
	for view in flame_views.values(): view.queue_free()
	views.clear()
	flame_views.clear()
	for item in gear: item.node.queue_free()
	gear.clear()
	for arrow in arrows:
		if is_instance_valid(arrow):arrow.queue_free()
	arrows.clear()
	if is_instance_valid(chicken_node): chicken_node.queue_free()
	chicken={}
	enemies.clear()
	scorches.clear()
	sparks.clear()
	for impact in landing_impacts:
		if is_instance_valid(impact):impact.queue_free()
	landing_impacts.clear()
	blood.reset()

func start_game():
	finished_run={}
	run_stats={"id":str(Time.get_unix_time_from_system())+"-"+str(Time.get_ticks_usec()),"date":Time.get_date_string_from_system(),"time":0.0,"best_combo":0,"peak_multiplier":1,"damage_dealt":0.0,"damage_taken":0.0}
	hero_voice.milestones.clear()
	chapter_select=false
	clear_world()
	if is_instance_valid(wipe): wipe.queue_free()
	wipe=null
	hero=make_actor(-140,660,100,true)
	hero.weapon=weapon
	hero["weapon_skin"]=weapon_skin
	hero["holiday"]=holiday
	wave=1
	score=0.0
	combo.reset()
	kills=0
	magic=0
	spell=-1
	spell_combo_targets.clear()
	displayed_health=100
	displayed_mana=0
	used_chickens.clear()
	encounters=e_ai.plan(current_episode)
	change_phase("playing")
	spawn_wave()
	begin_walk("enter")
	transition=CLOSE+HOLD
	swapped=true

func screen_for_wave(number: int) -> int:
	return clampi(1+int((number-1)/3),1,4)

func spawn_wave(preserve_corpses: bool=false):
	combo.suspend()
	wave_clear_time=0.0
	if not preserve_corpses:
		for enemy in enemies:
			if views.has(enemy.id): views[enemy.id].queue_free();views.erase(enemy.id)
			if flame_views.has(enemy.id): flame_views[enemy.id].queue_free();flame_views.erase(enemy.id)
		for item in gear: item.node.queue_free()
		gear.clear()
		for arrow in arrows:
			if is_instance_valid(arrow):arrow.queue_free()
		arrows.clear()
		enemies.clear()
	var next="%s-%d"%[["citadel","swamp","ashen"][current_episode-1],screen_for_wave(wave)]
	episode_combat.clear()
	if next!=background.key:
		remove_chicken()
		clear_eggs()
		hero.bootCoat=0.0
		hero.bootDistance=0.0
		hero.bootPos=Vector2(hero.x,hero.y)
		blood.reset()
		scorches.clear()
	if background.key!=next:background.setup(art,next)
	last_window_size=Vector2i.ZERO
	responsive_layout()
	pending_enemies=encounters[wave-1].duplicate()
	var initial=min(pending_enemies.size(),2+randi()%2)
	for i in initial:spawn_encounter_enemy()
	reinforcement_wait=randf_range(1.0,2.0)
	wave_time=0

func spawn_encounter_enemy():
	if pending_enemies.is_empty():return
	if enemies.filter(func(enemy):return enemy.hp>0).size()>=NORMAL_ENEMY_CAP:return
	if pending_enemies[0]=="shield" and enemies.filter(func(enemy):return enemy.hp>0 and enemy.kind=="shield").size()>=e_ai.shield_limit(screen_for_wave(wave)):return
	var kind=pending_enemies.pop_front()
	var left=randf()<.5
	var f=make_actor(randf_range(-360,-270) if left else randf_range(1710,1800),randf_range(570,730),e_ai.roster[kind].hp)
	f.kind=kind
	f.boss=kind in ["champion","king","saint"]
	f.dir=1 if left else -1
	var allowed=e_ai.wave_variants[wave-1] if wave<=e_ai.wave_variants.size() else []
	# Never stack several advanced variants in one reinforcement group.
	if enemies.any(func(enemy):return enemy.hp>0 and enemy.get("variant","regular")!="regular"):allowed=[]
	e_ai.variant(f,allowed)
	background.constrain(f)
	enemies.append(f)

func step_reinforcements(dt: float):
	if pending_enemies.is_empty():return
	reinforcement_wait-=dt
	var living=enemies.filter(func(enemy):return enemy.hp>0)
	var pressure=0
	for enemy in living:pressure+=2 if enemy.kind in ["shield","archer","marauder","witch","bearer"] else 1
	var next=pending_enemies[0]
	var cost=2 if next in ["shield","archer","marauder","witch","bearer"] else 1
	if living.is_empty() or reinforcement_wait<=0 and living.size()<NORMAL_ENEMY_CAP and pressure+cost<=screen_for_wave(wave)+3:
		spawn_encounter_enemy()
		reinforcement_wait=randf_range(.8,1.9)

func begin_walk(kind: String):
	combo.suspend()
	stage_walk=kind
	if audio:audio.play("transition",-14)
	bindings.clear()
	keys.clear()
	pressed.clear()
	spell=-1
	hero.attack={}
	hero.air={}
	hero.jump=null
	hero.arrowKick={}
	hero.diveUsed=false
	hero.diveHit=false
	hero.diveAge=0
	hero.holdTicks=0
	hero.spinUsed=false
	hero.chargeRebound=0.0
	hero.stagger=0
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
	if f.player and not f.pickup.is_empty():return
	if f.player and not f.attack.is_empty() and f.attack.get("spin",false) and f.attack.age<=f.attack.to:return
	if attacker.player and not f.player and a.get("type","")=="charge" and e_ai.heavy(f):
		m.rebound_charge(attacker,int(a.direction))
		audio.play("resist",-4)
		burst((f.x+attacker.x)*.5,f.y-105,7,Color("b7a58c"))
		hit_stop=.055
		shake=4
		return
	if not f.player and e_ai.block(f,a,attacker):
		f.x=clamp(f.x,70,1370)
		burst(f.x+f.dir*40,f.y-110,8,Color("cfbd94"))
		audio.play("resist",-4)
		return
	if a.get("dive",false):
		if not attacker.diveHit:
			attacker.diveHit=true
			hit_stop=.065 if attacker.weapon=="axe" else .045
			for other in enemies:
				if other.id!=f.id and other.hp>0 and other.down.is_empty() and abs(other.x-f.x)<120 and abs(other.y-f.y)<30 and not e_ai.guarding(other):
					m.interrupt_attack(other)
					other.hurtTicks=max(other.hurtTicks,16)
					other.velocityX=0
			a.knock=true
		else:a.knock=false
	if not f.player and not a.get("magic",false): f.hitGlow=.1
	if f.kind in ["king","saint"] and not e_ai.boss_open(f) and not a.get("magic",false):
		a=a.duplicate()
		a.damage*=.2
	var previous_hp=f.hp
	f.hp=max(0,f.hp-a.damage*damage_multiplier*(100.0/48 if f.player else 1)*(e_ai.damage_scale(attacker) if not attacker.player else 1.0))
	if f.hp<previous_hp:
		if f.player:
			if not run_stats.is_empty():run_stats.damage_taken+=previous_hp-f.hp
			combo.reset()
		elif attacker.player:
			f["combo_opportunity_seen"]=true
			# Continuous magic sustains the chain, but awards only one hit per target per cast.
			if a.get("magic",false) and f.id in spell_combo_targets:
				combo.remaining=combo.timeout
				combo.waiting_for_combat=false
			else:
				combo.hit()
				if a.get("magic",false):spell_combo_targets.append(f.id)
			score+=(previous_hp-f.hp)*combo.multiplier()*10.0
			if not run_stats.is_empty():
				run_stats.damage_dealt+=previous_hp-f.hp
				run_stats.best_combo=maxi(run_stats.best_combo,combo.hits)
				run_stats.peak_multiplier=maxi(run_stats.peak_multiplier,combo.multiplier())
	if not f.player and f.hp<previous_hp:
		f.healthBarUntil=clock+1.4
	if f.player and a.get("no_stun",false) and not a.get("continuous",false) and f.hp>0 and f.hp<previous_hp:
		f.arrowKick={"age":0.0,"offset":0.0,"direction":a.direction}
	if a.get("magic",false) and f.hp>0:
		m.interrupt_attack(f)
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
		var boss_committed=f.boss and f.down.is_empty() and ((f.attack.is_empty() or f.attack.age<=f.attack.to) if f.kind=="champion" else not e_ai.boss_open(f))
		var saved=f.attack
		var recovery=f.boss and not f.attack.is_empty() and f.attack.age>max(f.attack.to,f.attack.from+7)
		var reaction=a.duplicate()
		if boss_committed: reaction.knock=false
		if not a.get("no_stun",false) or f.hp<=0:m.hurt(f,reaction)
		if f.hp>0 and (committed or boss_committed):
			audio.play("resist",-4)
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
		if a.get("dive",false):blood.hit(impact,a.direction,true)
		if f.hp<=0 and not f.player:
			for i in (4 if f.boss else 1): blood.hit(impact,a.direction,true)
		burst(f.x,f.y-105,12,Color("e97b4f") if f.player else Color("ffc473"))
		shake=7 if a.get("dive",false) else (5 if a.get("knock",false) else 2)
		audio.play("charge_hit" if a.get("type","")=="charge" else "arrow_hit" if a.get("no_stun",false) else "flesh" if f.player else "enemy_impact")
		if f.player and not a.get("no_stun",false):audio.play("hero_pain",-6)
	if f.hp<=0:
		f.death=0
		f.burnAge=0
		f.engulf=.8+randf()*.5
		drop_gear(f)
		if f.player:
			stage_walk=""
			spell=-1
			change_phase("dying")
			audio.play("death",-4)
			wipe=DeathWipe.new()
			add_child(wipe)
			last_window_size=Vector2i.ZERO
			responsive_layout()
		else:
			kills+=1
	if not f.player and attacker.player and not a.get("magic",false):
		magic=min(100,magic+(6+(8 if f.hp<=0 else 0))*combo.mana_multiplier())
		if magic>=100:hero_voice.request_once("mana_full")

func burst(x: float,y: float,count: int,color: Color):
	for i in count: sparks.append({"x":x,"y":y,"vx":(randf()-.5)*460,"vy":(randf()-.65)*390,"life":.3+randf()*.4,"color":color})

func resolve_slam(origin: Vector2,strike: Dictionary):
	var ordered=enemies.duplicate()
	ordered.sort_custom(func(a,b):return abs(a.x-origin.x)<abs(b.x-origin.x))
	for enemy in ordered:
		if enemy.hp<=0:continue
		var delta=Vector2(enemy.x,enemy.y)-origin
		var previous_hp=enemy.hp
		if Vector2(delta.x/(150.0 if hero.weapon=="axe" else 187.5),delta.y/110.0).length_squared()<1.0 and enemy.down.is_empty() and not enemy.invTicks:
			var blow=strike.duplicate()
			blow.direction=1 if delta.x>=0 else -1
			blow.origin_x=origin.x
			damage(enemy,blow,hero)
		# The pressure wave moves nearby bodies without requiring damage or stagger.
		var distance=Vector2(delta.x,delta.y*1.8).length()
		if distance<375:
			var outward=delta.normalized() if delta.length()>1 else Vector2(hero.dir,0)
			var mass_resistance=clampf(1.0/pow(enemy.size,2),.4,1.6)
			var force=750.0 if enemy.hp==previous_hp else 500.0
			enemy.slamPush=outward*pow(1.0-distance/375.0,1.2)*force*mass_resistance
	hero.recovering=(8 if hero.diveHit else 24) if hero.weapon=="axe" else (6 if hero.diveHit else 19)


func tick_actor(f: Dictionary,dt: float):
	if not f.get("arrowKick",{}).is_empty():
		var kick=f.arrowKick
		kick.age=minf(.18,kick.age+dt)
		var t=kick.age/.18
		var offset=(sin(t*PI)*11*exp(-t*.8)+4*t)*kick.direction
		f.x=clampf(f.x+offset-kick.offset,70,1370)
		kick.offset=offset
		if t>=1:f.arrowKick={}

	var push=f.get("slamPush",Vector2.ZERO)
	if push.length_squared()>1:
		f.x=clamp(f.x+push.x*dt,70,1370)
		f.y=clamp(f.y+push.y*dt,560,755)
		f.slamPush=push*exp(-dt*7.0)
	f.hitGlow=max(0,f.hitGlow-dt)
	f.electricTicks=max(0,f.electricTicks-1)
	f.clock+=dt
	m.reaction(f)
	if not f.down.is_empty(): f.x=clamp(f.x,70,1370)
	if f.hp<=0:
		f.death+=dt
		f.moving=false
		if not f.player and not f.down.is_empty() and f.down.ground:
			f.burnAge+=dt*BurningSprite.SPEED
			if not f.scorched:
				f.scorched=true
				scorches.append({"x":f.x,"y":f.y,"r":(85 if f.boss else 45)*f.size})

# Waiting is latched between encounters, not whenever the player backs away.
func step_combo(dt: float):
	var living=enemies.filter(func(enemy):return enemy.hp>0)
	var ready=false
	for enemy in living:
		# Distance and knockdown must not freeze the clock after arena entry.
		var reachable=enemy.x>=0 and enemy.x<=1440
		if reachable:
			enemy["combo_opportunity_seen"]=true
			ready=true
	# Only protect spawn/transition gaps, never voluntary retreat from known foes.
	if living.is_empty() or not living.any(func(enemy):return enemy.get("combo_opportunity_seen",false)):
		combo.suspend()
	if combo.waiting_for_combat:
		if not ready:return
		combo.resume()
		return
	hero.hp=minf(hero.max,hero.hp+combo.advance(dt))

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
	arrows=arrows.filter(func(arrow):return is_instance_valid(arrow))
	for arrow in arrows:arrow.advance(dt)
	if phase=="playing":
		step_combo(dt)
		step_chicken(dt)
		step_reinforcements(dt)
	if pressed.has(KEY_K) and can_cast():
		if hero.hurtTicks or hero.recovering:
			hero.hurtTicks=0
			hero.hurtAge=0
			hero.recovering=0
			hero.recoil=0
			hero.stagger=0
			hero.invTicks=max(hero.invTicks,24)
		spell_combo_targets.clear()
		spell=0
		magic=0
	if spell>=0:
		spell+=1
		if spell>=20 and spell<77:
			if not chicken.is_empty() and not chicken.roast and chicken.x>=0 and chicken.x<=1440:
				chicken.lightning_until=clock+.22
				roast_chicken(1 if chicken.x>=hero.x else -1)
			for f in enemies:
				if f.hp>0 and f.x>=0 and f.x<=1440: damage(f,{"damage":.12,"knock":false,"magic":true,"continuous":true,"direction":1 if f.x>hero.x else -1},hero)
		if spell>=90: spell=-1
	tick_actor(hero,dt)
	for f in enemies:
		tick_actor(f,dt)
		e_ai.keep_in_arena(f)
		background.constrain(f)
	if phase=="dying":
		pressed.clear()
		return
	var dx=int(keys.has(KEY_D))-int(keys.has(KEY_A))
	episode_combat.prepare_actor(hero)
	var dy=int(keys.has(KEY_S))-int(keys.has(KEY_W))
	var run_held=keys.has(KEY_SHIFT)
	if run_held and dx!=0 and hero.air.is_empty() and hero.attack.is_empty():
		hero.running=true
		hero.runDir=dx
	elif run_button_active and not run_held:hero.running=false
	run_button_active=run_held
	var edge=-1 if pressed.has(KEY_A) else 1 if pressed.has(KEY_D) else 0
	if spell<0 and hero.pickup.is_empty():
		if pressed.has(KEY_J) and pressed.has(KEY_SPACE) and hero.air.is_empty(): m.begin(hero,"back")
		elif pressed.has(KEY_SPACE):
			if m.start_jump(hero): beep(160,.12)
		elif pressed.has(KEY_J):
			if m.begin(hero,m.select_strike(hero,enemies)): beep(230,.15)
	if not keys.has(KEY_J):
		hero.holdTicks=0
		hero.spinUsed=false
	else:hero.holdTicks+=1
	if hero.holdTicks>=21 and not hero.spinUsed and hero.air.is_empty() and spell<0 and hero.pickup.is_empty():
		if m.begin(hero,"spin"):hero.spinUsed=true
	var busy=spell>=0 or not hero.pickup.is_empty()
	var was_diving=hero.diveUsed and not hero.air.is_empty() and hero.air.land==0
	var landing_strike=hero.attack.duplicate() if was_diving else {}
	var hero_before=Vector2(hero.x,hero.y)
	m.motion(hero,0 if busy else dx,0 if busy else dy,0 if busy else edge,true)
	episode_combat.movement(hero,hero_before)
	if was_diving and not hero.air.is_empty() and hero.air.land>0:
		var impact=preload("res://scripts/landing_impact.gd").new()
		arena_clip.add_child(impact)
		var contact=Vector2(hero.x,hero.y) # Shared player landing origin for visuals and combat.
		impact.setup(contact,hero.weapon=="axe")
		landing_impacts.append(impact)
		if landing_strike.get("dive",false):resolve_slam(contact,landing_strike)
		audio.play("landing",-4)
	if hero.attack.has("weapon") and not hero.attack.get("dive",false):
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
		var enemy_before=Vector2(f.x,f.y)
		var intent=e_ai.intent(f,hero,f.id in engaged)
		if not f.attack.is_empty(): e_ai.motion(f)
		elif not f.hurtTicks and f.down.is_empty() and not f.recovering:
			var speed=e_ai.roster[f.kind].speed*f.speedFactor
			f.velocityX=intent.x*speed
			f.velocityY=intent.y*speed
			f.x+=f.velocityX*m.SCALE
			f.y=clamp(f.y+f.velocityY*m.SCALE,560,755)
			f.moving=intent!=Vector2.ZERO
			if f.moving: f.stride=fmod(f.stride+f.speedFactor/(56*f.size),1)
		episode_combat.movement(f,enemy_before)
		f.x=clamp(f.x,-2400,3840)
		var finished=m.tick_attack(f,[hero],damage)
		if f.kind=="archer" and f.attack.get("type","")=="archerShot" and f.attack.age==40:
			var arrow=preload("res://scripts/arrow.gd").new()
			arena_clip.add_child(arrow)
			arrow.setup(self,f)
			arrows.append(arrow)
			audio.play("bow_release",-8)
		if not finished.is_empty(): e_ai.finish(f,finished,hero)
		if phase!="playing": break
	episode_combat.step(self,dt)
	e_ai.separate(enemies)
	background.constrain(hero)
	if not chicken.is_empty():background.constrain(chicken)
	for f in enemies:
		e_ai.keep_in_arena(f)
		background.constrain(f)
	if not hero.pickup.is_empty():return # Finish eating before an area transition can clear the pickup.
	if phase=="playing" and pending_enemies.is_empty() and enemies.all(func(f):return f.hp<=0):
		wave_clear_time+=dt
		if wave<encounters.size() and screen_for_wave(wave+1)==screen_for_wave(wave):
			if wave_clear_time<WAVE_GAP:return
			wave+=1
			spawn_wave(true)
			return
		if enemies.all(func(f):return f.burnAge>=BurningSprite.finished_at(f.engulf)):
			begin_walk("exit")
			if wave<encounters.size():transition_tips.choose()
			else:transition_tips.current=""
			transition=0
			swapped=false
	else:wave_clear_time=0.0

func _process(raw: float):
	if not art: return
	responsive_layout()
	for child in get_children():
		if child is Node2D and child not in [screen_backdrop,hud,overlay,menu,wipe]:child.reparent(arena_clip)
	raw=min(raw,.25)
	if phase=="playing" and not run_stats.is_empty():run_stats.time+=raw
	if phase in ["lost","won"] and is_instance_valid(wipe) and wipe.age<3.8:wipe.advance(raw)
	if phase=="title" and not loading_menu: title_intro=min(1.25,title_intro+raw)
	if hit_stop>0 and phase=="playing":
		hit_stop=max(0.,hit_stop-raw)
		return
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
	episode_combat.sync_views(self)
	screen_backdrop.queue_redraw()
	heat_node.visible=background.key=="cinder" and phase!="title"
	scenery_shade.visible=phase!="title" and background.screen.is_empty()
	heat_node.material.set_shader_parameter("clock",clock)
	pause_cover=move_toward(pause_cover,1.0 if phase=="paused" else 0.0,raw/.65)
	pause_skull.visible=pause_cover>0
	pause_skull.position=Vector2.ZERO
	pause_skull.scale=screen_size/512.0
	pause_skull.material.set_shader_parameter("progress",1.0-pause_cover)
	if phase=="paused": menu.modulate.a=smoothstep(.8,1.0,pause_cover)
	else: menu.modulate.a=1.0
	transition_tips.update(transition if phase=="playing" else -1.0,CLOSE,HOLD,screen_size)
	skull_node.position=Vector2.ZERO
	skull_node.scale=screen_size/512.0
	skull_node.visible=transition>=0
	if transition>=0:
		var progress=1-transition/CLOSE if transition<CLOSE else 0.0 if transition<CLOSE+HOLD else (transition-CLOSE-HOLD)/OPEN
		skull_node.material.set_shader_parameter("progress",progress)
	for f in [hero]+enemies:
		if not views.has(f.id):
			var view=FighterView.new()
			view.actor=f
			view.art=art
			arena_clip.add_child(view)
			views[f.id]=view
		views[f.id].visible=phase!="title"
		views[f.id].update_view(spell if f.player else -1)
		if flame_views.has(f.id):
			flame_views[f.id].z_index=int(f.y)*2+1
			flame_views[f.id].queue_redraw()
	landing_impacts=landing_impacts.filter(func(impact):return is_instance_valid(impact))
	for impact in landing_impacts:impact.advance(dt)
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

func toggle_fullscreen():
	var fullscreen=DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if options and settings_page=="display":refresh_settings(0)

func _input(event: InputEvent):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		audio.unlocked=true
		if phase in ["title","paused","lost","won"] or event is InputEventJoypadButton and event.button_index==JOY_BUTTON_START:
			var translated=bindings.menu_event(event)
			if translated:_input(translated)
			return
	if event is InputEventKey and phase in ["title","paused","lost","won"] and not event.alt_pressed:
		if event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D]:
			event=event.duplicate()
			event.keycode={KEY_W:KEY_UP,KEY_A:KEY_LEFT,KEY_S:KEY_DOWN,KEY_D:KEY_RIGHT}[event.keycode]
	if is_instance_valid(controls_view):
		controls_view.handle(event)
		if event is InputEventKey:get_viewport().set_input_as_handled()
		return
	if is_instance_valid(hall_view):
		hall_view.handle(event)
		if event is InputEventKey:get_viewport().set_input_as_handled()
		return
	if is_instance_valid(results_view):
		results_view.handle(event)
		if event is InputEventKey:get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.alt_pressed and event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
		if event.pressed and not event.echo:toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if loading_menu:return
	if event is InputEventKey or event is InputEventMouseButton:audio.unlocked=true
	if event is InputEventKey:
		var code=event.keycode
		if event.pressed and not event.echo and code in [KEY_ESCAPE,KEY_P]:
			if options or chapter_select:menu_action("BACK")
			elif phase=="playing": change_phase("paused")
			elif phase=="paused": change_phase("playing")
			elif phase=="title" and options: menu_action("BACK")
			return
	if phase in ["title","paused","lost","won"]:
		if phase=="paused" and pause_cover<.8: return
		if options and settings_page=="sound" and menu.selected==3 and not menu.switching and event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT,KEY_RIGHT]:
			master_volume=clampi(master_volume+(-1 if event.keycode==KEY_LEFT else 1),0,100)
			apply_settings()
			refresh_settings(3)
			return
		if options and settings_page=="game" and menu.selected==0 and not menu.switching and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_LEFT,KEY_RIGHT]:
			cycle_weapon(-1 if event.keycode==KEY_LEFT else 1)
			refresh_settings(menu.selected)
			return
		menu.handle(event)
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_Q and phase=="playing":toggle_weapon()
	for change in bindings.gameplay(event):
		var code=change[0]
		if not change[1]:keys.erase(code)
		elif phase=="playing":
			if not keys.has(code):pressed[code]=true
			keys[code]=true

# Seasonal auto-equip never overwrites the player's regular preference.
func initialize_weapon(settings: ConfigFile,today: String):
	regular_weapon=settings.get_value("game","weapon","gravecleaver")
	if regular_weapon not in WEAPON_CHOICES or regular_weapon=="candy_cane":regular_weapon="gravecleaver"
	holiday_seen_date=settings.get_value("game","holiday_seen_date","")
	weapon_skin=regular_weapon
	# Keep available every day while testing the Christmas equipment.
	if holiday_seen_date!=today:
		weapon_skin="candy_cane"
		holiday_seen_date=today
	holiday="christmas" if weapon_skin=="candy_cane" else "off"
	weapon="axe"

func cycle_weapon(direction: int):
	weapon_skin=WEAPON_CHOICES[posmod(WEAPON_CHOICES.find(weapon_skin)+direction,WEAPON_CHOICES.size())]
	if weapon_skin!="candy_cane":regular_weapon=weapon_skin
	holiday="christmas" if weapon_skin=="candy_cane" else "off"
	weapon="sword" if weapon_skin=="sword" else "axe"
	hero.weapon=weapon
	hero["weapon_skin"]=weapon_skin
	hero["holiday"]=holiday
	apply_settings()

func toggle_weapon():
	cycle_weapon(1)

func _notification(what: int):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and phase=="playing" and is_instance_valid(menu): change_phase("paused")

func drop_gear(f: Dictionary):
	f.gearDropped=true
	if not art.has_separate_weapon(f):return # Archer gear burns with the body; minotaurs fight bare-handed.
	var pieces=[]
	if f.player or f.kind=="champion":
		var w=art.weapon_data(f) if f.player else art.data.weapons["axe"]
		pieces.append([art.weapon_cel(w).file,w.length if f.player else 182])
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
	for egg in eggs:
		egg.advance(dt)
		if egg.expired:egg.queue_free()
	eggs=eggs.filter(func(egg):return not egg.expired)
	wave_time+=dt
	var schedule={2:5,5:7,8:6,11:9}
	if schedule.has(wave) and wave_time>=schedule[wave] and not wave in used_chickens and chicken.is_empty():
		used_chickens.append(wave)
		hero_voice.request_line("dinner",.9,4.)
		chicken={"x":90.0,"y":610.0,"dir":1,"age":0.0,"roast":false,"turn":0.0,"hop":0.0,"height":0.0,"flight":false,"picked":false,"egg_check":2.0,"egg_count":0,"lay":-1.0,"laid":false}
		chicken_node=Node2D.new()
		chicken_node.material=ShaderMaterial.new()
		chicken_node.material.shader=load("res://shaders/chicken_edge.gdshader")
		chicken_node.draw.connect(draw_chicken)
		arena_clip.add_child(chicken_node)
	if chicken.is_empty(): return
	var c=chicken
	c.age+=dt
	if not hero.pickup.is_empty():
		var p=hero.pickup
		if hero.hp<=0 or not hero.down.is_empty() or hero.hurtTicks:
			if p.collected: remove_chicken()
			else:
				c.height=0
				c["draw_scale"]=1.0
				c.x=clampf(c.x,70,1370)
			hero.pickup={}
			return
		p.age+=dt
		# Reach, lift, toss, swallow, settle. The roast remains a separate sprite.
		var hand=Vector2(hero.x+hero.dir*76,hero.y-278)
		var mouth=Vector2(hero.x+hero.dir*12,hero.y-249)
		var point=Vector2(p.start_x,hero.y)
		if p.age>=.3 and p.age<.6:point=point.lerp(hand,smoothstep(.3,.6,p.age))
		elif p.age>=.6:
			var t=clampf((p.age-.6)/.32,0,1)
			point=hand.lerp(mouth,t)+Vector2(0,-sin(t*PI)*35)
		c.x=point.x
		c.height=(hero.y-point.y)/4.5
		c["draw_scale"]=lerpf(1.,.08,smoothstep(.68,.92,p.age))
		if p.age>=.92 and not p.collected:
			p.collected=true
			c.picked=true
			audio.play("gulp",-3)
			hero.hp=hero.max
		if p.age>=1.2:
			remove_chicken()
			hero.pickup={}
			return
	elif c.roast:
		if c.flight:
			c.x+=c.vx*dt
			if c.x<70 or c.x>1370:
				c.x=clampf(c.x,70,1370)
				c.vx=-c.vx*.55
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
			hero.pickup={"age":0.0,"collected":false,"start_x":c.x}
	else:
		c["egg_check"]=c.get("egg_check",2.)-dt
		if c.get("lay",-1.)<0 and c.egg_check<=0 and c.age<9 and c.height<=0:
			c.egg_check=2.
			if c.get("egg_count",0)<2 and randf()<.35:
				c["lay"]=0.
				c["laid"]=false
				c.hop=0.
		if c.get("lay",-1.)>=0:
			c.lay+=dt
			if c.lay>=.32 and not c.laid:
				c.laid=true
				c["egg_count"]=c.get("egg_count",0)+1
				drop_egg(Vector2(c.x-c.dir*26,c.y),randf()<.1,-c.dir)
				audio.play("egg_lay",-7)
			if c.lay>=.65:c.lay=-1.;c.hop=.3
		elif c.age>10:
			c.x+=c.dir*350*dt
			if c.x< -80 or c.x>1520: remove_chicken();return
		else:
			c.turn-=dt
			if c.turn<=0:
				c.turn=.65+randf()*.7
				c.dir=(1 if c.x>hero.x else -1) if abs(c.x-hero.x)<180 else (-c.dir if randf()<.2 else c.dir)
				c.targetY=575+randf()*150
				if randf()<.28: c.hop=.3
			c.x+=c.dir*235*dt
			# Reflect overshoot after movement; keep the whole sprite inside the arena.
			if c.x<70:
				c.x=140-c.x
				c.dir=1
				c.turn=max(c.turn,.35)
			elif c.x>1370:
				c.x=2740-c.x
				c.dir=-1
				c.turn=max(c.turn,.35)
			c.y+=clamp(c.get("targetY",630)-c.y,-60,60)*dt
			c.hop=max(0,c.hop-dt)
			c.height=sin(c.hop/.3*PI)*5
		var a=hero.attack
		if not a.is_empty() and a.age>=a.from and a.age<=a.to and abs(c.y-hero.y)<32:
			var reach=(a.box[0]+a.box[1] if a.has("box") else a.reach)*4.5
			if (c.x-hero.x)*a.direction> -15 and (c.x-hero.x)*a.direction<reach+26:
				roast_chicken(a.direction)
	if is_instance_valid(chicken_node):
		chicken_node.z_index=int(c.y)*2
		chicken_node.queue_redraw()

func roast_chicken(direction: float):
	if chicken.is_empty() or chicken.roast:return
	audio.play("chicken_hit",-5)
	chicken.roast=true
	chicken.age=0
	chicken.height=10
	chicken.flight=true
	chicken.vx=direction*(180+randf()*90)
	chicken.vz=250+randf()*70
	chicken.trail=0

func remove_chicken():
	chicken={}
	if is_instance_valid(chicken_node): chicken_node.queue_free()

func drop_egg(point: Vector2,golden: bool,direction: float=1.) -> Node2D:
	var egg=preload("res://scripts/egg_pickup.gd").new()
	egg.game=self
	egg.golden=golden
	egg.position=point
	egg.drift=direction*35
	arena_clip.add_child(egg)
	eggs.append(egg)
	return egg

func clear_eggs():
	for egg in eggs:
		if is_instance_valid(egg):egg.queue_free()
	eggs.clear()

func draw_chicken():
	if chicken.is_empty() or chicken.picked: return
	var c=chicken
	var atlas=art.data.atlases["chicken-v1"]
	var laying=c.get("lay",-1.)>=0 and not c.roast
	var cel=atlas.cels[10 if c.roast else 9 if c.hop or laying else int(c.age*16)%8]
	var s=132/atlas.cellWidth*c.get("draw_scale",1.0)
	var crouch=sin(clampf(c.get("lay",0.)/.65,0.,1.)*PI) if laying else 0.
	chicken_node.draw_set_transform(Vector2(c.x,c.y-c.height*4.5),c.dir*crouch*.12,Vector2(c.dir*(1.+crouch*.12),1.-crouch*.28))
	chicken_node.draw_texture_rect(art.texture(cel.file),Rect2((cel.left-atlas.cellWidth*.5)*s,-cel.height*s,cel.width*s,cel.height*s),false,Color(0.76,0.73,0.69,1.0))
	chicken_node.draw_set_transform(Vector2.ZERO)

func draw_ground():
	if phase!="title":episode_combat.draw_ground(self,ground_fx)
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
	episode_combat.draw_air(air_fx)
	for s in sparks:
		var color=s.color
		color.a=clamp(s.life*2,0,1)
		air_fx.draw_rect(Rect2(s.x,s.y,4,2),color)
	for f in enemies:
		if not f.boss and f.hp>0 and clock<f.get("healthBarUntil",-1.0):
			air_fx.draw_rect(Rect2(f.x-35,f.y-272,70,4),Color("000000"))
			air_fx.draw_rect(Rect2(f.x-35,f.y-272,70*f.hp/f.max,4),Color("b51219"))
	if spell>=17 and spell<77:
		var tip=art.weapon_tip(hero,["hero-cast-unarmed-v1",4 if spell<45 else 5])
		var elapsed=(spell-17)*m.STEP
		var cycle=int(elapsed/.16)
		lightning(air_fx,tip,Vector2(tip.x,-55),93417+cycle*104729,(spell-16)/3.0)
		if spell>=20:
			for f in enemies:
				if f.hp>0 and f.x>=0 and f.x<=1440: lightning(air_fx,Vector2(f.x,-55),Vector2(f.x,f.y-100),f.id*7919+cycle*104729,fmod(elapsed,.16)/.04)
	if not chicken.is_empty() and clock<chicken.get("lightning_until",-1.0):
		lightning(air_fx,Vector2(chicken.x,-55),Vector2(chicken.x,chicken.y-chicken.height*4.5-25),7193+int(clock/.04)*7919,1.0)
	for f in enemies:
		if f.boss and f.hp>0:
			var top=43-position.y
			center_text(air_fx,{"champion":"Cairn Champion","king":"The Drowned King","saint":"The Kiln Saint"}.get(f.kind,"Boss")+(" - Unbound" if f.phaseTwo else ""),Vector2(720,top),20,Color("e6d2aa"))
			air_fx.draw_rect(Rect2(510,top+11,420,8),Color("000000"))
			air_fx.draw_rect(Rect2(510,top+11,420*f.hp/f.max,8),Color("b51219"))

func center_text(node: Node2D,text: String,p: Vector2,size: int,color: Color):
	node.draw_string(serif,p-Vector2(serif.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func draw_hud():
	if phase=="title": return
	var s=1440.0/2172
	var extra=screen_size.x/hud.scale.x-1440.
	var stretch=1.+extra/(901*s)
	hud.draw_set_transform(Vector2.ZERO)
	var frame=art.texture("hud-native-frame.png")
	var uv_scale=frame.get_size()/Vector2(1440,296)
	for section in [Vector3(0,220,220),Vector3(220,550,550+extra),Vector3(770,670,670)]:
		var x=section.x+(extra if section.x>=770 else 0.)
		hud.draw_texture_rect_region(frame,Rect2(x,766,section.z,296),Rect2(Vector2(section.x,0)*uv_scale,Vector2(section.y,296)*uv_scale))
	# Stretch only the meter span; end ornaments and equipment panels retain their shape.
	hud.draw_set_transform(Vector2(298*s*(1.-stretch),810),0,Vector2(s*stretch,252.0/380))
	for i in 2:
		var top=70+i*140
		var value=displayed_health if i==0 else displayed_mana
		var colors=[Color("bf221e"),Color("710807")] if i==0 else [Color("269bff"),Color("074891")]
		# Readiness persists through attacks and jumps; pulse the visible fill, not just its frame.
		if i==1 and magic>=100:
			var pulse=(.5+.5*sin(clock*TAU*1.5))*.65
			colors[0]=colors[0].lerp(Color("d5f4ff"),pulse)
			colors[1]=colors[1].lerp(Color("68caff"),pulse)
		# One solid polygon survives downscaling; one-pixel scanlines can vanish in WebGL.
		var fill_width=901*clamp(value/100.,0.,1.)
		if fill_width>0:
			var left=298.0
			var right=left+fill_width
			var upper=top+17.0
			var lower=upper+77.0
			var bevel=min(7.,fill_width*.5)
			var points=PackedVector2Array([Vector2(left+bevel,upper),Vector2(right-bevel,upper),Vector2(right,upper+bevel),Vector2(right,lower-bevel),Vector2(right-bevel,lower),Vector2(left+bevel,lower),Vector2(left,lower-bevel),Vector2(left,upper+bevel)])
			hud.draw_polygon(points,PackedColorArray([colors[0],colors[0],colors[0],colors[1],colors[1],colors[1],colors[1],colors[0]]))
		if i==1 and magic>=100: hud.draw_rect(Rect2(298,top+17,901,77),Color(.6,.86,1,.5+.3*sin(clock*5)),false,4)
	hud.draw_set_transform(Vector2.ZERO)
	hero_voice.draw_portrait(hud,Rect2(1400*s+extra-80,810+46,160,180))
	hud.draw_set_transform(Vector2.ZERO)
	score_panel.position=Vector2(1758*s+extra,830)
	score_panel.queue_redraw()

func draw_overlay():
	if phase=="title":
		var tall=screen_size.y>1200
		# Share the menu's actual anchor; keep generous gutters in the open art column.
		var center=menu.to_global(Vector2(417.6,0)).x
		var gutter=screen_size.x*.09
		var open_right=screen_size.x-gutter if tall else screen_size.x*.64-gutter
		var safe_width=2.*max(1.,min(center-gutter,open_right-center))
		var width=min(safe_width,(min(1200.0,screen_size.x*.86) if tall else min(900.0,screen_size.x*.66))*.6)
		var size=title_logo.get_size()*width/title_logo.get_width()
		var t=clampf(title_intro/1.25,0.,1.)
		# Perspective depth accelerates into the foreground instead of easing before contact.
		var approach=clampf(title_intro/.8,0.,1.)
		var travel=pow(approach,1.6)
		var landing=clampf((title_intro-.8)/.45,0.,1.)
		var recoil=sin(landing*TAU*1.2)*exp(-landing*6.)*(1.-landing)
		var zoom=1./(1.+3.2*(1.-travel))+recoil*.10
		var unrest=sin(PI*approach)*.8+abs(recoil)*.12
		var drift=Vector2(sin(title_intro*18.)+sin(title_intro*26.)*.25,cos(title_intro*21.)*.8)*unrest*4.
		var arc=Vector2(-22.*(1.-travel),-48.*sin(approach*PI))*zoom
		var pivot=Vector2(center,screen_size.y*.1+size.y*.5)+arc+drift
		overlay.draw_set_transform(pivot,0.,Vector2.ONE*zoom)
		overlay.draw_texture_rect(title_logo,Rect2(-size*.5,size),false,Color(1,1,1,smoothstep(0.,.3,t)))
		overlay.draw_set_transform(Vector2.ZERO)

	overlay.draw_set_transform(Vector2.ZERO)

func _draw():
	pass

func beep(frequency: float,_duration: float):
	if not audio:return
	if frequency==380:audio.play("shield",-4)
	elif frequency==230:
		audio.play("sword" if hero.weapon=="sword" else "axe",-5)
		audio.play("hero_effort",-13)
	elif frequency==160:audio.play("hero_effort",-12)
	else:audio.play("menu_select",-12)

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
	roast_chicken(1)
	chicken.x=1369
	chicken.vx=500
	step_chicken(.1)
	assert(chicken.x<=1370 and chicken.vx<0)
	chicken.x=71
	chicken.vx=-500
	step_chicken(.1)
	assert(chicken.x>=70 and chicken.vx>0)
	chicken.height=0
	chicken.flight=false
	chicken.x=hero.x
	chicken.y=hero.y
	hero.attack={}
	hero.air={}
	hero.down={}
	hero.hurtTicks=0
	step_chicken(m.STEP)
	assert(not hero.pickup.is_empty())
	for i in 76: step_chicken(m.STEP)
	assert(hero.hp==100 and chicken.is_empty())
	# A final enemy can finish burning while the player is still diving.
	hero.recovering=0
	hero.attack={}
	assert(m.start_jump(hero))
	m.motion(hero,1,0)
	assert(m.begin(hero,"air"))
	begin_walk("exit")
	assert(hero.jump==null and hero.air.is_empty() and not hero.diveUsed)
	assert(art.pose(hero)[0]=="hero-walk-unarmed-v8","Wave exit must use walk pose after a dive")
	begin_walk("enter")
	assert(art.pose(hero)[0]=="hero-walk-unarmed-v8")
	for i in 180: tick(m.STEP)
	assert(hero.x==720 and stage_walk=="")
	change_phase("paused")
	assert(phase=="paused" and menu.visible)
	change_phase("playing")
	damage(hero,{"damage":100,"direction":-1,"knock":true},boss)
	assert(phase=="dying" and wipe.age==-.5 and hero.gearDropped)
	var facing_probe=FighterView.new()
	facing_probe.art=art
	facing_probe.actor=make_actor(720,660,100,true)
	add_child(facing_probe)
	facing_probe.actor.dir=-1
	facing_probe.update_view(-1)
	facing_probe.reparent(arena_clip)
	for direction in [-1,1,-1,1]:
		facing_probe.actor.dir=direction
		facing_probe.update_view(-1)
		assert(facing_probe.transform.x.is_equal_approx(Vector2(direction*facing_probe.actor.size,0)))
		assert(facing_probe.transform.y.is_equal_approx(Vector2(0,facing_probe.actor.size)))
	facing_probe.queue_free()
	print("CAIRN_FACING_OK: mirrored fighter remains upright after arena reparent and repeated turns")
	print("CAIRN_INTEGRATION_OK: shield windows, boss commitment, stun escape, magic duration, grounded burn, chicken pickup, stage entry, pause and death")
	get_tree().quit()



func responsive_layout():
	var window_size=get_window().size
	if window_size==last_window_size:return
	last_window_size=window_size
	screen_size=Vector2(1440,1440.0*window_size.y/max(1,window_size.x))
	get_window().content_scale_size=Vector2i(screen_size)
	var hud_scale=clamp(screen_size.y*.23/252.,.4,1.)
	var hud_height=252*hud_scale
	# Fit the arena width, reserving the upper painting as vertical crop space.
	# Bottom alignment preserves the fighting floor immediately above the HUD.
	scale=Vector2.ONE
	var bottom_crop=float(background.screen.get("framing",{}).get("bottom_crop",0.0)) if background else 0.0
	position=Vector2(0,screen_size.y-hud_height-810.+810.*bottom_crop)
	hud.scale=Vector2.ONE*hud_scale
	hud.position=Vector2(0,screen_size.y-1062*hud_scale)
	overlay.position=Vector2.ZERO
	overlay.scale=Vector2.ONE
	menu.layout_screen(screen_size,phase=="title")
	if is_instance_valid(wipe):
		wipe.top_level=true
		wipe.position=Vector2.ZERO
		wipe.scale=screen_size/Vector2(1440,1062)
	screen_backdrop.queue_redraw()
	overlay.queue_redraw()
func draw_screen_backdrop():
	var painting=title_background if phase=="title" or not art else art.texture(background.key+"-base.png")
	var factor=max(screen_size.x/painting.get_width(),screen_size.y/painting.get_height())
	var size=painting.get_size()*factor
	screen_backdrop.draw_texture_rect(painting,Rect2((screen_size-size)*.5,size),false,Color.WHITE if phase=="title" else Color(.25,.25,.25))
func layout_test():
	for dimensions in [Vector2i(1280,720),Vector2i(1600,700),Vector2i(640,960)]:
		get_window().size=dimensions
		change_phase("title")
		await get_tree().create_timer(1.6).timeout
		await RenderingServer.frame_post_draw
		assert(abs(scale.x-scale.y)<.001)
		for item in menu.items:
			var point=menu.to_global(item.node.position)
			assert(point.y>=0 and point.y+item.height*menu.scale.y<=screen_size.y)
		get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/layout-title-%d.png"%dimensions.x)
		start_game()
		magic=60
		displayed_mana=60
		await get_tree().create_timer(.2).timeout
		transition=-1
		stage_walk=""
		hero.x=720
		await get_tree().create_timer(.1).timeout
		await RenderingServer.frame_post_draw
		assert(abs(hud.to_global(Vector2(0,1062)).y-screen_size.y)<2)
		assert(abs(hud.scale.x-hud.scale.y)<.001)
		assert(abs(hud.position.x)<.001)
		assert(abs(hud.to_global(Vector2(screen_size.x/hud.scale.x,1062)).x-screen_size.x)<.001)
		get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/layout-game-%d.png"%dimensions.x)
		var capture=get_viewport().get_texture().get_image()
		var pixel_scale=Vector2(capture.get_size())/screen_size
		var extra=screen_size.x/hud.scale.x-1440.
		for meter in 2:
			var point=hud.to_global(Vector2(298*1440./2172.+(901*1440./2172.+extra)*.25,810+(125+meter*140)*252./380.))*pixel_scale
			var color=capture.get_pixel(int(point.x),int(point.y))
			assert(color.r>color.g*1.4 if meter==0 else color.b>color.r*1.4,"HUD fill must survive responsive downscaling")
	print("CAIRN_LAYOUT_OK: landscape, ultrawide, portrait; menu bounds and HUD anchor")
	get_tree().quit()

func moves_test():
	start_game()
	transition=-1
	stage_walk=""
	for e in enemies:e.x=1500;e.aiRest=10000
	hero.x=720
	keys[KEY_J]=true
	pressed[KEY_J]=true
	tick(m.STEP)
	assert(hero.attack.type=="slash" and hero.attack.age==1,"Press must attack immediately")
	for i in 24:tick(m.STEP)
	assert(hero.attack.get("spin",false) and hero.spinUsed)
	var hp=hero.hp
	damage(hero,{"damage":5,"direction":-1,"knock":true},enemies[0])
	assert(hero.hp==hp and hero.attack.get("spin",false))
	if DisplayServer.get_name()!="headless":
		await get_tree().create_timer(.05).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/spin-action.png")
	for i in 90:tick(m.STEP)
	assert(hero.attack.is_empty() and hero.spinUsed,"Holding cannot repeat spin")
	keys.erase(KEY_J)
	tick(m.STEP)
	assert(not hero.spinUsed)
	keys[KEY_J]=true
	pressed[KEY_J]=true
	for i in 26:tick(m.STEP)
	assert(hero.attack.get("spin",false))
	var guard=make_actor(800,660,20,false)
	guard.kind="shield"
	guard.dir=-1
	enemies.append(guard)
	hero.diveHit=false
	var dive={"damage":4.5,"dive":true,"direction":1,"knock":true}
	damage(guard,dive.duplicate(),hero)
	assert(guard.hp==20 and not hero.diveHit,"Visible guard must block aerial hits")
	m.begin(guard,"shieldBash")
	guard.attack.age=guard.attack.from-6
	damage(guard,dive.duplicate(),hero)
	assert(guard.hp<20 and not guard.down.is_empty() and hero.diveHit and hit_stop>0,"Exposed shield must be flattened")
	var near=m.make(900,780,650,30)
	var fringe=m.make(901,910,650,30)
	var distant=m.make(902,1150,650,30)
	var above=m.make(903,760,580,30)
	var below=m.make(904,760,720,30)
	var expanded=m.make(905,1100,650,30)
	var large=m.make(906,760,580,30)
	large.size=1.4
	var small=m.make(907,760,580,30)
	small.size=.8
	enemies=[near,fringe,distant,above,below,expanded,large,small]
	hero.diveHit=false
	hero.x=720
	hero.y=650
	hero.height=25
	assert(not m.can_hit(hero,near,{"dive":true}),"Dive must not connect while airborne")
	hero.height=0
	resolve_slam(Vector2(760,650),{"dive":true,"damage":4.5,"knock":true,"direction":1})
	assert(near.hp<30 and fringe.hp==30 and distant.hp==30)
	assert(near.slamPush.length()>fringe.slamPush.length() and fringe.slamPush.length()>0)
	assert(not distant.has("slamPush"))
	assert(above.slamPush.y<0 and below.slamPush.y>0)
	assert(small.slamPush.length()>above.slamPush.length() and large.slamPush.length()<above.slamPush.length())
	assert(is_equal_approx(above.slamPush.length(),pow(1.0-126.0/375.0,1.2)*500.0))
	assert(abs(above.slamPush.x)<.01 and abs(below.slamPush.x)<.01)
	assert(expanded.slamPush.x>0,"Expanded radius must reach enemies 340 units from impact")
	var old_x=fringe.x
	tick_actor(fringe,m.STEP)
	assert(fringe.x>old_x,"Undamaged enemy should move with the pressure wave")
	print("CAIRN_HOLD_OK: instant slash, hold transition, interruption protection, release-to-rearm")
	get_tree().quit()

func archer_test():
	set_process(false)
	start_game()
	hero.x=720
	hero.y=660
	hero.hp=100
	hero.invTicks=0
	hero.air={}
	hero.attack={}
	var archer=make_actor(350,660,6)
	archer.kind="archer"
	archer.dir=1
	assert(e_ai.archer_intent(archer,hero).is_zero_approx() and archer.attack.type=="archerShot")
	archer.attack={}
	archer.x=550
	assert(e_ai.archer_intent(archer,hero).x<0,"Archer must retreat when crowded")
	archer.x=-100
	hero.x=400
	assert(e_ai.archer_intent(archer,hero).is_zero_approx() and archer.attack.type=="archerShot","Archers can fire from offscreen")
	archer.attack={}
	hero.x=720
	archer.x=350
	var arrow=load("res://scripts/arrow.gd").new()
	arena_clip.add_child(arrow)
	arrow.setup(self,archer)
	for i in 90:
		arrow.advance(1.0/120)
		if arrow.attached:break
	assert(arrow.attached and is_equal_approx(hero.hp,100.-8.5*(100./48.)*damage_multiplier),"Arrow damage must respect global tuning and embed")
	assert(not blood.drops.is_empty(),"Arrow impact must emit blood")
	assert(hero.hurtTicks==0 and hero.recovering==0 and hero.recoil==0,"Arrow hits must not stun")
	arrow.advance(.51)
	assert(arrow.is_queued_for_deletion(),"Embedded arrow must expire in half a second")
	var miss=load("res://scripts/arrow.gd").new()
	arena_clip.add_child(miss)
	miss.setup(self,archer)
	hero.invTicks=999
	for i in 240:
		miss.advance(1.0/120)
		if miss.stuck>=0:break
	assert(miss.stuck>=0 and not miss.attached and miss.point.z==0,"Missed arrow must land under gravity")
	miss.advance(.51)
	assert(miss.is_queued_for_deletion())
	print("CAIRN_ARCHER_OK: retreat, draw, ballistic hit, blood, embedding and expiry")
	get_tree().quit()
