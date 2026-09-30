class_name InteractionSystem
extends RefCounted
## Logic behind world interactions: Inspect / Collect / Talk / Craft (roadmap Phase 1).
## The 3D node only knows its interactable id; everything else is data.
##
## Interactable data: { id, name, kind, prompt?, conditions?, text?, locked_text?,
##                      item?, qty?, once?, npc?, recipe?, missing_text? }
## Collect is repeatable unless "once": true; conditions decide when it can be used.

var ctx: GameContext


func _init(context: GameContext) -> void:
	ctx = context


func is_unlocked(interactable_id: String) -> bool:
	var def := ctx.data.get_def("interactables", interactable_id)
	if def.is_empty():
		return false
	if def.get("once", false) and ctx.state.has_flag("used:" + interactable_id):
		return false
	return ctx.conditions.check(def.get("conditions", []))


## Short prompt for the HUD, e.g. "Nhặt  Cây tre".
func prompt(interactable_id: String) -> String:
	var def := ctx.data.get_def("interactables", interactable_id)
	if def.is_empty():
		return ""
	var verb := str(def.get("prompt", ""))
	if verb == "" or not is_unlocked(interactable_id):
		verb = "Xem"
	return "%s  %s" % [verb, def.get("name", "")]


## Performs the interaction. Returns { text } to show (may be empty).
func interact(interactable_id: String) -> Dictionary:
	var def := ctx.data.get_def("interactables", interactable_id)
	if def.is_empty():
		return {"text": ""}
	var result := {"text": ""}
	if not is_unlocked(interactable_id):
		result["text"] = str(def.get("locked_text", def.get("text", "")))
	else:
		match str(def.get("kind", "inspect")):
			"collect":
				ctx.inventory.add(str(def["item"]), int(def.get("qty", 1)))
				ctx.state.set_flag("used:" + interactable_id)
				result["text"] = str(def.get("text", ""))
			"talk":
				if not ctx.npcs.talk(str(def["npc"])):
					result["text"] = str(def.get("text", ""))
			"craft":
				var recipe_id := str(def["recipe"])
				if ctx.crafting.can_craft(recipe_id):
					var recipe := ctx.data.get_def("recipes", recipe_id)
					ctx.crafting.craft(recipe_id)
					ctx.bus.emit_event(GameEvents.CUE, {"cue": "craft", "lines": recipe.get("craft_lines", [])})
				else:
					result["text"] = _missing_text(def, recipe_id)
			_:
				result["text"] = str(def.get("text", ""))
	ctx.bus.emit_event(GameEvents.INTERACTED, {"interactable": interactable_id})
	return result


func _missing_text(def: Dictionary, recipe_id: String) -> String:
	var names: Array[String] = []
	for m in ctx.crafting.missing_inputs(recipe_id):
		names.append(ctx.data.display_name("items", m["item"]).to_lower())
	if names.is_empty():
		return str(def.get("locked_text", ""))
	return "%s %s." % [def.get("missing_text", "Còn thiếu:"), ", ".join(names)]
