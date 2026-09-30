class_name DebugConsole
extends PanelContainer
## [F1] development console running DebugCommands. Debug builds only.

var commands: DebugCommands
var input: LineEdit
var output: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size = Vector2(0, 240)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var box := VBoxContainer.new()
	add_child(box)
	output = UiStyle.label("Debug console — type help", 15, Color(0.7, 1.0, 0.7))
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	output.clip_text = true
	box.add_child(output)
	input = LineEdit.new()
	input.placeholder_text = "command"
	input.text_submitted.connect(_on_submit)
	box.add_child(input)


func toggle() -> bool:
	if not OS.is_debug_build():
		return false
	visible = not visible
	if visible:
		input.clear()
		input.call_deferred("grab_focus")
	return visible


func _on_submit(line: String) -> void:
	input.clear()
	if commands == null or line.strip_edges() == "":
		return
	var result := commands.execute(line)
	var lines := (output.text + "\n> " + line + "\n" + result).split("\n")
	output.text = "\n".join(lines.slice(maxi(0, lines.size() - 12)))
