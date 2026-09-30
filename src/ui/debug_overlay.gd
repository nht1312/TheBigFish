class_name DebugOverlay
extends Label
## [F3] development overlay (docs/18 §53). Debug builds only.

var fishing: FishingController
var player: PlayerController


func _init() -> void:
	position = Vector2(28, 70)
	add_theme_font_size_override("font_size", 15)
	add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func toggle() -> void:
	visible = OS.is_debug_build() and not visible


func _process(_delta: float) -> void:
	if not visible or App.ctx() == null:
		return
	var ctx := App.ctx()
	var lines: Array[String] = []
	lines.append("FPS %d" % Engine.get_frames_per_second())
	lines.append("Map %s / %s" % [ctx.state.current_map, ctx.state.current_location])
	lines.append("Day %d %s (%s)  Weather %s  activity ×%.2f" % [ctx.clock.day, ctx.clock.time_string(), ctx.clock.day_phase(), ctx.clock.weather, ctx.clock.fish_activity()])
	if player:
		var p := player.global_position
		lines.append("Pos %.1f %.1f %.1f  yaw %.0f" % [p.x, p.y, p.z, player.yaw_degrees()])
	if fishing:
		var s := fishing.session
		lines.append("Fishing %s  tension %.1f  line %.1fm  rod %.1f  stamina %.0f  drag %.1f" % [s.state, s.tension, s.line_distance, s.rod_durability, s.player_stamina, s.drag])
		if s.fish:
			lines.append("Fish %s %.2fkg  %s  phase %s  stamina %.0f%%  lateral %.2f" % [s.fish_def.get("id", ""), s.fish_weight, s.fish.action, s.fish.phase_name, s.fish.stamina_ratio() * 100.0, s.fish.lateral])
		lines.append("Next fish override: %s" % ctx.state.get_var("fishing.next_fish"))
	for q in ctx.quests.active_quests():
		lines.append("Quest %s: %s" % [q, ctx.quests.current_objective_text(q)])
	lines.append("Passion %.0f  Skill %.0f (%s)  FishCaught %.0f" % [ctx.state.get_stat("FishingPassion"), ctx.state.get_stat("FishingSkill"), FishingSkill.level_name(ctx.state.get_stat("FishingSkill")), ctx.state.get_stat("FishCaught")])
	var mother := []
	for dim in ["Trust", "Concern", "Understanding", "Respect", "Conflict", "Support"]:
		mother.append("%s %.0f" % [dim, ctx.relationships.get_relationship("NPC_MOTHER", dim)])
	lines.append("Mother: " + ", ".join(mother))
	var recent := []
	for e in ctx.bus.history.slice(-5):
		recent.append(str(e[0]))
	lines.append("Events: " + ", ".join(recent))
	text = "\n".join(lines)
