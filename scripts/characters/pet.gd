class_name Pet
extends Actor
## Cat or dog. Four needs (satiety, energy, mood, cleanliness) shown only when
## the child taps the pet. Pets never get sick, leave or die; when needs are
## low they only look a little sad. The child serves food/water; pets eat on
## their own once a bowl is filled.

signal hold_state_changed(pet: Pet, held: bool)

const NEEDS := ["satiety", "energy", "mood", "cleanliness"]

var species := "cat"
var breed: Dictionary = {}
var breed_id := ""
var needs := {"satiety": 80.0, "energy": 80.0, "mood": 80.0, "cleanliness": 80.0}
var accessory: Dictionary = {}
var run_id := 0
var current := ""                 # current activity id
var brain_timer := 2.0
var holder: Node = null
var hold_requested_by: Node = null
var hold_ready := false
var care_ready := false
var care_target: Furniture = null
var anim_t := 0.0
var wet := 0.0
var toy: Node = null              # carried toy (dog mouth)
var _poses: Dictionary = {}
var _sound_t := 0.0
var _last_step := 0.0
var social_partner: Pet = null
var interrupt := false


func setup_pet(sp: String, bid: String) -> void:
	species = sp
	kind = sp
	actor_id = sp
	set_breed(bid)


func set_breed(bid: String) -> void:
	if not Content.breeds.has(bid):
		bid = Content.breeds_of(species)[0]["breed_id"]
	breed_id = bid
	breed = Content.breeds[bid]
	_poses = _build_poses()
	var leg := float(breed["leg_len"])
	speed = (115.0 if species == "cat" else 135.0) + leg * 0.8
	run_speed = speed * 2.2
	pose = _poses["stand"].duplicate()
	set_pose("stand", 0.01)
	queue_redraw()


func set_accessory(item_id: String) -> void:
	accessory = Content.item(item_id) if item_id != "none" and Content.has_item(item_id) else {}


func size_class() -> int:
	return int(breed.get("size_class", 1))


func poses() -> Dictionary:
	return _poses if not _poses.is_empty() else {"stand": {}}


func _build_poses() -> Dictionary:
	var leg := float(breed["leg_len"])
	var H := float(breed["body_h"])
	var L := float(breed["body_len"])
	var stand_y := leg + H * 0.35
	var base := {"body_x": 0.0, "body_y": stand_y, "tilt": 0.0, "head_dx": L * 0.16, "head_dy": -H * 0.75, "head_tilt": 0.0, "front_mode": "stand", "back_mode": "stand", "tail_a": -0.9 if species == "cat" else -1.3, "wag": 0.0, "ears_back": 0.0, "eyes": "open", "mouth_open": 0.0, "tongue": 0.0, "curl": 0.0, "paw_anim": 0.0}
	var P := {}
	P["stand"] = base.duplicate()
	var sit := base.duplicate()
	sit.merge({"body_y": stand_y * 0.72, "tilt": 0.55, "body_x": -L * 0.12, "back_mode": "fold", "head_dy": -H * 0.85, "tail_a": 0.7}, true)
	P["sit"] = sit
	var lie := base.duplicate()
	lie.merge({"body_y": H * 0.5, "tilt": 0.05, "front_mode": "tuck", "back_mode": "fold", "head_dy": -H * 0.55, "tail_a": 0.05}, true)
	P["lie"] = lie
	var curl := lie.duplicate()
	curl.merge({"curl": 1.0, "eyes": "closed", "body_y": H * 0.45}, true)
	P["curl"] = curl
	var beg := sit.duplicate()
	beg.merge({"head_tilt": -0.3, "head_dy": -H * 1.0, "front_mode": "paw", "paw_anim": 1.2, "eyes": "open", "wag": 1.0, "mouth_open": 0.3}, true)
	P["beg"] = beg
	var beg_up := sit.duplicate()
	beg_up.merge({"head_tilt": -0.5, "head_dy": -H * 1.15, "eyes": "happy", "wag": 1.0, "mouth_open": 0.8, "tongue": 1.0}, true)
	P["beg_up"] = beg_up
	var eat := base.duplicate()
	eat.merge({"tilt": -0.12, "head_dx": L * 0.3, "head_dy": H * 0.35, "head_tilt": 0.35, "front_mode": "reach"}, true)
	P["eat"] = eat
	var stretch := base.duplicate()
	stretch.merge({"tilt": -0.32, "body_y": stand_y * 0.85, "front_mode": "reach", "head_dy": -H * 0.4, "eyes": "closed", "mouth_open": 0.8}, true)
	P["stretch"] = stretch
	var held := base.duplicate()
	# cradled in the arms: body almost level, head up, paws relaxed
	held.merge({"tilt": 0.28, "front_mode": "dangle", "back_mode": "tuck", "body_y": stand_y * 0.8, "head_dx": L * 0.12, "head_dy": -H * 0.85, "head_tilt": -0.15, "tail_a": 0.4, "eyes": "happy", "wag": 0.6}, true)
	P["held"] = held
	var scratch := base.duplicate()
	scratch.merge({"tilt": 1.05, "body_y": stand_y * 1.15, "front_mode": "up", "back_mode": "stand", "head_dy": -H * 0.5, "ears_back": 0.4}, true)
	P["scratch"] = scratch
	var groom := sit.duplicate()
	groom.merge({"front_mode": "paw", "head_tilt": 0.45, "eyes": "closed", "paw_anim": 0.01}, true)
	P["groom"] = groom
	var crouch := base.duplicate()
	crouch.merge({"body_y": stand_y * 0.6, "front_mode": "tuck", "back_mode": "fold", "tilt": -0.05, "head_dy": -H * 0.45, "ears_back": 0.2}, true)
	P["crouch"] = crouch
	P["pounce"] = crouch.duplicate()
	var bath := sit.duplicate()
	bath.merge({"eyes": "closed", "ears_back": 0.8, "mouth_open": 0.0}, true)
	P["bath"] = bath
	var sniff := base.duplicate()
	sniff.merge({"head_dx": L * 0.3, "head_dy": H * 0.1, "head_tilt": 0.25, "tilt": -0.06}, true)
	P["sniff"] = sniff
	var happy := base.duplicate()
	happy.merge({"wag": 1.0, "mouth_open": 1.0, "tongue": 1.0 if species == "dog" else 0.0, "eyes": "happy"}, true)
	P["happy"] = happy
	var bow := base.duplicate()
	bow.merge({"tilt": -0.38, "front_mode": "tuck", "body_y": stand_y * 0.8, "wag": 1.0, "mouth_open": 1.0, "tongue": 1.0 if species == "dog" else 0.0}, true)
	P["play_bow"] = bow
	var walk := base.duplicate()
	P["walk"] = walk
	for k in P.keys():
		P[k]["spr"] = k   # picture pets pick their frame by pose name
	return P


