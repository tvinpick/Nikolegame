class_name Toy
extends Node2D
## Dynamic toy on the floor plane (ball / plush). floor_pos = point on the
## floor, z = height above it. Throw impulse is clamped; bounces off room
## bounds and furniture footprints; sound is played at the actual contact.

const MAX_SPEED := 1400.0
const GRAVITY := 1500.0

var inst: Dictionary = {}
var def: Dictionary = {}
var uid := -1
var item_id := ""
var kind := "ball"
var floor_pos := Vector2.ZERO
var z := 0.0
var vz := 0.0
var velocity := Vector2.ZERO
var spin := 0.0
var holder: Node = null
var room: Room = null
var dragging := false
var _drag_samples: Array = []
var ghost := false
var ghost_valid := true
var selected := false
var _rest_time := 0.0


func setup(i: Dictionary, r: Room) -> void:
	inst = i
	room = r
	uid = int(i["uid"])
	item_id = i["item_id"]
	def = Content.item(item_id)
	kind = def.get("dynamic", "ball")
	floor_pos = Vector2(float(i["x"]), float(i["y"]))
	position = floor_pos
	name = "T_%s_%d" % [item_id, uid]


func radius() -> float:
	return float(def.get("size", {}).get("w", 34)) * 0.5


func hit_test(p: Vector2) -> bool:
	var c := floor_pos + Vector2(0, -z - radius())
	return p.distance_to(c) < max(radius() * 2.2, 50.0)


func visual_rect() -> Rect2:
	return Rect2(floor_pos - Vector2(radius() * 2, radius() * 3 + z), Vector2(radius() * 4, radius() * 3 + z))


func footprint() -> Rect2:
	return Rect2(floor_pos - Vector2(radius(), radius() * 0.5), Vector2(radius() * 2, radius()))


func hold_by(who: Node) -> void:
	holder = who
	velocity = Vector2.ZERO
	vz = 0.0
	Diag.event("toy_hold", {"uid": uid, "by": who.get("actor_id")})


func follow(p: Vector2) -> void:
	# carried in a mouth/hand: p is the world point of the holder
	floor_pos = Vector2(p.x, holder.position.y + 3.0) if holder else p
	z = max(0.0, floor_pos.y - p.y - radius())
	position = floor_pos


func release(at: Vector2, v: Vector2, up: float) -> void:
	holder = null
	floor_pos = room.nav.nearest_free(at) if room else at
	velocity = v.limit_length(MAX_SPEED)
	vz = up
	Diag.event("toy_release", {"uid": uid, "v": [int(v.x), int(v.y)]})


func kick(v: Vector2, up := 0.0) -> void:
	if holder != null:
		return
	velocity = (velocity + v).limit_length(MAX_SPEED)
	vz = max(vz, up)


func begin_drag() -> void:
	dragging = true
	holder = null
	velocity = Vector2.ZERO
	_drag_samples.clear()


func drag_to(world: Vector2) -> void:
	var p := RoomGeo.clamp_walk(world + Vector2(0, 40))
	_drag_samples.append([Time.get_ticks_msec(), p])
	if _drag_samples.size() > 6:
		_drag_samples.pop_front()
	floor_pos = p
	z = 26.0
	position = floor_pos


## Release a drag: throw with the finger's velocity (clamped).
func end_drag() -> void:
	dragging = false
	var v := Vector2.ZERO
	if _drag_samples.size() >= 2:
		var a: Array = _drag_samples[0]
		var b: Array = _drag_samples[_drag_samples.size() - 1]
		var dt: float = max(1.0, float(b[0] - a[0])) / 1000.0
		v = ((b[1] as Vector2) - (a[1] as Vector2)) / dt
	velocity = v.limit_length(MAX_SPEED) * 0.8
	vz = clampf(v.length() * 0.15, 60.0, 360.0)
	Diag.event("toy_throw", {"uid": uid, "speed": int(velocity.length())})
	if velocity.length() > 300.0 and room:
		room.on_toy_thrown(self)


func _process(delta: float) -> void:
	if holder != null or dragging:
		queue_redraw()
		return
	if velocity.length() > 1.0 or z > 0.0 or vz != 0.0:
		_rest_time = 0.0
		var next := floor_pos + velocity * delta
		# bounce off walls / depth limits
		var wr := RoomGeo.walk_rect()
		if next.x < wr.position.x or next.x > wr.end.x:
			velocity.x = -velocity.x * 0.7
			next.x = clampf(next.x, wr.position.x, wr.end.x)
			_bump()
		if next.y < wr.position.y or next.y > wr.end.y:
			velocity.y = -velocity.y * 0.7
			next.y = clampf(next.y, wr.position.y, wr.end.y)
			_bump()
		# bounce off furniture footprints (when low enough to hit them)
		if room and z < 60.0 and not room.nav.is_free(next) and room.nav.is_free(floor_pos):
			var tx := Vector2(next.x, floor_pos.y)
			if room.nav.is_free(tx):
				velocity.y = -velocity.y * 0.6
				next = tx
			else:
				velocity.x = -velocity.x * 0.6
				next = Vector2(floor_pos.x, next.y) if room.nav.is_free(Vector2(floor_pos.x, next.y)) else floor_pos
			_bump()
		floor_pos = next
		vz -= GRAVITY * delta
		z += vz * delta
		if z <= 0.0:
			z = 0.0
			if absf(vz) > 120.0:
				vz = -vz * 0.45
				_bump()
			else:
				vz = 0.0
		var fr := 1.6 if z <= 0.0 else 0.2
		velocity = velocity.move_toward(Vector2.ZERO, velocity.length() * fr * delta + 8.0 * delta)
		spin += velocity.x * delta / max(1.0, radius())
		position = floor_pos
		queue_redraw()
	else:
		_rest_time += delta


func _bump() -> void:
	AudioSvc.sfx("ball_bounce" if kind == "ball" else "pop", floor_pos, -6.0)


func sync_to_inst() -> void:
	inst["x"] = floor_pos.x
	inst["y"] = floor_pos.y


func _draw() -> void:
	var c := FurniturePainter.cols(def)
	var r := radius()
	if ghost:
		draw_circle(Vector2(0, -r), r * 1.6, Color(0.4, 0.85, 0.5, 0.35) if ghost_valid else Color(0.95, 0.35, 0.4, 0.4))
	var sh := clampf(1.0 - z / 300.0, 0.3, 1.0)
	DrawUtil.shadow(self, Vector2(0, -2), r * 1.1 * sh, r * 0.35 * sh, 0.25 * sh)
	if kind == "ball":
		FurniturePainter.draw_ball(self, Vector2(0, -r - z), r, c, def.get("deco", ""), spin)
	else:
		FurniturePainter.draw_plush(self, Vector2(0, -z), float(def.get("size", {}).get("h", 56)), c)
	if selected:
		draw_arc(Vector2(0, -r - z), r * 1.7, 0, TAU, 24, Color(1, 1, 1, 0.9), 4)
