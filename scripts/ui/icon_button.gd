class_name IconButton
extends Button
## Big round picture button (no text needed). Squishes when pressed.

var icon_name := "star"
var bg := Color("#f39bb8")
var badge := ""
var disabled_look := false
var dim := false
var bg_ring := false             # selected tab: pink ring around the picture                 # not-selected tab: picture shown a bit faded and smaller

## UI names -> picture buttons (assets/ui/icons, drawn from the owner's button sheet).
## Names not listed keep their vector icon.
const PICS := {
	"gift": "gift", "pic_gift": "gift", "chest": "gift",
	"shop": "shop", "pic_shop": "shop",
	"wardrobe": "dress", "dress": "dress", "pic_dress": "dress",
	"paw": "pets", "pic_pets": "pets", "pets": "pets",
	"move": "move", "pic_move": "move", "weather": "weather",
	"eye": "eye", "lock": "lock", "pic_lock": "lock", "parent": "lock",
	"check": "check", "close": "close", "flip": "flip", "undo": "undo", "box": "chest", "back": "back",
	"food": "food", "water": "water", "comb": "comb", "play": "play", "treat": "fish",
	"study": "notebook", "heart": "heart", "star": "star", "hand": "paw", "goto": "home", "house": "home",
	"sleep": "moon", "sit": "tab_chair", "mirror": "hair2", "eat": "apple",
	"ui_sprout": "sprout", "ui_sun": "sun", "ui_moon": "moon", "ui_snow": "snow", "ui_flower": "flower", "ui_cloud": "weather", "ui_star": "star_s",
	"hair_style": "hair2", "hair_color": "hair", "eye_color": "eye_color", "skin": "skin", "makeup": "lips",
	"earrings": "earrings", "outfit": "dress_c", "hat": "crown", "accessory": "glasses", "bow": "bow",
}
static var _tex: Dictionary = {}


static func pic(name: String) -> Texture2D:
	if not PICS.has(name):
		return null
	var path := "res://assets/ui/icons/%s.png" % PICS[name]
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]
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
	var tex := pic(icon_name)
	if tex != null:
		# the picture already has its own plate, shine and shadow
		var k := (1.0 - _press * 0.08) * (0.86 if dim else 1.0)
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		var sc := minf(s.x / tw, s.y / th) * k
		var rr := Rect2(c - Vector2(tw, th) * sc * 0.5, Vector2(tw, th) * sc)
		draw_texture_rect(tex, rr, false, Color(1, 1, 1, 0.6) if (dim or disabled_look) else Color.WHITE)
		if not dim and bg_ring:
			draw_arc(c, minf(rr.size.x, rr.size.y) * 0.5 + 4, 0, TAU, 40, Color("#ff7aa8"), 5, true)
		_draw_badge(c, r)
		return
	draw_circle(c + Vector2(0, 5), r, Color(0.4, 0.2, 0.3, 0.2))
	var col := bg if not disabled_look else Color("#d9cfd3")
	draw_circle(c, r, col.darkened(0.08))
	draw_circle(c - Vector2(0, 3), r - 3, col)
	draw_arc(c - Vector2(0, 3), r - 10, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, 0.35), 5, true)
	# colourful picture icons fill more of the plate than the white glyphs
	IconPainter.draw_icon(self, icon_name, c, r * (1.45 if icon_name.begins_with("pic_") or icon_name == "weather" else 1.1))
	_draw_badge(c, r)


func _draw_badge(c: Vector2, r: float) -> void:
	if badge != "":
		var font := UIKit.FONT_BOLD
		var bw: float = max(40.0, font.get_string_size(badge, HORIZONTAL_ALIGNMENT_CENTER, -1, 24).x + 18)
		var br := Rect2(c + Vector2(r * 0.35, -r - 6), Vector2(bw, 40))
		DrawUtil.rrect(self, br, 20, Color("#fff3c4"), true, 0.0)
		draw_string(font, br.position + Vector2(9, 29), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UIKit.INK)
