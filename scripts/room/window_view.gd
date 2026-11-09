class_name WindowView
extends Node2D
## Big window: landscape layers live ONLY inside a clip mask (clip_children),
## move with parallax relative to the camera, and are clamped so no empty
## strips ever appear. Frame, glass and curtains are drawn on top as part of
## the room.

const D := preload("res://scripts/core/draw_util.gd")
const MARGIN := 280.0
const FACTORS := {"sky": 0.0, "clouds": 0.02, "far": 0.035, "mid": 0.075, "near": 0.13}

var clock: WorldClock
var rect: Rect2
var landscape := "mountains"
var camera_x := 0.0
var clip: Node2D
var layers: Dictionary = {}
var frame: Node2D
var rain: CPUParticles2D
var snow: CPUParticles2D
var low_detail := false
var _t := 0.0


func setup(c: WorldClock, r: Rect2) -> void:
	clock = c
	rect = r
	position = r.position
	clip = _ClipMask.new()
	clip.size = r.size
	clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	add_child(clip)
	for name in ["sky", "clouds", "far", "mid", "near"]:
		var l := _Layer.new()
		l.kind = name
		l.view = self
		clip.add_child(l)
		layers[name] = l
	rain = _make_particles(_rain_tex(), 260, Vector2(-60, 900), 1.0)
	snow = _make_particles(_snow_tex(), 140, Vector2(-20, 120), 6.0)
	clip.add_child(rain)
	clip.add_child(snow)
	frame = _Frame.new()
	frame.view = self
	add_child(frame)
	clock.changed.connect(_on_clock_changed)
	_on_clock_changed()


func _make_particles(tex: Texture2D, amount: int, vel: Vector2, life: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = tex
	p.amount = amount
	p.lifetime = life if life > 2.0 else 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(rect.size.x * 0.75, 10)
	p.position = Vector2(rect.size.x * 0.5, -20)
	p.direction = vel.normalized()
	p.spread = 4.0 if life <= 2.0 else 25.0
	p.initial_velocity_min = vel.length() * 0.85
	p.initial_velocity_max = vel.length() * 1.1
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.emitting = false
	p.local_coords = false
	if life > 2.0:
		p.angular_velocity_min = -40
		p.angular_velocity_max = 40
	return p


static func _rain_tex() -> Texture2D:
	var img := Image.create(4, 26, false, Image.FORMAT_RGBA8)
	for y in 26:
		for x in 4:
			var a := (1.0 - absf(x - 1.5) / 2.0) * (float(y) / 26.0) * 0.8
			img.set_pixel(x, y, Color(0.85, 0.92, 1.0, a))
	return ImageTexture.create_from_image(img)


static func _snow_tex() -> Texture2D:
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	for y in 14:
		for x in 14:
			var d := Vector2(x - 6.5, y - 6.5).length() / 6.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0, 1) * 0.95))
	return ImageTexture.create_from_image(img)


func set_landscape(theme_item: String) -> void:
	landscape = Content.item(theme_item).get("landscape", "mountains")
	for l in layers.values():
		l.queue_redraw()


func set_low_detail(on: bool) -> void:
	low_detail = on
	rain.amount = 120 if on else 260
	snow.amount = 60 if on else 140


func _on_clock_changed() -> void:
	rain.emitting = clock.weather == "rain"
	snow.emitting = clock.weather == "snow"
	for l in layers.values():
		l.queue_redraw()
	frame.queue_redraw()


## Clamped parallax offset for a layer (never exceeds the drawn margin).
func layer_offset(factor: float) -> float:
	var cx := rect.position.x + rect.size.x * 0.5
	return clampf(-(camera_x - cx) * factor, -MARGIN + 4.0, MARGIN - 4.0)


func update_camera(cam_x: float) -> void:
	camera_x = cam_x
	for name in layers:
		layers[name].position.x = layer_offset(FACTORS[name])


func _process(delta: float) -> void:
	_t += delta
	var cl: Node2D = layers.get("clouds")
	if cl:
		cl.drift = fmod(cl.drift + delta * (14.0 if clock.weather != "sun" else 7.0), 400.0)
		if not low_detail or Engine.get_process_frames() % 4 == 0:
			cl.queue_redraw()
	# sky redraw a few times per second is enough (slow clock)
	if Engine.get_process_frames() % (30 if low_detail else 10) == 0:
		layers["sky"].queue_redraw()
		frame.queue_redraw()


class _ClipMask extends Node2D:
	var size := Vector2.ONE
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)


