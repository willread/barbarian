extends RefCounted
const COMBAT=["sword","axe","flesh","heavy_hit","charge_hit","enemy_impact","bone","shield","resist","body_fall","landing","arrow_hit","lightning","fire","death_fire"]
const VOCALS=["hero_effort","hero_pain","magic_shout","roar","death"]
static func bus_for(id: String) -> StringName:
	if id.begins_with("music_"):return &"Music"
	if id in COMBAT:return &"Combat"
	if id in VOCALS:return &"Voice"
	return &"Foley"

static func setup():
	# AudioServer is shared by all scenes: install once, retaining master volume.
	if AudioServer.get_bus_index("Cairn Effects")>=0:return
	for name in ["Cairn Effects","Combat","Voice","Foley","Music"]:
		var index=AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(index,name)
		AudioServer.set_bus_send(index,"Master" if name in ["Cairn Effects","Music"] else "Cairn Effects")
	add_eq("Combat",[-3.,3.5,-2.,0.,1.,-1.])
	var grit=AudioEffectDistortion.new()
	grit.mode=AudioEffectDistortion.MODE_WAVESHAPE
	grit.drive=.12
	grit.pre_gain=1.
	grit.post_gain=-1.
	grit.keep_hf_hz=6000.
	add("Combat",grit)
	compress("Combat",-18.,2.5,2000.,110.,.55,1.)
	add_eq("Voice",[-6.,1.,-1.,0.,.5,-.5])
	compress("Voice",-16.,2.,2000.,140.,.45,.5)
	add_eq("Foley",[-4.,1.,-.75,0.,0.,-.5])
	compress("Foley",-14.,1.5,2000.,100.,.35,0.)
	compress("Cairn Effects",-10.,1.5,2000.,120.,.3,0.)
	var limiter=AudioEffectHardLimiter.new()
	limiter.ceiling_db=-1.
	limiter.release=.08
	add("Master",limiter)

static func add(name: String,effect: AudioEffect):
	AudioServer.add_bus_effect(AudioServer.get_bus_index(name),effect)
static func add_eq(name: String,bands: Array):
	var eq=AudioEffectEQ6.new()
	for i in bands.size():eq.set_band_gain_db(i,bands[i])
	add(name,eq)
static func compress(name: String,threshold: float,ratio: float,attack: float,release: float,mix: float,gain: float):
	var compressor=AudioEffectCompressor.new()
	compressor.threshold=threshold
	compressor.ratio=ratio
	compressor.attack_us=attack
	compressor.release_ms=release
	compressor.mix=mix
	compressor.gain=gain
	add(name,compressor)
