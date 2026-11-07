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
var detail: VBoxContainer
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
	var row := UIKit.hbox(20)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_stretch_ratio = 1.6
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	sc.add_child(grid)
	row.add_child(sc)
	var dp := PanelContainer.new()
	dp.add_theme_stylebox_override("panel", Screen.card_style(Color("#fdf0f4")))
	dp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail = UIKit.vbox(14)
	dp.add_child(detail)
	row.add_child(dp)
	body.add_child(row)
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
	var cat_label: String = ""
	for e in CATS:
		if e[0] == category:
			cat_label = Loc.t(e[1])
	for it in _items():
		var id: String = it["item_id"]
		grid.add_child(Screen.item_card(id, _select.bind(id), _badge(id), id == selected))
	_show_detail(cat_label)


func _badge(id: String) -> String:
	var it := Content.item(id)
	if it.get("consumable", false):
		var n := int(GameState.data["consumables"].get(id, 0))
		return ("×%d  " % n if n > 0 else "") + Screen.price_badge(id)
	if GameState.owned_count(id) > 0:
		return Loc.t("owned_badge") + (" ×%d" % GameState.owned_count(id) if it.get("category") not in Economy.UNIQUE_OWN_CATEGORIES else "")
	return Screen.price_badge(id)


func _select(id: String) -> void:
	selected = id
	_fill()


func _show_detail(cat_label: String) -> void:
	for c in detail.get_children():
		c.queue_free()
	if selected == "":
		detail.add_child(UIKit.label(cat_label, 36, UIKit.INK, true))
		detail.add_child(UIKit.label(Loc.t("shop_pick_hint"), 28, UIKit.INK, false, true))
		return
	var it := Content.item(selected)
	var pv := ItemPreview.new()
	pv.setup(selected, true)
	pv.custom_minimum_size = Vector2(0, 320)
	detail.add_child(pv)
	var price := Content.price(selected)
	var owned := GameState.owned_count(selected)
	var info := UIKit.label(Loc.t("price_n", [price]) if price > 0 else Loc.t("free"), 34, UIKit.INK, true)
	detail.add_child(info)
	if owned > 0:
		detail.add_child(UIKit.label(Loc.t("owned_n", [owned]), 28))
	var can := Economy.can_buy(selected)
	var cat: String = it.get("category", "")
	var placeable: bool = it.get("placement", "none") not in ["none", "fixed"]
	if placeable:
		if can == Economy.Result.OK:
			detail.add_child(UIKit.button(Loc.t("btn_try_in_room"), _preview_in_room, UIKit.MINT))
		elif can == Economy.Result.NOT_ENOUGH_COINS:
			detail.add_child(UIKit.label(Loc.t("msg_not_enough", [price - GameState.coins()]), 28, Color("#c25a78")))
		if GameState.stored_count(selected) > 0:
			detail.add_child(UIKit.button(Loc.t("btn_place_owned"), _place_owned, UIKit.SKY))
	elif cat in ["clothes_girl", "clothes_pet", "breeds", "wallfloor", "themes"]:
		if owned > 0:
			detail.add_child(UIKit.button(Loc.t("btn_apply"), _apply_owned, UIKit.SKY))
		elif can == Economy.Result.OK:
			detail.add_child(UIKit.button(Loc.t("btn_buy_for", [price]), _buy_direct, UIKit.MINT))
		else:
			detail.add_child(UIKit.label(Loc.t("msg_not_enough", [price - GameState.coins()]), 28, Color("#c25a78")))
	elif it.get("consumable", false):
		if can == Economy.Result.OK:
			detail.add_child(UIKit.button(Loc.t("btn_buy_for", [price]), _buy_direct, UIKit.MINT))
		else:
			detail.add_child(UIKit.label(Loc.t("msg_not_enough", [price - GameState.coins()]), 28, Color("#c25a78")))


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
	_fill()


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
	_fill()