# ---------------------------------------------------------------- needs

func apply_needs_delta(delta_min: float) -> void:
	var cfg: Dictionary = Content.econ("needs", {})
	var decay: Dictionary = cfg.get("decay_per_min", {})
	for n in NEEDS:
		var d := -float(decay.get(n, 0.5)) * delta_min
		if n == "energy" and current == "sleep":
			d = float(cfg.get("sleep_energy_per_min", 6.0)) * delta_min
		needs[n] = clampf(needs[n] + d, 0.0, 100.0)


func apply_effects(eff: Dictionary, frac := 1.0) -> void:
	for k in eff.keys():
		if needs.has(k):
			needs[k] = clampf(needs[k] + float(eff[k]) * frac, 0.0, 100.0)
	Diag.event("pet_needs", {"pet": actor_id, "needs": needs.duplicate()})


func is_sad() -> bool:
	var th := float(Content.econ("needs", {}).get("sad_threshold", 30.0))
	for n in NEEDS:
		if needs[n] < th:
			return true
	return false


func lowest_need() -> String:
	var best := "mood"
	for n in NEEDS:
		if needs[n] < needs[best]:
			best = n
	return best


# ---------------------------------------------------------------- availability

func in_closed_house() -> bool:
	return attached_to != null and current == "sleep" and attached_to.def.get("interaction_profile", "") == "pet_house"


func can_join() -> bool:
	return holder == null and not in_closed_house() and busy_lock == "" and current not in ["held", "care", "social"]


func can_be_held() -> bool:
	return holder == null and not in_closed_house() and current not in ["care", "social"]


# ---------------------------------------------------------------- control

func _new_run() -> int:
	run_id += 1
	interrupt = false
	return run_id


func wait(sec: float) -> void:
	await get_tree().create_timer(sec, false).timeout


var _walk_token := 0
var _walk_arrived := -1


func walk_to(p: Vector2, run := false) -> bool:
	_walk_token += 1
	var tok := _walk_token
	if not go_to(p, _on_arrive_tok.bind(tok), run):
		return false
	var my := run_id
	var guard := 0.0
	while _walk_arrived != tok and moving and my == run_id and guard < 25.0:
		await get_tree().process_frame
		guard += get_process_delta_time()
	return _walk_arrived == tok and my == run_id


func _on_arrive_tok(tok: int) -> void:
	_walk_arrived = tok


## Soft stop: finish current pose transition, leave furniture, stand.
func _soft_release() -> void:
	stop_moving()
	if attached_to != null:
		var f := attached_to
		var ap: Vector2 = room.best_approach(self, f, position)
		room.interactions.release_actor(actor_id)
		f.anim["occupied"] = room.interactions.occupants(f).size() > 0
		set_pose("stand", 0.4)
		detach_to(ap, 0.5, Callable(), 30.0 if float(draw_offset.y) < -20.0 else 0.0)
		await wait(0.52)
	else:
		room.interactions.release_actor(actor_id)
	hidden_frac = 0.0
	set_pose("stand", 0.3)


func request_hold(by: Node) -> void:
	hold_requested_by = by
	hold_ready = false
	var my := _new_run()
	current = "wait_pickup"
	set_state("WaitPickup")
	await _soft_release()
	if my != run_id:
		return
	if toy and is_instance_valid(toy):
		toy.release(position + Vector2(facing * 20.0, 0), Vector2.ZERO, 0.0)
		toy = null
	set_pose("sit", 0.4)
	face_toward_x(by.position.x)
	hold_ready = true


func cancel_hold() -> void:
	hold_requested_by = null
	hold_ready = false
	current = ""
	_go_idle()


var in_arms := false      # true once settled in the girl's arms (she draws us then)
var _hold_t := 0.0
var _hold_start := Vector2.ZERO


