class_name CharacterRig
extends Node3D
## A jointed human figure built from primitives, posed and animated procedurally.
## Proportions and clothing come from the NPC's "appearance" data. If
## res://assets/characters/<npc_id>.glb exists, that model is used instead, so real
## art can replace this without code changes.
##
## Local -Z is forward. Joints are pivots; a limb hangs along -Y from its pivot, so
## rotation.x > 0 swings it forward.

const MODEL_DIR := "res://assets/characters"

## Poses: joint -> Euler degrees. Missing joints stay at zero.
## Shoulders: z > 0 on the left and z < 0 on the right bring the arm in toward the body.
const POSES := {
	"stand": {
		"l_shoulder": Vector3(4, 0, 6), "r_shoulder": Vector3(4, 0, -6),
		"l_elbow": Vector3(10, 0, 0), "r_elbow": Vector3(10, 0, 0),
	},
	"sit_fishing": {
		"l_hip": Vector3(88, 0, 4), "r_hip": Vector3(88, 0, -4),
		"l_knee": Vector3(-95, 0, 0), "r_knee": Vector3(-95, 0, 0),
		"spine": Vector3(14, 0, 0),
		"l_shoulder": Vector3(52, 0, 10), "r_shoulder": Vector3(58, 0, -6),
		"l_elbow": Vector3(38, 0, 0), "r_elbow": Vector3(30, 0, 0),
	},
	"sit_reel": {
		"l_hip": Vector3(88, 0, 4), "r_hip": Vector3(88, 0, -4),
		"l_knee": Vector3(-95, 0, 0), "r_knee": Vector3(-95, 0, 0),
		"spine": Vector3(4, 0, 0),
		"l_shoulder": Vector3(95, 0, 12), "r_shoulder": Vector3(110, 0, -8),
		"l_elbow": Vector3(20, 0, 0), "r_elbow": Vector3(35, 0, 0),
	},
	"sit_chores": {
		"l_hip": Vector3(80, 0, 10), "r_hip": Vector3(80, 0, -10),
		"l_knee": Vector3(-100, 0, 0), "r_knee": Vector3(-100, 0, 0),
		"spine": Vector3(30, 0, 0), "neck": Vector3(12, 0, 0),
		"l_shoulder": Vector3(40, 0, 14), "r_shoulder": Vector3(40, 0, -14),
		"l_elbow": Vector3(28, 0, 0), "r_elbow": Vector3(28, 0, 0),
	},
}

var joints: Dictionary = {}  # name -> Node3D pivot
var head: Node3D
var height: float = 1.6
var hip_height: float = 0.85
var pose_name: String = "stand"
var model_override: Node3D

var _from: Dictionary = {}
var _target: Dictionary = {}
var _blend: float = 1.0
var _time: float = 0.0
var _stoop: float = 0.0
var _mats: Dictionary = {}


