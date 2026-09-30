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
	{"name": "08_fight", "pos": Vector3(57.5, 1, 45), "yaw": -90.0, "pitch": -20.0, "fight": true},
]

var main: Node
var out_dir := "user://screenshots"
var index := 0
var timer := 1.0
var prepared := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(delta: float) -> bool:
	timer -= delta
	if timer > 0.0:
		return false
	if index >= SHOTS.size():
		quit()
		return true
	var shot: Dictionary = SHOTS[index]
	if not prepared:
		_prepare(shot)
		prepared = true
		timer = float(shot.get("wait", 1.2))
		return false
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(shot["name"] + ".png"))
	print("saved ", shot["name"])
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