func attach_to_hands(by: Node) -> void:
	holder = by
	current = "held"
	_new_run()
	set_state("Held")
	set_pose("held", 0.45)
	stop_moving()
	in_arms = false
	_hold_start = ground_point()
	_hold_t = 0.0
	# glide from the floor up into the arms along a soft arc (no teleport)
	var tw := create_tween()
	tw.tween_property(self, "_hold_t", 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): in_arms = holder != null)
	AudioSvc.sfx("purr" if species == "cat" else "bark", position, -10.0)
	hold_state_changed.emit(self, true)
	mood_boost(4.0)


## World point where our ground point must be so that our body rests in her hands.
func _arms_ground(by: Node) -> Vector2:
	var hand: Vector2 = by.hold_anchor()
	var k := float(breed.get("scale", 1.0)) * scale.y
	var body_y := float(pose.get("body_y", 40.0))
	return hand + Vector2(by.facing * float(breed.get("body_len", 80)) * 0.08 * k, body_y * k * 0.95)


func follow_hands(by: Node) -> void:
	if holder != by:
		return
	var target := _arms_ground(by)
	var g := _hold_start.lerp(target, _hold_t) + Vector2(0, -sin(_hold_t * PI) * 30.0)
	position = Vector2(g.x, by.position.y + 2.0)
	draw_offset = g - position
	facing = by.facing


func put_down_at(spot: Vector2) -> void:
	var by := holder
	if by and is_instance_valid(by):
		var g := _arms_ground(by)
		position = Vector2(g.x, by.position.y + 2.0)
		draw_offset = g - position
	in_arms = false
	holder = null
	hold_requested_by = null
	hold_ready = false
	set_pose("stand", 0.4)
	attached_to = null
	detach_to(spot, 0.45)
	await wait(0.47)
	current = ""
	hold_state_changed.emit(self, false)
	Diag.event("put_down", {"pet": actor_id, "at": [int(spot.x), int(spot.y)]})
	_go_idle()
	brain_timer = 2.5


func react_petted() -> void:
	show_emote("heart", 2.0)
	mood_boost(15.0)
	set_pose("happy", 0.3)
	AudioSvc.sfx("purr" if species == "cat" else "bark", position, -6.0)


func mood_boost(v: float) -> void:
	needs["mood"] = clampf(needs["mood"] + v, 0.0, 100.0)


## Girl wants to pet us: stop, sit, look at her.
func wait_for_girl(by: Node) -> void:
	var my := _new_run()
	current = "care"
	set_state("Care")
	await _soft_release()
	if my != run_id:
		return
	face_toward_x(by.position.x)
	set_pose("sit", 0.4)


## Bath / brush / teaser: go to the furniture's pet anchor.
func join_care(f: Furniture, pet_anchor: Dictionary, care_pose: String, by: Node) -> void:
	var my := _new_run()
	current = "care"
	care_ready = false
	care_target = f
	set_state("Care")
	await _soft_release()
	if my != run_id:
		return
	var floor_pt: Vector2 = pet_anchor["pos"]
	var lift := float(pet_anchor["lift"])
	var target := floor_pt if lift < 1.0 else room.best_approach(self, f, floor_pt)
	var ok := await walk_to(target)
	if my != run_id:
		return
	if not ok:
		return
	if lift >= 1.0:
		set_pose("crouch", 0.3)
		await wait(0.3)
		attach(f, pet_anchor, "pet", 0.5, Callable(), 40.0)
		await wait(0.5)
	face_toward_x(by.position.x)
	set_pose(care_pose if poses().has(care_pose) else "sit", 0.4)
	if care_pose == "bath":
		wet = 1.0
	care_ready = true


func end_care() -> void:
	var my := _new_run()
	if attached_to == null:
		draw_offset = Vector2.ZERO
	care_ready = false
	care_target = null
	if attached_to != null:
		await _soft_release()
	if my != run_id:
		return
	if wet > 0.0:
		set_pose("stand", 0.2)
		await wait(0.3)
	current = ""
	_go_idle()
	brain_timer = 1.5


## Chase a moving toy (ball). Dogs bring it back to the girl.
func chase_toy(t: Node, fetch := false) -> void:
	if not can_join() and current != "play":
		return
	var my := _new_run()
	current = "play"
	set_state("Play")
	await _soft_release()
	if my != run_id:
		return
	set_pose("happy", 0.3)
	var tries := 0
	while my == run_id and is_instance_valid(t) and tries < 6:
		tries += 1
		await wait(0.25 if tries == 1 else 0.1)
		if not is_instance_valid(t):
			break
		var target: Vector2 = t.floor_pos + (t.velocity * 0.35 if t.velocity.length() > 30.0 else Vector2.ZERO)
		var ok := await walk_to(room.nav.nearest_free(target), true)
		if my != run_id:
			return
		if is_instance_valid(t) and position.distance_to(t.floor_pos) < 60.0:
			face_toward_x(t.floor_pos.x)
			if species == "dog" and fetch and t.holder == null:
				set_pose("eat", 0.2)
				await wait(0.25)
				t.hold_by(self)
				toy = t
				set_pose("happy", 0.3)
				var girl: Node = room.girl
				var ok2 := await walk_to(room.nav.nearest_free(girl.position + Vector2(-girl.facing * -60.0, 10.0)))
				if my != run_id:
					return
				face_toward_x(girl.position.x)
				set_pose("sit", 0.3)
				await wait(0.3)
				if toy and is_instance_valid(toy):
					toy.release(position + Vector2(facing * 30.0, 2.0), Vector2(facing * 40.0, 0), 0.0)
				toy = null
				AudioSvc.sfx("bark", position, -6.0)
				break
			else:
				# cat: paw it away playfully
				set_pose("pounce", 0.15)
				await wait(0.18)
				t.kick(Vector2(facing * randf_range(220.0, 420.0), randf_range(-80.0, 80.0)), 60.0)
				AudioSvc.sfx("ball_bounce", position, -6.0)
				set_pose("happy", 0.2)
				if randf() < 0.5:
					break
		if not ok:
			break
	if my != run_id:
		return
	apply_effects({"mood": 14.0, "energy": -3.0})
	current = ""
	_go_idle()