func build(npc_id: String, appearance: Dictionary) -> void:
	name = "Rig"
	_time = randf() * 10.0
	var glb := MODEL_DIR.path_join(npc_id.to_lower() + ".glb")
	if ResourceLoader.exists(glb):
		model_override = (load(glb) as PackedScene).instantiate()
		add_child(model_override)
		head = model_override
		return
	height = float(appearance.get("height", 1.6))
	_stoop = float(appearance.get("stoop", 0.0))
	var h := height
	hip_height = 0.53 * h
	var skin := _skin(_color(appearance, "skin", Color(0.78, 0.6, 0.47)))
	var shirt := _cloth(_color(appearance, "shirt", Color(0.5, 0.5, 0.5)))
	var pants := _cloth(_color(appearance, "pants", Color(0.15, 0.15, 0.18)))
	var sandal := _cloth(_color(appearance, "sandals", Color(0.3, 0.2, 0.15)))
	var hair := _cloth(_color(appearance, "hair_color", Color(0.08, 0.07, 0.06)), 0.55)
	var sleeves := str(appearance.get("sleeves", "long"))
	var slim: float = {"slim": 0.9, "stocky": 1.12}.get(str(appearance.get("build", "")), 1.0)

	var hips := _joint("hips", self, Vector3(0, hip_height, 0))
	_limb(hips, 0.06 * h, 0.13 * h * slim, pants, Vector3(0, 0.02 * h, 0), 0.08 * h)  # pelvis
	var spine := _joint("spine", hips, Vector3(0, 0.04 * h, 0))
	_capsule(spine, 0.115 * h * slim, 0.3 * h, shirt, Vector3(0, 0.14 * h, 0), Vector3(1.0, 1.0, 0.72))  # loose shirt torso
	var neck := _joint("neck", spine, Vector3(0, 0.29 * h, 0))
	_capsule(neck, 0.036 * h, 0.07 * h, skin, Vector3(0, 0.02 * h, 0))
	head = _joint("head", neck, Vector3(0, 0.045 * h, 0))
	_head(head, h, skin, hair, appearance)
	for side in [-1.0, 1.0]:
		var s := "l_" if side < 0 else "r_"
		var shoulder := _joint(s + "shoulder", spine, Vector3(side * 0.13 * h * slim, 0.265 * h, 0))
		var upper_mat := shirt
		var lower_mat := shirt if sleeves == "long" else skin
		_limb(shoulder, 0.17 * h, 0.034 * h, upper_mat)
		var elbow := _joint(s + "elbow", shoulder, Vector3(0, -0.17 * h, 0))
		_limb(elbow, 0.15 * h, 0.029 * h, lower_mat)
		if sleeves == "rolled":
			_limb(elbow, 0.05 * h, 0.034 * h, shirt)  # rolled cuff
		var hand := _joint(s + "hand", elbow, Vector3(0, -0.15 * h, 0))
		_capsule(hand, 0.025 * h, 0.09 * h, skin, Vector3(0, -0.035 * h, 0), Vector3(1.0, 1.0, 0.6))
		var hip := _joint(s + "hip", hips, Vector3(side * 0.06 * h * slim, -0.02 * h, 0))
		_limb(hip, 0.25 * h, 0.05 * h * slim, pants)
		var knee := _joint(s + "knee", hip, Vector3(0, -0.25 * h, 0))
		_limb(knee, 0.24 * h, 0.04 * h * slim, pants)
		var ankle := _joint(s + "ankle", knee, Vector3(0, -0.245 * h, 0))
		_capsule(ankle, 0.022 * h, 0.05 * h, skin, Vector3(0, 0.01 * h, 0))
		var foot := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.06 * h, 0.012 * h, 0.15 * h)
		foot.mesh = fm
		foot.material_override = sandal
		foot.position = Vector3(0, -0.012 * h, -0.035 * h)
		ankle.add_child(foot)
	set_pose(str(appearance.get("pose", "stand")), true)


func set_pose(p_name: String, instant: bool = false) -> void:
	if not POSES.has(p_name):
		return
	pose_name = p_name
	_from = {}
	for j in joints:
		_from[j] = joints[j].rotation_degrees
	_target = POSES[p_name]
	_blend = 1.0 if instant else 0.0
	if instant:
		_apply(1.0)


## Height of the hips above the feet for the current pose (for placing seated figures).
func seated_offset(seat_height: float) -> float:
	return seat_height - hip_height + 0.02 * height


func _process(delta: float) -> void:
	if joints.is_empty():
		return
	_time += delta
	if _blend < 1.0:
		_blend = minf(1.0, _blend + delta * 2.5)
		_apply(smoothstep(0.0, 1.0, _blend))
	# Life: breathing, small weight shifts, busy hands when doing chores.
	var breath := sin(_time * 1.7) * 1.2
	joints["spine"].rotation_degrees.x = _pose_value("spine").x + _stoop + breath
	if pose_name == "stand":
		joints["hips"].rotation_degrees.z = sin(_time * 0.45) * 1.5
	if pose_name == "sit_chores":
		joints["l_elbow"].rotation_degrees.x = _pose_value("l_elbow").x + sin(_time * 3.1) * 12.0
		joints["r_elbow"].rotation_degrees.x = _pose_value("r_elbow").x + sin(_time * 2.3 + 1.0) * 10.0
		joints["r_shoulder"].rotation_degrees.y = sin(_time * 1.3) * 8.0


func _pose_value(joint: String) -> Vector3:
	return _target.get(joint, Vector3.ZERO)


func _apply(t: float) -> void:
	for j in joints:
		var from: Vector3 = _from.get(j, Vector3.ZERO)
		joints[j].rotation_degrees = from.lerp(_target.get(j, Vector3.ZERO), t)


# --- Construction helpers ---------------------------------------------------------