class _Layer extends Node2D:
	var kind := ""
	var view: WindowView
	var drift := 0.0

	func _draw() -> void:
		var r: Rect2 = view.rect
		var W := r.size.x + WindowView.MARGIN * 2.0
		var x0 := -WindowView.MARGIN
		var H := r.size.y
		var c: WorldClock = view.clock
		var season := c.season
		match kind:
			"sky":
				var sc: Array = c.sky_colors()
				D.gradient_poly(self, PackedVector2Array([Vector2(x0, 0), Vector2(x0 + W, 0), Vector2(x0 + W, H), Vector2(x0, H)]), sc[0], sc[1])
				var cl := c.clock
				if c.is_dark():
					var rng := RandomNumberGenerator.new()
					rng.seed = 42
					for i in 60:
						draw_circle(Vector2(x0 + rng.randf() * W, rng.randf() * H * 0.6), rng.randf_range(1.0, 2.6), Color(1, 1, 0.9, 0.5 + 0.5 * sin(view._t * 2.0 + i)))
					var mp := Vector2(r.size.x * 0.72, H * 0.22)
					draw_circle(mp, 34, Color(1, 0.97, 0.85))
					draw_circle(mp + Vector2(14, -8), 30, c.sky_colors()[0])
				elif c.weather != "rain":
					var a := clampf((cl - 0.2) / 0.66, 0.0, 1.0)
					var sp := Vector2(lerpf(r.size.x * 0.1, r.size.x * 0.9, a), H * 0.55 - sin(a * PI) * H * 0.42)
					for i in 3:
						draw_circle(sp, 44.0 + i * 18.0, Color(1, 0.95, 0.7, 0.12))
					draw_circle(sp, 38, Color(1, 0.93, 0.6) if c.weather == "sun" else Color(1, 0.96, 0.85, 0.7))
			"clouds":
				var n := 4 if c.weather == "sun" else 8
				var col := Color(1, 1, 1, 0.92) if c.weather == "sun" else Color(0.86, 0.88, 0.92, 0.95)
				if c.is_dark():
					col = Color(0.5, 0.53, 0.7, 0.7)
				for i in n:
					var bx := fmod(i * 260.0 + drift * (0.6 + 0.1 * (i % 3)), W) + x0
					D.cloud(self, Vector2(bx, 50.0 + (i % 3) * 38.0), 150.0 + (i % 2) * 60.0, col)
			"far":
				var fcol := Color("#9cb7d6")
				if season == "winter":
					fcol = Color("#c6d3e6")
				fcol = fcol * c.room_tint()
				if view.landscape == "sea":
					draw_rect(Rect2(x0, H * 0.55, W, H * 0.45), Color("#5fb3dc") * c.room_tint())
					for i in 30:
						var wx := x0 + i * W / 30.0
						draw_arc(Vector2(wx, H * 0.6 + (i % 3) * 18), 14, PI * 1.1, PI * 1.9, 6, Color(1, 1, 1, 0.5), 2)
					D.poly(self, PackedVector2Array([Vector2(x0 + W * 0.62, H * 0.56), Vector2(x0 + W * 0.66, H * 0.36), Vector2(x0 + W * 0.7, H * 0.56)]), Color("#fdf3d8"), false)
				else:
					var pts := PackedVector2Array([Vector2(x0, H)])
					for i in 13:
						var px := x0 + W * i / 12.0
						pts.append(Vector2(px, H * (0.42 + 0.14 * sin(i * 1.7) + (0.1 if i % 2 else 0.0))))
					pts.append(Vector2(x0 + W, H))
					draw_colored_polygon(pts, fcol)
					for i in range(1, 12, 2):
						var px := x0 + W * i / 12.0
						var py := H * (0.42 + 0.14 * sin(i * 1.7) + 0.1)
						var peak := Vector2(px, py)
						draw_colored_polygon(PackedVector2Array([peak + Vector2(-26, 22), peak, peak + Vector2(26, 22)]), Color(1, 1, 1, 0.85))
			"mid":
				var hc: Color = {"spring": Color("#9fd68a"), "summer": Color("#7cc56b"), "autumn": Color("#d9b65e"), "winter": Color("#eef3f8")}[season] * c.room_tint()
				var pts2 := PackedVector2Array([Vector2(x0, H)])
				for i in 25:
					var px := x0 + W * i / 24.0
					pts2.append(Vector2(px, H * (0.7 + 0.05 * sin(i * 0.9))))
				pts2.append(Vector2(x0 + W, H))
				draw_colored_polygon(pts2, hc)
				# little house far away
				var hx := x0 + W * 0.3
				D.rrect(self, Rect2(hx, H * 0.62, 50, 34), 3, Color("#fbe3c8") * c.room_tint(), false)
				draw_colored_polygon(PackedVector2Array([Vector2(hx - 6, H * 0.62), Vector2(hx + 25, H * 0.56), Vector2(hx + 56, H * 0.62)]), Color("#e57a7a") * c.room_tint())
				if c.is_dark():
					draw_rect(Rect2(hx + 18, H * 0.635, 12, 12), Color(1, 0.9, 0.5))
			"near":
				var trunk := Color("#9a6b4c") * c.room_tint()
				var crowns: Array = {
					"spring": [Color("#8fd27a"), Color("#f7b8cf")],
					"summer": [Color("#5fb35a"), Color("#4f9e4c")],
					"autumn": [Color("#f0a03c"), Color("#e2603c")],
					"winter": [Color("#ffffff"), Color("#e6eef6")],
				}[season]
				for i in 6:
					var tx := x0 + 80 + i * (W - 160) / 5.0
					var th := H * (0.28 + (i % 3) * 0.04)
					draw_line(Vector2(tx, H), Vector2(tx, H - th), trunk, 12)
					if season == "winter":
						for b in 4:
							draw_line(Vector2(tx, H - th * (0.4 + b * 0.15)), Vector2(tx + (24 if b % 2 else -24), H - th * (0.55 + b * 0.15)), trunk, 4)
						draw_circle(Vector2(tx, H - th), 22, Color(1, 1, 1, 0.9))
					else:
						var cc: Color = crowns[0] * c.room_tint()
						draw_circle(Vector2(tx, H - th), 56, cc)
						draw_circle(Vector2(tx - 36, H - th + 24), 40, cc.darkened(0.06))
						draw_circle(Vector2(tx + 38, H - th + 20), 42, cc.darkened(0.03))
						if season == "spring" or season == "autumn":
							for k in 7:
								draw_circle(Vector2(tx - 40 + k * 13, H - th - 20 + (k % 3) * 22), 6, crowns[1] * c.room_tint())
				# ground strip
				var gc: Color = Color("#ffffff") if season == "winter" else ({"spring": Color("#86c96e"), "summer": Color("#6db85c"), "autumn": Color("#c99b4f")}[season])
				draw_rect(Rect2(x0, H - 24, W, 24), gc * c.room_tint())
				if c.weather == "rain":
					for k in 10:
						D.ellipse(self, Vector2(x0 + k * W / 10.0 + 40, H - 10), 36, 6, Color(0.7, 0.8, 0.95, 0.5), false, 0.0)


