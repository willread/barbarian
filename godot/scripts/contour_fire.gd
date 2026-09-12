extends Node2D
var viewport: SubViewport
var flow: ShaderMaterial
var emitting=true
var strength=1.0
var clock=randf()*100
var started=false
func setup(mask: Texture2D,meta: Dictionary):
	var dimensions=Vector2(meta.fw+64,meta.fh+64)
	viewport=SubViewport.new()
	viewport.size=Vector2i(dimensions.ceil())
	viewport.disable_3d=true
	viewport.transparent_bg=true
	viewport.render_target_clear_mode=SubViewport.CLEAR_MODE_ONCE
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var buffer=BackBufferCopy.new()
	buffer.copy_mode=BackBufferCopy.COPY_MODE_VIEWPORT
	viewport.add_child(buffer)
	var rect=ColorRect.new()
	rect.size=dimensions
	flow=ShaderMaterial.new()
	flow.shader=load("res://shaders/contour_fire_flow.gdshader")
	flow.set_shader_parameter("domain",dimensions)
	flow.set_shader_parameter("fuel_size",Vector2(meta.fw,meta.fh))
	flow.set_shader_parameter("fuel_mask",mask)
	rect.material=flow
	viewport.add_child(rect)
	var surface=Sprite2D.new()
	surface.centered=false
	surface.texture=viewport.get_texture()
	surface.position=Vector2(-meta.fw*.5-32,-meta.pad-32)
	surface.material=ShaderMaterial.new()
	surface.material.shader=load("res://shaders/contour_fire_surface.gdshader")
	add_child(surface)
func _process(dt: float):
	if not flow:return
	clock+=dt
	flow.set_shader_parameter("clock",clock)
	flow.set_shader_parameter("delta",min(dt,.033333))
	flow.set_shader_parameter("reset",not started)
	flow.set_shader_parameter("emitting",emitting)
	flow.set_shader_parameter("strength",strength)
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	started=true
