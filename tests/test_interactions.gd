extends RefCounted
## Interaction profile reuse across variants, placement rules, and behaviour
## scenarios in a real Room (accelerated time): sleep cycle, carry pet.

var runner: Object
var room: Room


func before_each() -> void:
	runner.root.get_node("Economy").new_game()
	var gs: Node = runner.root.get_node("GameState")
	gs.data["pets"]["cat"]["breed"] = "cat_ginger"
	gs.data["pets"]["dog"]["breed"] = "dog_corgi"


func after_each() -> void:
	Engine.time_scale = 1.0
	if room and is_instance_valid(room):
		room.queue_free()
		await runner.process_frame
	room = null


func _make_room() -> Room:
	room = Room.new()
	runner.root.add_child(room)
	room.build()
	return room


func test_every_profile_reused_by_variants() -> void:
	var c: Node = runner.root.get_node("Content")
	var by_profile := {}
	for id in c.items.keys():
		var it: Dictionary = c.items[id]
		if it.get("placement", "none") in ["none"]:
			continue
		var p: String = it.get("interaction_profile", "")
		if not by_profile.has(p):
			by_profile[p] = []
		by_profile[p].append(id)
	for p in ["bed", "sofa", "seat", "desk", "dining", "wardrobe", "mirror", "pet_bed", "pet_house", "scratcher", "bowl_food", "bowl_water", "device"]:
		runner.check(by_profile.get(p, []).size() >= 2, "profile %s has >=2 variants" % p)
	for p in by_profile.keys():
		var prof: Dictionary = c.profiles[p]
		for id in by_profile[p]:
			for a in prof.get("actions", []):
				var an: String = a.get("anchor", "")
				if an == "":
					continue
				var r: Dictionary = c.resolve_anchor(id, an)
				runner.check(not r.is_empty(), "%s resolves %s" % [id, an])
				if a.get("actor") == "girl" and a.get("pose", "") in ["sit", "read", "sleep", "eat", "desk", "desk_draw"]:
					runner.check(float(r["lift"]) > 20.0 and float(r["lift"]) < 90.0, "%s %s seat height sane (%.0f)" % [id, an, r["lift"]])


func test_house_sizes() -> void:
	var c: Node = runner.root.get_node("Content")
	for b in c.breeds_of("cat"):
		runner.check(int(b["size_class"]) <= int(c.item("cathouse_wood")["max_size"]), "cat %s fits wood house" % b["breed_id"])
		runner.check(int(b["size_class"]) <= int(c.item("cathouse_castle")["max_size"]), "cat fits castle")
	for b in c.breeds_of("dog"):
		runner.check(int(b["size_class"]) <= int(c.item("cathouse_castle")["max_size"]), "dog %s fits castle" % b["breed_id"])
	runner.check(int(c.breeds["dog_corgi"]["size_class"]) > int(c.item("cathouse_wood")["max_size"]), "corgi too big for wood house")


func test_starter_layout_valid_and_reachable() -> void:
	_make_room()
	for f in room.furniture_nodes():
		if f.is_fixed():
			continue
		runner.check(room.placement.is_valid(f), "starter %s valid" % f.item_id)
	for f in room.furniture_nodes():
		for a in f.actions_for("girl"):
			if a.get("remote", false):
				continue
			var anc: Dictionary = f.anchor(a["anchor"])
			var ap: Vector2 = room.best_approach(room.girl, f, anc["pos"])
			runner.check(room.nav.reachable(room.girl.position, ap), "%s/%s reachable" % [f.item_id, a["id"]])


func test_placement_rules() -> void:
	_make_room()
	var sofa := room.find_furniture_with_profile("sofa")
	var bed := room.find_furniture_with_profile("bed")
	var home := sofa.position
	room.placement.begin(sofa)
	room.placement.drag_to(bed.position + Vector2(0, -60))
	runner.check(not room.placement.is_valid(sofa), "overlap is invalid")
	runner.check(not room.placement.confirm(), "invalid confirm refused")
	room.placement.cancel()
	runner.eq(sofa.position, home, "cancel restores")
	room.placement.begin(sofa)
	room.placement.drag_to(Vector2(3200, 760))
	var ok: bool = room.placement.is_valid(sofa)
	runner.check(ok, "free spot valid")
	if ok:
		runner.check(room.placement.confirm(), "confirm")
		runner.check(room.placement.undo(), "undo")
		runner.eq(sofa.position, home, "undo restores")
	# wall item can't go on the window
	var pic := room.find_furniture_with_profile("decor")
	for f in room.furniture_nodes():
		if f.is_wall():
			pic = f
	room.placement.begin(pic)
	room.placement.drag_to(RoomGeo.WINDOW_RECT.get_center())
	runner.check(not room.placement.is_valid(pic), "picture not over window")
	room.placement.cancel()


