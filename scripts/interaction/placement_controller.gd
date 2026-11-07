class_name PlacementController
extends RefCounted
## Rearrange mode: pick, drag with snap, validity preview, flip, confirm,
## cancel, undo, store to inventory. Shop previews reuse the same ghost logic.
## Rules: floor items stay on the floor, wall items on the wall, small items
## may snap onto host surfaces; nothing floats between surfaces; footprints may
## not overlap; every item keeps at least one reachable access point.

const SNAP := 10.0

var room: Room
var active := false
var target: Node = null          # Furniture or Toy being moved
var orig := {}                   # original x,y,flip,host
var undo_stack: Array = []
var preview_item := ""           # shop preview item_id (not owned yet)
var replacing_uid := -1


func _init(r: Room) -> void:
	room = r


func begin(t: Node) -> void:
	if t is Furniture and (t as Furniture).is_fixed():
		return
	end_selection()
	target = t
	orig = {"x": t.position.x, "y": t.position.y, "flip": t.scale.x < 0 if t is Furniture else false, "host": t.host.uid if t is Furniture and t.host else -1}
	t.selected = true
	t.ghost = true
	_update_validity()
	Diag.event("place_begin", {"uid": t.uid, "item": t.item_id})


func end_selection() -> void:
	if target and is_instance_valid(target):
		target.selected = false
		target.ghost = false
		target.queue_redraw()
	target = null
	replacing_uid = -1


## Move ghost to a world point (finger), applying snap/surface rules.
func drag_to(world: Vector2) -> void:
	if target == null:
		return
	var p := world
	if target is Toy:
		var tp := RoomGeo.clamp_walk(p)
		target.floor_pos = tp
		target.position = tp
		_update_validity()
		return
	var f: Furniture = target
	var s := f.size()
	match f.placement():
		"wall":
			p.x = clampf(snappedf(p.x, SNAP), s.x / 2 + 20, RoomGeo.WIDTH - s.x / 2 - 20)
			p.y = clampf(snappedf(p.y, SNAP), RoomGeo.WALL_ITEM_TOP + s.z / 2, RoomGeo.WALL_ITEM_BOTTOM - s.z / 2)
			f.position = p
		_:
			# finger is roughly at the item's middle; footprint front-centre below it
			p.y += min(60.0, s.z * 0.3)
			var host: Furniture = null
			if f.placement() == "floor_or_surface":
				host = room.host_surface_at(p, f)
			if host:
				var hs: Dictionary = host.def.get("host_surface", {})
				var hw: float = host.size().x * float(hs.get("w", 0.9)) * 0.5 - s.x / 2
				f.host = host
				f.lift = host.size().z * float(hs.get("lift", 0.92)) + host.size().y * 0.5
				f.position = Vector2(clampf(snappedf(p.x, SNAP), host.position.x - hw, host.position.x + hw), host.position.y + 1.0)
			else:
				f.host = null
				f.lift = 0.0
				var fy := clampf(snappedf(p.y, SNAP), RoomGeo.WALL_BOTTOM + s.y + 2.0, RoomGeo.HEIGHT - 6.0)
				if f.placement() == "flat":
					fy = clampf(snappedf(p.y, SNAP), RoomGeo.WALL_BOTTOM + s.y, RoomGeo.HEIGHT)
				f.position = Vector2(clampf(snappedf(p.x, SNAP), s.x / 2 + 20, RoomGeo.WIDTH - s.x / 2 - 20), fy)
	_update_validity()


func flip() -> void:
	if target is Furniture:
		target.scale.x = -target.scale.x
		_update_validity()


func _update_validity() -> void:
	if target == null:
		return
	var ok: bool = is_valid(target)
	target.ghost_valid = ok
	target.queue_redraw()


func is_valid(t: Node) -> bool:
	if t is Toy:
		return room.nav.is_free(t.floor_pos)
	var f: Furniture = t
	var fp := f.footprint()
	if f.is_wall():
		if fp.intersects(RoomGeo.WINDOW_RECT.grow(30)):
			return false
		for o in room.furniture_nodes():
			if o != f and o.is_wall() and o.footprint().intersects(fp):
				return false
		return fp.position.y >= RoomGeo.WALL_ITEM_TOP - 1 and fp.end.y <= RoomGeo.WALL_ITEM_BOTTOM + 1
	if f.host != null:
		for o in room.furniture_nodes():
			if o != f and o.host == f.host and o.footprint().intersects(fp):
				return false
		return true
	if fp.position.y < RoomGeo.WALL_BOTTOM - 1 or fp.end.y > RoomGeo.HEIGHT + 1 or fp.position.x < 0 or fp.end.x > RoomGeo.WIDTH:
		return false
	if f.placement() == "flat":
		for o in room.furniture_nodes():
			if o != f and o.placement() == "flat" and o.footprint().intersects(fp.grow(-10)):
				return false
		return true
	for o in room.furniture_nodes():
		if o == f or o.uid == replacing_uid or not o.is_obstacle():
			continue
		if o.footprint().grow(4).intersects(fp):
			return false
	# keep access: the moved item and every other item need >=1 reachable approach
	return room.access_ok_with(f)


## Confirm move. Returns true if applied.
func confirm() -> bool:
	if target == null:
		return false
	if not is_valid(target):
		AudioSvc.sfx("hint")
		return false
	var t := target
	undo_stack.append({"uid": t.uid, "x": orig["x"], "y": orig["y"], "flip": orig["flip"], "host": orig["host"]})
	if undo_stack.size() > 30:
		undo_stack.pop_front()
	if t is Furniture:
		t.inst["host_uid"] = t.host.uid if t.host else -1
		if t.host == null:
			t.inst.erase("host_uid")
	t.sync_to_inst()
	end_selection()
	room.on_layout_changed(t)
	AudioSvc.sfx("pop")
	Diag.event("place_confirm", {"uid": t.uid, "x": int(t.position.x), "y": int(t.position.y)})
	Save.request_save("rearrange")
	return true


func cancel() -> void:
	if target == null:
		return
	var t := target
	_restore(t, orig)
	end_selection()
	room.on_layout_changed(t)


func _restore(t: Node, o: Dictionary) -> void:
	if t is Toy:
		t.floor_pos = Vector2(o["x"], o["y"])
		t.position = t.floor_pos
	else:
		t.position = Vector2(o["x"], o["y"])
		t.scale.x = -1.0 if o["flip"] else 1.0
		var h: Node = room.furniture_by_uid(int(o.get("host", -1)))
		t.host = h
		t.lift = (h.size().z * float(h.def.get("host_surface", {}).get("lift", 0.92)) + h.size().y * 0.5) if h else 0.0
	t.queue_redraw()


func undo() -> bool:
	if undo_stack.is_empty():
		return false
	var u: Dictionary = undo_stack.pop_back()
	var t: Node = room.node_by_uid(int(u["uid"]))
	if t == null:
		return false
	_restore(t, u)
	if t is Furniture:
		if t.host:
			t.inst["host_uid"] = t.host.uid
		else:
			t.inst.erase("host_uid")
	t.sync_to_inst()
	room.on_layout_changed(t)
	Save.request_save("undo")
	return true


func store_selected() -> bool:
	if target == null:
		return false
	var t := target
	end_selection()
	return room.store_node(t)
