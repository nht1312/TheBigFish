class_name WorldScene
extends Node3D
## The playable Vertical Slice world. Wires presentation (player, NPC actors, fishing
## visuals, HUD, audio) to the gameplay systems in App.ctx() and reacts to bus events.
## Gameplay rules stay in the systems/data; this node only translates.

signal exit_to_menu
signal load_requested(slot: String)

const DRAIN_PIPE := Vector3(70, -1.4, 32.0)
const MOTHER_STOOL_HEIGHT := 0.42
const HOME_DOOR := Vector3(-1.5, 0, 3.9)

var ctx: GameContext
var builder := WorldBuilder.new()
var player: PlayerController
var fishing: FishingController
var hud: Hud
var audio: GameAudio
var fisherman: OldFishermanActor
var mother: NpcActor
var lighting: WorldLighting
var graphics: Dictionary  # active quality preset from config/graphics.json
var zones: Array = []  # [{ map, location, rect }] first match wins
var npc_actors: Dictionary = {}  # npc id -> NpcActor spawned from data "spawn"/"spawns"
var _npc_spawn_index: Dictionary = {}  # npc id -> active spawn entry the actor was built for

## Cues that open UI or fade the screen wait until the dialogue that caused them ends.
const DEFERRED_CUES := ["open_shop", "work", "travel", "sleep", "pond_escort"]
var _pending_cues: Array = []
var _presence_timer: float = 0.0

var _cutscene: bool = false
var _input_cooldown: int = 0


func start(player_save: Dictionary) -> void:
	ctx = App.ctx()
	process_mode = Node.PROCESS_MODE_ALWAYS  # so Esc can close the pause menu
	graphics = _graphics_preset()
	builder.grass_density = float(graphics.get("grass_density", 5.0))
	builder.grass_distance = float(graphics.get("grass_distance", 42.0))
	builder.build(self, App.data())
	lighting = WorldLighting.new()
	add_child(lighting)
	lighting.setup(graphics)
	lighting.apply_viewport(get_viewport())
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
	fisherman.build(ctx.bus, _appearance("NPC_OLD_FISHERMAN"))
	fisherman.look_target = player
	add_child(fisherman)

	mother = NpcActor.new()
	mother.position = builder.mother_spot
	mother.rotation_degrees.y = 180
	mother.setup("NPC_MOTHER", "INT_MOTHER", _appearance("NPC_MOTHER"), MOTHER_STOOL_HEIGHT)
	builder.stool(builder.mother_spot, MOTHER_STOOL_HEIGHT, Color(0.2, 0.45, 0.8))
	builder.vegetable_basket(builder.mother_spot + Vector3(0, 0, 0.55))
	mother.look_target = player
	add_child(mother)
	_spawn_npcs()

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
	hud.shop_panel.closed.connect(func(): _input_cooldown = 2)

	fishing.message.connect(hud.show_message)
	fishing.sound.connect(audio.play)
	player.footstep.connect(func(): audio.play("step", player.global_position, -20.0))
	ctx.bus.event_emitted.connect(_on_bus)

	for node in get_children():
		if node != hud:
			node.process_mode = Node.PROCESS_MODE_PAUSABLE

	_refresh_presence()
	_refresh_placed()
	_refresh_regions()
	_refresh_barriers()
	_update_objective()
	_apply_weather()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	call_deferred("_resume_story")


