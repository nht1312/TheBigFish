class_name EffectExecutor
extends RefCounted
## Shared effects produced by dialogue, quests and events (docs/18 §21).
## An effect is a Dictionary with a "type"; run() accepts an Array of them.

var ctx: GameContext


func _init(context: GameContext) -> void:
	ctx = context


func run(effects) -> void:
	if effects == null:
		return
	for effect in effects:
		apply(effect)


func apply(e: Dictionary) -> void:
	var type := str(e.get("type", ""))
	match type:
		"give_item":
			ctx.inventory.add(str(e["item"]), int(e.get("qty", 1)))
		"remove_item":
			ctx.inventory.remove(str(e["item"]), int(e.get("qty", 1)))
		"add_money":
			ctx.state.add_money(int(e["amount"]))
		"set_flag":
			ctx.state.set_flag(str(e["key"]), bool(e.get("value", true)))
		"add_stat":
			ctx.state.add_stat(str(e["key"]), float(e["value"]))
		"set_var":
			ctx.state.set_var(str(e["key"]), str(e.get("value", "")))
		"start_quest":
			ctx.quests.start(str(e["quest"]))
		"complete_quest":
			ctx.quests.complete(str(e["quest"]))
		"modify_relationship":
			ctx.relationships.modify_relationship(str(e["npc"]), str(e["dim"]), float(e["delta"]))
		"add_memory":
			ctx.relationships.add_memory(str(e["npc"]), str(e["memory"]))
		"unlock_map":
			ctx.state.unlock_map(str(e["map"]))
		"trigger_event":
			ctx.story_events.trigger(str(e["event"]))
		"start_dialogue":
			ctx.dialogue.start(str(e["dialogue"]))
		"message":
			ctx.bus.emit_event(GameEvents.MESSAGE, {"text": str(e["text"]), "style": str(e.get("style", "thought")), "delay": float(e.get("delay", 0.0))})
		"travel":  # {destination (spawn), cost, minutes, lines?}
			travel(e)
		"confiscate":  # {key, slots?: ["rod"], categories?: ["FISH"], props_match?} — someone takes things away
			_confiscate(e)
		"return_confiscated":  # {key, categories?: ["FISHING_GEAR"]} — the rest stays gone
			_return_confiscated(e)
		"fishing_ban":  # the player promised not to fish for a day (today, or tomorrow if it is late)
			ctx.state.set_var("fishing.banned_day", str(ctx.clock.day + (1 if ctx.clock.hour() >= 12 else 0)))
		"cue":
			ctx.bus.emit_event(GameEvents.CUE, e)
		"open_shop":
			ctx.bus.emit_event(GameEvents.CUE, {"cue": "open_shop", "shop": str(e["shop"])})
		"mark_today":
			ctx.state.set_var(str(e["key"]), str(ctx.clock.day))
		"advance_time":
			ctx.clock.advance_minutes(float(e["minutes"]))
		"work":  # a small paid job: time passes, money earned, a short fade with what happened
			ctx.clock.advance_minutes(float(e.get("minutes", 60)))
			ctx.state.add_money(int(e.get("pay", 0)))
			ctx.state.add_stat("JobsDone", 1)
			ctx.bus.emit_event(GameEvents.CUE, {"cue": "work", "lines": e.get("lines", []), "pay": int(e.get("pay", 0))})
		"autosave":
			ctx.bus.emit_event(GameEvents.AUTOSAVE_REQUESTED, {"reason": str(e.get("reason", "effect"))})
		_:
			push_error("EffectExecutor: unknown effect type '%s'" % type)


## Pays the fare and moves time on; the world fades and moves the player on the "travel" cue.
## Returns "" or the reason it could not happen.
func travel(e: Dictionary) -> String:
	var cost := int(e.get("cost", 0))
	if not ctx.state.add_money(-cost):
		var text := "Không đủ tiền đi xe. Vé %s." % EconomySystem.format_money(cost)
		ctx.bus.emit_event(GameEvents.MESSAGE, {"text": text, "style": "info"})
		return text
	ctx.clock.advance_minutes(float(e.get("minutes", 30)))
	ctx.bus.emit_event(InteractionSystem.TRAVEL, {"destination": str(e["destination"]), "cost": cost})
	ctx.bus.emit_event(GameEvents.CUE, {"cue": "travel", "destination": str(e["destination"]), "lines": e.get("lines", e.get("travel_lines", []))})
	return ""


func _confiscate(e: Dictionary) -> void:
	var taken: Array = []
	for slot in e.get("slots", []):
		var entry := ctx.inventory.equipped_entry(str(slot))
		if not entry.is_empty():
			taken.append(entry.duplicate(true))
	var props_match: Dictionary = e.get("props_match", {})
	for category in e.get("categories", []):
		for entry in ctx.inventory.entries_in_category(str(category)):
			if taken.any(func(t): return int(t["uid"]) == int(entry["uid"])):
				continue
			if props_match.keys().all(func(k): return str(entry["props"].get(k, "")) == str(props_match[k])):
				taken.append(entry.duplicate(true))
	for entry in taken:
		ctx.inventory.remove_uid(int(entry["uid"]))
	var key := str(e["key"])
	ctx.state.set_var("confiscated:" + key, JSON.stringify(taken))
	ctx.state.set_flag("confiscated:" + key, not taken.is_empty())


func _return_confiscated(e: Dictionary) -> void:
	var key := str(e["key"])
	var taken = JSON.parse_string(ctx.state.get_var("confiscated:" + key))
	if taken is Array:
		var categories: Array = e.get("categories", [])
		for entry in taken:
			if categories.is_empty() or categories.has(ctx.data.get_item(entry["id"]).get("category", "")):
				ctx.inventory.add(str(entry["id"]), int(entry.get("qty", 1)), entry.get("props", {}))
	ctx.state.set_var("confiscated:" + key, "")
	ctx.state.set_flag("confiscated:" + key, false)