func _joint(joint_name: String, parent: Node3D, offset: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = joint_name
	n.position = offset
	parent.add_child(n)
	joints[joint_name] = n
	return n


## A limb hanging down from a pivot.
func _limb(pivot: Node3D, length: float, radius: float, mat: Material, offset: Vector3 = Vector3.ZERO, override_height: float = -1.0) -> void:
	var total := override_height if override_height > 0.0 else length
	_capsule(pivot, radius, total + radius * 2.0, mat, offset + Vector3(0, -total * 0.5, 0))


func _capsule(parent: Node3D, radius: float, total_height: float, mat: Material, pos: Vector3, scale_xyz: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = maxf(total_height, radius * 2.0)
	cm.radial_segments = 14
	cm.rings = 6
	m.mesh = cm
	m.material_override = mat
	m.position = pos
	m.scale = scale_xyz
	parent.add_child(m)
	return m


func _head(parent: Node3D, h: float, skin: Material, hair: Material, appearance: Dictionary) -> void:
	var r := 0.062 * h
	var skull := _sphere(parent, r, skin, Vector3(0, r * 0.95, 0), Vector3(0.9, 1.08, 1.0))
	skull.name = "Skull"
	# Face: brows, eyes, nose, mouth, ears — quiet and small, never cartoonish.
	var dark := _cloth(Color(0.05, 0.04, 0.04), 0.3)
	for side in [-1.0, 1.0]:
		_sphere(parent, r * 0.1, dark, Vector3(side * r * 0.36, r * 1.05, -r * 0.88))
		var brow := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(r * 0.34, r * 0.05, r * 0.06)
		brow.mesh = bm
		brow.material_override = hair
		brow.position = Vector3(side * r * 0.36, r * 1.22, -r * 0.9)
		parent.add_child(brow)
		_sphere(parent, r * 0.16, skin, Vector3(side * r * 0.9, r * 0.95, 0), Vector3(0.5, 1.0, 0.8))  # ears
	_sphere(parent, r * 0.14, skin, Vector3(0, r * 0.82, -r * 0.98), Vector3(0.8, 1.0, 1.0))  # nose
	var mouth := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(r * 0.36, r * 0.035, r * 0.04)
	mouth.mesh = mm
	mouth.material_override = _cloth(Color(0.42, 0.24, 0.22), 0.5)
	mouth.position = Vector3(0, r * 0.52, -r * 0.93)
	parent.add_child(mouth)
	match str(appearance.get("hair", "short")):
		"bun":
			_sphere(parent, r * 1.05, hair, Vector3(0, r * 1.15, r * 0.12), Vector3(0.92, 1.04, 1.0))
			_sphere(parent, r * 0.45, hair, Vector3(0, r * 1.1, r * 1.12))
		"short":
			_sphere(parent, r * 1.03, hair, Vector3(0, r * 1.18, r * 0.1), Vector3(0.92, 0.98, 1.0))
	if str(appearance.get("hat", "")) == "non_la":
		var hat := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = r * 3.0
		cm.height = r * 1.6
		cm.radial_segments = 24
		hat.mesh = cm
		var straw := StandardMaterial3D.new()
		straw.albedo_color = Color(0.86, 0.78, 0.56)
		straw.roughness = 0.85
		straw.backlight_enabled = true
		straw.backlight = Color(0.3, 0.25, 0.12)
		hat.material_override = straw
		hat.position = Vector3(0, r * 2.05, 0)
		parent.add_child(hat)
	elif str(appearance.get("hat", "")) == "cap":
		var cap_mat := _cloth(_color(appearance, "cap_color", Color(0.75, 0.15, 0.12)))
		_sphere(parent, r * 1.08, cap_mat, Vector3(0, r * 1.3, r * 0.05), Vector3(0.95, 0.62, 1.0))
		var brim := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(r * 1.5, r * 0.08, r * 1.0)
		brim.mesh = bm
		brim.material_override = cap_mat
		brim.position = Vector3(0, r * 1.25, -r * 1.2)
		parent.add_child(brim)


func _sphere(parent: Node3D, radius: float, mat: Material, pos: Vector3, scale_xyz: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	m.mesh = sm
	m.material_override = mat
	m.position = pos
	m.scale = scale_xyz
	parent.add_child(m)
	return m


func _skin(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.55
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.35
	m.rim_enabled = true
	m.rim = 0.15
	return m


func _cloth(color: Color, roughness: float = 0.92) -> StandardMaterial3D:
	var key := "%s_%s" % [color.to_html(), roughness]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.rim_enabled = roughness > 0.8
	m.rim = 0.2
	m.rim_tint = 0.6
	_mats[key] = m
	return m


static func _color(appearance: Dictionary, key: String, fallback: Color) -> Color:
	var v = appearance.get(key)
	if v is Array and v.size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	return fallback
