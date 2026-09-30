class_name DebugCommands
extends RefCounted
## Development console commands (CLAUDE.md §22, VERTICAL-SLICE §31). Debug builds only.
## World-dependent commands (teleport) go through `world_hooks`.

var ctx: GameContext
var world_hooks: Dictionary = {}  # "teleport": Callable(String) -> bool

const HELP := """give_money <n> | give_item <ITEM_ID> [n] | give_materials | give_rod
set_time <hh:mm> | set_weather <sunny|cloudy|light_rain|heavy_rain|storm>
set_relationship <NPC_ID> <value> [dim] | unlock_map <MAP_ID>
start_quest <ID> | complete_quest <ID> | reset_quest <ID> | trigger_event <ID>
set_flag <KEY> [true|false] | spawn_fish <FISH_ID> | teleport <home|drain|fisherman>
state | help"""


func _init(context: GameContext) -> void:
	ctx = context


## Runs one command line and returns the text to print.
func execute(line: String) -> String:
	var args := Array(line.strip_edges().split(" ", false))
	if args.is_empty():
		return ""
	var cmd := str(args.pop_front()).to_lower()
	match cmd:
		"help":
			return HELP
		"give_money":
			return _need(args, 1, func(): ctx.state.add_money(int(args[0])); return "money = %d" % ctx.state.money)
		"give_item":
			return _need(args, 1, func():
				var qty := int(args[1]) if args.size() > 1 else 1
				return "ok" if ctx.inventory.add(str(args[0]), qty) >= 0 else "unknown item")
		"give_materials":
			for item in ["ITEM_BAMBOO", "ITEM_RUBBER_LINE", "ITEM_SHOE_FLOAT", "ITEM_WIRE"]:
				ctx.inventory.add(item)
			ctx.inventory.add("ITEM_BASIC_BAIT", 5)
			return "materials + bait added"
		"give_rod":
			var uid := ctx.inventory.add("ITEM_IMPROVISED_ROD")
			ctx.inventory.equip(uid)
			ctx.inventory.add("ITEM_BASIC_BAIT", 5)
			ctx.inventory.cycle_bait()
			return "rod equipped"
		"set_time":
			return _need(args, 1, func():
				var parts := str(args[0]).split(":")
				ctx.clock.set_time(int(parts[0]), int(parts[1]) if parts.size() > 1 else 0)
				return ctx.clock.time_string())
		"set_weather":
			return _need(args, 1, func(): return "ok" if ctx.clock.set_weather(str(args[0])) else "unknown weather")
		"set_relationship":
			return _need(args, 2, func():
				var dim := str(args[2]) if args.size() > 2 else "Trust"
				ctx.relationships.set_relationship(str(args[0]), dim, float(args[1]))
				return "%s.%s = %s" % [args[0], dim, ctx.relationships.get_relationship(str(args[0]), dim)])
		"unlock_map":
			return _need(args, 1, func(): ctx.state.unlock_map(str(args[0])); return "ok")
		"start_quest":
			return _need(args, 1, func(): return "ok" if ctx.quests.start(str(args[0])) else "cannot start")
		"complete_quest":
			return _need(args, 1, func(): return "ok" if ctx.quests.complete(str(args[0])) else "cannot complete")
		"reset_quest":
			return _need(args, 1, func(): ctx.quests.reset(str(args[0])); return "reset")
		"trigger_event":
			return _need(args, 1, func(): return "ok" if ctx.story_events.trigger(str(args[0]), true) else "unknown event")
		"set_flag":
			return _need(args, 1, func():
				ctx.state.set_flag(str(args[0]), args.size() < 2 or str(args[1]) != "false")
				return "ok")
		"spawn_fish":
			return _need(args, 1, func():
				if not ctx.data.has_def("fish", str(args[0])):
					return "unknown fish"
				ctx.state.set_var("fishing.next_fish", str(args[0]))
				return "next bite: " + str(args[0]))
		"teleport":
			return _need(args, 1, func():
				var hook: Callable = world_hooks.get("teleport", Callable())
				return "ok" if hook.is_valid() and hook.call(str(args[0])) else "unknown place")
		"state":
			return "map=%s loc=%s time=%s weather=%s money=%d quests=%s" % [
				ctx.state.current_map, ctx.state.current_location, ctx.clock.time_string(),
				ctx.clock.weather, ctx.state.money, str(ctx.quests.active_quests())]
	return "unknown command (type help)"


func _need(args: Array, n: int, action: Callable) -> String:
	if args.size() < n:
		return "missing argument (type help)"
	return str(action.call())
