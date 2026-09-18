extends Node2D
var art=CairnArt.new()
var environment=preload("res://scripts/environment.gd").new()
var clock=8.0
var running=true
var actors: Array=[]
var storm=false
func _ready():
 storm="--citadel-storm-preview" in OS.get_cmdline_user_args() or (OS.has_feature("web") and JavaScriptBridge.eval("new URLSearchParams(location.search).has('citadel-storm-preview')"))
 add_child(environment);environment.setup(art,"citadel-4" if storm else "ashen-4")
 var m=CairnMechanics.new()
 for hero in [true,false]:
  var actor=m.make(1 if hero else 2,550 if hero else 970,715,100,hero)
  actor.kind="legion" if hero else ("champion" if storm else "saint");actor.dir=1 if hero else -1
  var view=preload("res://scripts/fighter_view.gd").new();view.art=art;view.actor=actor
  add_child(view);view.update_view(-1);actors.append(view)
 var ui=CanvasLayer.new();ui.layer=100;add_child(ui)
 var row=HBoxContainer.new();row.position=Vector2(24,20);row.add_theme_constant_override("separation",12);ui.add_child(row)
 var pause=Button.new();pause.text="Pause motion";row.add_child(pause)
 pause.pressed.connect(func():running=not running;pause.text="Pause motion" if running else "Resume motion")
 var fighters=Button.new();fighters.text="Hide fighters";row.add_child(fighters)
 fighters.pressed.connect(func():
  for actor in actors:actor.visible=not actor.visible
  fighters.text="Hide fighters" if actors[0].visible else "Show fighters")
 var label=Label.new();label.text="E1 / AREA 4 - STORM PREVIEW" if storm else "FINAL ARENA - AMBIENT PREVIEW";row.add_child(label)
 if OS.has_feature("web"):JavaScriptBridge.eval("window.cairnMenuReady=true; window.dispatchEvent(new Event('cairn-menu-ready'));")
 if "--sanctuary-capture" in OS.get_cmdline_user_args():capture.call_deferred()
func _process(dt):
 if running:clock+=dt
 environment.advance(clock)
 for view in actors:
  view.actor.clock=clock;view.update_view(-1)
func capture():
 for i in 3:
  await get_tree().create_timer(1.75).timeout
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("E:/Cairn-build-tools/%s-preview-%d.png"%["citadel-storm" if storm else "sanctuary",i])
 print("SANCTUARY_PREVIEW_OK")
 get_tree().quit()
