class_name NotebookScreen
extends Screen
## Interactive notebook (scalable UI layer, not a texture in the world).
## Category menu -> 3..5 short exercises -> reward -> back to the room.
## Single-choice answers are checked instantly (no "Answer" button). Wrong
## answers get a soft hint and another try: no timers, no penalties.

const CAT_ICONS := {"math": "apple", "letters": "book", "shapes": "star", "colors": "flower", "logic": "rainbow"}

var page: Control
var prompt_label: Label
var stage := "menu"
var ex: Dictionary = {}
var _busy := false
var _found: Array = []
var _matched: Dictionary = {}
var _basket := 0
var basket_label: Label
var result: Dictionary = {}


func _init() -> void:
	screen_name = "notebook"
	title_key = "title_notebook"


func _ready() -> void:
	super._ready()
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("#fffdf6")
	paper.set_corner_radius_all(30)
	paper.border_color = Color("#e7c9a4")
	paper.set_border_width_all(8)
	paper.shadow_color = Color(0.4, 0.25, 0.2, 0.25)
	paper.shadow_size = 18
	paper.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", paper)
	Learning.session_finished.connect(_on_finished)


func build() -> void:
	page = Control.new()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(page)
	_show_menu()


func _clear() -> void:
	for c in page.get_children():
		c.queue_free()


func _show_menu() -> void:
	stage = "menu"
	_clear()
	var v := UIKit.vbox(30)
	UIKit.full_rect(v)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := UIKit.label(Loc.tl("learn_pick", Loc.learn_lang), 44, UIKit.INK, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var h := UIKit.hbox(34)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var cols := [UIKit.PINK, UIKit.SKY, UIKit.SUN, UIKit.MINT, UIKit.LILAC]
	var i := 0
	for cat in ExerciseGen.CATEGORIES:
		var col := UIKit.vbox(8)
		var b := UIKit.icon_button(CAT_ICONS[cat], _start.bind(cat), cols[i], 190)
		col.add_child(b)
		var l := UIKit.label(Loc.tl("learn_" + cat, Loc.learn_lang), 30, UIKit.INK, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		col.add_child(l)
		var lv := UIKit.label("★".repeat(Learning.level_of(cat)), 28, Color("#e2a92e"))
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lv)
		h.add_child(col)
		i += 1
	v.add_child(h)
	page.add_child(v)
	AudioSvc.say("learn_pick", Loc.learn_lang)


func _start(cat: String) -> void:
	Learning.start_session(cat)
	_next()


func _next() -> void:
	ex = Learning.current_exercise()
	if ex.is_empty():
		return
	stage = "exercise"
	_busy = false
	_found = []
	_matched = {}
	_basket = 0
	_clear()
	var v := UIKit.vbox(22)
	UIKit.full_rect(v)
	page.add_child(v)
	# progress + prompt
	var top := UIKit.hbox(18)
	var cur: Dictionary = Learning.current
	var dots := UIKit.label("", 36, UIKit.PINK, true)
	var s := ""
	for k in cur["exercises"].size():
		s += "●" if k < int(cur["index"]) else ("◉" if k == int(cur["index"]) else "○")
	dots.text = s
	dots.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(dots)
	prompt_label = UIKit.label(_prompt_text(), 40, UIKit.INK, true)
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(prompt_label)
	top.add_child(UIKit.icon_button("note", _speak, UIKit.SKY, 96))
	v.add_child(top)
	match ex["type"]:
		"choose":
			_build_choose(v)
		"drag_count":
			_build_drag_count(v)
		"drag_match":
			_build_drag_match(v)
		"tap_all":
			_build_tap_all(v)
	_speak()


func _prompt_text() -> String:
	var args: Array = []
	for a in ex.get("prompt_args", []):
		if typeof(a) == TYPE_STRING and (str(a).begins_with("shape_") or str(a).begins_with("color_")):
			args.append(Loc.tl(a, Loc.learn_lang))
		else:
			args.append(a)
	return Loc.tl(ex["prompt"], Loc.learn_lang, args)


func _speak() -> void:
	var text := _prompt_text()
	if ex.has("speak_word"):
		text += " " + str(ex["speak_word"])
	AudioSvc.say_text(text, Loc.learn_lang)


# ---------------------------------------------------------------- choose

func _build_choose(v: VBoxContainer) -> void:
	var scene := ExerciseCanvas.new()
	scene.items = ex.get("items", [])
	scene.custom_minimum_size = Vector2(0, 280)
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scene)
	var h := UIKit.hbox(30)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	for o in ex["options"]:
		var b := OptionCard.new()
		b.opt = o
		b.custom_minimum_size = Vector2(230 if o.has("count") else 190, 190)
		b.pressed.connect(_choose.bind(b))
		h.add_child(b)
	v.add_child(h)


