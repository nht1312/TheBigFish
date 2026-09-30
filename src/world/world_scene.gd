class_name WorldScene
extends Node3D
## The playable Vertical Slice world. Wires presentation (player, NPC actors, fishing
## visuals, HUD, audio) to the gameplay systems in App.ctx() and reacts to bus events.
## Gameplay rules stay in the systems/data; this node only translates.

signal exit_to_menu
signal load_requested(slot: String)

const DRAIN_PIPE := Vector3(70, -1.4, 32.0)

var ctx: GameContext
var builder := WorldBuilder.new()
var player: PlayerController
var fishing: FishingController
var hud: Hud
var audio: GameAudio
var fisherman: OldFishermanActor
var mother: NpcActor
var sun: DirectionalLight3D
var environment: Environment
var sky_material: ProceduralSkyMaterial
var rain: CPUParticles3D
var zones: Array = []  # [{ map, location, rect }] first match wins

var _cutscene: bool = false
var _input_cooldown: int = 0


func start(player_save: Dictionary) -> void:
	ctx = App.ctx()
	process_mode = Node.PROCESS_MODE_ALWAYS  # so Esc can close the pause menu
	builder.build(self, App.data())
	_setup_environment()
	_setup_zones()

	player = PlayerController.new()
	add_child(player)
	var spawn: Dictionary = builder.spawns["start"]
	if player_save.has("position"):
		var p: Array = player_save["position"]
		player.global_position = Vector3(float(p[0]), float(p[1]) + 0.1, float(p[2]))
		player.set_yaw_degrees(float(player_save.get("yaw", 0.0)))
	else:
		player.global_position = spawn["position"]
		player.set_yaw_degrees(float(App.config().get("new_game", {}).get("player_yaw_degrees", spawn["yaw"])))

	fishing = FishingController.new()
	add_child(fishing)
	fishing.setup(player, App.data(), App.config())

	fisherman = OldFishermanActor.new()
	fisherman.position = builder.fisherman_spot
	fisherman.rotation_degrees.y = 180
	fisherman.water_y = 0.05
	fisherman.build(ctx.bus)
	fisherman.look_target = player
	add_child(fisherman)

	mother = NpcActor.new()
	mother.position = builder.mother_spot
	mother.rotation_degrees.y = 180
	mother.setup("NPC_MOTHER", "INT_MOTHER", Color(0.55, 0.32, 0.45), Color(0.18, 0.18, 0.22))
	mother.look_target = player
	add_child(mother)

	audio = GameAudio.new()
	add_child(audio)
	audio.place_drain_water(DRAIN_PIPE)

	hud = Hud.new()
	add_child(hud)
	hud.fishing_hud.set_zones(fishing.tension_zones)
	hud.debug_overlay.fishing = fishing
	hud.debug_overlay.player = player
	var commands := DebugCommands.new(ctx)
	commands.world_hooks["teleport"] = teleport
	hud.debug_console.commands = commands
	hud.pause_menu.resume_requested.connect(_toggle_pause)
	hud.pause_menu.save_requested.connect(func(): hud.pause_menu.status.text = "Đã lưu." if save_game("manual") else "Không lưu được lúc này.")
	hud.pause_menu.load_requested.connect(func(): _unpause(); load_requested.emit("manual"))
	hud.pause_menu.menu_requested.connect(func(): _unpause(); exit_to_menu.emit())

	fishing.message.connect(hud.show_message)
	fishing.sound.connect(audio.play)
	player.footstep.connect(func(): audio.play("step", player.global_position, -20.0))
	ctx.bus.event_emitted.connect(_on_bus)

	for node in get_children():
		if node != hud:
			node.process_mode = Node.PROCESS_MODE_PAUSABLE

	_update_objective()
	_apply_weather()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func teleport(place: String) -> bool:
	if not builder.spawns.has(place):
		return false
	player.global_position = builder.spawns[place]["position"]
	player.set_yaw_degrees(float(builder.spawns[place]["yaw"]))
	player.velocity = Vector3.ZERO
	return true


## Returns false when the current moment cannot be saved (mid-fight; manual saves also
## wait for dialogue and cutscenes to finish).
func save_game(slot: String) -> bool:
	if not fishing.prepare_for_save():
		return false
	if slot != "autosave" and (ctx.dialogue.is_active() or _cutscene):
		return false
	var p := player.global_position
	return ctx.save.write(slot, {"position": [p.x, p.y, p.z], "yaw": player.yaw_degrees()}) == OK


