class_name FurniturePainter
extends RefCounted
## Draws every furniture "shape" from catalog data (colours + size), so a new
## variant needs only data. Projection: oblique top-down. Origin = front-centre
## of the footprint on the floor; footprint spans x [-w/2, w/2], y [-d, 0].
## A point on a surface of height H at depth y is drawn at (x, y - H).

const D := preload("res://scripts/core/draw_util.gd")


const WEAR_MAX := 6.0
static var _tex_cache: Dictionary = {}


static func tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[path]


## Picture beds/furniture: catalog "sprite" (+ optional "sprite_worn") drawn so the
## picture's bottom sits on the floor line at the front, scaled to the footprint width.
static func sprite_tex(def: Dictionary, state: Dictionary, anim: Dictionary = {}) -> Texture2D:
	var path: String = def.get("sprite", "")
	if def.has("sprite_busy") and bool(anim.get("occupied", false)):
		path = def["sprite_busy"]   # e.g. the pet bath fills with water only while washing
	if def.has("sprite_worn") and float(state.get("wear", 0.0)) >= WEAR_MAX:
		path = def["sprite_worn"]
	return tex(path)


static func sprite_rect(def: Dictionary, t: Texture2D) -> Rect2:
	var w := float(def.get("size", {}).get("w", 100))
	var k := w / float(t.get_width())
	var hh := float(t.get_height()) * k
	return Rect2(-w / 2, -hh, w, hh)


## Draws the picture from fraction `from` to `to` of its height (0 = top).
static func draw_sprite_part(ci: CanvasItem, def: Dictionary, state: Dictionary, from := 0.0, to := 1.0, anim: Dictionary = {}) -> void:
	var t := sprite_tex(def, state, anim)
	if t == null:
		return
	var r := sprite_rect(def, t)
	var th := float(t.get_height())
	ci.draw_texture_rect_region(t, Rect2(r.position.x, r.position.y + r.size.y * from, r.size.x, r.size.y * (to - from)), Rect2(0, th * from, t.get_width(), th * (to - from)))


static func cols(def: Dictionary) -> Dictionary:
	var c: Dictionary = def.get("colors", {})
	return {
		"main": Content.color(c.get("main", "#ffffff")),
		"accent": Content.color(c.get("accent", "#ffffff")),
		"wood": Content.color(c.get("wood", "#c89a70")),
		"trim": Content.color(c.get("trim", "#f39bb8")),
	}


## anim: Dictionary with optional keys: chair_pull (0..1), doors (0..1), t (seconds), occupied (bool)
static func draw(ci: CanvasItem, def: Dictionary, state: Dictionary, anim: Dictionary) -> void:
	var sz: Dictionary = def.get("size", {})
	var w := float(sz.get("w", 100))
	var d := float(sz.get("d", 50))
	var h := float(sz.get("h", 100))
	var c := cols(def)
	var deco: String = def.get("deco", "")
	if def.has("sprite") and sprite_tex(def, state) != null:
		D.shadow(ci, Vector2(0, -6), w * 0.5, 16, 0.16)
		draw_sprite_part(ci, def, state, 0.0, 1.0, anim)
		return
	match def.get("shape", ""):
		"bed": _bed(ci, w, d, h, c, deco, anim)
		"sofa": _sofa(ci, w, d, h, c, deco)
		"armchair": _armchair(ci, w, d, h, c, deco)
		"desk": _desk(ci, w, d, h, c, anim)
		"dining": _dining(ci, w, d, h, c, deco, anim)
		"wardrobe": _wardrobe(ci, w, d, h, c, deco, anim)
		"mirror": _mirror(ci, w, d, h, c, deco)
		"shelf": _shelf(ci, w, d, h, c, deco)
		"pet_bed": _pet_bed(ci, w, d, h, c, deco)
		"pet_house": _pet_house(ci, w, d, h, c, deco, anim)
		"scratcher": _scratcher(ci, w, d, h, c, deco)
		"tunnel": _tunnel(ci, w, d, h, c)
		"bowl": _bowl(ci, w, d, h, c, def, state, deco)
		"bathtub": _bathtub(ci, w, d, h, c, anim)
		"groom_kit": _groom(ci, w, d, h, c)
		"ball": _ball_icon(ci, w, c, deco)
		"plush": _plush(ci, w, h, c)
		"teaser": _teaser(ci, w, d, h, c, anim)
		"lamp_floor": _lamp_floor(ci, w, d, h, c, state)
		"lamp_small": _lamp_small(ci, w, d, h, c, state)
		"tv": _tv(ci, w, d, h, c, state, anim)
		"radio": _radio(ci, w, d, h, c, state, anim)
		"clock": _clock(ci, w, h, c, anim)
		"rug": _rug(ci, w, d, c, deco)
		"plant": _plant(ci, w, d, h, c)
		"picture": _picture(ci, w, h, c, deco)
		"garland": _garland(ci, w, h, c, anim)
		"swatch_wall", "swatch_floor", "swatch_theme": _swatch(ci, def, c)
		"icon_fish": IconPainter.draw_icon(ci, "fish", Vector2(0, -20), 40.0)
		"icon_bone": IconPainter.draw_icon(ci, "bone", Vector2(0, -20), 40.0)
		_:
			D.rrect(ci, Rect2(-w / 2, -h, w, h), 8, c["main"])


## Box helper: footprint x0..x1, depth yb(back)..yf(front), from height h0 to h1.
static func box(ci: CanvasItem, x0: float, x1: float, yf: float, yb: float, h0: float, h1: float, col: Color, top_col: Variant = null, rad := 6.0) -> void:
	var tc: Color = col.lightened(0.12) if top_col == null else top_col
	var top := PackedVector2Array([Vector2(x0, yb - h1), Vector2(x1, yb - h1), Vector2(x1, yf - h1), Vector2(x0, yf - h1)])
	D.poly(ci, top, tc, true, 0.05)
	D.rrect(ci, Rect2(x0, yf - h1, x1 - x0, h1 - h0), rad, col, true, 0.16)


