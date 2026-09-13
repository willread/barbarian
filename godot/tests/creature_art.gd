extends SceneTree
func _init():
	var art=load("res://scripts/art.gd").new()
	var mechanics=load("res://scripts/mechanics.gd").new()
	var hero=mechanics.make(1,720,650,100,true)
	assert(art.has_separate_weapon(hero),"Player must retain weapon despite legacy legion kind")
	hero.player=false
	assert(not art.has_separate_weapon(hero),"Minotaurs remain unarmed")
	var archer={"kind":"archer","hp":0,"down":{"ground":0,"vz":-2}}
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
