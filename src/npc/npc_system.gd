class_name NpcSystem
extends RefCounted
## Basic NPC logic for the Vertical Slice: picks which dialogue an NPC uses right now.
## Schedules, mood and simulation levels come later (docs/13).
##
## NPC data: { id, name, relationship, dialogues: [{ dialogue, conditions? }] } — first match wins.

var ctx: GameContext


func _init(context: GameContext) -> void:
	ctx = context


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
