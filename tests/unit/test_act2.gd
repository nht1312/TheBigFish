extends TestCase
## Act II systems: economy, scrap collecting and respawn, jobs, travel, sleep, schedules.


var ctx: GameContext
var events: Array = []


func before_each() -> void:
	ctx = make_ctx()
	ctx.rng.seed = 7
	events = []
	ctx.bus.event_emitted.connect(func(n, d): events.append([n, d]))


func after_each() -> void:
	ctx.dispose()


func _emitted(name: StringName) -> Array:
	return events.filter(func(e): return e[0] == name)


func _cues(cue: String) -> Array:
	return _emitted(GameEvents.CUE).filter(func(e): return e[1].get("cue", "") == cue)


func _finish_slice() -> void:
	ctx.state.set_flag("VERTICAL_SLICE_COMPLETE")


func _play_through() -> void:
	for _i in 64:
		if not ctx.dialogue.is_active():
			return
		if ctx.dialogue.visible_choices().is_empty():
			ctx.dialogue.advance()
		else:
			ctx.dialogue.choose(0)


# --- Economy ---

func test_money_format() -> void:
	assert_eq(EconomySystem.format_money(20), "20.000đ")
	assert_eq(EconomySystem.format_money(1250), "1.250.000đ")
	assert_eq(EconomySystem.format_money(-5), "-5.000đ")


func test_buying_the_rod() -> void:
	ctx.state.money = 60
	assert_true(ctx.economy.buy("SHOP_FISHING", "ITEM_ROD_BASIC").begins_with("Không đủ tiền"), "too poor")
	assert_eq(ctx.inventory.count("ITEM_ROD_BASIC"), 0)
	ctx.state.money = 130
	assert_eq(ctx.economy.buy("SHOP_FISHING", "ITEM_ROD_BASIC"), "")
	assert_eq(ctx.state.money, 30)
	assert_eq(ctx.inventory.count("ITEM_ROD_BASIC"), 1)
	assert_eq(_emitted(EconomySystem.ITEM_BOUGHT).size(), 1)
	ctx.state.money = 130
	assert_false(ctx.economy.buy("SHOP_FISHING", "ITEM_ROD_BASIC") == "", "a second identical rod is refused")
	assert_eq(ctx.state.money, 130)


func test_stock_conditions() -> void:
	var ids := ctx.economy.stock("SHOP_FISHING").map(func(l): return l["item"])
	assert_false(ids.has("ITEM_ROD_REEL_BASIC"), "reel rod hidden before the first rod")
	ctx.inventory.add("ITEM_ROD_BASIC")
	ids = ctx.economy.stock("SHOP_FISHING").map(func(l): return l["item"])
	assert_true(ids.has("ITEM_ROD_REEL_BASIC"), "reel rod shown after")


func test_bait_bought_in_packs() -> void:
	ctx.state.money = 10
	assert_eq(ctx.economy.buy("SHOP_FISHING", "ITEM_BASIC_BAIT"), "")
	assert_eq(ctx.economy.buy("SHOP_FISHING", "ITEM_BASIC_BAIT"), "", "stackables can be bought again")
	assert_eq(ctx.inventory.count("ITEM_BASIC_BAIT"), 10)
	assert_eq(ctx.state.money, 4)


func test_fish_price_by_weight_and_freshness() -> void:
	var uid := ctx.inventory.add("FISH_CARP_COMMON", 1, {"weight": 2.0, "caught_at": ctx.clock.total_minutes()})
	var entry := ctx.inventory.get_entry(uid)
	assert_eq(ctx.economy.sell_price("SHOP_FISH_VENDOR", entry), 90, "2 kg × 45k")
	ctx.clock.advance_minutes(20 * 60)
	assert_eq(ctx.economy.sell_price("SHOP_FISH_VENDOR", entry), 63, "a day old is 70%")
	assert_eq(ctx.economy.freshness_label(entry), "hơi cũ")
	assert_eq(ctx.economy.sell_price("SHOP_SCRAP", entry), 0, "the scrap yard does not buy fish")


func test_selling_fish_and_scrap() -> void:
	ctx.inventory.add("FISH_SMALL_COMMON", 1, {"weight": 0.4, "caught_at": ctx.clock.total_minutes()})
	ctx.inventory.add("ITEM_SCRAP_CAN", 3)
	ctx.inventory.add("ITEM_ROD_BASIC")
	var money := ctx.state.money
	assert_eq(ctx.economy.sellable("SHOP_FISH_VENDOR").size(), 1, "fish only")
	assert_eq(ctx.economy.sell_all("SHOP_FISH_VENDOR"), 10, "0.4 kg × 25k")
	assert_eq(ctx.state.get_stat("FishSold"), 1.0)
	assert_eq(ctx.economy.sell_all("SHOP_SCRAP"), 6, "3 cans × 2k")
	assert_eq(ctx.state.money, money + 16)
	assert_eq(ctx.inventory.count("ITEM_ROD_BASIC"), 1, "gear is never sold")
	var sold := _emitted(EconomySystem.ITEM_SOLD)
	assert_eq(sold.size(), 2)
	assert_true(sold[0][1]["first"] and not sold[1][1]["first"], "first sale flagged once")


