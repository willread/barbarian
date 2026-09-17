extends SceneTree
func _init():
	var art=CairnArt.new()
	var m=CairnMechanics.new(art.data.attacks)
	m.combat_extensions=true
	for direction in [-1,1]:
		var hero=m.make(1,720,650,100,true)
		hero.dir=-1
		m.motion(hero,0,direction,0,true,direction)
		m.motion(hero,0,0,0,true)
		m.motion(hero,0,direction,0,true,direction)
		assert(hero.running and hero.runAxis==1 and hero.velocityY==direction*3)
		assert(hero.x==720 and hero.dir==-1,"Depth dash keeps position on X and facing")
		assert(m.select_strike(hero,[])!="charge","Depth dash does not launch a sideways charge")
		for i in 40:m.motion(hero,0,direction,0,true)
		assert(hero.y>=m.lane_min and hero.y<=m.lane_max and not hero.running)
	var jumper=m.make(1,720,650,100,true)
	jumper.running=true;jumper.runAxis=1;jumper.runDir=1
	assert(m.start_jump(jumper) and not jumper.air.carry and jumper.velocityX==0)
	print("CAIRN_VERTICAL_DASH_OK: both directions, lane bounds, facing, attack and jump transitions")
	quit()
