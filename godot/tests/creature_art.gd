extends SceneTree
func _init():
	var art=load("res://scripts/art.gd").new()
	var mechanics=load("res://scripts/mechanics.gd").new()
	var hero=mechanics.make(1,720,650,100,true)
	assert(art.has_separate_weapon(hero),"Player must retain weapon despite legacy legion kind")
	hero.player=false
	assert(not art.has_separate_weapon(hero),"Minotaurs remain unarmed")
	# Contact with the minotaur's forward torso/head used to miss the legacy box.
	var attacker=mechanics.make(2,720,650,100,true)
	for direction in [-1,1]:
		for size in [.72,1.,1.18]:
			hero.dir=direction;hero.size=size
			for state in ["idle","attack","hurt"]:
				hero.attack={"type":"enemySlash"} if state=="attack" else {}
				hero.hurtTicks=12 if state=="hurt" else 0
				var body=mechanics.receiving_rect(hero)
				var contact={"direction":direction,"type":"slash","reach":35,"box":[15*size,2*size,-54*size,4*size]}
				assert(mechanics.can_hit(attacker,hero,contact),"Forward torso must receive grounded hits in either facing")
				attacker.height=1
				assert(mechanics.can_hit(attacker,hero,contact),"Airborne strikes must reach the visible head")
				attacker.height=0
				contact.box=[26*size,2*size,-62*size,4*size]
				assert(not mechanics.can_hit(attacker,hero,contact),"Strikes beyond the body must miss")
				attacker.y=hero.y+mechanics.MELEE_LANE
				contact.box=[15*size,2*size,-54*size,4*size]
				assert(not mechanics.can_hit(attacker,hero,contact),"Body size must not widen the floor lane")
				attacker.y=hero.y
				assert(body.end.y<hero.y/mechanics.SCALE,"Receiving box leaves a little grace at the feet")
	var archer={"kind":"archer","hp":0,"attack":{},"down":{"ground":0,"vz":-2}}
	assert(art.enemy_frame(archer)==10)
	archer.down.vz=2
	assert(art.enemy_frame(archer)==11)
	archer.down.ground=1
	assert(art.enemy_frame(archer)==12)
	var atlas=art.data.atlases["enemy-archer-v1"]
	assert(atlas.cels[12].width>atlas.cels[12].height*2,"Archer corpse must be horizontal")
	assert(art.data.atlases["enemy-legion-v1"].cels.size()==16)
	for engulf in [.8,1.,1.3]:
		var end=.15+engulf+.6
		assert(BurningSprite.flare_envelope(0.,engulf)==0.)
		assert(BurningSprite.flare_envelope(.6,engulf)==1.)
		assert(BurningSprite.flare_envelope(end,engulf)==0.)
		for step in range(1,6):
			var age=step*.1
			assert(is_equal_approx(BurningSprite.flare_envelope(age,engulf),BurningSprite.flare_envelope(end-age,engulf)),"Ignition mirrors the existing fade-down")
	print("CAIRN_CREATURES_OK: archer ascending/falling/prone death poses and minotaur atlas")
	quit()
