class_name CairnBindings
extends RefCounted
# Logical keys retain the existing combat API: K is internally magic, Space jump.
const KEY_MAP={KEY_W:KEY_W,KEY_UP:KEY_W,KEY_S:KEY_S,KEY_DOWN:KEY_S,KEY_A:KEY_A,KEY_LEFT:KEY_A,KEY_D:KEY_D,KEY_RIGHT:KEY_D,KEY_J:KEY_J,KEY_Z:KEY_J,KEY_K:KEY_SPACE,KEY_X:KEY_SPACE,KEY_SPACE:KEY_SPACE,KEY_L:KEY_K,KEY_C:KEY_K,KEY_SHIFT:KEY_SHIFT}
const PAD_MAP={JOY_BUTTON_A:KEY_SPACE,JOY_BUTTON_X:KEY_J,JOY_BUTTON_Y:KEY_K,JOY_BUTTON_RIGHT_SHOULDER:KEY_SHIFT,JOY_BUTTON_DPAD_UP:KEY_W,JOY_BUTTON_DPAD_DOWN:KEY_S,JOY_BUTTON_DPAD_LEFT:KEY_A,JOY_BUTTON_DPAD_RIGHT:KEY_D}
var sources={}
var held={}
var menu_axes={}
func clear():
 sources.clear()
 held.clear()
 menu_axes.clear()
func set_source(id: String,code: int,down: bool):
 if down:sources[id]=code
 else:sources.erase(id)
func gameplay(event: InputEvent) -> Array:
 var old=held.duplicate()
 if event is InputEventKey:
  if event.echo:return []
  var key=event.physical_keycode if event.physical_keycode else event.keycode
  if KEY_MAP.has(key):set_source("key:%d"%key,KEY_MAP[key],event.pressed)
 elif event is InputEventMouseButton:
  if event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:set_source("mouse:%d"%event.button_index,KEY_J if event.button_index==MOUSE_BUTTON_LEFT else KEY_K,event.pressed)
 elif event is InputEventJoypadButton:
  if PAD_MAP.has(event.button_index):set_source("pad:%d:%d"%[event.device,event.button_index],PAD_MAP[event.button_index],event.pressed)
 elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
  var horizontal=event.axis==JOY_AXIS_LEFT_X
  set_source("axis:%d:%d:-"%[event.device,event.axis],KEY_A if horizontal else KEY_W,event.axis_value<-.35)
  set_source("axis:%d:%d:+"%[event.device,event.axis],KEY_D if horizontal else KEY_S,event.axis_value>.35)
 held.clear()
 for code in sources.values():held[code]=true
 var changes=[]
 for code in old:
  if not held.has(code):changes.append([code,false])
 for code in held:
  if not old.has(code):changes.append([code,true])
 return changes
func menu_event(event: InputEvent) -> InputEvent:
 var code=0
 var down=false
 if event is InputEventJoypadButton:
  code={JOY_BUTTON_A:KEY_ENTER,JOY_BUTTON_B:KEY_ESCAPE,JOY_BUTTON_START:KEY_ESCAPE,JOY_BUTTON_DPAD_UP:KEY_UP,JOY_BUTTON_DPAD_DOWN:KEY_DOWN,JOY_BUTTON_DPAD_LEFT:KEY_LEFT,JOY_BUTTON_DPAD_RIGHT:KEY_RIGHT}.get(event.button_index,0)
  down=event.pressed
 elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
  var id="%d:%d"%[event.device,event.axis]
  var direction=-1 if event.axis_value<-.5 else 1 if event.axis_value>.5 else 0
  if menu_axes.get(id,0)==direction:return null
  menu_axes[id]=direction
  if direction==0:return null
  code=(KEY_LEFT if direction<0 else KEY_RIGHT) if event.axis==JOY_AXIS_LEFT_X else (KEY_UP if direction<0 else KEY_DOWN)
  down=true
 if not code:return null
 var key=InputEventKey.new()
 key.keycode=code
 key.pressed=down
 return key