func _states(actor: String) -> Array:
	var out: Array = []
	for e in runner.root.get_node("Diag").events:
		if e["e"] == "state" and e["d"].get("a") == actor:
			out.append(e["d"]["to"])
	return out


func test_sleep_cycle_repeated() -> void:
	_make_room()
	Engine.time_scale = 8.0
	var bed := room.find_furniture_with_profile("bed")
	var act: Dictionary = runner.root.get_node("Content").find_action(bed.item_id, "sleep", "girl")
	var diag: Node = runner.root.get_node("Diag")
	for i in 5:
		diag.events.clear()
		room.girl.command({"type": "use", "f": bed, "action": act})
		var t := 0.0
		while room.girl.state != "Sleeping" and t < 40.0:
			await runner.process_frame
			t += runner.root.get_process_delta_time()
		runner.eq(room.girl.state, "Sleeping", "cycle %d asleep" % i)
		runner.check(room.girl.attached_to == bed, "attached to bed")
		runner.check(room.girl.draw_offset.y < -20.0, "lifted onto mattress")
		# wake up via a floor command (soft interrupt)
		var target := Vector2(1400, 950)
		room.girl.command({"type": "walk", "pos": target})
		t = 0.0
		while (room.girl.attached_to != null or room.girl.moving or room.girl.state not in ["Idle", "Observe"]) and t < 40.0:
			await runner.process_frame
			t += runner.root.get_process_delta_time()
		var st := _states("girl")
		for need in ["Approach", "SleepEnter", "Sleeping", "WakeUp", "StandUp"]:
			runner.check(need in st, "cycle %d passed %s" % [i, need])
		runner.check(room.girl.attached_to == null, "detached")
		runner.check(room.nav.is_free(room.girl.position), "ends on free floor")
		runner.check(absf(room.girl.draw_offset.y) < 1.0, "back on the floor")
		runner.eq(room.interactions.holder_key("girl"), "", "slot released")


func test_carry_pet_and_put_down() -> void:
	_make_room()
	Engine.time_scale = 8.0
	var cat: Pet = room.cat
	for i in 3:
		room.girl.command({"type": "pet_cmd", "cmd": "pickup", "pet": cat})
		var t := 0.0
		while room.girl.state != "CarryPet" and t < 40.0:
			await runner.process_frame
			t += runner.root.get_process_delta_time()
		runner.eq(room.girl.state, "CarryPet", "carrying %d" % i)
		runner.check(cat.holder == room.girl, "cat held")
		runner.eq(room.interactions.locked_by("cat"), "girl", "exclusive lock")
		# walk while carrying, then emergency command: use a seat (must put down first)
		var sofa := room.find_furniture_with_profile("sofa")
		room.girl.command({"type": "use", "f": sofa, "action": runner.root.get_node("Content").find_action(sofa.item_id, "sit", "girl")})
		t = 0.0
		while room.girl.state != "Sitting" and t < 60.0:
			await runner.process_frame
			t += runner.root.get_process_delta_time()
		runner.check(cat.holder == null, "cat put down before sitting")
		runner.check(room.nav.is_free(cat.position), "cat on free floor")
		runner.check(room.interactions.locked_by("cat") != "girl", "girl released her hold (pet may start its own play)")
		runner.eq(room.girl.state, "Sitting", "then sits")
		room.girl.command({"type": "walk", "pos": Vector2(2600, 950)})
		t = 0.0
		while room.girl.attached_to != null and t < 20.0:
			await runner.process_frame
			t += runner.root.get_process_delta_time()


func test_moving_furniture_interrupts_user() -> void:
	_make_room()
	Engine.time_scale = 8.0
	var sofa := room.find_furniture_with_profile("sofa")
	room.girl.command({"type": "use", "f": sofa, "action": runner.root.get_node("Content").find_action(sofa.item_id, "sit", "girl")})
	var t := 0.0
	while room.girl.state != "Sitting" and t < 40.0:
		await runner.process_frame
		t += runner.root.get_process_delta_time()
	room.placement.begin(sofa)
	room.placement.drag_to(Vector2(3300, 1000))
	if room.placement.is_valid(sofa):
		room.placement.confirm()
	t = 0.0
	while (room.girl.attached_to != null or room.girl.current_action != "") and t < 20.0:
		await runner.process_frame
		t += runner.root.get_process_delta_time()
	runner.check(room.girl.attached_to == null, "girl got off the moved sofa")
	runner.check(room.nav.is_free(room.girl.position), "girl on free floor")
