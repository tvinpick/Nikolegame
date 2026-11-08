class_name Furniture
extends Node2D
## A placed item instance. Visuals/anchors come from catalog + interaction
## profile, so swapping a variant never changes interaction code.

signal device_toggled(f: Furniture, on: bool)

var inst: Dictionary = {}        # reference into GameState.data.instances
var def: Dictionary = {}
var uid := -1
var item_id := ""
var lift := 0.0                  # >0 when standing on a host surface
var host: Furniture = null
var anim := {"chair_pull": 0.0, "doors": 0.0, "t": 0.0, "occupied": false, "hour": 10.0}
var front_overlay: Node2D = null # drawn above occupants (pet houses)
var ghost := false               # placement preview
var ghost_valid := true
var selected := false
var room: Room = null
var _anim_tweens: Dictionary = {}


func setup(i: Dictionary, r: Room) -> void:
	inst = i
	room = r
	uid = int(i.get("uid", -1))
	item_id = i["item_id"]
	def = Content.item(item_id)
	name = "F_%s_%d" % [item_id, uid]
	position = Vector2(float(i.get("x", 0)), float(i.get("y", 0)))
	scale.x = -1.0 if bool(i.get("flip", false)) else 1.0
	if def.get("shape") == "pet_house":
		front_overlay = _HouseFront.new()
		front_overlay.f = self
	elif def.get("shape") == "bed":
		front_overlay = _BedBlanket.new()
		front_overlay.f = self
	set_process(_needs_process())


func _needs_process() -> bool:
	return def.has("device") or def.get("shape") in ["garland", "bathtub", "teaser"]


func size() -> Vector3:
	return Content.size_of(item_id)


func placement() -> String:
	return def.get("placement", "floor")


func is_wall() -> bool:
	return placement() == "wall"


func is_fixed() -> bool:
	return placement() == "fixed"


func is_obstacle() -> bool:
	return placement() in ["floor", "floor_or_surface", "fixed"] and host == null and def.get("shape") != "window"


## Footprint on the floor in world coords.
func footprint() -> Rect2:
	var s := size()
	if is_wall():
		return Rect2(position - Vector2(s.x / 2, s.z / 2), Vector2(s.x, s.z))
	return Rect2(position.x - s.x / 2, position.y - s.y, s.x, s.y)


## Rough visual bounds (for tapping & camera focus), in world coords.
func visual_rect() -> Rect2:
	var s := size()
	if def.get("shape") == "window":
		return RoomGeo.WINDOW_RECT
	if is_wall():
		return Rect2(position - Vector2(s.x / 2, s.z / 2), Vector2(s.x, s.z))
	var top := s.z + s.y + lift + 20.0
	return Rect2(position.x - s.x / 2 - 10, position.y - top, s.x + 20, top + 6)


func hit_test(p: Vector2) -> bool:
	return visual_rect().has_point(p)


func sort_y() -> float:
	return position.y


## Anchor in world coordinates. pos = floor point; lift = visual height.
func anchor(name_: String, slot := 0) -> Dictionary:
	var a := Content.resolve_anchor(item_id, name_)
	if a.is_empty():
		return {}
	var p: Vector2 = a["pos"]
	p.x *= scale.x
	if slot > 0:
		p.x += (30.0 if slot % 2 == 1 else -30.0) * ceil(slot / 2.0)
	var out := a.duplicate()
	out["pos"] = position + p
	out["lift"] = float(a["lift"]) + lift
	var face: String = a.get("face", "")
	if face in ["left", "right"] and scale.x < 0:
		face = "left" if face == "right" else "right"
	out["face"] = face
	return out


func approach_points() -> Array:
	var out: Array = []
	for p in Content.approach_points(item_id):
		var v: Vector2 = p
		v.x *= scale.x
		out.append(position + v)
	return out


func actions_for(kind: String) -> Array:
	var out: Array = []
	for a in Content.actions_for(item_id, kind):
		if a.get("when", "") == "worn" and not is_worn():
			continue
		out.append(a)
	return out


# ---------------------------------------------------------------- wear & repair
## Beds with a "sprite_worn" slowly get shabby from use (sleeping, pets
## jumping on them); the girl can repair them for free (a little care task).

func wear() -> float:
	return float(inst.get("state", {}).get("wear", 0.0))


func is_worn() -> bool:
	return def.has("sprite_worn") and wear() >= FurniturePainter.WEAR_MAX


