class_name NpcActor
extends Node3D
## Visual + physical presence of an NPC. Talking goes through the Interactable id,
## so dialogue selection stays in NpcSystem/data. The body is a CharacterRig built
## from the NPC's "appearance" data (or a model from assets/characters/).

var npc_id: String = ""
var look_target: Node3D
var rig: CharacterRig
var head: Node3D
var seat_height: float = -1.0  # >= 0: sitting on a seat of this height


func setup(p_npc_id: String, interactable_id: String, appearance: Dictionary, p_seat_height: float = -1.0) -> void:
	npc_id = p_npc_id
	name = p_npc_id
	seat_height = p_seat_height
	rig = CharacterRig.new()
	add_child(rig)
	rig.build(p_npc_id, appearance)
	head = rig.head
	if seat_height >= 0.0:
		rig.position.y = rig.seated_offset(seat_height)
	var body_height := rig.height if seat_height < 0.0 else seat_height + rig.height * 0.47
	var it := Interactable.create(interactable_id, Vector3(0.7, body_height, 0.8), Vector3(0, body_height * 0.5, 0))
	add_child(it)


## Stand up (or sit) and blend into another pose.
func set_pose(pose: String, p_seat_height: float = -1.0) -> void:
	seat_height = p_seat_height
	rig.position.y = rig.seated_offset(seat_height) if seat_height >= 0.0 else 0.0
	rig.set_pose(pose)


func _process(delta: float) -> void:
	if look_target == null or head == null or rig.model_override:
		return
	var to_target := look_target.global_position - global_position
	var desired := 0.0
	if to_target.length() < 7.0:
		var local := global_transform.basis.inverse() * to_target
		desired = clampf(atan2(-local.x, -local.z), -1.1, 1.1)
	head.rotation.y = lerp_angle(head.rotation.y, desired, 1.0 - exp(-4.0 * delta))


## Turn the whole body to face a point (used when a conversation starts).
func face(point: Vector3) -> void:
	var dir := point - global_position
	dir.y = 0
	if dir.length() > 0.1:
		look_at(global_position + dir, Vector3.UP)


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	return m
