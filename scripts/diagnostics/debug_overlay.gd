class_name DebugOverlay
extends Node2D
## Developer overlay: footprints, approach points, anchors, paths, targets,
## active states/animations, camera bounds. Visible only when an adult enabled
## it in developer mode (never in normal child play by accident).
## Also shows a small sparkle where the child tapped the floor (always on).

var room: Room
var _flash_pos := Vector2.ZERO
var _flash_t := 0.0


func _ready() -> void:
	z_index = 100
	Diag.overlay_toggled.connect(func(_on): queue_redraw())


func flash_target(p: Vector2) -> void:
	_flash_pos = p
	_flash_t = 0.6


func _process(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta
		queue_redraw()
	elif Diag.overlay_on and Diag.dev_allowed():
		queue_redraw()


func _draw() -> void:
	if _flash_t > 0.0:
		var k := _flash_t / 0.6
		draw_arc(_flash_pos, 30.0 * (1.5 - k), 0, TAU, 24, Color(1, 1, 1, k), 4)
		draw_colored_polygon(DrawUtil.star_points(_flash_pos + Vector2(0, -20 * (1.0 - k)), 12, 5), Color(1, 0.85, 0.4, k))
	if not (Diag.overlay_on and Diag.dev_allowed()) or room == null:
		return
	var font := ThemeDB.fallback_font
	# nav blockers
	for r in room.nav.blockers:
		draw_rect(r, Color(1, 0.2, 0.2, 0.12))
		draw_rect(r, Color(1, 0.2, 0.2, 0.5), false, 2)
	draw_rect(RoomGeo.walk_rect(), Color(0.2, 0.6, 1, 0.6), false, 3)
	for f in room.furniture_nodes():
		draw_rect(f.footprint(), Color(0.1, 0.8, 0.3, 0.7), false, 2)
		for ap in f.approach_points():
			draw_circle(ap, 7, Color(0.2, 0.5, 1.0, 0.9))
		var prof: Dictionary = Content.profile_of(f.item_id)
		for an in prof.get("anchors", {}).keys():
			var a: Dictionary = f.anchor(an)
			if a.is_empty():
				continue
			var p: Vector2 = a["pos"]
			draw_line(p, p - Vector2(0, a["lift"]), Color(1, 0.6, 0, 0.8), 2)
			draw_circle(p - Vector2(0, a["lift"]), 6, Color(1, 0.6, 0, 0.9))
			draw_string(font, p - Vector2(0, a["lift"] + 8), an, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.3, 0))
		draw_string(font, f.position + Vector2(-f.size().x / 2, 18), "%s #%d" % [f.item_id, f.uid], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.1, 0.4, 0.1))
	for a in room.actors:
		if a.moving and a.path.size() > 0:
			var pts := PackedVector2Array([a.position])
			for i in range(a.path_i, a.path.size()):
				pts.append(a.path[i])
			if pts.size() >= 2:
				draw_polyline(pts, Color(0.9, 0.2, 0.9, 0.9), 3)
			draw_circle(a.goal, 9, Color(0.9, 0.2, 0.9, 0.9))
		draw_circle(a.position, 5, Color.BLACK)
		draw_circle(a.ground_point(), 5, Color.RED)
		var label := "%s %s/%s" % [a.actor_id, a.state, a.pose_name]
		if a is Pet:
			label += " %s" % a.current
		draw_string(font, a.ground_point() + Vector2(-60, 26), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.1, 0.1, 0.3))
	# camera bounds
	var cam: Camera2D = room.camera
	var vs: Vector2 = cam.get_viewport_rect().size / cam.zoom.x
	draw_rect(Rect2(cam.position - vs * 0.5 + Vector2(8, 8), vs - Vector2(16, 16)), Color(1, 1, 0, 0.6), false, 3)