func come_to(target: Node) -> void:
	if not can_join():
		return
	var my := _new_run()
	current = "come"
	set_state("Come")
	await _soft_release()
	if my != run_id:
		return
	var ok := await walk_to(room.nav.nearest_free(target.position + Vector2(target.facing * 70.0, 12.0)))
	if my != run_id:
		return
	face_toward_x(target.position.x)
	set_pose("happy" if species == "dog" else "sit", 0.35)
	if ok:
		AudioSvc.sfx("meow" if species == "cat" else "bark", position, -6.0)
	await wait(2.0)
	if my != run_id:
		return
	current = ""
	_go_idle()


## Use a furniture action from the interaction profile (player "go to" or AI).
func use_furniture(f: Furniture, action: Dictionary, auto := true) -> bool:
	if f == null or action.is_empty():
		return false
	var max_sz := int(action.get("max_size", f.def.get("max_size", 9)))
	if size_class() > max_sz:
		Diag.event("pet_too_big", {"pet": actor_id, "item": f.item_id})
		return false
	if action.has("requires_content") and f.content(action["requires_content"]) <= 0:
		return false
	if holder != null or current == "care":
		return false
	var slot: int = room.interactions.reserve_slot(f, action["anchor"], actor_id)
	if slot < 0:
		return false
	var my := _new_run()
	current = action["id"]
	_run_furniture(f, action, slot, my)
	return true


func _run_furniture(f: Furniture, a: Dictionary, slot: int, my: int) -> void:
	var anc := f.anchor(a["anchor"], slot)
	var lift := float(anc["lift"])
	var target: Vector2 = anc["pos"] if lift < 1.0 else room.best_approach(self, f, anc["pos"])
	set_state("Approach")
	var ok := await walk_to(target, needs["energy"] > 60.0 and randf() < 0.3)
	if my != run_id:
		return
	if not ok or not is_instance_valid(f):
		room.interactions.release_actor(actor_id)
		current = ""
		_go_idle()
		return
	var enclosed: bool = a.get("enclosed", false)
	if a.has("traverse_to"):
		# tunnel: enter one side, come out the other
		set_state("Tunnel")
		face_toward_x(f.position.x)
		set_pose("crouch", 0.25)
		await wait(0.25)
		hidden_frac = 0.85
		var exit_pt: Vector2 = f.anchor(a["traverse_to"])["pos"]
		var start := position
		var tw := create_tween()
		tw.tween_property(self, "position", exit_pt, 1.0).from(start)
		travel = 0.0
		await wait(1.0)
		hidden_frac = 0.0
		room.interactions.release_actor(actor_id)
		apply_effects(a.get("effects", {}))
		set_pose("happy", 0.3)
		await wait(0.6)
		if my == run_id:
			current = ""
			_go_idle()
		return
	if lift >= 1.0 or enclosed:
		set_state("JumpUp" if lift >= 1.0 else "EnterHouse")
		face_toward_x(anc["pos"].x)
		set_pose("crouch", 0.3)
		await wait(0.3)
		attach(f, anc, a["anchor"], 0.55 if lift >= 1.0 else 0.7, Callable(), 46.0 if lift >= 1.0 else 0.0)
		if lift >= 1.0:
			set_pose("stand", 0.4)
		await wait(0.6)
		if enclosed:
			hidden_frac = float(anc.get("hidden", 0.6))
			facing = -facing  # turn around inside
		f.anim["occupied"] = true
	else:
		face_toward_x(f.position.x if a.get("anchor") != "cat_watch" else position.x)
		if a["id"] in ["watch"]:
			facing = 1.0
	if my != run_id:
		return
	var pose_id: String = a.get("pose", "sit")
	set_state({"curl": "Sleep", "lie": "Rest", "eat": "Eat", "scratch": "Scratch", "sit": "Watch"}.get(pose_id, "UseObject"))
	set_pose(pose_id, 0.6)
	if pose_id == "eat":
		AudioSvc.sfx("eat" if a["id"] == "eat" else "lap", position, -6.0)
	var dur := 6.0
	if a.has("loop_sec"):
		dur = randf_range(float(a["loop_sec"][0]), float(a["loop_sec"][1]))
	if pose_id == "curl":
		current = "sleep"
	var t := 0.0
	var consumed := false
	while t < dur and my == run_id and not interrupt and is_instance_valid(f):
		await get_tree().process_frame
		var dt := get_process_delta_time()
		t += dt
		var eff: Dictionary = a.get("effects", {})
		for k in eff.keys():
			if k != "energy" or pose_id != "curl":
				needs[k] = clampf(needs[k] + float(eff[k]) * dt, 0.0, 100.0)
		if pose_id == "curl" and needs["energy"] >= 99.0 and t > 8.0:
			break
		if a.has("consumes") and not consumed and t > dur * 0.5:
			consumed = true
			f.set_content(a["requires_content"], f.content(a["requires_content"]) - int(a["consumes"]))
			if f.content("treat") > 0 and a["requires_content"] == "food":
				f.set_content("treat", f.content("treat") - 1)
				mood_boost(10.0)
	if my != run_id:
		return
	if a.get("id", "") == "rest" and is_instance_valid(f):
		f.add_wear(0.5)   # paws on the blanket
	# exit
	if lift >= 1.0 or enclosed:
		set_state("JumpDown" if lift >= 1.0 else "ExitHouse")
		if pose_id == "curl":
			set_pose("stretch", 0.6)
			await wait(0.8)
		var ap: Vector2 = room.best_approach(self, f, anc["pos"])
		set_pose("stand", 0.3)
		room.interactions.release_actor(actor_id)
		f.anim["occupied"] = room.interactions.occupants(f).size() > 0
		hidden_frac = 0.0
		detach_to(ap, 0.55, Callable(), 36.0 if lift >= 1.0 else 0.0)
		await wait(0.57)
	else:
		room.interactions.release_actor(actor_id)
		if pose_id == "curl":
			set_pose("stretch", 0.6)
			await wait(0.8)
	if my != run_id:
		return
	current = ""
	_go_idle()


