class_name ShopScreen
extends Screen
## Illustrated catalog. Flow: pick item -> preview (room / girl / pet, no
## charge) -> confirm purchase (Economy, atomic) -> place or inventory.

const CATS := [
	["furniture", "cat_furniture", "sit"],
	["pets", "cat_pets", "paw"],
	["toys", "cat_toys", "ball"],
	["care", "cat_care", "food"],
	["clothes_girl", "cat_clothes_girl", "dress"],
	["clothes_pet", "cat_clothes_pet", "heart"],
	["wallfloor", "cat_wallfloor", "house"],
	["decor", "cat_decor", "flower"],
	["devices", "cat_devices", "power"],
	["themes", "cat_themes", "window"],
]

var category := "furniture"
var grid: GridContainer
var detail: VBoxContainer   # content of the full-screen item view (null when closed)
var tabs: HBoxContainer
var selected := ""


func _init() -> void:
	screen_name = "shop"
	title_key = "title_shop"


func build() -> void:
	var sc_tabs := ScrollContainer.new()
	sc_tabs.custom_minimum_size = Vector2(0, 116)
	sc_tabs.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs = UIKit.hbox(12)
	sc_tabs.add_child(tabs)
	body.add_child(sc_tabs)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	sc.add_child(grid)
	body.add_child(sc)
	_build_tabs()
	_fill()


func _build_tabs() -> void:
	for c in tabs.get_children():
		c.queue_free()
	for e in CATS:
		var b := UIKit.icon_button(e[2], _set_cat.bind(e[0]), UIKit.PINK if e[0] == category else Color("#e9c9d5"), 100)
		b.tooltip_text = Loc.t(e[1])
		tabs.add_child(b)


func _set_cat(c: String) -> void:
	category = c
	selected = ""
	_build_tabs()
	_fill()


func _items() -> Array:
	var out: Array = []
	if category == "pets":
		out = Content.items_in_category("breeds") + Content.items_in_category("pets")
	else:
		out = Content.items_in_category(category)
	return out


func _fill() -> void:
	for c in grid.get_children():
		c.queue_free()
	for it in _items():
		var id: String = it["item_id"]
		grid.add_child(Screen.item_card(id, _select.bind(id), _badge(id), id == selected))


func _badge(id: String) -> String:
	var it := Content.item(id)
	if it.get("consumable", false):
		var n := int(GameState.data["consumables"].get(id, 0))
		return ("×%d  " % n if n > 0 else "") + Screen.price_badge(id)
	if GameState.owned_count(id) > 0:
		return Loc.t("owned_badge") + (" ×%d" % GameState.owned_count(id) if it.get("category") not in Economy.UNIQUE_OWN_CATEGORIES else "")
	return Screen.price_badge(id)


## Tapping an item opens it big, over the whole screen, with just two
## buttons at the bottom: back (arrow) and buy / place / put on.
func _select(id: String) -> void:
	selected = id
	_show_item_view()


func _close_item_view() -> void:
	AudioSvc.sfx("pop")
	if detail and is_instance_valid(detail):
		detail.get_parent().queue_free()
	detail = null
	selected = ""
	_fill()


func _show_item_view() -> void:
	if detail and is_instance_valid(detail):
		detail.get_parent().queue_free()
	var view := Control.new()
	view.name = "ItemView"
	UIKit.full_rect(view)
	add_child(view)
	var bg := ColorRect.new()
	bg.color = Color("#fdf0f4")
	UIKit.full_rect(bg)
	view.add_child(bg)
	var m := UIKit.safe_margins(self)
	detail = UIKit.vbox(18)
	detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail.offset_left = m.x + 40
	detail.offset_right = -m.z - 40
	detail.offset_top = m.y + 30
	detail.offset_bottom = -m.w - 30
	view.add_child(detail)
	var pv := ItemPreview.new()
	pv.setup(selected, true)
	pv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(pv)
	var price := Content.price(selected)
	var owned := GameState.owned_count(selected)
	var info_txt: String = Loc.t("price_n", [price]) if price > 0 else Loc.t("free")
	if owned > 0:
		info_txt += "   ·   " + Loc.t("owned_n", [owned])
	var info := UIKit.label(info_txt, 40, UIKit.INK, true)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_child(info)
	var bar := UIKit.hbox(40)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(UIKit.icon_button("back", _close_item_view, Color("#c9a8ec"), 130))
	var act := _primary_action()
	if act.is_empty():
		var l := UIKit.label(Loc.t("msg_not_enough", [price - GameState.coins()]), 34, Color("#c25a78"), true)
		bar.add_child(l)
	else:
		var b := UIKit.button(act["text"], act["cb"], act["color"], 520)
		b.custom_minimum_size.y = 130
		b.add_theme_font_size_override("font_size", 46)
		bar.add_child(b)
	detail.add_child(bar)


