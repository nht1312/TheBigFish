class_name FishingController
extends Node3D
## Presentation + input for fishing (docs/18 §13). Owns the FishingSession for the player,
## chooses the fish via FishSelector and hands finished results to FishingOutcomes.
## Visual feedback: rod bend, line, float, fish position, splashes (docs/07 §49).

signal message(text: String, style: String)
signal sound(name: String, position: Vector3, volume_db: float)

const CHARGE_SECONDS := 1.1
const RESULT_HOLD_SECONDS := 1.8

const REASON_TEXT := {
	"HOOK_MISSED": "Giật hụt. Cá nhả mồi rồi.",
	"BAIT_STOLEN": "Phao chìm mà không giật. Cá ăn mất mồi.",
	"SLACK": "Dây chùng quá lâu, cá nhả lưỡi.",
	"HOOK": "Lưỡi bị kéo thẳng ra. Căng dây quá lâu.",
	"LINE": "Đứt dây! Căng quá mức rồi.",
	"ROD": "Rắc! Cần gãy rồi.",
}
## Texts that only fit the home-made bamboo rod.
const IMPROVISED_TEXT := {
	"HOOK": "Lưỡi kẽm bị kéo thẳng ra. Căng dây quá lâu.",
	"ROD": "Rắc! Cây tre gãy.",
}
const BAMBOO_COLOR := Color(0.62, 0.62, 0.3)

var player: PlayerController
var session := FishingSession.new()
var enabled: bool = true  # false during dialogue / menus / cutscenes
var autopilot: bool = false  # tests/tools drive `session` directly; device input is ignored
var in_hand: bool = false
var charge: float = -1.0  # < 0 = not charging
var spots: Array = []  # [{ spot, map }]
var tension_zones: Dictionary = {}

var _rod_uid: int = -1
var _cast_spot: Dictionary = {}
var _cast_point: Vector3
var _cast_from: Vector3
var _result_timer: float = 0.0
var _hooked_once: bool = false
var _fight_time: float = 0.0
var _reel_tick: float = 0.0
var _flow := Vector3.ZERO  # downstream direction × current at the cast spot
var _rod_item: String = ""
var _rod_mat: StandardMaterial3D

var _rod_pivot: Node3D
var _rod_tip_joint: Node3D
var _rod_tip_piece: Node3D
var _rod_tip: Node3D
var _float_node: MeshInstance3D
var _line: MeshInstance3D
var _line_mesh := ImmediateMesh.new()
var _line_mat: StandardMaterial3D
var _held_fish: MeshInstance3D
var _splash: CPUParticles3D


func setup(p_player: PlayerController, data: DataRegistry, config: Dictionary) -> void:
	player = p_player
	session.configure({}, config.get("fishing", {}).get("session", {}))
	tension_zones = config.get("fishing", {}).get("tension_zones", {"safe": 30, "normal": 60, "danger": 80, "critical": 95})
	for map in data.all("maps"):
		for spot in map.get("fishing_spots", []):
			spots.append({"spot": spot, "map": map["id"]})
	session.state_changed.connect(_on_state_changed)
	session.cue.connect(_on_cue)
	_build_visuals()


func ctx() -> GameContext:
	return App.ctx()


func is_busy() -> bool:
	return session.is_busy()


## Before saving: an active fight cannot be saved; a waiting cast is reeled in.
func prepare_for_save() -> bool:
	if session.is_fighting() or session.state == FishingSession.BITE:
		return false
	if session.state in [FishingSession.CASTING, FishingSession.WAITING]:
		session.cancel()
	return true


func has_rod() -> bool:
	return ctx().inventory.count("ITEM_IMPROVISED_ROD") > 0 or not ctx().inventory.entries_in_category("FISHING_GEAR").is_empty()


func _process(delta: float) -> void:
	if App.ctx() == null:
		return
	_handle_input(delta)
	session.tick(delta)
	if session.is_finished():
		_result_timer -= delta
		if _result_timer <= 0.0:
			session.reset()
	_update_visuals(delta)


# --- Input --------------------------------------------------------------------

