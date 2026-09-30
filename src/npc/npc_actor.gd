class_name NpcActor
extends Node3D
## Visual + physical presence of an NPC. Talking goes through the Interactable id,
## so dialogue selection stays in NpcSystem/data.

var npc_id: String = ""
var look_target: Node3D
var head: Node3D
var body_root: Node3D
var _base_yaw: float = 0.0


func setup(p_npc_id: String, interactable_id: String, shirt: Color, pants: Color, seated: bool = false, hat: bool = false) -> void:
	npc_id = p_npc_id
	name = p_npc_id
	body_root = Node3D.new()
	add_child(body_root)
	var hip := 0.45 if seated else 0.9
	_part(body_root, Vector3(0, hip + 0.32, 0), Vector3(0.42, 0.62, 0.26), shirt)  # torso
	for side in [-1.0, 1.0]:
		_part(body_root, Vector3(side * 0.27, hip + 0.32, -0.05 if seated else 0.0), Vector3(0.11, 0.55, 0.12), shirt)  # arms
		if seated:
			_part(body_root, Vector3(side * 0.11, hip, -0.25), Vector3(0.14, 0.14, 0.5), pants)
			_part(body_root, Vector3(side * 0.11, hip * 0.5, -0.48), Vector3(0.13, hip, 0.14), pants)
		else:
			_part(body_root, Vector3(side * 0.11, hip * 0.5, 0), Vector3(0.15, hip, 0.16), pants)
	head = Node3D.new()
	head.position = Vector3(0, hip + 0.78, 0)
	body_root.add_child(head)
	var face := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.28
	face.mesh = sphere
	face.material_override = _mat(Color(0.80, 0.62, 0.48))
	head.add_child(face)
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.135
	hair_mesh.height = 0.2
	hair.mesh = hair_mesh
	hair.position = Vector3(0, 0.05, 0.02)
	hair.material_override = _mat(Color(0.12, 0.1, 0.1) if not seated else Color(0.75, 0.75, 0.75))
	head.add_child(hair)
	if hat:  # nón lá
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.34
		cm.height = 0.2
		cone.mesh = cm
		cone.position = Vector3(0, 0.15, 0)
		cone.material_override = _mat(Color(0.85, 0.78, 0.55))
		head.add_child(cone)
	var it := Interactable.create(interactable_id, Vector3(0.7, hip + 1.0, 0.7), Vector3(0, (hip + 1.0) * 0.5, 0))
	add_child(it)
	_base_yaw = rotation.y


func _process(delta: float) -> void:
	if look_target == null or head == null:
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


func _part(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	m.material_override = _mat(color)
	parent.add_child(m)


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	return m