## What the big button does for the selected item: {text, cb, color}, or {} if it can't be bought.
func _primary_action() -> Dictionary:
	var it := Content.item(selected)
	var price := Content.price(selected)
	var owned := GameState.owned_count(selected)
	var can := Economy.can_buy(selected)
	var cat: String = it.get("category", "")
	var placeable: bool = it.get("placement", "none") not in ["none", "fixed"]
	if placeable:
		if GameState.stored_count(selected) > 0:
			return {"text": Loc.t("btn_place_owned"), "cb": _place_owned, "color": UIKit.SKY}
		if can == Economy.Result.OK:
			return {"text": Loc.t("btn_buy_for", [price]) if price > 0 else Loc.t("btn_buy"), "cb": _buy_and_place, "color": UIKit.MINT}
		return {}
	if cat in ["clothes_girl", "clothes_pet", "breeds", "wallfloor", "themes"] and owned > 0:
		return {"text": Loc.t("btn_apply"), "cb": _apply_owned, "color": UIKit.SKY}
	if can == Economy.Result.OK:
		return {"text": Loc.t("btn_buy_for", [price]) if price > 0 else Loc.t("btn_buy"), "cb": _buy_direct, "color": UIKit.MINT}
	return {}


## Buy furniture/toys and put them straight into the room (a bed replaces the old one,
## which goes to the chest); then she can move it right away.
func _buy_and_place() -> void:
	var id := selected
	var r := Economy.purchase(id)
	if r == Economy.Result.NOT_ENOUGH_COINS:
		hud.show_toast("msg_not_enough", [Content.price(id) - GameState.coins()])
		return
	if r != Economy.Result.OK:
		hud.show_toast("msg_cant_buy")
		return
	AudioSvc.sfx("sparkle")
	close()
	var n: Node = room.place_owned(id)
	if n == null:
		hud.show_toast("msg_in_inventory")
		return
	hud.show_toast("msg_bought")
	Save.request_save("bought_placed")
	hud.enter_rearrange()
	room.placement.begin(n)
	room.camera.focus(Vector2(n.position.x, room.camera.target_pos.y))


func _preview_in_room() -> void:
	var id := selected
	close()
	hud.begin_preview(id)


func _place_owned() -> void:
	var id := selected
	close()
	var n: Node = room.place_owned(id)
	if n == null:
		hud.show_toast("msg_no_space")
	else:
		hud.enter_rearrange()
		room.placement.begin(n)
		room.camera.focus(Vector2(n.position.x, room.camera.target_pos.y))


func _buy_direct() -> void:
	var r := Economy.purchase(selected)
	if r == Economy.Result.OK:
		hud.show_toast("msg_bought")
		AudioSvc.sfx("sparkle")
		var it := Content.item(selected)
		if it.get("category") in ["breeds", "wallfloor", "themes", "clothes_girl", "clothes_pet"]:
			_apply_owned()
			return
	elif r == Economy.Result.NOT_ENOUGH_COINS:
		hud.show_toast("msg_not_enough", [Content.price(selected) - GameState.coins()])
	_refresh()


## Apply an owned non-placeable item (breed, clothes, wallpaper, landscape).
func _apply_owned() -> void:
	var it := Content.item(selected)
	match it.get("category"):
		"breeds":
			var sp: String = it["species"]
			var pet: Pet = room.cat if sp == "cat" else room.dog
			pet.set_breed(selected)
			GameState.pet(sp)["breed"] = selected
			GameState.pets_changed.emit()
		"wallfloor":
			GameState.data["surfaces"][it.get("surface", "wall")] = selected
			room.apply_surfaces()
		"themes":
			GameState.data["surfaces"]["landscape"] = selected
			room.apply_surfaces()
		"clothes_girl":
			GameState.appearance()[it.get("slot", "outfit")] = selected
			room.girl.apply_appearance(GameState.appearance())
			GameState.appearance_changed.emit()
		"clothes_pet":
			# dog first if it has nothing special, otherwise cat
			var pet2: Pet = room.dog if room.dog.accessory.get("item_id", "") != selected else room.cat
			pet2.set_accessory(selected)
			GameState.pet(pet2.species)["accessory"] = selected
	Save.request_save("apply")
	AudioSvc.sfx("sparkle")
	_refresh()


func _refresh() -> void:
	_fill()
	if selected != "":
		_show_item_view()