static func _bed(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, deco: String, anim: Dictionary) -> void:
	D.shadow(ci, Vector2(0, -d * 0.45), w * 0.55, d * 0.6)
	var hb_x := -w / 2.0
	# headboard (left side, at back)
	var hb := Rect2(hb_x - 6, -d - h, 34, h + d * 0.2)
	D.rrect(ci, hb, 16, c["wood"])
	ci.draw_circle(Vector2(hb_x + 11, -d - h + 14), 13, c["trim"])
	if deco == "stars":
		for i in 3:
			ci.draw_colored_polygon(D.star_points(Vector2(hb_x + 11, -d - h * 0.55 + i * 34), 10, 4.5), c["trim"])
	elif deco == "clouds":
		D.cloud(ci, Vector2(hb_x + 12, -d - h * 0.5), 46, Color.WHITE)
	# frame + legs
	box(ci, -w / 2 + 14, w / 2, 0, -d, 0, h * 0.18, c["wood"])
	for x in [-w / 2 + 22, w / 2 - 10]:
		D.rrect(ci, Rect2(x - 7, -h * 0.06, 14, h * 0.06 + 2), 3, c["wood"].darkened(0.2))
	# mattress
	box(ci, -w / 2 + 18, w / 2 - 4, -2, -d + 4, h * 0.18, h * 0.3, c["accent"], c["accent"].lightened(0.05), 10)
	# blanket over front 2/3
	var bx := -w / 2 + w * 0.36
	var blanket := PackedVector2Array([Vector2(bx, -d + 4 - h * 0.31), Vector2(w / 2 - 2, -d + 4 - h * 0.31), Vector2(w / 2 + 4, -h * 0.30), Vector2(w / 2 + 4, -h * 0.12), Vector2(bx - 4, -h * 0.12), Vector2(bx - 6, -h * 0.3)])
	D.poly(ci, blanket, c["main"], true, 0.15)
	for i in 4:
		var yy := -h * 0.30 + 6
		ci.draw_line(Vector2(bx + 20 + i * (w * 0.15), yy), Vector2(bx + 30 + i * (w * 0.15), -h * 0.13), c["main"].darkened(0.08), 3)
	if deco == "stars":
		for i in 4:
			ci.draw_colored_polygon(D.star_points(Vector2(bx + 30 + i * w * 0.14, -h * 0.22), 7, 3), c["trim"])
	# pillow near headboard
	D.ellipse(ci, Vector2(-w / 2 + 62, -d * 0.62 - h * 0.33), 38, 18, Color.WHITE, true, 0.08)
	# foot board
	D.rrect(ci, Rect2(w / 2 - 14, -h * 0.55, 22, h * 0.55), 10, c["wood"])
	ci.draw_circle(Vector2(w / 2 - 3, -h * 0.55 + 6), 8, c["trim"])


static func _sofa(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, deco: String) -> void:
	D.shadow(ci, Vector2(0, -d * 0.4), w * 0.55, d * 0.55)
	# back rest
	D.rrect(ci, Rect2(-w / 2 + 10, -d - h * 0.95, w - 20, h * 0.62 + 10), 26, c["main"].darkened(0.04))
	# seat
	box(ci, -w / 2 + 16, w / 2 - 16, 0, -d + 18, h * 0.08, h * 0.3, c["main"], c["accent"], 12)
	# cushions
	for i in 2:
		var cx := -w * 0.22 + i * w * 0.44
		D.rrect(ci, Rect2(cx - w * 0.2, -d + 10 - h * 0.62, w * 0.4, h * 0.36), 18, c["accent"].lerp(c["main"], 0.4))
		if deco == "flowers":
			IconPainter.draw_icon(ci, "flower", Vector2(cx, -d - h * 0.44), 26)
	# arms
	for sx in [-1.0, 1.0]:
		D.rrect(ci, Rect2(sx * (w / 2) - (26 if sx > 0 else 0) + (0 if sx > 0 else -4), -h * 0.55, 30, h * 0.55), 14, c["trim"])
	for x in [-w / 2 + 26, w / 2 - 26]:
		D.rrect(ci, Rect2(x - 6, -h * 0.08, 12, h * 0.08 + 2), 3, c["wood"])


static func _armchair(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, deco: String) -> void:
	D.shadow(ci, Vector2(0, -d * 0.4), w * 0.55, d * 0.55)
	D.rrect(ci, Rect2(-w / 2 + 12, -d - h * 0.9, w - 24, h * 0.62 + 10), 30, c["main"].darkened(0.05))
	if deco == "flowers":
		IconPainter.draw_icon(ci, "flower", Vector2(0, -d - h * 0.6), 30)
	box(ci, -w / 2 + 14, w / 2 - 14, 0, -d + 14, h * 0.1, h * 0.36, c["main"], c["accent"], 12)
	for sx in [-1.0, 1.0]:
		var x := -w / 2 - 2 if sx < 0 else w / 2 - 22
		D.rrect(ci, Rect2(x, -h * 0.6, 24, h * 0.6), 12, c["trim"])
	for x in [-w / 2 + 20, w / 2 - 20]:
		D.rrect(ci, Rect2(x - 5, -h * 0.1, 10, h * 0.1 + 2), 3, c["wood"])


static func chair(ci: CanvasItem, x: float, y: float, seat_h: float, wd: float, c: Dictionary, back_side: int) -> void:
	# simple kid chair seen from the side/front; back_side: -1 back to the left, +1 right, 0 back behind
	D.shadow(ci, Vector2(x, y - 6), wd * 0.6, 10, 0.18)
	for lx in [x - wd * 0.4, x + wd * 0.4]:
		D.rrect(ci, Rect2(lx - 4, y - seat_h, 8, seat_h), 3, c["wood"].darkened(0.15))
	box(ci, x - wd / 2, x + wd / 2, y, y - 26, seat_h - 8, seat_h, c["wood"], c["trim"], 4)
	if back_side == 0:
		D.rrect(ci, Rect2(x - wd / 2 + 4, y - 26 - seat_h - 70, wd - 8, 66), 12, c["wood"])
		ci.draw_circle(Vector2(x, y - 26 - seat_h - 38), 9, c["trim"])