func _go_idle() -> void:
	if holder != null:
		return
	set_state("Idle")
	set_pose("stand", 0.4)


# ---------------------------------------------------------------- autonomous brain

func _brain(delta: float) -> void:
	if current != "" or moving or attached_to != null or holder != null or busy_lock != "" or is_attach_tweening():
		return
	brain_timer -= delta
	if brain_timer > 0.0:
		return
	brain_timer = randf_range(2.5, 6.0)
	var my := _new_run()
	# needs-driven intents first
	if needs["energy"] < 35.0 and _try_profile_action(["sleep", "rest"]):
		return
	if needs["satiety"] < 60.0 and _try_profile_action(["eat", "drink"], true):
		return
	if _react_to_girl(my):
		return
	var r := randf()
	if r < 0.07:
		_zoomies(my)
		return
	if r < 0.11 and room.clock.weather in ["rain", "snow"] and _try_profile_action(["watch"]):
		return
	if species == "dog" and r < 0.16 and needs["energy"] > 45.0 and _offer_ball(my):
		return
	if species == "cat":
		if r < 0.12 and _try_profile_action(["scratch"]):
			return
		if r < 0.2 and _try_profile_action(["run_through", "watch"]):
			return
		if r < 0.3:
			_do_idle_anim("groom", 3.0, my)
			return
	else:
		if r < 0.15:
			_do_sniff(my)
			return
		if r < 0.22 and _try_profile_action(["run_through"]):
			return
	if r < 0.36 and needs["energy"] > 40.0:
		var ball: Node = room.nearest_toy(position, "ball")
		if ball and ball.holder == null and position.distance_to(ball.floor_pos) < 900.0:
			chase_toy(ball, false)
			return
	if r < 0.48 and room.try_social(self):
		return
	if r < 0.56 and needs["energy"] < 70.0 and _try_profile_action(["rest", "sleep"]):
		return
	if r < 0.66:
		_do_idle_anim(["sit", "lie", "stretch"][randi() % 3], randf_range(3.0, 7.0), my)
		return
	_wander(my)


# ---------------------------------------------------------------- life with the girl

var emote := ""
var emote_t := 0.0


func show_emote(kind_: String, dur := 1.6) -> void:
	emote = kind_
	emote_t = dur


## Pets notice what the girl is doing and join in, like real pets do.
func _react_to_girl(my: int) -> bool:
	var g: Girl = room.girl
	if g == null or randf() > 0.55:
		return false
	match g.state:
		"Sleeping", "Resting":
			# curl up on the same bed / sofa (or beside it)
			if g.attached_to and needs["energy"] < 85.0:
				for c in room.furniture_actions_for_pet(self, ["rest"]):
					if c["f"] == g.attached_to and use_furniture(c["f"], c["action"]):
						show_emote("zzz", 2.0)
						return true
		"Sitting":
			if species == "cat" and g.attached_to and randf() < 0.6:
				for c2 in room.furniture_actions_for_pet(self, ["rest"]):
					if c2["f"] == g.attached_to and use_furniture(c2["f"], c2["action"]):
						show_emote("heart")
						return true
		"Eat":
			_beg(my, g)
			return true
		"Idle", "Observe":
			if position.distance_to(g.position) < 1300.0 and randf() < 0.2:
				_greet(my, g)
				return true
	return false


