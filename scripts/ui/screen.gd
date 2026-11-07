class_name Screen
extends Control
## Full-screen book-style overlay with a big close button.

signal closed(screen: Screen)

var screen_name := ""
var title_key := ""
var panel: PanelContainer
var body: VBoxContainer
var room: Room
var hud: HUD


func _ready() -> void:
	theme = UIKit.theme()
	UIKit.full_rect(self)
	add_child(UIKit.dim_bg())
	panel = UIKit.panel()
	add_child(panel)
	var outer := UIKit.vbox(14)
	panel.add_child(outer)
	var head := UIKit.hbox(16)
	var title := UIKit.label(Loc.t(title_key) if title_key != "" else "", 44, UIKit.INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(title)
	head.add_child(UIKit.icon_button("close", close, Color("#e8a0a0"), 92))
	outer.add_child(head)
	body = UIKit.vbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)
	_layout()
	get_viewport().size_changed.connect(_layout)
	build()
	AudioSvc.sfx("page")


func _layout() -> void:
	var vs := get_viewport_rect().size
	var m := UIKit.safe_margins(self)
	panel.position = Vector2(m.x + 30, m.y + 20)
	panel.size = Vector2(vs.x - m.x - m.z - 60, vs.y - m.y - m.w - 40)


func build() -> void:
	pass


func close() -> void:
	closed.emit(self)
	queue_free()


static func card_style(col := Color("#fff4f8"), sel := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(26)
	sb.set_content_margin_all(10)
	if sel:
		sb.border_color = UIKit.PINK
		sb.set_border_width_all(6)
	return sb


static func item_card(id: String, cb: Callable, badge := "", sel := false, w := 210.0, h := 210.0) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(w, h)
	card.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed"]:
		card.add_theme_stylebox_override(st, card_style(Color("#fff4f8") if st != "pressed" else Color("#fde3ec"), sel))
	var pv := ItemPreview.new()
	pv.setup(id)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pv.offset_bottom = -40
	card.add_child(pv)
	if badge != "":
		var l := UIKit.label(badge, 26, UIKit.INK, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		l.offset_top = -40
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(l)
	card.pressed.connect(func():
		AudioSvc.sfx("pop")
		cb.call())
	return card


static func price_badge(id: String) -> String:
	var p := Content.price(id)
	return Loc.t("coins_n", [p]) if p > 0 else Loc.t("free")