func _handle_input(delta: float) -> void:
	var inv := ctx().inventory
	if in_hand and inv.get_entry(_rod_uid).is_empty() and not session.is_busy():
		in_hand = false  # the rod was taken, sold or lost
	if autopilot:
		return
	if not enabled:
		charge = -1.0
		session.reeling = false
		return
	if Input.is_action_just_pressed("rod_toggle") and not session.is_busy():
		_toggle_rod()
	if Input.is_action_just_pressed("bait_cycle") and not session.is_busy():
		if inv.cycle_bait():
			message.emit("Mồi: %s (%d)" % [ctx().data.display_name("items", inv.equipped_item_id("bait")), inv.count(inv.equipped_item_id("bait"))], "info")
		else:
			message.emit("Không có mồi.", "info")
	if not in_hand:
		return
	match session.state:
		FishingSession.IDLE:
			if Input.is_action_just_pressed("cast"):
				charge = 0.0
			if charge >= 0.0:
				charge = minf(1.0, charge + delta / CHARGE_SECONDS)
				if Input.is_action_just_released("cast"):
					_release_cast(charge)
					charge = -1.0
		FishingSession.CASTING, FishingSession.WAITING:
			if Input.is_action_just_pressed("cast"):
				session.strike()
			elif Input.is_action_just_pressed("reel_in"):
				session.cancel()
				sound.emit("reel", _float_node.global_position, -8.0)
		FishingSession.BITE:
			if Input.is_action_just_pressed("cast"):
				session.strike()
		FishingSession.HOOKED, FishingSession.FIGHTING, FishingSession.EXHAUSTED:
			session.reeling = Input.is_action_pressed("cast")
			session.rod_dir = Input.get_axis("move_left", "move_right")
			if Input.is_action_just_pressed("drag_up"):
				session.drag = clampf(session.drag + 0.1, 0.0, 1.0)
			if Input.is_action_just_pressed("drag_down"):
				session.drag = clampf(session.drag - 0.1, 0.0, 1.0)


func _toggle_rod() -> void:
	var inv := ctx().inventory
	if in_hand:
		in_hand = false
		inv.unequip("rod")
		return
	var gear := inv.entries_in_category("FISHING_GEAR")
	if gear.is_empty():
		return
	# Take the strongest rod the player owns.
	gear.sort_custom(func(a, b): return _rod_strength(a) > _rod_strength(b))
	_rod_uid = int(gear[0]["uid"])
	inv.equip(_rod_uid)
	_rod_item = str(gear[0]["id"])
	var c: Array = ctx().data.get_item(_rod_item).get("rod", {}).get("color", [])
	_rod_mat.albedo_color = Color(float(c[0]), float(c[1]), float(c[2])) if c.size() == 3 else BAMBOO_COLOR
	if inv.equipped_item_id("bait") == "":
		inv.cycle_bait()
	in_hand = true
	_rod_tip_piece.visible = true


func _rod_strength(entry: Dictionary) -> float:
	return float(ctx().data.get_item(entry["id"]).get("rod", {}).get("strength", 0.0))


