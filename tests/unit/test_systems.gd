extends TestCase
## Inventory, crafting, conditions, quests, dialogue, events, relationships.


var ctx: GameContext
var events: Array = []


func before_each() -> void:
	ctx = make_ctx()
	events = []
	ctx.bus.event_emitted.connect(func(n, d): events.append([n, d]))


func after_each() -> void:
	ctx.dispose()


func _emitted(name: StringName) -> bool:
	return events.any(func(e): return e[0] == name)


# --- Inventory ---

func test_inventory_stacks_and_removes_atomically() -> void:
	ctx.inventory.add("ITEM_BASIC_BAIT", 3)
	ctx.inventory.add("ITEM_BASIC_BAIT", 2)
	assert_eq(ctx.inventory.count("ITEM_BASIC_BAIT"), 5)
	assert_eq(ctx.inventory.entries.size(), 1, "stackable items share one entry")
	assert_false(ctx.inventory.remove("ITEM_BASIC_BAIT", 9), "cannot remove more than owned")
	assert_eq(ctx.inventory.count("ITEM_BASIC_BAIT"), 5, "failed remove changes nothing")
	assert_true(ctx.inventory.remove("ITEM_BASIC_BAIT", 5))
	assert_eq(ctx.inventory.entries.size(), 0)
	assert_true(_emitted(GameEvents.ITEM_OBTAINED) and _emitted(GameEvents.ITEM_LOST))


func test_inventory_rejects_unknown_item() -> void:
	assert_eq(ctx.inventory.add("ITEM_DOES_NOT_EXIST"), -1)
	assert_eq(ctx.inventory.entries.size(), 0)


func test_gear_has_durability_and_equips() -> void:
	var uid := ctx.inventory.add("ITEM_IMPROVISED_ROD")
	assert_eq(ctx.inventory.get_entry(uid)["props"]["durability"], 20.0)
	assert_true(ctx.inventory.equip(uid))
	assert_eq(ctx.inventory.equipped_item_id("rod"), "ITEM_IMPROVISED_ROD")
	ctx.inventory.remove_uid(uid)
	assert_eq(ctx.inventory.equipped_item_id("rod"), "", "removing gear unequips it")


func test_bait_consumption_keeps_slot_filled() -> void:
	ctx.inventory.add("ITEM_BASIC_BAIT", 2)
	assert_true(ctx.inventory.cycle_bait())
	assert_true(ctx.inventory.consume_equipped_bait())
	assert_eq(ctx.inventory.equipped_item_id("bait"), "ITEM_BASIC_BAIT")
	assert_true(ctx.inventory.consume_equipped_bait())
	assert_eq(ctx.inventory.equipped_item_id("bait"), "")
	assert_false(ctx.inventory.consume_equipped_bait())


# --- Crafting ---

func test_crafting_requires_story_and_materials() -> void:
	assert_false(ctx.crafting.is_available("RECIPE_IMPROVISED_ROD"), "locked before seeing the fisherman")
	ctx.state.set_flag("STORY_PROLOGUE_FISHERMAN")
	assert_eq(ctx.crafting.missing_inputs("RECIPE_IMPROVISED_ROD").size(), 4)
	for item in ["ITEM_BAMBOO", "ITEM_RUBBER_LINE", "ITEM_SHOE_FLOAT"]:
		ctx.inventory.add(item)
	assert_false(ctx.crafting.craft("RECIPE_IMPROVISED_ROD"), "wire still missing")
	assert_eq(ctx.inventory.count("ITEM_BAMBOO"), 1, "nothing consumed on failure")
	ctx.inventory.add("ITEM_WIRE")
	assert_true(ctx.crafting.craft("RECIPE_IMPROVISED_ROD"))
	assert_eq(ctx.inventory.count("ITEM_IMPROVISED_ROD"), 1)
	assert_eq(ctx.inventory.count("ITEM_BAMBOO"), 0, "materials consumed")
	assert_true(ctx.state.has_flag("crafted:ITEM_IMPROVISED_ROD"))


