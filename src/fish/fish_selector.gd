class_name FishSelector
extends RefCounted
## Chooses which fish is interested in a cast (docs/07 §29, docs/08 §8, §20–21).


## Returns { fish: def, weight: kg } or {} when nothing is biting here.
## forced_id (story/debug) wins over the spot's fish table.
static func pick(spot: Dictionary, data: DataRegistry, bait_id: String, forced_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var fish_def := {}
	if forced_id != "":
		fish_def = data.get_def("fish", forced_id)
	if fish_def.is_empty():
		fish_def = _weighted_species(spot, data, bait_id, rng)
	if fish_def.is_empty():
		return {}
	var w: Array = fish_def.get("weight_kg", [0.2, 0.5])
	return {"fish": fish_def, "weight": snappedf(rng.randf_range(float(w[0]), float(w[1])), 0.01)}


static func bait_match(fish_def: Dictionary, data: DataRegistry, bait_id: String) -> bool:
	var bait_type := str(data.get_item(bait_id).get("bait_type", ""))
	return bait_type != "" and fish_def.get("bait_preference", []).has(bait_type)


static func _weighted_species(spot: Dictionary, data: DataRegistry, bait_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var candidates: Array = []
	var total := 0.0
	for entry in spot.get("fish", []):
		var def := data.get_def("fish", str(entry["fish"]))
		if def.is_empty():
			continue
		var weight := float(entry.get("weight", 1.0)) * (1.5 if bait_match(def, data, bait_id) else 0.5)
		candidates.append([def, weight])
		total += weight
	if total <= 0.0:
		return {}
	var roll := rng.randf() * total
	for c in candidates:
		roll -= c[1]
		if roll <= 0.0:
			return c[0]
	return candidates[-1][0]
