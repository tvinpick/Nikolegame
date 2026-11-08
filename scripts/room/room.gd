class_name Room
extends Node2D
## The seamless 3-screen room. Owns layers, camera, navigation, interaction
## reservations, characters and touch routing. UI talks to it through signals
## and a few explicit methods; it never touches coins.

signal furniture_tapped(f: Furniture, screen_pos: Vector2)
signal pet_tapped(pet: Pet, screen_pos: Vector2)
signal girl_tapped(screen_pos: Vector2)
signal floor_tapped(world: Vector2)
signal selection_cleared()
signal layout_changed()
signal mode_changed(mode: String)
signal message(key: String)
signal girl_ui_request(name: String)

const TAP_MAX_MS := 450
const DRAG_THRESHOLD := 22.0

var camera: CameraRig
var painter: RoomPainter
var wall_layer: Node2D
var window_view: WindowView
var entities: Node2D
var overlay: Node2D
var tint: CanvasModulate
var clock: WorldClock
var nav := NavGrid.new()
var interactions := InteractionService.new()
var placement: PlacementController
var girl: Girl
var cat: Pet
var dog: Pet
var actors: Array = []
var mode := "play"               # play | rearrange | preview | pet_goto
var pet_goto_pet: Pet = null
var _touches: Dictionary = {}
var _gesture := ""               # "", tap, pan, pinch, toy, move
var _press_pos := Vector2.ZERO
var _press_time := 0
var _press_target: Node = null
var _pinch_dist := 0.0
var _social_cooldown := 20.0
var _needs_save_t := 0.0
var low_detail := false
var ui_blocker: Callable = Callable()   # returns true when a screen point is over UI
var input_locked := false


func _ready() -> void:
	clock = WorldClock.new()
	clock.name = "Clock"
	add_child(clock)
	painter = RoomPainter.new()
	painter.name = "Painter"
	add_child(painter)
	wall_layer = Node2D.new()
	wall_layer.name = "Wall"
	add_child(wall_layer)
	window_view = WindowView.new()
	window_view.name = "Window"
	wall_layer.add_child(window_view)
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)
	overlay = DebugOverlay.new()
	overlay.name = "Overlay"
	overlay.room = self
	add_child(overlay)
	tint = CanvasModulate.new()
	add_child(tint)
	camera = CameraRig.new()
	camera.name = "Camera"
	add_child(camera)
	camera.make_current()
	placement = PlacementController.new(self)
	Diag.state_provider = capture_scene_state


func build() -> void:
	clock.load_from_state()
	window_view.setup(clock, RoomGeo.WINDOW_RECT)
	clock.changed.connect(_on_clock_changed)
	apply_surfaces()
	for inst in GameState.data["instances"]:
		_spawn_instance(inst)
	_resolve_hosts()
	rebuild_nav()
	_spawn_characters()
	var gp: Array = GameState.data["girl"].get("pos", [2880, 900])
	camera.position = Vector2(float(gp[0]), 540)
	camera.target_pos = camera.clamp_pos(camera.position, camera.min_zoom())
	camera.target_zoom = camera.min_zoom()
	_on_clock_changed()
	Diag.event("room_built", {"instances": GameState.data["instances"].size()})


func apply_surfaces() -> void:
	var s: Dictionary = GameState.data["surfaces"]
	painter.set_surfaces(s.get("wall", "wall_pink_dots"), s.get("floor", "floor_oak"))
	window_view.set_landscape(s.get("landscape", "theme_mountains"))


func _spawn_instance(inst: Dictionary) -> Node:
	var def := Content.item(inst["item_id"])
	if def.is_empty() or def.get("placement", "none") == "none":
		return null
	if def.has("dynamic"):
		var t := Toy.new()
		t.setup(inst, self)
		entities.add_child(t)
		return t
	var f := Furniture.new()
	f.setup(inst, self)
	if f.is_wall():
		wall_layer.add_child(f)
	else:
		entities.add_child(f)
		if f.front_overlay:
			entities.add_child(f.front_overlay)
	return f


