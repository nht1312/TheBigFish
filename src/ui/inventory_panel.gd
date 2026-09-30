class_name InventoryPanel
extends PanelContainer
## Read-only list of what the player carries (docs/09 §21: not a spreadsheet).

const CATEGORY_NAMES := {
	"FISHING_GEAR": "Đồ câu", "BAIT": "Mồi", "FISH": "Cá", "MATERIAL": "Vật liệu",
	"CONSUMABLE": "Đồ dùng", "QUEST_ITEM": "Đồ quan trọng", "SPECIAL": "Kỷ niệm",
}

var list: VBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	custom_minimum_size = Vector2(460, 0)
	position = Vector2(-500, -260)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	add_child(list)


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


func refresh() -> void:
	for c in list.get_children():
		c.free()
	var ctx := App.ctx()
	list.add_child(UiStyle.label("Đồ mang theo", 22, UiStyle.THOUGHT))
	list.add_child(UiStyle.label("Tiền: %d" % ctx.state.money, 17, UiStyle.DIM))
	if ctx.inventory.entries.is_empty():
		list.add_child(UiStyle.label("Chẳng có gì.", 18, UiStyle.DIM))
	for category in CATEGORY_NAMES:
		var entries := ctx.inventory.entries_in_category(category)
		if entries.is_empty():
			continue
		list.add_child(UiStyle.label(CATEGORY_NAMES[category], 17, UiStyle.DIM))
		for e in entries:
			var def := ctx.data.get_item(e["id"])
			var text := "  " + str(def.get("name", e["id"]))
			if int(e["qty"]) > 1:
				text += "  × %d" % int(e["qty"])
			if e["props"].has("weight"):
				text += "  — %.2f kg" % float(e["props"]["weight"])
			var equipped: bool = ctx.inventory.equipment.values().has(int(e["uid"]))
			if equipped:
				text += "   (đang dùng)"
			var l := UiStyle.label(text, 19)
			l.tooltip_text = str(def.get("description", ""))
			list.add_child(l)
			var desc := UiStyle.label("     " + str(def.get("description", "")), 15, UiStyle.DIM)
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc.custom_minimum_size = Vector2(420, 0)
			list.add_child(desc)
