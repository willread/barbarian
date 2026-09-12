extends CanvasLayer
var audio: Node
var panel: Control
var content: VBoxContainer
var preview: AudioStreamPlayer
var previous_pause=false
var buttons: Dictionary={}
var opened=false
var preview_base=-8.0
var preview_id=""
func _ready():
	layer=100
	process_mode=Node.PROCESS_MODE_ALWAYS
	preview=AudioStreamPlayer.new()
	add_child(preview)
	preview.volume_db=-8
	panel=PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var margin=MarginContainer.new()
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
	panel.add_child(margin)
	var column=VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	var title=Label.new()
	title.text="CAIRN · SOUND LAB"
	title.add_theme_font_size_override("font_size",28)
	column.add_child(title)
	var help=Label.new()
	help.text="F8 / Escape: close · Choosing an option previews it and applies it to the game. Choices save automatically. Hover an option to inspect its generation prompt."
	help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(help)
	var tools=HBoxContainer.new()
	column.add_child(tools)
	var close=Button.new()
	close.text="Return to game [F8]"
	close.pressed.connect(toggle)
	tools.add_child(close)
	var stop=Button.new()
	stop.text="Stop preview"
	stop.pressed.connect(func():preview.stop())
	tools.add_child(stop)
	var volume=HSlider.new()
	volume.custom_minimum_size.x=180
	volume.min_value=-30
	volume.max_value=0
	volume.value=-8
	volume.tooltip_text="Preview volume (does not alter game mix)"
	volume.value_changed.connect(func(value):
		preview_base=value
		preview.volume_db=preview_base+audio.volumes.get(preview_id,0.0))
	tools.add_child(volume)
	var search=LineEdit.new()
	search.placeholder_text="Filter sounds…"
	column.add_child(search)
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	content=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",20)
	scroll.add_child(content)
	if FileAccess.file_exists("res://audio_options/manifest.json"):
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://audio_options/manifest.json"))
		var groups={}
		for job in data.jobs:
			if not groups.has(job.group):groups[job.group]=[]
			groups[job.group].append(job)
		for group in groups:
			var id={"selection":"menu_select","activation":"menu_activate","drop":"menu_land"}.get(group,group)
			if not audio.originals.has(id):continue
			var box=VBoxContainer.new()
			box.set_meta("search",(groups[group][0].label+" "+group).to_lower())
			content.add_child(box)
			var heading=Label.new()
			heading.text=groups[group][0].label
			heading.add_theme_font_size_override("font_size",22)
			box.add_child(heading)
			var mix=HBoxContainer.new()
			box.add_child(mix)
			var level=Label.new()
			level.custom_minimum_size.x=170
			level.text="Game volume: %+.0f dB"%audio.volumes.get(id,0.0)
			mix.add_child(level)
			var gain=HSlider.new()
			gain.min_value=-30
			gain.max_value=6
			gain.step=1
			gain.value=audio.volumes.get(id,0.0)
			gain.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			mix.add_child(gain)
			gain.value_changed.connect(func(value):
				audio.set_volume(id,value)
				level.text="Game volume: %+.0f dB"%value
				if preview_id==id:preview.volume_db=preview_base+value)
			var reset=Button.new()
			reset.text="Reset level"
			reset.pressed.connect(func():gain.value=0)
			mix.add_child(reset)
			buttons[id]=[]
			var original=Button.new()
			original.text="Original game sound"
			original.toggle_mode=true
			original.pressed.connect(func():choose(id,"original"))
			box.add_child(original)
			buttons[id].append([original,"original"])
			var silent=Button.new()
			silent.text="No sound"
			silent.toggle_mode=true
			silent.pressed.connect(func():choose(id,"none"))
			box.add_child(silent)
			buttons[id].append([silent,"none"])
			for job in groups[group]:
				var button=Button.new()
				button.text=str(buttons[id].size()-1)+" · "+job.name+" — "+job.description
				button.tooltip_text=job.prompt
				button.alignment=HORIZONTAL_ALIGNMENT_LEFT
				button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				button.toggle_mode=true
				button.pressed.connect(func():choose(id,job.id))
				box.add_child(button)
				buttons[id].append([button,job.id])
	search.text_changed.connect(func(value):
		for box in content.get_children():box.visible=value.to_lower() in box.get_meta("search"))
	refresh()
	panel.hide()
func refresh():
	for id in buttons:
		for entry in buttons[id]:entry[0].set_pressed_no_signal(audio.choices.get(id,"original")==entry[1])
func choose(id: String,variant: String):
	audio.set_variant(id,variant)
	refresh()
	preview.stop()
	preview_id=id
	preview.volume_db=preview_base+audio.volumes.get(id,0.0)
	preview.stream=audio.clips[id]
	if preview.stream:preview.play()
func toggle():
	opened=not opened
	panel.visible=opened
	if opened:
		previous_pause=get_tree().paused
		get_tree().paused=true
		panel.get_child(0).get_child(0).get_child(2).get_child(0).grab_focus()
	else:
		preview.stop()
		get_tree().paused=previous_pause
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode==KEY_F8 or (opened and event.keycode==KEY_ESCAPE)):
		toggle()
		get_viewport().set_input_as_handled()
func _exit_tree():
	preview.stop()
	preview.stream=null
