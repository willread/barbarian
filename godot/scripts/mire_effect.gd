extends Node2D
# Fresh isolated oil hands and animated oil slick, with independent depth sorting.
const FORM_SECONDS=1.4
const HAND_STEP_SECONDS=.15
const DRAW_RECT=Rect2(-72,-98.8,144,130)
var texture: Texture2D
var mode=0
var progress=0.0
var clock=0.0
var phase=0.0
var exiting=false
var finished=false
var exit_start=0.0
var exit_age=0.0
var layers: Array=[]
var spots: Array=[]

func _ready():
	spots=preload("res://scripts/mire_layout.gd").spots(position)
	for spot in spots:
		for part in 2:
			var layer=Sprite2D.new()
			layer.centered=false
			layer.texture=texture
			layer.position=DRAW_RECT.position+spot.offset
			layer.scale=DRAW_RECT.size/texture.get_size()
			layer.z_as_relative=false
			layer.material=ShaderMaterial.new()
			layer.material.shader=preload("res://shaders/mire_sequence.gdshader")
			layer.material.set_shader_parameter("part",part)
			layer.material.set_shader_parameter("seed",spot.seed)
			add_child(layer)
			layers.append(layer)

func refresh_layers():
	for i in layers.size():
		var layer=layers[i]
		var spot=spots[i/2]
		layer.visible=not finished
		layer.z_index=-4 if i%2==0 else int((position.y+spot.offset.y)*2)+1
		layer.material.set_shader_parameter("clock",clock+spot.seed*.01)
		layer.material.set_shader_parameter("formation",clampf(phase,0,1))
		layer.material.set_shader_parameter("pose",clampf(phase-1,0,3))

func configure(new_mode: int,remaining: float,time: float):
	if exiting:return
	mode=new_mode;progress=remaining;clock=time
	if mode==0:phase=clampf(progress,0,1)
	elif clock<.45:phase=1+clock/HAND_STEP_SECONDS
	else:phase=3.5+.5*cos((clock-.45)*TAU/1.2)
	if mode==1 and remaining<=FORM_SECONDS+maxf(0,phase-1)*HAND_STEP_SECONDS:retire()
	refresh_layers()

func retire():
	if exiting:return
	exiting=true
	exit_start=phase
	exit_age=0.0

func advance(dt: float):
	if not exiting:return
	exit_age+=dt
	clock+=dt
	var hand_time=maxf(0,exit_start-1)*HAND_STEP_SECONDS
	if exit_age<hand_time:phase=exit_start-exit_age/HAND_STEP_SECONDS
	else:phase=maxf(0,minf(exit_start,1)-(exit_age-hand_time)/FORM_SECONDS)
	finished=phase<=0
	refresh_layers()

