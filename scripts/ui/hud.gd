class_name HUD
extends Control
## In-room interface: coins, daily chest, hideable side menu, contextual action
## icons for the tapped object, pet needs panel (shown only after tapping a
## pet), rearrange and shop-preview toolbars, toasts.

signal open_screen(name: String)

var room: Room
var coins_box: HBoxContainer
var coins_label: Label
var chest_btn: IconButton
var side: VBoxContainer
var side_toggle: IconButton       # parent-area lock (small, top-right corner)
var side_plate: PanelContainer
var eye_btn: IconButton
var context: HBoxContainer
var pet_panel: PanelContainer
var rearrange_bar: PanelContainer
var preview_bar: PanelContainer
var inventory_row: HBoxContainer
var toast: Label
var _toast_t := 0.0
var _pet: Pet = null
var _need_bars: Dictionary = {}
var _hidden := false
var preview_item := ""
var _preview_buy: Button
var hint: Control


func _ready() -> void:
	theme = UIKit.theme()
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	GameState.coins_changed.connect(func(_c): _refresh_coins())
	GameState.inventory_changed.connect(_refresh_inventory)
	Loc.ui_language_changed.connect(func(_l): _refresh_texts())
	_refresh_coins()


func _build() -> void:
	var m := UIKit.safe_margins(self)
	# coins
	coins_box = UIKit.hbox(10)
	coins_box.position = Vector2(m.x, m.y)
	# coin pill picture with the number written inside it
	var coin_panel := TextureRect.new()
	coin_panel.texture = load("res://assets/ui/icons/coin_pill.png")
	coin_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_panel.custom_minimum_size = Vector2(200, 128)
	coin_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coins_label = UIKit.label("0", 44, UIKit.INK, true)
	coins_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coins_label.offset_left = 94
	coins_label.offset_right = -12
	coins_label.offset_bottom = -8
	coin_panel.add_child(coins_label)
	coins_box.add_child(coin_panel)
	chest_btn = UIKit.icon_button("pic_gift", func(): open_screen.emit("chest"), Color("#fff1c7"), 104)
	coins_box.add_child(chest_btn)
	add_child(coins_box)
	# right dock: big colourful picture buttons on a soft white plate
	side = UIKit.vbox(16)
	var dock_bg := StyleBoxFlat.new()
	dock_bg.bg_color = Color(1, 1, 1, 0.55)
	dock_bg.set_corner_radius_all(70)
	dock_bg.set_content_margin_all(12)
	side_plate = PanelContainer.new()
	side_plate.add_theme_stylebox_override("panel", dock_bg)
	side_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side_plate.add_child(side)
	for e in [["pic_shop", "shop", Color("#ffe1ec")], ["pic_dress", "wardrobe_all", Color("#f0e3ff")], ["pic_pets", "pets", Color("#fff0cf")], ["pic_move", "rearrange", Color("#dcf5ea")], ["weather", "weather", Color("#d9eeff")]]:
		var b := UIKit.icon_button(e[0], _on_side.bind(e[1]), e[2], 124)
		b.name = "btn_" + e[1]
		side.add_child(b)
	add_child(side_plate)
	# small grown-up corner: hide UI (eye) and the parent area (lock)
	side_toggle = UIKit.icon_button("pic_lock", _on_side.bind("parent"), Color("#efe9f2"), 70)
	side_toggle.name = "btn_parent"
	add_child(side_toggle)
	eye_btn = UIKit.icon_button("eye", _toggle_hide, Color("#c9b8d8"), 70)
	add_child(eye_btn)
	# context actions
	context = UIKit.hbox(18)
	context.visible = false
	add_child(context)
	# pet panel
	pet_panel = UIKit.panel()
	pet_panel.visible = false
	add_child(pet_panel)
	# rearrange
	rearrange_bar = UIKit.panel()
	rearrange_bar.visible = false
	var rv := UIKit.vbox(10)
	var rb := UIKit.hbox(18)
	rb.add_child(UIKit.icon_button("check", _on_place_confirm, UIKit.MINT, 100))
	rb.add_child(UIKit.icon_button("close", _on_place_cancel, Color("#e8a0a0"), 100))
	rb.add_child(UIKit.icon_button("flip", func(): room.placement.flip(), UIKit.SKY, 100))
	rb.add_child(UIKit.icon_button("undo", _on_undo, UIKit.LILAC, 100))
	rb.add_child(UIKit.icon_button("box", _on_store, UIKit.SUN, 100))
	var done := UIKit.button(Loc.t("btn_done"), _exit_rearrange, UIKit.PINK, 160)
	done.name = "done"
	rb.add_child(done)
	rv.add_child(rb)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(900, 130)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_row = UIKit.hbox(12)
	sc.add_child(inventory_row)
	rv.add_child(sc)
	rearrange_bar.add_child(rv)
	add_child(rearrange_bar)
	# shop preview
	preview_bar = UIKit.panel()
	preview_bar.visible = false
	var pb := UIKit.hbox(20)
	_preview_buy = UIKit.button("", _on_preview_buy, UIKit.MINT, 260)
	pb.add_child(_preview_buy)
	pb.add_child(UIKit.icon_button("flip", func(): room.placement.flip(), UIKit.SKY, 92))
	pb.add_child(UIKit.button(Loc.t("btn_back"), _on_preview_cancel, Color("#e8a0a0"), 200))
	preview_bar.add_child(pb)
	add_child(preview_bar)
	# toast
	toast = UIKit.label("", 34, UIKit.INK, true)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_OFF
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(1, 1, 1, 0.94)
	ts.set_corner_radius_all(28)
	ts.set_content_margin_all(18)
	toast.add_theme_stylebox_override("normal", ts)
	toast.visible = false
	add_child(toast)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	var vs := get_viewport_rect().size
	var m := UIKit.safe_margins(self)
	coins_box.position = Vector2(m.x, m.y)
	side_plate.position = Vector2(vs.x - m.z - 160, maxf(m.y + 96, (vs.y - 760) * 0.5 + 40))
	side_toggle.position = Vector2(vs.x - m.z - 84, m.y + 6)
	eye_btn.position = Vector2(vs.x - m.z - 170, m.y + 6)
	rearrange_bar.position = Vector2((vs.x - 1000) * 0.5, vs.y - m.w - 290)
	rearrange_bar.size = Vector2(1000, 0)
	preview_bar.position = Vector2((vs.x - 700) * 0.5, vs.y - m.w - 130)
	toast.position = Vector2(vs.x * 0.5 - 400, m.y + 110)
	toast.size = Vector2(800, 0)


