class_name FishingOutcomes
extends RefCounted
## Applies a finished FishingSession to the game: inventory, gear, stats, records, events.
## Story reactions (giant fish, first catch) are data events listening to what this emits.

var ctx: GameContext


func _init(context: GameContext) -> void:
	ctx = context


func apply(result: Dictionary, rod_uid: int) -> void:
	var outcome := str(result.get("outcome", ""))
	if outcome in ["", "CANCELLED"]:
		return
	if result.get("bait_consumed", false):
		ctx.inventory.consume_equipped_bait()
	var rod := ctx.inventory.get_entry(rod_uid)
	if not rod.is_empty():
		ctx.inventory.set_prop(rod_uid, "durability", float(result.get("rod_durability", 0.0)))
	var fish_id := str(result.get("fish", ""))
	match outcome:
		FishingSession.LANDED:
			_land(fish_id, float(result.get("weight", 0.0)))
		FishingSession.LOST:
			ctx.bus.emit_event(GameEvents.FISH_LOST, {"fish": fish_id, "reason": result.get("reason", ""), "map": ctx.state.current_map})
		FishingSession.BROKEN:
			ctx.bus.emit_event(GameEvents.FISH_LOST, {"fish": fish_id, "reason": result.get("reason", ""), "map": ctx.state.current_map})
			if result.get("reason", "") == "ROD" and not rod.is_empty():
				ctx.inventory.remove_uid(rod_uid)
				ctx.bus.emit_event(GameEvents.ROD_BROKEN, {"item": rod["id"], "fish": fish_id, "map": ctx.state.current_map})


func _land(fish_id: String, weight: float) -> void:
	var def := ctx.data.get_def("fish", fish_id)
	var length_range: Array = def.get("length_cm", [10, 20])
	var weight_range: Array = def.get("weight_kg", [weight, weight])
	var t := inverse_lerp(float(weight_range[0]), float(weight_range[1]), weight) if weight_range[1] != weight_range[0] else 0.5
	var length := snappedf(lerpf(float(length_range[0]), float(length_range[1]), t), 0.1)
	var first := ctx.state.get_stat("FishCaught") < 1.0
	ctx.inventory.add(fish_id, 1, {
		"weight": weight, "length": length, "map": ctx.state.current_map,
		"day": ctx.clock.day, "time": ctx.clock.time_string(), "caught_at": ctx.clock.total_minutes(),
	})
	ctx.state.add_stat("FishCaught", 1)
	ctx.state.add_stat("FishCaught." + ctx.state.current_map, 1)
	ctx.state.add_stat("FishingSkill", float(def.get("skill_xp", 2)))
	var records := ctx.state.records
	if first:
		records["first_catch"] = {"fish": fish_id, "weight": weight, "day": ctx.clock.day}
	if weight > float(records.get("largest", {}).get("weight", 0.0)):
		records["largest"] = {"fish": fish_id, "weight": weight}
	ctx.bus.emit_event(GameEvents.FISH_LANDED, {
		"fish": fish_id, "weight": weight, "length": length, "map": ctx.state.current_map, "first": first,
	})