func _resolve_hosts() -> void:
	for f in furniture_nodes():
		var hu := int(f.inst.get("host_uid", -1))
		if hu >= 0:
			var h := furniture_by_uid(hu)
			if h:
				f.host = h
				f.lift = h.size().z * float(h.def.get("host_surface", {}).get("lift", 0.92)) + h.size().y * 0.5
				f.position.y = h.position.y + 1.0
			else:
				f.inst.erase("host_uid")


func _spawn_characters() -> void:
	girl = Girl.new()
	girl.name = "Girl"
	girl.room = self
	girl.apply_appearance(GameState.appearance())
	var gp: Array = GameState.data["girl"].get("pos", [2880, 900])
	girl.position = nav.nearest_free(Vector2(float(gp[0]), float(gp[1])))
	entities.add_child(girl)
	girl.ui_requested.connect(func(n: String, _g): girl_ui_request.emit(n))
	actors.append(girl)
	for sp in ["cat", "dog"]:
		var st: Dictionary = GameState.pet(sp)
		var p := Pet.new()
		p.name = sp.capitalize()
		p.room = self
		p.setup_pet(sp, st.get("breed", ""))
		p.set_accessory(st.get("accessory", "none"))
		for n in Pet.NEEDS:
			p.needs[n] = float(st.get("needs", {}).get(n, 80.0))
		var pp: Array = st.get("pos", [2000, 950])
		p.position = nav.nearest_free(Vector2(float(pp[0]), float(pp[1])))
		entities.add_child(p)
		actors.append(p)
		if sp == "cat":
			cat = p
		else:
			dog = p


## Offline needs change: slow, capped, never below the floor, and system clock
## rollback can never make things worse.
static func offline_needs(needs: Dictionary, elapsed_sec: float, cfg: Dictionary) -> Dictionary:
	var out := needs.duplicate()
	var hours: float = clampf(elapsed_sec / 3600.0, 0.0, float(cfg.get("offline_max_hours", 6.0)))
	var floor_v := float(cfg.get("offline_floor", 25.0))
	var decay: Dictionary = cfg.get("decay_per_min", {})
	for k in out.keys():
		var before := float(out[k])
		var decayed := before - float(decay.get(k, 0.5)) * hours * 60.0 * 0.25  # closed game: 4x slower
		# offline time never pushes a need below the floor (and never worsens a need already below it)
		out[k] = clampf(max(decayed, min(before, floor_v)), 0.0, 100.0)
	return out


func apply_offline_time(elapsed_sec: float) -> void:
	var cfg: Dictionary = Content.econ("needs", {})
	for p in [cat, dog]:
		p.needs = offline_needs(p.needs, elapsed_sec, cfg)
	Diag.event("offline", {"sec": int(elapsed_sec)})


func set_low_detail(on: bool) -> void:
	low_detail = on
	window_view.set_low_detail(on)


# ---------------------------------------------------------------- queries

func furniture_nodes() -> Array:
	var out: Array = []
	for n in entities.get_children():
		if n is Furniture and not n.is_queued_for_deletion():
			out.append(n)
	for n in wall_layer.get_children():
		if n is Furniture and not n.is_queued_for_deletion():
			out.append(n)
	return out


func toy_nodes() -> Array:
	var out: Array = []
	for n in entities.get_children():
		if n is Toy and not n.is_queued_for_deletion():
			out.append(n)
	return out


func furniture_by_uid(uid: int) -> Furniture:
	for f in furniture_nodes():
		if f.uid == uid:
			return f
	return null


func node_by_uid(uid: int) -> Node:
	var f := furniture_by_uid(uid)
	if f:
		return f
	for t in toy_nodes():
		if t.uid == uid:
			return t
	return null


func find_furniture_with_profile(profile: String) -> Furniture:
	for f in furniture_nodes():
		if f.def.get("interaction_profile", "") == profile:
			return f
	return null


func nearest_toy(p: Vector2, kind_: String) -> Toy:
	var best: Toy = null
	var bd := INF
	for t in toy_nodes():
		if t.kind == kind_ and t.holder == null and not t.dragging:
			var d := p.distance_to(t.floor_pos)
			if d < bd:
				bd = d
				best = t
	return best


