class_name WardrobeScreen
extends Screen
## Appearance editor: hair style/colour, eyes, skin, outfit, shoes, hat,
## accessory. Owned clothes apply instantly; locked ones show a price and
## can be bought here (Economy, atomic).

const TABS := [["hair_style", "hand"], ["hair_color", "flower"], ["eye_color", "eye"], ["skin", "heart"], ["outfit", "dress"], ["shoes", "paw"], ["hat", "star"], ["accessory", "necklace_icon"]]

var tab := "outfit"
var preview: GirlPreview
var options: GridContainer
var tabs: HBoxContainer


func _init() -> void:
	screen_name = "wardrobe"
	title_key = "title_wardrobe"


func build() -> void:
	var row := UIKit.hbox(24)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview = GirlPreview.new()
	preview.custom_minimum_size = Vector2(420, 0)
	preview.app = GameState.appearance().duplicate()
	row.add_child(preview)
	var right := UIKit.vbox(14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs = UIKit.hbox(10)
	right.add_child(tabs)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	options = GridContainer.new()
	options.columns = 5
	options.add_theme_constant_override("h_separation", 12)
	options.add_theme_constant_override("v_separation", 12)
	sc.add_child(options)
	right.add_child(sc)
	row.add_child(right)
	body.add_child(row)
	_fill()


func _fill() -> void:
	for c in tabs.get_children():
		c.queue_free()
	for t in TABS:
		var icon: String = t[1] if t[1] != "necklace_icon" else "heart"
		tabs.add_child(UIKit.icon_button(icon, _set_tab.bind(t[0]), UIKit.PINK if tab == t[0] else Color("#e9c9d5"), 92))
	for c in options.get_children():
		c.queue_free()
	var app := GameState.appearance()
	var wd: Dictionary = Content.wardrobe
	match tab:
		"hair_style":
			for st in wd.get("hair_styles", []):
				var a2 := app.duplicate()
				a2["hair_style"] = st
				options.add_child(_app_card(a2, st == app.get("hair_style"), _set_app.bind("hair_style", st)))
		"hair_color", "eye_color", "skin":
			var key: String = {"hair_color": "hair_colors", "eye_color": "eye_colors", "skin": "skin_tones"}[tab]
			for col in wd.get(key, []):
				options.add_child(_color_card(Color(col), col == app.get(tab), _set_app.bind(tab, col)))
		_:
			if tab in ["hat", "accessory"]:
				options.add_child(_none_card(app.get(tab, "none") == "none", _set_app.bind(tab, "none")))
			for it in Content.items_in_category("clothes_girl"):
				if it.get("slot") != tab:
					continue
				var id: String = it["item_id"]
				var owned := GameState.owned_count(id) > 0
				var badge := "" if owned else Screen.price_badge(id)
				options.add_child(Screen.item_card(id, _pick_clothes.bind(id), badge, app.get(tab) == id, 190, 230))


func _app_card(a: Dictionary, sel: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(190, 210)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, Screen.card_style(Color("#fff4f8"), sel))
	var gp := GirlPreview.new()
	gp.app = a
	gp.head_only = true
	gp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(gp)
	b.add_child(gp)
	b.pressed.connect(cb)
	return b


func _color_card(col: Color, sel: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 150)
	var sb := Screen.card_style(col, sel)
	sb.set_corner_radius_all(75)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(cb)
	return b


func _none_card(sel: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(190, 230)
	b.text = "—"
	b.add_theme_color_override("font_color", UIKit.INK)
	b.add_theme_font_size_override("font_size", 60)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, Screen.card_style(Color("#fff4f8"), sel))
	b.pressed.connect(cb)
	return b


func _set_tab(t: String) -> void:
	tab = t
	_fill()


func _set_app(key: String, value: String) -> void:
	AudioSvc.sfx("pop")
	GameState.appearance()[key] = value
	_apply()


func _pick_clothes(id: String) -> void:
	if GameState.owned_count(id) <= 0:
		var r := Economy.purchase(id)
		if r == Economy.Result.NOT_ENOUGH_COINS:
			hud.show_toast("msg_not_enough", [Content.price(id) - GameState.coins()])
			# still let her try it on in the mirror preview (not saved)
			var a := GameState.appearance().duplicate()
			a[tab] = id
			preview.app = a
			preview.queue_redraw()
			return
		if r != Economy.Result.OK:
			return
		AudioSvc.sfx("sparkle")
	GameState.appearance()[tab] = id
	_apply()


func _apply() -> void:
	preview.app = GameState.appearance().duplicate()
	preview.queue_redraw()
	room.girl.apply_appearance(GameState.appearance())
	GameState.appearance_changed.emit()
	Save.request_save("appearance")
	_fill()


class GirlPreview extends Control:
	var app: Dictionary = {}
	var head_only := false
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var outfit := {}
		for slot in ["outfit", "shoes", "hat", "accessory"]:
			var id: String = app.get(slot, "none")
			if Content.has_item(id):
				outfit[slot] = Content.item(id)
		var pose: Dictionary = Girl.POSES["stand"].duplicate()
		pose["fb_arms"] = 2.0 if not head_only else 0.0
		pose["eyes"] = "happy" if fmod(t, 4.0) < 0.3 else "open"
		var s := size
		if head_only:
			var k := s.y / 130.0
			GirlPainter.draw(self, pose, app, outfit, "front", 1.0, 0.0, 0.0, 0.0, 0.0, Vector2(0, 205), Transform2D(0, Vector2(k, k), 0, Vector2(s.x * 0.5, s.y * 0.1)))
		else:
			DrawUtil.ellipse(self, Vector2(s.x * 0.5, s.y * 0.5), s.x * 0.46, s.y * 0.47, Color("#fbe3ec"), false, 0.0)
			var k2 := s.y / 300.0
			GirlPainter.draw(self, pose, app, outfit, "front", 1.0, 0.0, 0.0, 0.0, 0.0, Vector2.ZERO, Transform2D(0, Vector2(k2, k2), 0, Vector2(s.x * 0.5, s.y * 0.92)))
		draw_set_transform(Vector2.ZERO)