func _choose(b: OptionCard) -> void:
	if _busy:
		return
	var r := Learning.answer(b.opt["id"])
	if r["correct"]:
		_correct(b)
	else:
		_wrong(b)


func _correct(node: Control) -> void:
	_busy = true
	AudioSvc.sfx("correct")
	if node:
		var tw := create_tween()
		tw.tween_property(node, "scale", Vector2(1.12, 1.12), 0.15)
		tw.tween_property(node, "scale", Vector2.ONE, 0.15)
		if node is OptionCard:
			node.state = "good"
	AudioSvc.say(["praise_1", "praise_2", "praise_3"][randi() % 3], Loc.learn_lang)
	await get_tree().create_timer(1.1, false).timeout
	if not is_inside_tree():
		return
	if Learning.current.get("done", false):
		_show_result()
	else:
		_next()


func _wrong(node: Control) -> void:
	AudioSvc.sfx("hint")
	AudioSvc.say("try_again", Loc.learn_lang)
	if node:
		var x := node.position.x
		var tw := create_tween()
		for k in 3:
			tw.tween_property(node, "position:x", x + 12, 0.05)
			tw.tween_property(node, "position:x", x - 12, 0.05)
		tw.tween_property(node, "position:x", x, 0.05)


# ---------------------------------------------------------------- drag count (berries into basket)

func _build_drag_count(v: VBoxContainer) -> void:
	var area := Control.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.custom_minimum_size = Vector2(0, 460)
	v.add_child(area)
	var basket := Basket.new()
	basket.name = "Basket"
	area.add_child(basket)
	basket_label = UIKit.label("0", 60, UIKit.INK, true)
	area.add_child(basket_label)
	var total := int(ex["items"][0]["count"])
	await get_tree().process_frame
	var w := area.size.x
	var h := area.size.y
	basket.position = Vector2(w * 0.62, h * 0.25)
	basket.size = Vector2(w * 0.32, h * 0.6)
	basket_label.position = basket.position + Vector2(basket.size.x * 0.42, -70)
	for k in total:
		var p := DragPiece.new()
		p.icon = ex["items"][0]["icon"]
		p.size = Vector2(100, 100)
		p.home = Vector2(40 + (k % 4) * 120, 30 + int(k / 4) * 120)
		p.position = p.home
		p.dropped.connect(_on_berry_dropped.bind(p, basket))
		area.add_child(p)
	var done := UIKit.icon_button("check", _check_count, UIKit.MINT, 130)
	done.position = Vector2(w * 0.62 + basket.size.x * 0.35, h - 130)
	area.add_child(done)


func _on_berry_dropped(p: DragPiece, basket: Control) -> void:
	var in_basket := basket.get_global_rect().has_point(p.get_global_rect().get_center())
	if in_basket and not p.placed:
		p.placed = true
		_basket += 1
		AudioSvc.sfx("pop")
	elif not in_basket and p.placed:
		p.placed = false
		_basket -= 1
	if not in_basket:
		p.go_home()
	basket_label.text = str(_basket)


