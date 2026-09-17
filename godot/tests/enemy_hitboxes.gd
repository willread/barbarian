extends SceneTree
# Painted head/torso landmarks, independent of the collision profile dimensions.
const LANDMARKS={
 "bone":[Vector2(0,-52),Vector2(-3,-34)],
 "shield":[Vector2(1,-49),Vector2(-3,-34)],
 "marauder":[Vector2(5,-46),Vector2(-2,-32)],
 "legion":[Vector2(9,-53),Vector2(0,-34)],
 "archer":[Vector2(2,-49),Vector2(0,-33)],
 "champion":[Vector2(-4,-60),Vector2(-8,-39)],
 "witch":[Vector2(3,-39),Vector2(-6,-25)],
 "bearer":[Vector2(14,-44),Vector2(0,-28)],
 "king":[Vector2(9,-74),Vector2(0,-43)],
 "saint":[Vector2(0,-80),Vector2(-5,-53)],
}
func _init():
 var m=CairnMechanics.new()
 var art=CairnArt.new()
 for kind in art.HEIGHTS:
  assert(LANDMARKS.has(kind) and m.ENEMY_BODIES.has(kind),"Every rendered enemy needs an authored body profile: "+kind)
  var enemy=m.make(2,720,660,100);enemy.kind=kind
  var hero=m.make(1,720,660,100,true)
  for size in [.702,1.,1.18]:
   enemy.size=size
   for direction in [-1,1]:
    enemy.dir=direction
    for state in ["idle","walking","windup","strike","hurt","recovering"]:
     enemy.moving=state=="walking"
     enemy.attack={"type":"enemySlash","age":12 if state=="strike" else 0} if state in ["windup","strike"] else {}
     enemy.hurtTicks=12 if state=="hurt" else 0
     enemy.recovering=12 if state=="recovering" else 0
     for landmark in LANDMARKS[kind]:
      # A tiny airborne strike at the visible head/torso exercises real XY overlap.
      hero.height=1
      var strike={"type":"air","reach":35,"direction":direction,"box":[landmark.x*size-1,2,landmark.y*size,2]}
      assert(m.can_hit(hero,enemy,strike),"Visible body contact: %s / %s / %s"%[kind,state,direction])
      hero.y=enemy.y+m.MELEE_LANE
      assert(not m.can_hit(hero,enemy,strike),"Different floor lanes must miss")
      hero.y=enemy.y
      enemy.invTicks=1
      assert(not m.can_hit(hero,enemy,strike),"Invulnerability still protects")
      enemy.invTicks=0
      enemy.down={"ground":1}
      assert(not m.can_hit(hero,enemy,strike),"Downed bodies remain excluded")
      enemy.down={}
     hero.height=0
     var outside={"type":"slash","reach":35,"direction":direction,"box":[50*size,2,-30,2]}
     assert(not m.can_hit(hero,enemy,outside),"Extended weapons are not receiving bodies")
     enemy.height=8
     var raised=m.receiving_rect(enemy)
     var grounded=raised.position.y+8
     enemy.height=0
     assert(is_equal_approx(grounded,m.receiving_rect(enemy).position.y),"Jump height remains independent of body size")
     enemy.height=0
     enemy.moving=false;enemy.attack={};enemy.hurtTicks=0;enemy.recovering=0
     var fitted=m.rect(enemy,m.ENEMY_BODIES[kind],direction)
     var target=m.receiving_rect(enemy)
     assert(target.size.is_equal_approx(fitted.size*.8),"Ten percent grace on each edge")
     assert(target.get_center().is_equal_approx(fitted.get_center()),"Inset must not shift the body")
     for side in [-1,1]:
      var x=(fitted.position.x if side<0 else target.end.x)+fitted.size.x*.025
      hero.height=1
      var glance={"type":"air","reach":35,"direction":1,"box":[x-hero.x/m.SCALE,fitted.size.x*.025,target.get_center().y-hero.y/m.SCALE+1,1]}
      assert(not m.can_hit(hero,enemy,glance),"Glancing contact inside the silhouette margin must miss")
 # Separate Saint atlases shift his actual chest/head forward from idle.
 var saint=m.make(2,720,660,100);saint.kind="saint"
 var attacker=m.make(1,720,660,100,true);attacker.height=1
 for direction in [-1,1]:
  saint.dir=direction
  for action in ["walk","volley"]:
   saint.moving=action=="walk"
   saint.attack={"type":"saintVolley"} if action=="volley" else {}
   var x=28 if action=="walk" else 18
   assert(m.can_hit(attacker,saint,{"type":"air","reach":35,"direction":direction,"box":[x,2,-75,2]}),"Saint contact must follow the shifted torso atlas")
 print("CAIRN_ENEMY_HITBOXES_OK: ten enemy bodies, painted head/torso contacts, six states, both facings, three sizes, air height, lanes and immunity")
 quit()
