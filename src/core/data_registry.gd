class_name DataRegistry
extends RefCounted
## Loads static game data (docs/18 §41–44). Every definition has a unique "id".
##
## Layout: data/<collection>/*.json, each file holding an array of definitions.

const COLLECTIONS: Array[String] = [
	"items", "recipes", "fish", "quests", "dialogues", "events", "npcs", "maps", "interactables", "shops",
]

var tables: Dictionary = {}  # collection -> { id -> definition }
var errors: Array[String] = []


func load_from(root: String = "res://data") -> DataRegistry:
	for collection in COLLECTIONS:
		tables[collection] = {}
		var dir_path := root.path_join(collection)
		if not DirAccess.dir_exists_absolute(dir_path):
			continue
		var files := DirAccess.get_files_at(dir_path)
		files.sort()
		for file_name in files:
			if file_name.get_extension() == "json":
				_load_file(collection, dir_path.path_join(file_name))
	for message in errors:
		push_error(message)
	return self


func add_definitions(collection: String, defs: Array) -> void:
	if not tables.has(collection):
		tables[collection] = {}
	for def in defs:
		_add(collection, def, "<code>")


func get_def(collection: String, id: String) -> Dictionary:
	return tables.get(collection, {}).get(id, {})


func has_def(collection: String, id: String) -> bool:
	return tables.get(collection, {}).has(id)


func all(collection: String) -> Array:
	return tables.get(collection, {}).values()


## Items include fish: a landed fish is carried as an inventory item (docs/09 §12).
func get_item(id: String) -> Dictionary:
	var item := get_def("items", id)
	if not item.is_empty():
		return item
	var fish := get_def("fish", id)
	if fish.is_empty():
		return {}
	return {
		"id": id,
		"name": fish.get("name", id),
		"category": "FISH",
		"stackable": false,
		"description": fish.get("description", ""),
	}


func display_name(collection: String, id: String) -> String:
	return str(get_def(collection, id).get("name", id))


func _load_file(collection: String, path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if not parsed is Array:
		errors.append("DataRegistry: %s must contain a JSON array" % path)
		return
	for def in parsed:
		_add(collection, def, path)


func _add(collection: String, def, source: String) -> void:
	if not def is Dictionary or not def.has("id"):
		errors.append("DataRegistry: entry without id in %s" % source)
		return
	var id := str(def["id"])
	if tables[collection].has(id):
		errors.append("DataRegistry: duplicate id %s in %s" % [id, source])
		return
	tables[collection][id] = def