func teleport(place: String) -> bool:
	if not builder.spawns.has(place):
		return false
	player.global_position = builder.spawns[place]["position"]
	player.set_yaw_degrees(float(builder.spawns[place]["yaw"]))
	player.velocity = Vector3.ZERO
	_refresh_regions()
	_refresh_barriers()
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
	if ctx == null or ctx != App.ctx():
		return  # a load replaced the context; this world is being freed
	if get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	_update_zone()
	_presence_timer -= _delta
	if _presence_timer <= 0.0:
		_presence_timer = 1.0
		_refresh_presence()
		_refresh_regions()
		_refresh_barriers()
	var talking := ctx.dialogue.is_active()
	var menu_open := hud.pause_menu.visible or hud.debug_console.visible or hud.shop_panel.visible
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
	lighting.set_time(ctx.clock.minutes / 60.0, player.global_position)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if hud.debug_console.visible:
			hud.debug_console.toggle()
		elif hud.shop_panel.visible:
			hud.shop_panel.close()
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
	if hud.debug_console.visible or hud.pause_menu.visible or hud.shop_panel.visible:
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
	if player.focused == null or ctx.dialogue.is_active() or _cutscene or fishing.is_busy() or _input_cooldown > 0 or hud.shop_panel.visible:
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
			if data.get("dialogue", "") == "DIALOGUE_MOTHER_VS_END":
				# "Mẹ đứng ở cửa." — she has been waiting at the door.
				mother.position = HOME_DOOR
				mother.set_pose("stand")
			if mother.global_position.distance_to(player.global_position) < 6.0:
				mother.face(player.global_position)
			for actor in npc_actors.values():
				if actor.seat_height < 0.0 and not actor is OldFishermanActor and actor.visible \
						and actor.global_position.distance_to(player.global_position) < 4.0:
					actor.face(player.global_position)
		GameEvents.DIALOGUE_ENDED:
			if not _pending_cues.is_empty():
				call_deferred("_flush_cues")
		GameEvents.MONEY_CHANGED:
			var delta := int(data.get("delta", 0))
			if delta != 0 and not ctx.dialogue.is_active() and not hud.shop_panel.visible and not _cutscene:
				hud.show_message(("+" if delta > 0 else "") + EconomySystem.format_money(delta), "hint")
		GameEvents.INTERACTED, InteractionSystem.SLEEP:
			_refresh_placed()
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
	var cue := str(data.get("cue", ""))
	if cue in DEFERRED_CUES and ctx.dialogue.is_active():
		_pending_cues.append(data)
		return
	match cue:
		"open_shop":
			hud.inventory_panel.visible = false
			hud.shop_panel.open(str(data["shop"]))
		"work":
			var lines: Array = data.get("lines", []).duplicate()
			lines.append("+" + EconomySystem.format_money(int(data.get("pay", 0))))
			_play_fade(lines)
		"travel":
			_play_travel(str(data["destination"]), data.get("lines", []))
		"sleep":
			_play_fade(data.get("lines", []))
		"chapter_end":
			_play_chapter_end(data)
		"pond_escort":
			_play_travel(str(data.get("destination", "lake")), data.get("lines", []))
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


func _play_fade(lines: Array) -> void:
	_cutscene = true
	await hud.fade_sequence(lines, 1.8)
	_cutscene = false
	_refresh_presence()
	_refresh_placed()


func _play_travel(destination: String, lines: Array) -> void:
	_cutscene = true
	await hud.fade_sequence(lines, 1.8, true)
	teleport(destination)
	_update_zone()
	_refresh_presence()
	await hud.fade_from_black()
	_cutscene = false


func _flush_cues() -> void:
	var cues := _pending_cues.duplicate()
	_pending_cues.clear()
	for data in cues:
		_on_cue(data)


## End of the Vertical Slice (Act I): the night passes and Chapter II begins at home.
func _play_ending() -> void:
	_cutscene = true
	await get_tree().create_timer(1.2).timeout
	await hud.fade_sequence(["Con cá đó vẫn còn ở dưới ống cống.", "Còn tiếp..."], 2.6, true)
	await _start_chapter_two()


## Also used when a save from the moment after the ending is loaded.
func _start_chapter_two() -> void:
	_cutscene = true
	if hud.fade_rect.color.a < 1.0:
		await hud.fade_sequence([], 0.0, true)
	await hud.title_card("CHƯƠNG II\n\nHọc nghề")
	ctx.clock.sleep_until(7)
	teleport("home")
	mother.position = builder.mother_spot
	mother.rotation_degrees = Vector3(0, 180, 0)
	mother.set_pose("sit_chores", MOTHER_STOOL_HEIGHT)
	_update_zone()
	_refresh_presence()
	_refresh_placed()
	save_game("autosave")
	await hud.fade_from_black(1.2)
	_cutscene = false
	ctx.bus.emit_event(GameEvents.CHAPTER_STARTED, {"chapter": "ACT_II"})


## Cue data: { end_text, next_title?, next_chapter? } — the card texts live with the event.
func _play_chapter_end(data: Dictionary) -> void:
	_cutscene = true
	await hud.fade_sequence([], 0.0, true)
	await hud.title_card(str(data.get("end_text", "")), 4.0)
	if data.has("next_title"):
		await hud.title_card(str(data["next_title"]), 3.5)
	await hud.fade_from_black()
	_cutscene = false
	if data.has("next_chapter"):
		ctx.bus.emit_event(GameEvents.CHAPTER_STARTED, {"chapter": str(data["next_chapter"])})


