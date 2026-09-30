class_name PauseMenu
extends PanelContainer
## Esc menu. The world supplies the actions through the signals.

signal resume_requested
signal save_requested
signal load_requested
signal menu_requested

var status: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(360, 0)
	position = Vector2(-180, -170)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.add_child(UiStyle.label("Tạm dừng", 26, UiStyle.THOUGHT))
	for entry in [["Tiếp tục", resume_requested], ["Lưu game", save_requested], ["Tải bản lưu", load_requested], ["Về màn hình chính", menu_requested]]:
		var b := Button.new()
		b.text = entry[0]
		var sig: Signal = entry[1]
		b.pressed.connect(func(): sig.emit())
		box.add_child(b)
	status = UiStyle.label("", 16, UiStyle.DIM)
	box.add_child(status)