func _greet(my: int, g: Node) -> void:
	current = "greet"
	set_state("Greet")
	var side := -1.0 if g.position.x > position.x else 1.0
	var ok := await walk_to(room.nav.nearest_free(g.position + Vector2(side * 75.0, 8.0)))
	if my != run_id:
		return
	face_toward_x(g.position.x)
	if ok:
		show_emote("heart")
		if species == "cat":
			# rubs against her legs, purring
			AudioSvc.sfx("purr", position, -8.0)
			set_pose("happy", 0.3)
			var t := 0.0
			while t < 2.4 and my == run_id:
				pose["tilt"] = sin(t * 5.0) * 0.12
				position.x += sin(t * 5.0) * 0.6
				await get_tree().process_frame
				t += get_process_delta_time()
		else:
			AudioSvc.sfx("bark", position, -8.0)
			set_pose("happy", 0.2)
			for k in 3:  # happy little hops
				var tw := create_tween()
				tw.tween_property(self, "draw_offset:y", -26.0, 0.16).set_ease(Tween.EASE_OUT)
				tw.tween_property(self, "draw_offset:y", 0.0, 0.16).set_ease(Tween.EASE_IN)
				await wait(0.36)
				if my != run_id:
					return
			draw_offset = Vector2.ZERO
		mood_boost(5.0)
	if my != run_id:
		return
	current = ""
	_go_idle()


func _beg(my: int, g: Node) -> void:
	current = "beg"
	_got_treat = false
	set_state("Beg")
	var f: Furniture = g.attached_to if g.attached_to is Furniture else null
	var spot: Vector2
	if f != null and f.def.has("sprite_front"):
		# sit right beside the table, looking up at her plate
		var best := INF
		for side in [-1.0, 1.0]:
			var cand: Vector2 = f.position + Vector2(side * (f.size().x * 0.5 + 60.0), 30.0)
			var cost: float = position.distance_to(cand) + (0.0 if room.nav.is_free(cand) else 2000.0)
			if cost < best:
				best = cost
				spot = room.nav.nearest_free(cand)
	else:
		var side2 := 1.0 if position.x > g.position.x else -1.0
		spot = room.nav.nearest_free(g.position + Vector2(side2 * 90.0, 30.0))
	var ok := await walk_to(spot)
	if my != run_id:
		return
	face_toward_x(g.position.x)
	set_pose("beg", 0.35)
	if ok:
		show_emote("food", 2.5)
		AudioSvc.sfx("meow" if species == "cat" else "bark", position, -10.0)
	var t := 0.0
	while t < 10.0 and my == run_id and not _got_treat:
		await get_tree().process_frame
		t += get_process_delta_time()
		if fmod(t, 3.0) < get_process_delta_time() and t > 1.0:
			show_emote("food", 1.6)
	if my != run_id:
		return
	if _got_treat:
		# munch the bite, say thank you, then trot off about its own business
		await wait(0.9)
		set_pose("eat", 0.25)
		AudioSvc.sfx("eat", position, -8.0)
		await wait(1.3)
		if my != run_id:
			return
		set_pose("stand", 0.3)
		show_emote("heart", 1.8)
		await wait(0.6)
		current = ""
		brain_timer = randf_range(10.0, 16.0)  # don't come straight back
		_wander(my)
		return
	current = ""
	_go_idle()


var _got_treat := false


## The girl hands down a bite from her plate.
func receive_treat(_by: Node, amount: float) -> void:
	_got_treat = true
	needs["satiety"] = clampf(needs["satiety"] + 8.0 * amount * 2.0, 0.0, 100.0)
	mood_boost(8.0)
	set_pose("beg_up", 0.25)


## Dog brings the ball and drops it at the girl's feet: "play with me!"
func _offer_ball(my: int) -> bool:
	var ball: Node = room.nearest_toy(position, "ball")
	if ball == null or ball.holder != null or room.girl.attached_to != null:
		return false
	current = "offer"
	set_state("OfferBall")
	_do_offer(ball, my)
	return true


func _do_offer(ball: Node, my: int) -> void:
	var ok := await walk_to(room.nav.nearest_free(ball.floor_pos), true)
	if my != run_id or not ok or not is_instance_valid(ball) or ball.holder != null:
		if my == run_id:
			current = ""
			_go_idle()
		return
	set_pose("eat", 0.2)
	await wait(0.25)
	ball.hold_by(self)
	toy = ball
	set_pose("happy", 0.3)
	var g: Node = room.girl
	await walk_to(room.nav.nearest_free(g.position + Vector2(g.facing * 70.0, 14.0)))
	if my != run_id:
		return
	face_toward_x(g.position.x)
	set_pose("play_bow", 0.3)
	if toy and is_instance_valid(toy):
		toy.release(position + Vector2(facing * 26.0, 2.0), Vector2(facing * 30.0, 0), 0.0)
	toy = null
	show_emote("exclaim")
	AudioSvc.sfx("bark", position, -6.0)
	room.ball_offered_by = self
	room.ball_offered_t = Time.get_ticks_msec()
	await wait(2.5)
	if my != run_id:
		return
	current = ""
	_go_idle()


## Burst of energy: a few fast laps around the room.
func _zoomies(my: int) -> void:
	if needs["energy"] < 55.0:
		_wander(my)
		return
	current = "zoomies"
	set_state("Zoomies")
	show_emote("exclaim", 1.0)
	for k in 3:
		await walk_to(room.random_free_point_near(position, 700.0), true)
		if my != run_id:
			return
	set_pose("play_bow" if species == "dog" else "stretch", 0.3)
	await wait(1.0)
	if my != run_id:
		return
	apply_effects({"mood": 6.0, "energy": -4.0})
	current = ""
	_go_idle()


