class_name IconPainter
extends RefCounted
## Vector icons for UI buttons and learning pictures. All drawn at any size,
## so the notebook stays crisp at every screen density.

const D := preload("res://scripts/core/draw_util.gd")


static func draw_shape(ci: CanvasItem, shape: String, c: Vector2, s: float, col: Color) -> void:
	var r := s * 0.45
	match shape:
		"circle":
			D.ellipse(ci, c, r, r, col)
		"square":
			D.rrect(ci, Rect2(c - Vector2(r, r) * 0.9, Vector2(r, r) * 1.8), r * 0.12, col)
		"rectangle":
			D.rrect(ci, Rect2(c - Vector2(r * 1.05, r * 0.6), Vector2(r * 2.1, r * 1.2)), r * 0.1, col)
		"triangle":
			D.poly(ci, PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 1.05, r * 0.8), c + Vector2(-r * 1.05, r * 0.8)]), col)
		"star":
			D.poly(ci, D.star_points(c, r * 1.05, r * 0.45), col)
		"heart":
			D.poly(ci, D.heart_points(c + Vector2(0, -r * 0.1), r * 1.0), col)
		"drop":
			var pts := PackedVector2Array()
			for i in 21:
				var a := PI * i / 20.0
				pts.append(c + Vector2(cos(a) * r * 0.75, r * 0.25 + sin(a) * r * 0.75))
			pts.append(c + Vector2(0, -r))
			D.poly(ci, pts, col)
		_:
			D.ellipse(ci, c, r, r, col)


static func draw_outline_shape(ci: CanvasItem, shape: String, c: Vector2, s: float, col: Color) -> void:
	var r := s * 0.45
	var pts := PackedVector2Array()
	match shape:
		"circle":
			pts = D.ellipse_points(c, r, r, 32)
		"square":
			pts = D.rrect_points(Rect2(c - Vector2(r, r) * 0.9, Vector2(r, r) * 1.8), r * 0.12)
		"rectangle":
			pts = D.rrect_points(Rect2(c - Vector2(r * 1.05, r * 0.6), Vector2(r * 2.1, r * 1.2)), r * 0.1)
		"triangle":
			pts = PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 1.05, r * 0.8), c + Vector2(-r * 1.05, r * 0.8)])
		"star":
			pts = D.star_points(c, r * 1.05, r * 0.45)
		"heart":
			pts = D.heart_points(c + Vector2(0, -r * 0.1), r)
		_:
			pts = D.ellipse_points(c, r, r, 32)
	pts.append(pts[0])
	ci.draw_colored_polygon(pts.slice(0, pts.size() - 1), Color(col, 0.12))
	# dashed outline
	for i in pts.size() - 1:
		if i % 2 == 0:
			ci.draw_line(pts[i], pts[i + 1], col, 5, true)