func _release_cast(power: float) -> void:
	var inv := ctx().inventory
	var rod := inv.equipped_entry("rod")
	if rod.is_empty():
		in_hand = false
		return
	if ctx().state.get_var("fishing.banned_day") == str(ctx().clock.day):
		message.emit("Đã hứa với mẹ hôm nay không đi câu.", "thought")
		return
	if inv.equipped_item_id("bait") == "" and not inv.cycle_bait():
		message.emit("Chưa có mồi. Móc lưỡi không thì cá nào ăn.", "thought")
		return
	var rod_stats: Dictionary = ctx().data.get_item(rod["id"]).get("rod", {})
	session.configure(rod_stats)
	var distance := lerpf(float(session.tuning["cast_min_distance"]), session.max_cast, power)
	var aim := _aim(distance)
	if aim.is_empty():
		message.emit("Không có nước ở đó.", "info")
		return
	var spot: Dictionary = aim["spot"]
	if not spot_fishable(spot):
		message.emit(str(spot.get("blocked_text", "Không câu ở đây được.")), "thought")
		return
	_cast_spot = spot
	_cast_point = aim["point"]
	_cast_from = _rod_tip.global_position
	var bait_id := inv.equipped_item_id("bait")
	var pick := FishSelector.pick(spot, ctx().data, bait_id, ctx().state.get_var("fishing.next_fish"), session.rng)
	var attraction := float(ctx().data.get_item(bait_id).get("attraction", 1.0))
	var skill := FishingSkill.level_index(ctx().state.get_stat("FishingSkill"))
	session.rod_durability = float(rod["props"].get("durability", 1.0))
	session.drag = clampf(session.drag, 0.0, 1.0)
	# Only spots with a flow direction have moving water (the drain's "current" is descriptive).
	var current := float(spot.get("current", 0.0)) if spot.has("flow") else 0.0
	var f: Array = spot.get("flow", [0, 0])
	_flow = Vector3(float(f[0]), 0, float(f[1])).normalized() * current
	var cast_dir := (_cast_point - player.global_position) * Vector3(1, 0, 1)
	var right := cast_dir.normalized().cross(Vector3.UP)
	session.set_water(current, clampf(right.dot(_flow.normalized()), -1.0, 1.0) if current > 0.0 else 0.0)
	var activity := ctx().clock.fish_activity() * float(spot.get("bite_rate", 1.0))
	session.cast(power, pick, activity, attraction, skill)
	sound.emit("whoosh", player.global_position, -6.0)
	ctx().bus.emit_event(GameEvents.CAST_MADE, {"spot": str(spot.get("id", "")), "map": ctx().state.current_map, "current": current})


## Static "fishable", then optional "fishable_conditions" (e.g. a pond closed after an incident).
func spot_fishable(spot: Dictionary) -> bool:
	if not spot.get("fishable", true):
		return false
	return ctx().conditions.check(spot.get("fishable_conditions", []))


func _map_has_fishing(map_id: String) -> bool:
	for entry in spots:
		if entry["map"] == map_id and entry["spot"].get("fishable", true):
			return true
	return false


## Finds the water spot the bait would land in at `distance` straight ahead.
func _aim(distance: float) -> Dictionary:
	var fwd := player.forward()
	fwd.y = 0
	fwd = fwd.normalized()
	var p := player.global_position + fwd * distance
	for entry in spots:
		var spot: Dictionary = entry["spot"]
		var r: Array = spot["rect"]
		if p.x >= float(r[0]) and p.x <= float(r[2]) and p.z >= float(r[1]) and p.z <= float(r[3]):
			return {"spot": spot, "point": Vector3(p.x, float(spot["water_y"]), p.z)}
	return {}


## Tutorial: one mechanic at a time (VERTICAL-SLICE §17).
func hint_text() -> String:
	if not enabled:
		return ""
	var learning := ctx().state.get_stat("FishCaught") < 1.0
	if not in_hand:
		return "[1]  Cầm cần câu" if has_rod() and _map_has_fishing(ctx().state.current_map) else ""
	match session.state:
		FishingSession.IDLE:
			if charge >= 0.0:
				return "Thả chuột để quăng"
			return "Giữ [Chuột trái] lấy đà rồi thả để quăng   ·   [1] cất cần" if learning else ""
		FishingSession.WAITING:
			return "Nhìn cái phao. Chìm hẳn mới giật.   ·   [Chuột phải] thu dây" if learning else ""
		FishingSession.BITE:
			return "[Chuột trái]  Giật!" if learning or _hooked_once == false else ""
		FishingSession.FIGHTING, FishingSession.HOOKED:
			if not learning and not session.fish_def.get("giant", false):
				return ""
			if _fight_time < 5.0:
				return "Giữ [Chuột trái] để kéo — đừng để dây căng quá"
			if _fight_time < 10.0:
				return "[A] / [D]  ghì cần ngược hướng cá chạy"
			return "[Q] / [E] / con lăn  chỉnh độ hãm dây"
		FishingSession.EXHAUSTED:
			return "Cá đuối rồi — kéo vào bờ" if learning else ""
	return ""


# --- Session callbacks --------------------------------------------------------

