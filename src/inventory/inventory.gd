class_name Inventory
extends RefCounted
## Player inventory and equipped gear (docs/09).
##
## Each entry: { uid, id, qty, props }. Stackable items with no props merge into one entry;
## gear and fish are one entry each so they can carry durability / weight in props.
## Capacity (weight/slots) is not enforced yet — out of Vertical Slice scope.

const SLOTS: Array[String] = ["rod", "bait"]

var data: DataRegistry
var bus: EventBus
var entries: Array = []
var equipment: Dictionary = {}  # slot -> uid
var _next_uid: int = 1


func _init(p_data: DataRegistry, p_bus: EventBus) -> void:
	data = p_data
	bus = p_bus


## Adds qty of an item. Returns the uid of the (last) entry touched, or -1 if the id is unknown.
func add(item_id: String, qty: int = 1, props: Dictionary = {}) -> int:
	var def := data.get_item(item_id)
	if def.is_empty() or qty <= 0:
		push_error("Inventory: cannot add unknown item '%s'" % item_id)
		return -1
	var uid := -1
	if bool(def.get("stackable", false)) and props.is_empty():
		var entry := _find_stack(item_id)
		if entry.is_empty():
			entry = _new_entry(item_id, 0, {})
		entry["qty"] = int(entry["qty"]) + qty
		uid = int(entry["uid"])
	else:
		for i in qty:
			uid = int(_new_entry(item_id, 1, _initial_props(def, props))["uid"])
	bus.emit_event(GameEvents.ITEM_OBTAINED, {"item": item_id, "qty": qty, "uid": uid})
	return uid


## Removes qty of an item, all or nothing. Returns false if there is not enough.
func remove(item_id: String, qty: int = 1) -> bool:
	if count(item_id) < qty or qty <= 0:
		return false
	var remaining := qty
	for entry in entries.duplicate():
		if remaining == 0:
			break
		if entry["id"] != item_id:
			continue
		var take := mini(remaining, int(entry["qty"]))
		entry["qty"] = int(entry["qty"]) - take
		remaining -= take
		if int(entry["qty"]) == 0:
			_erase(entry)
	bus.emit_event(GameEvents.ITEM_LOST, {"item": item_id, "qty": qty})
	return true


func remove_uid(uid: int) -> bool:
	var entry := get_entry(uid)
	if entry.is_empty():
		return false
	_erase(entry)
	bus.emit_event(GameEvents.ITEM_LOST, {"item": entry["id"], "qty": int(entry["qty"]), "uid": uid})
	return true


func count(item_id: String) -> int:
	var total := 0
	for entry in entries:
		if entry["id"] == item_id:
			total += int(entry["qty"])
	return total


func get_entry(uid: int) -> Dictionary:
	for entry in entries:
		if int(entry["uid"]) == uid:
			return entry
	return {}


func find_first(item_id: String) -> Dictionary:
	for entry in entries:
		if entry["id"] == item_id:
			return entry
	return {}


func entries_in_category(category: String) -> Array:
	return entries.filter(func(e): return data.get_item(e["id"]).get("category", "") == category)


func set_prop(uid: int, key: String, value) -> void:
	var entry := get_entry(uid)
	if not entry.is_empty():
		entry["props"][key] = value


# --- Equipment ---------------------------------------------------------------

func equip(uid: int) -> bool:
	var entry := get_entry(uid)
	if entry.is_empty():
		return false
	var slot := str(data.get_item(entry["id"]).get("equip_slot", ""))
	if not SLOTS.has(slot):
		return false
	equipment[slot] = uid
	bus.emit_event(GameEvents.EQUIPMENT_CHANGED, {"slot": slot, "item": entry["id"]})
	return true


func unequip(slot: String) -> void:
	if not equipment.has(slot):
		return
	equipment.erase(slot)
	bus.emit_event(GameEvents.EQUIPMENT_CHANGED, {"slot": slot, "item": ""})


func equipped_entry(slot: String) -> Dictionary:
	if not equipment.has(slot):
		return {}
	return get_entry(int(equipment[slot]))


func equipped_item_id(slot: String) -> String:
	var entry := equipped_entry(slot)
	return "" if entry.is_empty() else str(entry["id"])


## Equips the next available bait of any kind; returns false if the player has none.
func cycle_bait() -> bool:
	var baits := entries_in_category("BAIT")
	if baits.is_empty():
		unequip("bait")
		return false
	var current := int(equipment.get("bait", -1))
	var index := 0
	for i in baits.size():
		if int(baits[i]["uid"]) == current:
			index = (i + 1) % baits.size()
	return equip(int(baits[index]["uid"]))


func consume_equipped_bait() -> bool:
	var entry := equipped_entry("bait")
	if entry.is_empty():
		return false
	var bait_id := str(entry["id"])
	remove(bait_id, 1)
	if equipped_entry("bait").is_empty():
		var next := find_first(bait_id)
		if not next.is_empty():
			equip(int(next["uid"]))
	return true


# --- Save ---------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"entries": entries.duplicate(true), "equipment": equipment.duplicate(), "next_uid": _next_uid}


func load_dict(d: Dictionary) -> void:
	entries = []
	for e in d.get("entries", []):
		entries.append({"uid": int(e["uid"]), "id": str(e["id"]), "qty": int(e["qty"]), "props": e.get("props", {}).duplicate()})
	equipment = {}
	for slot in d.get("equipment", {}):
		equipment[slot] = int(d["equipment"][slot])
	_next_uid = int(d.get("next_uid", 1))


# --- Internal -----------------------------------------------------------------

func _find_stack(item_id: String) -> Dictionary:
	for entry in entries:
		if entry["id"] == item_id and entry["props"].is_empty():
			return entry
	return {}


func _new_entry(item_id: String, qty: int, props: Dictionary) -> Dictionary:
	var entry := {"uid": _next_uid, "id": item_id, "qty": qty, "props": props}
	_next_uid += 1
	entries.append(entry)
	return entry


func _initial_props(def: Dictionary, props: Dictionary) -> Dictionary:
	var result := props.duplicate()
	if def.has("durability") and not result.has("durability"):
		result["durability"] = float(def["durability"])
	return result


func _erase(entry: Dictionary) -> void:
	entries.erase(entry)
	for slot in equipment.keys():
		if int(equipment[slot]) == int(entry["uid"]):
			unequip(slot)
