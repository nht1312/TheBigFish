extends TestCase
## Act III: moving water, the pond incident and its consequences, the friend, new maps.


var ctx: GameContext
var events: Array = []


func before_each() -> void:
	ctx = make_ctx()
	ctx.rng.seed = 11
	events = []
	ctx.bus.event_emitted.connect(func(n, d): events.append([n, d]))


func after_each() -> void:
	ctx.dispose()


func _cues(cue: String) -> Array:
	return events.filter(func(e): return e[0] == GameEvents.CUE and e[1].get("cue", "") == cue)


## Steps the running dialogue, taking the choice whose text contains `prefer` (else the first).
func _play(prefer: String = "") -> void:
	for _i in 64:
		if not ctx.dialogue.is_active():
			return
		var choices := ctx.dialogue.visible_choices()
		if choices.is_empty():
			ctx.dialogue.advance()
			continue
		var pick := 0
		for i in choices.size():
			if prefer != "" and str(choices[i]["text"]).contains(prefer):
				pick = i
				break
		ctx.dialogue.choose(pick)


func _land(map_id: String, fish_id: String = "FISH_TILAPIA_LAKE") -> void:
	ctx.state.enter_map(map_id)
	var rod := ctx.inventory.equipped_entry("rod")
	ctx.fishing_outcomes.apply({"outcome": "LANDED", "fish": fish_id, "weight": 0.6, "rod_durability": 50.0}, int(rod.get("uid", -1)))


func _equip_rod(item: String = "ITEM_ROD_BASIC") -> int:
	var uid := ctx.inventory.add(item)
	ctx.inventory.equip(uid)
	return uid


func _session(current: float, side: float) -> FishingSession:
	var s := FishingSession.new()
	s.rng.seed = 5
	s.configure({"strength": 82, "line_strength": 95, "hook_strength": 90, "reel_power": 32, "reel_speed": 1.8, "line_length": 45, "max_cast": 22})
	s.set_water(current, side)
	return s


# --- Moving water ---

func test_bait_drifts_out_in_current() -> void:
	var s := _session(1.0, 1.0)
	s.cast(0.8, {}, 1.0, 1.0)  # nothing will bite
	for _i in 60 * 12:
		s.tick(1.0 / 60.0)
		if s.state == FishingSession.IDLE:
			break
	assert_eq(s.state, FishingSession.IDLE, "current carried the bait away")
	assert_eq(str(s.result.get("outcome", "")), "DRIFTED")
	assert_false(s.result.get("bait_consumed", true), "drifting keeps the bait")
	var still := _session(0.0, 0.0)
	still.cast(0.8, {}, 1.0, 1.0)
	for _i in 60 * 30:
		still.tick(1.0 / 60.0)
	assert_eq(still.state, FishingSession.WAITING, "still water never drifts")
	assert_gt(_session(0.12, 1.0).drift_limit(), 30.0, "slack water behind a rock gives time")


func test_current_loads_the_line() -> void:
	var fish_def: Dictionary = App.data().get_def("fish", "FISH_GRASS_CARP") if App.data() else ctx.data.get_def("fish", "FISH_GRASS_CARP")
	var tensions: Array = []
	for current in [0.0, 0.9]:
		var s := _session(current, 1.0)
		s.cast(0.8, {"fish": fish_def, "weight": 3.0}, 5.0, 2.0)
		var total := 0.0
		var samples := 0
		for _i in 60 * 60:
			s.tick(1.0 / 60.0)
			if s.state == FishingSession.BITE:
				s.strike()
			if s.is_fighting():
				s.reeling = false
				total += s.tension
				samples += 1
				if samples > 60 * 6:
					break
		tensions.append(total / maxf(1, samples))
	assert_gt(float(tensions[1]), float(tensions[0]) + 3.0, "the same fish pulls harder in a current: %s" % str(tensions))


# --- Effects ---

func test_confiscation_and_return() -> void:
	var rod := _equip_rod()
	ctx.inventory.set_prop(rod, "durability", 42.0)
	ctx.inventory.add("FISH_CARP_COMMON", 1, {"weight": 2.0, "map": "MAP_POND"})
	ctx.inventory.add("FISH_TILAPIA_LAKE", 1, {"weight": 0.5, "map": "MAP_LAKE"})
	ctx.effects.apply({"type": "confiscate", "key": "POND", "slots": ["rod"], "categories": ["FISH"], "props_match": {"map": "MAP_POND"}})
	assert_eq(ctx.inventory.count("ITEM_ROD_BASIC"), 0, "rod taken")
	assert_eq(ctx.inventory.count("FISH_CARP_COMMON"), 0, "pond fish taken")
	assert_eq(ctx.inventory.count("FISH_TILAPIA_LAKE"), 1, "lake fish kept")
	assert_true(ctx.state.has_flag("confiscated:POND"))
	ctx.effects.apply({"type": "return_confiscated", "key": "POND", "categories": ["FISHING_GEAR"]})
	assert_eq(ctx.inventory.count("ITEM_ROD_BASIC"), 1, "rod back")
	assert_eq(ctx.inventory.count("FISH_CARP_COMMON"), 0, "the fish stay with the owner")
	var back: Dictionary = ctx.inventory.entries_in_category("FISHING_GEAR")[0]
	assert_eq(float(back["props"]["durability"]), 42.0, "same rod, same wear")
	assert_false(ctx.state.has_flag("confiscated:POND"))


