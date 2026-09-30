extends SceneTree
## Boots the real main scene headless and drives Prologue → Act III through the actual
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
	if elapsed > 1500.0:
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
			if not world.fishing.in_hand:
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
			_money_mark = game.ctx.state.money
			game.ctx.interactions.interact("INT_BUS_STOP_HOME")
			_check(game.ctx.dialogue.current_id == "DIALOGUE_BUS_STOP", "bus stop asks where to")
		31:
			if _run_dialogue(game.ctx.dialogue, "ra hồ"):
				return false
			_check(game.ctx.state.money == _money_mark - 5, "bus fare paid")
			wait = 8.0  # bus fade
		32:
			_check(game.ctx.state.current_map == "MAP_LAKE", "arrived at the lake: " + game.ctx.state.current_map)
			_check(world.builder.act2.lake_region.visible and not world.builder.act3.stream_region.visible, "only the lake region drawn")
			world.teleport("lake")
			wait = 0.3
		33:
			if not _cast_ready():
				return false
			world.fishing._release_cast(0.8)
		34:
			if not _bot_fish(world.fishing.session):
				return false
			print("  lake cast: ", world.fishing.session.result)
			wait = 2.5
			if world.fishing.session.result.get("outcome", "") != FishingSession.LANDED:
				step = 33
				return false
		35:
			_check(game.ctx.quests.get_state("QUEST_MAIN_THE_LAKE") == QuestSystem.COMPLETED, "MQ_010 complete")
			_check(game.ctx.state.has_flag("ACT_II_COMPLETE"), "act II complete")
			wait = 19.0  # chapter II end card + chapter III title
		36:
			# --- Act III: MQ_011 the fishing friend ---
			if world._cutscene:
				return false
			_check(game.ctx.state.has_flag("event_done:EVENT_ACT3_START"), "chapter III started")
			_check(game.ctx.quests.is_active("QUEST_MAIN_NEW_FRIEND"), "MQ_011 active")
			_check(world.npc_actors.has("NPC_FISHING_FRIEND") and world.npc_actors["NPC_FISHING_FRIEND"].visible, "Cò at the lake")
			game.ctx.interactions.interact("INT_FISHING_FRIEND")
			_check(game.ctx.dialogue.current_id == "DIALOGUE_FRIEND_001", "meeting Cò")
		37:
			if _run_dialogue(game.ctx.dialogue):
				return false
			wait = 0.2
		38:
			if not _cast_ready():
				return false
			world.fishing._release_cast(0.8)
		39:
			if not _bot_fish(world.fishing.session):
				return false
			print("  fishing with Cò: ", world.fishing.session.result.get("outcome", ""))
			wait = 2.5
			if game.ctx.state.get_stat("FishWithFriend") < 2.0:
				step = 38
				return false
		40:
			game.ctx.interactions.interact("INT_FISHING_FRIEND")
			_check(game.ctx.dialogue.current_id == "DIALOGUE_FRIEND_INVITE", "Cò's invitation")
		41:
			if _run_dialogue(game.ctx.dialogue, "đi"):
				return false
			_check(game.ctx.quests.is_active("QUEST_MAIN_WRONG_POND"), "MQ_012 active")
			wait = 1.2
		42:
			_check(world.builder.barriers["BARRIER_POND_GAP"]["body"].get_child(0).disabled, "fence gap open")
			world.teleport("pond")
			wait = 1.2
		43:
			_check(game.ctx.state.current_map == "MAP_POND", "at the pond: " + game.ctx.state.current_map)
			if world.npc_actors["NPC_FISHING_FRIEND"].global_position.z < 120.0:
				_fail("Cò moved to the pond")
			if not _cast_ready():
				return false
			world.fishing._release_cast(0.6)
		44:
			if not _bot_fish(world.fishing.session):
				return false
			print("  pond cast: ", world.fishing.session.result.get("outcome", ""))
			wait = 1.0
			if world.fishing.session.result.get("outcome", "") != FishingSession.LANDED:
				wait = 2.5
				step = 43
				return false
			_check(game.ctx.dialogue.current_id == "DIALOGUE_POND_CAUGHT", "the owner shows up")
		45:
			if _run_dialogue(game.ctx.dialogue, "xin lỗi"):
				return false
			wait = 8.0  # walked out
		46:
			_check(game.ctx.state.has_flag("POND_CAUGHT"), "caught trespassing")
			_check(game.ctx.inventory.entries_in_category("FISHING_GEAR").is_empty(), "rod confiscated")
			_check(not world.fishing.in_hand, "hands empty")
			_check(game.ctx.state.current_map == "MAP_LAKE", "escorted out to the lake")
			_check(not world.builder.barriers["BARRIER_POND_GAP"]["body"].get_child(0).disabled, "gap mended")
			_check(game.ctx.quests.is_active("QUEST_MAIN_KEEP_GOING"), "MQ_013 active")
			world.teleport("home")
			wait = 0.5
		47:
			_check(game.ctx.dialogue.current_id == "DIALOGUE_MOTHER_BAN", "Mother's fishing ban")
		48:
			if _run_dialogue(game.ctx.dialogue, "dạ."):
				return false
			game.ctx.state.add_money(maxi(0, 60 - game.ctx.state.money))
			game.ctx.interactions.interact("INT_POND_GATE")  # logic only; the gate is at the lake
		49:
			if _run_dialogue(game.ctx.dialogue, "năm chục"):
				return false
			_check(game.ctx.inventory.count("ITEM_ROD_BASIC") == 1, "rod redeemed")
			world.fishing._toggle_rod()
			world.teleport("drain")
			wait = 0.3
		50:
			var banned: bool = game.ctx.state.get_var("fishing.banned_day") == str(game.ctx.clock.day)
			if banned:
				world.fishing._release_cast(0.8)
				_check(world.fishing.session.state == FishingSession.IDLE, "promised Mother: no fishing today")
			# Sleep until the ban is over.
			game.ctx.clock.minutes = 20 * 60.0
			game.ctx.interactions.interact("INT_HOME_DOOR")
			wait = 7.5
			if game.ctx.state.get_var("fishing.banned_day") == str(game.ctx.clock.day):
				step = 50
				return false
		51:
			_check(not game.ctx.interactions.is_depleted("INT_SCRAP_01"), "scrap respawned overnight")
			world.teleport("home")
			wait = 1.2
		52:
			_check(world.npc_actors["NPC_FISHING_FRIEND"].global_position.distance_to(Vector3(3.2, 0, 10.9)) < 0.5, "Cò waits at the gate")
			game.ctx.interactions.interact("INT_FISHING_FRIEND")
			_check(game.ctx.dialogue.current_id == "DIALOGUE_FRIEND_AFTER_POND", "Cò apologises")
		53:
			if _run_dialogue(game.ctx.dialogue, "lần sau"):
				return false
			_check(game.ctx.state.is_map_unlocked("MAP_STREAM"), "stream unlocked")
			world.teleport("home_stop")
			game.ctx.interactions.interact("INT_BUS_STOP_HOME")
		54:
			if _run_dialogue(game.ctx.dialogue, "suối"):
				return false
			wait = 8.0
		55:
			_check(game.ctx.state.current_map == "MAP_STREAM", "at the stream: " + game.ctx.state.current_map)
			_check(world.builder.act3.stream_region.visible and not world.builder.act2.lake_region.visible, "only the stream region drawn")
			world.teleport("stream")
			wait = 1.2
		56:
			_check(world.npc_actors["NPC_FISHING_FRIEND"].global_position.z > 350.0, "Cò at the stream")
			if not _cast_ready():
				return false
			world.fishing._release_cast(0.4)
			_check(world.fishing.session.current < 0.2, "cast into the slack water: current %.2f" % world.fishing.session.current)
		57:
			if not _bot_fish(world.fishing.session):
				if world.fishing.session.state == FishingSession.IDLE:
					step = 56  # drifted
				return false
			print("  stream cast: ", world.fishing.session.result.get("outcome", ""), " ", world.fishing.session.result.get("fish", ""))
			wait = 2.5
			if world.fishing.session.result.get("outcome", "") != FishingSession.LANDED:
				step = 56
				return false
		58:
			_check(game.ctx.quests.is_active("QUEST_MAIN_THE_RIVER"), "MQ_014 active")
			game.ctx.state.add_money(maxi(0, 420 - game.ctx.state.money))  # a few days of fishing and selling
			_check(game.ctx.economy.buy("SHOP_FISHING", "ITEM_ROD_REEL_BASIC") == "", "bought the reel rod")
			_check(game.ctx.state.is_map_unlocked("MAP_RIVER"), "river unlocked")
			world.teleport("stream_stop")
			game.ctx.interactions.interact("INT_BUS_STOP_STREAM")
		59:
			if _run_dialogue(game.ctx.dialogue, "sông"):
				return false
			wait = 8.0
		60:
			_check(game.ctx.state.current_map == "MAP_RIVER", "at the river: " + game.ctx.state.current_map)
			world.teleport("river")
			if world.fishing.in_hand:
				world.fishing._toggle_rod()
			world.fishing._toggle_rod()
			_check(game.ctx.inventory.equipped_item_id("rod") == "ITEM_ROD_REEL_BASIC", "strongest rod picked")
			wait = 0.3
		61:
			if not _cast_ready():
				return false
			world.fishing._release_cast(0.3)
		62:
			if not _bot_fish(world.fishing.session):
				return false
			print("  river cast: ", world.fishing.session.result)
			wait = 2.5
			if world.fishing.session.result.get("outcome", "") != FishingSession.LANDED:
				step = 61
				return false
		63:
			_check(game.ctx.quests.get_state("QUEST_MAIN_THE_RIVER") == QuestSystem.COMPLETED, "MQ_014 complete")
			_check(game.ctx.state.has_flag("ACT_III_COMPLETE"), "act III complete")
			wait = 14.0  # chapter-end card
		64:
			_check(main._world == world and not world._cutscene, "free play after chapter III")
			_check(world.save_game("manual"), "manual save in act III")
			main._load("manual")
			wait = 0.5
		65:
			world = main._world
			_check(world != null and game.ctx.state.has_flag("ACT_III_COMPLETE"), "loaded save keeps act III")
			_check(game.ctx.inventory.count("ITEM_ROD_REEL_BASIC") == 1, "reel rod survives load")
			_check(game.ctx.relationships.has_memory("NPC_MOTHER", "OBEYED_BAN"), "Mother remembers")
			return _done()
	step += 1
	return false


## Rod in hand and bait on the hook, ready for _release_cast.
func _cast_ready() -> bool:
	if world.fishing.session.state != FishingSession.IDLE:
		return false
	var game: Node = root.get_node("Game")
	if game.ctx.inventory.count("ITEM_BASIC_BAIT") == 0:
		game.ctx.inventory.add("ITEM_BASIC_BAIT", 10)
	if not world.fishing.in_hand:
		world.fishing._toggle_rod()
	return world.fishing.in_hand


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
		FishingSession.IDLE:
			return str(s.result.get("outcome", "")) == "DRIFTED"
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
