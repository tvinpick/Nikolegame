class_name CameraRig
extends Camera2D
## Horizontal swipe pan with inertia, pinch zoom (min..2x), soft focus moves.
## Zoom never goes below the level where the room height fills the screen, so
## no empty space shows at any aspect ratio.

const MAX_ZOOM := 2.0

var target_pos := Vector2.ZERO
var target_zoom := 1.0
var velocity := Vector2.ZERO
var dragging := false
var saved_zoom := -1.0
var saved_pos := Vector2.ZERO


func _ready() -> void:
	position_smoothing_enabled = false
	limit_left = 0
	limit_right = int(RoomGeo.WIDTH)
	limit_top = 0
	limit_bottom = int(RoomGeo.HEIGHT)
	target_pos = position
	target_zoom = min_zoom()
	zoom = Vector2(target_zoom, target_zoom)


func min_zoom() -> float:
	var vs := get_viewport_rect().size
	return max(vs.y / RoomGeo.HEIGHT, vs.x / RoomGeo.WIDTH, 0.5)


func view_size() -> Vector2:
	return get_viewport_rect().size / zoom.x


func clamp_pos(p: Vector2, z: float) -> Vector2:
	var half := get_viewport_rect().size / z * 0.5
	return Vector2(clampf(p.x, half.x, RoomGeo.WIDTH - half.x), clampf(p.y, half.y, RoomGeo.HEIGHT - half.y))


func pan_by_screen(delta_screen: Vector2) -> void:
	target_pos -= delta_screen / zoom.x
	target_pos = clamp_pos(target_pos, target_zoom)
	velocity = -delta_screen / zoom.x / max(get_process_delta_time(), 0.001)


func release_pan() -> void:
	dragging = false


func zoom_at(factor: float, screen_pt: Vector2) -> void:
	var old := target_zoom
	target_zoom = clampf(target_zoom * factor, min_zoom(), MAX_ZOOM)
	var vs := get_viewport_rect().size
	var world_before := target_pos + (screen_pt - vs * 0.5) / old
	target_pos = world_before - (screen_pt - vs * 0.5) / target_zoom
	target_pos = clamp_pos(target_pos, target_zoom)


func focus(world: Vector2, z := -1.0) -> void:
	if z > 0.0:
		target_zoom = clampf(z, min_zoom(), MAX_ZOOM)
	target_pos = clamp_pos(world, target_zoom)
	velocity = Vector2.ZERO


func is_visible_x(x: float, margin := 120.0) -> bool:
	var half := view_size().x * 0.5
	return absf(x - position.x) < half - margin


func push_zoom(world: Vector2, z: float) -> void:
	if saved_zoom < 0.0:
		saved_zoom = target_zoom
		saved_pos = target_pos
	focus(world, z)


func pop_zoom() -> void:
	if saved_zoom > 0.0:
		target_zoom = saved_zoom
		target_pos = clamp_pos(saved_pos, saved_zoom)
		saved_zoom = -1.0


func _process(delta: float) -> void:
	if not dragging and velocity.length() > 5.0:
		target_pos += velocity * delta
		velocity = velocity.move_toward(Vector2.ZERO, velocity.length() * 4.0 * delta + 40.0 * delta)
		target_pos = clamp_pos(target_pos, target_zoom)
	elif not dragging:
		velocity = Vector2.ZERO
	var zl := lerpf(zoom.x, target_zoom, 1.0 - exp(-10.0 * delta))
	if absf(zl - target_zoom) < 0.0005:
		zl = target_zoom
	zoom = Vector2(zl, zl)
	position = clamp_pos(position.lerp(target_pos, 1.0 - exp(-(14.0 if dragging else 7.0) * delta)), zl)
	AudioSvc.listener_pos = position
	AudioSvc.listener_half_width = view_size().x * 0.5
