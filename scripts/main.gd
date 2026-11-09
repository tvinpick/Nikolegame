extends Node
## Entry point: load progress (or start a new game), build the room and UI,
## route screens, apply offline time safely, autosave on background.

var room: Room
var ui_layer: CanvasLayer
var hud: HUD
var screen: Screen = null
var tutorial: Tutorial = null
var _shot_path := ""


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	var src := Save.load_game()
	var first := src == "new"
	if first:
		Economy.new_game()
	var s: Dictionary = GameState.data["settings"]
	Loc.set_ui_language(s.get("ui_lang", "ru"))
	Loc.set_learn_language(s.get("learn_lang", "ru"))
	AudioSvc.apply_volumes()
	# offline needs: only forward time, capped; rollback never hurts
	var now := int(Time.get_unix_time_from_system())
	var last := int(GameState.data.get("last_seen_unix", 0))
	var elapsed: int = max(0, now - last) if last > 0 else 0
	Economy.note_time_seen(now)
	room = Room.new()
	room.name = "Room"
	add_child(room)
	room.build()
	if elapsed > 0:
		room.apply_offline_time(elapsed)
	room.set_low_detail(bool(s.get("low_detail", false)))
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	hud = HUD.new()
	hud.room = room
	ui_layer.add_child(hud)
	room.ui_blocker = func(p: Vector2) -> bool: return screen != null or hud.is_over_ui(p)
	_connect()
	Save.pre_save = room.store_runtime_state
	Diag.load_times["startup_ms"] = Time.get_ticks_msec() - t0
	Diag.event("startup", {"ms": Diag.load_times["startup_ms"], "save": src})
	AudioSvc.play_music("cozy_room")
	if first or not bool(s.get("onboarding_done", false)):
		_start_onboarding()
	elif not bool(s.get("tutorial_done", false)):
		_start_tutorial()
	Save.save_now()
	_handle_cmdline()


func _connect() -> void:
	hud.open_screen.connect(open_screen)
	room.furniture_tapped.connect(func(f: Furniture, sp: Vector2): hud.show_furniture_actions(f, sp))
	room.pet_tapped.connect(func(p: Pet, sp: Vector2): hud.show_pet(p, sp))
	room.girl_tapped.connect(func(_sp): _girl_tapped())
	room.selection_cleared.connect(hud.hide_context)
	room.floor_tapped.connect(func(_w): hud.hide_context())
	room.message.connect(func(k: String): hud.show_toast(k))
	room.girl_ui_request.connect(_on_girl_ui)
	Economy.reward_granted.connect(func(amount: int, _r): hud.show_toast("msg_reward", [amount]))


func _girl_tapped() -> void:
	hud.hide_context()
	var g := room.girl
	if g.carrying:
		g.command({"type": "pet_cmd", "cmd": "putdown", "pet": g.carrying})
	else:
		g.command({"type": "idle_anim", "pose": "happy", "dur": 1.2})
		AudioSvc.sfx("yay", g.position, -6.0)


func _on_girl_ui(name_: String) -> void:
	match name_:
		"notebook":
			open_screen("notebook")
		"wardrobe":
			open_screen("wardrobe")
		"beauty":
			open_screen("beauty")


func open_screen(name_: String) -> void:
	if screen != null:
		return
	hud.hide_context()
	var sc: Screen = null
	match name_:
		"shop":
			sc = ShopScreen.new()
		"wardrobe", "beauty", "wardrobe_all":
			var ws := WardrobeScreen.new()
			ws.set_mode({"wardrobe": "clothes", "beauty": "beauty"}.get(name_, "all"))
			sc = ws
		"pets":
			sc = PetsScreen.new()
		"weather":
			sc = WeatherScreen.new()
		"chest":
			sc = ChestScreen.new()
		"notebook":
			sc = NotebookScreen.new()
		"parent":
			var gate := ParentScreen.ParentGate.new()
			gate.passed.connect(func(): call_deferred("_open_parent"))
			sc = gate
		"dev":
			if not Diag.dev_allowed():
				return
			sc = DevScreen.new()
	if sc == null:
		return
	_show_screen(sc)


func _open_parent() -> void:
	var p := ParentScreen.new()
	p.open_dev.connect(func(): call_deferred("open_screen", "dev"))
	p.language_changed.connect(_on_language_changed)
	_show_screen(p)


func _show_screen(sc: Screen) -> void:
	sc.room = room
	sc.hud = hud
	screen = sc
	sc.closed.connect(_on_screen_closed)
	ui_layer.add_child(sc)
	Diag.event("screen_open", {"name": sc.screen_name})


func _on_screen_closed(sc: Screen) -> void:
	Diag.event("screen_close", {"name": sc.screen_name})
	if screen == sc:
		screen = null
	match sc.screen_name:
		"notebook":
			room.girl.ui_closed("notebook")
		"wardrobe":
			room.girl.ui_closed("wardrobe")
		"beauty":
			room.girl.ui_closed("beauty")
		"pets":
			if not bool(GameState.setting("onboarding_done", false)):
				GameState.set_setting("onboarding_done", true)
				Save.save_now()
				_start_tutorial()