static func draw_icon(ci: CanvasItem, name: String, c: Vector2, s: float, tint := Color.WHITE) -> void:
	var r := s * 0.5
	match name:
		"apple":
			D.ellipse(ci, c + Vector2(0, r * 0.1), r * 0.8, r * 0.75, Color("#ef5b5b") * tint)
			ci.draw_line(c + Vector2(0, -r * 0.55), c + Vector2(r * 0.1, -r * 0.9), Color("#7a5236"), max(2, r * 0.12), true)
			D.ellipse(ci, c + Vector2(r * 0.32, -r * 0.75), r * 0.25, r * 0.12, Color("#62c370") * tint, false)
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.2), r * 0.15, Color(1, 1, 1, 0.6))
		"berry":
			for o in [Vector2(-0.3, 0.1), Vector2(0.3, 0.1), Vector2(0, -0.25), Vector2(0, 0.4)]:
				D.ellipse(ci, c + o * r, r * 0.36, r * 0.36, Color("#d94a7a") * tint)
				ci.draw_circle(c + o * r + Vector2(-r * 0.1, -r * 0.1), r * 0.08, Color(1, 1, 1, 0.7))
			D.ellipse(ci, c + Vector2(0, -r * 0.65), r * 0.3, r * 0.12, Color("#62c370"), false)
		"star":
			D.poly(ci, D.star_points(c, r * 0.95, r * 0.42), Color("#f7cf46") * tint)
		"heart":
			D.poly(ci, D.heart_points(c, r * 0.9), Color("#f06f97") * tint)
		"fish":
			D.ellipse(ci, c + Vector2(-r * 0.1, 0), r * 0.65, r * 0.42, Color("#6fb3f0") * tint)
			D.poly(ci, PackedVector2Array([c + Vector2(r * 0.45, 0), c + Vector2(r * 0.95, -r * 0.4), c + Vector2(r * 0.95, r * 0.4)]), Color("#4f94d6") * tint)
			ci.draw_circle(c + Vector2(-r * 0.4, -r * 0.08), r * 0.1, Color("#2b2b38"))
		"flower":
			for i in 5:
				var a := TAU * i / 5.0 - PI / 2.0
				D.ellipse(ci, c + Vector2(cos(a), sin(a)) * r * 0.45, r * 0.32, r * 0.32, Color("#f58fb8") * tint, false)
			ci.draw_circle(c, r * 0.28, Color("#f7cf46"))
		"ball":
			D.ellipse(ci, c, r * 0.8, r * 0.8, Color("#5b8def") * tint)
			ci.draw_arc(c, r * 0.6, 0.3, 2.6, 12, Color.WHITE, max(2, r * 0.12), true)
			ci.draw_arc(c, r * 0.6, 3.4, 5.7, 12, Color("#f7cf46"), max(2, r * 0.12), true)
		"leaf":
			var pts := PackedVector2Array()
			for i in 17:
				var t := float(i) / 16.0
				pts.append(c + Vector2(lerp(-r * 0.8, r * 0.8, t), -sin(t * PI) * r * 0.5))
			for i in 17:
				var t := 1.0 - float(i) / 16.0
				pts.append(c + Vector2(lerp(-r * 0.8, r * 0.8, t), sin(t * PI) * r * 0.5))
			D.poly(ci, pts, Color("#62c370") * tint)
			ci.draw_line(c + Vector2(-r * 0.8, 0), c + Vector2(r * 0.7, 0), Color("#3f9b52"), max(1.5, r * 0.06), true)
		"watermelon":
			var pts2 := PackedVector2Array()
			for i in 17:
				var a := PI * i / 16.0
				pts2.append(c + Vector2(cos(a) * r * 0.9, -r * 0.2 + sin(a) * r * 0.8))
			D.poly(ci, pts2, Color("#62c370") * tint)
			var inner := PackedVector2Array()
			for i in 17:
				var a := PI * i / 16.0
				inner.append(c + Vector2(cos(a) * r * 0.75, -r * 0.2 + sin(a) * r * 0.65))
			ci.draw_colored_polygon(inner, Color("#ef5b5b") * tint)
			for i in 5:
				ci.draw_circle(c + Vector2(-r * 0.4 + i * r * 0.2, r * 0.05 + (i % 2) * r * 0.15), r * 0.05, Color("#2b2b38"))
		"banana":
			var pts3 := PackedVector2Array()
			for i in 13:
				var a := PI * 0.15 + PI * 0.7 * i / 12.0
				pts3.append(c + Vector2(cos(a) * r * 0.85, -r * 0.5 + sin(a) * r * 0.95))
			for i in 13:
				var a := PI * 0.85 - PI * 0.7 * i / 12.0
				pts3.append(c + Vector2(cos(a) * r * 0.6, -r * 0.35 + sin(a) * r * 0.6))
			D.poly(ci, pts3, Color("#f7d046") * tint)
		"pear":
			D.ellipse(ci, c + Vector2(0, r * 0.25), r * 0.6, r * 0.55, Color("#b5d65a") * tint)
			D.ellipse(ci, c + Vector2(0, -r * 0.25), r * 0.38, r * 0.4, Color("#b5d65a") * tint)
			ci.draw_line(c + Vector2(0, -r * 0.6), c + Vector2(r * 0.1, -r * 0.9), Color("#7a5236"), max(2, r * 0.1), true)
		"lemon":
			D.ellipse(ci, c, r * 0.8, r * 0.55, Color("#f7e046") * tint)
			ci.draw_circle(c + Vector2(r * 0.8, 0), r * 0.12, Color("#f7e046"))
		"cucumber":
			D.rrect(ci, Rect2(c - Vector2(r * 0.9, r * 0.3), Vector2(r * 1.8, r * 0.6)), r * 0.3, Color("#4fae5a") * tint)
			for i in 4:
				ci.draw_circle(c + Vector2(-r * 0.5 + i * r * 0.33, -r * 0.05), r * 0.05, Color("#c9f0b5"))
		"mushroom":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.22, -r * 0.1), Vector2(r * 0.44, r * 0.8)), r * 0.15, Color("#fbeee0"))
			var cap := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				cap.append(c + Vector2(cos(a) * r * 0.85, -r * 0.05 + sin(a) * r * 0.7))
			D.poly(ci, cap, Color("#ef5b5b") * tint)
			for o in [Vector2(-0.4, -0.3), Vector2(0.1, -0.5), Vector2(0.45, -0.2)]:
				ci.draw_circle(c + o * r, r * 0.1, Color.WHITE)
		"house":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.65, -r * 0.1), Vector2(r * 1.3, r * 0.9)), r * 0.1, Color("#fbe3c8") * tint)
			D.poly(ci, PackedVector2Array([c + Vector2(-r * 0.85, -r * 0.05), c + Vector2(0, -r * 0.85), c + Vector2(r * 0.85, -r * 0.05)]), Color("#ef6f6f") * tint)
			D.rrect(ci, Rect2(c + Vector2(-r * 0.15, r * 0.3), Vector2(r * 0.32, r * 0.5)), r * 0.05, Color("#b5835a"))
			D.rrect(ci, Rect2(c + Vector2(r * 0.25, r * 0.05), Vector2(r * 0.28, r * 0.25)), r * 0.04, Color("#9fd4f0"))
		"cat":
			_cat_face(ci, c, r, Color("#f2a65a") * tint)
		"dog":
			D.ellipse(ci, c, r * 0.7, r * 0.62, Color("#c98a4f") * tint)
			for sx in [-1.0, 1.0]:
				D.ellipse(ci, c + Vector2(sx * r * 0.68, -r * 0.05), r * 0.2, r * 0.42, Color("#8a5a35") * tint)
			D.ellipse(ci, c + Vector2(0, r * 0.25), r * 0.32, r * 0.24, Color("#fbeee0"), false)
			ci.draw_circle(c + Vector2(0, r * 0.15), r * 0.1, Color("#2b2b38"))
			ci.draw_circle(c + Vector2(-r * 0.25, -r * 0.12), r * 0.08, Color("#2b2b38"))
			ci.draw_circle(c + Vector2(r * 0.25, -r * 0.12), r * 0.08, Color("#2b2b38"))
		"moon":
			ci.draw_circle(c, r * 0.75, Color("#f7e08a") * tint)
			ci.draw_circle(c + Vector2(r * 0.35, -r * 0.2), r * 0.62, Color(0, 0, 0, 0))
			var crescent := PackedVector2Array()
			for i in 25:
				var a := -PI / 2.0 + PI * i / 24.0
				crescent.append(c + Vector2(-cos(a) * r * 0.75, sin(a) * r * 0.75))
			D.poly(ci, crescent, Color("#f7d046") * tint)
		"cloud":
			D.cloud(ci, c + Vector2(0, r * 0.1), r * 1.6, Color("#e9f2fb") * tint)
		"rain":
			D.cloud(ci, c + Vector2(0, -r * 0.2), r * 1.5, Color("#c7d6e8") * tint)
			for i in 4:
				ci.draw_line(c + Vector2(-r * 0.5 + i * r * 0.32, r * 0.25), c + Vector2(-r * 0.6 + i * r * 0.32, r * 0.65), Color("#5b8def"), max(2, r * 0.1), true)
		"rainbow":
			var bands := [Color("#ef5b5b"), Color("#f59a3b"), Color("#f7d046"), Color("#62c370"), Color("#5b8def"), Color("#a274e0")]
			for i in bands.size():
				ci.draw_arc(c + Vector2(0, r * 0.4), r * (0.9 - i * 0.1), PI, TAU, 24, bands[i] * tint, r * 0.1, true)
		"bird":
			D.ellipse(ci, c, r * 0.6, r * 0.45, Color("#6fb3f0") * tint)
			ci.draw_circle(c + Vector2(r * 0.45, -r * 0.3), r * 0.3, Color("#6fb3f0") * tint)
			D.poly(ci, PackedVector2Array([c + Vector2(r * 0.72, -r * 0.35), c + Vector2(r * 0.95, -r * 0.25), c + Vector2(r * 0.72, -r * 0.18)]), Color("#f59a3b"), false)
			ci.draw_circle(c + Vector2(r * 0.52, -r * 0.36), r * 0.07, Color("#2b2b38"))
			D.ellipse(ci, c + Vector2(-r * 0.1, -r * 0.1), r * 0.35, r * 0.2, Color("#4f94d6"), false)
		"chick":
			ci.draw_circle(c + Vector2(0, r * 0.15), r * 0.55, Color("#f7d046") * tint)
			ci.draw_circle(c + Vector2(0, -r * 0.4), r * 0.35, Color("#f7d046") * tint)
			D.poly(ci, PackedVector2Array([c + Vector2(r * 0.25, -r * 0.42), c + Vector2(r * 0.5, -r * 0.35), c + Vector2(r * 0.25, -r * 0.28)]), Color("#f59a3b"), false)
			ci.draw_circle(c + Vector2(r * 0.12, -r * 0.48), r * 0.06, Color("#2b2b38"))
		"egg":
			D.ellipse(ci, c + Vector2(0, r * 0.1), r * 0.55, r * 0.72, Color("#fbf3e6") * tint)
		"seed":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.8, r * 0.3), Vector2(r * 1.6, r * 0.4)), r * 0.1, Color("#a8754f"))
			D.ellipse(ci, c + Vector2(0, r * 0.2), r * 0.25, r * 0.16, Color("#7a5236"))
		"sprout":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.8, r * 0.3), Vector2(r * 1.6, r * 0.4)), r * 0.1, Color("#a8754f"))
			ci.draw_line(c + Vector2(0, r * 0.3), c + Vector2(0, -r * 0.3), Color("#3f9b52"), max(2, r * 0.1), true)
			D.ellipse(ci, c + Vector2(-r * 0.25, -r * 0.35), r * 0.25, r * 0.13, Color("#62c370"))
			D.ellipse(ci, c + Vector2(r * 0.25, -r * 0.45), r * 0.25, r * 0.13, Color("#62c370"))
		"sunrise":
			var half := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				half.append(c + Vector2(cos(a), sin(a)) * r * 0.55 + Vector2(0, r * 0.3))
			D.poly(ci, half, Color("#f7b046") * tint)
			ci.draw_line(c + Vector2(-r * 0.9, r * 0.3), c + Vector2(r * 0.9, r * 0.3), Color("#62c370"), max(2, r * 0.12), true)
		"sun":
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.6, c + Vector2(cos(a), sin(a)) * r * 0.92, Color("#f7c046") * tint, max(2, r * 0.12), true)
			D.ellipse(ci, c, r * 0.5, r * 0.5, Color("#f7d046") * tint)
		"tree":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.12, r * 0.3), Vector2(r * 0.24, r * 0.6)), r * 0.05, Color("#a8754f"))
			D.poly(ci, PackedVector2Array([c + Vector2(0, -r * 0.95), c + Vector2(r * 0.6, r * 0.35), c + Vector2(-r * 0.6, r * 0.35)]), Color("#3fa45a") * tint)
		"duck":
			D.ellipse(ci, c + Vector2(-r * 0.05, r * 0.2), r * 0.62, r * 0.42, Color("#f7d046") * tint)
			ci.draw_circle(c + Vector2(r * 0.35, -r * 0.3), r * 0.32, Color("#f7d046") * tint)
			D.ellipse(ci, c + Vector2(r * 0.72, -r * 0.25), r * 0.2, r * 0.09, Color("#f59a3b"), false)
			ci.draw_circle(c + Vector2(r * 0.42, -r * 0.38), r * 0.06, Color("#2b2b38"))
		"hedgehog":
			for i in 9:
				var a := PI + PI * i / 8.0
				D.poly(ci, PackedVector2Array([c + Vector2(cos(a - 0.2), sin(a - 0.2)) * r * 0.5, c + Vector2(cos(a), sin(a)) * r * 0.95, c + Vector2(cos(a + 0.2), sin(a + 0.2)) * r * 0.5]), Color("#8a6a55") * tint, false)
			D.ellipse(ci, c + Vector2(0, r * 0.1), r * 0.65, r * 0.42, Color("#a8836a") * tint)
			D.ellipse(ci, c + Vector2(r * 0.55, r * 0.2), r * 0.3, r * 0.22, Color("#e8cfb8"), false)
			ci.draw_circle(c + Vector2(r * 0.85, r * 0.18), r * 0.07, Color("#2b2b38"))
		"spoon":
			D.ellipse(ci, c + Vector2(0, -r * 0.45), r * 0.28, r * 0.38, Color("#c7d3df") * tint)
			D.rrect(ci, Rect2(c + Vector2(-r * 0.07, -r * 0.1), Vector2(r * 0.14, r * 0.95)), r * 0.07, Color("#c7d3df") * tint)
		"bone":
			D.rrect(ci, Rect2(c - Vector2(r * 0.6, r * 0.15), Vector2(r * 1.2, r * 0.3)), r * 0.1, Color("#f6ead3") * tint)
			for o in [Vector2(-0.65, -0.2), Vector2(-0.65, 0.2), Vector2(0.65, -0.2), Vector2(0.65, 0.2)]:
				ci.draw_circle(c + o * r, r * 0.22, Color("#f6ead3") * tint)
		"globe":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.3, r * 0.6), Vector2(r * 0.6, r * 0.15)), 3, Color("#b98159"))
			ci.draw_line(c + Vector2(0, r * 0.35), c + Vector2(0, r * 0.62), Color("#b98159"), 3)
			D.ellipse(ci, c - Vector2(0, r * 0.1), r * 0.5, r * 0.5, Color("#8ec9e8") * tint)
			D.ellipse(ci, c + Vector2(-r * 0.12, -r * 0.2), r * 0.2, r * 0.15, Color("#62c370"), false)
			D.ellipse(ci, c + Vector2(r * 0.2, r * 0.05), r * 0.15, r * 0.12, Color("#62c370"), false)
		"note":
			ci.draw_circle(c + Vector2(-r * 0.25, r * 0.4), r * 0.25, Color("#a274e0") * tint)
			ci.draw_line(c + Vector2(0, r * 0.4), c + Vector2(0, -r * 0.6), Color("#a274e0") * tint, max(2, r * 0.12))
			ci.draw_line(c + Vector2(0, -r * 0.6), c + Vector2(r * 0.4, -r * 0.35), Color("#a274e0") * tint, max(2, r * 0.12))
		"coin":
			D.ellipse(ci, c, r * 0.8, r * 0.8, Color("#f7cf46") * tint)
			D.ellipse(ci, c, r * 0.58, r * 0.58, Color("#fbe07a"), false)
			D.poly(ci, D.star_points(c, r * 0.36, r * 0.16), Color("#e2a92e"), false)
		_:
			_ui_icon(ci, name, c, r, tint)