func host_surface_at(p: Vector2, exclude: Furniture) -> Furniture:
	for f in furniture_nodes():
		if f == exclude or not f.def.has("host_surface"):
			continue
		var top: float = f.position.y - f.size().z * 0.92 - f.size().y
		var r := Rect2(f.position.x - f.size().x * 0.45, top - 80, f.size().x * 0.9, 160)
		if r.has_point(p - Vector2(0, 40)):
			return f
	return null


func obstacle_rects(extra: Furniture = null, ignore_uid := -1) -> Array:
	var rects: Array = []
	for f in furniture_nodes():
		if f.uid == ignore_uid or f == extra:
			continue
		if f.is_obstacle() and not f.ghost and f.uid >= 0:
			rects.append(f.footprint())
	if extra and extra.is_obstacle():
		rects.append(extra.footprint())
	return rects


func rebuild_nav() -> void:
	nav.rebuild(obstacle_rects())
	Diag.event("nav_rebuild", {"v": nav.version})


## Would the layout (with f at its current ghost position) keep access?
func access_ok_with(f: Furniture) -> bool:
	var test := NavGrid.new()
	test.rebuild(obstacle_rects(f, placement.replacing_uid))
	var from := test.nearest_free(girl.position if girl else Vector2(2880, 900))
	for o in furniture_nodes():
		if o.uid == placement.replacing_uid:
			continue
		var aps: Array = o.approach_points()
		if aps.is_empty() or o.def.get("interaction_profile", "") in ["decor", "surface"]:
			continue
		var any := false
		for ap in aps:
			var c: Vector2 = ap
			if RoomGeo.walk_rect().has_point(c) and test.reachable(from, test.nearest_free(c, 2)) and test.nearest_free(c, 2).distance_to(c) < 30.0:
				any = true
				break
		if not any:
			return false
	return true


func best_approach(actor: Actor, f: Furniture, anchor_pos: Vector2) -> Vector2:
	var best := nav.nearest_free(anchor_pos)
	var bd := INF
	for ap in f.approach_points():
		var p: Vector2 = ap
		if not RoomGeo.walk_rect().has_point(p) or not nav.is_free(p):
			continue
		var d := actor.position.distance_to(p) * 0.6 + p.distance_to(anchor_pos)
		if d < bd and nav.reachable(actor.position, p):
			bd = d
			best = p
	return best


func random_free_point_near(p: Vector2, radius: float) -> Vector2:
	for i in 12:
		var c := RoomGeo.clamp_walk(p + Vector2(randf_range(-radius, radius), randf_range(-160, 160)))
		if nav.is_free(c):
			return c
	return nav.nearest_free(p)


func random_girl_action(ids: Array) -> Dictionary:
	var cands: Array = []
	for f in furniture_nodes():
		for a in f.actions_for("girl"):
			if a["id"] in ids and a.get("opens_ui", "") == "" and interactions.free_slots(f, a.get("anchor", "")) > 0:
				if girl.position.distance_to(f.position) < 1600.0:
					cands.append({"f": f, "action": a})
	if cands.is_empty():
		return {}
	return cands[randi() % cands.size()]


func furniture_actions_for_pet(p: Pet, ids: Array) -> Array:
	var out: Array = []
	for f in furniture_nodes():
		if f.ghost:
			continue
		for a in f.actions_for(p.kind):
			if a["id"] in ids and interactions.free_slots(f, a["anchor"]) > 0:
				var max_sz := int(a.get("max_size", f.def.get("max_size", 9)))
				if p.size_class() <= max_sz:
					out.append({"f": f, "action": a})
	return out


func pick_pet_for_care() -> Pet:
	if cat.can_join() and (not dog.can_join() or cat.needs["cleanliness"] <= dog.needs["cleanliness"]):
		return cat
	return dog if dog.can_join() else null


func free_direction(p: Vector2, preferred: float) -> float:
	if nav.line_free(p, RoomGeo.clamp_walk(p + Vector2(preferred * 300.0, 0))):
		return preferred
	return -preferred


# ---------------------------------------------------------------- social (pets together)

