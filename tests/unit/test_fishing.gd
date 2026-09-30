extends TestCase
## Fishing session, fish AI and outcome handling (docs/07, docs/08).


var data: DataRegistry
var rod: Dictionary


func before_each() -> void:
	data = DataRegistry.new().load_from("res://data")
	rod = data.get_def("items", "ITEM_IMPROVISED_ROD")


func _session(seed: int) -> FishingSession:
	var s := FishingSession.new()
	s.rng.seed = seed
	s.configure(rod["rod"])
	s.rod_durability = float(rod["durability"])
	return s


func _pick(fish_id: String) -> Dictionary:
	var def := data.get_def("fish", fish_id)
	return {"fish": def, "weight": float(def["weight_kg"][1])}


## Runs until a bite, then strikes immediately.
func _hook(s: FishingSession, fish_id: String) -> void:
	s.cast(0.8, _pick(fish_id), 1.0, 1.0)
	for i in 60 * 60:
		s.tick(1.0 / 60.0)
		if s.state == FishingSession.BITE:
			s.strike()
			s.tick(1.0 / 60.0)
			return


## A reasonable player: keep tension in the working range, counter the fish's direction.
func _fight_like_a_player(s: FishingSession, max_seconds: float) -> void:
	var dt := 1.0 / 60.0
	for i in int(max_seconds * 60):
		if not s.is_fighting():
			return
		s.reeling = s.tension < 45.0 and not s.player_exhausted
		s.rod_dir = -signf(s.fish.lateral) if absf(s.fish.lateral) > 0.2 else 0.0
		s.tick(dt)


func test_small_fish_can_be_landed() -> void:
	var landed := 0
	for seed in 10:
		var s := _session(seed)
		_hook(s, "FISH_SMALL_COMMON")
		if not s.is_fighting():
			continue
		_fight_like_a_player(s, 90.0)
		if s.state == FishingSession.LANDED:
			landed += 1
	assert_gt(landed, 6, "a careful player should land most small fish (landed %d/10)" % landed)


func test_fight_takes_time() -> void:
	var s := _session(3)
	_hook(s, "FISH_SMALL_COMMON")
	var t := 0.0
	while s.is_fighting() and t < 90.0:
		s.reeling = s.tension < 45.0 and not s.player_exhausted
		s.tick(1.0 / 60.0)
		t += 1.0 / 60.0
	assert_gt(t, 4.0, "not an instant catch")


func test_giant_fish_always_breaks_improvised_rod() -> void:
	for seed in 8:
		for style in ["careful", "idle", "no_drag", "max_drag"]:
			var s := _session(seed)
			_hook(s, "FISH_GIANT_DRAIN")
			assert_true(s.is_fighting(), "giant always hooks")
			var t := 0.0
			while s.is_fighting() and t < 180.0:
				match style:
					"careful":
						s.reeling = s.tension < 45.0 and not s.player_exhausted
						s.rod_dir = -signf(s.fish.lateral)
					"no_drag":
						s.drag = 0.0
					"max_drag":
						s.drag = 1.0
						s.reeling = true
				s.tick(1.0 / 60.0)
				t += 1.0 / 60.0
			assert_eq(s.state, FishingSession.BROKEN, "seed %d style %s" % [seed, style])
			assert_eq(s.result["reason"], "ROD", "seed %d style %s" % [seed, style])
			assert_gt(t, 6.0, "the fight should last a while (%s %.1fs)" % [style, t])
			assert_lt(t, 120.0, "but not forever (%s)" % style)


func test_missed_bite_steals_bait() -> void:
	var s := _session(5)
	s.cast(0.8, _pick("FISH_SMALL_COMMON"), 1.0, 1.0)
	for i in 60 * 120:
		s.tick(1.0 / 60.0)
		if s.is_finished():
			break
	assert_eq(s.state, FishingSession.LOST)
	assert_eq(s.result["reason"], "BAIT_STOLEN")
	assert_true(s.result["bait_consumed"])


func test_striking_a_nibble_spooks_the_fish() -> void:
	var s := _session(1)
	var cautious := data.get_def("fish", "FISH_SMALL_001").duplicate()
	cautious["caution"] = 1.0  # always nibbles first
	s.cast(0.8, {"fish": cautious, "weight": 0.3}, 1.0, 1.0)
	var cues: Array = []  # lambdas capture locals by value, so collect into an array
	s.cue.connect(func(n, _d): cues.append(n))
	for i in 60 * 60:
		s.tick(1.0 / 60.0)
		if s._nibble_left > 0.0:
			s.strike()
			break
	assert_true(cues.has("spooked"), str(cues))
	assert_eq(s.state, FishingSession.WAITING, "keeps waiting; a fish may come back")


func test_no_fish_means_waiting() -> void:
	var s := _session(1)
	s.cast(0.5, {}, 1.0, 1.0)
	for i in 60 * 30:
		s.tick(1.0 / 60.0)
	assert_eq(s.state, FishingSession.WAITING)
	s.cancel()
	assert_eq(s.state, FishingSession.IDLE)
	assert_false(s.result["bait_consumed"])


