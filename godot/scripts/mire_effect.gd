extends Node2D
# Keep the approved artwork and footprint; animate its buildup and reverse sequence.
const FORM_SECONDS=1.4
const HAND_STEP_SECONDS=.15
const DRAW_RECT=Rect2(-120,-91,240,120)
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

func _ready():
	for part in 5:
		var layer=Sprite2D.new()
		layer.centered=false
		layer.texture=texture
		layer.position=DRAW_RECT.position
		layer.scale=DRAW_RECT.size/texture.get_size()
		layer.z_as_relative=false
		layer.material=ShaderMaterial.new()
		layer.material.shader=preload("res://shaders/mire_sequence.gdshader")
		if part==0:
			var mud_shader=Shader.new()
			mud_shader.code=layer.material.shader.code.replace("shader_type canvas_item;","shader_type canvas_item;\nrender_mode blend_mul;").replace("COLOR=vec4(rgb,alpha*reveal);","COLOR=vec4(mix(vec3(1.0),rgb,alpha*reveal),1.0);")
			layer.material.shader=mud_shader
		layer.material.set_shader_parameter("part",part)
		add_child(layer)
		layers.append(layer)

func refresh_layers():
	for part in layers.size():
		var layer=layers[part]
		layer.visible=not finished
		# Each root has its own ground depth; mud is beneath all fighters.
		var root_y=[0.0,-2.2,-5.8,8.6,-2.0][part]
		layer.z_index=-4 if part==0 else int((position.y+root_y)*2)+1
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
	var hand_time=maxf(0,exit_start-1)*HAND_STEP_SECONDS
	if exit_age<hand_time:phase=exit_start-exit_age/HAND_STEP_SECONDS
	else:phase=maxf(0,minf(exit_start,1)-(exit_age-hand_time)/FORM_SECONDS)
	finished=phase<=0
	refresh_layers()