func _refresh_texts() -> void:
	var done: Button = rearrange_bar.find_child("done", true, false)
	if done:
		done.text = Loc.t("btn_done")


func _refresh_coins() -> void:
	coins_label.text = str(GameState.coins())
	chest_btn.visible = Economy.daily_status()["available"]


func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		toast.modulate.a = clampf(_toast_t * 2.0, 0.0, 1.0)
		if _toast_t <= 0.0:
			toast.visible = false
	if pet_panel.visible and _pet:
		_update_pet_panel()
		_place_near(pet_panel, room.world_to_screen(_pet.ground_point() + Vector2(0, -170)))
	if Engine.get_process_frames() % 60 == 0:
		chest_btn.visible = Economy.daily_status()["available"] and not _hidden


## True if a screen point is over an interactive HUD element.
func is_over_ui(p: Vector2) -> bool:
	for c in [coins_box, side_plate, side_toggle, eye_btn, context, pet_panel, rearrange_bar, preview_bar]:
		if c.visible and c.get_global_rect().has_point(p):
			return true
	return false


func show_toast(key: String, args: Array = []) -> void:
	toast.text = Loc.t(key, args)
	toast.visible = true
	_toast_t = 2.8
	toast.modulate.a = 1.0


func _on_side(name_: String) -> void:
	hide_context()
	if name_ == "rearrange":
		enter_rearrange()
		return
	open_screen.emit(name_)


func _toggle_hide() -> void:
	_hidden = not _hidden
	for c in [coins_box, side_plate, side_toggle]:
		c.visible = not _hidden
	hide_context()
	eye_btn.set_icon("hide" if _hidden else "eye")


# ---------------------------------------------------------------- context menu