## Player command: a trick (dog: sit + roll over; cat: high-five + spin).
func do_trick(by: Node) -> void:
	if not can_join():
		return
	var my := _new_run()
	current = "trick"
	set_state("Trick")
	await _soft_release()
	if my != run_id:
		return
	face_toward_x(by.position.x)
	if species == "dog":
		set_pose("sit", 0.3)
		await wait(0.5)
		set_pose("lie", 0.3)
		await wait(0.35)
		# roll over: spin the whole body once
		var tw := create_tween()
		tw.tween_method(func(a: float): rotation = a, 0.0, TAU * facing, 0.7)
		await wait(0.72)
		rotation = 0.0
		set_pose("happy", 0.3)
		AudioSvc.sfx("bark", position, -6.0)
	else:
		set_pose("sit", 0.3)
		await wait(0.4)
		pose["front_mode"] = "up"
		pose["paw_anim"] = 1.0
		AudioSvc.sfx("meow", position, -6.0)
		await wait(0.7)
		var tw2 := create_tween()
		tw2.tween_property(self, "draw_offset:y", -30.0, 0.2)
		tw2.tween_callback(func(): facing = -facing)
		tw2.tween_property(self, "draw_offset:y", 0.0, 0.2)
		await wait(0.45)
		set_pose("happy", 0.3)
	show_emote("star")
	apply_effects({"mood": 10.0, "energy": -2.0})
	await wait(1.0)
	if my != run_id:
		return
	current = ""
	_go_idle()


func _draw_emote(o: Vector2) -> void:
	if emote_t <= 0.0:
		return
	var k := clampf(emote_t, 0.0, 1.0)
	var top := o + Vector2(0, -float(breed.get("leg_len", 30)) - float(breed.get("body_h", 40)) - float(breed.get("head_r", 24)) * 2.2 - (1.0 - k) * 14.0)
	draw_circle(top, 22, Color(1, 1, 1, 0.9 * k))
	match emote:
		"heart":
			draw_colored_polygon(DrawUtil.heart_points(top, 13), Color(0.95, 0.4, 0.55, k))
		"star":
			draw_colored_polygon(DrawUtil.star_points(top, 15, 6.5), Color(0.98, 0.8, 0.25, k))
		"exclaim":
			draw_line(top + Vector2(0, -12), top + Vector2(0, 4), Color(0.9, 0.35, 0.4, k), 5)
			draw_circle(top + Vector2(0, 11), 3, Color(0.9, 0.35, 0.4, k))
		"food":
			var tx := IconButton.pic("food")
			if tx:
				draw_texture_rect(tx, Rect2(top - Vector2(24, 24), Vector2(48, 48)), false, Color(1, 1, 1, k))
			else:
				IconPainter.draw_icon(self, "bone" if species == "dog" else "fish", top, 30, Color(1, 1, 1, k))
		"zzz":
			IconPainter._z(self, top, 9.0, Color(0.5, 0.55, 0.9, k), 3.0)


func _try_profile_action(ids: Array, need_content := false) -> bool:
	var cands: Array = room.furniture_actions_for_pet(self, ids)
	cands.shuffle()
	for c in cands:
		if need_content and c["action"].has("requires_content") and c["f"].content(c["action"]["requires_content"]) <= 0:
			continue
		if use_furniture(c["f"], c["action"]):
			return true
	return false


func _wander(my: int) -> void:
	current = "wander"
	set_state("Wander")
	var ok := await walk_to(room.random_free_point_near(position, 520.0), randf() < 0.15)
	if my != run_id:
		return
	current = ""
	_go_idle()


func _do_idle_anim(p: String, dur: float, my: int) -> void:
	current = "idle_" + p
	set_state({"sit": "Sit", "lie": "Lie", "stretch": "Stretch", "groom": "Groom"}.get(p, "Idle"))
	set_pose(p, 0.5)
	if p == "stretch":
		AudioSvc.sfx("yawn", position, -12.0)
	await wait(dur)
	if my != run_id:
		return
	if p == "groom":
		needs["cleanliness"] = clampf(needs["cleanliness"] + 4.0, 0, 100)
	current = ""
	_go_idle()


func _do_sniff(my: int) -> void:
	current = "sniff"
	set_state("Sniff")
	set_pose("sniff", 0.4)
	var target := room.random_free_point_near(position, 260.0)
	var ok := await walk_to(target)
	if my != run_id:
		return
	await wait(1.4)
	if my != run_id:
		return
	current = ""
	_go_idle()


## Social choreography driven by the room coordinator.
func social_step(kind_: String, partner: Pet, role: String) -> void:
	var my := _new_run()
	current = "social"
	social_partner = partner
	set_state("Social")
	match kind_:
		"meet":
			var side := -1.0 if partner.position.x > position.x else 1.0
			if role == "lead":
				await walk_to(room.nav.nearest_free(partner.position + Vector2(side * 75.0, 0)))
			if my != run_id:
				return
			face_toward_x(partner.position.x)
			set_pose("sniff", 0.4)
			await wait(1.8)
			if my != run_id:
				return
			set_pose("happy" if species == "dog" else "sit", 0.4)
			if species == "dog":
				AudioSvc.sfx("bark", position, -10.0)
			await wait(1.4)
		"chase":
			var t := 0.0
			while t < 7.0 and my == run_id:
				if role == "lead":  # runs away
					var away := room.random_free_point_near(position, 500.0)
					await walk_to(away, true)
				else:
					await walk_to(room.nav.nearest_free(partner.position), true)
				t += 1.6
			if my != run_id:
				return
			set_pose("lie", 0.6)
			await wait(3.0)
	if my != run_id:
		return
	apply_effects({"mood": 10.0, "energy": -4.0})
	social_partner = null
	current = ""
	room.end_social(self)
	_go_idle()


