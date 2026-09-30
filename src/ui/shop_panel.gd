class_name ShopPanel
extends PanelContainer
## Buy/sell window for one shop (docs/10). Every transaction goes through EconomySystem;
## this only lists what the shop offers and what it would buy from the player.

signal closed

var shop_id: String = ""
var list: VBoxContainer
var status: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(620, 0)
	position = Vector2(-310, -300)
	visible = false
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	add_child(list)


func open(p_shop_id: String) -> void:
	shop_id = p_shop_id
	visible = true
	refresh("")


func close() -> void:
	if not visible:
		return
	visible = false
	shop_id = ""
	closed.emit()


func refresh(message: String) -> void:
	for c in list.get_children():
		c.free()
	var ctx := App.ctx()
	var eco := ctx.economy
	var def := eco.shop(shop_id)
	list.add_child(UiStyle.label(str(def.get("name", "")), 24, UiStyle.THOUGHT))
	list.add_child(UiStyle.label("Tiền: " + EconomySystem.format_money(ctx.state.money), 18, UiStyle.DIM))

	var stock := eco.stock(shop_id)
	if not stock.is_empty():
		list.add_child(UiStyle.label("Bán", 17, UiStyle.DIM))
		for line in stock:
			var item_id := str(line["item"])
			var name := ctx.data.display_name("items", item_id)
			if line.has("note"):
				name = str(line["note"])
			var row := _row("%s  —  %s" % [name, EconomySystem.format_money(int(line["price"]))], "Mua")
			var button: Button = row.get_child(1)
			button.disabled = not eco.can_afford(int(line["price"]))
			button.pressed.connect(func(): refresh(_bought(eco.buy(shop_id, item_id), name)))
			list.add_child(row)

	if not def.get("buys", {}).is_empty():
		list.add_child(UiStyle.label("Mua lại của bạn", 17, UiStyle.DIM))
		var offers := eco.sellable(shop_id)
		if offers.is_empty():
			list.add_child(UiStyle.label("  Không có gì bán được.", 18, UiStyle.DIM))
		for offer in offers:
			var entry: Dictionary = offer["entry"]
			var text := ctx.data.display_name("items", entry["id"])
			if entry["props"].has("weight"):
				text += "  %.2f kg, %s" % [float(entry["props"]["weight"]), eco.freshness_label(entry)]
			if int(entry["qty"]) > 1:
				text += "  × %d" % int(entry["qty"])
			var row := _row("%s  —  %s" % [text, EconomySystem.format_money(int(offer["price"]) * int(entry["qty"]))], "Bán")
			var uid := int(entry["uid"])
			(row.get_child(1) as Button).pressed.connect(func(): refresh("Được " + EconomySystem.format_money(eco.sell(shop_id, uid)) + "."))
			list.add_child(row)
		if offers.size() > 1:
			var all := Button.new()
			all.text = "Bán hết"
			all.pressed.connect(func(): refresh("Được " + EconomySystem.format_money(eco.sell_all(shop_id)) + "."))
			list.add_child(all)

	status = UiStyle.label(message, 18, UiStyle.THOUGHT)
	list.add_child(status)
	var leave := Button.new()
	leave.text = "Thôi  [Esc]"
	leave.pressed.connect(close)
	list.add_child(leave)


func _bought(error: String, name: String) -> String:
	return error if error != "" else "Mua %s." % name.to_lower()


func _row(text: String, action: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := UiStyle.label(text, 19)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(l)
	var b := Button.new()
	b.text = action
	b.custom_minimum_size = Vector2(90, 0)
	row.add_child(b)
	return row
