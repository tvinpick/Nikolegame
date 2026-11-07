class_name Actor
extends Node2D
## Base for the girl and the pets: path following with local avoidance and
## recovery, pose blending (no instant pose swaps), smooth attach/detach to
## furniture anchors (no teleport), state machine with diagnostics logging.

signal state_changed(actor: Actor, from: String, to: String)
signal arrived(actor: Actor)

var actor_id := ""
var kind := ""                   # girl | cat | dog
var room: Room = null
var facing := 1.0                # +1 right, -1 left
var view := "side"               # side | front | back
var draw_offset := Vector2.ZERO  # visual offset from the sort point (lift etc.)
var state := "Idle"
var state_time := 0.0
var speed := 170.0
var run_speed := 330.0
var running := false
var path := PackedVector2Array()
var path_i := 0
var moving := false
var travel := 0.0                # distance moved this frame (drives gait)
var gait_phase := 0.0
var walk_weight := 0.0           # 0 idle .. 1 walking (blends gait in/out)
var on_arrive: Callable = Callable()
var nav_version := -1
var goal := Vector2.ZERO
var stuck_time := 0.0
var attached_to: Furniture = null
var attach_anchor := ""
var hidden_frac := 0.0           # inside a house: partly hidden
var pose: Dictionary = {}
var _pose_from: Dictionary = {}
var _pose_to: Dictionary = {}
var _pose_t := 1.0
var _pose_dur := 0.3
var pose_name := "stand"
var expression := "smile"
var _attach_tween: Tween = null
var blink := 0.0
var _blink_timer := 2.0
var busy_lock := ""              # set when another actor owns this one (carry, bath)
const BASE_SCALE := 1.3          # character art scale relative to furniture


func _ready() -> void:
	pose = poses().get("stand", {}).duplicate()
	_pose_from = pose.duplicate()
	_pose_to = pose.duplicate()


## Override: Dictionary name -> pose params.
func poses() -> Dictionary:
	return {"stand": {}}


func set_state(s: String) -> void:
	if s == state:
		return
	var old := state
	state = s
	state_time = 0.0
	Diag.event("state", {"a": actor_id, "from": old, "to": s, "pose": pose_name})
	state_changed.emit(self, old, s)


func set_pose(name_: String, dur := 0.35) -> void:
	var p: Dictionary = poses().get(name_, {})
	if p.is_empty():
		push_warning("%s: unknown pose %s" % [actor_id, name_])
		return
	if name_ != pose_name:
		Diag.event("anim", {"a": actor_id, "from": pose_name, "to": name_, "dur": dur})
	pose_name = name_
	_pose_from = pose.duplicate()
	_pose_to = p.duplicate()
	for k in _pose_from.keys():
		if not _pose_to.has(k):
			_pose_to[k] = poses()["stand"].get(k, _pose_from[k])
	for k in _pose_to.keys():
		if not _pose_from.has(k):
			_pose_from[k] = _pose_to[k]
	_pose_t = 0.0
	_pose_dur = max(0.01, dur)


func pose_done() -> bool:
	return _pose_t >= 1.0


func _update_pose(delta: float) -> void:
	if _pose_t < 1.0:
		_pose_t = min(1.0, _pose_t + delta / _pose_dur)
		var t := ease(_pose_t, -2.0)  # ease in-out
		for k in _pose_to.keys():
			var a: Variant = _pose_from.get(k, _pose_to[k])
			var b: Variant = _pose_to[k]
			if typeof(a) in [TYPE_FLOAT, TYPE_INT] and typeof(b) in [TYPE_FLOAT, TYPE_INT]:
				pose[k] = lerpf(float(a), float(b), t)
			else:
				pose[k] = b if t > 0.5 else a


# ---------------------------------------------------------------- navigation

func go_to(target: Vector2, cb: Callable = Callable(), run := false) -> bool:
	if room == null:
		return false
	if attached_to != null:
		push_warning("%s: go_to while attached" % actor_id)
		return false
	var nav: NavGrid = room.nav
	var dest := nav.nearest_free(target)
	var p := nav.find_path(position, dest)
	if p.size() == 0:
		Diag.event("path_fail", {"a": actor_id, "to": [int(target.x), int(target.y)]})
		return false
	path = p
	path[path.size() - 1] = dest
	path_i = 1 if p.size() > 1 else 0
	goal = dest
	moving = true
	running = run
	on_arrive = cb
	nav_version = nav.version
	stuck_time = 0.0
	Diag.event("path", {"a": actor_id, "n": p.size(), "to": [int(dest.x), int(dest.y)]})
	return true


func stop_moving() -> void:
	moving = false
	path = PackedVector2Array()
	on_arrive = Callable()