func test_overpowering_small_fish_breaks_line_or_hook() -> void:
	var s := _session(2)
	s.configure({"line_strength": 30, "hook_strength": 200, "strength": 200})
	var sure_hook := data.get_def("fish", "FISH_SMALL_001").duplicate()
	sure_hook["hook_bonus"] = 1.0
	s.cast(0.8, {"fish": sure_hook, "weight": 0.5}, 1.0, 1.0)
	while s.state != FishingSession.BITE:
		s.tick(1.0 / 60.0)
	s.strike()
	s.tick(1.0 / 60.0)
	s.drag = 1.0
	for i in 60 * 60:
		if not s.is_fighting():
			break
		s.reeling = true
		s.player_stamina = 100.0
		s.tick(1.0 / 60.0)
	assert_eq(s.state, FishingSession.BROKEN)
	assert_eq(s.result["reason"], "LINE")


func test_slack_line_loses_fish() -> void:
	var s := _session(4)
	_hook(s, "FISH_SMALL_COMMON")
	s.fish.force_action("REST")
	s.fish.strength = 0.5  # barely pulls: line goes slack
	for i in 60 * 30:
		if not s.is_fighting():
			break
		s.tick(1.0 / 60.0)
	assert_eq(s.result.get("reason", ""), "SLACK")


func test_fish_selector_respects_forced_and_spot() -> void:
	var rng := RandomNumberGenerator.new()
	var spot: Dictionary = data.get_def("maps", "MAP_DRAIN")["fishing_spots"][0]
	var pick := FishSelector.pick(spot, data, "ITEM_BASIC_BAIT", "", rng)
	assert_true(pick["fish"]["id"] in ["FISH_SMALL_COMMON", "FISH_SMALL_001"])
	pick = FishSelector.pick(spot, data, "ITEM_BASIC_BAIT", "FISH_GIANT_DRAIN", rng)
	assert_eq(pick["fish"]["id"], "FISH_GIANT_DRAIN")
	assert_true(FishSelector.pick({"fish": []}, data, "", "", rng).is_empty())


func test_fish_personalities_differ() -> void:
	# Same weight class, different archetypes → different share of time spent resting.
	var rest := {}
	for id in ["FISH_SMALL_COMMON", "FISH_GIANT_DRAIN"]:
		var def := data.get_def("fish", id)
		var f := FishFighter.new(def, float(def["weight_kg"][0]), RandomNumberGenerator.new())
		var rest_time := 0.0
		for i in 60 * 60:
			f.tick(1.0 / 60.0, 50.0, false)
			if f.action == "REST":
				rest_time += 1.0 / 60.0
		rest[id] = rest_time
	assert_gt(rest["FISH_SMALL_COMMON"], rest["FISH_GIANT_DRAIN"] + 5.0, str(rest))


func test_skill_levels() -> void:
	assert_eq(FishingSkill.level_name(0), "BEGINNER")
	assert_eq(FishingSkill.level_name(10), "NOVICE")
	assert_eq(FishingSkill.level_name(1000), "MASTER")


func test_outcome_landed_adds_fish_and_records() -> void:
	var ctx := make_ctx()
	ctx.state.current_map = "MAP_DRAIN"
	var rod_uid := ctx.inventory.add("ITEM_IMPROVISED_ROD")
	ctx.inventory.add("ITEM_BASIC_BAIT", 2)
	ctx.inventory.cycle_bait()
	ctx.fishing_outcomes.apply({"outcome": "LANDED", "fish": "FISH_SMALL_COMMON", "weight": 0.3, "bait_consumed": true, "rod_durability": 18.5}, rod_uid)
	assert_eq(ctx.inventory.count("FISH_SMALL_COMMON"), 1)
	assert_eq(ctx.inventory.count("ITEM_BASIC_BAIT"), 1)
	assert_eq(ctx.inventory.get_entry(rod_uid)["props"]["durability"], 18.5)
	assert_eq(ctx.state.get_stat("FishCaught"), 1.0)
	assert_eq(ctx.state.records["first_catch"]["fish"], "FISH_SMALL_COMMON")
	assert_eq(ctx.state.get_var("fishing.next_fish"), "FISH_GIANT_DRAIN", "giant fish event queued")
	ctx.dispose()


func test_outcome_rod_break_triggers_story() -> void:
	var ctx := make_ctx()
	var rod_uid := ctx.inventory.add("ITEM_IMPROVISED_ROD")
	ctx.state.set_var("fishing.next_fish", "FISH_GIANT_DRAIN")
	ctx.fishing_outcomes.apply({"outcome": "BROKEN", "reason": "ROD", "fish": "FISH_GIANT_DRAIN", "bait_consumed": true, "rod_durability": 0.0}, rod_uid)
	assert_eq(ctx.inventory.count("ITEM_IMPROVISED_ROD"), 0, "rod destroyed")
	assert_eq(ctx.inventory.count("SPECIAL_ITEM_FIRST_ROD"), 1, "kept as a memory")
	assert_true(ctx.state.has_flag("GiantFishEncountered"))
	assert_eq(ctx.state.get_var("fishing.next_fish"), "")
	assert_gt(ctx.state.get_stat("FishingPassion"), 10.0)
	ctx.dispose()
