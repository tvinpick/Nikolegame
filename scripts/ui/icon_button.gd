class_name IconButton
extends Button
## Big round picture button (no text needed). Squishes when pressed.

var icon_name := "star"
var bg := Color("#f39bb8")
var badge := ""
var disabled_look := false
var _press := 0.0


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button_down.connect(_on_down)
	button_up.connect(queue_redraw)


func _on_down() -> void:
	_press = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	if _press > 0.0:
		_press = max(0.0, _press - delta * 5.0)
		queue_redraw()


func set_icon(n: String) -> void:
	icon_name = n
	queue_redraw()


func _draw() -> void:
	var s := size
	var c := s * 0.5
	var r: float = min(s.x, s.y) * 0.5 * (1.0 - _press * 0.08)
	draw_circle(c + Vector2(0, 5), r, Color(0.4, 0.2, 0.3, 0.2))
	var col := bg if not disabled_look else Color("#d9cfd3")
	draw_circle(c, r, col.darkened(0.08))
	draw_circle(c - Vector2(0, 3), r - 3, col)
	draw_arc(c - Vector2(0, 3), r - 10, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, 0.35), 5, true)
	IconPainter.draw_icon(self, icon_name, c, r * 1.1)
	if badge != "":
		var font := UIKit.FONT_BOLD
		var bw: float = max(40.0, font.get_string_size(badge, HORIZONTAL_ALIGNMENT_CENTER, -1, 24).x + 18)
		var br := Rect2(c + Vector2(r * 0.35, -r - 6), Vector2(bw, 40))
		DrawUtil.rrect(self, br, 20, Color("#fff3c4"), true, 0.0)
		draw_string(font, br.position + Vector2(9, 29), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UIKit.INK)