func stop_social() -> void:
	if current == "social":
		_new_run()
		social_partner = null
		current = ""
		stop_moving()
		_go_idle()


## Furniture moved/stored under us: recover gracefully.
func evicted() -> void:
	var my := _new_run()
	room.interactions.release_actor(actor_id)
	hidden_frac = 0.0
	if attached_to != null:
		var p := room.nav.nearest_free(position)
		set_pose("stand", 0.3)
		detach_to(p, 0.4, Callable(), 20.0)
		await wait(0.42)
	if my == run_id:
		current = ""
		_go_idle()


# ---------------------------------------------------------------- loop

func _tick(delta: float) -> void:
	anim_t += delta
	emote_t = max(0.0, emote_t - delta)
	wet = max(0.0, wet - delta * (0.0 if current == "care" else 0.15))
	apply_needs_delta(delta / 60.0)
	if pose_name == "groom":
		pose["paw_anim"] = anim_t * 6.0
		pose["head_tilt"] = 0.45 + sin(anim_t * 6.0) * 0.08
	if pose_name in ["happy", "play_bow"] or (species == "dog" and holder != null):
		pose["wag"] = 1.0
	if pose_name == "eat":
		pose["head_dy"] = float(_poses["eat"]["head_dy"]) + sin(anim_t * 8.0) * 2.0
	if pose_name == "pounce" and current == "care":
		draw_offset.y = -absf(sin(anim_t * 4.5)) * 34.0
		pose["paw_anim"] = anim_t * 9.0
		pose["front_mode"] = "up" if sin(anim_t * 4.5) > 0.3 else "tuck"
	if pose_name == "scratch":
		pose["paw_anim"] = anim_t * 10.0
	if pose_name == "beg":
		pose["paw_anim"] = 1.0 + sin(anim_t * 5.0) * 0.6   # "please!" paw wave
		pose["wag"] = 1.0
	# ambient sounds (rare, throttled)
	_sound_t -= delta
	if _sound_t <= 0.0:
		_sound_t = randf_range(18.0, 40.0)
		if current == "sleep" and species == "cat":
			AudioSvc.sfx("purr", position, -14.0)
		elif randf() < 0.25:
			AudioSvc.sfx("meow" if species == "cat" else "bark", position, -12.0)
	# paw steps synced to stance contacts
	if walk_weight > 0.5:
		var ph := fmod(gait_phase, 0.25)
		if _last_step > ph:
			AudioSvc.sfx("step_paw", position, -14.0)
		_last_step = ph
	if toy and is_instance_valid(toy):
		toy.follow(mouth_point())
	_brain(delta)


func _advance_gait(dist: float) -> void:
	var S := PetPainter.stride(breed, running)
	var st := PetPainter.stance_frac(running)
	gait_phase = fmod(gait_phase + dist / max(scale.x, 0.01) / (S / st) / float(breed.get("scale", 1.0)), 1.0)


func _speed_scale() -> float:
	return 0.8 if is_sad() else 1.0


func mouth_point() -> Vector2:
	var s := PetPainter.skeleton(breed, pose, gait_phase, walk_weight, running)
	var r := float(breed.get("head_r", 24))
	var m: Vector2 = s["head"] + Vector2(r * 1.1, r * 0.4)
	m.x *= facing
	return ground_point() + m * float(breed.get("scale", 1.0)) * scale.x


func _draw() -> void:
	var o := draw_offset / scale
	if attached_to == null and holder == null:
		DrawUtil.shadow(self, o, float(breed.get("body_len", 80)) * 0.55 * float(breed.get("scale", 1.0)), 9, 0.2)
	if hidden_frac > 0.0:
		modulate.a = 1.0 - hidden_frac * 0.55
	else:
		modulate.a = 1.0
	if in_arms:
		return  # the girl draws us inside her hug
	PetPainter.draw(self, breed, pose, facing, gait_phase, walk_weight, running, anim_t, blink, accessory, o, wet, is_sad(), Transform2D.IDENTITY, current_view())
	_draw_emote(o)
	if current == "sleep" or (pose_name == "curl"):
		var k := fmod(anim_t * 12.0, 36.0)
		var hx := float(breed.get("body_len", 80)) * float(breed.get("scale", 1.0)) * 0.5
		IconPainter._z(self, o + Vector2(facing * hx, -55.0 - k), 8.0, Color(0.5, 0.55, 0.9, 1.0 - k / 36.0), 2.8)
		IconPainter._z(self, o + Vector2(facing * (hx + 14.0), -75.0 - k * 0.8), 5.5, Color(0.5, 0.55, 0.9, 0.8 - k / 45.0), 2.2)


func save_state() -> Dictionary:
	return {"breed": breed_id, "needs": needs.duplicate(), "accessory": accessory.get("item_id", "none"), "pos": [position.x, position.y] if attached_to == null and holder == null else [room.nav.nearest_free(position).x, room.nav.nearest_free(position).y]}


func debug_info() -> Dictionary:
	var d := super.debug_info()
	d["current"] = current
	d["needs"] = needs.duplicate()
	d["breed"] = breed_id
	d["held"] = holder != null
	return d