static func _desk(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, anim: Dictionary) -> void:
	var desk_d := d * 0.62
	var top_h := h * 0.62
	D.shadow(ci, Vector2(0, -d * 0.6), w * 0.55, d * 0.5)
	# back shelf with books
	D.rrect(ci, Rect2(-w / 2 + 8, -d - h, w - 16, h * 0.42), 10, c["main"].darkened(0.08))
	var bx := -w / 2 + 22
	var bcols := [Color("#f39bb8"), Color("#8ec9e8"), Color("#f6d36b"), Color("#a8dcc8"), Color("#c7b6ef")]
	for i in 7:
		var bw := 14.0 + (i % 3) * 3
		D.rrect(ci, Rect2(bx, -d - h + 16 + (i % 2) * 6, bw, h * 0.3 - (i % 2) * 6), 3, bcols[i % 5], true, 0.1)
		bx += bw + 3
	IconPainter.draw_icon(ci, "globe", Vector2(w / 2 - 50, -d - h + h * 0.22), 46)
	# legs + top
	for x in [-w / 2 + 14, w / 2 - 14]:
		D.rrect(ci, Rect2(x - 8, -(d - desk_d) - top_h, 16, top_h), 4, c["wood"])
	box(ci, -w / 2, w / 2, -(d - desk_d), -d, top_h - 14, top_h, c["main"], c["accent"], 6)
	# drawer
	D.rrect(ci, Rect2(w / 2 - 110, -(d - desk_d) - top_h + 16, 90, 34), 6, c["main"].darkened(0.06))
	ci.draw_circle(Vector2(w / 2 - 65, -(d - desk_d) - top_h + 33), 5, c["trim"])
	# items on desk
	D.rrect(ci, Rect2(-40, -d + 10 - top_h - 8, 60, 10), 2, Color.WHITE)
	D.rrect(ci, Rect2(-w / 2 + 30, -d + 20 - top_h - 30, 26, 30), 5, c["trim"])
	# chair (pulled out with anim)
	var pull: float = anim.get("chair_pull", 0.0)
	chair(ci, -w * 0.05, -4.0 - (1.0 - pull) * (d - desk_d) * 0.5, h * 0.27, 86, c, 2)


static func _dining(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, deco: String, anim: Dictionary) -> void:
	D.shadow(ci, Vector2(w * 0.1, -d * 0.5), w * 0.5, d * 0.55)
	# stool on the left (where the girl sits, facing right)
	var sx := -w * 0.38
	chair(ci, sx, -d * 0.08 + 6, h * 0.36, 60, c, 2)
	# table
	var tx0 := -w * 0.18
	var tx1 := w / 2
	if deco == "round":
		for x in [tx0 + 30, tx1 - 30]:
			D.rrect(ci, Rect2(x - 6, -d * 0.2 - h * 0.92, 12, h * 0.92), 4, c["wood"])
		D.ellipse(ci, Vector2((tx0 + tx1) / 2, -d * 0.55 - h), (tx1 - tx0) * 0.55, d * 0.5, c["main"], true, 0.06)
		D.rrect(ci, Rect2(tx0 - 6, -d * 0.55 - h, tx1 - tx0 + 12, 14), 7, c["main"].darkened(0.1))
	else:
		for x in [tx0 + 12, tx1 - 12]:
			D.rrect(ci, Rect2(x - 7, -d * 0.12 - h * 0.92, 14, h * 0.92), 4, c["wood"])
		box(ci, tx0, tx1, -d * 0.12, -d, h - 12, h, c["wood"], c["main"], 6)
		# tablecloth stripe
		D.rrect(ci, Rect2(tx0 + 14, -d * 0.12 - h, tx1 - tx0 - 28, 22), 6, c["accent"])
	# plate + cup
	var occ: bool = anim.get("occupied", false)
	D.ellipse(ci, Vector2(tx0 + 46, -d * 0.55 - h), 26, 10, Color.WHITE, true, 0.04)
	if occ:
		IconPainter.draw_icon(ci, "apple", Vector2(tx0 + 46, -d * 0.55 - h - 10), 22)
	D.rrect(ci, Rect2(tx1 - 70, -d * 0.6 - h - 30, 22, 30), 5, c["trim"])