func test_fishing_ban_day() -> void:
	ctx.clock.minutes = 9 * 60.0
	ctx.effects.apply({"type": "fishing_ban"})
	assert_eq(ctx.state.get_var("fishing.banned_day"), str(ctx.clock.day), "morning: today")
	ctx.clock.minutes = 19 * 60.0
	ctx.effects.apply({"type": "fishing_ban"})
	assert_eq(ctx.state.get_var("fishing.banned_day"), str(ctx.clock.day + 1), "evening: tomorrow")


func test_bus_routes_follow_unlocks() -> void:
	ctx.state.money = 100
	for m in ["MAP_LAKE", "MAP_STREAM", "MAP_RIVER"]:
		ctx.state.unlock_map(m)
	ctx.state.enter_map("MAP_STREAM")
	ctx.interactions.interact("INT_BUS_STOP_STREAM")
	var texts: Array = ctx.dialogue.visible_choices().map(func(c): return str(c["text"]))
	assert_eq(texts.size(), 4, "home, lake, river, stay: %s" % str(texts))
	assert_true(texts[0].contains("8.000đ"), "home from the stream costs its own fare")
	assert_false(texts.any(func(t): return t.begins_with("Lên suối")), "no ride to where you are")
	_play("sông")
	assert_eq(ctx.state.money, 90)
	assert_eq(_cues("travel")[0][1]["destination"], "river_stop")


# --- Story ---

func test_act3_story_chain() -> void:
	ctx.state.money = 60
	ctx.state.set_flag("ACT_II_COMPLETE")
	ctx.bus.emit_event(GameEvents.CHAPTER_STARTED, {"chapter": "ACT_III"})
	assert_true(ctx.quests.is_active("QUEST_MAIN_NEW_FRIEND"), "MQ_011")
	assert_eq(ctx.npcs.spawn_index("NPC_FISHING_FRIEND"), 3, "Cò fishes at the lake")
	_equip_rod()
	ctx.clock.minutes = 9 * 60.0
	ctx.npcs.talk("NPC_FISHING_FRIEND")
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_FRIEND_001")
	_play()
	_land("MAP_LAKE")
	_land("MAP_LAKE")
	assert_eq(ctx.state.get_stat("FishWithFriend"), 2.0, "fished together")
	assert_eq(ctx.npcs.dialogue_for("NPC_FISHING_FRIEND"), "DIALOGUE_FRIEND_INVITE")
	ctx.npcs.talk("NPC_FISHING_FRIEND")
	_play()
	assert_true(ctx.quests.is_active("QUEST_MAIN_WRONG_POND"), "MQ_012")
	assert_eq(ctx.npcs.spawn_index("NPC_FISHING_FRIEND"), 0, "Cò waits at the pond")
	assert_true(ctx.conditions.check(ctx.data.get_def("maps", "MAP_LAKE")["barriers"][0]["open_conditions"]), "the gap is open")

	# The pond: first catch brings the owner.
	_land("MAP_POND", "FISH_CARP_COMMON")
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_POND_CAUGHT")
	_play("xin lỗi")
	assert_true(ctx.state.has_flag("POND_CAUGHT"))
	assert_eq(ctx.inventory.count("ITEM_ROD_BASIC"), 0, "rod confiscated")
	assert_eq(ctx.inventory.count("FISH_CARP_COMMON"), 0, "pond fish kept by the owner")
	assert_eq(ctx.state.get_var("pond.fine"), "50")
	assert_eq(_cues("pond_escort").size(), 1, "walked out of the pond")
	assert_false(ctx.conditions.check(ctx.data.get_def("maps", "MAP_LAKE")["barriers"][0]["open_conditions"]), "gap closed again")
	assert_true(ctx.quests.is_active("QUEST_MAIN_KEEP_GOING"), "MQ_013")
	assert_eq(ctx.npcs.spawn_index("NPC_FISHING_FRIEND"), -1, "Cò is gone for now")

	# Home: Mother's ban (EVENT_FAMILY_FISHING_BAN).
	ctx.state.enter_location("LOC_HOME_YARD")
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_MOTHER_BAN")
	_play("Dạ.")
	assert_true(ctx.relationships.has_memory("NPC_MOTHER", "OBEYED_BAN"))
	assert_eq(ctx.state.get_var("fishing.banned_day"), str(ctx.clock.day))
	assert_eq(ctx.npcs.spawn_index("NPC_FISHING_FRIEND"), 1, "Cò comes by the gate")

	# Redeem the rod at the pond gate.
	ctx.interactions.interact("INT_POND_GATE")
	_play("năm chục")
	assert_eq(ctx.inventory.count("ITEM_ROD_BASIC"), 1, "rod redeemed")
	assert_eq(ctx.state.money, 10)

	# Make up with Cò, who shows the way to the stream.
	ctx.npcs.talk("NPC_FISHING_FRIEND")
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_FRIEND_AFTER_POND")
	_play("Thôi. Lần sau")
	assert_true(ctx.state.is_map_unlocked("MAP_STREAM"))
	assert_eq(ctx.npcs.spawn_index("NPC_FISHING_FRIEND"), 2, "Cò waits at the stream")
	ctx.state.enter_map("MAP_STREAM")
	ctx.inventory.equip(int(ctx.inventory.entries_in_category("FISHING_GEAR")[0]["uid"]))
	_land("MAP_STREAM", "FISH_STREAM_GOBY")
	assert_true(ctx.quests.is_active("QUEST_MAIN_THE_RIVER"), "MQ_014")

	# The river needs the reel rod.
	assert_false(ctx.state.is_map_unlocked("MAP_RIVER"))
	ctx.state.money = 400
	assert_eq(ctx.economy.buy("SHOP_FISHING", "ITEM_ROD_REEL_BASIC"), "")
	assert_true(ctx.state.is_map_unlocked("MAP_RIVER"), "buying the reel opens the river")
	_land("MAP_RIVER", "FISH_RIVER_CATFISH")
	assert_eq(ctx.quests.get_state("QUEST_MAIN_THE_RIVER"), QuestSystem.COMPLETED)
	assert_true(ctx.state.has_flag("ACT_III_COMPLETE"))
	assert_eq(ctx.state.get_var("story.chapter"), "ACT_IV")