func _on_language_changed() -> void:
	# rebuild HUD texts by recreating it (simple and safe)
	hud.queue_free()
	hud = HUD.new()
	hud.room = room
	ui_layer.add_child(hud)
	ui_layer.move_child(hud, 0)
	room.ui_blocker = func(p: Vector2) -> bool: return screen != null or hud.is_over_ui(p)
	hud.open_screen.connect(open_screen)
	room.furniture_tapped.connect(func(f: Furniture, sp: Vector2): hud.show_furniture_actions(f, sp))
	room.pet_tapped.connect(func(p: Pet, sp: Vector2): hud.show_pet(p, sp))


func _start_onboarding() -> void:
	var p := PetsScreen.new()
	p.onboarding = true
	p.title_key = "title_welcome"
	_show_screen(p)
	AudioSvc.say("onb_choose_cat")


func _start_tutorial() -> void:
	if tutorial:
		return
	tutorial = Tutorial.new()
	tutorial.room = room
	tutorial.finished.connect(func(): tutorial = null)
	ui_layer.add_child(tutorial)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if screen:
			screen.close()
		elif room and room.mode != "play":
			room.cancel_preview()
			room.set_mode("play")


# ---------------------------------------------------------------- dev/CI helpers

## --shot=<png> [--camx= --camy= --zoom= --delay=] renders a screenshot and quits
## (used by CI smoke tests and visual review; not reachable in normal play).
func _handle_cmdline() -> void:
	var args := OS.get_cmdline_user_args()
	var cx := -1.0
	var cy := 540.0
	var z := -1.0
	var delay := 3.0
	var scenario := ""
	for a in args:
		if a.begins_with("--shot="):
			_shot_path = a.substr(7)
		elif a.begins_with("--camx="):
			cx = float(a.substr(7))
		elif a.begins_with("--camy="):
			cy = float(a.substr(7))
		elif a.begins_with("--zoom="):
			z = float(a.substr(7))
		elif a.begins_with("--delay="):
			delay = float(a.substr(8))
		elif a.begins_with("--scenario="):
			scenario = a.substr(11)
	if _shot_path == "":
		return
	if screen and scenario != "onboarding":
		screen.close()
	if tutorial and scenario != "tutorial":
		tutorial.queue_free()
		tutorial = null
	if cx >= 0.0:
		room.camera.target_pos = Vector2(cx, cy)
		room.camera.position = room.camera.target_pos
	if z > 0.0:
		room.camera.target_zoom = z
	_run_scenario(scenario)
	await get_tree().create_timer(delay).timeout
	get_viewport().get_texture().get_image().save_png(_shot_path)
	get_tree().quit()


## Dev scenarios "heart_<x>" / "heartworn_<x>": swap in the picture heart bed first.
func _swap_bed(item_id: String, worn: bool) -> void:
	var bed := room.find_furniture_with_profile("bed")
	if bed == null:
		return
	var inst: Dictionary = bed.inst
	inst["item_id"] = item_id
	inst["state"] = {"wear": FurniturePainter.WEAR_MAX if worn else 0.0}
	bed.queue_free()
	await get_tree().process_frame
	room._spawn_instance(inst)
	room.rebuild_nav()


