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
	shield.attack.age=shield.attack.from-13
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
	var art=CairnArt.new()
	var frames=[]
	for age in range(2,34,2):
		spinner.attack.age=age
		frames.append(art.pose(spinner)[1])
	assert(frames==[0,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7],"Two complete faster rotations")
	spinner.attack.age=0
	var targets=[m.make(2,620,660,100),m.make(3,820,660,100),m.make(4,730,710,100)]
	var hits=[]
	for i in 45:m.tick_attack(spinner,targets,func(e,a,_h):hits.append([e.id,a.direction]))
	assert(hits==[[2,-1],[3,1]],"Spin must hit once per side and exclude distant lanes")
	var brute=m.make(9,800,660,100)
	brute.size=1.18
	assert(ai.heavy(brute))
	brute.size=.9
	assert(not ai.heavy(brute))
	var runner=m.make(10,720,660,100,true)
	m.begin(runner,"charge")
	m.rebound_charge(runner,1)
	assert(runner.attack.is_empty() and runner.hurtTicks==24 and runner.hp==100)
	for i in 5:m.reaction(runner)
	assert(runner.x<700 and runner.hurtTicks>0,"Rebound moves backward while stunned")
	var slow=m.make(20,800,660,100)
	slow.size=1.18
	slow.dir=1
	var behind=m.make(21,700,660,100,true)
	for i in 23:
		ai.intent(slow,behind,true)
		assert(slow.dir==1,"Heavy legion must not instantly face a flanking player")
	ai.intent(slow,behind,true)
	assert(slow.dir==-1 and slow.aiRest>=12)
	print("CAIRN_MOVES_OK: shield opening, dive startup/momentum/recovery, weapon distinction, spin sides/once/lane")
	quit()