static func _wardrobe(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, deco: String, anim: Dictionary) -> void:
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.55, d * 0.6)
	if deco == "castle":
		for i in 3:
			var tx := -w / 2 + 20 + i * (w - 40) / 2.0
			D.poly(ci, PackedVector2Array([Vector2(tx - 22, -d - h + 10), Vector2(tx, -d - h - 40), Vector2(tx + 22, -d - h + 10)]), c["trim"])
	box(ci, -w / 2, w / 2, 0, -d, 8, h, c["main"], c["main"].lightened(0.1), 10)
	var doors: float = anim.get("doors", 0.0)
	var top := -h + 18
	var dh := h * 0.72
	var dw := w / 2 - 14
	# inside (visible when open)
	D.rrect(ci, Rect2(-w / 2 + 10, top, w - 20, dh), 6, c["wood"].darkened(0.25), false)
	if doors > 0.05:
		var dress_cols := [Color("#f59ab8"), Color("#a9c6f2"), Color("#ffd86b"), Color("#d6b4f5")]
		for i in 4:
			var hx := -w / 2 + 30 + i * (w - 60) / 3.0
			ci.draw_line(Vector2(-w / 2 + 14, top + 16), Vector2(w / 2 - 14, top + 16), Color("#e2c38f"), 4)
			D.poly(ci, PackedVector2Array([Vector2(hx - 10, top + 20), Vector2(hx + 10, top + 20), Vector2(hx + 20, top + 110), Vector2(hx - 20, top + 110)]), dress_cols[i], true, 0.1)
	# doors swing: drawn narrower as they open (perspective squash)
	var open_w: float = dw * (1.0 - doors * 0.82)
	D.rrect(ci, Rect2(-w / 2 + 10 - doors * 18, top, open_w, dh), 8, c["main"].darkened(0.03))
	D.rrect(ci, Rect2(w / 2 - 10 - open_w + doors * 18, top, open_w, dh), 8, c["main"].darkened(0.03))
	if doors < 0.4:
		ci.draw_circle(Vector2(-10, top + dh * 0.5), 6, c["trim"])
		ci.draw_circle(Vector2(10, top + dh * 0.5), 6, c["trim"])
		D.heart_points(Vector2.ZERO, 1)
		ci.draw_colored_polygon(D.heart_points(Vector2(-w / 4 + 4, top + 50), 14), c["accent"])
		ci.draw_colored_polygon(D.heart_points(Vector2(w / 4 - 4, top + 50), 14), c["accent"])
	# drawers
	D.rrect(ci, Rect2(-w / 2 + 10, top + dh + 8, w - 20, h - dh - 34), 6, c["main"].darkened(0.05))
	ci.draw_line(Vector2(-18, top + dh + (h - dh - 34) * 0.5 + 8), Vector2(18, top + dh + (h - dh - 34) * 0.5 + 8), c["trim"], 5, true)
	D.rrect(ci, Rect2(-w / 2 - 4, -h - 12, w + 8, 18), 8, c["trim"])


static func _mirror(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, deco: String) -> void:
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.6, 14)
	ci.draw_line(Vector2(-w * 0.32, 0), Vector2(0, -h * 0.25), c["wood"].darkened(0.2), 7, true)
	ci.draw_line(Vector2(w * 0.32, 0), Vector2(0, -h * 0.25), c["wood"].darkened(0.2), 7, true)
	var cy := -d - h * 0.58
	D.ellipse(ci, Vector2(0, cy), w * 0.5, h * 0.4, c["wood"])
	D.ellipse(ci, Vector2(0, cy), w * 0.4, h * 0.34, c["accent"], false, 0.0)
	ci.draw_line(Vector2(-w * 0.18, cy - h * 0.18), Vector2(w * 0.05, cy - h * 0.3), Color(1, 1, 1, 0.8), 6, true)
	ci.draw_line(Vector2(-w * 0.2, cy - h * 0.06), Vector2(w * 0.1, cy - h * 0.22), Color(1, 1, 1, 0.5), 4, true)
	if deco == "flowers":
		for a in [-0.8, 0.0, 0.8]:
			IconPainter.draw_icon(ci, "flower", Vector2(sin(a) * w * 0.5, cy - cos(a) * h * 0.4), 22)
	else:
		ci.draw_colored_polygon(D.heart_points(Vector2(0, cy - h * 0.42), 12), c["trim"])


static func _shelf(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, deco: String) -> void:
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.55, d * 0.6)
	box(ci, -w / 2, w / 2, 0, -d, 0, h, c["main"], c["accent"], 8)
	for i in 2:
		var y := -h + 16 + i * (h * 0.45)
		D.rrect(ci, Rect2(-w / 2 + 12, y, w - 24, h * 0.36), 6, c["wood"].darkened(0.15), false)
		var bx := -w / 2 + 20
		for j in 4:
			var col: Color = [Color("#f39bb8"), Color("#8ec9e8"), Color("#f6d36b"), Color("#a8dcc8")][(i + j) % 4]
			D.rrect(ci, Rect2(bx, y + 6 + (j % 2) * 4, 13, h * 0.3 - (j % 2) * 4), 3, col, true, 0.1)
			bx += 17
		if i == 0:
			IconPainter.draw_icon(ci, "star" if deco == "stars" else "flower", Vector2(w / 2 - 40, y + h * 0.18), 30)
		else:
			D.rrect(ci, Rect2(w / 2 - 70, y + 10, 46, h * 0.22), 8, c["trim"])


static func _pet_bed(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, deco: String) -> void:
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.55, d * 0.6)
	if deco == "heart":
		var pts := D.heart_points(Vector2(0, -d * 0.55 - h * 0.4), w * 0.5)
		for i in pts.size():
			pts[i].y = -d * 0.55 - h * 0.4 + (pts[i].y + d * 0.55 + h * 0.4) * 0.55
		D.poly(ci, pts, c["main"])
	else:
		D.ellipse(ci, Vector2(0, -d * 0.5 - h * 0.35), w * 0.5, d * 0.55 + h * 0.3, c["main"])
	D.ellipse(ci, Vector2(0, -d * 0.55 - h * 0.45), w * 0.36, d * 0.36, c["accent"], false, 0.05)
	for i in 5:
		ci.draw_circle(Vector2(-w * 0.32 + i * w * 0.16, -d * 0.12 - h * 0.15), 3, c["trim"])


