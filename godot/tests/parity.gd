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
	for i in 100:
		var plan=enemy_ai.plan()
		assert(plan.size()==8 and plan[7]==["champion"])
		assert(plan[0][0]=="archer")
		var types=[]
		for wave in plan:
			for kind in wave:
				if not kind in types: types.append(kind)
		assert(types.size()==6)
	print("CAIRN_PARITY_OK: ",checked," frame snapshots, weapon timing and 100 encounter plans")
	quit()

