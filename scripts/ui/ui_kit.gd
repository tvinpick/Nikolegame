class_name UIKit
extends RefCounted
## Shared children's-book UI: soft rounded panels, big round icon buttons,
## readable fonts with Cyrillic/Latin/German glyphs (Inter, OFL).

const FONT_BOLD := preload("res://assets/fonts/Inter-Bold.otf")
const FONT := preload("res://assets/fonts/Inter-SemiBold.otf")
const PINK := Color("#f39bb8")
const PINK_D := Color("#d9708f")
const MINT := Color("#8fd3b8")
const SKY := Color("#8ec9e8")
const SUN := Color("#f6c955")
const LILAC := Color("#b9a2ea")
const PAPER := Color("#fffaf3")
const INK := Color("#5b4250")

static var _theme: Theme = null


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = FONT
	t.default_font_size = 30
	var panel := StyleBoxFlat.new()
	panel.bg_color = PAPER
	panel.set_corner_radius_all(34)
	panel.shadow_color = Color(0.45, 0.25, 0.3, 0.18)
	panel.shadow_size = 14
	panel.shadow_offset = Vector2(0, 6)
	panel.border_color = Color("#f6d5e0")
	panel.set_border_width_all(4)
	panel.set_content_margin_all(22)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var b := StyleBoxFlat.new()
		b.bg_color = {"normal": PINK, "hover": PINK.lightened(0.08), "pressed": PINK_D, "focus": PINK, "disabled": Color("#d9cfd3")}[state]
		b.set_corner_radius_all(28)
		b.set_content_margin_all(14)
		b.content_margin_left = 26
		b.content_margin_right = 26
		b.shadow_color = Color(0.4, 0.2, 0.3, 0.2)
		b.shadow_size = 0 if state == "pressed" else 6
		b.shadow_offset = Vector2(0, 4)
		if state == "focus":
			b.draw_center = false
			b.shadow_size = 0
		t.set_stylebox(state, "Button", b)
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_font("font", "Button", FONT_BOLD)
	t.set_font_size("font_size", "Button", 30)
	t.set_color("font_color", "Label", INK)
	t.set_font_size("font_size", "Label", 30)
	var sl := StyleBoxFlat.new()
	sl.bg_color = Color("#f6dce5")
	sl.set_corner_radius_all(12)
	sl.content_margin_top = 10
	sl.content_margin_bottom = 10
	t.set_stylebox("slider", "HSlider", sl)
	var grab := StyleBoxFlat.new()
	grab.bg_color = PINK
	grab.set_corner_radius_all(12)
	t.set_stylebox("grabber_area", "HSlider", grab)
	t.set_stylebox("grabber_area_highlight", "HSlider", grab)
	var tab := StyleBoxFlat.new()
	tab.bg_color = Color("#fbe7ee")
	tab.set_corner_radius_all(22)
	tab.set_content_margin_all(12)
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var le := StyleBoxFlat.new()
	le.bg_color = Color.WHITE
	le.set_corner_radius_all(16)
	le.set_border_width_all(3)
	le.border_color = Color("#f3c0d0")
	le.set_content_margin_all(12)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("normal", "TextEdit", le)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_color", "TextEdit", INK)
	t.set_font_size("font_size", "CheckButton", 28)
	t.set_color("font_color", "CheckButton", INK)
	t.set_color("font_color", "CheckBox", INK)
	t.set_font_size("font_size", "CheckBox", 26)
	_theme = t
	return t


static func label(text: String, size := 30, color := INK, bold := false, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", FONT_BOLD)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 300
	return l


static func button(text: String, cb: Callable, color := PINK, min_w := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	if color != PINK:
		for state in ["normal", "hover", "pressed"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(state, "Button").duplicate() if b.has_theme_stylebox(state, "Button") else theme().get_stylebox(state, "Button").duplicate()
			sb.bg_color = color if state != "pressed" else color.darkened(0.15)
			b.add_theme_stylebox_override(state, sb)
	b.custom_minimum_size = Vector2(min_w, 84)
	b.pressed.connect(func():
		AudioSvc.sfx("pop")
		cb.call())
	return b


static func icon_button(icon: String, cb: Callable, color := PINK, size := 112.0, tip := "") -> IconButton:
	var b := IconButton.new()
	b.icon_name = icon
	b.bg = color
	# grey-ish colours are used for "not selected" tabs all over the UI
	b.dim = color.s < 0.16 and color.v > 0.8 and icon not in ["lock", "pic_lock", "eye"]
	b.custom_minimum_size = Vector2(size, size)
	b.tooltip_text = tip
	b.pressed.connect(func():
		AudioSvc.sfx("pop")
		cb.call())
	return b


static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.theme = theme()
	return p


static func hbox(sep := 16) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep := 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func dim_bg() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.35, 0.2, 0.3, 0.35)
	full_rect(r)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


## Safe-area margins in UI units (notches, gesture bars).
static func safe_margins(ctrl: Control) -> Vector4:
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	var vp := ctrl.get_viewport_rect().size
	if win.x <= 0 or safe.size.x <= 0:
		return Vector4(24, 24, 24, 24)
	var k := vp.x / float(win.x)
	return Vector4(max(24.0, safe.position.x * k), max(18.0, safe.position.y * k), max(24.0, (win.x - safe.end.x) * k), max(18.0, (win.y - safe.end.y) * k))
