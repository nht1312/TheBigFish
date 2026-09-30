class_name DialogueSystem
extends RefCounted
## Branching, conditional dialogue (docs/15, docs/18 §19).
##
## Dialogue data: { id, start, nodes: { node_id: node } }
## Node: { speaker, text, next?, choices?, effects?, branch? }
##   branch:  [{ conditions, next }] — redirects on entry to the first matching target
##   choices: [{ text, next?, conditions?, effects? }] — only choices whose conditions pass are shown
## Ending a dialogue runs its "end_effects" and sets flag "dialogue_done:<id>".

var ctx: GameContext
var current_id: String = ""
var current_node_id: String = ""
var _queue: Array[String] = []


func _init(context: GameContext) -> void:
	ctx = context


func is_active() -> bool:
	return current_id != ""


## Starts a dialogue, or queues it if one is already running.
func start(dialogue_id: String) -> bool:
	var def := ctx.data.get_def("dialogues", dialogue_id)
	if def.is_empty():
		push_error("DialogueSystem: unknown dialogue '%s'" % dialogue_id)
		return false
	if is_active():
		if dialogue_id != current_id and not _queue.has(dialogue_id):
			_queue.append(dialogue_id)
		return true
	current_id = dialogue_id
	ctx.bus.emit_event(GameEvents.DIALOGUE_STARTED, {"dialogue": dialogue_id})
	_enter(str(def.get("start", "start")))
	return true


func current_node() -> Dictionary:
	if not is_active():
		return {}
	return ctx.data.get_def("dialogues", current_id).get("nodes", {}).get(current_node_id, {})


func visible_choices() -> Array:
	return current_node().get("choices", []).filter(func(c): return ctx.conditions.check(c.get("conditions", [])))


func speaker_name(speaker_id: String) -> String:
	match speaker_id:
		"PLAYER":
			return "Bạn"
		"NARRATION", "":
			return ""
	return ctx.data.display_name("npcs", speaker_id)


## Continue a node without choices.
func advance() -> void:
	if not is_active() or not visible_choices().is_empty():
		return
	_go(str(current_node().get("next", "")))


func choose(index: int) -> void:
	var choices := visible_choices()
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	ctx.effects.run(choice.get("effects", []))
	if not is_active():  # an effect may have ended the dialogue
		return
	_go(str(choice.get("next", "")))


func end() -> void:
	if not is_active():
		return
	var ended_id := current_id
	var def := ctx.data.get_def("dialogues", ended_id)
	current_id = ""
	current_node_id = ""
	ctx.state.set_flag("dialogue_done:" + ended_id)
	ctx.effects.run(def.get("end_effects", []))
	ctx.bus.emit_event(GameEvents.DIALOGUE_ENDED, {"dialogue": ended_id})
	if not _queue.is_empty() and not is_active():
		start(_queue.pop_front())


func _go(node_id: String) -> void:
	if node_id == "" or node_id == "end":
		end()
	else:
		_enter(node_id)


func _enter(node_id: String) -> void:
	var nodes: Dictionary = ctx.data.get_def("dialogues", current_id).get("nodes", {})
	# Follow conditional branches (bounded, to survive bad data).
	for _i in 16:
		var node: Dictionary = nodes.get(node_id, {})
		if node.is_empty():
			push_error("DialogueSystem: missing node '%s' in %s" % [node_id, current_id])
			end()
			return
		var redirected := false
		for branch in node.get("branch", []):
			if ctx.conditions.check(branch.get("conditions", [])):
				node_id = str(branch["next"])
				redirected = true
				break
		if not redirected:
			break
	current_node_id = node_id
	var entered: Dictionary = nodes[node_id]
	ctx.effects.run(entered.get("effects", []))
	if is_active() and current_node_id == node_id:
		ctx.bus.emit_event(GameEvents.DIALOGUE_NODE, {"dialogue": current_id, "node": node_id})