func _run_scenario(s: String) -> void:
	if s.begins_with("heart_") or s.begins_with("heartworn_"):
		await _swap_bed("bed_heart", s.begins_with("heartworn_"))
		s = s.substr(s.find("_") + 1)
	elif s.begins_with("bed-"):
		var parts := s.split("-")   # bed-<item_id>-<scenario>
		await _swap_bed(parts[1], false)
		s = parts[2] if parts.size() > 2 else ""
	match s:
		"shop":
			open_screen("shop")
		"shop_pets":
			open_screen("shop")
			(screen as ShopScreen).open_at("pets", "dogs")
		"shop_clothes":
			open_screen("shop")
			(screen as ShopScreen).open_at("clothes", "outfits")
		"shop_item":
			open_screen("shop")
			(screen as ShopScreen)._select("bed_unicorn")
		"shop_buy":
			GameState.data["coins"] = 1000
			open_screen("shop")
			(screen as ShopScreen)._select("bed_rose_princess")
			await get_tree().create_timer(0.5).timeout
			(screen as ShopScreen)._buy_and_place()
		"shop_item_owned":
			GameState.data["coins"] = 1000
			open_screen("shop")
			(screen as ShopScreen)._select("bed_wood_green")
		"wardrobe":
			open_screen("wardrobe")
		"beauty":
			open_screen("beauty")
		"notebook":
			open_screen("notebook")
		"notebook_ex":
			open_screen("notebook")
			(screen as NotebookScreen)._start("math")
		"pets":
			open_screen("pets")
		"weather_night":
			room.clock.set_manual("winter", "night", "snow")
		"weather_rain":
			room.clock.set_manual("spring", "evening", "rain")
		"sleep":
			var bed := room.find_furniture_with_profile("bed")
			room.girl.command({"type": "use", "f": bed, "action": Content.find_action(bed.item_id, "sleep", "girl")})
		"pethouse":
			var ch := room.find_furniture_with_profile("pet_house")
			for f in room.furniture_nodes():
				if f.item_id == "cathouse_wood":
					ch = f
			room.cat.use_furniture(ch, Content.find_action(ch.item_id, "sleep", "cat"), false)
			var dh: Furniture = null
			for f in room.furniture_nodes():
				if f.item_id == "doghouse_lilac":
					dh = f
			if dh:
				room.dog.use_furniture(dh, Content.find_action(dh.item_id, "sleep", "dog"), false)
		"wash":
			var bt := room.find_furniture_with_profile("bath")
			room.girl.command({"type": "use", "f": bt, "action": Content.find_action(bt.item_id, "wash", "girl"), "pet": room.dog})
		"chair":
			var chf: Furniture = null
			for f in room.furniture_nodes():
				if f.item_id == "chair_daisy":
					chf = f
			room.girl.command({"type": "use", "f": chf, "action": Content.find_action(chf.item_id, "sit", "girl")})
		"petsleep":
			for pt in [room.cat, room.dog]:
				pt.set_physics_process(false)
				pt.set_process(true)
			room.cat.position = Vector2(2500, 900)
			room.dog.position = Vector2(2350, 1000)
			room.cat.brain_timer = 999.0
			room.dog.brain_timer = 999.0
			room.cat.set_pose("curl", 0.0)
			room.dog.set_pose("curl", 0.0)
		"repair":
			var rb := room.find_furniture_with_profile("bed")
			room.girl.command({"type": "use", "f": rb, "action": Content.find_action(rb.item_id, "repair", "girl")})
		"bedsit":
			var sb := room.find_furniture_with_profile("bed")
			room.girl.command({"type": "use", "f": sb, "action": Content.find_action(sb.item_id, "sit", "girl")})
		"sit":
			var sofa := room.find_furniture_with_profile("sofa")
			room.girl.command({"type": "use", "f": sofa, "action": Content.find_action(sofa.item_id, "read", "girl")})
		"desk":
			var desk := room.find_furniture_with_profile("desk")
			room.girl.command({"type": "use", "f": desk, "action": Content.find_action(desk.item_id, "draw", "girl")})
		"carry":
			room.girl.command({"type": "pet_cmd", "cmd": "pickup", "pet": room.cat})
		"carry_walk":
			room.girl.command({"type": "pet_cmd", "cmd": "pickup", "pet": room.cat})
			await get_tree().create_timer(6.0).timeout
			room.girl.command({"type": "walk", "pos": Vector2(room.girl.position.x + 40, 1050)})
		"eat":
			var tb := room.find_furniture_with_profile("dining")
			room.girl.command({"type": "use", "f": tb, "action": Content.find_action(tb.item_id, "eat", "girl")})
		"walk_down":
			room.girl.position = Vector2(2600, 660)
			room.cat.position = Vector2(2450, 660)
			room.dog.position = Vector2(2750, 1050)
			room.girl.command({"type": "walk", "pos": Vector2(2620, 1050)})
			room.cat.go_to(Vector2(2470, 1050))
			room.dog.go_to(Vector2(2760, 660))
		"rearrange":
			hud.enter_rearrange()
			room.placement.begin(room.find_furniture_with_profile("sofa"))
		"beauty_screen":
			open_screen("beauty")
		"outfits":
			open_screen("wardrobe")
		"dressed":
			var ap: Dictionary = GameState.appearance()
			ap["outfit"] = "dress_flower"
			ap["hair_style"] = "pigtails"
			ap["hat"] = "flower_clip"
			ap["earrings"] = "earrings_heart"
			ap["makeup"] = "blush_pink"
			ap["accessory"] = "purse_heart"
			ap["shoes"] = "sandals_mint"
			room.girl.apply_appearance(ap)
			var sofa2 := room.find_furniture_with_profile("sofa")
			room.girl.command({"type": "use", "f": sofa2, "action": Content.find_action(sofa2.item_id, "sit", "girl")})
		"lie_sofa":
			var sofa3 := room.find_furniture_with_profile("sofa")
			room.girl.command({"type": "use", "f": sofa3, "action": Content.find_action(sofa3.item_id, "lie", "girl")})
		"dev":
			GameState.set_setting("dev_mode", true)
			Diag.set_overlay(true)
		"pet_panel":
			hud.show_pet(room.dog, room.world_to_screen(room.dog.position))
		"context":
			var sf := room.find_furniture_with_profile("bed")
			hud.show_furniture_actions(sf, room.world_to_screen(sf.visual_rect().get_center()))