static func _pet_house(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, deco: String, anim: Dictionary) -> void:
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.58, d * 0.6)
	var body_h := h * 0.62
	box(ci, -w / 2, w / 2, 0, -d, 0, body_h, c["main"], c["main"].lightened(0.15), 8)
	# roof
	if deco == "castle":
		for i in 3:
			var tx := -w / 2 + 18 + i * (w - 36) / 2.0
			D.rrect(ci, Rect2(tx - 16, -d - body_h - 40, 32, 44), 4, c["main"].darkened(0.05))
			D.poly(ci, PackedVector2Array([Vector2(tx - 20, -d - body_h - 38), Vector2(tx, -d - body_h - 80), Vector2(tx + 20, -d - body_h - 38)]), c["trim"])
	else:
		D.poly(ci, PackedVector2Array([Vector2(-w / 2 - 14, -body_h + 4), Vector2(0, -body_h - h * 0.45 - d * 0.4), Vector2(w / 2 + 14, -body_h + 4)]), c["trim"])
		D.poly(ci, PackedVector2Array([Vector2(-w / 2 - 14, -body_h + 4), Vector2(-w / 2 + 4, -body_h - d + 8), Vector2(0, -body_h - h * 0.45 - d * 0.4)]), c["trim"].darkened(0.1))
	# entrance (dark arch)
	var ew := w * 0.48
	var eh := body_h * 0.72
	var arch := D.rrect_points(Rect2(-ew / 2, -eh, ew, eh + 12), ew * 0.5)
	ci.draw_colored_polygon(arch, c["accent"])
	ci.draw_rect(Rect2(-ew / 2 - 2, -2, ew + 4, 6), c["main"].darkened(0.1))
	ci.draw_colored_polygon(D.heart_points(Vector2(0, -body_h + 2 - 12), 9), c["trim"])


## Front part of the house drawn over an occupant (keeps them "inside").
static func draw_house_front(ci: CanvasItem, def: Dictionary) -> void:
	var sz: Dictionary = def.get("size", {})
	var w := float(sz.get("w", 100))
	var h := float(sz.get("h", 100))
	var c := cols(def)
	var body_h := h * 0.62
	var ew := w * 0.48
	var eh := body_h * 0.72
	# side walls of the front face, leaving the arch open
	D.rrect(ci, Rect2(-w / 2, -body_h, (w - ew) / 2, body_h), 6, c["main"], true, 0.16)
	D.rrect(ci, Rect2(ew / 2, -body_h, (w - ew) / 2, body_h), 6, c["main"], true, 0.16)
	ci.draw_rect(Rect2(-ew / 2, -body_h, ew, body_h - eh + ew * 0.25), c["main"])
	ci.draw_colored_polygon(D.heart_points(Vector2(0, -body_h + 2 - 12), 9), c["trim"])


static func _scratcher(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, deco: String) -> void:
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.7, d * 0.6)
	box(ci, -w / 2, w / 2, 0, -d, 0, 16, c["accent"], c["accent"].lightened(0.1), 6)
	var pw := w * 0.36
	D.rrect(ci, Rect2(-pw / 2, -d * 0.5 - h, pw, h - 10), 6, c["main"])
	for i in int(h / 14):
		var y := -d * 0.5 - h + 10 + i * 14
		ci.draw_line(Vector2(-pw / 2 + 2, y), Vector2(pw / 2 - 2, y + 6), c["main"].darkened(0.15), 2)
	box(ci, -w / 2 + 4, w / 2 - 4, -d * 0.3, -d * 0.8, h - 4, h + 12, c["accent"], null, 8)
	if deco == "tower":
		box(ci, -w / 2 + 4, w / 2 - 4, -d * 0.3, -d * 0.8, h * 0.5 - 4, h * 0.5 + 10, c["accent"], null, 8)
	ci.draw_line(Vector2(w * 0.3, -d * 0.6 - h - 12), Vector2(w * 0.5, -d * 0.6 - h + 30), c["wood"], 2)
	D.ellipse(ci, Vector2(w * 0.5, -d * 0.6 - h + 36), 9, 9, c["trim"])


static func _tunnel(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary) -> void:
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.55, d * 0.55)
	var segs := 6
	var ring := [c["main"], c["accent"], c["wood"], c["trim"]]
	for i in segs:
		var x0 := -w / 2 + i * w / segs
		D.rrect(ci, Rect2(x0, -d * 0.4 - h, w / segs + 2, h), h * 0.45, ring[i % 4], false, 0.15)
	for sx in [-1.0, 1.0]:
		D.ellipse(ci, Vector2(sx * w / 2, -d * 0.4 - h * 0.5), h * 0.22, h * 0.5, ring[0].darkened(0.1))
		D.ellipse(ci, Vector2(sx * w / 2, -d * 0.4 - h * 0.5), h * 0.14, h * 0.4, Color(0.25, 0.18, 0.25), false)


static func _bowl(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, def: Dictionary, state: Dictionary, deco: String) -> void:
	D.shadow(ci, Vector2(0, -d * 0.4), w * 0.62, d * 0.45)
	var water: bool = def.get("interaction_profile", "") == "bowl_water"
	var amount := float(state.get("water" if water else "food", 0)) + float(state.get("treat", 0))
	var top_y := -h - d * 0.35
	var body := PackedVector2Array([Vector2(-w / 2, top_y), Vector2(w / 2, top_y), Vector2(w * 0.4, -d * 0.12), Vector2(-w * 0.4, -d * 0.12)])
	D.poly(ci, body, c["main"], true, 0.15)
	# rim + inside
	D.ellipse(ci, Vector2(0, top_y), w / 2, d * 0.32, c["main"].lightened(0.15), true, 0.0)
	D.ellipse(ci, Vector2(0, top_y + 1), w / 2 - 5, d * 0.25, c["wood"].darkened(0.25), false, 0.0)
	if amount > 0:
		var fill := clampf(amount / 3.0, 0.35, 1.0)
		if water:
			D.ellipse(ci, Vector2(0, top_y + 1), (w / 2 - 6) * fill, d * 0.22 * fill, c["accent"], false, 0.0)
			ci.draw_line(Vector2(-w * 0.15, top_y - 2), Vector2(w * 0.05, top_y - 2), Color(1, 1, 1, 0.8), 2)
		else:
			for i in int(4 + fill * 7):
				var a := i * 2.4
				ci.draw_circle(Vector2(cos(a) * w * 0.27 * fill, top_y + sin(a) * d * 0.12 - fill * 3), 4.5, c["accent"].darkened((i % 3) * 0.1))
			if float(state.get("treat", 0)) > 0:
				IconPainter.draw_icon(ci, "fish", Vector2(0, top_y - 8), 22)
	var mid := Vector2(0, (top_y - d * 0.12) * 0.5)
	if deco == "stars":
		ci.draw_colored_polygon(D.star_points(mid, 7, 3), Color.WHITE)
	elif deco == "fish":
		IconPainter.draw_icon(ci, "fish", mid, 18)
	else:
		ci.draw_circle(mid, 4, c["trim"])


