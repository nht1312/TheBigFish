class_name DialoguePanel
extends PanelContainer
## Shows the DialogueSystem's current node. Text types out; [E]/[Space]/click continues,
## [1]–[4] or clicking picks a choice. Narration lines have no speaker (docs/15 §16).

signal wants_mouse(visible: bool)

const CHARS_PER_SECOND := 45.0

var speaker_label: Label
var text_label: Label
var choices_box: VBoxContainer
var continue_label: Label
var _visible_chars: float = 0.0
var _node_key: String = ""


func _init() -> void:
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	custom_minimum_size = Vector2(980, 0)
	position = Vector2(-490, -250)
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	speaker_label = UiStyle.label("", 20, UiStyle.THOUGHT)
	box.add_child(speaker_label)
	text_label = UiStyle.label("", 23)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(930, 0)
	box.add_child(text_label)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 6)
	box.add_child(choices_box)
	continue_label = UiStyle.label("▸", 18, UiStyle.DIM)
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(continue_label)


func _process(delta: float) -> void:
	var dlg := _dialogue()
	if dlg == null or not dlg.is_active():
		if visible:
			visible = false
			_node_key = ""
			wants_mouse.emit(false)
		return
	var key := dlg.current_id + "/" + dlg.current_node_id
	if key != _node_key:
		_show_node(dlg)
		_node_key = key
	if text_label.visible_characters >= 0:
		_visible_chars += delta * CHARS_PER_SECOND
		text_label.visible_characters = int(_visible_chars)
		if text_label.visible_characters >= text_label.text.length():
			text_label.visible_characters = -1
			_reveal_choices()


func _unhandled_input(event: InputEvent) -> void:
	var dlg := _dialogue()
	if not visible or dlg == null or not dlg.is_active():
		return
	if event.is_action_pressed("dialogue_next"):
		get_viewport().set_input_as_handled()
		if text_label.visible_characters >= 0:
			text_label.visible_characters = -1
			_reveal_choices()
		elif dlg.visible_choices().is_empty():
			dlg.advance()
	elif event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.physical_keycode - KEY_1
		if index >= 0 and index < 4 and text_label.visible_characters < 0 and index < dlg.visible_choices().size():
			get_viewport().set_input_as_handled()
			dlg.choose(index)


func _dialogue() -> DialogueSystem:
	return App.ctx().dialogue if App.ctx() else null


func _show_node(dlg: DialogueSystem) -> void:
	visible = true
	var node := dlg.current_node()
	var speaker := str(node.get("speaker", "NARRATION"))
	speaker_label.text = dlg.speaker_name(speaker)
	speaker_label.visible = speaker_label.text != ""
	text_label.text = str(node.get("text", ""))
	text_label.add_theme_color_override("font_color", UiStyle.NARRATION if speaker == "NARRATION" else UiStyle.TEXT)
	_visible_chars = 0.0
	text_label.visible_characters = 0
	for c in choices_box.get_children():
		c.queue_free()
	choices_box.visible = false
	continue_label.visible = false
	wants_mouse.emit(false)


func _reveal_choices() -> void:
	var dlg := _dialogue()
	var choices := dlg.visible_choices()
	continue_label.visible = choices.is_empty()
	if choices.is_empty() or choices_box.visible:
		return
	choices_box.visible = true
	for i in choices.size():
		var b := Button.new()
		b.text = "%d.  %s" % [i + 1, choices[i]["text"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func(): dlg.choose(i))
		choices_box.add_child(b)
	wants_mouse.emit(true)
