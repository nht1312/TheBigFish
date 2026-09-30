class_name RelationshipSystem
extends RefCounted
## Generic multi-dimensional relationships + NPC memory (docs/18 §28, docs/14).
## Values are 0..100 per dimension; the Mother uses Trust/Concern/Understanding/Respect/Conflict/Support.

var bus: EventBus
var values: Dictionary = {}  # npc -> { dim -> float }
var memories: Dictionary = {}  # npc -> [memory ids]


func _init(p_bus: EventBus) -> void:
	bus = p_bus


func init_from_npcs(data: DataRegistry) -> void:
	for npc in data.all("npcs"):
		values[npc["id"]] = npc.get("relationship", {}).duplicate()


func get_relationship(npc: String, dim: String) -> float:
	return float(values.get(npc, {}).get(dim, 0.0))


func set_relationship(npc: String, dim: String, value: float) -> void:
	if not values.has(npc):
		values[npc] = {}
	var old := get_relationship(npc, dim)
	values[npc][dim] = clampf(value, 0.0, 100.0)
	bus.emit_event(GameEvents.RELATIONSHIP_CHANGED, {"npc": npc, "dim": dim, "value": values[npc][dim], "delta": values[npc][dim] - old})


func modify_relationship(npc: String, dim: String, delta: float) -> void:
	set_relationship(npc, dim, get_relationship(npc, dim) + delta)


func get_memories(npc: String) -> Array:
	return memories.get(npc, [])


func has_memory(npc: String, memory: String) -> bool:
	return get_memories(npc).has(memory)


func add_memory(npc: String, memory: String) -> void:
	if has_memory(npc, memory):
		return
	if not memories.has(npc):
		memories[npc] = []
	memories[npc].append(memory)
	bus.emit_event(GameEvents.MEMORY_ADDED, {"npc": npc, "memory": memory})


func to_dict() -> Dictionary:
	return {"values": values.duplicate(true), "memories": memories.duplicate(true)}


func load_dict(d: Dictionary) -> void:
	values = d.get("values", {}).duplicate(true)
	memories = d.get("memories", {}).duplicate(true)
