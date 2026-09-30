class_name StoryEventSystem
extends RefCounted
## Story and random events (docs/06, docs/18 §29–30).
##
## Event data: { id, trigger: { on, match? }, conditions?, once?, probability?, cooldown_minutes?,
##               effects?, dialogue?, autosave? }
## "on" is a bus event name; "match" requires equal fields in that event's data.

var ctx: GameContext
var history: Dictionary = {}  # id -> { count, last_minute }
var rng := RandomNumberGenerator.new()


func _init(context: GameContext) -> void:
	ctx = context
	ctx.bus.event_emitted.connect(_on_event)


## Fires an event directly (effects / debug). Conditions still apply.
func trigger(event_id: String, force: bool = false) -> bool:
	var def := ctx.data.get_def("events", event_id)
	if def.is_empty():
		push_error("StoryEventSystem: unknown event '%s'" % event_id)
		return false
	if not force and not _can_fire(def):
		return false
	_fire(def)
	return true


func times_fired(event_id: String) -> int:
	return int(history.get(event_id, {}).get("count", 0))


func to_dict() -> Dictionary:
	return history.duplicate(true)


func load_dict(d: Dictionary) -> void:
	history = d.duplicate(true)


func _on_event(event_name: StringName, data: Dictionary) -> void:
	if event_name in [GameEvents.STORY_EVENT_TRIGGERED, GameEvents.CUE, GameEvents.MESSAGE]:
		return
	for def in ctx.data.all("events"):
		var trig: Dictionary = def.get("trigger", {})
		if str(trig.get("on", "")) != String(event_name):
			continue
		if not _matches(trig.get("match", {}), data):
			continue
		if _can_fire(def) and rng.randf() <= float(def.get("probability", 1.0)):
			_fire(def)


func _matches(match: Dictionary, data: Dictionary) -> bool:
	for key in match:
		if str(data.get(key, "")) != str(match[key]):
			return false
	return true


func _can_fire(def: Dictionary) -> bool:
	var id := str(def["id"])
	var record: Dictionary = history.get(id, {})
	if def.get("once", true) and int(record.get("count", 0)) > 0:
		return false
	var cooldown := float(def.get("cooldown_minutes", 0))
	if cooldown > 0 and record.has("last_minute"):
		if ctx.clock.total_minutes() - float(record["last_minute"]) < cooldown:
			return false
	return ctx.conditions.check(def.get("conditions", []))


func _fire(def: Dictionary) -> void:
	var id := str(def["id"])
	var record: Dictionary = history.get(id, {"count": 0})
	record["count"] = int(record["count"]) + 1
	record["last_minute"] = ctx.clock.total_minutes()
	history[id] = record
	ctx.state.set_flag("event_done:" + id)
	ctx.bus.emit_event(GameEvents.STORY_EVENT_TRIGGERED, {"event": id})
	ctx.effects.run(def.get("effects", []))
	if def.has("dialogue"):
		ctx.dialogue.start(str(def["dialogue"]))
	if def.get("autosave", false):
		ctx.bus.emit_event(GameEvents.AUTOSAVE_REQUESTED, {"reason": id})
