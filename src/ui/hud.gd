class_name Hud
extends CanvasLayer
## Everyday HUD: crosshair, interaction prompt, current objective, messages, hints,
## screen fades. Specialised panels live in their own scripts and are children of this layer.

var root: Control
var prompt_label: Label
var objective_label: Label
var hint_label: Label
var messages: VBoxContainer
var fade_rect: ColorRect
var fade_text: Label
var fishing_hud: FishingHud
var dialogue_panel: DialoguePanel
var inventory_panel: InventoryPanel
var shop_panel: ShopPanel
var pause_menu: PauseMenu
var debug_overlay: DebugOverlay
var debug_console: DebugConsole

var _fading: bool = false


func _init() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiStyle.theme()
	add_child(root)

	var cross := UiStyle.label("·", 30, Color(1, 1, 1, 0.7))
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position -= Vector2(4, 20)
	root.add_child(cross)

	prompt_label = UiStyle.label("", 19, UiStyle.TEXT)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.custom_minimum_size = Vector2(600, 0)
	prompt_label.position = Vector2(-300, 26)
	root.add_child(prompt_label)

	objective_label = UiStyle.label("", 18, UiStyle.DIM)
	objective_label.position = Vector2(28, 22)
	root.add_child(objective_label)

	hint_label = UiStyle.label("", 18, UiStyle.DIM)
	hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.custom_minimum_size = Vector2(900, 0)
	hint_label.position = Vector2(-450, -46)
	root.add_child(hint_label)

	messages = VBoxContainer.new()
	messages.set_anchors_preset(Control.PRESET_CENTER)
	messages.custom_minimum_size = Vector2(900, 0)
	messages.position = Vector2(-450, 120)
	messages.alignment = BoxContainer.ALIGNMENT_BEGIN
	messages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(messages)

	fishing_hud = FishingHud.new()
	root.add_child(fishing_hud)
	dialogue_panel = DialoguePanel.new()
	root.add_child(dialogue_panel)
	inventory_panel = InventoryPanel.new()
	root.add_child(inventory_panel)
	shop_panel = ShopPanel.new()
	root.add_child(shop_panel)

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect)
	fade_text = UiStyle.label("", 26, UiStyle.THOUGHT)
	fade_text.set_anchors_preset(Control.PRESET_CENTER)
	fade_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fade_text.custom_minimum_size = Vector2(1000, 0)
	fade_text.position = Vector2(-500, -20)
	fade_text.modulate.a = 0.0
	root.add_child(fade_text)

	pause_menu = PauseMenu.new()
	root.add_child(pause_menu)
	debug_overlay = DebugOverlay.new()
	root.add_child(debug_overlay)
	debug_console = DebugConsole.new()
	root.add_child(debug_console)


func set_prompt(text: String) -> void:
	prompt_label.text = "[E]  " + text if text != "" else ""


func set_objective(text: String) -> void:
	objective_label.text = text


func set_hint(text: String) -> void:
	hint_label.text = text


## style: thought | narration | info | hint
func show_message(text: String, style: String = "info", delay: float = 0.0) -> void:
	if delay > 0.0:
		get_tree().create_timer(delay, false).timeout.connect(show_message.bind(text, style, 0.0))
		return
	var color := UiStyle.TEXT
	match style:
		"thought":
			color = UiStyle.THOUGHT
			text = "“%s”" % text
		"narration":
			color = UiStyle.NARRATION
		"hint":
			color = UiStyle.DIM
	var l := UiStyle.label(text, 21, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	messages.add_child(l)
	while messages.get_child_count() > 3:
		messages.get_child(0).free()
	var hold := 2.5 + text.length() * 0.04
	var tween := l.create_tween()
	tween.tween_interval(hold)
	tween.tween_property(l, "modulate:a", 0.0, 0.8)
	tween.tween_callback(l.queue_free)


## Fade to black, show lines one by one, fade back. Returns when finished.
func fade_sequence(lines: Array, seconds_per_line: float = 2.2, stay_black: bool = false) -> void:
	_fading = true
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.8)
	await tween.finished
	for line in lines:
		fade_text.text = str(line)
		var t := create_tween()
		t.tween_property(fade_text, "modulate:a", 1.0, 0.4)
		t.tween_interval(seconds_per_line)
		t.tween_property(fade_text, "modulate:a", 0.0, 0.4)
		await t.finished
	if not stay_black:
		var back := create_tween()
		back.tween_property(fade_rect, "color:a", 0.0, 0.8)
		await back.finished
	_fading = false


## Back from a fade_sequence(..., stay_black = true).
func fade_from_black(seconds: float = 0.8) -> void:
	var back := create_tween()
	back.tween_property(fade_rect, "color:a", 0.0, seconds)
	await back.finished
	_fading = false


## Big centred text on the current (usually black) screen, then gone.
func title_card(text: String, seconds: float = 3.5) -> void:
	fade_text.text = text
	var t := create_tween()
	t.tween_property(fade_text, "modulate:a", 1.0, 0.8)
	t.tween_interval(seconds)
	t.tween_property(fade_text, "modulate:a", 0.0, 0.8)
	await t.finished


func is_fading() -> bool:
	return _fading