func test_running_from_the_pond_costs_more() -> void:
	ctx.state.set_flag("ACT_II_COMPLETE")
	ctx.quests.start("QUEST_MAIN_WRONG_POND")
	_equip_rod()
	_land("MAP_POND", "FISH_CARP_COMMON")
	_play("Bỏ chạy")
	assert_eq(ctx.state.get_var("pond.fine"), "80")
	ctx.state.enter_location("LOC_HOME_YARD")
	assert_eq(ctx.dialogue.current_id, "DIALOGUE_MOTHER_BAN")
	var trust := ctx.relationships.get_relationship("NPC_MOTHER", "Trust")
	ctx.dialogue.advance()  # "Điện thoại còn nằm trong tay mẹ."
	ctx.dialogue.advance()  # the owner called
	assert_lt(ctx.relationships.get_relationship("NPC_MOTHER", "Trust"), trust, "Mother heard it from someone else")
	_play("Không nói gì")
	assert_true(ctx.relationships.has_memory("NPC_MOTHER", "IGNORED_BAN"))
	assert_eq(ctx.state.get_var("fishing.banned_day"), "", "ignoring sets no ban")
	assert_eq(ctx.npcs.dialogue_for("NPC_MOTHER"), "DIALOGUE_MOTHER_AFTER_IGNORE", "she brings it up later")
	ctx.state.money = 60
	ctx.interactions.interact("INT_POND_GATE")
	ctx.dialogue.advance()  # the owner opens the gate a crack
	var texts: Array = ctx.dialogue.visible_choices().map(func(c): return str(c["text"]))
	assert_eq(texts.size(), 1, "50k is not enough after running: %s" % str(texts))


func test_keeping_distance_from_the_friend() -> void:
	ctx.state.set_flag("ACT_II_COMPLETE")
	ctx.state.set_flag("POND_CAUGHT")
	ctx.state.set_flag("BLAMED_FRIEND")
	ctx.state.set_flag("dialogue_done:DIALOGUE_FRIEND_001")
	ctx.state.set_flag("event_done:EVENT_FAMILY_FISHING_BAN")
	ctx.clock.minutes = 10 * 60.0
	assert_eq(ctx.npcs.spawn_index("NPC_FISHING_FRIEND"), 1)
	ctx.npcs.talk("NPC_FISHING_FRIEND")
	_play("tự đi")
	assert_true(ctx.state.has_flag("FRIEND_DISTANCE"))
	assert_true(ctx.state.is_map_unlocked("MAP_STREAM"), "Cò still tells about the stream")
	assert_eq(ctx.npcs.spawn_index("NPC_FISHING_FRIEND"), 4, "back at the lake, alone")
	assert_eq(ctx.npcs.dialogue_for("NPC_FISHING_FRIEND"), "DIALOGUE_FRIEND_DISTANT")
	assert_lt(ctx.relationships.get_relationship("NPC_FISHING_FRIEND", "Friendship"), 10.0)
