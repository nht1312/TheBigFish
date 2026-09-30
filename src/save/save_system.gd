class_name SaveSystem
extends RefCounted
## Versioned JSON saves (docs/18 §36–40, CLAUDE.md §21).
## Slots: "autosave", "manual". Old saves are migrated step by step up to SAVE_VERSION.

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"

var ctx: GameContext
var save_dir: String = SAVE_DIR


func _init(context: GameContext) -> void:
	ctx = context


## player: { position: [x,y,z], yaw: float } supplied by the world.
func build_save(player: Dictionary) -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"player": player.duplicate(true),
		"state": ctx.state.to_dict(),
		"inventory": ctx.inventory.to_dict(),
		"quests": ctx.quests.to_dict(),
		"relationships": ctx.relationships.to_dict(),
		"events": ctx.story_events.to_dict(),
		"clock": ctx.clock.to_dict(),
	}


## Restores systems from a save; returns the player block for the world to apply.
func apply_save(save: Dictionary) -> Dictionary:
	save = migrate(save)
	ctx.state.load_dict(save.get("state", {}))
	ctx.inventory.load_dict(save.get("inventory", {}))
	ctx.quests.load_dict(save.get("quests", {}))
	ctx.relationships.load_dict(save.get("relationships", {}))
	ctx.story_events.load_dict(save.get("events", {}))
	ctx.clock.load_dict(save.get("clock", {}))
	return save.get("player", {})


static func migrate(save: Dictionary) -> Dictionary:
	var version := int(save.get("save_version", 0))
	if version < 1:
		# v0 → v1: pre-release saves had no version field; nothing else changed.
		save["save_version"] = 1
		version = 1
	return save


func slot_path(slot: String) -> String:
	return save_dir.path_join(slot + ".json")


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func write(slot: String, player: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(save_dir)
	var tmp_path := slot_path(slot) + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(build_save(player), "\t"))
	file.close()
	# Write-then-rename so a crash never leaves a half-written save.
	return DirAccess.rename_absolute(tmp_path, slot_path(slot))


## Returns {} if the file is missing or corrupted.
func read(slot: String) -> Dictionary:
	if not has_save(slot):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	if not parsed is Dictionary or not parsed.has("state"):
		push_warning("SaveSystem: save '%s' is corrupted" % slot)
		return {}
	return parsed