func _on_state_changed(new_state: String, old_state: String) -> void:
	ctx().bus.emit_event(GameEvents.FISHING_STATE_CHANGED, {"state": new_state, "previous": old_state})
	if new_state == FishingSession.IDLE:
		player.unlock("fishing")
	else:
		player.lock("fishing", true, false)
	if new_state == FishingSession.FIGHTING and old_state == FishingSession.HOOKED:
		_fight_time = 0.0
		_hooked_once = true
		ctx().bus.emit_event(GameEvents.FISH_HOOKED, {"fish": session.fish_def.get("id", "")})
	if new_state in [FishingSession.LANDED, FishingSession.LOST, FishingSession.BROKEN]:
		_result_timer = RESULT_HOLD_SECONDS
		_finish(session.result)
	if old_state in [FishingSession.CASTING, FishingSession.WAITING] and new_state == FishingSession.IDLE:
		ctx().fishing_outcomes.apply(session.result, _rod_uid)


func _finish(result: Dictionary) -> void:
	var outcome := str(result["outcome"])
	var fish_name := ctx().data.display_name("fish", str(result.get("fish", "")))
	ctx().fishing_outcomes.apply(result, _rod_uid)
	match outcome:
		FishingSession.LANDED:
			message.emit("%s — %.2f kg" % [fish_name, float(result["weight"])], "info")
			_held_fish.visible = true
			sound.emit("splash_small", player.global_position + player.forward(), -4.0)
		FishingSession.LOST, FishingSession.BROKEN:
			var reason := str(result.get("reason", ""))
			if not session.fish_def.get("giant", false) or reason != "ROD":
				var texts: Dictionary = IMPROVISED_TEXT if _rod_item == "ITEM_IMPROVISED_ROD" and IMPROVISED_TEXT.has(reason) else REASON_TEXT
				message.emit(texts.get(reason, "Mất cá rồi."), "info")
			if reason == "ROD":
				_break_rod_visual()
			elif reason == "LINE":
				sound.emit("snap", _rod_tip.global_position, -2.0)


func _on_cue(cue_name: String, data: Dictionary) -> void:
	match cue_name:
		"float_landed":
			_emit_splash(_cast_point, 6)
			sound.emit("plop", _cast_point, -8.0)
		"nibble":
			sound.emit("tick", _float_node.global_position, -16.0)
		"bite":
			_emit_splash(_float_node.global_position, 14 if data.get("giant", false) else 6)
			sound.emit("splash_big" if data.get("giant", false) else "plop", _float_node.global_position, 0.0)
		"hooked":
			sound.emit("splash_big" if session.fish_def.get("giant", false) else "splash_small", _float_node.global_position, 0.0)
			player.shake(0.4 if session.fish_def.get("giant", false) else 0.15)
		"spooked":
			message.emit("Giật sớm quá. Phao mới rung thôi, cá bỏ đi rồi.", "info")
		"shadow":
			ctx().bus.emit_event(GameEvents.CUE, {"cue": "fish_shadow", "position": _cast_point})
		"rod_creak":
			sound.emit("creak", _rod_tip.global_position, lerpf(-12.0, 0.0, clampf(float(data.get("severity", 0.5)), 0.0, 1.0)))
			player.shake(0.12)
		"splash":
			_emit_splash(_float_node.global_position, 10)
			sound.emit("splash_small", _float_node.global_position, -2.0)
		"drag_slip":
			sound.emit("drag", _rod_tip.global_position, -10.0)
		"fish_exhausted":
			message.emit("Con cá đuối sức rồi.", "hint")
		"drifted":
			message.emit("Nước cuốn phao trôi xa rồi. Thu dây quăng lại.", "info")


# --- Visuals ------------------------------------------------------------------

