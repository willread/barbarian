extends SceneTree
# Offline trailer staging. Uses live combat; does not change normal gameplay.
var game
var frame=0
var shot=-1
var local_frame=0
var ready_capture=false
func _init():
	root.size=Vector2i(1920,1080)
	call_deferred("setup")
func setup():
	seed(413)
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.muted=false
	game.music_enabled=false
	game.voice_enabled=true
	game.master_volume=85
	game.apply_settings(false)
	game.audio.unlocked=true
	ready_capture=true
func stage(index):
	if shot>=0:print("SHOT ",shot," kills=",game.kills," HP=",game.hero.hp)
	shot=index
	local_frame=0
	if index==6:
		game.clear_world()
		game.transition=-1
		game.stage_walk=""
		game.change_phase("title")
		game.menu.visible=false
		game.audio.play("menu_land",-2)
		return
	game.start_game()
	game.wave=[1,3,5,5,7,9][index]
	game.spawn_wave()
	game.clear_world()
	game.phase="playing"
	game.transition=-1
	game.stage_walk=""
	game.hero=game.make_actor(590,655,100,true)
	game.hero.weapon="sword" if index in [1,4] else "axe"
	game.weapon=game.hero.weapon
	game.hero.dir=1
	game.hero.invTicks=0
	game.magic=100 if index==4 else 35
	game.displayed_mana=game.magic
	var types=["bone","legion","bone"]
	var places=[Vector2(685,650),Vector2(885,670),Vector2(470,665)]
	if index==1:types=["legion","archer"];places=[Vector2(795,655),Vector2(1050,640)]
	if index==2:types=["bone","bone","archer"];places=[Vector2(850,655),Vector2(1000,665),Vector2(1170,625)]
	if index==3:types=["legion","bone","marauder"];places=[Vector2(730,655),Vector2(465,655),Vector2(925,670)]
	if index==4:types=["legion","shield","marauder","bone"];places=[Vector2(325,665),Vector2(830,650),Vector2(1080,670),Vector2(480,640)]
	if index==5:types=["champion"];places=[Vector2(840,655)]
	for i in types.size():
		var kind=types[i]
		var e=game.make_actor(places[i].x,places[i].y,game.e_ai.roster[kind].hp)
		e.kind=kind
		e.boss=kind=="champion"
		e.dir=-1 if e.x>game.hero.x else 1
		game.e_ai.variant(e)
		e.aiRest=95+i*12
		if not e.boss:
			e.hp=minf(e.hp,4.0) # Stage a mid-fight finish; normal damage and reactions remain intact.
			e.size=1.0
			e.speedFactor=1.0
		game.background.constrain(e)
		game.enemies.append(e)
	game.background.constrain(game.hero)
func _process(_delta):
	if not ready_capture:return false
	# 0–4 slam; 4–8 sword; 8–12 charge; 12–16 spin; 16–21 magic; 21–26 boss; 26–30 logo.
	var target=0 if frame<120 else 1 if frame<240 else 2 if frame<360 else 3 if frame<480 else 4 if frame<630 else 5 if frame<780 else 6
	if target!=shot:stage(target)
	if shot<6:
		game.transition=-1
		game.stage_walk=""
		game.keys.clear()
		if shot in [0,1,2] and local_frame>30:
			var nearest={}
			for e in game.enemies:
				if e.hp>0 and (nearest.is_empty() or absf(e.x-game.hero.x)<absf(nearest.x-game.hero.x)):nearest=e
			if not nearest.is_empty():
				game.hero.dir=1 if nearest.x>game.hero.x else -1
				if absf(nearest.x-game.hero.x)>120:game.keys[KEY_D if game.hero.dir==1 else KEY_A]=true
		if shot==0:
			if local_frame==1:game.m.start_jump(game.hero)
			if local_frame==9:game.m.begin(game.hero,"air")
			if local_frame in [40,60,80,100]:game.m.begin(game.hero,"slash")
		elif shot==1:
			if local_frame<15:game.keys[KEY_D]=true
			if local_frame in [8,28,49,70,95]:game.m.begin(game.hero,"slash")
		elif shot==2:
			if local_frame<14:game.keys[KEY_D]=true
			if local_frame==12:game.m.begin(game.hero,"charge")
			if local_frame in [40,60,80,100]:game.m.begin(game.hero,"slash")
		elif shot==3:
			if local_frame==2:game.m.begin(game.hero,"slash")
			if local_frame<48:game.keys[KEY_J]=true
			if local_frame==67:game.m.start_jump(game.hero)
			if local_frame==76:game.m.begin(game.hero,"air")
		elif shot==4:
			if local_frame==9:game.pressed[KEY_K]=true
			if local_frame in [95,120]:game.m.begin(game.hero,"back")
		elif shot==5:
			if local_frame<18:game.keys[KEY_D]=true
			if local_frame in [10,39,70,112]:game.m.begin(game.hero,"slash")
			if local_frame==87:game.m.start_jump(game.hero)
			if local_frame==96:game.m.begin(game.hero,"air")
	else:game.menu.visible=false
	frame+=1
	local_frame+=1
	if frame>=901:quit()
	return false
