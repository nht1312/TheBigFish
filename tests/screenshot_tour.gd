extends SceneTree
## Renders a few fixed views to PNG for visual review (needs a real window, not --headless).
##   godot --path . -s tests/screenshot_tour.gd -- <output_dir>

const SHOTS := [
	{"name": "01_menu", "menu": true},
	{"name": "02_start_road", "pos": Vector3(30, 1, 12), "yaw": 90.0, "pitch": -3.0},
	{"name": "03_fisherman", "pos": Vector3(-5, 1, 13.5), "yaw": 150.0, "pitch": -12.0, "wait": 9.0},
	{"name": "04_home_yard", "pos": Vector3(0, 1, 8.5), "yaw": 0.0, "pitch": -8.0, "talk": true},
	{"name": "05_bamboo", "pos": Vector3(-4.5, 1, -5.5), "yaw": 40.0, "pitch": -5.0},
	{"name": "06_drain", "pos": Vector3(57.5, 1, 45), "yaw": -60.0, "pitch": -15.0},
	{"name": "07_drain_pipe", "pos": Vector3(58, 1, 40), "yaw": -140.0, "pitch": -18.0},
	{"name": "09_mother_close", "pos": Vector3(1.1, 1, 6.7), "yaw": -18.0, "pitch": -22.0},
	{"name": "10_fisherman_close", "pos": Vector3(-6.3, 1, 18.3), "yaw": 38.0, "pitch": -14.0, "wait": 1.5},
	{"name": "11_fishing_shop", "pos": Vector3(52, 1, 12.8), "yaw": 0.0, "pitch": -4.0, "act2": true},
	{"name": "12_scrap_yard", "pos": Vector3(70, 1, 12.0), "yaw": 0.0, "pitch": -10.0},
	{"name": "13_market", "pos": Vector3(91, 1, 12.2), "yaw": 180.0, "pitch": -14.0},
	{"name": "14_scrap_spot", "pos": Vector3(15, 1, 11.0), "yaw": 0.0, "pitch": -35.0},
	{"name": "15_shop_panel", "pos": Vector3(52, 1, 9.6), "yaw": 0.0, "pitch": -5.0, "shop": "SHOP_FISHING"},
	{"name": "16_lake_pier", "pos": Vector3(437, 1, 0), "yaw": -90.0, "pitch": -4.0},
	{"name": "17_lake_wide", "pos": Vector3(424, 1, -14), "yaw": -65.0, "pitch": -4.0, "wait": 2.0},
	{"name": "18_bus_stop", "pos": Vector3(98, 1, 12.6), "yaw": 0.0, "pitch": -6.0},
	{"name": "08_fight", "pos": Vector3(57.5, 1, 45), "yaw": -90.0, "pitch": -20.0, "fight": true},
]

var main: Node
var out_dir := "user://screenshots"
var index := 0
var timer := 1.0
var prepared := false
var _frames := 0
var _frame_time := 0.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(delta: float) -> bool:
	timer -= delta
	if prepared and timer < 2.0:  # steady-state window just before the capture
		_frames += 1
		_frame_time += delta
	if timer > 0.0:
		return false
	if index >= SHOTS.size():
		quit()
		return true
	var shot: Dictionary = SHOTS[index]
	if not prepared:
		_prepare(shot)
		prepared = true
		timer = float(shot.get("wait", 1.2)) + 2.0
		_frames = 0
		_frame_time = 0.0
		return false
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(shot["name"] + ".png"))
	print("saved %s  avg fps %.0f" % [shot["name"], _frames / maxf(_frame_time, 0.001)])
	index += 1
	prepared = false
	timer = 0.2
	return false


func _prepare(shot: Dictionary) -> void:
	if shot.get("menu", false):
		return
	var game: Node = root.get_node("Game")
	if main._world == null:
		main._menu.new_game_requested.emit()
		game.ctx.clock.set_time(9, 0)
	var world: WorldScene = main._world
	world.player.global_position = shot["pos"]
	world.player.set_yaw_degrees(shot["yaw"])
	world.player.head.rotation_degrees.x = shot.get("pitch", 0.0)
	if shot.get("act2", false):
		while game.ctx.dialogue.is_active():
			game.ctx.dialogue.end()
		game.ctx.state.set_flag("VERTICAL_SLICE_COMPLETE")
		game.ctx.state.set_flag("event_done:EVENT_ACT2_MORNING")  # no chapter transition in the tour
		world._refresh_placed()
	world.hud.shop_panel.close()
	if shot.has("shop"):
		game.ctx.state.money = 150
		world.hud.shop_panel.open(shot["shop"])
	if shot.get("talk", false):
		game.ctx.state.set_flag("STORY_PROLOGUE_FISHERMAN")
		game.ctx.interactions.interact("INT_MOTHER")
	if shot.get("fight", false):
		var dlg: DialogueSystem = game.ctx.dialogue
		while dlg.is_active():
			dlg.end()
		var uid: int = game.ctx.inventory.add("ITEM_IMPROVISED_ROD")
		game.ctx.inventory.add("ITEM_BASIC_BAIT", 3)
		world.fishing._toggle_rod()
		world.fishing.autopilot = true
		world.fishing._release_cast(0.8)
		var s: FishingSession = world.fishing.session
		for i in 60 * 30:
			s.tick(1.0 / 60.0)
			if s.state == FishingSession.BITE:
				s.strike()
			if s.is_fighting() and s.fish.action == "RUN" and s.tension > 30:
				break
		s.reeling = true