func _build_visuals() -> void:
	var bamboo := StandardMaterial3D.new()
	bamboo.albedo_color = BAMBOO_COLOR
	_rod_mat = bamboo
	_rod_pivot = Node3D.new()
	_rod_pivot.rotation_degrees = Vector3(32, 0, 0)
	player.hand.add_child(_rod_pivot)
	_rod_pivot.add_child(_segment(1.0, 0.011, 0.008, bamboo))
	_rod_tip_joint = Node3D.new()
	_rod_tip_joint.position = Vector3(0, 0, -1.0)
	_rod_pivot.add_child(_rod_tip_joint)
	_rod_tip_piece = _segment(1.0, 0.008, 0.004, bamboo)
	_rod_tip_joint.add_child(_rod_tip_piece)
	_rod_tip = Node3D.new()
	_rod_tip.position = Vector3(0, 0, -1.0)
	_rod_tip_joint.add_child(_rod_tip)
	_rod_pivot.visible = false

	_float_node = MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.045
	fm.height = 0.13
	_float_node.mesh = fm
	var float_mat := StandardMaterial3D.new()
	float_mat.albedo_color = Color(0.95, 0.9, 0.85)
	float_mat.emission_enabled = true
	float_mat.emission = Color(0.4, 0.1, 0.05)
	_float_node.material_override = float_mat
	_float_node.top_level = true
	_float_node.visible = false
	add_child(_float_node)

	_line = MeshInstance3D.new()
	_line.mesh = _line_mesh
	_line_mat = StandardMaterial3D.new()
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_mat.albedo_color = Color(0.92, 0.92, 0.9)
	_line.material_override = _line_mat
	_line.top_level = true
	add_child(_line)

	_held_fish = MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.06
	hm.height = 0.12
	_held_fish.mesh = hm
	_held_fish.scale = Vector3(0.8, 1.0, 2.6)
	var fish_mat := StandardMaterial3D.new()
	fish_mat.albedo_color = Color(0.55, 0.6, 0.55)
	fish_mat.metallic = 0.4
	_held_fish.material_override = fish_mat
	_held_fish.position = Vector3(-0.1, -0.1, -0.55)
	_held_fish.rotation_degrees.y = 80
	_held_fish.visible = false
	player.camera.add_child(_held_fish)

	_splash = CPUParticles3D.new()
	_splash.emitting = false
	_splash.one_shot = true
	_splash.explosiveness = 0.95
	_splash.amount = 24
	_splash.lifetime = 0.8
	_splash.direction = Vector3.UP
	_splash.spread = 35.0
	_splash.initial_velocity_min = 1.5
	_splash.initial_velocity_max = 3.5
	_splash.gravity = Vector3(0, -9.8, 0)
	_splash.scale_amount_min = 0.03
	_splash.scale_amount_max = 0.07
	var drop := SphereMesh.new()
	drop.radius = 0.5
	drop.height = 1.0
	var drop_mat := StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.75, 0.85, 0.85, 0.8)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop.material = drop_mat
	_splash.mesh = drop
	_splash.top_level = true
	add_child(_splash)


