class_name InteractionSystem
extends RefCounted
## Logic behind world interactions (roadmap Phase 1). The 3D node only knows its
## interactable id; everything else is data.
##
## Interactable data: { id, name, kind, prompt?, conditions?, text?, locked_text?, ... }
##   collect: item + qty, or yield: [{ item, qty: n | [min, max], chance? }]
##            once: true → never again; respawn_days: n → again after n days (empty_text meanwhile)
##   talk:    npc (closed_text when the NPC is not there)
##   craft:   recipe
##   travel:  destination (spawn name), cost, minutes
##   dialogue: dialogue — a place that asks something (a bus stop: where to?)
##   sleep:   wake_hour
##   inspect: text
## Optional "position"/"size" let the world place the interactable itself.

const SLEEP := &"Sleep"
const TRAVEL := &"Travel"

var ctx: GameContext


func _init(context: GameContext) -> void:
	ctx = context


func is_unlocked(interactable_id: String) -> bool:
	var def := ctx.data.get_def("interactables", interactable_id)
	if def.is_empty():
		return false
	if def.get("once", false) and ctx.state.has_flag("used:" + interactable_id):
		return false
	if _waiting_to_respawn(def):
		return false
	return ctx.conditions.check(def.get("conditions", []))


## True while a used, respawning spot is still empty (the world hides its visual).
func is_depleted(interactable_id: String) -> bool:
	return _waiting_to_respawn(ctx.data.get_def("interactables", interactable_id))


## Short prompt for the HUD, e.g. "Lượm  Rác ven đường".
func prompt(interactable_id: String) -> String:
	var def := ctx.data.get_def("interactables", interactable_id)
	if def.is_empty():
		return ""
	var verb := str(def.get("prompt", ""))
	if verb == "" or not is_unlocked(interactable_id):
		verb = "Xem"
	var extra := ""
	if def.get("kind", "") == "travel" and is_unlocked(interactable_id):
		extra = "  (%s)" % EconomySystem.format_money(int(def.get("cost", 0)))
	return "%s  %s%s" % [verb, def.get("name", ""), extra]


## Performs the interaction. Returns { text } to show (may be empty).
func interact(interactable_id: String) -> Dictionary:
	var def := ctx.data.get_def("interactables", interactable_id)
	if def.is_empty():
		return {"text": ""}
	var result := {"text": ""}
	if _waiting_to_respawn(def):
		result["text"] = str(def.get("empty_text", def.get("locked_text", "")))
	elif not is_unlocked(interactable_id):
		result["text"] = str(def.get("locked_text", def.get("text", "")))
	else:
		match str(def.get("kind", "inspect")):
			"collect":
				result["text"] = _collect(interactable_id, def)
			"dialogue":
				ctx.dialogue.start(str(def["dialogue"]))
			"talk":
				var npc := str(def["npc"])
				if not ctx.npcs.is_present(npc):
					result["text"] = str(def.get("closed_text", def.get("text", "")))
				elif not ctx.npcs.talk(npc):
					result["text"] = str(def.get("text", ""))
			"craft":
				var recipe_id := str(def["recipe"])
				if ctx.crafting.can_craft(recipe_id):
					var recipe := ctx.data.get_def("recipes", recipe_id)
					ctx.crafting.craft(recipe_id)
					ctx.bus.emit_event(GameEvents.CUE, {"cue": "craft", "lines": recipe.get("craft_lines", [])})
				else:
					result["text"] = _missing_text(def, recipe_id)
			"travel":
				result["text"] = _travel(def)
			"sleep":
				ctx.clock.sleep_until(int(def.get("wake_hour", 6)))
				ctx.bus.emit_event(SLEEP, {"day": ctx.clock.day})
				ctx.bus.emit_event(GameEvents.CUE, {"cue": "sleep", "lines": def.get("sleep_lines", [])})
				ctx.bus.emit_event(GameEvents.AUTOSAVE_REQUESTED, {"reason": "sleep"})
			_:
				result["text"] = str(def.get("text", ""))
	ctx.bus.emit_event(GameEvents.INTERACTED, {"interactable": interactable_id})
	return result


func _collect(interactable_id: String, def: Dictionary) -> String:
	var got: Array[String] = []
	if def.has("yield"):
		for y in def["yield"]:
			if ctx.rng.randf() > float(y.get("chance", 1.0)):
				continue
			var qty_spec = y.get("qty", 1)
			var qty := ctx.rng.randi_range(int(qty_spec[0]), int(qty_spec[1])) if qty_spec is Array else int(qty_spec)
			if qty > 0:
				ctx.inventory.add(str(y["item"]), qty)
				got.append("%d %s" % [qty, ctx.data.display_name("items", str(y["item"])).to_lower()])
	else:
		ctx.inventory.add(str(def["item"]), int(def.get("qty", 1)))
	ctx.state.set_flag("used:" + interactable_id)
	if def.has("respawn_days"):
		ctx.state.set_var("used_day:" + interactable_id, str(ctx.clock.day))
	if def.has("yield"):
		return ("Lượm được " + ", ".join(got) + ".") if not got.is_empty() else str(def.get("empty_text", ""))
	return str(def.get("text", ""))


func _travel(def: Dictionary) -> String:
	var cost := int(def.get("cost", 0))
	if ctx.state.money < cost:
		return "Không đủ tiền đi xe. Vé %s." % EconomySystem.format_money(cost)
	return ctx.effects.travel(def)


func _waiting_to_respawn(def: Dictionary) -> bool:
	if def.is_empty() or not def.has("respawn_days"):
		return false
	var used := ctx.state.get_var("used_day:" + str(def["id"]))
	if used == "":
		return false
	return ctx.clock.day - int(used) < int(def["respawn_days"])


func _missing_text(def: Dictionary, recipe_id: String) -> String:
	var names: Array[String] = []
	for m in ctx.crafting.missing_inputs(recipe_id):
		names.append(ctx.data.display_name("items", m["item"]).to_lower())
	if names.is_empty():
		return str(def.get("locked_text", ""))
	return "%s %s." % [def.get("missing_text", "Còn thiếu:"), ", ".join(names)]
