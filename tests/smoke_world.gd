extends SceneTree
## Boots the real main scene headless and drives the Vertical Slice through the actual
## world nodes (player, actors, fishing controller, HUD). Catches runtime script errors
## that unit tests on the logic layer cannot see.
##   godot --headless --path . -s tests/smoke_world.gd

var main: Node
var world: WorldScene
var step := 0
var wait := 0.0
var failures: Array[String] = []
var elapsed := 0.0
var _money_mark := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 600.0:
		_fail("timeout at step %d" % step)
		return _done()
	if wait > 0.0:
		wait -= delta
		return false
	var game: Node = root.get_node("Game")
	match step:
		0:
			main._menu.new_game_requested.emit()
			wait = 0.3
		1:
			world = main._world
			_check(world != null, "world created")
			_check(game.ctx.quests.is_active("QUEST_MAIN_FISHERMAN"), "opening quest active")
			world.teleport("fisherman")
			wait = 0.2
		2:
			# Wait near the fisherman until he lands a fish in front of the player.
			if game.ctx.state.has_flag("STORY_PROLOGUE_FISHERMAN"):
				print("  fisherman observed after %.1fs" % elapsed)
			else:
				return false
		3:
			world.teleport("home")
			wait = 0.3
		4:
			_check(game.ctx.state.current_location == "LOC_HOME_YARD", "home zone detected: " + game.ctx.state.current_location)
			game.ctx.interactions.interact("INT_MOTHER")
			_check(game.ctx.dialogue.is_active(), "mother dialogue started")
			wait = 0.5
		5:
			var dlg: DialogueSystem = game.ctx.dialogue
			if dlg.is_active():
				if dlg.visible_choices().is_empty():
					dlg.advance()
				else:
					dlg.choose(0)
				wait = 0.1
				return false
			_check(game.ctx.quests.is_active("QUEST_MAIN_FIND_MATERIALS"), "materials quest")
		6:
			for id in ["INT_BAMBOO_CLUMP", "INT_INNER_TUBE", "INT_OLD_SHOE", "INT_SCRAP_PILE"]:
				game.ctx.interactions.interact(id)
			game.ctx.interactions.interact("INT_CRAFT_SPOT")
			_check(game.ctx.inventory.count("ITEM_IMPROVISED_ROD") == 1, "rod crafted")
			wait = 9.0  # crafting fade sequence
		7:
			game.ctx.interactions.interact("INT_BAIT_SOIL_HOME")
			world.teleport("drain")
			world.fishing.autopilot = true
			wait = 0.5
		8:
			_check(game.ctx.state.current_map == "MAP_DRAIN", "drain reached")
			_check(game.ctx.quests.is_active("QUEST_MAIN_FIRST_FISH"), "first fish quest")
			world.fishing._toggle_rod()
			_check(world.fishing.in_hand, "rod in hand")
			world.fishing._release_cast(0.8)
			_check(world.fishing.session.state == FishingSession.CASTING, "casting: " + world.fishing.session.state)
		9:
			if not _bot_fish(world.fishing.session):
				return false
			var result: String = str(world.fishing.session.result.get("outcome", ""))
			print("  first cast result: ", world.fishing.session.result)
			if result != FishingSession.LANDED:
				wait = 2.5  # retry after the result is shown
				step = 7
				return false
			wait = 2.5
		10:
			_check(game.ctx.state.get_stat("FishCaught") >= 1.0, "fish caught")
			_check(game.ctx.state.get_var("fishing.next_fish") == "FISH_GIANT_DRAIN", "giant queued")
			if world.fishing.session.state != FishingSession.IDLE:
				return false
			if not world.fishing.in_hand:
				world.fishing._toggle_rod()
			world.fishing._release_cast(0.9)
		11:
			if not _bot_fish(world.fishing.session):
				return false
			print("  giant result: ", world.fishing.session.result)
			_check(world.fishing.session.result.get("reason", "") == "ROD", "giant broke the rod")
			wait = 3.0
		12:
			_check(game.ctx.state.has_flag("GiantFishEncountered"), "giant encounter flag")
			_check(game.ctx.inventory.count("SPECIAL_ITEM_FIRST_ROD") == 1, "broken rod memento")
			_check(game.ctx.save.has_save("autosave"), "autosaved")
			_check(world.save_game("manual"), "manual save")
			world.teleport("home")
			wait = 0.5
		13:
			var dlg: DialogueSystem = game.ctx.dialogue
			_check(dlg.current_id == "DIALOGUE_MOTHER_VS_END" or game.ctx.state.has_flag("VERTICAL_SLICE_COMPLETE"), "ending dialogue")
			if dlg.is_active():
				dlg.advance()
				wait = 0.1
				return false
			_check(game.ctx.state.has_flag("VERTICAL_SLICE_COMPLETE"), "slice complete")
			wait = 1.0
		14:
			# The ending fades into Chapter II the next morning, at home, without leaving the world.
			if not game.ctx.state.has_flag("event_done:EVENT_ACT2_MORNING"):
				return false
			print("  chapter II started after %.1fs" % elapsed)
			_check(main._world == world, "stayed in the world after the ending")
			_check(game.ctx.clock.day == 2 and game.ctx.clock.hour() == 7, "next morning: day %d %dh" % [game.ctx.clock.day, game.ctx.clock.hour()])
			_check(game.ctx.state.current_location == "LOC_HOME_YARD", "woke at home")
			_check(game.ctx.dialogue.current_id == "DIALOGUE_MOTHER_DAY2", "mother's morning talk")
		15:
			if _run_dialogue(game.ctx.dialogue):
				return false
			_check(game.ctx.quests.is_active("QUEST_MAIN_GET_BACK_UP"), "MQ_008 active")
			world.teleport("shop")
			wait = 0.3
		16:
			_check(game.ctx.state.current_location == "LOC_FISHING_SHOP", "shop zone: " + game.ctx.state.current_location)
			_check(world.npc_actors["NPC_SHOP_OWNER"].visible, "shop owner is in")
			game.ctx.interactions.interact("INT_SHOP_OWNER")
			_check(game.ctx.dialogue.current_id == "DIALOGUE_SHOP_OWNER_001", "shop owner intro")
		17:
			if _run_dialogue(game.ctx.dialogue):
				return false
			_check(game.ctx.state.has_flag("SHOP_ROD_PRICE_SEEN"), "rod price seen")
			var money_before: int = game.ctx.state.money
			for i in range(1, 13):
				game.ctx.interactions.interact("INT_SCRAP_%02d" % i)
			_check(game.ctx.inventory.count("ITEM_SCRAP_BOTTLE") + game.ctx.inventory.count("ITEM_SCRAP_CAN") > 0, "scrap collected")
			_check(game.ctx.interactions.is_depleted("INT_SCRAP_01"), "scrap spot empty after picking")
			_check(not world.builder.act2.placed["INT_SCRAP_01"].visible, "picked scrap hidden")
			_check(game.ctx.state.money == money_before, "collecting is free")
			game.ctx.interactions.interact("INT_SCRAP_COLLECTOR")
		18:
			if _run_dialogue(game.ctx.dialogue):
				return false
			game.ctx.interactions.interact("INT_SCRAP_COLLECTOR")
			_check(game.ctx.dialogue.current_id == "DIALOGUE_SCRAP_SHOP", "scrap shop dialogue")
			_money_mark = game.ctx.state.money
		19:
			if _run_dialogue(game.ctx.dialogue, "phụ"):
				return false
			_check(game.ctx.state.money == _money_mark + 25, "paid for sorting: %d" % (game.ctx.state.money - _money_mark))
			wait = 12.5  # work fade
		20:
			game.ctx.interactions.interact("INT_SCRAP_COLLECTOR")
			_check(not _has_choice(game.ctx.dialogue, "phụ"), "only one job per day")
		21:
			if _run_dialogue(game.ctx.dialogue, "bán"):
				return false
			wait = 0.2
		22:
			_check(world.hud.shop_panel.visible and world.hud.shop_panel.shop_id == "SHOP_SCRAP", "scrap shop opened after the talk")
			var earned: int = game.ctx.economy.sell_all("SHOP_SCRAP")
			_check(earned > 0 and game.ctx.inventory.count("ITEM_SCRAP_BOTTLE") == 0, "sold scrap for %d" % earned)
			world.hud.shop_panel.close()
			game.ctx.state.add_money(maxi(0, 110 - game.ctx.state.money))  # skip a few days of saving up
			_check(game.ctx.quests.is_active("QUEST_MAIN_FIRST_REAL_GEAR"), "MQ_009 active once 100k saved")
			_check(game.ctx.economy.buy("SHOP_FISHING", "ITEM_ROD_BASIC") == "", "bought the rod")
			_check(game.ctx.economy.buy("SHOP_FISHING", "ITEM_BASIC_BAIT") == "", "bought worms")
			world.teleport("drain")
			wait = 0.5
		23:
			if not world.fishing.in_hand:
				world.fishing._toggle_rod()
			_check(game.ctx.inventory.equipped_item_id("rod") == "ITEM_ROD_BASIC", "new rod in hand")
			world.fishing._release_cast(0.8)
		24:
			if not _bot_fish(world.fishing.session):
				return false
			print("  drain cast with the new rod: ", world.fishing.session.result)
			wait = 2.5
			if world.fishing.session.result.get("outcome", "") != FishingSession.LANDED:
				step = 23
				return false
		25:
			if world.fishing.session.state != FishingSession.IDLE:
				return false
			game.ctx.clock.minutes = 9 * 60.0  # the market is open
			world.teleport("market")
			wait = 0.3
		26:
			_check(game.ctx.state.current_location == "LOC_MARKET", "market zone")
			game.ctx.interactions.interact("INT_FISH_VENDOR")
		27:
			if _run_dialogue(game.ctx.dialogue):
				return false
			wait = 0.2
		28:
			_check(world.hud.shop_panel.shop_id == "SHOP_FISH_VENDOR", "fish stall open")
			_check(game.ctx.economy.sell_all("SHOP_FISH_VENDOR") > 0, "sold fish")
			world.hud.shop_panel.close()
			_check(game.ctx.quests.is_active("QUEST_MAIN_THE_LAKE"), "MQ_010 active")
			world.teleport("shop")
			game.ctx.interactions.interact("INT_SHOP_OWNER")
			_check(game.ctx.dialogue.current_id == "DIALOGUE_SHOP_OWNER_LAKE", "told about the lake")
		29:
			if _run_dialogue(game.ctx.dialogue):
				return false
			world.hud.shop_panel.close()
			_check(game.ctx.state.is_map_unlocked("MAP_LAKE"), "lake unlocked")
			world.teleport("home_stop")
			wait = 0.3
		30:
			var money: int = game.ctx.state.money
			game.ctx.interactions.interact("INT_BUS_STOP_HOME")
			_check(game.ctx.state.money == money - 5, "bus fare paid")
			wait = 8.0  # bus fade
		31:
			_check(game.ctx.state.current_map == "MAP_LAKE", "arrived at the lake: " + game.ctx.state.current_map)
			world.teleport("lake")
			wait = 0.3
		32:
			if not world.fishing.in_hand:
				world.fishing._toggle_rod()
			if game.ctx.inventory.count("ITEM_BASIC_BAIT") == 0:
				game.ctx.inventory.add("ITEM_BASIC_BAIT", 5)
			world.fishing._release_cast(0.8)
		33:
			if not _bot_fish(world.fishing.session):
				return false
			print("  lake cast: ", world.fishing.session.result)
			wait = 2.5
			if world.fishing.session.result.get("outcome", "") != FishingSession.LANDED:
				step = 32
				return false
		34:
			_check(game.ctx.state.get_stat("FishCaught.MAP_LAKE") >= 1.0, "caught a lake fish")
			_check(game.ctx.quests.get_state("QUEST_MAIN_THE_LAKE") == QuestSystem.COMPLETED, "MQ_010 complete")
			_check(game.ctx.state.has_flag("ACT_II_COMPLETE"), "act II complete")
			wait = 14.0  # chapter-end card
		35:
			_check(main._world == world and not world._cutscene, "free play after chapter II")
			game.ctx.clock.minutes = 20 * 60.0
			world.teleport("home_stop")
			game.ctx.interactions.interact("INT_HOME_DOOR")  # too far away is fine: logic only
			_check(game.ctx.clock.day == 3 and game.ctx.clock.hour() == 6, "slept to the next morning")
			wait = 7.5
		36:
			_check(not game.ctx.interactions.is_depleted("INT_SCRAP_01"), "scrap respawned overnight")
			_check(world.save_game("manual"), "manual save in act II")
			main._load("manual")
			wait = 0.5
		37:
			world = main._world
			_check(world != null and game.ctx.state.has_flag("ACT_II_COMPLETE"), "loaded save keeps act II")
			_check(game.ctx.inventory.count("ITEM_ROD_BASIC") == 1, "rod survives load")
			return _done()
	step += 1
	return false


