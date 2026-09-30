class_name EventBus
extends RefCounted
## Decoupled communication between systems (docs/18 §9–10).
##
## Events emitted while another event is being dispatched are queued, so every
## listener sees events in the order they happened and handlers never recurse.

signal event_emitted(event_name: StringName, data: Dictionary)

const HISTORY_SIZE := 30

var history: Array = []  # [[event_name, data], ...] newest last, for the debug overlay

var _queue: Array = []
var _dispatching := false


func emit_event(event_name: StringName, data: Dictionary = {}) -> void:
	_queue.append([event_name, data])
	if _dispatching:
		return
	_dispatching = true
	while not _queue.is_empty():
		var entry: Array = _queue.pop_front()
		history.append(entry)
		if history.size() > HISTORY_SIZE:
			history.pop_front()
		event_emitted.emit(entry[0], entry[1])
	_dispatching = false