static func _bathtub(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, anim: Dictionary) -> void:
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.55, d * 0.55)
	for x in [-w * 0.35, w * 0.35]:
		D.rrect(ci, Rect2(x - 8, -12, 16, 14), 6, c["wood"])
	D.ellipse(ci, Vector2(0, -d * 0.55 - h), w * 0.5, d * 0.45, c["main"].darkened(0.04), true, 0.0)
	D.ellipse(ci, Vector2(0, -d * 0.55 - h + 4), w * 0.44, d * 0.36, c["accent"], false, 0.0)
	if anim.get("occupied", false):
		for i in 7:
			var t: float = anim.get("t", 0.0) * 2.0 + i
			ci.draw_circle(Vector2(sin(t) * w * 0.35, -d * 0.6 - h - 8 - fmod(t * 10.0, 30.0)), 6 + (i % 3) * 2, Color(1, 1, 1, 0.75))
	var tub := D.rrect_points(Rect2(-w / 2, -d * 0.55 - h, w, h + d * 0.4), 34)
	var front := PackedVector2Array()
	for p in tub:
		if p.y >= -d * 0.55 - h + 2:
			front.append(p)
	D.poly(ci, front, c["main"], true, 0.1)
	ci.draw_line(Vector2(-w * 0.3, -d * 0.3 - h * 0.4), Vector2(-w * 0.1, -d * 0.3 - h * 0.4), c["trim"], 4, true)
	IconPainter.draw_icon(ci, "duck", Vector2(w * 0.25, -d * 0.8 - h - 8), 26)


static func _groom(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary) -> void:
	D.shadow(ci, Vector2(0, -d * 0.4), w * 0.6, d * 0.5)
	box(ci, -w / 2, w / 2, 0, -d, 0, h * 0.55, c["main"], c["accent"], 8)
	# brush on top
	D.rrect(ci, Rect2(-w * 0.35, -d * 0.6 - h * 0.55 - 12, w * 0.5, 12), 5, c["wood"])
	for i in 6:
		ci.draw_line(Vector2(-w * 0.32 + i * 6, -d * 0.6 - h * 0.55 - 12), Vector2(-w * 0.32 + i * 6, -d * 0.6 - h * 0.55 - 20), c["trim"].darkened(0.3), 2)
	D.rrect(ci, Rect2(w * 0.12, -d * 0.6 - h * 0.55 - 30, 14, 30), 5, c["trim"])


static func _ball_icon(ci: CanvasItem, w: float, c: Dictionary, deco: String) -> void:
	draw_ball(ci, Vector2(0, -w * 0.5), w * 0.5, c, deco, 0.0)


static func draw_ball(ci: CanvasItem, center: Vector2, r: float, c: Dictionary, deco: String, spin: float) -> void:
	D.ellipse(ci, center, r, r, c["main"], true, 0.2)
	if deco == "stars":
		ci.draw_colored_polygon(D.star_points(center + Vector2(cos(spin), sin(spin)) * r * 0.25, r * 0.45, r * 0.2, 5, spin), c["accent"])
	else:
		ci.draw_arc(center, r * 0.75, spin, spin + PI * 0.8, 12, c["accent"], 4, true)
		ci.draw_arc(center, r * 0.75, spin + PI, spin + PI * 1.8, 12, c["trim"], 4, true)
	ci.draw_circle(center + Vector2(-r * 0.35, -r * 0.35), r * 0.18, Color(1, 1, 1, 0.7))


static func _plush(ci: CanvasItem, w: float, h: float, c: Dictionary) -> void:
	draw_plush(ci, Vector2.ZERO, h, c)


static func draw_plush(ci: CanvasItem, base: Vector2, h: float, c: Dictionary) -> void:
	D.shadow(ci, base + Vector2(0, -2), h * 0.4, h * 0.12)
	D.ellipse(ci, base + Vector2(0, -h * 0.3), h * 0.32, h * 0.3, c["main"])
	for sx in [-1.0, 1.0]:
		D.ellipse(ci, base + Vector2(sx * h * 0.12, -h * 0.95), h * 0.08, h * 0.24, c["main"])
		D.ellipse(ci, base + Vector2(sx * h * 0.12, -h * 0.95), h * 0.04, h * 0.17, c["accent"], false)
	D.ellipse(ci, base + Vector2(0, -h * 0.68), h * 0.26, h * 0.22, c["main"])
	ci.draw_circle(base + Vector2(-h * 0.09, -h * 0.7), 3, c["trim"])
	ci.draw_circle(base + Vector2(h * 0.09, -h * 0.7), 3, c["trim"])
	ci.draw_circle(base + Vector2(0, -h * 0.62), 3, c["accent"])


static func _teaser(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, anim: Dictionary) -> void:
	D.shadow(ci, Vector2(0, -d * 0.4), w * 0.6, d * 0.4)
	ci.draw_line(Vector2(-w * 0.5, -6), Vector2(w * 0.4, -h), c["wood"], 5, true)
	var sway := sin(float(anim.get("t", 0.0)) * 3.0) * 6.0
	ci.draw_line(Vector2(w * 0.4, -h), Vector2(w * 0.5 + sway, -h * 0.35), Color(0.4, 0.3, 0.3), 1.5, true)
	for i in 3:
		D.ellipse(ci, Vector2(w * 0.5 + sway + (i - 1) * 6, -h * 0.3), 4, 10, [c["accent"], c["trim"], Color.WHITE][i], false)


