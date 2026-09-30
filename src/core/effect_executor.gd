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
			ctx.bus.emit_event(GameEvents.MESSAGE, {"text": str(e["text"]), "style": str(e.get("style", "thought"))})
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