func add_wear(v: float) -> void:
	if not def.has("sprite_worn") or ghost:
		return
	var was := is_worn()
	var st: Dictionary = inst.get("state", {})
	st["wear"] = minf(wear() + v, FurniturePainter.WEAR_MAX)
	inst["state"] = st
	Save.request_save("wear")
	queue_redraw()
	if is_worn() and not was:
		Diag.event("worn", {"uid": uid, "item": item_id})


func repair() -> void:
	var st: Dictionary = inst.get("state", {})
	st["wear"] = 0.0
	inst["state"] = st
	anim["shine"] = 1.0
	animate("shine", 0.0, 1.6)
	AudioSvc.sfx("sparkle", position)
	Diag.event("repaired", {"uid": uid, "item": item_id})
	Save.request_save("repair")
	queue_redraw()


func is_on() -> bool:
	return bool(inst.get("state", {}).get("on", false))


func toggle_device() -> void:
	if not def.has("device"):
		return
	var st: Dictionary = inst.get("state", {})
	st["on"] = not bool(st.get("on", false))
	inst["state"] = st
	match def["device"]:
		"tv":
			AudioSvc.sfx("tv_on", position)
		"clock":
			AudioSvc.sfx("tick", position)
		_:
			AudioSvc.sfx("click", position)
	Diag.event("device", {"uid": uid, "on": st["on"]})
	device_toggled.emit(self, st["on"])
	Save.request_save("device")
	queue_redraw()


func content(kind: String) -> int:
	return int(inst.get("state", {}).get(kind, 0))


func set_content(kind: String, v: int) -> void:
	var st: Dictionary = inst.get("state", {})
	st[kind] = max(0, v)
	inst["state"] = st
	Save.request_save("bowl")
	queue_redraw()


func animate(key: String, to: float, dur := 0.4) -> void:
	if _anim_tweens.has(key) and _anim_tweens[key].is_valid():
		_anim_tweens[key].kill()
	var tw := create_tween()
	tw.tween_method(_set_anim.bind(key), float(anim.get(key, 0.0)), to, dur).set_trans(Tween.TRANS_SINE)
	_anim_tweens[key] = tw


func _set_anim(v: float, key: String) -> void:
	anim[key] = v
	queue_redraw()


func _process(delta: float) -> void:
	anim["t"] = float(anim["t"]) + delta
	if room and room.get("clock"):
		anim["hour"] = room.clock.game_hour()
	if Engine.get_process_frames() % 2 == 0:
		queue_redraw()


func sync_to_inst() -> void:
	inst["x"] = position.x
	inst["y"] = position.y
	inst["flip"] = scale.x < 0


func _draw() -> void:
	if def.get("shape") == "window":
		return
	if lift != 0.0:
		draw_set_transform(Vector2(0, -lift))
	if ghost:
		var fp := Rect2(-size().x / 2, -size().y, size().x, size().y) if not is_wall() else Rect2(-size().x / 2, -size().z / 2, size().x, size().z)
		draw_rect(fp.grow(6), Color(0.4, 0.85, 0.5, 0.35) if ghost_valid else Color(0.95, 0.35, 0.4, 0.4))
		draw_rect(fp.grow(6), Color(0.3, 0.7, 0.4, 0.9) if ghost_valid else Color(0.9, 0.2, 0.3, 0.9), false, 4.0)
	FurniturePainter.draw(self, def, inst.get("state", {}), anim)
	_draw_repair_fx()
	if selected:
		var vr := visual_rect()
		var local := Rect2(vr.position - position, vr.size)
		draw_rect(local, Color(1, 1, 1, 0.9), false, 5.0)
		draw_rect(local.grow(4), Color(0.95, 0.5, 0.7, 0.8), false, 3.0)
	draw_set_transform(Vector2.ZERO)


