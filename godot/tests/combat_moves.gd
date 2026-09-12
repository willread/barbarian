extends SceneTree
func _init():
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
	var m=CairnMechanics.new(data.attacks)
	m.combat_extensions=true
	var ai=CairnEnemies.new(m,data.roster)
	var shield=m.make(2,800,660,20)
	shield.kind="shield"
	shield.dir=-1
	assert(m.begin(shield,"shieldBash"))
	shield.attack.age=shield.attack.from-7
	assert(ai.guarding(shield))
	shield.attack.age+=1
	assert(not ai.guarding(shield) and ai.frame(shield)==5)
	var hero=m.make(1,720,660,100,true)
	hero.running=true
	assert(m.start_jump(hero) and hero.velocityX==3.2)
	assert(m.begin(hero,"air") and hero.attack.from==3)
	var axe_damage=hero.attack.damage
	var landing=[]
	for connected in [false,true]:
		var h=m.make(1,720,660,100,true)
		m.start_jump(h)
		m.begin(h,"air")
		h.diveHit=connected
		for i in 120:
			m.motion(h,0,0)
			if h.recovering:
				landing.append(h.recovering)
				assert(h.attack.is_empty())
				break
	assert(landing==[24,8])
	var sword=m.make(1,720,660,100,true)
	sword.weapon="sword"
	m.start_jump(sword)
	assert(sword.velocityX==0)
	m.begin(sword,"air")
	assert(sword.attack.from==2 and sword.attack.box[1]>hero.attack.box[1] and sword.attack.damage<axe_damage)
	var spinner=m.make(1,720,660,100,true)
	assert(m.begin(spinner,"spin"))
	var targets=[m.make(2,620,660,100),m.make(3,820,660,100),m.make(4,730,710,100)]
	var hits=[]
	for i in 45:m.tick_attack(spinner,targets,func(e,a,_h):hits.append([e.id,a.direction]))
	assert(hits==[[2,-1],[3,1]],"Spin must hit once per side and exclude distant lanes")
	print("CAIRN_MOVES_OK: shield opening, dive startup/momentum/recovery, weapon distinction, spin sides/once/lane")
	quit()
