extends RefCounted
# Accumulate net displacement so small alternating sensor jitter never wins focus.
const REVEAL_DISTANCE=6.0
var mouse_active=true
var motion=Vector2.ZERO
func accept(event: InputEvent) -> bool:
	var keyboard=event is InputEventKey and event.pressed and not event.echo
	var button=event is InputEventJoypadButton and event.pressed
	var stick=false
	if event is InputEventJoypadMotion:
		stick=absf(event.axis_value)>.35 if event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y,JOY_AXIS_RIGHT_X,JOY_AXIS_RIGHT_Y] else event.axis_value>.35
	if keyboard or button or stick:
		mouse_active=false
		motion=Vector2.ZERO
	elif event is InputEventMouseMotion and not mouse_active:
		motion+=event.relative
		if motion.length()<REVEAL_DISTANCE:return false
		mouse_active=true
		motion=Vector2.ZERO
	return true
