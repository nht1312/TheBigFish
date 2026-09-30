class_name MainMenu
extends Control
## Title screen: new game / continue / quit.

signal new_game_requested
signal continue_requested(slot: String)
signal quit_requested


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(560, 0)
	box.position = Vector2(-280, -230)
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var title := UiStyle.label("CÁ LỚN", 72, UiStyle.THOUGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := UiStyle.label("THE LAST CAST", 22, UiStyle.DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	box.add_child(Control.new())
	var slot := _latest_slot()
	if slot != "":
		box.add_child(_button("Tiếp tục", func(): continue_requested.emit(slot)))
	box.add_child(_button("Chơi mới", func(): new_game_requested.emit()))
	box.add_child(_button("Thoát", func(): quit_requested.emit()))
	var help := UiStyle.label("WASD đi  ·  Shift chạy  ·  E tương tác  ·  Tab đồ đạc  ·  Esc tạm dừng\n1 cầm cần  ·  B đổi mồi  ·  Chuột trái quăng / giật / kéo  ·  Chuột phải thu dây\nA/D ghì cần  ·  Q/E hoặc con lăn chỉnh độ hãm  ·  F5 lưu  ·  F9 tải", 15, UiStyle.DIM)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(Control.new())
	box.add_child(help)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var first := find_children("*", "Button", true, false)
	if not first.is_empty():
		first[0].grab_focus()


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.pressed.connect(action)
	return b


## Most recently written save slot, or "" if none.
func _latest_slot() -> String:
	var best := ""
	var best_time := -1
	var saves := SaveSystem.new(null)
	for slot in ["autosave", "manual"]:
		if saves.has_save(slot):
			var t := FileAccess.get_modified_time(saves.slot_path(slot))
			if t > best_time:
				best_time = t
				best = slot
	return best
