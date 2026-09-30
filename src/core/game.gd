extends Node
## Autoload "Game": owns the current GameContext and advances world time.
## Scenes reach systems through Game.ctx (e.g. Game.ctx.inventory).

signal context_changed

var data: DataRegistry
var config: Dictionary
var ctx: GameContext
var running: bool = false  # false on the title screen
var loaded_player: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	data = DataRegistry.new().load_from("res://data")
	config = GameContext.load_config("res://config")


func _process(delta: float) -> void:
	if running and ctx:
		ctx.clock.advance(delta)


func new_game() -> void:
	_replace_context()
	ctx.new_game()
	running = true
	context_changed.emit()


## Loads a slot. On success the saved player block is in `loaded_player`.
## Returns false (and keeps the current game) if the save is missing or corrupted.
func load_game(slot: String) -> bool:
	var save := SaveSystem.new(null).read(slot)
	if save.is_empty():
		return false
	_replace_context()
	loaded_player = ctx.save.apply_save(save)
	running = true
	context_changed.emit()
	return true


func has_save(slot: String) -> bool:
	return SaveSystem.new(null).has_save(slot)


func stop() -> void:
	running = false


func _exit_tree() -> void:
	if ctx:
		ctx.dispose()
		ctx = null


func _replace_context() -> void:
	if ctx:
		ctx.dispose()
	ctx = GameContext.new(data, config)