func show_furniture_actions(f: Furniture, screen: Vector2) -> void:
	hide_context()
	var g := room.girl
	for a in f.actions_for("girl"):
		if a.has("requires_consumable") and Economy.consumable_count(a["requires_consumable"]) <= 0:
			continue
		if a.get("needs_pet", "") == "cat" and not room.cat.can_join():
			continue
		var b := UIKit.icon_button(a.get("icon", "star"), _on_action.bind(f, a), UIKit.PINK, 120)
		if a.get("device_toggle", false):
			b.bg = UIKit.SUN if not f.is_on() else UIKit.SKY
		context.add_child(b)
	if g.carrying:
		context.add_child(UIKit.icon_button("down", func():
			hide_context()
			g.command({"type": "pet_cmd", "cmd": "putdown", "pet": g.carrying}), UIKit.MINT, 120))
	if context.get_child_count() == 0:
		return
	f.selected = true
	f.queue_redraw()
	context.set_meta("f", f)
	context.visible = true
	context.reset_size()
	await get_tree().process_frame
	_place_near(context, screen + Vector2(0, -150))


func _on_action(f: Furniture, a: Dictionary) -> void:
	hide_context()
	room.girl.command({"type": "use", "f": f, "action": a})


func hide_context() -> void:
	if context.has_meta("f"):
		var f: Variant = context.get_meta("f")
		if f != null and is_instance_valid(f):
			f.selected = false
			f.queue_redraw()
		context.remove_meta("f")
	for c in context.get_children():
		c.queue_free()
	context.visible = false
	pet_panel.visible = false
	_pet = null


func _place_near(c: Control, screen: Vector2) -> void:
	var vs := get_viewport_rect().size
	var sz := c.size
	c.position = Vector2(clampf(screen.x - sz.x * 0.5, 20, vs.x - sz.x - 140), clampf(screen.y - sz.y, 110, vs.y - sz.y - 20))


# ---------------------------------------------------------------- pet panel

func show_pet(p: Pet, _screen: Vector2) -> void:
	hide_context()
	_pet = p
	for c in pet_panel.get_children():
		c.queue_free()
	var v := UIKit.vbox(10)
	var bars := UIKit.hbox(14)
	_need_bars.clear()
	for n in Pet.NEEDS:
		var nb := NeedBar.new()
		nb.need = n
		nb.custom_minimum_size = Vector2(92, 120)
		bars.add_child(nb)
		_need_bars[n] = nb
	v.add_child(bars)
	var cmds := UIKit.hbox(12)
	var g := room.girl
	cmds.add_child(UIKit.icon_button("play", _pet_cmd.bind("play"), UIKit.PINK, 92))
	cmds.add_child(UIKit.icon_button("come", _pet_cmd.bind("come"), UIKit.SKY, 92))
	cmds.add_child(UIKit.icon_button("hand", _pet_cmd.bind("pet"), UIKit.SUN, 92))
	if g.carrying == p:
		cmds.add_child(UIKit.icon_button("down", _pet_cmd.bind("putdown"), UIKit.MINT, 92))
	elif g.carrying == null:
		cmds.add_child(UIKit.icon_button("carry", _pet_cmd.bind("pickup"), UIKit.MINT, 92))
	cmds.add_child(UIKit.icon_button("heart", _pet_cmd.bind("hug"), Color("#f7a8c0"), 92))
	cmds.add_child(UIKit.icon_button("star", _pet_cmd.bind("trick"), UIKit.SUN, 92))
	cmds.add_child(UIKit.icon_button("goto", _pet_cmd.bind("goto"), UIKit.LILAC, 92))
	v.add_child(cmds)
	pet_panel.add_child(v)
	pet_panel.visible = true
	pet_panel.reset_size()
	if p.kind == "cat":
		AudioSvc.sfx("meow", p.position, -4.0)
	else:
		AudioSvc.sfx("bark", p.position, -6.0)


func _update_pet_panel() -> void:
	for n in _need_bars.keys():
		_need_bars[n].value = float(_pet.needs[n])


func _pet_cmd(cmd: String) -> void:
	var p := _pet
	hide_context()
	if p == null:
		return
	match cmd:
		"come":
			if p.can_join():
				p.come_to(room.girl)
			else:
				show_toast("bubble_pet_busy")
		"goto":
			room.pet_goto_pet = p
			room.set_mode("pet_goto")
			show_toast("hint_tap_object")
		_:
			room.girl.command({"type": "pet_cmd", "cmd": cmd, "pet": p})


# ---------------------------------------------------------------- rearrange

func enter_rearrange() -> void:
	room.set_mode("rearrange")
	rearrange_bar.visible = true
	side_plate.visible = false
	side_toggle.visible = false
	_refresh_inventory()
	show_toast("hint_rearrange")