## Steps a dialogue; picks the choice containing `prefer` (else the first).
## Returns true while the dialogue is still running.
func _run_dialogue(dlg: DialogueSystem, prefer: String = "") -> bool:
	if not dlg.is_active():
		return false
	var choices := dlg.visible_choices()
	if choices.is_empty():
		dlg.advance()
	else:
		var pick := 0
		for i in choices.size():
			if prefer != "" and str(choices[i]["text"]).to_lower().contains(prefer):
				pick = i
				break
		dlg.choose(pick)
	wait = 0.05
	return true


func _has_choice(dlg: DialogueSystem, text: String) -> bool:
	for c in dlg.visible_choices():
		if str(c["text"]).to_lower().contains(text):
			return true
	return false


## Plays the current fishing session like a player; returns true when it has an outcome.
func _bot_fish(s: FishingSession) -> bool:
	match s.state:
		FishingSession.BITE:
			s.strike()
		FishingSession.HOOKED, FishingSession.FIGHTING, FishingSession.EXHAUSTED:
			s.reeling = s.tension < 45.0 and not s.player_exhausted
			s.rod_dir = -signf(s.fish.lateral) if absf(s.fish.lateral) > 0.2 else 0.0
		FishingSession.LANDED, FishingSession.LOST, FishingSession.BROKEN:
			return true
	return false


func _check(ok: bool, what: String) -> void:
	print("  %s %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		failures.append(what)


func _fail(what: String) -> void:
	_check(false, what)


func _done() -> bool:
	print("\nsmoke: %d failures" % failures.size())
	quit(1 if not failures.is_empty() else 0)
	return true