static func _lamp_floor(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, state: Dictionary) -> void:
	var on: bool = state.get("on", false)
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.6, d * 0.4)
	D.ellipse(ci, Vector2(0, -d * 0.5), w * 0.45, 8, c["wood"])
	ci.draw_line(Vector2(0, -d * 0.5), Vector2(0, -d * 0.5 - h + 50), c["wood"].darkened(0.2), 6, true)
	var top := -d * 0.5 - h
	if on:
		for i in 4:
			ci.draw_circle(Vector2(0, top + 50), 70.0 + i * 30.0, Color(1, 0.92, 0.6, 0.07))
	var shade := PackedVector2Array([Vector2(-w * 0.35, top), Vector2(w * 0.35, top), Vector2(w * 0.75, top + 60), Vector2(-w * 0.75, top + 60)])
	D.poly(ci, shade, c["main"].lightened(0.2) if on else c["main"], true, 0.1)
	ci.draw_line(Vector2(-w * 0.7, top + 58), Vector2(w * 0.7, top + 58), c["trim"], 4, true)


static func _lamp_small(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, state: Dictionary) -> void:
	var on: bool = state.get("on", false)
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.5, d * 0.4)
	if on:
		for i in 3:
			ci.draw_circle(Vector2(0, -d * 0.5 - h * 0.7), 40.0 + i * 22.0, Color(1, 0.9, 0.6, 0.08))
	D.rrect(ci, Rect2(-w * 0.15, -d * 0.5 - h * 0.6, w * 0.3, h * 0.6), 6, c["wood"])
	var cap := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		cap.append(Vector2(cos(a) * w * 0.5, -d * 0.5 - h * 0.55 + sin(a) * h * 0.5))
	D.poly(ci, cap, c["main"].lightened(0.15) if on else c["main"], true, 0.1)
	for p in [Vector2(-w * 0.2, -h * 0.85), Vector2(w * 0.15, -h * 0.95), Vector2(0, -h * 0.7)]:
		ci.draw_circle(p + Vector2(0, -d * 0.5), 4, c["accent"])


static func _tv(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, state: Dictionary, anim: Dictionary) -> void:
	var on: bool = state.get("on", false)
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.55, d * 0.4)
	for x in [-w * 0.3, w * 0.3]:
		ci.draw_line(Vector2(x, 0), Vector2(x * 0.6, -h * 0.2), c["wood"], 5, true)
	box(ci, -w / 2, w / 2, -d * 0.2, -d, h * 0.2, h, c["main"], null, 14)
	var scr := Rect2(-w / 2 + 14, -d * 0.2 - h + 14, w * 0.68, h * 0.62)
	if on:
		var t: float = anim.get("t", 0.0)
		var top := Color.from_hsv(fmod(t * 0.05, 1.0), 0.35, 1.0)
		D.rrect(ci, scr, 12, top, false, 0.3)
		IconPainter.draw_icon(ci, ["cat", "star", "fish", "flower"][int(t / 3.0) % 4], scr.get_center() + Vector2(sin(t) * 10, 0), 34)
	else:
		D.rrect(ci, scr, 12, c["accent"], false, 0.2)
		ci.draw_line(scr.position + Vector2(10, 10), scr.position + Vector2(30, 6), Color(1, 1, 1, 0.4), 3)
	ci.draw_circle(Vector2(w / 2 - 22, -d * 0.2 - h * 0.7), 7, c["trim"])
	ci.draw_circle(Vector2(w / 2 - 22, -d * 0.2 - h * 0.45), 7, c["trim"])
	ci.draw_line(Vector2(-10, -d - h), Vector2(-26, -d - h - 26), c["wood"], 3, true)
	ci.draw_line(Vector2(10, -d - h), Vector2(26, -d - h - 26), c["wood"], 3, true)


static func _radio(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary, state: Dictionary, anim: Dictionary) -> void:
	var on: bool = state.get("on", false)
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.55, d * 0.4)
	box(ci, -w / 2, w / 2, 0, -d, 0, h, c["main"], null, 12)
	ci.draw_circle(Vector2(-w * 0.2, -h * 0.45), h * 0.26, c["accent"])
	for i in 3:
		ci.draw_arc(Vector2(-w * 0.2, -h * 0.45), h * 0.08 * (i + 1), 0, TAU, 16, c["main"].darkened(0.15), 1.5)
	D.rrect(ci, Rect2(w * 0.05, -h * 0.75, w * 0.35, h * 0.2), 4, c["accent"])
	ci.draw_circle(Vector2(w * 0.25, -h * 0.3), 6, c["trim"])
	ci.draw_line(Vector2(w * 0.3, -h - d), Vector2(w * 0.5, -h - d - 30), c["wood"].darkened(0.2), 2, true)
	if on:
		var t: float = anim.get("t", 0.0)
		for i in 2:
			var k := fmod(t * 0.6 + i * 0.5, 1.0)
			IconPainter.draw_icon(ci, "note", Vector2(-w * 0.1 + i * 30 + sin(k * 6.0) * 8, -h - d - 10 - k * 50), 20, Color(1, 1, 1, 1.0 - k))


static func _clock(ci: CanvasItem, w: float, h: float, c: Dictionary, anim: Dictionary) -> void:
	var r := w * 0.5
	D.ellipse(ci, Vector2.ZERO, r, r, c["wood"])
	D.ellipse(ci, Vector2.ZERO, r * 0.82, r * 0.82, c["main"], false, 0.05)
	for i in 12:
		var a := TAU * i / 12.0
		ci.draw_circle(Vector2(cos(a), sin(a)) * r * 0.68, 2.5 if i % 3 else 4.0, c["trim"])
	var game_hour: float = anim.get("hour", 10.0)
	var ha := TAU * fmod(game_hour, 12.0) / 12.0 - PI / 2.0
	var ma := TAU * fmod(game_hour, 1.0) - PI / 2.0
	ci.draw_line(Vector2.ZERO, Vector2(cos(ha), sin(ha)) * r * 0.4, c["trim"], 5, true)
	ci.draw_line(Vector2.ZERO, Vector2(cos(ma), sin(ma)) * r * 0.6, c["accent"], 3, true)
	ci.draw_circle(Vector2.ZERO, 5, c["trim"])


