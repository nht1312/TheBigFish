extends TestCase
## Save/load round trip, migration, debug commands, and the whole Vertical Slice
## story flow driven through the logic layer (VERTICAL-SLICE.md §32).

const TEST_SAVE_DIR := "user://test_saves"


func test_save_round_trip() -> void:
	var ctx := make_ctx()
	ctx.new_game()
	ctx.save.save_dir = TEST_SAVE_DIR
	ctx.state.set_flag("STORY_PROLOGUE_FISHERMAN")
	var uid := ctx.inventory.add("ITEM_IMPROVISED_ROD")
	ctx.inventory.equip(uid)
	ctx.inventory.set_prop(uid, "durability", 7.5)
	ctx.relationships.add_memory("NPC_MOTHER", "SAW_IMPROVISED_ROD")
	ctx.relationships.set_relationship("NPC_MOTHER", "Trust", 61)
	ctx.clock.set_time(16, 45)
	ctx.clock.set_weather("CLOUDY")
	ctx.bus.emit_event(GameEvents.FISHERMAN_CATCH_OBSERVED, {"npc": "NPC_OLD_FISHERMAN"})
	var player := {"position": [1.0, 2.0, 3.0], "yaw": 0.5}
	assert_eq(ctx.save.write("manual", player), OK)
	ctx.dispose()

	var loaded := make_ctx()
	loaded.save.save_dir = TEST_SAVE_DIR
	var save := loaded.save.read("manual")
	assert_eq(int(save["save_version"]), SaveSystem.SAVE_VERSION)
	var p := loaded.save.apply_save(save)
	assert_eq(p["position"], [1.0, 2.0, 3.0])
	assert_true(loaded.state.has_flag("STORY_PROLOGUE_FISHERMAN"))
	assert_eq(loaded.inventory.equipped_item_id("rod"), "ITEM_IMPROVISED_ROD")
	assert_eq(loaded.inventory.equipped_entry("rod")["props"]["durability"], 7.5)
	assert_true(loaded.relationships.has_memory("NPC_MOTHER", "SAW_IMPROVISED_ROD"))
	assert_eq(loaded.relationships.get_relationship("NPC_MOTHER", "Trust"), 61.0)
	assert_eq(loaded.clock.time_string(), "16:45")
	assert_eq(loaded.clock.weather, "CLOUDY")
	assert_eq(loaded.quests.get_state("QUEST_MAIN_FISHERMAN"), QuestSystem.ACTIVE)
	assert_eq(loaded.story_events.times_fired("EVENT_FIRST_FISHERMAN"), 1, "event history survives")
	loaded.bus.emit_event(GameEvents.FISHERMAN_CATCH_OBSERVED, {"npc": "NPC_OLD_FISHERMAN"})
	assert_eq(loaded.state.get_stat("FishingPassion"), 5.0, "once-events do not re-fire after load")
	loaded.dispose()