func _resume_story() -> void:
	if _cutscene:
		return
	if ctx.state.has_flag("VERTICAL_SLICE_COMPLETE") and not ctx.state.has_flag("event_done:EVENT_ACT2_MORNING"):
		_start_chapter_two()
	elif ctx.state.has_flag("ACT_II_COMPLETE") and not ctx.state.has_flag("event_done:EVENT_ACT3_START"):
		ctx.bus.emit_event(GameEvents.CHAPTER_STARTED, {"chapter": "ACT_III"})  # saved during the chapter card


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


func _spawn_npcs() -> void:
	for def in App.data().all("npcs"):
		if def.has("spawn") or def.has("spawns"):
			_npc_spawn_index[str(def["id"])] = -2  # built by the first _refresh_presence()


func _build_npc(id: String, sp: Dictionary) -> NpcActor:
	var def := App.data().get_def("npcs", id)
	var p: Array = sp["position"]
	var appearance: Dictionary = def.get("appearance", {}).duplicate()
	if sp.has("pose"):
		appearance["pose"] = sp["pose"]
	var actor: NpcActor
	if str(sp.get("actor", "")) == "fisherman":
		var angler := OldFishermanActor.new()
		angler.water_y = float(sp.get("water_y", 0.0))
		angler.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		angler.rotation_degrees.y = float(sp.get("yaw", 0.0))
		angler.build(ctx.bus, appearance, id, str(def["interactable"]))
		actor = angler
	else:
		actor = NpcActor.new()
		actor.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		actor.rotation_degrees.y = float(sp.get("yaw", 0.0))
		actor.setup(id, str(def["interactable"]), appearance, float(sp.get("seat", -1.0)))
		if float(sp.get("seat", -1.0)) >= 0.0 and sp.get("stool", false):
			builder.stool(actor.position, float(sp["seat"]), Color(0.2, 0.35, 0.7))
	actor.look_target = player
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(actor)
	return actor


## NPCs keep hours (docs/13 §4) and move with the story: the active "spawns" entry
## decides where they are, and the actor is rebuilt when that changes.
func _refresh_presence() -> void:
	for id in _npc_spawn_index:
		var index := ctx.npcs.spawn_index(id)
		if index != _npc_spawn_index[id]:
			_npc_spawn_index[id] = index
			if npc_actors.has(id):
				npc_actors[id].queue_free()
				npc_actors.erase(id)
			if index >= 0:
				npc_actors[id] = _build_npc(id, ctx.npcs.spawn_def(id))
		if not npc_actors.has(id):
			continue
		var actor: Node3D = npc_actors[id]
		var here := ctx.npcs.is_present(id)
		if actor.visible != here:
			actor.visible = here
			actor.process_mode = Node.PROCESS_MODE_PAUSABLE if here else Node.PROCESS_MODE_DISABLED


## Only the far area the player is in is drawn (the lake, stream and river are hundreds
## of metres apart), which keeps draw calls down.
func _refresh_regions() -> void:
	var p := player.global_position
	for region in builder.regions:
		var r: Array = region["rect"]
		region["node"].visible = p.x >= float(r[0]) and p.x <= float(r[2]) and p.z >= float(r[1]) and p.z <= float(r[3])


## Story barriers (a fence gap that is only open while Cò is showing the way).
func _refresh_barriers() -> void:
	for id in builder.barriers:
		var entry: Dictionary = builder.barriers[id]
		var open := ctx.conditions.check(entry["def"].get("open_conditions", []))
		var shape: CollisionShape3D = entry["body"].get_child(0)
		if shape.disabled != open:
			shape.set_deferred("disabled", open)
		entry["visual"].visible = not open


## Scrap spots already picked today stay empty until they respawn.
func _refresh_placed() -> void:
	for id in builder.act2.placed:
		builder.act2.placed[id].visible = not ctx.interactions.is_depleted(id)


func _appearance(npc_id: String) -> Dictionary:
	return App.data().get_def("npcs", npc_id).get("appearance", {})


func _graphics_preset() -> Dictionary:
	var cfg: Dictionary = App.config().get("graphics", {})
	var quality := str(cfg.get("quality", "medium"))
	return cfg.get("presets", {}).get(quality, {})


func _apply_weather() -> void:
	lighting.set_weather(ctx.clock.weather)


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
