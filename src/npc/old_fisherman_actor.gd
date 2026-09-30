class_name OldFishermanActor
extends NpcActor
## A seated NPC angler — NPC_OLD_FISHERMAN at the canal (VERTICAL-SLICE §8–9), and
## anyone else whose spawn data says actor "fisherman".
## Loops: wait → nibble → bite → reel → hold the fish up → bucket.
## When the player is close enough to see a catch, emits FishermanCatchObserved.

enum Phase { WAIT, NIBBLE, BITE, REEL, HOLD, STORE }

const OBSERVE_DISTANCE := 24.0
const WAKE_DISTANCE := 32.0

var bus: EventBus
var water_y: float = 0.05
var phase: Phase = Phase.WAIT
var catches: int = 0

var _timer: float = 5.0
var _rod: Node3D
var _tip: Node3D
var _float_node: MeshInstance3D
var _float_rest: Vector3
var _fish: MeshInstance3D
var _line: MeshInstance3D
var _line_mesh := ImmediateMesh.new()
var _clock: float = 0.0


func build(p_bus: EventBus, appearance: Dictionary, p_npc_id: String = "NPC_OLD_FISHERMAN", interactable_id: String = "INT_OLD_FISHERMAN") -> void:
	bus = p_bus
	setup(p_npc_id, interactable_id, appearance, 0.4)
	var stool := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.4, 0.4, 0.4)
	stool.mesh = sm
	stool.position = Vector3(0, 0.2, 0.05)
	stool.material_override = _mat(Color(0.2, 0.35, 0.7))
	add_child(stool)
	var bucket := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.2
	bm.bottom_radius = 0.16
	bm.height = 0.35
	bucket.mesh = bm
	bucket.position = Vector3(0.6, 0.18, 0.1)
	bucket.material_override = _mat(Color(0.85, 0.85, 0.8))
	add_child(bucket)
	# Rod from the hands out over the water (local -Z faces the canal).
	_rod = Node3D.new()
	_rod.position = Vector3(0.15, 0.85, -0.3)
	_rod.rotation_degrees.x = 28
	add_child(_rod)
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.01
	cm.bottom_radius = 0.025
	cm.height = 3.2
	pole.mesh = cm
	pole.rotation_degrees.x = -90
	pole.position = Vector3(0, 0, -1.6)
	pole.material_override = _mat(Color(0.55, 0.5, 0.3))
	_rod.add_child(pole)
	_tip = Node3D.new()
	_tip.position = Vector3(0, 0, -3.2)
	_rod.add_child(_tip)
	_float_node = MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.05
	fm.height = 0.12
	_float_node.mesh = fm
	_float_node.material_override = _mat(Color(0.95, 0.2, 0.15))
	add_child(_float_node)
	_fish = MeshInstance3D.new()
	var fish_mesh := SphereMesh.new()
	fish_mesh.radius = 0.08
	fish_mesh.height = 0.16
	_fish.mesh = fish_mesh
	_fish.scale = Vector3(0.7, 0.9, 2.2)
	_fish.material_override = _mat(Color(0.65, 0.68, 0.6))
	_fish.visible = false
	add_child(_fish)
	_line = MeshInstance3D.new()
	_line.mesh = _line_mesh
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.9, 0.9, 0.9)
	_line.material_override = lm
	_line.top_level = true
	add_child(_line)


func _ready() -> void:
	_attach_rod_to_hands()
	_float_rest = to_local(Vector3(global_position.x, water_y, global_position.z)) + Vector3(0, 0, -3.3)
	_float_node.position = _float_rest


func _process(delta: float) -> void:
	super._process(delta)
	_attach_rod_to_hands()
	_clock += delta
	var near := look_target != null and look_target.global_position.distance_to(global_position) < WAKE_DISTANCE
	if phase == Phase.WAIT and catches == 0 and not near:
		return  # the first catch waits for the player to be around
	_timer -= delta
	var bob := sin(_clock * 2.0) * 0.01
	match phase:
		Phase.WAIT:
			_float_node.position = _float_rest + Vector3(0, bob, 0)
			if _timer <= 0.0:
				_enter(Phase.NIBBLE, 1.6)
		Phase.NIBBLE:
			_float_node.position = _float_rest + Vector3(0, sin(_clock * 30.0) * 0.02, 0)
			if _timer <= 0.0:
				_enter(Phase.BITE, 0.35)
		Phase.BITE:
			_float_node.position = _float_rest + Vector3(0, -0.12, 0)
			_rod.rotation_degrees.x = lerpf(_rod.rotation_degrees.x, 12.0, delta * 10.0)
			if _timer <= 0.0:
				_enter(Phase.REEL, 1.3)
				rig.set_pose("sit_reel")
				_fish.visible = true
				_float_node.visible = false
				if bus:
					bus.emit_event(GameEvents.CUE, {"cue": "npc_splash", "position": _float_node.global_position})
		Phase.REEL:
			var t := 1.0 - _timer / 1.3
			_rod.rotation_degrees.x = lerpf(12.0, 55.0, t)
			var from := _float_rest
			var to := Vector3(0.25, 1.1, -0.45)
			_fish.position = from.lerp(to, t) + Vector3(0, sin(t * PI) * 0.8, 0)
			_fish.rotation.z = sin(_clock * 25.0) * 0.6
			if _timer <= 0.0:
				_enter(Phase.HOLD, 2.8)
				_notify_observed()
		Phase.HOLD:
			_fish.position = Vector3(0.25, 1.05, -0.4)
			_fish.rotation.z = sin(_clock * 18.0) * 0.5 * (_timer / 2.8)
			if _timer <= 0.0:
				_enter(Phase.STORE, 0.6)
		Phase.STORE:
			_fish.position = _fish.position.lerp(Vector3(0.6, 0.3, 0.1), delta * 8.0)
			if _timer <= 0.0:
				_fish.visible = false
				_float_node.visible = true
				_rod.rotation_degrees.x = 28
				rig.set_pose("sit_fishing")
				catches += 1
				_enter(Phase.WAIT, randf_range(25.0, 40.0))
	_draw_line()


## The rod butt follows the right hand, so arm poses and rod angle stay together.
func _attach_rod_to_hands() -> void:
	if rig and rig.joints.has("r_hand") and is_inside_tree():
		_rod.global_position = rig.joints["r_hand"].global_position


func _enter(p: Phase, seconds: float) -> void:
	phase = p
	_timer = seconds


func _notify_observed() -> void:
	if look_target and look_target.global_position.distance_to(global_position) < OBSERVE_DISTANCE and bus:
		bus.emit_event(GameEvents.FISHERMAN_CATCH_OBSERVED, {"npc": npc_id})


func _draw_line() -> void:
	_line_mesh.clear_surfaces()
	var end := _fish.global_position if _fish.visible else _float_node.global_position
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_line_mesh.surface_add_vertex(_tip.global_position)
	_line_mesh.surface_add_vertex(end)
	_line_mesh.surface_end()
