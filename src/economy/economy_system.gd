class_name EconomySystem
extends RefCounted
## Shops, selling and buying (docs/10). Every transaction goes through here.
## Money is counted in thousands of đồng (1 = 1.000đ).
##
## Shop data: { id, npc, name, sells: [{ item, price, qty? }], buys: { categories?, tags? } }
## Shops never buy back what they sell, so there is no buy-cheap-sell-dear loop (docs/10 §18).

const ITEM_SOLD := &"ItemSold"
const ITEM_BOUGHT := &"ItemBought"
const FISH_SOLD := &"FishSold"

var ctx: GameContext


func _init(context: GameContext) -> void:
	ctx = context


static func format_money(amount: int) -> String:
	var n := absi(amount) * 1000
	var digits := str(n)
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if amount < 0 else "") + out + "đ"


func shop(shop_id: String) -> Dictionary:
	return ctx.data.get_def("shops", shop_id)


# --- Selling ---------------------------------------------------------------------

func shop_buys(shop_id: String, item_id: String) -> bool:
	var buys: Dictionary = shop(shop_id).get("buys", {})
	var item := ctx.data.get_item(item_id)
	if item.is_empty():
		return false
	if buys.get("categories", []).has(item.get("category", "")):
		return true
	for tag in buys.get("tags", []):
		if item.get("tags", []).has(tag):
			return true
	return false


## Price the shop pays for one unit of this inventory entry (0 = not for sale).
func sell_price(shop_id: String, entry: Dictionary) -> int:
	if entry.is_empty() or not shop_buys(shop_id, entry["id"]):
		return 0
	var multiplier := float(shop(shop_id).get("buys", {}).get("multiplier", 1.0))
	var fish := ctx.data.get_def("fish", entry["id"])
	if not fish.is_empty():
		var weight := float(entry["props"].get("weight", 0.0))
		var price := weight * float(fish.get("price_per_kg", 0.0)) * freshness(entry) * multiplier
		return maxi(1, int(round(price)))
	return int(round(float(ctx.data.get_item(entry["id"]).get("value", 0)) * multiplier))


## Fresh the same day, cheaper the next, much cheaper after (docs/09 §13).
func freshness(entry: Dictionary) -> float:
	if not entry["props"].has("caught_at"):
		return 1.0
	var age_hours := (ctx.clock.total_minutes() - float(entry["props"]["caught_at"])) / 60.0
	if age_hours < 12.0:
		return 1.0
	if age_hours < 36.0:
		return 0.7
	return 0.4


func freshness_label(entry: Dictionary) -> String:
	var f := freshness(entry)
	return "tươi" if f >= 1.0 else ("hơi cũ" if f >= 0.7 else "cũ")


## Everything in the inventory this shop would buy: [{ entry, price }] (price per unit).
func sellable(shop_id: String) -> Array:
	var result: Array = []
	for entry in ctx.inventory.entries:
		var price := sell_price(shop_id, entry)
		if price > 0:
			result.append({"entry": entry, "price": price})
	return result


## Sells the whole stack/entry. Returns money earned (0 if nothing happened).
func sell(shop_id: String, uid: int) -> int:
	var entry := ctx.inventory.get_entry(uid)
	var unit := sell_price(shop_id, entry)
	if unit <= 0:
		return 0
	var qty := int(entry["qty"])
	var total := unit * qty
	var item_id := str(entry["id"])
	var is_fish := ctx.data.has_def("fish", item_id)
	var weight := float(entry["props"].get("weight", 0.0))
	ctx.inventory.remove_uid(uid)
	ctx.state.add_money(total)
	var first := ctx.state.get_stat("ItemsSold") < 1.0
	ctx.state.add_stat("ItemsSold", qty)
	var event := {"shop": shop_id, "item": item_id, "qty": qty, "price": total, "first": first}
	ctx.bus.emit_event(ITEM_SOLD, event)
	if is_fish:
		var first_fish := ctx.state.get_stat("FishSold") < 1.0
		ctx.state.add_stat("FishSold", 1)
		ctx.bus.emit_event(FISH_SOLD, {"shop": shop_id, "fish": item_id, "weight": weight, "price": total, "first": first_fish})
	return total


func sell_all(shop_id: String) -> int:
	var total := 0
	for s in sellable(shop_id):
		total += sell(shop_id, int(s["entry"]["uid"]))
	return total


# --- Buying ----------------------------------------------------------------------

func stock(shop_id: String) -> Array:
	return shop(shop_id).get("sells", []).filter(func(s): return ctx.conditions.check(s.get("conditions", [])))


func can_afford(price: int) -> bool:
	return ctx.state.money >= price


## Buys one stock line. Returns "" on success, or the reason it failed.
func buy(shop_id: String, item_id: String) -> String:
	for line in stock(shop_id):
		if str(line["item"]) != item_id:
			continue
		var price := int(line["price"])
		if not can_afford(price):
			return "Không đủ tiền. Cần %s." % format_money(price)
		if not ctx.data.get_item(item_id).get("stackable", false) and ctx.inventory.count(item_id) > 0 and not line.get("repeatable", false):
			return "Có một cây rồi."
		ctx.state.add_money(-price)
		var uid := ctx.inventory.add(item_id, int(line.get("qty", 1)))
		ctx.bus.emit_event(ITEM_BOUGHT, {"shop": shop_id, "item": item_id, "price": price, "uid": uid})
		return ""
	return "Tiệm không bán món này."