func _segment(length: float, r0: float, r1: float, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.height = length
	cm.bottom_radius = r0
	cm.top_radius = r1
	cm.radial_segments = 6
	m.mesh = cm
	m.material_override = mat
	m.rotation_degrees.x = -90
	m.position = Vector3(0, 0, -length * 0.5)
	return m


func _emit_splash(pos: Vector3, amount: int) -> void:
	_splash.global_position = pos
	_splash.amount = amount
	_splash.restart()
	_splash.emitting = true


func _break_rod_visual() -> void:
	sound.emit("snap", _rod_tip.global_position, 2.0)
	_rod_tip_piece.visible = false
	var piece := _segment(1.0, 0.008, 0.004, _rod_tip_piece.material_override)
	var body := RigidBody3D.new()
	body.top_level = true
	body.add_child(piece)
	var shape := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(0.05, 0.05, 1.0)
	shape.shape = cs
	shape.position = Vector3(0, 0, -0.5)
	body.add_child(shape)
	add_child(body)
	body.global_transform = _rod_tip_joint.global_transform
	body.linear_velocity = (_float_node.global_position - body.global_position).normalized() * 6.0 + Vector3.UP * 2.0
	body.angular_velocity = Vector3(randf_range(-6, 6), randf_range(-6, 6), 0)
	get_tree().create_timer(6.0).timeout.connect(body.queue_free)
	player.shake(0.8)
	in_hand = false
	get_tree().create_timer(1.2).timeout.connect(func(): _rod_pivot.visible = in_hand)


func _update_visuals(delta: float) -> void:
	_rod_pivot.visible = in_hand or session.is_busy()
	if session.is_fighting():
		_fight_time += delta
	var busy := session.state != FishingSession.IDLE and not (session.is_finished() and session.state != FishingSession.LANDED)
	# Float position.
	match session.state:
		FishingSession.CASTING:
			var t := clampf(session._state_time / float(session.tuning["cast_seconds"]), 0.0, 1.0)
			_float_node.global_position = _cast_from.lerp(_cast_point, t) + Vector3(0, sin(t * PI) * 2.5, 0)
		FishingSession.WAITING:
			var bob := sin(Time.get_ticks_msec() * 0.003) * 0.01
			if session._nibble_left > 0.0:
				bob += sin(Time.get_ticks_msec() * 0.06) * 0.025
			_float_node.global_position = _drifted_point() + Vector3(0, bob, 0)
		FishingSession.BITE:
			var depth := 0.1 if session.bite_ai.bite_strength == "LIGHT" else 0.22
			_float_node.global_position = _drifted_point() + Vector3(0, -depth, 0)
		FishingSession.HOOKED, FishingSession.FIGHTING, FishingSession.EXHAUSTED:
			_float_node.global_position = _fish_position()
		FishingSession.LANDED:
			busy = false
	_float_node.visible = busy
	_held_fish.visible = session.state == FishingSession.LANDED
	if _held_fish.visible:
		_held_fish.rotation.z = sin(Time.get_ticks_msec() * 0.02) * 0.5
	# Rod bend and sway.
	var bend := 0.0
	var sway := 0.0
	if session.is_fighting():
		bend = session.tension / 100.0
		sway = -session.rod_dir * 0.5 + session.fish.lateral * 0.25
	elif session.state == FishingSession.BITE:
		bend = 0.15
	elif charge >= 0.0:
		bend = -charge * 0.3
	_rod_tip_joint.rotation.x = lerpf(_rod_tip_joint.rotation.x, -bend * 0.9, 1.0 - exp(-10.0 * delta))
	_rod_pivot.rotation.x = lerpf(_rod_pivot.rotation.x, deg_to_rad(32.0 + (charge * 40.0 if charge > 0.0 else 0.0) - bend * 12.0), 1.0 - exp(-10.0 * delta))
	_rod_pivot.rotation.y = lerpf(_rod_pivot.rotation.y, sway, 1.0 - exp(-6.0 * delta))
	if session.is_fighting() and session.tension > float(tension_zones.get("danger", 80)):
		player.shake(0.05)
	# Reel clicking while reeling in.
	if session.is_fighting() and session.reeling and not session.player_exhausted:
		_reel_tick -= delta
		if _reel_tick <= 0.0:
			_reel_tick = 0.09
			sound.emit("tick", _rod_tip.global_position, -18.0)
	# Line.
	_line_mesh.clear_surfaces()
	if _float_node.visible and _rod_pivot.visible and _rod_tip_piece.visible:
		var a := _rod_tip.global_position
		var b := _float_node.global_position
		var sag := 0.0 if session.is_fighting() else clampf(a.distance_to(b) * 0.08, 0.0, 0.8)
		var danger := session.is_fighting() and session.tension > session.rod_strength
		_line_mat.albedo_color = Color(1.0, 0.55, 0.45) if danger else Color(0.92, 0.92, 0.9)
		_line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in 13:
			var t := i / 12.0
			_line_mesh.surface_add_vertex(a.lerp(b, t) - Vector3(0, sin(t * PI) * sag, 0))
		_line_mesh.surface_end()


## The float carried downstream by the current while waiting.
func _drifted_point() -> Vector3:
	return _cast_point + _flow * minf(session.drift_time, 30.0) * 0.5


## Where the hooked fish is: along the cast direction at line_distance, offset sideways by its run.
func _fish_position() -> Vector3:
	var origin := player.global_position
	var dir := _cast_point - origin
	dir.y = 0
	dir = dir.normalized()
	var side := dir.cross(Vector3.UP)
	var p := origin + dir * session.line_distance + side * session.fish.lateral * minf(3.0, session.line_distance * 0.4)
	var y := float(_cast_spot.get("water_y", _cast_point.y))
	if session.fish.action in ["DIVE", "HIDE"]:
		y -= 0.35
	elif session.fish.action in ["BURST", "SURFACE"]:
		y += 0.03
	return Vector3(p.x, y, p.z)
