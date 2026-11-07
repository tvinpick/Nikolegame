class_name RoomPainter
extends Node2D
## Draws wall (wallpaper pattern), baseboard and wooden floor with perspective
## planks. Surfaces are catalog items (category "wallfloor") -> data driven.

const D := preload("res://scripts/core/draw_util.gd")

var wall_def: Dictionary = {}
var floor_def: Dictionary = {}
var light_tint := Color.WHITE


func set_surfaces(wall_id: String, floor_id: String) -> void:
	wall_def = Content.item(wall_id)
	floor_def = Content.item(floor_id)
	queue_redraw()


func _draw() -> void:
	var wc := FurniturePainter.cols(wall_def) if not wall_def.is_empty() else {"main": Color("#fbe3e8"), "accent": Color("#f7cbd6"), "wood": Color("#f1b9c8"), "trim": Color.WHITE}
	var fc := FurniturePainter.cols(floor_def) if not floor_def.is_empty() else {"main": Color("#d9a578"), "accent": Color("#c98f62"), "wood": Color("#b77d52"), "trim": Color("#e6b98e")}
	var W := RoomGeo.WIDTH
	var wb := RoomGeo.WALL_BOTTOM
	# wall
	D.gradient_poly(self, PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, wb), Vector2(0, wb)]), wc["main"].lightened(0.06), wc["main"].darkened(0.03))
	wall_pattern(self, Rect2(0, 0, W, wb - 40), wall_def.get("pattern", "dots"), wc, 48.0)
	# crown moulding
	draw_rect(Rect2(0, 0, W, 22), wc["trim"])
	draw_rect(Rect2(0, 22, W, 6), wc["wood"].darkened(0.05))
	# wainscot band
	draw_rect(Rect2(0, wb - 150, W, 150), wc["accent"].lerp(wc["trim"], 0.3))
	draw_rect(Rect2(0, wb - 154, W, 8), wc["trim"])
	for x in range(0, int(W), 160):
		D.rrect(self, Rect2(x + 18, wb - 132, 124, 96), 10, wc["accent"].lerp(wc["trim"], 0.55), false, 0.04)
	# floor with perspective planks
	var fy := wb
	D.gradient_poly(self, PackedVector2Array([Vector2(0, fy), Vector2(W, fy), Vector2(W, RoomGeo.HEIGHT), Vector2(0, RoomGeo.HEIGHT)]), fc["main"].darkened(0.1), fc["main"].lightened(0.05))
	var rows := 9
	for i in rows + 1:
		var t := float(i) / rows
		var y := fy + (RoomGeo.HEIGHT - fy) * (t * t * 0.45 + t * 0.55)
		draw_line(Vector2(0, y), Vector2(W, y), fc["wood"].darkened(0.05), 2.0)
		if i < rows:
			var t2 := float(i + 1) / rows
			var y2 := fy + (RoomGeo.HEIGHT - fy) * (t2 * t2 * 0.45 + t2 * 0.55)
			var off := 90.0 if i % 2 == 0 else 0.0
			var plank := 220.0 + i * 8.0
			var x := -off
			while x < W:
				draw_line(Vector2(x, y), Vector2(x, y2), fc["wood"].darkened(0.08), 2.0)
				# subtle grain
				draw_line(Vector2(x + plank * 0.3, y + (y2 - y) * 0.45), Vector2(x + plank * 0.7, y + (y2 - y) * 0.5), Color(fc["accent"], 0.5), 1.5)
				x += plank
	# soft shade near the wall
	for i in 6:
		draw_rect(Rect2(0, fy + i * 6, W, 6), Color(0.3, 0.15, 0.1, 0.06 - i * 0.009))
	# baseboard
	draw_rect(Rect2(0, wb - 20, W, 22), wc["trim"])
	draw_rect(Rect2(0, wb, W, 4), Color(0.3, 0.2, 0.2, 0.18))
	# side walls hint at both ends (room is a closed box)
	for sx in [0.0, W]:
		var dir := 1.0 if sx == 0.0 else -1.0
		D.gradient_poly(self, PackedVector2Array([Vector2(sx, 0), Vector2(sx + dir * 30, 0), Vector2(sx + dir * 30, RoomGeo.HEIGHT), Vector2(sx, RoomGeo.HEIGHT)]), Color(0.4, 0.25, 0.25, 0.25), Color(0.4, 0.25, 0.25, 0.1))


static func wall_pattern(ci: CanvasItem, r: Rect2, pattern: String, c: Dictionary, step: float) -> void:
	match pattern:
		"stripes":
			var x := r.position.x
			var i := 0
			while x < r.end.x:
				if i % 2 == 0:
					ci.draw_rect(Rect2(x, r.position.y, min(step * 0.6, r.end.x - x), r.size.y), Color(c["accent"], 0.7))
				x += step * 0.6
				i += 1
		"stars":
			var y := r.position.y + step * 0.6
			var row := 0
			while y < r.end.y:
				var x2 := r.position.x + (step * 0.9 if row % 2 else step * 0.3)
				while x2 < r.end.x:
					ci.draw_colored_polygon(D.star_points(Vector2(x2, y), step * 0.16, step * 0.07), Color(c["accent"], 0.9))
					x2 += step * 1.3
				y += step * 1.1
				row += 1
		_:
			var y2 := r.position.y + step * 0.5
			var row2 := 0
			while y2 < r.end.y:
				var x3 := r.position.x + (step * 0.5 if row2 % 2 else 0.0) + step * 0.25
				while x3 < r.end.x:
					ci.draw_circle(Vector2(x3, y2), step * 0.09, Color(c["accent"], 0.95))
					x3 += step
				y2 += step * 0.9
				row2 += 1