func _follow_path(delta: float) -> void:
	travel = 0.0
	if not moving:
		return
	var nav: NavGrid = room.nav
	if nav.version != nav_version:
		# furniture changed: re-plan toward the same goal (recovery)
		var cb := on_arrive
		if not go_to(goal, cb, running):
			moving = false
			Diag.event("path_abort", {"a": actor_id})
			_on_path_failed()
		return
	if path_i >= path.size():
		_finish_path()
		return
	var target := path[path_i]
	var to := target - position
	var sp := (run_speed if running else speed) * _speed_scale()
	var avoid := _avoidance()
	var step := sp * delta
	if to.length() <= step:
		travel = to.length()
		position = target
		path_i += 1
		if path_i >= path.size():
			_finish_path()
		return
	var dir := (to.normalized() + avoid).normalized()
	var new_pos := position + dir * step
	if not nav.is_free(new_pos) and nav.is_free(position):
		new_pos = position + to.normalized() * step
	travel = position.distance_to(new_pos)
	if travel < step * 0.2:
		stuck_time += delta
		if stuck_time > 1.5:
			stuck_time = 0.0
			go_to(goal, on_arrive, running)
	else:
		stuck_time = 0.0
	position = new_pos
	if absf(dir.x) > 0.25:
		facing = signf(dir.x)


func _speed_scale() -> float:
	return 1.0


## Simple separation from other characters ahead of us.
func _avoidance() -> Vector2:
	var push := Vector2.ZERO
	if room == null:
		return push
	for a in room.actors:
		if a == self or a.attached_to != null or not a.visible:
			continue
		var d: Vector2 = position - a.position
		var dist := d.length()
		if dist > 1.0 and dist < 46.0:
			push += d.normalized() * (46.0 - dist) / 46.0 * 0.7
	return push


func _finish_path() -> void:
	moving = false
	var cb := on_arrive
	on_arrive = Callable()
	Diag.event("arrived", {"a": actor_id, "at": [int(position.x), int(position.y)]})
	arrived.emit(self)
	if cb.is_valid():
		cb.call()


func _on_path_failed() -> void:
	pass


func face_toward_x(x: float) -> void:
	if absf(x - position.x) > 2.0:
		facing = signf(x - position.x)


# ---------------------------------------------------------------- attach / detach

## Smoothly move onto an anchor: floor point -> sort point above the furniture,
## and visual lift tween. Calls cb when done.
func attach(f: Furniture, anchor_world: Dictionary, anchor_name: String, dur := 0.55, cb: Callable = Callable(), arc := 0.0) -> void:
	stop_moving()
	attached_to = f
	attach_anchor = anchor_name
	var floor_pt: Vector2 = anchor_world["pos"]
	var lift: float = anchor_world["lift"]
	var sort_y: float = max(f.position.y + 1.0, floor_pt.y)
	var target_pos := Vector2(floor_pt.x, sort_y)
	var target_off := Vector2(0, floor_pt.y - sort_y - lift)
	_tween_to(target_pos, target_off, dur, cb, arc)


## Move back to a floor point (detaching).
func detach_to(floor_pt: Vector2, dur := 0.5, cb: Callable = Callable(), arc := 0.0) -> void:
	var f := attached_to
	attached_to = null
	attach_anchor = ""
	var pt := floor_pt
	if room:
		pt = room.nav.nearest_free(floor_pt)
	# keep the visual where it is while switching sort point
	var visual := position + draw_offset
	var sort_y: float = position.y if (f != null and pt.y < position.y) else pt.y
	position = Vector2(pt.x, sort_y)
	draw_offset = visual - position
	_tween_to(pt, Vector2.ZERO, dur, cb, arc)


func _tween_to(pos: Vector2, off: Vector2, dur: float, cb: Callable, arc: float) -> void:
	if _attach_tween and _attach_tween.is_valid():
		_attach_tween.kill()
	var start_pos := position
	var start_off := draw_offset
	_attach_tween = create_tween()
	_attach_tween.tween_method(func(t: float):
		position = start_pos.lerp(pos, t)
		draw_offset = start_off.lerp(off, t) + Vector2(0, -sin(t * PI) * arc)
		, 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if cb.is_valid():
		_attach_tween.tween_callback(cb)


func is_attach_tweening() -> bool:
	return _attach_tween != null and _attach_tween.is_valid() and _attach_tween.is_running()


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	state_time += delta
	_follow_path(delta)
	var target_w := 1.0 if (moving and travel > 0.01) else 0.0
	walk_weight = move_toward(walk_weight, target_w, delta * 5.0)
	_advance_gait(travel)
	_update_pose(delta)
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = randf_range(2.0, 5.0)
		blink = 1.0
	blink = max(0.0, blink - delta * 7.0)
	var s := (RoomGeo.depth_scale(position.y + draw_offset.y) if attached_to == null else RoomGeo.depth_scale(position.y)) * BASE_SCALE
	scale = Vector2(s, s)
	_tick(delta)
	queue_redraw()


func _advance_gait(dist: float) -> void:
	pass


func _tick(_delta: float) -> void:
	pass


## Visual ground point in world (where feet touch).
func ground_point() -> Vector2:
	return position + draw_offset


func debug_info() -> Dictionary:
	return {"id": actor_id, "state": state, "pose": pose_name, "pos": [int(position.x), int(position.y)], "off": [int(draw_offset.x), int(draw_offset.y)], "attached": attached_to.uid if attached_to else -1, "anchor": attach_anchor, "moving": moving, "lock": busy_lock}
