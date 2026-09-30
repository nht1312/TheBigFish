class_name NpcSystem
extends RefCounted
## Basic NPC logic for the Vertical Slice: picks which dialogue an NPC uses right now.
## Schedules, mood and simulation levels come later (docs/13).
##
## NPC data: { id, name, relationship, dialogues: [{ dialogue, conditions? }] } — first match wins.

var ctx: GameContext


func _init(context: GameContext) -> void:
	ctx = context


## Whether the NPC is at their spot right now. "schedule": [{ from, to }] in hours;
## no schedule means always there (docs/13 §4 — presence only, no movement yet).
func is_present(npc_id: String) -> bool:
	var def := ctx.data.get_def("npcs", npc_id)
	if def.has("spawns") and spawn_index(npc_id) < 0:
		return false
	var schedule: Array = def.get("schedule", [])
	if schedule.is_empty():
		return true
	var h := ctx.clock.minutes / 60.0
	for block in schedule:
		if h >= float(block["from"]) and h < float(block["to"]):
			return true
	return false


## Where the NPC is in the story right now: "spawns": [{ position, conditions?, ... }],
## first match wins (-1 = nowhere). A single "spawn" is always index 0.
func spawn_index(npc_id: String) -> int:
	var def := ctx.data.get_def("npcs", npc_id)
	if def.has("spawns"):
		var spawns: Array = def["spawns"]
		for i in spawns.size():
			if ctx.conditions.check(spawns[i].get("conditions", [])):
				return i
		return -1
	return 0 if def.has("spawn") else -1


func spawn_def(npc_id: String) -> Dictionary:
	var def := ctx.data.get_def("npcs", npc_id)
	var i := spawn_index(npc_id)
	if i < 0:
		return {}
	return def["spawns"][i] if def.has("spawns") else def["spawn"]


func dialogue_for(npc_id: String) -> String:
	for option in ctx.data.get_def("npcs", npc_id).get("dialogues", []):
		if ctx.conditions.check(option.get("conditions", [])):
			return str(option["dialogue"])
	return ""


func talk(npc_id: String) -> bool:
	var dialogue_id := dialogue_for(npc_id)
	if dialogue_id == "":
		return false
	return ctx.dialogue.start(dialogue_id)