func _process(_delta: float) -> void:
	if ctx == null:
		return
	if get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	_update_zone()
	var talking := ctx.dialogue.is_active()
	var menu_open := hud.pause_menu.visible or hud.debug_console.visible
	if talking or _cutscene or menu_open:
		player.lock("ui")
		fishing.enabled = false
		_input_cooldown = 2
	else:
		player.unlock("ui")
		if _input_cooldown > 0:
			_input_cooldown -= 1  # swallow the click/key that closed the UI
		else:
			fishing.enabled = true
	hud.fishing_hud.refresh(fishing)
	hud.set_hint(fishing.hint_text() if not talking and not _cutscene else "")
	var prompt := ""
	if player.focused and not talking and not _cutscene and not fishing.is_busy():
		prompt = ctx.interactions.prompt(player.focused.interactable_id)
	hud.set_prompt(prompt)
	var wants_mouse := menu_open or (talking and hud.dialogue_panel.choices_box.visible)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if wants_mouse else Input.MOUSE_MODE_CAPTURED
	_update_sun()
	if rain.emitting:
		rain.global_position = player.global_position + Vector3(0, 8, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if hud.debug_console.visible:
			hud.debug_console.toggle()
		elif hud.inventory_panel.visible:
			hud.inventory_panel.toggle()
		else:
			_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("debug_console"):
		hud.debug_console.toggle()
		get_viewport().set_input_as_handled()
		return
	if hud.debug_console.visible or hud.pause_menu.visible:
		return
	if event.is_action_pressed("debug_overlay"):
		hud.debug_overlay.toggle()
	elif event.is_action_pressed("inventory"):
		hud.inventory_panel.toggle()
	elif event.is_action_pressed("quicksave"):
		hud.show_message("Đã lưu." if save_game("manual") else "Không lưu được lúc này.", "hint")
	elif event.is_action_pressed("quickload"):
		load_requested.emit("manual")
	elif event.is_action_pressed("interact"):
		_interact()


func _interact() -> void:
	if player.focused == null or ctx.dialogue.is_active() or _cutscene or fishing.is_busy() or _input_cooldown > 0:
		return
	var id := player.focused.interactable_id
	var result := ctx.interactions.interact(id)
	if str(result.get("text", "")) != "":
		hud.show_message(str(result["text"]), "narration")
	if hud.inventory_panel.visible:
		hud.inventory_panel.refresh()


# --- Bus reactions --------------------------------------------------------------

func _on_bus(event_name: StringName, data: Dictionary) -> void:
	match event_name:
		GameEvents.MESSAGE:
			hud.show_message(str(data["text"]), str(data.get("style", "info")), float(data.get("delay", 0.0)))
		GameEvents.CUE:
			_on_cue(data)
		GameEvents.QUEST_STARTED, GameEvents.OBJECTIVE_COMPLETED:
			_update_objective()
		GameEvents.QUEST_COMPLETED:
			_update_objective()
			if data.get("autosave", false):
				call_deferred("save_game", "autosave")
		GameEvents.AUTOSAVE_REQUESTED:
			call_deferred("save_game", "autosave")
		GameEvents.DIALOGUE_STARTED:
			if mother.global_position.distance_to(player.global_position) < 6.0:
				mother.face(player.global_position)
		GameEvents.WEATHER_CHANGED:
			_apply_weather()
		GameEvents.ITEM_OBTAINED, GameEvents.ITEM_LOST:
			if hud.inventory_panel.visible:
				hud.inventory_panel.refresh()


func _on_cue(data: Dictionary) -> void:
	var delay := float(data.get("delay", 0.0))
	if delay > 0.0:
		var copy := data.duplicate()
		copy.erase("delay")
		get_tree().create_timer(delay, false).timeout.connect(_on_cue.bind(copy))
		return
	match str(data.get("cue", "")):
		"craft":
			_play_craft(data.get("lines", []))
		"giant_sign":
			_giant_sign()
		"fish_shadow":
			var p: Vector3 = data["position"]
			_spawn_shadow(p + Vector3(0, -0.5, -4), p + Vector3(0, -0.5, 0), 2.5, 2.2)
		"rod_break_fall":
			player.fall_back()
		"npc_splash":
			audio.play("splash_small", data["position"], -6.0)
		"vs_ending":
			_play_ending()


func _play_craft(lines: Array) -> void:
	_cutscene = true
	await hud.fade_sequence(lines, 1.8)
	_cutscene = false
	hud.show_message("[Tab] xem đồ mang theo", "hint", 0.5)


func _play_ending() -> void:
	_cutscene = true
	await get_tree().create_timer(1.2).timeout
	await hud.fade_sequence(["Con cá đó vẫn còn ở dưới ống cống.", "Còn tiếp..."], 2.6, true)
	hud.fade_text.text = "CÁ LỚN — THE LAST CAST\n\nHết bản Vertical Slice. Cảm ơn bạn đã chơi."
	var t := create_tween()
	t.tween_property(hud.fade_text, "modulate:a", 1.0, 0.8)
	await get_tree().create_timer(6.0).timeout
	_cutscene = false
	exit_to_menu.emit()


func _giant_sign() -> void:
	fishing._emit_splash(DRAIN_PIPE + Vector3(0, 0.05, 3.0), 30)
	audio.play("splash_big", DRAIN_PIPE + Vector3(0, 0, 3), 4.0)
	_spawn_ripple(DRAIN_PIPE + Vector3(0, 0.03, 3.0))
	_spawn_shadow(DRAIN_PIPE + Vector3(0, -0.6, 3), DRAIN_PIPE + Vector3(2, -0.6, 14), 4.0, 3.2)
	player.shake(0.15)


func _spawn_shadow(from: Vector3, to: Vector3, seconds: float, length: float) -> void:
	var shadow := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 0.2
	shadow.mesh = sm
	shadow.scale = Vector3(0.9, 0.3, length)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.04, 0.03, 0.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = mat
	add_child(shadow)
	shadow.global_position = from
	shadow.look_at(to, Vector3.UP)
	var t := create_tween()
	t.tween_property(mat, "albedo_color:a", 0.7, seconds * 0.25)
	t.parallel().tween_property(shadow, "global_position", to, seconds)
	t.tween_property(mat, "albedo_color:a", 0.0, seconds * 0.25)
	t.tween_callback(shadow.queue_free)


func _spawn_ripple(pos: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.85, 0.8, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	ring.scale = Vector3(0.5, 0.05, 0.5)
	add_child(ring)
	ring.global_position = pos
	var t := create_tween()
	t.tween_property(ring, "scale", Vector3(5, 0.05, 5), 2.5)
	t.parallel().tween_property(mat, "albedo_color:a", 0.0, 2.5)
	t.tween_callback(ring.queue_free)


# --- World state helpers -----------------------------------------------------------

func _update_objective() -> void:
	var text := ""
	for quest_id in ctx.quests.active_quests():
		if ctx.data.get_def("quests", quest_id).get("type", "") == "MAIN":
			text = ctx.quests.current_objective_text(quest_id)
			if text != "":
				break
	hud.set_objective(text)


func _setup_zones() -> void:
	for map in App.data().all("maps"):
		for z in map.get("zones", []):
			zones.append({"map": map["id"], "location": z["location"], "rect": z["rect"]})
	# Specific places before the neighbourhood-wide fallback.
	zones.sort_custom(func(a, b): return _area(a["rect"]) < _area(b["rect"]))


func _area(r: Array) -> float:
	return (float(r[2]) - float(r[0])) * (float(r[3]) - float(r[1]))


func _update_zone() -> void:
	var p := player.global_position
	for z in zones:
		var r: Array = z["rect"]
		if p.x >= float(r[0]) and p.x <= float(r[2]) and p.z >= float(r[1]) and p.z <= float(r[3]):
			ctx.state.enter_map(str(z["map"]))
			ctx.state.enter_location(str(z["location"]))
			return


func _setup_environment() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.38, 0.55, 0.78)
	sky_material.sky_horizon_color = Color(0.78, 0.8, 0.78)
	sky_material.ground_horizon_color = Color(0.6, 0.6, 0.55)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.8
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_density = 0.004
	environment.fog_light_color = Color(0.75, 0.78, 0.8)
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)
	rain = CPUParticles3D.new()
	rain.emitting = false
	rain.amount = 600
	rain.lifetime = 0.9
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(14, 0.5, 14)
	rain.direction = Vector3.DOWN
	rain.spread = 3.0
	rain.gravity = Vector3(0, -30, 0)
	rain.initial_velocity_min = 8.0
	rain.initial_velocity_max = 10.0
	var drop := BoxMesh.new()
	drop.size = Vector3(0.01, 0.35, 0.01)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.75, 0.8, 0.9, 0.5)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop.material = drop_mat
	rain.mesh = drop
	rain.top_level = true
	add_child(rain)