# --- Interactions ---

func test_scrap_needs_act2_and_respawns() -> void:
	assert_false(ctx.interactions.is_unlocked("INT_SCRAP_01"), "not during the slice")
	_finish_slice()
	assert_true(ctx.interactions.is_unlocked("INT_SCRAP_01"))
	var text: String = ctx.interactions.interact("INT_SCRAP_01")["text"]
	assert_true(text.begins_with("Lượm được"), text)
	assert_gt(ctx.inventory.count("ITEM_SCRAP_BOTTLE"), 0.0, "at least one bottle")
	assert_true(ctx.interactions.is_depleted("INT_SCRAP_01"))
	var before := ctx.inventory.count("ITEM_SCRAP_BOTTLE")
	assert_eq(ctx.interactions.interact("INT_SCRAP_01")["text"], "Lượm hết rồi. Mai chắc lại có.")
	assert_eq(ctx.inventory.count("ITEM_SCRAP_BOTTLE"), before, "an empty spot gives nothing")
	ctx.clock.sleep_until(6)
	assert_false(ctx.interactions.is_depleted("INT_SCRAP_01"), "back the next day")
	ctx.interactions.interact("INT_SCRAP_06")
	ctx.clock.sleep_until(6)
	assert_true(ctx.interactions.is_depleted("INT_SCRAP_06"), "metal takes two days")
	ctx.clock.sleep_until(6)
	assert_false(ctx.interactions.is_depleted("INT_SCRAP_06"))


func test_scrap_job_once_per_day() -> void:
	_finish_slice()
	ctx.clock.minutes = 9 * 60.0
	ctx.state.set_flag("dialogue_done:DIALOGUE_SCRAP_001")
	var money := ctx.state.money
	ctx.interactions.interact("INT_SCRAP_COLLECTOR")
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_SCRAP_SHOP")
	assert_eq(ctx.dialogue.visible_choices().size(), 3, "sell, work, leave")
	ctx.dialogue.choose(1)
	assert_eq(ctx.state.money, money + 25)
	assert_eq(ctx.clock.hour(), 11, "two hours of work")
	assert_eq(_cues("work").size(), 1)
	ctx.dialogue.advance()
	assert_false(ctx.dialogue.is_active())
	ctx.interactions.interact("INT_SCRAP_COLLECTOR")
	assert_eq(ctx.dialogue.visible_choices().size(), 2, "no second job today")
	ctx.dialogue.choose(0)
	assert_eq(_cues("open_shop").size(), 1, "selling opens the scrap shop")
	assert_eq(_cues("open_shop")[0][1]["shop"], "SHOP_SCRAP")


func test_npc_schedules() -> void:
	ctx.clock.minutes = 6 * 60.0
	assert_false(ctx.npcs.is_present("NPC_SHOP_OWNER"), "shop not open at 6")
	assert_true(ctx.npcs.is_present("NPC_FISH_VENDOR"), "market open at 6")
	assert_true(ctx.npcs.is_present("NPC_MOTHER"), "no schedule = always")
	ctx.clock.minutes = 12.5 * 60.0
	assert_false(ctx.npcs.is_present("NPC_SHOP_OWNER"), "lunch break")
	assert_false(ctx.npcs.is_present("NPC_FISH_VENDOR"), "market closed after noon")
	var text: String = ctx.interactions.interact("INT_FISH_VENDOR")["text"]
	assert_true(text.contains("buổi sáng"), text)
	assert_false(ctx.dialogue.is_active())


func test_bus_needs_the_lake_and_the_fare() -> void:
	ctx.state.money = 20
	ctx.interactions.interact("INT_BUS_STOP_HOME")
	assert_eq(ctx.state.money, 20, "locked before the lake is known")
	ctx.state.unlock_map("MAP_LAKE")
	var start := ctx.clock.total_minutes()
	assert_true(ctx.interactions.prompt("INT_BUS_STOP_HOME").contains("5.000đ"), "fare shown")
	ctx.interactions.interact("INT_BUS_STOP_HOME")
	assert_eq(ctx.state.money, 15)
	assert_eq(ctx.clock.total_minutes() - start, 40.0)
	var travel := _cues("travel")
	assert_eq(travel.size(), 1)
	assert_eq(travel[0][1]["destination"], "lake_stop")
	ctx.state.money = 3
	var refused: String = ctx.interactions.interact("INT_BUS_STOP_LAKE")["text"]
	assert_true(refused.begins_with("Không đủ tiền"), "cannot ride without the fare")
	assert_eq(_cues("travel").size(), 1)