func _check_count() -> void:
	if _busy:
		return
	var r := Learning.answer(_basket)
	if r["correct"]:
		_correct(basket_label)
	else:
		_wrong(basket_label)
		AudioSvc.say_text(Loc.tl("hint_count", Loc.learn_lang, [int(ex["answer"]), _basket]), Loc.learn_lang)


# ---------------------------------------------------------------- shapes into outlines

func _build_drag_match(v: VBoxContainer) -> void:
	var area := Control.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.custom_minimum_size = Vector2(0, 460)
	v.add_child(area)
	await get_tree().process_frame
	var w := area.size.x
	var h := area.size.y
	var slots: Array = ex["items"]
	var n := slots.size()
	var slot_nodes := {}
	for k in n:
		var s := ShapeSlot.new()
		s.shape = slots[k]["shape"]
		s.slot_id = slots[k]["id"]
		s.size = Vector2(170, 170)
		s.position = Vector2(w * (k + 0.5) / n - 85, 10)
		area.add_child(s)
		slot_nodes[s.slot_id] = s
	var pieces: Array = ex["options"]
	for k in pieces.size():
		var p := DragPiece.new()
		p.shape = pieces[k]["shape"]
		p.color = Color(pieces[k]["color"])
		p.piece_id = pieces[k]["id"]
		p.size = Vector2(150, 150)
		p.home = Vector2(w * (k + 0.5) / pieces.size() - 75, h - 170)
		p.position = p.home
		p.dropped.connect(_on_shape_dropped.bind(p, slot_nodes))
		area.add_child(p)


func _on_shape_dropped(p: DragPiece, slot_nodes: Dictionary) -> void:
	if _busy:
		return
	for sid in slot_nodes.keys():
		var s: ShapeSlot = slot_nodes[sid]
		if s.get_global_rect().grow(20).has_point(p.get_global_rect().get_center()) and not s.filled:
			if ExerciseGen.check_step(ex, p.piece_id, sid):
				s.filled = true
				s.fill_color = p.color
				s.queue_redraw()
				p.visible = false
				_matched[p.piece_id] = sid
				AudioSvc.sfx("pop")
				if _matched.size() == ex["answer"].size():
					var r := Learning.answer(_matched)
					if r["correct"]:
						_correct(null)
				return
			else:
				Learning.note_wrong_step()
				AudioSvc.sfx("hint")
				s.wiggle()
	p.go_home()


# ---------------------------------------------------------------- tap all of a colour

func _build_tap_all(v: VBoxContainer) -> void:
	var h := HFlowContainer.new()
	h.alignment = FlowContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("h_separation", 30)
	h.add_theme_constant_override("v_separation", 30)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for o in ex["options"]:
		var b := OptionCard.new()
		b.opt = o
		b.custom_minimum_size = Vector2(190, 190)
		b.pressed.connect(_tap_one.bind(b))
		h.add_child(b)
	v.add_child(h)


func _tap_one(b: OptionCard) -> void:
	if _busy or b.state == "good":
		return
	if ExerciseGen.check_step(ex, b.opt["id"], ""):
		b.state = "good"
		_found.append(b.opt["id"])
		AudioSvc.sfx("pop")
		if _found.size() == ex["answer"].size():
			var r := Learning.answer(_found)
			if r["correct"]:
				_correct(b)
	else:
		Learning.note_wrong_step()
		_wrong(b)


# ---------------------------------------------------------------- result

func _on_finished(r: Dictionary) -> void:
	result = r


