class_name CraftingSystem
extends RefCounted
## Recipe-based crafting (docs/11). Validate → consume materials → create output.

var ctx: GameContext


func _init(context: GameContext) -> void:
	ctx = context


## Recipe is known/allowed right now (story conditions), regardless of materials.
func is_available(recipe_id: String) -> bool:
	var recipe := ctx.data.get_def("recipes", recipe_id)
	return not recipe.is_empty() and ctx.conditions.check(recipe.get("conditions", []))


## [{ item, need, have }] for every input the player does not have enough of.
func missing_inputs(recipe_id: String) -> Array:
	var missing: Array = []
	for input in ctx.data.get_def("recipes", recipe_id).get("inputs", []):
		var need := int(input.get("qty", 1))
		var have := ctx.inventory.count(str(input["item"]))
		if have < need:
			missing.append({"item": str(input["item"]), "need": need, "have": have})
	return missing


func can_craft(recipe_id: String) -> bool:
	return is_available(recipe_id) and missing_inputs(recipe_id).is_empty()


func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false
	var recipe := ctx.data.get_def("recipes", recipe_id)
	for input in recipe.get("inputs", []):
		ctx.inventory.remove(str(input["item"]), int(input.get("qty", 1)))
	var output: Dictionary = recipe["output"]
	var output_id := str(output["item"])
	var uid := ctx.inventory.add(output_id, int(output.get("qty", 1)))
	ctx.state.set_flag("crafted:" + output_id)
	ctx.bus.emit_event(GameEvents.ITEM_CRAFTED, {"recipe": recipe_id, "item": output_id, "uid": uid})
	return true