func test_sleeping_at_night() -> void:
	_finish_slice()
	ctx.clock.minutes = 15 * 60.0
	assert_false(ctx.interactions.is_unlocked("INT_HOME_DOOR"), "too early")
	ctx.clock.minutes = 21 * 60.0
	var day := ctx.clock.day
	ctx.interactions.interact("INT_HOME_DOOR")
	assert_eq(ctx.clock.day, day + 1)
	assert_eq(ctx.clock.hour(), 6)
	assert_eq(_emitted(GameEvents.AUTOSAVE_REQUESTED).size(), 1)


# --- Story ---

func test_act2_quest_chain() -> void:
	ctx.quests.start("QUEST_MAIN_GET_BACK_UP")
	ctx.state.money = 150
	ctx.quests.evaluate_all()
	assert_true(ctx.quests.is_active("QUEST_MAIN_GET_BACK_UP"), "the shop visit comes first")
	ctx.state.set_flag("dialogue_done:DIALOGUE_SHOP_OWNER_001")
	ctx.quests.evaluate_all()
	assert_true(ctx.quests.is_active("QUEST_MAIN_FIRST_REAL_GEAR"), "saved up → buy the rod")
	assert_eq(ctx.economy.buy("SHOP_FISHING", "ITEM_ROD_BASIC"), "")
	ctx.inventory.add("FISH_SMALL_COMMON", 1, {"weight": 0.5, "caught_at": ctx.clock.total_minutes()})
	ctx.economy.sell_all("SHOP_FISH_VENDOR")
	ctx.quests.evaluate_all()
	assert_true(ctx.quests.is_active("QUEST_MAIN_THE_LAKE"))
	assert_eq(ctx.npcs.dialogue_for("NPC_SHOP_OWNER"), "DIALOGUE_SHOP_OWNER_LAKE", "the shop owner hears about the sale")
	ctx.npcs.talk("NPC_SHOP_OWNER")
	_play_through()
	assert_true(ctx.state.is_map_unlocked("MAP_LAKE"))
	ctx.state.enter_map("MAP_LAKE")
	ctx.state.add_stat("FishCaught.MAP_LAKE", 1)
	ctx.quests.evaluate_all()
	assert_eq(ctx.quests.get_state("QUEST_MAIN_THE_LAKE"), QuestSystem.COMPLETED)
	assert_true(ctx.state.has_flag("ACT_II_COMPLETE"), "chapter end event")
	assert_eq(ctx.state.get_var("story.chapter"), "ACT_III")


func test_chapter_two_morning() -> void:
	_finish_slice()
	ctx.bus.emit_event(GameEvents.CHAPTER_STARTED, {"chapter": "ACT_II"})
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_MOTHER_DAY2")
	assert_true(ctx.quests.is_active("QUEST_MAIN_GET_BACK_UP"))
	_play_through()
	assert_true(ctx.relationships.has_memory("NPC_MOTHER", "TALKED_ABOUT_MONEY"))


func test_mother_notices_the_new_rod() -> void:
	_finish_slice()
	ctx.state.set_flag("dialogue_done:DIALOGUE_MOTHER_001")
	assert_eq(ctx.npcs.dialogue_for("NPC_MOTHER"), "DIALOGUE_MOTHER_ACT2")
	ctx.inventory.add("ITEM_ROD_BASIC")
	assert_eq(ctx.npcs.dialogue_for("NPC_MOTHER"), "DIALOGUE_MOTHER_BASIC_ROD")
	var trust := ctx.relationships.get_relationship("NPC_MOTHER", "Trust")
	ctx.npcs.talk("NPC_MOTHER")
	ctx.dialogue.advance()
	ctx.dialogue.choose(1)  # "Người ta cho con."
	assert_true(ctx.state.has_flag("LIED_ABOUT_ROD"))
	assert_lt(ctx.relationships.get_relationship("NPC_MOTHER", "Trust"), trust, "lying costs trust")


func test_lake_fisherman_does_not_restart_the_prologue() -> void:
	ctx.bus.emit_event(GameEvents.FISHERMAN_CATCH_OBSERVED, {"npc": "NPC_LAKE_FISHERMAN"})
	assert_false(ctx.state.has_flag("STORY_PROLOGUE_FISHERMAN"))