class _Frame extends Node2D:
	var view: WindowView

	func _draw() -> void:
		var s: Vector2 = view.rect.size
		var c: WorldClock = view.clock
		var frame_col := Color("#ffffff")
		var trim := Color("#f39bb8")
		# glass sheen
		draw_line(Vector2(s.x * 0.12, s.y * 0.15), Vector2(s.x * 0.22, s.y * 0.05), Color(1, 1, 1, 0.35), 10)
		draw_line(Vector2(s.x * 0.62, s.y * 0.2), Vector2(s.x * 0.7, s.y * 0.1), Color(1, 1, 1, 0.25), 7)
		# mullions
		draw_rect(Rect2(s.x * 0.5 - 8, 0, 16, s.y), frame_col)
		draw_rect(Rect2(0, s.y * 0.42 - 7, s.x, 14), frame_col)
		# outer frame
		for r in [Rect2(-22, -22, s.x + 44, 22), Rect2(-22, s.y, s.x + 44, 22), Rect2(-22, 0, 22, s.y), Rect2(s.x, 0, 22, s.y)]:
			draw_rect(r, frame_col)
		draw_rect(Rect2(-22, -22, s.x + 44, s.y + 44), Color(0.5, 0.35, 0.4, 0.4), false, 2.0)
		# sill
		D.rrect(self, Rect2(-46, s.y + 14, s.x + 92, 26), 8, Color("#f7ede6"))
		# curtains with gentle sway (stronger when it rains/snows = wind)
		var sway := sin(view._t * (1.6 if c.weather in ["rain", "snow"] else 0.8)) * (10.0 if c.weather in ["rain", "snow"] else 4.0)
		for side in [-1, 1]:
			var x_out: float = -70.0 if side < 0 else s.x + 70.0
			var x_in: float = s.x * 0.17 if side < 0 else s.x * 0.83
			var pts := PackedVector2Array()
			pts.append(Vector2(x_out, -40))
			pts.append(Vector2(x_in, -40))
			for i in 9:
				var t := float(i) / 8.0
				var bulge: float = sin(t * PI) * 40.0 * -side
				pts.append(Vector2(lerpf(x_in, x_out + side * -20.0, t * 0.8) + bulge * 0.4 + sway * t, -40 + t * (s.y + 120)))
			pts.append(Vector2(x_out, s.y + 80))
			D.poly(self, pts, Color("#fbd3df"), true, 0.12)
			for i in 4:
				var fx := lerpf(x_out, x_in, 0.2 + i * 0.2)
				draw_line(Vector2(fx, -30), Vector2(fx + sway * 0.4, s.y + 60), Color(0.95, 0.7, 0.78, 0.6), 3)
			D.rrect(self, Rect2(min(x_out, x_in + side * 30.0) if side < 0 else x_in - 30.0, s.y * 0.55, absf(x_out - x_in) * 0.6, 18), 9, trim)
		# rod
		D.rrect(self, Rect2(-100, -58, s.x + 200, 16), 8, Color("#e2b75c"))
		draw_circle(Vector2(-100, -50), 14, Color("#f6d27a"))
		draw_circle(Vector2(s.x + 100, -50), 14, Color("#f6d27a"))
