class_name DrawUtil
extends RefCounted
## Vector drawing helpers shared by all painters: rounded shapes, vertical
## gradients, soft contact shadows. Everything is resolution independent, so
## zooming the camera to 2x stays crisp (no raster upscaling).

const OUTLINE := Color(0.36, 0.24, 0.26, 0.55)


static func rrect_points(r: Rect2, rad: float, seg: int = 5) -> PackedVector2Array:
	rad = min(rad, min(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(r.position.x + r.size.x - rad, r.position.y + rad), -PI / 2.0],
		[Vector2(r.position.x + r.size.x - rad, r.position.y + r.size.y - rad), 0.0],
		[Vector2(r.position.x + rad, r.position.y + r.size.y - rad), PI / 2.0],
		[Vector2(r.position.x + rad, r.position.y + rad), PI],
	]
	for c in corners:
		for i in seg + 1:
			var a: float = c[1] + (PI / 2.0) * i / seg
			pts.append(c[0] + Vector2(cos(a), sin(a)) * rad)
	return pts


static func ellipse_points(c: Vector2, rx: float, ry: float, seg: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * i / seg
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Fill polygon with a vertical gradient (top colour -> bottom colour).
static func gradient_poly(ci: CanvasItem, pts: PackedVector2Array, top: Color, bottom: Color) -> void:
	if pts.size() < 3:
		return
	var y0 := INF
	var y1 := -INF
	for p in pts:
		y0 = min(y0, p.y)
		y1 = max(y1, p.y)
	var cols := PackedColorArray()
	for p in pts:
		var t := 0.0 if y1 - y0 < 0.01 else (p.y - y0) / (y1 - y0)
		cols.append(top.lerp(bottom, t))
	ci.draw_polygon(pts, cols)


static func rrect(ci: CanvasItem, r: Rect2, rad: float, col: Color, outline := true, shade := 0.12) -> void:
	var pts := rrect_points(r, rad)
	gradient_poly(ci, pts, col.lightened(shade * 0.6), col.darkened(shade))
	if outline:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, OUTLINE, 2.0, true)


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, outline := true, shade := 0.12) -> void:
	var pts := ellipse_points(c, rx, ry)
	gradient_poly(ci, pts, col.lightened(shade * 0.6), col.darkened(shade))
	if outline:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, OUTLINE, 2.0, true)


static func poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, outline := true, shade := 0.1) -> void:
	gradient_poly(ci, pts, col.lightened(shade * 0.6), col.darkened(shade))
	if outline:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, OUTLINE, 2.0, true)


## Soft contact shadow (stacked translucent ellipses = cheap blur).
static func shadow(ci: CanvasItem, c: Vector2, rx: float, ry: float, strength := 0.22) -> void:
	for i in 4:
		var k := 1.0 + i * 0.12
		ci.draw_colored_polygon(ellipse_points(c, rx * k, ry * k, 24), Color(0.25, 0.12, 0.12, strength / (i + 1.6)))


static func star_points(c: Vector2, r_out: float, r_in: float, n := 5, rot := -PI / 2.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var r := r_out if i % 2 == 0 else r_in
		var a := rot + PI * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func heart_points(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 40:
		var t := TAU * i / 40.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * s / 17.0)
	return pts


static func cloud(ci: CanvasItem, c: Vector2, w: float, col: Color) -> void:
	var r := w * 0.22
	for o in [Vector2(-0.3, 0.05), Vector2(0, -0.12), Vector2(0.3, 0.05), Vector2(-0.12, 0.1), Vector2(0.15, 0.12)]:
		ci.draw_circle(c + Vector2(o.x * w, o.y * w), r * (1.0 if o.y < 0 else 0.85), col)


static func limb(ci: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color, outline := true) -> void:
	if outline:
		ci.draw_line(a, b, OUTLINE, w + 3.0, true)
		ci.draw_circle(a, (w + 3.0) * 0.5, OUTLINE)
		ci.draw_circle(b, (w + 3.0) * 0.5, OUTLINE)
	ci.draw_line(a, b, col, w, true)
	ci.draw_circle(a, w * 0.5, col)
	ci.draw_circle(b, w * 0.5, col)


## Tapered limb polygon from a (width wa) to b (width wb).
static func taper(ci: CanvasItem, a: Vector2, b: Vector2, wa: float, wb: float, col: Color, outline := true) -> void:
	var dir := (b - a)
	if dir.length() < 0.01:
		ci.draw_circle(a, wa * 0.5, col)
		return
	var n := dir.normalized().orthogonal()
	var pts := PackedVector2Array([a + n * wa * 0.5, b + n * wb * 0.5, b - n * wb * 0.5, a - n * wa * 0.5])
	if outline:
		var o := PackedVector2Array([a + n * (wa * 0.5 + 1.5), b + n * (wb * 0.5 + 1.5), b - n * (wb * 0.5 + 1.5), a - n * (wa * 0.5 + 1.5)])
		ci.draw_colored_polygon(o, OUTLINE)
		ci.draw_circle(a, wa * 0.5 + 1.5, OUTLINE)
		ci.draw_circle(b, wb * 0.5 + 1.5, OUTLINE)
	ci.draw_colored_polygon(pts, col)
	ci.draw_circle(a, wa * 0.5, col)
	ci.draw_circle(b, wb * 0.5, col)
