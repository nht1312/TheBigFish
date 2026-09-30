extends Node
## Entry scene: switches between the title screen and the world.

var _menu: MainMenu
var _world: WorldScene


func _ready() -> void:
	InputSetup.setup()
	_show_menu()


func _show_menu() -> void:
	_clear()
	App.game().stop()
	_menu = MainMenu.new()
	_menu.new_game_requested.connect(func():
		App.game().new_game()
		_start_world({}))
	_menu.continue_requested.connect(_load)
	_menu.quit_requested.connect(func(): get_tree().quit())
	add_child(_menu)


func _load(slot: String) -> void:
	if not App.game().load_game(slot):
		if is_instance_valid(_world):
			_world.hud.show_message("Chưa có bản lưu nào dùng được.", "hint")
		return
	_start_world(App.game().loaded_player)


func _start_world(player_save: Dictionary) -> void:
	_clear()
	_world = WorldScene.new()
	_world.name = "World"
	add_child(_world)
	_world.start(player_save)
	_world.exit_to_menu.connect(_show_menu, CONNECT_DEFERRED)
	_world.load_requested.connect(_load, CONNECT_DEFERRED)


func _clear() -> void:
	get_tree().paused = false
	for node in [_menu, _world]:
		if is_instance_valid(node):
			node.queue_free()
	_menu = null
	_world = null
