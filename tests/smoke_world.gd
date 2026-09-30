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


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(delta: float) -> bool:
	elapsed += delta
	if elapsed > 240.0:
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
			_check(main._world == world, "still in world before ending card")
			wait = 17.0  # ending sequence returns to menu
		15:
			_check(main._menu != null, "back at the title screen")
			main._load("autosave")
			wait = 0.5
		16:
			world = main._world
			_check(world != null and game.ctx.state.has_flag("VERTICAL_SLICE_COMPLETE"), "loaded save keeps completion")
			return _done()
	step += 1
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
