class_name QuestSystem
extends RefCounted
## Quest state and objective tracking (docs/05, docs/18 §17–18).
##
## Objectives are conditions. Active quests are re-checked after every game event and an
## objective latches once its condition has been true. With "sequential": true only the
## first unfinished objective is checked (needed for momentary conditions like locations).

const LOCKED := "LOCKED"
const AVAILABLE := "AVAILABLE"
const ACTIVE := "ACTIVE"
const COMPLETED := "COMPLETED"
const FAILED := "FAILED"

var ctx: GameContext
var quests: Dictionary = {}  # id -> { state, done: [objective ids] }


func _init(context: GameContext) -> void:
	ctx = context
	ctx.bus.event_emitted.connect(_on_event)


func get_state(quest_id: String) -> String:
	return str(quests.get(quest_id, {}).get("state", LOCKED))


func is_active(quest_id: String) -> bool:
	return get_state(quest_id) == ACTIVE


func start(quest_id: String) -> bool:
	var def := ctx.data.get_def("quests", quest_id)
	if def.is_empty():
		push_error("QuestSystem: unknown quest '%s'" % quest_id)
		return false
	if get_state(quest_id) not in [LOCKED, AVAILABLE]:
		return false
	quests[quest_id] = {"state": ACTIVE, "done": []}
	ctx.bus.emit_event(GameEvents.QUEST_STARTED, {"quest": quest_id})
	evaluate(quest_id)
	return true


func complete(quest_id: String) -> bool:
	if get_state(quest_id) in [COMPLETED, FAILED]:
		return false
	var def := ctx.data.get_def("quests", quest_id)
	if def.is_empty():
		return false
	if not quests.has(quest_id):
		quests[quest_id] = {"state": ACTIVE, "done": []}
	quests[quest_id]["state"] = COMPLETED
	ctx.effects.run(def.get("rewards", []))
	ctx.bus.emit_event(GameEvents.QUEST_COMPLETED, {"quest": quest_id, "autosave": def.get("type", "") == "MAIN"})
	for next_id in def.get("next", []):
		start(str(next_id))
	return true


func reset(quest_id: String) -> void:
	quests.erase(quest_id)


func evaluate(quest_id: String) -> void:
	if not is_active(quest_id):
		return
	var def := ctx.data.get_def("quests", quest_id)
	var done: Array = quests[quest_id]["done"]
	for objective in def.get("objectives", []):
		var obj_id := str(objective["id"])
		if done.has(obj_id):
			continue
		if ctx.conditions.check(objective.get("condition")):
			done.append(obj_id)
			ctx.bus.emit_event(GameEvents.OBJECTIVE_COMPLETED, {"quest": quest_id, "objective": obj_id})
		elif def.get("sequential", false):
			return
	if done.size() >= def.get("objectives", []).size():
		complete(quest_id)


func evaluate_all() -> void:
	for quest_id in quests.keys():
		evaluate(quest_id)


func active_quests() -> Array:
	return quests.keys().filter(func(id): return is_active(id))


## Text of the first unfinished, non-hidden objective (what the HUD shows).
func current_objective_text(quest_id: String) -> String:
	if not is_active(quest_id):
		return ""
	var done: Array = quests[quest_id]["done"]
	for objective in ctx.data.get_def("quests", quest_id).get("objectives", []):
		if not done.has(str(objective["id"])):
			return str(objective.get("text", ""))
	return ""


func to_dict() -> Dictionary:
	return quests.duplicate(true)


func load_dict(d: Dictionary) -> void:
	quests = {}
	for id in d:
		quests[id] = {"state": str(d[id].get("state", LOCKED)), "done": d[id].get("done", []).duplicate()}


func _on_event(event_name: StringName, _data: Dictionary) -> void:
	# Our own emissions are re-checked by the calls that produced them.
	if event_name in [GameEvents.OBJECTIVE_COMPLETED, GameEvents.QUEST_STARTED, GameEvents.CUE, GameEvents.MESSAGE]:
		return
	evaluate_all()
