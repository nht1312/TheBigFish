class_name ConditionEvaluator
extends RefCounted
## Shared condition checks for dialogue, quests, events and interactables (docs/18 §20).
##
## A condition is a Dictionary with a "type", or an Array of conditions (all must pass).
## null / empty Array always passes.

var ctx: GameContext


func _init(context: GameContext) -> void:
	ctx = context


func check(cond) -> bool:
	if cond == null:
		return true
	if cond is Array:
		for c in cond:
			if not check(c):
				return false
		return true
	if not cond is Dictionary:
		push_error("ConditionEvaluator: invalid condition %s" % str(cond))
		return false
	return _check_one(cond)


func _check_one(c: Dictionary) -> bool:
	var type := str(c.get("type", ""))
	match type:
		"all":
			return check(c.get("conditions", []))
		"any":
			for sub in c.get("conditions", []):
				if check(sub):
					return true
			return false
		"not":
			return not check(c.get("condition"))
		"flag":
			return ctx.state.has_flag(str(c["key"]))
		"not_flag":
			return not ctx.state.has_flag(str(c["key"]))
		"event_done":
			return ctx.state.has_flag("event_done:" + str(c["event"]))
		"has_item":
			return ctx.inventory.count(str(c["item"])) >= int(c.get("qty", 1))
		"lacks_item":
			return ctx.inventory.count(str(c["item"])) < int(c.get("qty", 1))
		"equipped":
			return ctx.inventory.equipped_item_id(str(c["slot"])) == str(c["item"])
		"stat_gte":
			return ctx.state.get_stat(str(c["key"])) >= float(c["value"])
		"stat_lt":
			return ctx.state.get_stat(str(c["key"])) < float(c["value"])
		"money_gte":
			return ctx.state.money >= int(c["value"])
		"var_equals":
			return ctx.state.get_var(str(c["key"])) == str(c.get("value", ""))
		"quest_state":
			return ctx.quests.get_state(str(c["quest"])) == str(c["state"])
		"current_map":
			return ctx.state.current_map == str(c["map"])
		"current_location":
			return ctx.state.current_location == str(c["location"])
		"map_unlocked":
			return ctx.state.is_map_unlocked(str(c["map"]))
		"day_phase":
			return ctx.clock.day_phase() == str(c["phase"])
		"hour_between":  # [from, to) in hours, wraps past midnight
			var h := ctx.clock.hour()
			var from := int(c["from"])
			var to := int(c["to"])
			return (h >= from and h < to) if from <= to else (h >= from or h < to)
		"weather":
			return ctx.clock.weather == str(c["weather"])
		"relationship_gte":
			return ctx.relationships.get_relationship(str(c["npc"]), str(c["dim"])) >= float(c["value"])
		"relationship_lt":
			return ctx.relationships.get_relationship(str(c["npc"]), str(c["dim"])) < float(c["value"])
		"has_memory":
			return ctx.relationships.has_memory(str(c["npc"]), str(c["memory"]))
		_:
			push_error("ConditionEvaluator: unknown condition type '%s'" % type)
			return false
