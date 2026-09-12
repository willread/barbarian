class_name ContourFire
extends Node2D
var viewport: SubViewport
var flow: ShaderMaterial
var thermal_view: SubViewport
var thermal: ShaderMaterial
var emitting=true
var strength=0.6
var source_origin=Vector2.ZERO
const PADDING=32.0
var clock=randf()*100
var started=false
# Mask may be a static texture or a live viewport (e.g. a dissolving corpse).
# Coordinates and resolution are local pixels; parenting supplies world transform/depth.
func setup(mask: Texture2D,source_size: Vector2,origin=Vector2.ZERO,with_heat=true):
	source_origin=origin
	var dimensions=source_size+Vector2.ONE*PADDING*2
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
	flow.set_shader_parameter("fuel_size",source_size)
	flow.set_shader_parameter("fuel_mask",mask)
	rect.material=flow
	viewport.add_child(rect)
	var surface=Sprite2D.new()
	surface.centered=false
	surface.texture=viewport.get_texture()
	surface.position=origin-Vector2.ONE*PADDING
	surface.material=ShaderMaterial.new()
	surface.material.shader=load("res://shaders/contour_fire_surface.gdshader")
	add_child(surface)
	if not with_heat:return
	# A separate persistent temperature field keeps hot stone cooling after flames move.
	thermal_view=SubViewport.new()
	thermal_view.size=viewport.size
	thermal_view.disable_3d=true
	thermal_view.render_target_clear_mode=SubViewport.CLEAR_MODE_ONCE
	thermal_view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(thermal_view)
	var thermal_buffer=BackBufferCopy.new()
	thermal_buffer.copy_mode=BackBufferCopy.COPY_MODE_VIEWPORT
	thermal_view.add_child(thermal_buffer)
	var thermal_rect=ColorRect.new()
	thermal_rect.size=dimensions
	thermal=ShaderMaterial.new()
	thermal.shader=load("res://shaders/stone_temperature.gdshader")
	thermal.set_shader_parameter("flames",viewport.get_texture())
	thermal.set_shader_parameter("domain",dimensions)
	thermal_rect.material=thermal
	thermal_view.add_child(thermal_rect)
# Apply optional heat response to a face whose rectangle is in this node's local space.
func heat_face(face: Sprite2D,rect: Rect2):
	if not thermal_view:return
	var material=ShaderMaterial.new()
	material.shader=load("res://shaders/hot_stone.gdshader")
	material.set_shader_parameter("temperature",thermal_view.get_texture())
	material.set_shader_parameter("face_size",rect.size)
	material.set_shader_parameter("domain",Vector2(viewport.size))
	material.set_shader_parameter("offset",rect.position-source_origin+Vector2.ONE*PADDING)
	face.material=material
func restart():
	started=false
	clock=randf()*100
	emitting=true
func _process(dt: float):
	if not flow:return
	clock+=dt
	flow.set_shader_parameter("clock",clock)
	flow.set_shader_parameter("delta",min(dt,.033333))
	flow.set_shader_parameter("reset",not started)
	flow.set_shader_parameter("emitting",emitting)
	flow.set_shader_parameter("strength",strength)
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	if thermal:
		thermal.set_shader_parameter("emitting",emitting)
		thermal.set_shader_parameter("delta",min(dt,.033333))
		thermal.set_shader_parameter("reset",not started)
		thermal_view.render_target_update_mode=SubViewport.UPDATE_ONCE
	started=true