func try_social(p: Pet) -> bool:
	if _social_cooldown > 0.0:
		return false
	var other: Pet = dog if p == cat else cat
	if not p.can_join() or not other.can_join() or other.current != "" or other.attached_to != null:
		return false
	if p.position.distance_to(other.position) > 1400.0:
		return false
	var owner := "social"
	if not interactions.lock_actor(p.actor_id, owner) or not interactions.lock_actor(other.actor_id, owner):
		interactions.unlock_actor(p.actor_id, owner)
		interactions.unlock_actor(other.actor_id, owner)
		return false
	_social_cooldown = randf_range(30.0, 60.0)
	var kind_ := "chase" if randf() < 0.45 and p.needs["energy"] > 50.0 and other.needs["energy"] > 50.0 else "meet"
	Diag.event("social", {"kind": kind_})
	var lead: Pet = cat if kind_ == "chase" else p
	var follow: Pet = dog if kind_ == "chase" else other
	lead.social_step(kind_, follow, "lead")
	follow.social_step(kind_, lead, "follow")
	return true


func end_social(p: Pet) -> void:
	interactions.unlock_actor(p.actor_id, "social")


# ---------------------------------------------------------------- camera helpers

func focus_if_far(world: Vector2) -> void:
	if not camera.is_visible_x(world.x):
		camera.focus(Vector2(world.x, camera.target_pos.y))


func focus_zoom(world: Vector2, z: float) -> void:
	camera.push_zoom(world, z)


func restore_zoom() -> void:
	camera.pop_zoom()


# ---------------------------------------------------------------- layout changes

func on_layout_changed(changed: Node = null) -> void:
	if changed is Furniture:
		var f: Furniture = changed
		f.anim["sleeper"] = false
		# interrupt anyone using the moved item
		for a in interactions.evict(f):
			var actor := _actor_by_id(a)
			if actor is Pet:
				actor.evicted()
			elif actor is Girl:
				actor.interrupt = true
				if actor.attached_to == f:
					actor.detach_to(nav.nearest_free(actor.position), 0.3)
		for o in furniture_nodes():
			if o.host == f:
				o.position = Vector2(o.position.x + 0.0, f.position.y + 1.0)
				o.sync_to_inst()
	rebuild_nav()
	layout_changed.emit()


func _actor_by_id(id: String) -> Actor:
	for a in actors:
		if a.actor_id == id:
			return a
	return null


func store_node(n: Node) -> bool:
	if n is Furniture and n.is_fixed():
		return false
	var uid: int = n.uid
	if n is Furniture:
		for a in interactions.evict(n):
			var actor := _actor_by_id(a)
			if actor is Pet:
				actor.evicted()
		for o in furniture_nodes():
			if o.host == n:
				o.queue_free()
	if n is Toy and n.holder != null:
		n.holder = null
	if not Economy.store_instance(uid):
		return false
	n.queue_free()
	rebuild_nav()
	layout_changed.emit()
	return true


## Place an owned, stored item: find a valid spot near the camera centre.
func place_owned(item_id: String, near: Vector2 = Vector2.INF) -> Node:
	if near == Vector2.INF:
		near = camera.position
	var def := Content.item(item_id)
	var group: String = def.get("unique_group", "")
	var replacing: Furniture = null
	if group != "":
		for f in furniture_nodes():
			if f.def.get("unique_group", "") == group:
				replacing = f
	var probe_inst := {"uid": -999, "item_id": item_id, "x": near.x, "y": near.y, "flip": false, "state": {}}
	var spot := Vector2.INF
	if replacing:
		spot = replacing.position
	else:
		spot = find_free_spot(probe_inst, near)
	if spot == Vector2.INF:
		message.emit("msg_no_space")
		return null
	if replacing:
		for a in interactions.evict(replacing):
			var actor := _actor_by_id(a)
			if actor is Pet:
				actor.evicted()
	var uid := Economy.place_from_inventory(item_id, spot)
	if uid < 0:
		return null
	# remove nodes whose instances were displaced to inventory (unique group)
	var live := {}
	for inst in GameState.data["instances"]:
		live[int(inst["uid"])] = true
	for n in furniture_nodes() + toy_nodes():
		if not live.has(n.uid):
			n.queue_free()
	var inst := GameState.instance_by_uid(uid)
	var node := _spawn_instance(inst)
	_resolve_hosts()
	rebuild_nav()
	layout_changed.emit()
	return node


