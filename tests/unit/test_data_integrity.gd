extends TestCase
## Every id referenced by data must exist (docs/18 §44).


var data: DataRegistry


func before_each() -> void:
	data = DataRegistry.new().load_from("res://data")


func test_data_loads_without_errors() -> void:
	assert_eq(data.errors.size(), 0, "load errors: %s" % str(data.errors))
	for collection in ["items", "recipes", "fish", "quests", "dialogues", "events", "npcs", "maps", "interactables"]:
		assert_gt(data.all(collection).size(), 0, "collection %s empty" % collection)


func test_quest_references() -> void:
	for quest in data.all("quests"):
		for next_id in quest.get("next", []):
			assert_true(data.has_def("quests", next_id), "%s → unknown next %s" % [quest["id"], next_id])
		assert_gt(quest.get("objectives", []).size(), 0, "%s has no objectives" % quest["id"])


func test_dialogue_nodes_resolve() -> void:
	for dialogue in data.all("dialogues"):
		var nodes: Dictionary = dialogue["nodes"]
		assert_true(nodes.has(dialogue["start"]), "%s missing start node" % dialogue["id"])
		for node_id in nodes:
			var node: Dictionary = nodes[node_id]
			var targets: Array = []
			if node.has("next"):
				targets.append(node["next"])
			for c in node.get("choices", []):
				targets.append(c.get("next", "end"))
			for b in node.get("branch", []):
				targets.append(b["next"])
			for t in targets:
				assert_true(t == "end" or nodes.has(t), "%s.%s → missing node %s" % [dialogue["id"], node_id, t])
			var speaker := str(node.get("speaker", "NARRATION"))
			assert_true(speaker in ["NARRATION", "PLAYER"] or data.has_def("npcs", speaker), "unknown speaker %s" % speaker)


func test_npc_and_event_dialogues_exist() -> void:
	for npc in data.all("npcs"):
		for option in npc.get("dialogues", []):
			assert_true(data.has_def("dialogues", option["dialogue"]), "%s → %s" % [npc["id"], option["dialogue"]])
	for event in data.all("events"):
		if event.has("dialogue"):
			assert_true(data.has_def("dialogues", event["dialogue"]), "%s → %s" % [event["id"], event["dialogue"]])


func test_items_referenced_exist() -> void:
	for recipe in data.all("recipes"):
		for input in recipe["inputs"]:
			assert_false(data.get_item(input["item"]).is_empty(), "recipe input %s" % input["item"])
		assert_false(data.get_item(recipe["output"]["item"]).is_empty(), "recipe output")
	for it in data.all("interactables"):
		if it.has("item"):
			assert_false(data.get_item(it["item"]).is_empty(), "%s → %s" % [it["id"], it["item"]])
		if it.has("npc"):
			assert_true(data.has_def("npcs", it["npc"]), "%s → %s" % [it["id"], it["npc"]])
		if it.has("recipe"):
			assert_true(data.has_def("recipes", it["recipe"]), "%s → %s" % [it["id"], it["recipe"]])


func test_fishing_spots_reference_fish() -> void:
	for map in data.all("maps"):
		for spot in map.get("fishing_spots", []):
			assert_eq(spot["rect"].size(), 4, "%s rect" % spot["id"])
			for entry in spot.get("fish", []):
				assert_true(data.has_def("fish", entry["fish"]), "%s → %s" % [spot["id"], entry["fish"]])


func test_canonical_ids_present() -> void:
	for id in ["NPC_MOTHER", "NPC_OLD_FISHERMAN"]:
		assert_true(data.has_def("npcs", id), id)
	for id in ["ITEM_BAMBOO", "ITEM_RUBBER_LINE", "ITEM_SHOE_FLOAT", "ITEM_WIRE", "ITEM_BASIC_BAIT", "ITEM_IMPROVISED_ROD"]:
		assert_true(data.has_def("items", id), id)
	for id in ["FISH_SMALL_COMMON", "FISH_GIANT_DRAIN"]:
		assert_true(data.has_def("fish", id), id)
	for id in ["QUEST_MAIN_FIRST_FISH", "QUEST_MAIN_BROKEN_ROD"]:
		assert_true(data.has_def("quests", id), id)
	for id in ["EVENT_FIRST_FISHERMAN", "EVENT_GIANT_FISH", "EVENT_GIANT_FISH_BREAKS_ROD"]:
		assert_true(data.has_def("events", id), id)
	for id in ["MAP_HOME", "MAP_DRAIN"]:
		assert_true(data.has_def("maps", id), id)
