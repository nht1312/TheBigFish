class_name FishingHud
extends PanelContainer
## Minimal fishing HUD (VERTICAL-SLICE §18, docs/18 §52): tension, rod condition,
## player stamina, fish stamina, what the fish is doing. Nothing more.

const FISH_STATE_TEXT := {
	"RUN": "Cá đang chạy", "BURST": "Cá vọt mạnh!", "TURN": "Cá đổi hướng", "SHAKE": "Cá lắc đầu",
	"REST": "Cá đang nghỉ", "DIVE": "Cá lặn sâu", "SURFACE": "Cá trồi lên", "HIDE": "Cá rúc xuống đáy",
	"EXHAUSTED": "Cá đuối sức",
}

var tension_bar: ProgressBar
var rod_bar: ProgressBar
var stamina_bar: ProgressBar
var fish_bar: ProgressBar
var charge_bar: ProgressBar
var state_label: Label
var info_label: Label
var _fight_box: VBoxContainer
var _zones := {"safe": 30.0, "normal": 60.0, "danger": 80.0, "critical": 95.0}


func _init() -> void:
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	custom_minimum_size = Vector2(420, 0)
	position = Vector2(-210, -290)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	state_label = UiStyle.label("", 22, UiStyle.THOUGHT)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(state_label)
	_fight_box = VBoxContainer.new()
	box.add_child(_fight_box)
	tension_bar = _row(_fight_box, "Căng dây", UiStyle.SAFE, 260)
	rod_bar = _row(_fight_box, "Cần", Color(0.75, 0.65, 0.4))
	stamina_bar = _row(_fight_box, "Sức", Color(0.5, 0.7, 0.9))
	fish_bar = _row(_fight_box, "Cá", Color(0.7, 0.75, 0.7))
	charge_bar = _row(box, "Lấy đà", Color(0.9, 0.85, 0.6))
	info_label = UiStyle.label("", 16, UiStyle.DIM)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info_label)


func set_zones(zones: Dictionary) -> void:
	for key in zones:
		_zones[key] = float(zones[key])


func refresh(fishing: FishingController) -> void:
	var s := fishing.session
	var inv := App.ctx().inventory
	var charging := fishing.in_hand and fishing.charge >= 0.0
	var fighting := s.is_fighting()
	visible = fighting or charging or s.state in [FishingSession.WAITING, FishingSession.BITE, FishingSession.CASTING] or (fishing.in_hand and s.state == FishingSession.IDLE)
	if not visible:
		return
	_fight_box.visible = fighting
	charge_bar.get_parent().visible = charging
	charge_bar.value = fishing.charge * 100.0
	state_label.text = ""
	if fighting:
		var fish_state := s.fish_state_name()
		var arrow := ""
		if absf(s.fish.lateral) > 0.3:
			arrow = "◀  " if s.fish.lateral < 0.0 else ""
		var arrow_r := "  ▶" if s.fish.lateral > 0.3 else ""
		state_label.text = arrow + str(FISH_STATE_TEXT.get(fish_state, "")) + arrow_r
		if s.slack_time > 1.0:
			state_label.text = "Dây chùng — kéo lên một chút!"
		tension_bar.value = s.tension
		UiStyle.set_bar_color(tension_bar, _tension_color(s.tension))
		rod_bar.value = s.rod_durability / maxf(1.0, _max_durability(inv)) * 100.0
		stamina_bar.value = s.player_stamina
		UiStyle.set_bar_color(stamina_bar, UiStyle.CRITICAL if s.player_exhausted else Color(0.5, 0.7, 0.9))
		fish_bar.value = s.fish.stamina_ratio() * 100.0
		info_label.text = "Hãm dây %d%%" % int(round(s.drag * 100.0))
	elif s.state == FishingSession.BITE:
		state_label.text = "!"
		info_label.text = ""
	else:
		var bait := inv.equipped_item_id("bait")
		info_label.text = "Mồi: %s × %d" % [App.ctx().data.display_name("items", bait), inv.count(bait)] if bait != "" else "Chưa có mồi"


func _tension_color(t: float) -> Color:
	if t >= _zones["danger"]:
		return UiStyle.CRITICAL if t >= _zones["critical"] else UiStyle.DANGER
	if t >= _zones["normal"]:
		return UiStyle.NORMAL
	return UiStyle.SAFE


func _max_durability(inv: Inventory) -> float:
	var rod := inv.equipped_entry("rod")
	if rod.is_empty():
		return 20.0
	return float(App.ctx().data.get_item(rod["id"]).get("durability", 20.0))


func _row(parent: Control, title: String, color: Color, width: float = 220.0) -> ProgressBar:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var l := UiStyle.label(title, 16, UiStyle.DIM)
	l.custom_minimum_size = Vector2(80, 0)
	row.add_child(l)
	var b := UiStyle.bar(color, width)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	parent.add_child(row)
	return b