## Spiral search for a valid footprint position.
func find_free_spot(inst: Dictionary, near: Vector2) -> Vector2:
	var ghost := Furniture.new()
	var def := Content.item(inst["item_id"])
	if def.has("dynamic"):
		return nav.nearest_free(RoomGeo.clamp_walk(Vector2(near.x, 960)))
	ghost.setup(inst, self)
	ghost.uid = -999
	var start := Vector2(near.x, 900.0) if not ghost.is_wall() else Vector2(near.x, 320.0)
	entities.add_child(ghost)
	ghost.visible = false
	var found := Vector2.INF
	for r in range(0, 30):
		for k in range(-r, r + 1):
			for dy in ([0, -80, 80, -160] if not ghost.is_wall() else [0, -60, 60]):
				var p := start + Vector2(k * 60.0, dy)
				placement.target = ghost
				placement.drag_to(p - Vector2(0, min(60.0, ghost.size().z * 0.3)) if not ghost.is_wall() else p)
				if placement.is_valid(ghost):
					found = ghost.position
					break
			if found != Vector2.INF:
				break
		if found != Vector2.INF:
			break
	placement.target = null
	ghost.queue_free()
	return found


# ---------------------------------------------------------------- shop preview

var preview_node: Node = null


func start_preview(item_id: String) -> bool:
	cancel_preview()
	var def := Content.item(item_id)
	if def.get("placement", "none") in ["none", "fixed"]:
		return false
	var inst := {"uid": -5, "item_id": item_id, "x": camera.position.x, "y": 900.0, "flip": false, "state": Economy.default_instance_state(item_id)}
	var spot := Vector2.INF
	var group: String = def.get("unique_group", "")
	var replacing: Furniture = null
	if group != "":
		for f in furniture_nodes():
			if f.def.get("unique_group", "") == group:
				replacing = f
	if replacing:
		spot = replacing.position
	else:
		spot = find_free_spot(inst, camera.position)
	if def.has("dynamic"):
		var t := Toy.new()
		inst["x"] = spot.x if spot != Vector2.INF else camera.position.x
		inst["y"] = spot.y if spot != Vector2.INF else 960.0
		t.setup(inst, self)
		entities.add_child(t)
		preview_node = t
	else:
		var f := Furniture.new()
		f.setup(inst, self)
		if spot != Vector2.INF:
			f.position = spot
		if f.is_wall():
			wall_layer.add_child(f)
		else:
			entities.add_child(f)
		preview_node = f
	placement.begin(preview_node)
	if replacing:
		placement.replacing_uid = replacing.uid
		replacing.modulate.a = 0.35
		placement._update_validity()
	set_mode("preview")
	camera.focus(Vector2(preview_node.position.x, camera.target_pos.y))
	return true


func preview_valid() -> bool:
	return preview_node != null and placement.is_valid(preview_node)


func preview_position() -> Vector2:
	return preview_node.position if preview_node else Vector2.INF


func cancel_preview() -> void:
	if preview_node and is_instance_valid(preview_node):
		var rep := furniture_by_uid(placement.replacing_uid)
		if rep:
			rep.modulate.a = 1.0
		placement.end_selection()
		preview_node.queue_free()
	preview_node = null
	if mode == "preview":
		set_mode("play")


## After a successful purchase: turn the preview into a real placed instance.
func commit_preview(item_id: String) -> Node:
	var pos := preview_position()
	var host_uid := -1
	if preview_node is Furniture and preview_node.host:
		host_uid = preview_node.host.uid
	var flip: bool = preview_node is Furniture and preview_node.scale.x < 0
	var was_valid := preview_valid()
	cancel_preview()
	if not was_valid:
		message.emit("msg_in_inventory")
		return null
	var group: String = Content.item(item_id).get("unique_group", "")
	if group != "":
		for f in furniture_nodes():
			if f.def.get("unique_group", "") == group:
				for a in interactions.evict(f):
					var actor := _actor_by_id(a)
					if actor is Pet:
						actor.evicted()
	var uid := Economy.place_from_inventory(item_id, pos, host_uid)
	if uid < 0:
		return null
	var inst := GameState.instance_by_uid(uid)
	inst["flip"] = flip
	var live := {}
	for i in GameState.data["instances"]:
		live[int(i["uid"])] = true
	for n in furniture_nodes() + toy_nodes():
		if not live.has(n.uid):
			n.queue_free()
	var node := _spawn_instance(inst)
	_resolve_hosts()
	rebuild_nav()
	layout_changed.emit()
	Save.request_save("placed_purchase")
	return node


