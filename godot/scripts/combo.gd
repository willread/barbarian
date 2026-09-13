class_name CairnCombo
extends RefCounted
var hits=0
var remaining=0.0
var timeout=5.0
var waiting_for_combat=false
var resume_grace=3.0
var hits_per_tier=3
var max_multiplier=10
var heal_threshold=5
var heal_per_second=1.5
func multiplier() -> int:return mini(max_multiplier,1+int(hits/hits_per_tier))
func mana_multiplier() -> float:return 1.+(multiplier()-1)*.2
func hit():
	waiting_for_combat=false
	hits+=1
	remaining=timeout
func reset():
	hits=0
	remaining=0
	waiting_for_combat=false
func suspend():
	if hits>0:waiting_for_combat=true
func resume():
	if waiting_for_combat and hits>0:remaining=maxf(remaining,resume_grace)
	waiting_for_combat=false
func advance(dt: float) -> float:
	if waiting_for_combat:return 0.0
	var healing=heal_per_second*minf(dt,remaining) if multiplier()>=heal_threshold else 0.0
	remaining=maxf(0.,remaining-dt)
	if remaining==0:hits=0
	return healing