# --- Conditions ---

func test_conditions() -> void:
	var c := ctx.conditions
	assert_true(c.check(null))
	assert_true(c.check([]))
	ctx.state.set_flag("A")
	assert_true(c.check({"type": "flag", "key": "A"}))
	assert_false(c.check({"type": "not", "condition": {"type": "flag", "key": "A"}}))
	assert_true(c.check({"type": "any", "conditions": [{"type": "flag", "key": "B"}, {"type": "flag", "key": "A"}]}))
	ctx.clock.set_time(22, 0)
	assert_true(c.check({"type": "hour_between", "from": 21, "to": 5}), "wraps midnight")
	assert_true(c.check({"type": "day_phase", "phase": "NIGHT"}))
	ctx.relationships.set_relationship("NPC_MOTHER", "Concern", 75)
	assert_true(c.check({"type": "relationship_gte", "npc": "NPC_MOTHER", "dim": "Concern", "value": 70}))


# --- Quests ---

func test_quest_chain_latches_objectives() -> void:
	ctx.quests.start("QUEST_MAIN_FIND_MATERIALS")
	ctx.inventory.add("ITEM_BAMBOO")
	ctx.inventory.add("ITEM_WIRE")
	assert_eq(ctx.quests.get_state("QUEST_MAIN_FIND_MATERIALS"), QuestSystem.ACTIVE)
	ctx.inventory.add("ITEM_RUBBER_LINE")
	ctx.inventory.add("ITEM_SHOE_FLOAT")
	assert_eq(ctx.quests.get_state("QUEST_MAIN_FIND_MATERIALS"), QuestSystem.COMPLETED)
	assert_eq(ctx.quests.get_state("QUEST_MAIN_FIRST_ROD"), QuestSystem.ACTIVE, "next quest started")


func test_sequential_quest_waits_for_order() -> void:
	ctx.quests.start("QUEST_MAIN_BROKEN_ROD")
	ctx.state.enter_location("LOC_HOME_YARD")  # too early: giant not met yet
	ctx.state.enter_location("LOC_ROAD")
	ctx.state.set_flag("event_done:EVENT_GIANT_FISH_BREAKS_ROD")
	assert_eq(ctx.quests.current_objective_text("QUEST_MAIN_BROKEN_ROD"), "Về nhà")
	ctx.state.enter_location("LOC_HOME_YARD")
	assert_eq(ctx.quests.current_objective_text("QUEST_MAIN_BROKEN_ROD"), "")


func test_quest_cannot_start_twice() -> void:
	assert_true(ctx.quests.start("QUEST_MAIN_FIRST_CAST"))
	assert_false(ctx.quests.start("QUEST_MAIN_FIRST_CAST"))
	assert_false(ctx.quests.start("QUEST_UNKNOWN"))


# --- Dialogue ---

func test_dialogue_choices_and_effects() -> void:
	ctx.state.set_flag("STORY_PROLOGUE_FISHERMAN")
	assert_eq(ctx.npcs.dialogue_for("NPC_MOTHER"), "DIALOGUE_MOTHER_001")
	assert_true(ctx.npcs.talk("NPC_MOTHER"))
	assert_eq(ctx.dialogue.current_node()["text"], "Về rồi đó hả?")
	ctx.dialogue.advance()
	assert_eq(ctx.dialogue.visible_choices().size(), 2)
	ctx.dialogue.choose(0)  # mention the fisherman
	ctx.dialogue.advance()
	ctx.dialogue.choose(0)  # "thử coi"
	assert_true(ctx.relationships.has_memory("NPC_MOTHER", "PLAYER_SAID_WANTS_TO_FISH"))
	assert_eq(ctx.relationships.get_relationship("NPC_MOTHER", "Understanding"), 22.0)
	ctx.dialogue.advance()
	ctx.dialogue.advance()
	assert_false(ctx.dialogue.is_active())
	assert_true(ctx.state.has_flag("dialogue_done:DIALOGUE_MOTHER_001"))
	assert_eq(ctx.npcs.dialogue_for("NPC_MOTHER"), "DIALOGUE_MOTHER_IDLE", "intro only once")