func _update_sun() -> void:
	var hours := ctx.clock.minutes / 60.0
	var day_t := clampf((hours - 5.5) / 13.5, 0.0, 1.0)  # 05:30 → 19:00
	var elevation := sin(day_t * PI) * 65.0
	sun.rotation_degrees = Vector3(-maxf(elevation, 4.0), 90.0 - day_t * 180.0 + 180.0, 0)
	var daylight := clampf(elevation / 25.0, 0.0, 1.0)
	var weather_dim := {"SUNNY": 1.0, "CLOUDY": 0.65, "LIGHT_RAIN": 0.5, "HEAVY_RAIN": 0.35, "STORM": 0.25}
	sun.light_energy = lerpf(0.05, 1.1, daylight) * float(weather_dim.get(ctx.clock.weather, 1.0))
	sun.light_color = Color(1.0, 0.75, 0.55).lerp(Color(1.0, 0.97, 0.9), daylight)
	environment.ambient_light_energy = lerpf(0.15, 0.8, daylight)


func _apply_weather() -> void:
	var w := ctx.clock.weather
	var grey := w != "SUNNY"
	sky_material.sky_top_color = Color(0.5, 0.53, 0.56) if grey else Color(0.38, 0.55, 0.78)
	environment.fog_density = {"SUNNY": 0.004, "CLOUDY": 0.006, "LIGHT_RAIN": 0.01, "HEAVY_RAIN": 0.018, "STORM": 0.025}.get(w, 0.004)
	rain.emitting = w in ["LIGHT_RAIN", "HEAVY_RAIN", "STORM"]
	rain.amount = 300 if w == "LIGHT_RAIN" else 900


func _toggle_pause() -> void:
	if hud.pause_menu.visible:
		_unpause()
	else:
		hud.pause_menu.visible = true
		hud.pause_menu.status.text = ""
		get_tree().paused = true


func _unpause() -> void:
	hud.pause_menu.visible = false
	get_tree().paused = false
