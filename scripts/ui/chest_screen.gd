class_name ChestScreen
extends Screen
## Daily decorative chest: one tap opens it. No streaks, no penalties.

var chest: ChestView


func _init() -> void:
	screen_name = "chest"
	title_key = "title_chest"


func build() -> void:
	chest = ChestView.new()
	chest.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chest.mouse_filter = Control.MOUSE_FILTER_STOP
	chest.gui_input.connect(_on_input)
	body.add_child(chest)
	var st := Economy.daily_status()
	if not st["available"]:
		chest.opened = true
		chest.text = Loc.t("chest_tomorrow")
	else:
		chest.text = Loc.t("chest_tap")
		AudioSvc.say("chest_tap")


func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and not chest.opened:
		var got := Economy.claim_daily()
		chest.opened = true
		if got > 0:
			chest.amount = got
			chest.text = Loc.t("chest_got", [got])
			AudioSvc.sfx("chest")
			AudioSvc.say("chest_yay")
		else:
			chest.text = Loc.t("chest_tomorrow")


class ChestView extends Control:
	var opened := false
	var amount := 0
	var text := ""
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5 + Vector2(0, 30)
		var bob := sin(t * 2.0) * 6.0 if not opened else 0.0
		var w := 360.0
		var h := 220.0
		DrawUtil.shadow(self, c + Vector2(0, h * 0.5), w * 0.6, 26)
		DrawUtil.rrect(self, Rect2(c.x - w / 2, c.y - h / 2 + bob, w, h), 24, Color("#d39a6a"))
		DrawUtil.rrect(self, Rect2(c.x - w / 2, c.y - 10 + bob, w, 30), 8, Color("#f6c955"))
		var lid_a := -0.9 if opened else 0.0
		var lid := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			lid.append(Vector2(cos(a) * w / 2, sin(a) * 90))
		var xf := Transform2D(lid_a, c + Vector2(-w / 2, -h / 2 + bob)) * Transform2D(0, Vector2(w / 2, 0))
		var pts := PackedVector2Array()
		for p in lid:
			pts.append(xf * p)
		DrawUtil.poly(self, pts, Color("#e7b07e"))
		if opened and amount > 0:
			for i in 9:
				var a := t * 2.0 + i * 0.7
				var p := c + Vector2(cos(a) * (60 + i * 14), -140 - sin(a * 1.3) * 40 - i * 6)
				IconPainter.draw_icon(self, "coin" if i % 3 else "star", p, 46)
		var f := UIKit.FONT_BOLD
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 44).x
		draw_string(f, Vector2(c.x - tw / 2, size.y - 30), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, UIKit.INK)