func test_dialogue_branch_by_time() -> void:
	ctx.clock.set_time(18, 0)
	ctx.dialogue.start("DIALOGUE_MOTHER_IDLE")
	assert_eq(ctx.dialogue.current_node_id, "evening")


func test_dialogue_queue() -> void:
	ctx.dialogue.start("DIALOGUE_MOTHER_IDLE")
	ctx.dialogue.start("DIALOGUE_FISHERMAN_001")
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_MOTHER_IDLE")
	ctx.dialogue.advance()
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_FISHERMAN_001", "queued dialogue starts next")


# --- Story events ---

func test_story_event_fires_once_with_effects() -> void:
	ctx.bus.emit_event(GameEvents.FISHERMAN_CATCH_OBSERVED, {"npc": "NPC_OLD_FISHERMAN"})
	assert_true(ctx.state.has_flag("STORY_PROLOGUE_FISHERMAN"))
	assert_eq(ctx.state.get_stat("FishingPassion"), 5.0)
	ctx.bus.emit_event(GameEvents.FISHERMAN_CATCH_OBSERVED, {"npc": "NPC_OLD_FISHERMAN"})
	assert_eq(ctx.state.get_stat("FishingPassion"), 5.0, "once")
	assert_eq(ctx.story_events.times_fired("EVENT_FIRST_FISHERMAN"), 1)


func test_story_event_match_and_conditions() -> void:
	ctx.bus.emit_event(GameEvents.LOCATION_ENTERED, {"location": "LOC_HOME_YARD"})
	assert_false(ctx.dialogue.is_active(), "ending needs the giant encounter first")
	ctx.state.set_flag("GiantFishEncountered")
	ctx.bus.emit_event(GameEvents.LOCATION_ENTERED, {"location": "LOC_ROAD"})
	assert_false(ctx.dialogue.is_active(), "wrong location")
	ctx.bus.emit_event(GameEvents.LOCATION_ENTERED, {"location": "LOC_HOME_YARD"})
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_MOTHER_VS_END")


# --- Interactions ---

func test_interactions_follow_conditions() -> void:
	var r := ctx.interactions.interact("INT_BAMBOO_CLUMP")
	assert_eq(ctx.inventory.count("ITEM_BAMBOO"), 0, "not interested in fishing yet")
	assert_eq(r["text"], "Bụi tre sau nhà. Mẹ hay chặt làm cọc phơi đồ.")
	ctx.state.set_flag("STORY_PROLOGUE_FISHERMAN")
	ctx.interactions.interact("INT_BAMBOO_CLUMP")
	ctx.interactions.interact("INT_BAMBOO_CLUMP")
	assert_eq(ctx.inventory.count("ITEM_BAMBOO"), 1, "only one needed at a time")
	r = ctx.interactions.interact("INT_CRAFT_SPOT")
	assert_true(r["text"].contains("dây thun"), "lists missing materials: " + r["text"])


# --- Relationships ---

func test_relationship_clamps_and_memory() -> void:
	ctx.relationships.modify_relationship("NPC_MOTHER", "Trust", 500)
	assert_eq(ctx.relationships.get_relationship("NPC_MOTHER", "Trust"), 100.0)
	ctx.relationships.add_memory("NPC_MOTHER", "X")
	ctx.relationships.add_memory("NPC_MOTHER", "X")
	assert_eq(ctx.relationships.get_memories("NPC_MOTHER").size(), 1)


# --- Clock ---

func test_clock_phases_and_rollover() -> void:
	ctx.clock.set_time(23, 50)
	ctx.clock.time_scale = 1.0
	ctx.clock.advance(20.0)
	assert_eq(ctx.clock.day, 2)
	assert_eq(ctx.clock.time_string(), "00:10")
	assert_false(ctx.clock.set_weather("snow"))
	assert_true(ctx.clock.set_weather("light_rain"))
	assert_gt(ctx.clock.fish_activity(), 0.0)