func test_corrupted_and_missing_saves() -> void:
	var ctx := make_ctx()
	ctx.save.save_dir = TEST_SAVE_DIR
	DirAccess.make_dir_recursive_absolute(TEST_SAVE_DIR)
	var f := FileAccess.open(ctx.save.slot_path("broken"), FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	assert_true(ctx.save.read("broken").is_empty())
	assert_true(ctx.save.read("nope").is_empty())
	ctx.dispose()


func test_migration_from_unversioned_save() -> void:
	var migrated := SaveSystem.migrate({"state": {}})
	assert_eq(int(migrated["save_version"]), 1)


func test_debug_commands() -> void:
	var ctx := make_ctx()
	var debug := DebugCommands.new(ctx)
	debug.execute("give_money 100")
	assert_eq(ctx.state.money, 100)
	debug.execute("give_item ITEM_BAMBOO 2")
	assert_eq(ctx.inventory.count("ITEM_BAMBOO"), 2)
	debug.execute("set_time 18:30")
	assert_eq(ctx.clock.time_string(), "18:30")
	debug.execute("set_weather heavy_rain")
	assert_eq(ctx.clock.weather, "HEAVY_RAIN")
	debug.execute("set_relationship NPC_MOTHER 80")
	assert_eq(ctx.relationships.get_relationship("NPC_MOTHER", "Trust"), 80.0)
	debug.execute("spawn_fish FISH_GIANT_DRAIN")
	assert_eq(ctx.state.get_var("fishing.next_fish"), "FISH_GIANT_DRAIN")
	debug.execute("give_rod")
	assert_eq(ctx.inventory.equipped_item_id("rod"), "ITEM_IMPROVISED_ROD")
	assert_eq(debug.execute("teleport home"), "unknown place", "no world attached")
	assert_true(debug.execute("bogus").begins_with("unknown"))
	ctx.dispose()


## The full Vertical Slice as a sequence of player actions on the logic layer.
func test_vertical_slice_flow() -> void:
	var ctx := make_ctx()
	ctx.new_game()
	var q := ctx.quests
	assert_eq(q.get_state("QUEST_MAIN_FISHERMAN"), QuestSystem.ACTIVE)

	# Watch the old fisherman catch a fish.
	ctx.bus.emit_event(GameEvents.FISHERMAN_CATCH_OBSERVED, {"npc": "NPC_OLD_FISHERMAN"})
	assert_true(ctx.state.has_flag("STORY_PROLOGUE_FISHERMAN"))
	assert_eq(q.current_objective_text("QUEST_MAIN_FISHERMAN"), "Về nhà")

	# Talk to Mother.
	ctx.interactions.interact("INT_MOTHER")
	while ctx.dialogue.is_active():
		if ctx.dialogue.visible_choices().is_empty():
			ctx.dialogue.advance()
		else:
			ctx.dialogue.choose(0)
	assert_eq(q.get_state("QUEST_MAIN_FISHERMAN"), QuestSystem.COMPLETED)
	assert_eq(q.get_state("QUEST_MAIN_FIND_MATERIALS"), QuestSystem.ACTIVE)

	# Collect materials, craft, dig bait.
	for id in ["INT_BAMBOO_CLUMP", "INT_INNER_TUBE", "INT_OLD_SHOE", "INT_SCRAP_PILE"]:
		ctx.interactions.interact(id)
	assert_eq(q.get_state("QUEST_MAIN_FIRST_ROD"), QuestSystem.ACTIVE)
	ctx.interactions.interact("INT_CRAFT_SPOT")
	assert_eq(ctx.inventory.count("ITEM_IMPROVISED_ROD"), 1)
	assert_eq(q.get_state("QUEST_MAIN_FIND_BAIT"), QuestSystem.ACTIVE)
	ctx.interactions.interact("INT_BAIT_SOIL_HOME")
	assert_eq(ctx.inventory.count("ITEM_BASIC_BAIT"), 4)
	assert_eq(q.get_state("QUEST_MAIN_FIRST_CAST"), QuestSystem.ACTIVE)

	# Reach the drain and land the first fish.
	ctx.state.enter_map("MAP_DRAIN")
	assert_eq(q.get_state("QUEST_MAIN_FIRST_FISH"), QuestSystem.ACTIVE)
	var rod_uid := int(ctx.inventory.find_first("ITEM_IMPROVISED_ROD")["uid"])
	ctx.inventory.equip(rod_uid)
	ctx.inventory.cycle_bait()
	ctx.fishing_outcomes.apply({"outcome": "LANDED", "fish": "FISH_SMALL_COMMON", "weight": 0.3, "bait_consumed": true, "rod_durability": 19.0}, rod_uid)
	assert_eq(q.get_state("QUEST_MAIN_BROKEN_ROD"), QuestSystem.ACTIVE)
	assert_eq(ctx.state.get_var("fishing.next_fish"), "FISH_GIANT_DRAIN")

	# The giant breaks the rod.
	ctx.fishing_outcomes.apply({"outcome": "BROKEN", "reason": "ROD", "fish": "FISH_GIANT_DRAIN", "bait_consumed": true, "rod_durability": 0.0}, rod_uid)
	assert_true(ctx.state.has_flag("GiantFishEncountered"))
	assert_eq(q.current_objective_text("QUEST_MAIN_BROKEN_ROD"), "Về nhà")
	assert_false(ctx.crafting.is_available("RECIPE_IMPROVISED_ROD"), "no second bamboo rod after the giant")

	# Return home: Mother's final scene.
	ctx.state.enter_map("MAP_HOME")
	ctx.state.enter_location("LOC_HOME_YARD")
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_MOTHER_VS_END")
	while ctx.dialogue.is_active():
		ctx.dialogue.advance()
	assert_true(ctx.state.has_flag("VERTICAL_SLICE_COMPLETE"))
	assert_eq(q.get_state("QUEST_MAIN_BROKEN_ROD"), QuestSystem.COMPLETED)
	ctx.dispose()
