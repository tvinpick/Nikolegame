class_name ShopScreen
extends Screen
## Picture shop for a child who can't read yet: 4 big sections on the left
## (furniture, clothes, pets, room), picture sub-sections on top (beds, chairs,
## dresses, cats...), items in a grid. Tapping an item opens it full screen
## with a back arrow and one big buy button. Structure: ShopCatalog.

var section := "furniture"
var subsection := "beds"
var grid: GridContainer
var detail: VBoxContainer   # content of the full-screen item view (null when closed)
var mains: VBoxContainer
var tabs: HBoxContainer
var selected := ""


func _init() -> void:
	screen_name = "shop"
	title_key = "title_shop"


func build() -> void:
	var row := UIKit.hbox(18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mains = UIKit.vbox(14)
	row.add_child(mains)
	var right := UIKit.vbox(12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sc_tabs := ScrollContainer.new()
	sc_tabs.custom_minimum_size = Vector2(0, 178)
	sc_tabs.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs = UIKit.hbox(12)
	sc_tabs.add_child(tabs)
	right.add_child(sc_tabs)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid = GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	sc.add_child(grid)
	right.add_child(sc)
	row.add_child(right)
	body.add_child(row)
	_build_tabs()
	_fill()


## Opens the shop straight at a section / sub-section (e.g. from a hint).
func open_at(sec: String, sub: String = "") -> void:
	section = sec
	subsection = sub if sub != "" else ShopCatalog.section(sec)["subs"][0]["id"]
	if tabs:
		_build_tabs()
		_fill()


func _build_tabs() -> void:
	for c in mains.get_children():
		c.queue_free()
	for s in ShopCatalog.SECTIONS:
		var on: bool = s["id"] == section
		mains.add_child(_pic_tab(s, Color(s["color"]), on, Vector2(170, 150), "shop_main_" + s["id"], _set_section.bind(s["id"])))
	for c in tabs.get_children():
		c.queue_free()
	var sec := ShopCatalog.section(section)
	for sb in sec["subs"]:
		var on2: bool = sb["id"] == subsection
		tabs.add_child(_pic_tab(sb, Color(sec["color"]), on2, Vector2(150, 160), "shop_sub_" + sb["id"], _set_sub.bind(sb["id"])))


## A picture tab: a button picture from the owner's sheet (or the item itself),
## a small word under it for grown-ups; the chosen one is big with a thick frame.
func _pic_tab(e: Dictionary, col: Color, on: bool, sz: Vector2, key: String, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = sz
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.0) if not on else col.lightened(0.55)
	sb.set_corner_radius_all(30)
	sb.border_color = col.darkened(0.05)
	sb.set_border_width_all(6 if on else 0)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, sb)
	var tex := ShopCatalog.pic_tex(e.get("pic", ""))
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = 8
		tr.offset_right = -8
		tr.offset_top = 6
		tr.offset_bottom = -30
		tr.modulate = Color.WHITE if on else Color(1, 1, 1, 0.8)
		b.add_child(tr)
	elif e.has("icon"):
		var ic := IconButton.new()
		ic.icon_name = e["icon"]
		ic.bg = col.lightened(0.45)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = sz.x * 0.12
		ic.offset_right = -sz.x * 0.12
		ic.offset_top = 6
		ic.offset_bottom = -30
		b.add_child(ic)
	else:
		# a real item as the picture (cats, dogs, wallpapers...) on a soft card
		var card := Panel.new()
		var cs := StyleBoxFlat.new()
		cs.bg_color = col.lightened(0.7)
		cs.set_corner_radius_all(26)
		cs.border_color = Color.WHITE
		cs.set_border_width_all(4)
		card.add_theme_stylebox_override("panel", cs)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.offset_left = 12
		card.offset_right = -12
		card.offset_top = 8
		card.offset_bottom = -32
		b.add_child(card)
		var pv := ItemPreview.new()
		pv.setup(e.get("rep", ""))
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pv.offset_left = 16
		pv.offset_right = -16
		pv.offset_top = 10
		pv.offset_bottom = -34
		b.add_child(pv)
	var l := UIKit.label(Loc.t(key), 22 if not on else 24, UIKit.INK if on else Color(UIKit.INK, 0.7), true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.clip_text = true
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_top = -30
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	b.pressed.connect(func():
		AudioSvc.sfx("pop")
		cb.call())
	return b


func _set_section(s: String) -> void:
	section = s
	subsection = ShopCatalog.section(s)["subs"][0]["id"]
	selected = ""
	_build_tabs()
	_fill()


func _set_sub(s: String) -> void:
	subsection = s
	selected = ""
	_build_tabs()
	_fill()


func _items() -> Array:
	return ShopCatalog.items_in(section, subsection)


func _fill() -> void:
	for c in grid.get_children():
		c.queue_free()
	for it in _items():
		var id: String = it["item_id"]
		grid.add_child(Screen.item_card(id, _select.bind(id), _badge(id), id == selected, 196, 210))


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