func _exit_rearrange() -> void:
	if room.placement.target:
		if not room.placement.confirm():
			room.placement.cancel()
	room.set_mode("play")
	rearrange_bar.visible = false
	side_plate.visible = true
	side_toggle.visible = true


func _on_place_confirm() -> void:
	if room.placement.target == null:
		return
	if not room.placement.confirm():
		show_toast("msg_cant_place")


func _on_undo() -> void:
	if not room.placement.undo():
		AudioSvc.sfx("hint")


func _on_place_cancel() -> void:
	room.placement.cancel()


func _on_store() -> void:
	if room.placement.target == null:
		show_toast("hint_select_first")
		return
	if room.placement.target is Furniture and room.placement.target.is_fixed():
		return
	room.placement.store_selected()
	_refresh_inventory()


func _refresh_inventory() -> void:
	if inventory_row == null:
		return
	for c in inventory_row.get_children():
		c.queue_free()
	for e in Economy.stored_items():
		var card := Button.new()
		card.custom_minimum_size = Vector2(120, 120)
		var pv := ItemPreview.new()
		pv.setup(e["item_id"])
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIKit.full_rect(pv)
		card.add_child(pv)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#fff4f8")
		sb.set_corner_radius_all(20)
		card.add_theme_stylebox_override("normal", sb)
		card.add_theme_stylebox_override("hover", sb)
		card.add_theme_stylebox_override("pressed", sb)
		if int(e["count"]) > 1:
			card.text = "×%d" % int(e["count"])
			card.add_theme_color_override("font_color", UIKit.INK)
			card.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		card.pressed.connect(_place_from_inventory.bind(e["item_id"]))
		inventory_row.add_child(card)
	if rearrange_bar.visible and Economy.stored_items().is_empty():
		var l := UIKit.label(Loc.t("inventory_empty"), 26)
		inventory_row.add_child(l)


func _place_from_inventory(item_id: String) -> void:
	AudioSvc.sfx("pop")
	var n: Node = room.place_owned(item_id)
	if n == null:
		show_toast("msg_no_space")
	else:
		room.placement.begin(n)
		room.camera.focus(Vector2(n.position.x, room.camera.target_pos.y))
	_refresh_inventory()


# ---------------------------------------------------------------- shop preview

func begin_preview(item_id: String) -> void:
	preview_item = item_id
	if not room.start_preview(item_id):
		return
	_preview_buy.text = Loc.t("btn_buy_for", [Content.price(item_id)])
	preview_bar.visible = true
	side_plate.visible = false
	show_toast("hint_preview")


func _on_preview_buy() -> void:
	if not room.preview_valid():
		show_toast("msg_cant_place")
		return
	var r := Economy.purchase(preview_item)
	if r == Economy.Result.NOT_ENOUGH_COINS:
		show_toast("msg_not_enough", [Content.price(preview_item) - GameState.coins()])
		return
	if r != Economy.Result.OK:
		show_toast("msg_cant_buy")
		return
	var n: Node = room.commit_preview(preview_item)
	show_toast("msg_bought" if n else "msg_in_inventory")
	AudioSvc.sfx("sparkle")
	_end_preview()


func _on_preview_cancel() -> void:
	room.cancel_preview()
	_end_preview()
	open_screen.emit("shop")


func _end_preview() -> void:
	preview_bar.visible = false
	side_plate.visible = true
	preview_item = ""


class NeedBar extends Control:
	var need := "satiety"
	var value := 50.0:
		set(v):
			value = v
			queue_redraw()

	func _draw() -> void:
		var s := size
		var icon: String = {"satiety": "food", "energy": "sleep", "mood": "heart", "cleanliness": "bath"}[need]
		var col: Color = {"satiety": Color("#f6a35c"), "energy": Color("#8ea6f0"), "mood": Color("#f07fa3"), "cleanliness": Color("#7fcfe8")}[need]
		var r := Rect2(s.x * 0.5 - 18, 6, 36, s.y - 62)
		DrawUtil.rrect(self, r, 16, Color("#f3e3e8"), false, 0.0)
		var fh := r.size.y * clampf(value / 100.0, 0.0, 1.0)
		DrawUtil.rrect(self, Rect2(r.position.x, r.end.y - fh, r.size.x, fh), 16, col, false, 0.1)
		draw_circle(Vector2(s.x * 0.5, s.y - 28), 26, col)
		IconPainter.draw_icon(self, icon, Vector2(s.x * 0.5, s.y - 28), 34)