## Sparkles while the girl fixes the bed ("fixing" 0..1) and a burst when done ("shine" 1..0).
func _draw_repair_fx() -> void:
	var fixing := float(anim.get("fixing", 0.0))
	var shine := float(anim.get("shine", 0.0))
	if fixing <= 0.0 and shine <= 0.0:
		return
	var vr := visual_rect()
	var c := vr.get_center() - position + Vector2(0, 40)
	if fixing > 0.0 and fixing < 1.0:
		for i in 6:
			var ph := fmod(fixing * 9.0 + i / 6.0, 1.0)
			var p := c + Vector2(sin(i * 2.3 + fixing * 20.0) * vr.size.x * 0.32, vr.size.y * 0.25 - ph * vr.size.y * 0.5)
			draw_colored_polygon(DrawUtil.star_points(p, 10.0 + i % 3 * 3.0, 4.0), Color(1.0, 0.85, 0.35, 1.0 - ph))
	if shine > 0.0:
		var k := 1.0 - shine
		for i in 12:
			var a := TAU * i / 12.0
			var p := c + Vector2(cos(a), sin(a) * 0.7) * (60.0 + k * vr.size.x * 0.45)
			draw_colored_polygon(DrawUtil.star_points(p, 14.0, 6.0), Color(1.0, 0.8, 0.9, shine) if i % 2 == 0 else Color(1.0, 0.9, 0.4, shine))
		draw_colored_polygon(DrawUtil.heart_points(c + Vector2(0, -vr.size.y * 0.3 - k * 60.0), 26.0), Color(1.0, 0.45, 0.65, shine))


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and front_overlay and is_instance_valid(front_overlay):
		front_overlay.queue_free()


class _HouseFront extends Node2D:
	var f: Furniture
	var visible_when_occupied := true

	func _process(_d: float) -> void:
		if f == null or not is_instance_valid(f):
			queue_free()
			return
		position = f.position + Vector2(0, 2)
		scale = f.scale
		visible = bool(f.anim.get("occupied", false)) and not f.ghost

	func _draw() -> void:
		FurniturePainter.draw_house_front(self, f.def)



## Blanket drawn OVER a sleeping girl (she is tucked in, head on the pillow).
class _BedBlanket extends Node2D:
	var f: Furniture
	var t := 0.0

	var fade := 0.0

	func _process(delta: float) -> void:
		if f == null or not is_instance_valid(f):
			queue_free()
			return
		t += delta
		position = f.position + Vector2(0, 3)
		scale = f.scale
		var on := bool(f.anim.get("sleeper", false)) and not f.ghost
		fade = move_toward(fade, 1.0 if on else 0.0, delta * 2.5)  # tuck in / out softly
		modulate.a = fade
		if (fade > 0.0) != visible:
			visible = fade > 0.0
		if visible:
			queue_redraw()

	func _draw() -> void:
		if f.def.has("sprite"):
			# front-facing sprite bed: redraw the blanket part of the picture over her
			draw_set_transform(Vector2(0, -3 - f.lift))
			FurniturePainter.draw_sprite_part(self, f.def, f.inst.get("state", {}), float(f.def.get("sprite_cut", 0.4)), 1.0)
			draw_set_transform(Vector2.ZERO)
			return
		var sz: Dictionary = f.def.get("size", {})
		var w := float(sz.get("w", 300))
		var d := float(sz.get("d", 100))
		var h := float(sz.get("h", 200))
		var c := FurniturePainter.cols(f.def)
		var breathe := sin(t * 1.6) * 2.0
		var x0 := -w / 2 + w * 0.28
		var x1 := w / 2 - 2
		var top := -d * 0.5 - h * 0.30 - 8.0 - breathe  # at the sleeper's body level
		var pts := PackedVector2Array()
		pts.append(Vector2(x0 - 6, -h * 0.13))
		# soft rounded top following the body under the blanket
		for i in 17:
			var k := float(i) / 16.0
			var x := lerpf(x0, x1, k)
			var bump := sin(k * PI) * 14.0 + (8.0 if k < 0.25 else 0.0) * (1.0 - k * 4.0)
			pts.append(Vector2(x, top - bump * 0.6 + k * 10.0))
		pts.append(Vector2(x1 + 6, -h * 0.30))
		pts.append(Vector2(x1 + 6, -h * 0.12))
		DrawUtil.poly(self, pts, c["main"], true, 0.15)
		# folded edge near the chest
		DrawUtil.rrect(self, Rect2(x0 - 8, top - 10, 30, h * 0.30 - 10 + 26 - h * 0.13 + 10), 10, c["accent"], true, 0.05)
		for i in 4:
			var fx := x0 + 40 + i * (x1 - x0 - 40) / 4.0
			draw_line(Vector2(fx, top + 8), Vector2(fx + 10, -h * 0.15), c["main"].darkened(0.1), 3, true)
		if f.def.get("deco", "") == "stars":
			for i in 4:
				draw_colored_polygon(DrawUtil.star_points(Vector2(x0 + 50 + i * (x1 - x0 - 60) / 4.0, top + 22), 8, 3.5), c["trim"])
