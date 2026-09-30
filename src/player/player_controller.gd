class_name PlayerController
extends CharacterBody3D
## First-person walk / look / sprint + looking at interactables (roadmap Phase 1, docs/18 §11).
## Holds no fishing, inventory or dialogue logic — those systems read `aim` and `locks`.

signal focus_changed(interactable: Interactable)

const WALK_SPEED := 3.4
const SPRINT_SPEED := 6.0
const ACCELERATION := 12.0
const GRAVITY := 18.0
const EYE_HEIGHT := 1.6
const REACH := 2.8

var mouse_sensitivity: float = 0.0022
var head: Node3D
var camera: Camera3D
var hand: Node3D  # rod attaches here
var focused: Interactable

## Reasons movement / looking are blocked ("dialogue", "fishing", "menu", "cutscene").
var move_locks: Dictionary = {}
var look_locks: Dictionary = {}

var _ray: RayCast3D
var _bob_time: float = 0.0
var _step_distance: float = 0.0
var _shake: float = 0.0
var _tilt_target: float = 0.0

signal footstep


func _init() -> void:
	name = "Player"
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.875
	add_child(shape)
	head = Node3D.new()
	head.position.y = EYE_HEIGHT
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 72
	camera.near = 0.05
	camera.current = true
	head.add_child(camera)
	hand = Node3D.new()
	hand.position = Vector3(0.32, -0.28, -0.35)
	camera.add_child(hand)
	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -REACH)
	_ray.collision_mask = 1 | Interactable.LAYER
	_ray.collide_with_areas = false
	camera.add_child(_ray)


func can_move() -> bool:
	return move_locks.is_empty()


func can_look() -> bool:
	return look_locks.is_empty()


func lock(reason: String, movement: bool = true, look: bool = true) -> void:
	if movement:
		move_locks[reason] = true
	if look:
		look_locks[reason] = true


func unlock(reason: String) -> void:
	move_locks.erase(reason)
	look_locks.erase(reason)


func yaw_degrees() -> float:
	return rotation_degrees.y


func set_yaw_degrees(yaw: float) -> void:
	rotation_degrees.y = yaw


## Horizontal forward direction.
func forward() -> Vector3:
	return -global_transform.basis.z


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Camera roll/pitch used for the rod-break fall.
func fall_back() -> void:
	_tilt_target = 1.0
	shake(0.6)
	get_tree().create_timer(1.6).timeout.connect(func(): _tilt_target = 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and can_look():
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if can_move():
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var sprint := Input.is_action_pressed("sprint") and input.y < 0.0
	var speed := SPRINT_SPEED if sprint else WALK_SPEED
	var wish := (global_transform.basis * Vector3(input.x, 0, input.y)).normalized() * speed
	velocity.x = move_toward(velocity.x, wish.x, ACCELERATION * delta * speed)
	velocity.z = move_toward(velocity.z, wish.z, ACCELERATION * delta * speed)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()
	_update_head(delta)
	_update_focus()


func _update_head(delta: float) -> void:
	var horizontal := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal > 0.3:
		_bob_time += delta * horizontal * 2.2
		_step_distance += horizontal * delta
		if _step_distance > 1.6:
			_step_distance = 0.0
			footstep.emit()
	var bob := sin(_bob_time) * 0.035 * clampf(horizontal / SPRINT_SPEED, 0.0, 1.0)
	_shake = move_toward(_shake, 0.0, delta * 1.2)
	var jitter := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.05
	head.position = Vector3(0, EYE_HEIGHT + bob, 0) + jitter
	# Falling back: drop the head and pitch the view up.
	var tilt := lerpf(head.get_meta("tilt", 0.0), _tilt_target, 1.0 - exp(-6.0 * delta))
	head.set_meta("tilt", tilt)
	head.position.y -= tilt * 0.9
	camera.rotation.x = tilt * 0.5
	camera.rotation.z = tilt * 0.15


func _update_focus() -> void:
	var hit: Interactable = null
	if can_look() and can_move():
		_ray.force_raycast_update()
		var collider := _ray.get_collider()
		if collider is Interactable:
			hit = collider
	if hit != focused:
		focused = hit
		focus_changed.emit(hit)