func set_mode(m: String) -> void:
	if m == mode:
		return
	if mode == "rearrange" and placement.target:
		placement.cancel()
	mode = m
	Diag.event("mode", {"mode": m})
	mode_changed.emit(m)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom_at(1.1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom_at(1.0 / 1.1, event.position)


func screen_to_world(p: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * p


func world_to_screen(p: Vector2) -> Vector2:
	return get_canvas_transform() * p


func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed and (input_locked or (ui_blocker.is_valid() and ui_blocker.call(e.position))):
		return
	if e.pressed:
		_touches[e.index] = e.position
		if _touches.size() == 2:
			_gesture = "pinch"
			var pts := _touches.values()
			_pinch_dist = (pts[0] as Vector2).distance_to(pts[1])
			camera.dragging = false
			return
		if _touches.size() == 1:
			_press_pos = e.position
			_press_time = Time.get_ticks_msec()
			_gesture = "press"
			var w := screen_to_world(e.position)
			_press_target = _pick_drag_target(w)
	else:
		var was := _gesture
		_touches.erase(e.index)
		if _touches.size() > 0:
			return
		camera.release_pan()
		match was:
			"press":
				if Time.get_ticks_msec() - _press_time < TAP_MAX_MS:
					_on_tap(e.position)
			"toy":
				if _press_target and is_instance_valid(_press_target):
					_press_target.end_drag()
			"move":
				pass
		_gesture = ""
		_press_target = null


func _on_drag(e: InputEventScreenDrag) -> void:
	if not _touches.has(e.index):
		return
	_touches[e.index] = e.position
	if _gesture == "pinch" and _touches.size() >= 2:
		var pts := _touches.values()
		var d := (pts[0] as Vector2).distance_to(pts[1])
		if _pinch_dist > 1.0:
			camera.zoom_at(d / _pinch_dist, ((pts[0] as Vector2) + (pts[1] as Vector2)) * 0.5)
		_pinch_dist = d
		return
	if _gesture == "press" and e.position.distance_to(_press_pos) > DRAG_THRESHOLD:
		if _press_target is Toy and mode == "play":
			_gesture = "toy"
			_press_target.begin_drag()
		elif mode in ["rearrange", "preview"] and _press_target != null and (_press_target == placement.target or mode == "rearrange"):
			if placement.target != _press_target:
				placement.begin(_press_target)
			_gesture = "move"
		else:
			_gesture = "pan"
			camera.dragging = true
	match _gesture:
		"pan":
			camera.pan_by_screen(e.relative)
		"toy":
			if is_instance_valid(_press_target):
				_press_target.drag_to(screen_to_world(e.position))
		"move":
			placement.drag_to(screen_to_world(e.position))


func _pick_drag_target(w: Vector2) -> Node:
	if mode == "play":
		for t in toy_nodes():
			if t.hit_test(w) and t.holder == null:
				return t
		return null
	if mode == "preview":
		if preview_node and (preview_node.hit_test(w) or (preview_node is Furniture and preview_node.footprint().grow(40).has_point(w))):
			return preview_node
		return null
	# rearrange: front-most furniture/toy under the finger
	return _hit_furniture(w, true)


func _hit_furniture(w: Vector2, include_toys := false) -> Node:
	var best: Node = null
	var best_y := -INF
	if include_toys:
		for t in toy_nodes():
			if t.hit_test(w):
				return t
	for f in furniture_nodes():
		if f.ghost and f != placement.target:
			continue
		if f.hit_test(w):
			var y: float = f.position.y + (10000.0 if f.host else 0.0) - (5000.0 if f.is_wall() or f.def.get("shape") == "window" else 0.0) - (8000.0 if f.placement() == "flat" else 0.0)
			if y > best_y:
				best_y = y
				best = f
	return best


func _hit_actor(w: Vector2) -> Actor:
	for a in [cat, dog, girl]:
		if a == null:
			continue
		var g: Vector2 = a.ground_point()
		var h: float = (240.0 if a is Girl else 80.0) * a.scale.y
		var wdt: float = (55.0 if a is Girl else 65.0) * a.scale.x
		if Rect2(g.x - wdt, g.y - h, wdt * 2, h + 20).has_point(w):
			return a
	return null


func _on_tap(screen: Vector2) -> void:
	var w := screen_to_world(screen)
	if mode == "rearrange":
		var t := _hit_furniture(w, true)
		if t:
			placement.begin(t)
		else:
			placement.end_selection()
			selection_cleared.emit()
		return
	if mode == "preview":
		return
	if mode == "pet_goto":
		var f := _hit_furniture(w)
		if f and pet_goto_pet:
			var acts: Array = f.actions_for(pet_goto_pet.kind)
			if acts.size() > 0 and pet_goto_pet.can_join():
				if not pet_goto_pet.use_furniture(f, acts[0], false):
					message.emit("msg_pet_cant")
			else:
				message.emit("msg_pet_cant")
		set_mode("play")
		pet_goto_pet = null
		return
	var a := _hit_actor(w)
	if a is Pet:
		pet_tapped.emit(a, screen)
		AudioSvc.sfx("pop")
		return
	if a is Girl:
		girl_tapped.emit(screen)
		return
	for t in toy_nodes():
		if t.hit_test(w):
			# tap on a ball: girl goes to throw it
			if t.kind == "ball":
				girl.command({"type": "pet_cmd", "cmd": "play", "pet": dog if dog.can_join() else cat})
			return
	var f2 := _hit_furniture(w)
	if f2 and (f2.actions_for("girl").size() > 0):
		furniture_tapped.emit(f2, screen)
		AudioSvc.sfx("pop")
		return
	if RoomGeo.is_floor_point(w) and w.y >= RoomGeo.WALK_TOP - 20:
		var target := RoomGeo.clamp_walk(w)
		selection_cleared.emit()
		floor_tapped.emit(target)
		girl.command({"type": "walk", "pos": target})
		overlay.flash_target(target)
	else:
		selection_cleared.emit()


func on_toy_thrown(t: Toy) -> void:
	# dog likes to chase thrown balls
	if t.kind == "ball" and dog.can_join() and randf() < 0.8:
		dog.chase_toy(t, true)
	elif t.kind == "ball" and cat.can_join():
		cat.chase_toy(t, false)


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	window_view.update_camera(camera.position.x)
	_social_cooldown = max(0.0, _social_cooldown - delta)
	tint.color = clock.room_tint().lerp(Color.WHITE, 0.35 if _any_light_on() else 0.0)
	_needs_save_t += delta
	if _needs_save_t > 45.0:
		_needs_save_t = 0.0
		store_runtime_state()
		Save.request_save("periodic_runtime")


func _any_light_on() -> bool:
	for f in furniture_nodes():
		if f.def.get("device", "") == "light" and f.is_on():
			return true
	return false


func _on_clock_changed() -> void:
	clock.store_to_state()
	if clock.weather == "rain":
		AudioSvc.sfx("rain_loop", null, -16.0)


## Copy runtime positions/needs into GameState (called before saves).
func store_runtime_state() -> void:
	if girl == null:
		return
	var gp := nav.nearest_free(girl.position)
	GameState.data["girl"]["pos"] = [gp.x, gp.y]
	for p in [cat, dog]:
		var st: Dictionary = GameState.pet(p.species)
		var s: Dictionary = p.save_state()
		st["needs"] = s["needs"]
		st["pos"] = s["pos"]
		st["breed"] = p.breed_id
	for t in toy_nodes():
		if t.holder == null:
			t.sync_to_inst()
	clock.store_to_state()


func capture_scene_state() -> Dictionary:
	var out := {"mode": mode, "camera": [camera.position.x, camera.position.y, camera.zoom.x], "nav_version": nav.version, "actors": [], "interactions": interactions.snapshot(), "world": {"season": clock.season, "weather": clock.weather, "clock": clock.clock}}
	for a in actors:
		out["actors"].append(a.debug_info())
	return out