static func _rug(ci: CanvasItem, w: float, d: float, c: Dictionary, deco: String) -> void:
	var cy := -d * 0.5
	D.ellipse(ci, Vector2(0, cy), w * 0.5, d * 0.5, c["wood"], false, 0.0)
	D.ellipse(ci, Vector2(0, cy), w * 0.46, d * 0.44, c["main"], false, 0.0)
	D.ellipse(ci, Vector2(0, cy), w * 0.3, d * 0.28, c["accent"], false, 0.0)
	if deco == "stars":
		for i in 5:
			var a := TAU * i / 5.0
			ci.draw_colored_polygon(D.star_points(Vector2(cos(a) * w * 0.38, cy + sin(a) * d * 0.36), 9, 4), c["accent"])
	else:
		for i in 10:
			var a := TAU * i / 10.0
			ci.draw_circle(Vector2(cos(a) * w * 0.38, cy + sin(a) * d * 0.37), 4, c["trim"])


static func _plant(ci: CanvasItem, w: float, d: float, h: float, c: Dictionary) -> void:
	D.shadow(ci, Vector2(0, -d * 0.5), w * 0.55, d * 0.4)
	for i in 7:
		var a := -PI / 2.0 + (i - 3) * 0.32
		var tip := Vector2(cos(a) * h * 0.6, -h * 0.3 + sin(a) * h * 0.7) + Vector2(0, -d * 0.5)
		var leaf := PackedVector2Array([Vector2(0, -h * 0.35 - d * 0.5), tip + Vector2(-8, 4), tip, tip + Vector2(8, 4)])
		D.poly(ci, leaf, c["main"].darkened((i % 2) * 0.12), false)
	ci.draw_circle(Vector2(-10, -h * 0.85 - d * 0.5), 7, c["accent"])
	ci.draw_circle(Vector2(14, -h * 0.75 - d * 0.5), 6, c["accent"])
	D.poly(ci, PackedVector2Array([Vector2(-w * 0.4, -h * 0.38 - d * 0.5), Vector2(w * 0.4, -h * 0.38 - d * 0.5), Vector2(w * 0.3, -d * 0.2), Vector2(-w * 0.3, -d * 0.2)]), c["wood"])


static func _picture(ci: CanvasItem, w: float, h: float, c: Dictionary, deco: String) -> void:
	ci.draw_rect(Rect2(-w / 2 + 6, -h / 2 + 8, w, h), Color(0.3, 0.15, 0.15, 0.12))
	D.rrect(ci, Rect2(-w / 2, -h / 2, w, h), 8, c["main"])
	var inner := Rect2(-w / 2 + 12, -h / 2 + 12, w - 24, h - 24)
	D.rrect(ci, inner, 4, c["accent"], false, 0.0)
	match deco:
		"cat":
			IconPainter.draw_icon(ci, "cat", inner.get_center() + Vector2(0, 6), min(inner.size.x, inner.size.y) * 0.8)
		"mountain":
			ci.draw_colored_polygon(PackedVector2Array([inner.position + Vector2(0, inner.size.y), inner.position + Vector2(inner.size.x * 0.35, inner.size.y * 0.3), inner.position + Vector2(inner.size.x * 0.6, inner.size.y * 0.7), inner.position + Vector2(inner.size.x * 0.8, inner.size.y * 0.4), inner.end]), c["trim"])
			ci.draw_circle(inner.position + Vector2(inner.size.x * 0.8, inner.size.y * 0.25), 9, Color("#ffd86b"))
		_:
			IconPainter.draw_icon(ci, "flower", inner.get_center(), inner.size.y * 0.7)


static func _garland(ci: CanvasItem, w: float, h: float, c: Dictionary, anim: Dictionary) -> void:
	var pts := PackedVector2Array()
	for i in 21:
		var x := -w / 2 + w * i / 20.0
		pts.append(Vector2(x, -h * 0.3 + sin(PI * i / 20.0) * h * 0.6))
	ci.draw_polyline(pts, c["trim"], 2, true)
	var t: float = anim.get("t", 0.0)
	for i in 7:
		var p := pts[1 + i * 3]
		var glow := 0.75 + 0.25 * sin(t * 2.0 + i)
		var col: Color = [c["main"], c["accent"], c["wood"]][i % 3]
		ci.draw_colored_polygon(D.star_points(p + Vector2(0, 12), 12, 5.5), col * Color(glow, glow, glow, 1))


static func _swatch(ci: CanvasItem, def: Dictionary, c: Dictionary) -> void:
	var r := Rect2(-60, -100, 120, 100)
	match def.get("shape"):
		"swatch_wall":
			D.rrect(ci, r, 10, c["main"], true, 0.0)
			RoomPainter.wall_pattern(ci, r.grow(-6), def.get("pattern", "dots"), c, 18.0)
		"swatch_floor":
			D.rrect(ci, r, 10, c["main"], true, 0.0)
			for i in 5:
				ci.draw_line(Vector2(-54, -94 + i * 20), Vector2(54, -94 + i * 20), c["wood"], 2)
		_:
			D.rrect(ci, r, 10, c["main"], true, 0.1)
			if def.get("landscape", "") == "sea":
				ci.draw_rect(Rect2(-54, -40, 108, 34), c["wood"])
				ci.draw_circle(Vector2(20, -70), 14, Color("#ffd86b"))
			else:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(-54, -6), Vector2(-20, -70), Vector2(10, -30), Vector2(30, -60), Vector2(54, -6)]), c["wood"])
