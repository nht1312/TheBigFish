class_name GameContext
extends RefCounted
## Composition root: builds every gameplay system and wires them to one EventBus.
## Holds no gameplay logic itself. Tests create their own context; the game uses App.ctx().

var bus: EventBus
var data: DataRegistry
var config: Dictionary
var state: GameState
var clock: GameClock
var inventory: Inventory
var relationships: RelationshipSystem
var conditions: ConditionEvaluator
var effects: EffectExecutor
var crafting: CraftingSystem
var quests: QuestSystem
var dialogue: DialogueSystem
var npcs: NpcSystem
var story_events: StoryEventSystem
var interactions: InteractionSystem
var fishing_outcomes: FishingOutcomes
var save: SaveSystem


func _init(p_data: DataRegistry, p_config: Dictionary = {}) -> void:
	data = p_data
	config = p_config
	bus = EventBus.new()
	state = GameState.new(bus)
	clock = GameClock.new(bus)
	inventory = Inventory.new(data, bus)
	relationships = RelationshipSystem.new(bus)
	conditions = ConditionEvaluator.new(self)
	effects = EffectExecutor.new(self)
	crafting = CraftingSystem.new(self)
	quests = QuestSystem.new(self)
	dialogue = DialogueSystem.new(self)
	npcs = NpcSystem.new(self)
	story_events = StoryEventSystem.new(self)
	interactions = InteractionSystem.new(self)
	fishing_outcomes = FishingOutcomes.new(self)
	save = SaveSystem.new(self)
	relationships.init_from_npcs(data)


## Reads config/<name>.json into { name: Dictionary }.
static func load_config(root: String = "res://config") -> Dictionary:
	var result := {}
	for file_name in DirAccess.get_files_at(root):
		if file_name.get_extension() == "json":
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(root.path_join(file_name)))
			if parsed is Dictionary:
				result[file_name.get_basename()] = parsed
			else:
				push_error("GameContext: config %s is not a JSON object" % file_name)
	return result


## Initial state of a new game (config/new_game.json, docs/03 §5).
func new_game() -> void:
	var cfg: Dictionary = config.get("new_game", {})
	state.money = int(cfg.get("money", 0))
	for map_id in cfg.get("unlocked_maps", []):
		state.unlock_map(str(map_id))
	var start_time: Array = cfg.get("start_time", [7, 0])
	clock.set_time(int(start_time[0]), int(start_time[1]))
	clock.set_weather(str(cfg.get("weather", "SUNNY")))
	clock.time_scale = float(cfg.get("time_scale", 1.0))
	for quest_id in cfg.get("start_quests", []):
		quests.start(str(quest_id))


## Breaks reference cycles so the context can be freed.
func dispose() -> void:
	for connection in bus.event_emitted.get_connections():
		bus.event_emitted.disconnect(connection["callable"])
	conditions = null
	effects = null
	crafting = null
	quests = null
	dialogue = null
	npcs = null
	story_events = null
	interactions = null
	fishing_outcomes = null
	save = null
