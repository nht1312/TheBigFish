class_name GameState
extends RefCounted
## Global story/world/player-progress state (docs/18 §8, §31–32).
## Other systems change it only through these methods so every change emits an event.

var bus: EventBus

var flags: Dictionary = {}  # key -> bool   (story flags, "event_done:<id>", "crafted:<item>")
var stats: Dictionary = {}  # key -> float  (FishingPassion, FishingSkill, Knowledge.Fishing, FishCaught)
var vars: Dictionary = {}  # key -> String (e.g. "fishing.next_fish")
var records: Dictionary = {}  # fish records (docs/07 §44)
var money: int = 0
var unlocked_maps: Array = []
var current_map: String = ""
var current_location: String = ""


func _init(p_bus: EventBus) -> void:
	bus = p_bus


func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))


func set_flag(key: String, value: bool = true) -> void:
	if has_flag(key) == value:
		return
	flags[key] = value
	bus.emit_event(GameEvents.FLAG_CHANGED, {"key": key, "value": value})


func get_stat(key: String) -> float:
	return float(stats.get(key, 0.0))


func set_stat(key: String, value: float) -> void:
	stats[key] = value
	bus.emit_event(GameEvents.STAT_CHANGED, {"key": key, "value": value})


func add_stat(key: String, delta: float) -> void:
	set_stat(key, get_stat(key) + delta)


func get_var(key: String) -> String:
	return str(vars.get(key, ""))


func set_var(key: String, value: String) -> void:
	if value == "":
		vars.erase(key)
	else:
		vars[key] = value


## Returns false (and changes nothing) if the result would be negative.
func add_money(amount: int) -> bool:
	if money + amount < 0:
		return false
	money += amount
	bus.emit_event(GameEvents.MONEY_CHANGED, {"money": money, "delta": amount})
	return true


func is_map_unlocked(map_id: String) -> bool:
	return unlocked_maps.has(map_id)


func unlock_map(map_id: String) -> void:
	if is_map_unlocked(map_id):
		return
	unlocked_maps.append(map_id)
	bus.emit_event(GameEvents.MAP_UNLOCKED, {"map": map_id})


func enter_map(map_id: String) -> void:
	if map_id == current_map:
		return
	current_map = map_id
	bus.emit_event(GameEvents.MAP_ENTERED, {"map": map_id})


func enter_location(location_id: String) -> void:
	if location_id == current_location:
		return
	current_location = location_id
	bus.emit_event(GameEvents.LOCATION_ENTERED, {"location": location_id, "map": current_map})


func to_dict() -> Dictionary:
	return {
		"flags": flags.duplicate(),
		"stats": stats.duplicate(),
		"vars": vars.duplicate(),
		"records": records.duplicate(true),
		"money": money,
		"unlocked_maps": unlocked_maps.duplicate(),
		"current_map": current_map,
		"current_location": current_location,
	}


func load_dict(d: Dictionary) -> void:
	flags = d.get("flags", {}).duplicate()
	stats = d.get("stats", {}).duplicate()
	vars = d.get("vars", {}).duplicate()
	records = d.get("records", {}).duplicate(true)
	money = int(d.get("money", 0))
	unlocked_maps = d.get("unlocked_maps", []).duplicate()
	current_map = str(d.get("current_map", ""))
	current_location = str(d.get("current_location", ""))
