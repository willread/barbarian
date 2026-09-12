extends SceneTree
func _init():
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
	var m=CairnMechanics.new(data.attacks)
	var fixtures=JSON.parse_string(FileAccess.get_file_as_string("res://tests/parity.json"))
	var checked=0
	for fixture in fixtures:
		var f=m.make(1,720,660,100,true)
		var name=fixture.name
		for tick in 120:
			if name=="jump" and tick==0 or name=="run-jump" and tick==18: m.start_jump(f)
			if tick==0 and name in ["hurt","knockdown"]: m.hurt(f,{"direction":1,"knock":name=="knockdown"})
			var dx=1 if name in ["walk","diagonal","run","run-jump"] and tick<60 else 0
			m.reaction(f)
			m.motion(f,dx,1 if name=="diagonal" else 0,1 if name in ["run","run-jump"] and tick in [0,8] else 0,true)
			for key in fixture.samples[tick]:
				var expected=fixture.samples[tick][key]
				if abs(float(f[key])-float(expected))>.00001:
					push_error("Parity failure %s tick %d %s: %s != %s"%[name,tick,key,f[key],expected])
					quit(1)
					return
			checked+=1
	for weapon in ["axe","sword"]:
		var f=m.make(1,720,660,100,true)
		f.weapon=weapon
		assert(m.begin(f,"slash"))
		assert(f.attack.ticks==(22 if weapon=="axe" else 14))
		assert(f.attack.damage==(3 if weapon=="axe" else 2))
	var enemy_ai=CairnEnemies.new(m,data.roster)
	for v in ["swift","brute"]:
		var found=false
		for attempt in 100:
			var actor=m.make(99,720,660,16,false)
			actor.kind="legion"
			actor.boss=false
			enemy_ai.variant(actor,[v])
			if actor.variant!=v:continue
			found=true
			assert(is_equal_approx(actor.size,.72 if v=="swift" else 1.18))
			assert(is_equal_approx(actor.speedFactor,1.65 if v=="swift" else .68))
			assert(is_equal_approx(enemy_ai.damage_scale(actor),.65 if v=="swift" else 1.35))
		assert(found)
	assert(enemy_ai.damage_scale({})==1.0)
	for i in 100:
		var plan=enemy_ai.plan()
		assert(plan.size()==13 and plan[12]==["champion"])
		assert(enemy_ai.unlock_order.size()==3)
		assert(plan[0].size()==2 and plan[1].size()<=3 and plan[2].size()<=4)
		for w in 12:
			var screen=int(w/3)
			var allowed=["bone","legion"]+enemy_ai.unlock_order.slice(0,screen)
			for kind in plan[w]:assert(kind in allowed)
			assert(plan[w].size()<=9)
			assert(enemy_ai.wave_variants[w].size()==(0 if screen<2 else screen-1))
		var types=[]
		for wave in plan:
			for kind in wave:
				if not kind in types: types.append(kind)
		assert("bone" in types and "legion" in types and "champion" in types)
	print("CAIRN_PARITY_OK: ",checked," frame snapshots, weapon timing and 100 encounter plans")
	quit()


