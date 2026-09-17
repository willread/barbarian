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
	var blast_guard=m.make(90,800,660,20)
	blast_guard.kind="shield"
	blast_guard.dir=1
	hero.x=900
	assert(not ai.block(blast_guard,{"origin_x":700,"knock":false},hero),"Rear blast bypasses guard even with player in front")
	hero.x=700
	assert(ai.block(blast_guard,{"origin_x":900,"knock":false},hero),"Front blast respects guard even with player behind")
	hero.x=720
	hero.running=true
	assert(m.start_jump(hero) and hero.velocityX==3.2)
	assert(m.begin(hero,"air") and hero.attack.from==3)
	assert(hero.spinUsed and hero.holdTicks==0,"Slam consumes the held attack press")
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
	var slam=m.make(101,720,660,100,true)
	m.start_jump(slam);m.begin(slam,"air")
	for i in 180:
		slam.recovering=maxi(0,slam.recovering-1)
		m.motion(slam,0,0)
	assert(slam.air.is_empty() and slam.attack.is_empty())
	assert(not m.begin(slam,"spin"),"Holding through a completed slam cannot start a spin")
	slam.spinUsed=false # Input re-arms only after release.
	assert(m.begin(slam,"spin"),"A new press may spin after the slam")
	var sword=m.make(1,720,660,100,true)
	sword.weapon="sword"
	m.start_jump(sword)
	assert(sword.velocityX==0)
	m.begin(sword,"air")
	assert(sword.attack.from==2 and sword.attack.box[1]==hero.attack.box[1] and sword.attack.damage<axe_damage)
	var spinner=m.make(1,720,660,100,true)
	assert(m.begin(spinner,"spin"))
	var art=CairnArt.new()
	# Every weapon shares Gravecleaver's collision geometry, across swing poses.
	var baseline=m.make(300,720,660,100,true)
	baseline.weapon_skin="gravecleaver"
	for move in ["slash","back","spin"]:
		baseline.attack={};m.begin(baseline,move)
		for age in range(int(baseline.attack.from),int(baseline.attack.to)+1):
			baseline.attack.age=age
			var pose=art.pose(baseline)
			var expected=art.hit_box(baseline,pose)
			for weapon in ["axe","sword"]:
				for skin in ["gravecleaver","blacktooth","barrow_star","gatebreaker","candy_cane"]:
					var other=baseline.duplicate(true)
					other.weapon=weapon;other.weapon_skin=skin
					assert(art.hit_box(other,pose)==expected,"Weapon appearance must not change combat reach")
	for weapon in ["axe","sword"]:
		for facing in [-1,1]:
			var fighter=m.make(200,720,660,100,true)
			fighter.weapon=weapon;fighter.dir=facing
			m.begin(fighter,"slash")
			fighter.attack.age=fighter.attack.from
			var pose=art.pose(fighter)
			var extended=art.hit_box(fighter,pose)
			fighter.attack.type="back"
			var original=art.hit_box(fighter,pose)
			var old_end=original[0]+original[1]
			var new_end=extended[0]+extended[1]
			assert(is_equal_approx(new_end,old_end*1.2))
			assert(extended[0]==original[0] and extended[2]==original[2] and extended[3]==original[3])
			var target=m.make(201,720+facing*((old_end+new_end)*.5+16)*m.SCALE,660,100)
			target.dir=facing
			fighter.attack.box=original
			assert(not m.can_hit(fighter,target,fighter.attack))
			fighter.attack.type="slash";fighter.attack.box=extended
			assert(m.can_hit(fighter,target,fighter.attack),"Normal attack hits in the added reach in either direction")
	# Real weapon poses must cover both edges of the melee lane symmetrically.
	for player_move in ["slash","spin"]:
		for weapon in ["axe","sword"]:
			for facing in [-1,1]:
				for depth in [-48,-47,-36,0,36,47,48]:
					var player=m.make(100,720,660,100,true)
					player.weapon=weapon
					player.dir=facing
					var foe=m.make(101,720+100*facing,660+depth,100)
					foe.dir=-facing
					m.begin(player,player_move)
					var connected=false
					for age in range(int(player.attack.from),int(player.attack.to)+1):
						player.attack.age=age
						player.attack.box=art.hit_box(player,art.pose(player))
						connected=connected or m.can_hit(player,foe,player.attack)
					assert(connected==(abs(depth)<48),"Player swing must reach either lane edge, never outside")
					for move in data.attacks:
						if move in ["whiff","slash","pommel","kick","air","back","charge"]:continue
						foe.attack={}
						m.begin(foe,move)
						assert(not m.can_hit(foe,player,foe.attack) or connected,"Enemy melee cannot reach a lane the player cannot hit: "+move)
	var jumper=m.make(102,720,660,100,true)
	var grounded=m.make(103,820,660,100)
	grounded.dir=-1
	m.begin(grounded,"enemy")
	jumper.height=100
	assert(not m.can_hit(grounded,jumper,grounded.attack),"Ground attacks must not hit above their jump-height reach")
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
	assert(runner.spinUsed and not m.begin(runner,"spin"),"Holding after a charge cannot trigger spin, including recoil")
	runner.spinUsed=false # Attack release re-arms a new press.
	assert(m.begin(runner,"spin"),"A fresh press can still escape charge recoil")
	assert(runner.hurtTicks==0 and runner.recovering==0 and runner.chargeRebound==0)
	var trapped=m.make(11,720,660,100,true)
	m.hurt(trapped,{"direction":1,"knock":true})
	assert(m.begin(trapped,"spin"),"Spin must escape knockdown")
	assert(trapped.down.is_empty() and trapped.attack.spin)
	var staggered=m.make(12,720,660,100,true)
	m.hurt(staggered,{"direction":1,"knock":false})
	assert(m.begin(staggered,"spin"),"Spin must escape ordinary stun")
	assert(staggered.hurtTicks==0 and staggered.recovering==0)
	staggered.attack={}
	staggered.hp=0
	assert(not m.begin(staggered,"spin"),"Spin cannot resurrect player")
	var leaper=m.make(13,720,660,100)
	m.begin(leaper,"enemyCharge")
	m.motion(leaper,0,0)
	assert(leaper.height>0)
	m.interrupt_attack(leaper)
	assert(leaper.height==0 and leaper.attack.is_empty(),"Interrupted charge cannot leave floating enemy")
	m.hurt(leaper,{"direction":1,"knock":true})
	m.reaction(leaper)
	var airborne=leaper.height
	m.interrupt_attack(leaper)
	assert(leaper.height==airborne and not leaper.down.is_empty(),"Do not cancel real knockdown physics")
	var slow=m.make(20,800,660,100)
	slow.size=1.18
	slow.dir=1
	var behind=m.make(21,700,660,100,true)
	for i in 23:
		ai.intent(slow,behind,true)
		assert(slow.dir==1,"Heavy legion must not instantly face a flanking player")
	ai.intent(slow,behind,true)
	assert(slow.dir==-1 and slow.aiRest>=12)
	var crowd=[m.make(31,720,660,10),m.make(32,720,660,10),m.make(33,720,660,10)]
	for i in 8:ai.separate(crowd)
	for i in crowd.size():
		for j in range(i+1,crowd.size()):
			assert(abs(crowd[i].x-crowd[j].x)>=121.9,"Stacked enemies must separate")
	print("CAIRN_MOVES_OK: shield opening, dive startup/momentum/recovery, weapon distinction, spin sides/once/lane")
	quit()