static func _cat_face(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	for sx in [-1.0, 1.0]:
		D.poly(ci, PackedVector2Array([c + Vector2(sx * r * 0.7, -r * 0.1), c + Vector2(sx * r * 0.6, -r * 0.9), c + Vector2(sx * r * 0.15, -r * 0.5)]), col)
	D.ellipse(ci, c, r * 0.75, r * 0.62, col)
	ci.draw_circle(c + Vector2(-r * 0.28, -r * 0.08), r * 0.1, Color("#2b2b38"))
	ci.draw_circle(c + Vector2(r * 0.28, -r * 0.08), r * 0.1, Color("#2b2b38"))
	ci.draw_circle(c + Vector2(0, r * 0.12), r * 0.07, Color("#f06f97"))
	for sx in [-1.0, 1.0]:
		ci.draw_line(c + Vector2(sx * r * 0.3, r * 0.2), c + Vector2(sx * r * 0.9, r * 0.12), Color(0.3, 0.2, 0.2, 0.6), 1.5)


## UI glyphs (white on coloured buttons).
static func _ui_icon(ci: CanvasItem, name: String, c: Vector2, r: float, tint: Color) -> void:
	var w := Color.WHITE * tint
	var lw: float = max(3.0, r * 0.16)
	match name:
		"shop":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.6, -r * 0.2), Vector2(r * 1.2, r * 0.85)), r * 0.15, w, false)
			ci.draw_arc(c + Vector2(0, -r * 0.2), r * 0.35, PI, TAU, 12, w, lw, true)
		"wardrobe", "dress":
			D.poly(ci, PackedVector2Array([c + Vector2(-r * 0.25, -r * 0.8), c + Vector2(r * 0.25, -r * 0.8), c + Vector2(r * 0.7, r * 0.8), c + Vector2(-r * 0.7, r * 0.8)]), w, false)
			ci.draw_line(c + Vector2(-r * 0.4, -r * 0.2), c + Vector2(r * 0.4, -r * 0.2), Color(1, 0.6, 0.75), lw * 0.7)
		"paw":
			D.ellipse(ci, c + Vector2(0, r * 0.25), r * 0.4, r * 0.32, w, false)
			for o in [Vector2(-0.5, -0.2), Vector2(-0.18, -0.55), Vector2(0.18, -0.55), Vector2(0.5, -0.2)]:
				D.ellipse(ci, c + o * r, r * 0.16, r * 0.2, w, false)
		"move":
			for a in [0.0, PI / 2.0, PI, PI * 1.5]:
				var d := Vector2(cos(a), sin(a))
				ci.draw_line(c, c + d * r * 0.8, w, lw, true)
				ci.draw_colored_polygon(PackedVector2Array([c + d * r * 0.95, c + d * r * 0.6 + d.orthogonal() * r * 0.25, c + d * r * 0.6 - d.orthogonal() * r * 0.25]), w)
		"weather":
			draw_icon(ci, "sun", c + Vector2(-r * 0.25, -r * 0.2), r * 1.2)
			D.cloud(ci, c + Vector2(r * 0.15, r * 0.25), r * 1.1, Color.WHITE)
		"settings", "gear":
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.45, c + Vector2(cos(a), sin(a)) * r * 0.85, w, lw * 1.3)
			ci.draw_circle(c, r * 0.55, w)
			ci.draw_circle(c, r * 0.22, Color(0.55, 0.45, 0.7))
		"sit":
			ci.draw_line(c + Vector2(-r * 0.5, -r * 0.8), c + Vector2(-r * 0.5, r * 0.8), w, lw, true)
			ci.draw_line(c + Vector2(-r * 0.5, r * 0.1), c + Vector2(r * 0.6, r * 0.1), w, lw, true)
			ci.draw_line(c + Vector2(r * 0.5, r * 0.1), c + Vector2(r * 0.5, r * 0.8), w, lw, true)
		"sleep":
			draw_icon(ci, "moon", c + Vector2(-r * 0.1, r * 0.1), r * 1.4)
			_z(ci, c + Vector2(r * 0.5, -r * 0.55), r * 0.3, w, lw * 0.6)
		"book", "study":
			D.poly(ci, PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.5), c + Vector2(0, -r * 0.3), c + Vector2(0, r * 0.7), c + Vector2(-r * 0.8, r * 0.5)]), w, false)
			D.poly(ci, PackedVector2Array([c + Vector2(r * 0.8, -r * 0.5), c + Vector2(0, -r * 0.3), c + Vector2(0, r * 0.7), c + Vector2(r * 0.8, r * 0.5)]), Color(1, 0.95, 0.85) * tint, false)
			if name == "study":
				D.poly(ci, D.star_points(c + Vector2(r * 0.55, -r * 0.7), r * 0.3, r * 0.13), Color("#f7cf46"), false)
		"pencil":
			ci.draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(r * 0.55, -r * 0.55), w, lw * 1.8, true)
			ci.draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(-r * 0.75, r * 0.75), Color(0.4, 0.3, 0.3), lw, true)
		"food":
			draw_icon(ci, "apple", c, r * 1.6)
		"water":
			draw_shape(ci, "drop", c, r * 1.9, Color("#8fd3f5"))
		"treat":
			draw_icon(ci, "fish", c, r * 1.7)
		"mirror":
			D.ellipse(ci, c, r * 0.5, r * 0.75, w, false)
			ci.draw_line(c + Vector2(-r * 0.2, -r * 0.3), c + Vector2(r * 0.1, -r * 0.5), Color(0.6, 0.8, 1), lw * 0.7, true)
		"window":
			D.rrect(ci, Rect2(c - Vector2(r * 0.7, r * 0.7), Vector2(r * 1.4, r * 1.4)), r * 0.1, Color(0.75, 0.9, 1), false)
			ci.draw_line(c + Vector2(0, -r * 0.7), c + Vector2(0, r * 0.7), w, lw)
			ci.draw_line(c + Vector2(-r * 0.7, 0), c + Vector2(r * 0.7, 0), w, lw)
		"bath":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.8, -r * 0.05), Vector2(r * 1.6, r * 0.65)), r * 0.3, w, false)
			for i in 3:
				ci.draw_circle(c + Vector2(-r * 0.4 + i * r * 0.4, -r * 0.35 - (i % 2) * r * 0.2), r * 0.17, Color(0.8, 0.95, 1))
		"comb":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.8, -r * 0.4), Vector2(r * 1.6, r * 0.3)), r * 0.1, w, false)
			for i in 7:
				ci.draw_line(c + Vector2(-r * 0.7 + i * r * 0.23, -r * 0.1), c + Vector2(-r * 0.7 + i * r * 0.23, r * 0.5), w, lw * 0.6)
		"power":
			ci.draw_arc(c, r * 0.6, -PI * 0.3, PI * 1.3, 20, w, lw, true)
			ci.draw_line(c + Vector2(0, -r * 0.8), c + Vector2(0, -r * 0.1), w, lw, true)
		"play":
			draw_icon(ci, "ball", c, r * 1.6)
		"come":
			draw_icon(ci, "heart", c + Vector2(r * 0.3, -r * 0.3), r * 0.9)
			ci.draw_line(c + Vector2(-r * 0.7, r * 0.5), c + Vector2(r * 0.1, r * 0.5), w, lw, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.4, r * 0.5), c + Vector2(r * 0.05, r * 0.25), c + Vector2(r * 0.05, r * 0.75)]), w)
		"hand", "pet":
			D.ellipse(ci, c + Vector2(0, r * 0.2), r * 0.5, r * 0.45, w, false)
			for i in 4:
				D.rrect(ci, Rect2(c + Vector2(-r * 0.45 + i * r * 0.25, -r * 0.65), Vector2(r * 0.2, r * 0.7)), r * 0.1, w, false)
		"carry":
			draw_icon(ci, "heart", c + Vector2(0, -r * 0.1), r * 1.3)
			ci.draw_arc(c + Vector2(0, r * 0.1), r * 0.75, 0.2, PI - 0.2, 14, w, lw, true)
		"down":
			ci.draw_line(c + Vector2(0, -r * 0.7), c + Vector2(0, r * 0.4), w, lw, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, r * 0.8), c + Vector2(-r * 0.4, r * 0.3), c + Vector2(r * 0.4, r * 0.3)]), w)
			ci.draw_line(c + Vector2(-r * 0.7, r * 0.85), c + Vector2(r * 0.7, r * 0.85), w, lw * 0.7)
		"goto":
			draw_icon(ci, "house", c, r * 1.6)
		"eye":
			var pts := PackedVector2Array()
			for i in 13:
				pts.append(c + Vector2(lerp(-r * 0.85, r * 0.85, i / 12.0), -sin(PI * i / 12.0) * r * 0.5))
			for i in 13:
				pts.append(c + Vector2(lerp(r * 0.85, -r * 0.85, i / 12.0), sin(PI * i / 12.0) * r * 0.5))
			ci.draw_colored_polygon(pts, w)
			ci.draw_circle(c, r * 0.28, Color(0.35, 0.5, 0.8))
		"repair":
			# little hammer + sparkle
			ci.draw_line(c + Vector2(-r * 0.55, r * 0.7), c + Vector2(r * 0.2, -r * 0.1), Color("#e8b27e") * tint, lw * 1.3, true)
			D.rrect(ci, Rect2(c + Vector2(-r * 0.05, -r * 0.6), Vector2(r * 0.7, r * 0.4)), r * 0.08, w, false)
			D.poly(ci, D.star_points(c + Vector2(r * 0.55, r * 0.45), r * 0.3, r * 0.12), Color("#f7cf46") * tint, false)
		"close":
			ci.draw_line(c + Vector2(-r * 0.55, -r * 0.55), c + Vector2(r * 0.55, r * 0.55), w, lw * 1.2, true)
			ci.draw_line(c + Vector2(r * 0.55, -r * 0.55), c + Vector2(-r * 0.55, r * 0.55), w, lw * 1.2, true)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.6, 0), c + Vector2(-r * 0.15, r * 0.45), c + Vector2(r * 0.65, -r * 0.5)]), w, lw * 1.3, true)
		"undo":
			ci.draw_arc(c + Vector2(0, r * 0.1), r * 0.55, PI * 1.1, PI * 2.3, 16, w, lw, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.85, -r * 0.1), c + Vector2(-r * 0.35, -r * 0.2), c + Vector2(-r * 0.6, r * 0.3)]), w)
		"flip":
			ci.draw_line(c + Vector2(0, -r * 0.8), c + Vector2(0, r * 0.8), w, lw * 0.6)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.15, -r * 0.5), c + Vector2(-r * 0.8, r * 0.5), c + Vector2(-r * 0.15, r * 0.5)]), w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.15, -r * 0.5), c + Vector2(r * 0.8, r * 0.5), c + Vector2(r * 0.15, r * 0.5)]), Color(1, 1, 1, 0.5) * tint)
		"box", "inventory":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.7, -r * 0.3), Vector2(r * 1.4, r * 0.95)), r * 0.1, Color("#e8c39e") * tint, false)
			D.poly(ci, PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.3), c + Vector2(r * 0.8, -r * 0.3), c + Vector2(r * 0.6, -r * 0.65), c + Vector2(-r * 0.6, -r * 0.65)]), Color("#d6a77f") * tint, false)
		"chest":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.8, -r * 0.2), Vector2(r * 1.6, r * 0.85)), r * 0.1, Color("#c98f62") * tint)
			var lid := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				lid.append(c + Vector2(cos(a) * r * 0.8, -r * 0.2 + sin(a) * r * 0.5))
			D.poly(ci, lid, Color("#e2a97a") * tint)
			D.rrect(ci, Rect2(c + Vector2(-r * 0.15, -r * 0.3), Vector2(r * 0.3, r * 0.35)), r * 0.05, Color("#f7cf46"))
		"lock":
			ci.draw_arc(c + Vector2(0, -r * 0.2), r * 0.35, PI, TAU, 12, w, lw, true)
			D.rrect(ci, Rect2(c + Vector2(-r * 0.5, -r * 0.2), Vector2(r * 1.0, r * 0.8)), r * 0.1, w, false)
		"record":
			ci.draw_circle(c, r * 0.6, Color("#ef5b5b") * tint)
			ci.draw_arc(c, r * 0.8, 0, TAU, 24, w, lw * 0.6, true)
		"stop":
			D.rrect(ci, Rect2(c - Vector2(r * 0.5, r * 0.5), Vector2(r, r)), r * 0.12, w, false)
		"bug":
			D.ellipse(ci, c + Vector2(0, r * 0.1), r * 0.45, r * 0.6, Color("#ef5b5b") * tint)
			ci.draw_circle(c + Vector2(0, -r * 0.55), r * 0.25, Color("#3a3a48"))
			for sy in [-0.1, 0.2, 0.5]:
				ci.draw_line(c + Vector2(-r * 0.4, r * sy), c + Vector2(-r * 0.8, r * (sy - 0.1)), Color("#3a3a48"), lw * 0.5)
				ci.draw_line(c + Vector2(r * 0.4, r * sy), c + Vector2(r * 0.8, r * (sy - 0.1)), Color("#3a3a48"), lw * 0.5)
		"trash":
			D.rrect(ci, Rect2(c + Vector2(-r * 0.45, -r * 0.4), Vector2(r * 0.9, r * 1.1)), r * 0.1, w, false)
			ci.draw_line(c + Vector2(-r * 0.65, -r * 0.5), c + Vector2(r * 0.65, -r * 0.5), w, lw)
		"share":
			for p in [Vector2(-0.5, 0), Vector2(0.45, -0.5), Vector2(0.45, 0.5)]:
				ci.draw_circle(c + p * r, r * 0.22, w)
			ci.draw_line(c + Vector2(-r * 0.5, 0), c + Vector2(r * 0.45, -r * 0.5), w, lw * 0.7)
			ci.draw_line(c + Vector2(-r * 0.5, 0), c + Vector2(r * 0.45, r * 0.5), w, lw * 0.7)
		"plus":
			ci.draw_line(c + Vector2(-r * 0.6, 0), c + Vector2(r * 0.6, 0), w, lw * 1.3, true)
			ci.draw_line(c + Vector2(0, -r * 0.6), c + Vector2(0, r * 0.6), w, lw * 1.3, true)
		"minus":
			ci.draw_line(c + Vector2(-r * 0.6, 0), c + Vector2(r * 0.6, 0), w, lw * 1.3, true)
		"left", "right":
			var sx := -1.0 if name == "left" else 1.0
			ci.draw_polyline(PackedVector2Array([c + Vector2(-sx * r * 0.3, -r * 0.6), c + Vector2(sx * r * 0.35, 0), c + Vector2(-sx * r * 0.3, r * 0.6)]), w, lw * 1.3, true)
		"hide":
			_ui_icon(ci, "eye", c, r, tint)
			ci.draw_line(c + Vector2(-r * 0.8, r * 0.7), c + Vector2(r * 0.8, -r * 0.7), Color(0.9, 0.4, 0.5), lw)
		"family", "parent":
			ci.draw_circle(c + Vector2(-r * 0.35, -r * 0.45), r * 0.25, w)
			D.rrect(ci, Rect2(c + Vector2(-r * 0.65, -r * 0.15), Vector2(r * 0.6, r * 0.9)), r * 0.25, w, false)
			ci.draw_circle(c + Vector2(r * 0.4, -r * 0.15), r * 0.18, w)
			D.rrect(ci, Rect2(c + Vector2(r * 0.17, r * 0.08), Vector2(r * 0.46, r * 0.65)), r * 0.2, w, false)
		_:
			ci.draw_circle(c, r * 0.5, w)


static func _z(ci: CanvasItem, p: Vector2, s: float, col: Color, lw: float) -> void:
	ci.draw_polyline(PackedVector2Array([p + Vector2(-s, -s), p + Vector2(s, -s), p + Vector2(-s, s), p + Vector2(s, s)]), col, lw, true)