func _show_result() -> void:
	stage = "result"
	_clear()
	var v := UIKit.vbox(26)
	UIKit.full_rect(v)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var stars := ResultStars.new()
	stars.custom_minimum_size = Vector2(0, 260)
	v.add_child(stars)
	var t := UIKit.label(Loc.tl("learn_done", Loc.learn_lang), 48, UIKit.INK, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var coins := int(result.get("coins", 0))
	var l := UIKit.label(Loc.t("learn_reward", [coins]) if coins > 0 else Loc.t("learn_reward_none"), 40, Color("#c98a2e"), true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var h := UIKit.hbox(30)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(UIKit.icon_button("book", _show_menu, UIKit.SKY, 150))
	h.add_child(UIKit.icon_button("house", close, UIKit.PINK, 150))
	v.add_child(h)
	page.add_child(v)
	AudioSvc.sfx("yay")
	AudioSvc.say("learn_done", Loc.learn_lang)


func close() -> void:
	Learning.abort()
	super.close()


# ---------------------------------------------------------------- widgets

class ExerciseCanvas extends Control:
	var items: Array = []

	func _draw() -> void:
		var n := items.size()
		if n == 0:
			return
		var s := size
		var slot_w := s.x / n
		for k in n:
			var it: Dictionary = items[k]
			var c := Vector2(slot_w * (k + 0.5), s.y * 0.45)
			if it.get("q", false):
				DrawUtil.rrect(self, Rect2(c - Vector2(60, 60), Vector2(120, 120)), 24, Color("#fdeef3"), true, 0.0)
				var f := UIKit.FONT_BOLD
				draw_string(f, c + Vector2(-18, 28), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 80, UIKit.PINK)
			elif it.has("op"):
				draw_string(UIKit.FONT_BOLD, c + Vector2(-22, 30), str(it["op"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 90, UIKit.INK)
			elif it.has("shape"):
				IconPainter.draw_shape(self, it["shape"], c, min(slot_w * 0.8, 170.0), Color(it.get("color", "#8fb3e8")))
			elif it.has("icon"):
				var cnt := int(it.get("count", 1))
				_draw_group(it["icon"], cnt, c, min(slot_w * 0.95, 520.0), s.y * 0.8)
				if it.has("caption"):
					var cap := str(it["caption"]).to_upper()
					var f2 := UIKit.FONT_BOLD
					var tw := f2.get_string_size(cap, HORIZONTAL_ALIGNMENT_CENTER, -1, 54).x
					draw_string(f2, Vector2(c.x - tw / 2, s.y - 6), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, UIKit.INK)

	func _draw_group(icon: String, cnt: int, c: Vector2, w: float, h: float) -> void:
		var cols := int(ceil(sqrt(float(cnt)) * 1.4)) if cnt > 1 else 1
		cols = clampi(cols, 1, 5)
		var rows := int(ceil(float(cnt) / cols))
		var cell: float = min(w / cols, h / max(rows, 1) * 0.9, 140.0)
		for i in cnt:
			var col := i % cols
			var row := i / cols
			var p := c + Vector2((col - (cols - 1) * 0.5) * cell, (row - (rows - 1) * 0.5) * cell)
			IconPainter.draw_icon(self, icon, p, cell * 0.85)


class OptionCard extends Button:
	var opt: Dictionary = {}
	var state := "":
		set(v):
			state = v
			queue_redraw()

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		for st in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())
		pivot_offset = custom_minimum_size * 0.5

	func _draw() -> void:
		var r := Rect2(Vector2(6, 6), size - Vector2(12, 12))
		DrawUtil.rrect(self, r, 30, Color("#e3f6ee") if state == "good" else Color("#fff1f6"), true, 0.04)
		var c := size * 0.5
		var s: float = min(size.x, size.y) * 0.62
		if opt.has("count"):
			var cnt := int(opt["count"])
			var cols := clampi(int(ceil(sqrt(float(cnt)))), 1, 4)
			var rows := int(ceil(float(cnt) / cols))
			var cell: float = min((size.x - 30) / cols, (size.y - 30) / rows)
			for i in cnt:
				var p := c + Vector2((i % cols - (cols - 1) * 0.5) * cell, (i / cols - (rows - 1) * 0.5) * cell)
				IconPainter.draw_icon(self, opt.get("icon", "apple"), p, cell * 0.85)
		elif opt.has("shape"):
			IconPainter.draw_shape(self, opt["shape"], c, s, Color(opt.get("color", "#8fb3e8")))
		elif opt.has("icon"):
			IconPainter.draw_icon(self, opt["icon"], c, s)
		elif opt.has("text"):
			var f := UIKit.FONT_BOLD
			var t := str(opt["text"])
			var fs := 100
			var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
			draw_string(f, Vector2(c.x - tw / 2, c.y + fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIKit.INK)
		if state == "good":
			IconPainter.draw_icon(self, "check", size - Vector2(36, 36), 50, Color("#4caf7a"))
			draw_circle(size - Vector2(36, 36), 24, Color(0.3, 0.75, 0.5, 0.9))
			IconPainter._ui_icon(self, "check", size - Vector2(36, 36), 20, Color.WHITE)


class DragPiece extends Control:
	signal dropped()
	var icon := ""
	var shape := ""
	var color := Color.WHITE
	var piece_id := ""
	var home := Vector2.ZERO
	var placed := false
	var _drag := false
	var _off := Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_drag = true
				_off = e.position
				move_to_front()
				scale = Vector2(1.1, 1.1)
			elif _drag:
				_drag = false
				scale = Vector2.ONE
				dropped.emit()
			accept_event()
		elif e is InputEventMouseMotion and _drag:
			position += e.relative
			accept_event()

	func go_home() -> void:
		var tw := create_tween()
		tw.tween_property(self, "position", home if not placed else position, 0.25).set_trans(Tween.TRANS_BACK)

	func _draw() -> void:
		var c := size * 0.5
		if shape != "":
			IconPainter.draw_shape(self, shape, c, size.x * 0.9, color)
		else:
			IconPainter.draw_icon(self, icon, c, size.x * 0.85)


class Basket extends Control:
	func _draw() -> void:
		var s := size
		var body := PackedVector2Array([Vector2(0, s.y * 0.35), Vector2(s.x, s.y * 0.35), Vector2(s.x * 0.86, s.y), Vector2(s.x * 0.14, s.y)])
		draw_arc(Vector2(s.x * 0.5, s.y * 0.35), s.x * 0.38, PI, TAU, 24, Color("#b98159"), 14, true)
		DrawUtil.poly(self, body, Color("#e2b37c"))
		for i in 5:
			var y := s.y * (0.45 + i * 0.12)
			draw_line(Vector2(s.x * (0.04 + i * 0.02), y), Vector2(s.x * (0.96 - i * 0.02), y), Color("#c4915e"), 4)


class ShapeSlot extends Control:
	var shape := "circle"
	var slot_id := ""
	var filled := false
	var fill_color := Color.WHITE

	func wiggle() -> void:
		var x := position.x
		var tw := create_tween()
		tw.tween_property(self, "position:x", x + 10, 0.05)
		tw.tween_property(self, "position:x", x - 10, 0.05)
		tw.tween_property(self, "position:x", x, 0.05)

	func _draw() -> void:
		var c := size * 0.5
		if filled:
			IconPainter.draw_shape(self, shape, c, size.x * 0.9, fill_color)
		else:
			IconPainter.draw_outline_shape(self, shape, c, size.x * 0.9, Color("#b9a2ea"))


class ResultStars extends Control:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		for i in 3:
			var p := c + Vector2((i - 1) * 170, -abs(i - 1) * -30 - 10)
			var k: float = clampf(t * 2.5 - i * 0.4, 0.0, 1.0)
			var r := 70.0 * (0.6 + 0.4 * ease(k, -2.0)) * (1.0 + 0.05 * sin(t * 4.0 + i))
			if k > 0:
				DrawUtil.poly(self, DrawUtil.star_points(p, r, r * 0.45), Color("#f7cf46"))
