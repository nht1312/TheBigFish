class_name InputSetup
extends RefCounted
## Registers input actions at startup so project.godot stays readable.

const KEYS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"sprint": [KEY_SHIFT],
	"interact": [KEY_E],
	"rod_toggle": [KEY_1],
	"bait_cycle": [KEY_B],
	"drag_down": [KEY_Q],
	"drag_up": [KEY_E],
	"inventory": [KEY_TAB, KEY_I],
	"pause": [KEY_ESCAPE],
	"dialogue_next": [KEY_SPACE, KEY_E, KEY_ENTER],
	"quicksave": [KEY_F5],
	"quickload": [KEY_F9],
	"debug_console": [KEY_F1, KEY_QUOTELEFT],
	"debug_overlay": [KEY_F3],
}

const MOUSE := {
	"cast": [MOUSE_BUTTON_LEFT],
	"reel_in": [MOUSE_BUTTON_RIGHT],
	"drag_up": [MOUSE_BUTTON_WHEEL_UP],
	"drag_down": [MOUSE_BUTTON_WHEEL_DOWN],
	"dialogue_next": [MOUSE_BUTTON_LEFT],
}


static func setup() -> void:
	for action in KEYS.keys() + MOUSE.keys():
		_ensure(action)
	for action in KEYS:
		for key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	for action in MOUSE:
		for button in MOUSE[action]:
			var ev := InputEventMouseButton.new()
			ev.button_index = button
			InputMap.action_add_event(action, ev)


static func _ensure(action: String) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action)
