class_name Girl
extends Actor
## The girl: calm, kind, curious. Player commands have priority; the autonomous
## brain only wanders, looks around and sometimes sits. Every action has
## enter -> loop -> exit and is soft-interruptible (current transition finishes,
## exit plays, then the new command starts). No teleports: all moves are
## walks or tweens between anchors.

signal walk_finished(ok: bool)
signal ui_requested(name: String, girl: Girl)

const POSES := {
	"stand": {"hip_h": 104.0, "lean": 0.03, "head": 0.0, "thigh_f": 0.04, "shin_f": 0.0, "thigh_b": -0.04, "shin_b": 0.0, "arm_f_u": 0.12, "arm_f_l": 0.3, "arm_b_u": -0.12, "arm_b_l": 0.1, "body_rot": 0.0, "sit_ik": 0.0, "fb_arms": 0.0, "eyes": "open", "mouth": "smile", "hold": ""},
	"observe": {"hip_h": 104.0, "lean": 0.0, "head": 0.12, "arm_f_u": 0.05, "arm_f_l": 0.2, "arm_b_u": -0.05, "arm_b_l": 0.15},
	"sit": {"hip_h": 9.0, "lean": -0.05, "head": 0.05, "thigh_f": 1.5, "thigh_b": 1.42, "shin_f": 0.0, "shin_b": 0.0, "sit_ik": 1.0, "arm_f_u": 0.55, "arm_f_l": 1.25, "arm_b_u": 0.45, "arm_b_l": 1.15, "fb_arms": 3.0},
	"read": {"hip_h": 9.0, "lean": -0.02, "head": 0.3, "thigh_f": 1.5, "thigh_b": 1.42, "sit_ik": 1.0, "arm_f_u": 0.95, "arm_f_l": 1.95, "arm_b_u": 0.85, "arm_b_l": 1.85, "hold": "book", "fb_arms": 1.0},
	"lie_prep": {"hip_h": 9.0, "lean": 0.0, "body_rot": -0.75, "thigh_f": 1.1, "thigh_b": 1.0, "shin_f": 0.9, "shin_b": 0.8, "sit_ik": 0.0, "arm_f_u": 0.4, "arm_f_l": 0.6, "arm_b_u": 0.3, "arm_b_l": 0.5},
	"sleep": {"hip_h": 6.0, "lean": 0.0, "head": -0.12, "body_rot": -1.5708, "thigh_f": 0.06, "thigh_b": 0.02, "shin_f": 0.1, "shin_b": 0.04, "sit_ik": 0.0, "arm_f_u": 0.15, "arm_f_l": 0.6, "arm_b_u": 0.05, "arm_b_l": 0.1, "eyes": "closed"},
	"sleep_front": {"hip_h": 104.0, "lean": 0.0, "head": 0.08, "fb_arms": 0.0, "eyes": "closed", "mouth": "smile"},
	"fix_bed": {"hip_h": 104.0, "lean": 0.08, "fb_arms": 1.0, "arm_f_u": 1.3, "arm_f_l": 1.5, "eyes": "happy"},
	"lie_sofa": {"hip_h": 6.0, "lean": 0.0, "head": -0.3, "body_rot": -1.5708, "thigh_f": 0.25, "thigh_b": 0.1, "shin_f": -0.35, "shin_b": 0.05, "sit_ik": 0.0, "arm_f_u": 0.45, "arm_f_l": 1.5, "arm_b_u": 0.05, "arm_b_l": 0.1, "eyes": "happy", "mouth": "smile"},
	"desk": {"hip_h": 9.0, "lean": 0.12, "thigh_f": 1.5, "thigh_b": 1.45, "sit_ik": 1.0, "fb_arms": 1.0, "arm_f_u": 1.2, "arm_f_l": 1.6, "arm_b_u": 1.1, "arm_b_l": 1.5},
	"desk_draw": {"hip_h": 9.0, "lean": 0.16, "thigh_f": 1.5, "thigh_b": 1.45, "sit_ik": 1.0, "fb_arms": 1.0, "arm_f_u": 1.25, "arm_f_l": 1.7, "hold": "pencil"},
	"eat": {"hip_h": 9.0, "lean": 0.04, "thigh_f": 1.5, "thigh_b": 1.42, "sit_ik": 1.0, "arm_f_u": 1.0, "arm_f_l": 1.9, "arm_b_u": 0.9, "arm_b_l": 1.6, "hold": "spoon", "mouth": "chew"},
	"reach": {"hip_h": 104.0, "lean": 0.1, "arm_f_u": 1.45, "arm_f_l": 1.6, "arm_b_u": 0.2, "arm_b_l": 0.3, "fb_arms": 1.0},
	"admire": {"hip_h": 104.0, "lean": 0.0, "fb_arms": 2.0, "eyes": "happy"},
	"look_up": {"hip_h": 104.0, "lean": -0.05, "head": -0.25, "fb_arms": 0.0},
	"crouch": {"hip_h": 62.0, "lean": 0.38, "head": 0.1, "thigh_f": 1.3, "shin_f": -0.3, "thigh_b": 0.95, "shin_b": -0.65, "arm_f_u": 0.95, "arm_f_l": 1.05, "arm_b_u": 0.7, "arm_b_l": 0.85, "sit_ik": 0.0},
	"crouch_wash": {"hip_h": 62.0, "lean": 0.4, "thigh_f": 1.3, "shin_f": -0.3, "thigh_b": 0.95, "shin_b": -0.65, "arm_f_u": 1.3, "arm_f_l": 1.5, "arm_b_u": 0.9, "arm_b_l": 1.0, "hold": "shower"},
	"crouch_brush": {"hip_h": 62.0, "lean": 0.4, "thigh_f": 1.3, "shin_f": -0.3, "thigh_b": 0.95, "shin_b": -0.65, "arm_f_u": 1.1, "arm_f_l": 1.3, "arm_b_u": 0.7, "arm_b_l": 0.9, "hold": "brush"},
	"pet": {"hip_h": 62.0, "lean": 0.42, "thigh_f": 1.3, "shin_f": -0.3, "thigh_b": 0.95, "shin_b": -0.65, "arm_f_u": 1.15, "arm_f_l": 1.25, "arm_b_u": 0.6, "arm_b_l": 0.8, "eyes": "happy"},
	"carry": {"hip_h": 104.0, "lean": -0.08, "arm_f_u": 0.55, "arm_f_l": 1.75, "arm_b_u": 0.45, "arm_b_l": 1.65, "fb_arms": 1.0, "eyes": "happy"},
	"throw_wind": {"hip_h": 100.0, "lean": -0.12, "arm_f_u": -1.3, "arm_f_l": -0.6, "arm_b_u": 0.5, "arm_b_l": 0.6, "hold": "ball"},
	"throw_release": {"hip_h": 104.0, "lean": 0.16, "arm_f_u": 2.0, "arm_f_l": 1.9, "arm_b_u": -0.3, "arm_b_l": -0.1, "hold": ""},
	"tease": {"hip_h": 104.0, "lean": 0.05, "arm_f_u": 1.7, "arm_f_l": 1.9, "hold": "teaser", "eyes": "happy"},
	"happy": {"hip_h": 104.0, "arm_f_u": 2.7, "arm_f_l": 2.9, "arm_b_u": 2.6, "arm_b_l": 2.8, "eyes": "happy", "mouth": "open"},
	"stretch": {"hip_h": 106.0, "lean": -0.12, "arm_f_u": 3.0, "arm_f_l": 3.05, "arm_b_u": 2.95, "arm_b_l": 3.0, "eyes": "closed", "mouth": "o"},
	"fix_hair": {"hip_h": 104.0, "head": 0.1, "arm_f_u": 2.5, "arm_f_l": 3.7, "eyes": "open"},
	"surprised": {"hip_h": 104.0, "lean": -0.05, "arm_f_u": 0.6, "arm_f_l": 1.6, "arm_b_u": 0.5, "arm_b_l": 1.5, "mouth": "o"},
}

const ACTION_STATE := {
	"sit": "Sitting", "read": "Sitting", "lie": "Resting", "sleep": "Sleeping", "eat": "Eat", "study": "Study",
	"draw": "Study", "dress": "Dress", "admire": "UseObject", "look": "LookWindow", "toggle": "UseObject",
	"fill": "UseObject", "fill_treat": "UseObject", "wash": "Pet", "brush": "Pet", "play_cat": "Play", "beauty": "Dress",
}

var appearance: Dictionary = {}
var outfit: Dictionary = {}       # slot -> item def
var preview_override: Dictionary = {}
var run_id := 0
var pending: Dictionary = {}
var interrupt := false
var current_cmd: Dictionary = {}
var current_action := ""
var carrying: Node = null         # Pet
var brain_timer := 4.0
var _waiting_walk := false
var anim_t := 0.0
var seat_lift := 0.0
var bubble := ""
var bubble_t := 0.0
var _last_foot_phase := 0.0
var ui_open := ""
var bed_scale := 1.0              # smaller while asleep far back in tall picture beds


func _init() -> void:
	actor_id = "girl"
	kind = "girl"
	speed = 270.0
	run_speed = 420.0


func poses() -> Dictionary:
	return POSES


func apply_appearance(app: Dictionary) -> void:
	appearance = app
	outfit = {}
	for slot in ["outfit", "shoes", "hat", "accessory", "makeup", "earrings"]:
		var id: String = app.get(slot, "none")
		if id != "none" and Content.has_item(id):
			outfit[slot] = Content.item(id)
	queue_redraw()


func preview_appearance(app: Dictionary) -> void:
	apply_appearance(app)


# ---------------------------------------------------------------- commands

## Entry point for player & brain. cmd.auto = true for brain commands.
func command(cmd: Dictionary) -> void:
	if not cmd.get("auto", false):
		Diag.command({"who": "girl", "type": cmd.get("type"), "action": cmd.get("action", {}).get("id", "") if typeof(cmd.get("action")) == TYPE_DICTIONARY else "", "uid": cmd["f"].uid if cmd.has("f") and cmd["f"] != null else -1})
		brain_timer = randf_range(10.0, 18.0)
	if current_action != "" or attached_to != null or is_attach_tweening():
		# soft interrupt: let the action exit, then run this
		pending = cmd
		interrupt = true
		return
	_start(cmd)


func _start(cmd: Dictionary) -> void:
	run_id += 1
	interrupt = false
	pending = {}
	current_cmd = cmd
	var my := run_id
	if _waiting_walk:
		_waiting_walk = false
		stop_moving()
		walk_finished.emit(false)
	match cmd.get("type", ""):
		"walk":
			_run_walk(cmd, my)
		"use":
			_run_use(cmd, my)
		"pet_cmd":
			_run_pet_cmd(cmd, my)
		"idle_anim":
			_run_idle_anim(cmd, my)
		_:
			_go_idle()


func _go_idle() -> void:
	current_action = ""
	current_cmd = {}
	if carrying:
		set_state("CarryPet")
		set_pose("carry", 0.3)
	else:
		set_state("Idle")
		set_pose("stand", 0.35)
		view = "side"


func _next_or_idle(my: int) -> void:
	if my != run_id:
		return
	current_action = ""
	if not pending.is_empty():
		var p := pending
		pending = {}
		_start(p)
	else:
		_go_idle()


func walk_to(p: Vector2, run := false) -> bool:
	if not go_to(p, _on_walk_arrived, run):
		return false
	_waiting_walk = true
	var ok: bool = await walk_finished
	return ok


func _on_walk_arrived() -> void:
	if _waiting_walk:
		_waiting_walk = false
		walk_finished.emit(true)


func _on_path_failed() -> void:
	if _waiting_walk:
		_waiting_walk = false
		walk_finished.emit(false)


func wait(sec: float) -> void:
	await get_tree().create_timer(sec, false).timeout


func say_bubble(key: String) -> void:
	bubble = Loc.t(key)
	bubble_t = 2.6


func _run_walk(cmd: Dictionary, my: int) -> void:
	view = "side"
	set_state("CarryPet" if carrying else "Walk")
	set_pose("carry" if carrying else "stand", 0.25)
	var ok := await walk_to(cmd["pos"])
	if my != run_id:
		return
	if not ok:
		say_bubble("bubble_cant_reach")
	if not carrying and randf() < 0.3:
		set_state("Observe")
		set_pose("observe", 0.5)
		await wait(1.2)
	_next_or_idle(my)


func _run_idle_anim(cmd: Dictionary, my: int) -> void:
	current_action = "idle_anim"
	var p: String = cmd.get("pose", "stretch")
	set_state("Idle")
	view = "front" if p == "admire" else "side"
	set_pose(p, 0.6)
	await wait(float(cmd.get("dur", 1.8)))
	if my != run_id:
		return
	view = "side"
	set_pose("stand", 0.5)
	await wait(0.5)
	_next_or_idle(my)


## Generic furniture action driven by the interaction profile.
func _run_use(cmd: Dictionary, my: int) -> void:
	var f: Furniture = cmd["f"]
	var a: Dictionary = cmd["action"]
	if f == null or not is_instance_valid(f):
		_go_idle()
		return
	if carrying and not a.get("remote", false):
		await _put_down_pet(my)
		if my != run_id:
			return
	current_action = a["id"]
	view = "side"
	if a.get("needs_pet", "") != "":
		await _run_care(f, a, cmd, my)
		return
	if a.get("remote", false):
		set_state("Approach")
		var below := room.nav.nearest_free(Vector2(f.position.x, RoomGeo.WALK_TOP + 30))
		var okr := await walk_to(below)
		if my != run_id:
			return
		if okr:
			set_state("UseObject")
			view = "back"
			set_pose("reach", 0.35)
			await wait(0.45)
			f.toggle_device()
			await wait(0.4)
		_next_or_idle(my)
		return
	var anchor_name: String = a.get("anchor", "")
	var slot: int = room.interactions.reserve_slot(f, anchor_name, actor_id)
	if slot < 0:
		say_bubble("bubble_busy")
		_next_or_idle(my)
		return
	var anc: Dictionary = f.anchor(anchor_name, slot)
	set_state("Approach")
	room.focus_if_far(f.visual_rect().get_center())
	var ap: Vector2 = room.best_approach(self, f, anc["pos"])
	var standing_anchor: bool = float(anc["lift"]) < 1.0 and a.get("pose", "") not in ["sit", "read", "desk", "eat"]
	var ok := await walk_to(anc["pos"] if standing_anchor else ap)
	if my != run_id:
		room.interactions.release_actor(actor_id)
		return
	if not ok:
		room.interactions.release_actor(actor_id)
		say_bubble("bubble_cant_reach")
		_next_or_idle(my)
		return
	# Turn toward the target
	set_state("Turn")
	_face_for(anc, f)
	await wait(0.18)
	var seq: Array = a.get("sequence", [])
	var seated: bool = not standing_anchor
	if a.get("chair_pull", false):
		f.animate("chair_pull", 1.0, 0.45)
		await wait(0.45)
	if a.get("device_anim", "") == "doors":
		AudioSvc.sfx("creak", f.position)
		f.animate("doors", 1.0, 0.6)
	f.anim["occupied"] = true
	if seated:
		# SitTransition: approach point -> seat anchor while blending into the pose
		set_state("SleepEnter" if a["id"] == "sleep" else "SitTransition")
		var first_name: String = seq[0] if seq.size() > 0 else a["pose"]
		var seat_anchor_name := anchor_name
		if seq.size() > 0 and anchor_name != "seat" and not Content.resolve_anchor(f.item_id, "seat").is_empty():
			seat_anchor_name = "seat"
		var seat := f.anchor(seat_anchor_name, slot if seat_anchor_name == anchor_name else 0)
		_set_view_for(seat, first_name)
		seat_lift = float(seat["lift"])
		set_pose(first_name, 0.55)
		attach(f, seat, anchor_name, 0.6)
		await wait(0.62)
		if not is_instance_valid(f):
			return
		for i in range(1, seq.size()):
			if seq[i] == "lie_prep":
				view = "side"   # lying down is shown from the side
			set_pose(seq[i], 0.6)
			await wait(0.65)
		if seq.size() > 0:
			seat_lift = float(anc["lift"])
			if a["id"] == "sleep" and f.def.has("sprite"):
				f.anim["sleeper"] = true   # slides under the blanket of the picture bed
			_set_view_for(anc, a["pose"])
			set_pose(a["pose"], 0.7)
			attach(f, anc, anchor_name, 0.7)
			await wait(0.72)
		elif first_name != a["pose"]:
			set_pose(a["pose"], 0.5)
	else:
		_set_view_for(anc, a["pose"])
		set_pose(a["pose"], 0.45)
		await wait(0.45)
	if my != run_id:
		return
	set_state(ACTION_STATE.get(a["id"], "UseObject"))
	if a["id"] == "sleep":
		f.anim["sleeper"] = true   # tuck in under the blanket
	# loop effects
	if a.get("device_toggle", false):
		f.toggle_device()
	if a.has("fills"):
		_fill(f, a)
	if a["id"] == "eat":
		AudioSvc.sfx("eat", position)
	if a["id"] == "repair":
		AudioSvc.sfx("pop", f.position)
	if a.get("opens_ui", "") != "":
		if a["opens_ui"] == "notebook":
			room.focus_zoom(f.visual_rect().get_center() + Vector2(0, -80), 1.6)
		ui_open = a["opens_ui"]
		ui_requested.emit(a["opens_ui"], self)
	var dur := -1.0
	if a.has("loop_sec"):
		var r: Array = a["loop_sec"]
		dur = randf_range(float(r[0]), float(r[1]))
	elif a.get("loop", "") == "until_cmd" and cmd.get("auto", false):
		dur = randf_range(8.0, 16.0)
	var t := 0.0
	while my == run_id and not interrupt and is_instance_valid(f):
		if seated and attached_to != f:
			break
		if a.get("opens_ui", "") != "" and ui_open != "":
			pass
		elif dur >= 0.0 and t >= dur:
			break
		await get_tree().process_frame
		t += get_process_delta_time()
		if a["id"] == "repair" and is_instance_valid(f) and dur > 0.0:
			f.anim["fixing"] = clampf(t / dur, 0.0, 1.0)
			f.queue_redraw()
	if is_instance_valid(f) and a["id"] == "repair":
		f.anim["fixing"] = 0.0
		if my == run_id and not interrupt and t >= dur:
			f.repair()
			say_bubble("bubble_bed_fixed")
	if my != run_id:
		return
	# exit
	await _exit_action(f, a, anc, seated, ap)
	room.interactions.release_actor(actor_id)
	if is_instance_valid(f):
		f.anim["occupied"] = false
		if a.get("chair_pull", false):
			f.animate("chair_pull", 0.0, 0.45)
		if a.get("device_anim", "") == "doors":
			f.animate("doors", 0.0, 0.5)
	if a.get("opens_ui", "") == "notebook":
		room.restore_zoom()
	_next_or_idle(my)


func _face_for(anc: Dictionary, f: Furniture) -> void:
	var face: String = anc.get("face", "")
	match face:
		"right":
			facing = 1.0
		"left":
			facing = -1.0
		"toward":
			face_toward_x(f.position.x)
		_:
			face_toward_x(anc["pos"].x)
	if f.def.get("shape") == "bed":
		facing = f.scale.x  # head toward the headboard
	elif f.def.get("shape") == "sofa" and anc.get("face", "") == "":
		facing = 1.0


func _set_view_for(anc: Dictionary, pose_id: String) -> void:
	if anc.get("face", "") == "front" and pose_id in ["sit", "read", "sleep_front"]:
		view = "front"   # sits facing the player on sofas, armchairs and beds
		return
	if anc.get("face", "") == "back" or pose_id in ["desk", "desk_draw", "look_up"]:
		view = "back"
	elif pose_id == "admire":
		view = "back" if anc.get("face", "") == "back" else "front"
	else:
		view = "side"


func _exit_action(f: Furniture, a: Dictionary, anc: Dictionary, seated: bool, ap: Vector2) -> void:
	if not is_instance_valid(f):
		attached_to = null
		draw_offset = Vector2.ZERO
		return
	if a["id"] == "sleep":
		f.add_wear(1.0)
	if a["id"] == "sleep" and f.def.has("sprite"):
		# picture bed: slide out from under the blanket to the edge, stretch, get up
		f.anim["sleeper"] = false
		set_state("WakeUp")
		var seat0 := f.anchor("seat")
		view = "front"
		set_pose("sit", 0.7)
		if not seat0.is_empty():
			seat_lift = float(seat0["lift"])
			attach(f, seat0, "seat", 0.7)
		await wait(0.75)
		AudioSvc.sfx("yawn", position)
		set_pose("stretch", 0.5)
		await wait(0.9)
		set_pose("sit", 0.4)
		await wait(0.4)
		if f.is_worn():
			say_bubble("bubble_bed_worn")
	elif a["id"] in ["sleep", "lie"]:
		if a["id"] == "sleep":
			f.anim["sleeper"] = false
		set_state("WakeUp")
		set_pose("lie_prep", 0.8)
		await wait(0.8)
		var seat := f.anchor("seat")
		if not seat.is_empty():
			seat_lift = float(seat["lift"])
			view = "side"
			set_pose("sit", 0.6)
			attach(f, seat, "seat", 0.6)
			await wait(0.62)
		AudioSvc.sfx("yawn", position)
		set_pose("stretch", 0.5)
		await wait(0.9)
		set_pose("sit", 0.4)
		await wait(0.4)
	if seated:
		set_state("StandUp")
		view = "side"
		face_toward_x(ap.x)
		set_pose("stand", 0.55)
		detach_to(ap, 0.55)
		await wait(0.57)
		seat_lift = 0.0
	else:
		set_pose("stand", 0.35)
		await wait(0.35)
	view = "side"


func _fill(f: Furniture, a: Dictionary) -> void:
	var kind_: String = a["fills"]
	if a.get("requires_consumable", "") != "":
		var used := Economy.consume(a["requires_consumable"])
		if used == "":
			say_bubble("bubble_no_treats")
			return
		f.set_content("treat", f.content("treat") + 1)
		f.set_content("food", f.content("food") + 1)
	else:
		f.set_content(kind_, int(a.get("amount", 3)))
	AudioSvc.sfx("pop" if kind_ != "water" else "splash", f.position, -6.0)
	Diag.event("bowl_fill", {"uid": f.uid, "kind": kind_})


## Bath / brush / teaser: needs a pet participant (exclusive lock).
func _run_care(f: Furniture, a: Dictionary, cmd: Dictionary, my: int) -> void:
	var pet: Node = cmd.get("pet", null)
	if pet == null:
		var want: String = a["needs_pet"]
		pet = room.cat if want == "cat" else (room.pick_pet_for_care() if want == "pet" else room.dog)
	if pet == null or not pet.can_join():
		say_bubble("bubble_pet_busy")
		_next_or_idle(my)
		return
	if not room.interactions.lock_actor(pet.actor_id, actor_id):
		say_bubble("bubble_pet_busy")
		_next_or_idle(my)
		return
	if room.interactions.reserve_slot(f, a["anchor"], actor_id) < 0:
		room.interactions.unlock_actor(pet.actor_id, actor_id)
		say_bubble("bubble_busy")
		_next_or_idle(my)
		return
	var helper := f.anchor(a["anchor"])
	var pet_anchor := f.anchor("pet")
	set_state("Approach")
	pet.join_care(f, pet_anchor, a.get("pet_pose", "sit"), self)
	var ok := await walk_to(helper["pos"])
	if my != run_id or not ok:
		room.interactions.release_actor(actor_id)
		room.interactions.unlock_actor(pet.actor_id, actor_id)
		pet.end_care()
		if my == run_id:
			say_bubble("bubble_cant_reach")
			_next_or_idle(my)
		return
	face_toward_x(pet_anchor["pos"].x)
	# wait for the pet to arrive (max 8 s, then give up softly)
	var waited := 0.0
	while not pet.care_ready and waited < 8.0 and my == run_id:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if my != run_id or not pet.care_ready:
		room.interactions.release_actor(actor_id)
		room.interactions.unlock_actor(pet.actor_id, actor_id)
		pet.end_care()
		if my == run_id:
			_next_or_idle(my)
		return
	face_toward_x(pet.position.x)
	set_state(ACTION_STATE.get(a["id"], "Pet"))
	set_pose(a["pose"], 0.45)
	f.anim["occupied"] = true
	var dur := float(a.get("loop_sec", [5, 5])[0])
	var t := 0.0
	var snd: String = {"wash": "splash", "brush": "brush", "play_cat": "whoosh"}.get(a["id"], "pop")
	while t < dur and my == run_id and not interrupt:
		if fmod(t, 1.2) < get_process_delta_time():
			AudioSvc.sfx(snd, position, -4.0)
		await get_tree().process_frame
		t += get_process_delta_time()
	var frac := clampf(t / dur, 0.0, 1.0)
	pet.apply_effects(a.get("pet_effects", {}), frac)
	f.anim["occupied"] = false
	set_pose("stand", 0.4)
	room.interactions.release_actor(actor_id)
	room.interactions.unlock_actor(pet.actor_id, actor_id)
	pet.end_care()
	await wait(0.4)
	_next_or_idle(my)


# ---------------------------------------------------------------- pet commands

func _run_pet_cmd(cmd: Dictionary, my: int) -> void:
	var pet: Node = cmd["pet"]
	var what: String = cmd["cmd"]
	current_action = "pet_" + what
	match what:
		"pickup":
			await _pick_up(pet, my)
		"putdown":
			await _put_down_pet(my)
		"pet":
			await _pet_it(pet, my)
		"play":
			await _play_with(pet, my)
		"hug":
			await _hug(pet, my)
		"trick":
			if await _approach_pet(pet, my):
				set_pose("happy", 0.3)
				pet.do_trick(self)
				await wait(2.6)
		_:
			pass
	_next_or_idle(my)


func _approach_pet(pet: Node, my: int) -> bool:
	var side := -1.0 if pet.position.x > position.x else 1.0
	var target: Vector2 = room.nav.nearest_free(pet.position + Vector2(side * 70.0, 6.0))
	if position.distance_to(target) > 20.0:
		var ok := await walk_to(target)
		if my != run_id or not ok:
			return false
	face_toward_x(pet.position.x)
	return true


func _pick_up(pet: Node, my: int) -> void:
	if carrying:
		return
	if not pet.can_be_held():
		say_bubble("bubble_pet_busy")
		return
	if not room.interactions.lock_actor(pet.actor_id, actor_id):
		say_bubble("bubble_pet_busy")
		return
	pet.request_hold(self)
	set_state("Approach")
	# wait for the pet to finish its current action softly
	var waited := 0.0
	while not pet.hold_ready and waited < 6.0 and my == run_id:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if my != run_id or not pet.hold_ready or not await _approach_pet(pet, my):
		room.interactions.unlock_actor(pet.actor_id, actor_id)
		pet.cancel_hold()
		return
	set_state("PickUpPet")
	set_pose("crouch", 0.45)
	await wait(0.45)
	carrying = pet
	pet.attach_to_hands(self)
	set_pose("carry", 0.55)
	await wait(0.55)
	set_state("CarryPet")


func _put_down_pet(my: int) -> void:
	if carrying == null:
		return
	var pet: Node = carrying
	var spot := Vector2.INF
	for side in [facing, -facing]:
		for dist in [60.0, 85.0, 110.0]:
			var cand: Vector2 = position + Vector2(side * dist, 8.0)
			if room.nav.is_free(cand) and RoomGeo.walk_rect().has_point(cand):
				spot = cand
				break
		if spot != Vector2.INF:
			break
	if spot == Vector2.INF:
		var near: Vector2 = room.nav.nearest_free(position + Vector2(facing * 70.0, 10.0), 8)
		if near.distance_to(position) < 160.0 and room.nav.is_free(near):
			spot = near
	if spot == Vector2.INF:
		say_bubble("bubble_no_space")
		return
	set_state("PutDownPet")
	face_toward_x(spot.x)
	set_pose("crouch", 0.5)
	await wait(0.3)
	carrying = null
	pet.put_down_at(spot)
	await wait(0.45)
	room.interactions.unlock_actor(pet.actor_id, actor_id)
	set_pose("stand", 0.4)
	await wait(0.4)


func _pet_it(pet: Node, my: int) -> void:
	if carrying == pet:
		set_state("Pet")
		set_pose("carry", 0.2)
		pet.react_petted()
		await wait(1.5)
		return
	if not pet.can_join():
		say_bubble("bubble_pet_busy")
		return
	if not room.interactions.lock_actor(pet.actor_id, actor_id):
		say_bubble("bubble_pet_busy")
		return
	pet.wait_for_girl(self)
	if not await _approach_pet(pet, my):
		room.interactions.unlock_actor(pet.actor_id, actor_id)
		pet.end_care()
		return
	set_state("Pet")
	set_pose("pet", 0.45)
	await wait(0.45)
	pet.react_petted()
	var t := 0.0
	while t < 2.6 and my == run_id:
		pose["arm_f_l"] = 1.25 + sin(t * 7.0) * 0.25
		await get_tree().process_frame
		t += get_process_delta_time()
	set_pose("stand", 0.4)
	room.interactions.unlock_actor(pet.actor_id, actor_id)
	pet.end_care()
	await wait(0.4)


func _hug(pet: Node, my: int) -> void:
	if not pet.can_join() or not room.interactions.lock_actor(pet.actor_id, actor_id):
		say_bubble("bubble_pet_busy")
		return
	pet.wait_for_girl(self)
	if not await _approach_pet(pet, my):
		room.interactions.unlock_actor(pet.actor_id, actor_id)
		pet.end_care()
		return
	set_state("Pet")
	view = "side"
	set_pose("crouch", 0.4)
	await wait(0.4)
	pose["arm_f_u"] = 1.5
	pose["arm_f_l"] = 2.3
	pose["arm_b_u"] = 1.4
	pose["arm_b_l"] = 2.2
	pose["eyes"] = "happy"
	pet.react_petted()
	pet.show_emote("heart", 2.4)
	AudioSvc.sfx("purr" if pet.kind == "cat" else "yay", position, -6.0)
	await wait(2.2)
	set_pose("stand", 0.4)
	room.interactions.unlock_actor(pet.actor_id, actor_id)
	pet.end_care()
	await wait(0.4)


func _play_with(pet: Node, my: int) -> void:
	if not pet.can_join():
		say_bubble("bubble_pet_busy")
		return
	if pet.kind == "cat":
		var teaser: Furniture = room.find_furniture_with_profile("teaser")
		if teaser:
			_start({"type": "use", "f": teaser, "action": Content.find_action(teaser.item_id, "play_cat", "girl"), "pet": pet})
			return
	var ball: Node = room.nearest_toy(position, "ball")
	if ball == null:
		say_bubble("bubble_no_ball")
		return
	# walk to the ball, pick it up, throw it so the pet can chase it
	set_state("Play")
	var ok := await walk_to(room.nav.nearest_free(ball.floor_pos + Vector2(-40.0 * signf(ball.floor_pos.x - position.x + 0.01), 0)))
	if my != run_id or not ok or not is_instance_valid(ball):
		return
	face_toward_x(ball.floor_pos.x)
	set_pose("crouch", 0.35)
	await wait(0.35)
	ball.hold_by(self)
	await throw_ball(ball, pet)


func throw_ball(ball: Node, for_pet: Node = null) -> void:
	set_state("Play")
	var dir := facing
	var free_dir := room.free_direction(position, dir)
	facing = free_dir
	set_pose("throw_wind", 0.35)
	await wait(0.4)
	set_pose("throw_release", 0.18)
	await wait(0.12)
	var v := Vector2(facing * randf_range(520.0, 760.0), randf_range(-60.0, 80.0))
	ball.release(position + Vector2(facing * 30.0, 2.0), v, 220.0)
	AudioSvc.sfx("whoosh", position)
	if for_pet != null and is_instance_valid(for_pet):
		for_pet.chase_toy(ball, true)
	await wait(0.4)
	set_pose("stand", 0.4)


# ---------------------------------------------------------------- brain + loop

func _tick(delta: float) -> void:
	anim_t += delta
	pose["anim_t"] = anim_t
	if bubble_t > 0.0:
		bubble_t -= delta
	# animated loops
	var bs_target := 1.0
	if pose_name == "sleep_front" and attached_to != null and is_instance_valid(attached_to):
		bs_target = float(attached_to.def.get("sleep_scale", 1.0))
	bed_scale = move_toward(bed_scale, bs_target, delta * 0.8)
	match pose_name:
		"eat":
			pose["arm_f_u"] = 0.95 + sin(anim_t * 3.0) * 0.18
			if fmod(anim_t, 2.1) < delta:
				AudioSvc.sfx("eat", position, -8.0)
		"desk_draw":
			pose["arm_f_l"] = 1.7 + sin(anim_t * 8.0) * 0.1
		"crouch_wash", "crouch_brush":
			pose["arm_f_u"] = 1.15 + sin(anim_t * 6.0) * 0.22
		"fix_bed":
			pose["arm_f_u"] = 1.3 + sin(anim_t * 9.0) * 0.25
			draw_offset.y += sin(anim_t * 9.0) * 0.05
		"tease":
			pose["arm_f_u"] = 1.7 + sin(anim_t * 4.0) * 0.3
		"observe":
			pose["head"] = sin(anim_t * 0.8) * 0.18
		"sleep":
			draw_offset.y += sin(anim_t * 1.6) * 0.04  # breathing
	# footsteps synced to foot contact
	if walk_weight > 0.5:
		var ph := fmod(gait_phase, 0.5)
		if _last_foot_phase > ph:
			AudioSvc.sfx("step_floor", position, -8.0, 1.0 + randf() * 0.1)
		_last_foot_phase = ph
	# carried pet follows the hands every frame
	if carrying and is_instance_valid(carrying):
		carrying.follow_hands(self)
	_brain(delta)


func _advance_gait(dist: float) -> void:
	# one cycle = two steps; stance covers STRIDE while the hip moves STRIDE
	# feet stay planted: convert world distance to body space (character is scaled)
	gait_phase = fmod(gait_phase + dist / max(scale.x, 0.01) / (GirlPainter.STRIDE / GirlPainter.STANCE), 1.0)


func _speed_scale() -> float:
	return 0.85 if carrying else 1.0


func _brain(delta: float) -> void:
	if current_action != "" or moving or attached_to != null or ui_open != "":
		return
	brain_timer -= delta
	if brain_timer > 0.0:
		return
	brain_timer = randf_range(5.0, 12.0)
	if carrying:
		return
	# the dog brought the ball -> she happily throws it
	if room.ball_offered_by and Time.get_ticks_msec() - room.ball_offered_t < 6000:
		var dog_: Node = room.ball_offered_by
		room.ball_offered_by = null
		command({"type": "pet_cmd", "cmd": "play", "pet": dog_, "auto": true})
		return
	var r := randf()
	if r < 0.45:
		var target := room.random_free_point_near(position, 700.0)
		command({"type": "walk", "pos": target, "auto": true})
	elif r < 0.62:
		var seat: Dictionary = room.random_girl_action(["sit", "read", "draw"])
		if not seat.is_empty():
			command({"type": "use", "f": seat["f"], "action": seat["action"], "auto": true})
	elif r < 0.72:
		var w: Dictionary = room.random_girl_action(["look", "admire"])
		if not w.is_empty():
			command({"type": "use", "f": w["f"], "action": w["action"], "auto": true})
	else:
		var anims := ["stretch", "fix_hair", "observe", "happy"]
		command({"type": "idle_anim", "pose": anims[randi() % anims.size()], "dur": 1.6, "auto": true})


func ui_closed(name_: String) -> void:
	if ui_open == name_:
		ui_open = ""
		interrupt = true


func hold_anchor() -> Vector2:
	## World point between the hands (for carrying), honours facing & pose.
	var j := GirlPainter.joints(pose, gait_phase, walk_weight, seat_lift / scale.y)
	var h: Vector2 = (j["hand_f"] + j["hand_b"]) * 0.5
	h.x *= facing
	return ground_point() + h * scale


func _draw() -> void:
	var o := draw_offset / scale
	DrawUtil.shadow(self, o + Vector2(0, 0) if attached_to == null else o + Vector2(0, 6), 40, 11, 0.2 if attached_to == null else 0.0)
	var base := Transform2D.IDENTITY
	if bed_scale < 0.999:
		base = Transform2D(0, Vector2(bed_scale, bed_scale), 0, o * (1.0 - bed_scale))
	var j := GirlPainter.draw(self, pose, appearance, outfit, current_view(), facing, gait_phase, walk_weight, seat_lift / scale.y, blink, o, base, _draw_carried if carrying and is_instance_valid(carrying) and carrying.in_arms else Callable())
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if bubble_t > 0.0 and bubble != "":
		var font := ThemeDB.fallback_font
		var top := o + Vector2(0, -260)
		var w := font.get_string_size(bubble, HORIZONTAL_ALIGNMENT_CENTER, -1, 30).x + 40
		DrawUtil.rrect(self, Rect2(top.x - w / 2, top.y - 50, w, 56), 26, Color(1, 1, 1, 0.95), true, 0.0)
		draw_string(font, Vector2(top.x - w / 2 + 20, top.y - 12), bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#6b4a5a"))
	if state == "Sleeping":
		var zp := o + Vector2(-facing * 70.0, -60.0 - fmod(anim_t * 14.0, 40.0))
		if view == "front":
			zp = o + Vector2(60.0, -200.0 - fmod(anim_t * 14.0, 40.0))
		IconPainter._z(self, zp, 9.0, Color(0.55, 0.6, 0.9, 1.0 - fmod(anim_t * 14.0, 40.0) / 40.0), 3.0)


## Draws the carried pet inside the girl's transform, between body and arm.
func _draw_carried(ci: CanvasItem, j: Dictionary, xf: Transform2D) -> void:
	var pet: Node = carrying
	var b: Dictionary = pet.breed
	var bs := float(b.get("scale", 1.0))
	var hands: Vector2 = j["hands"] if j.has("fb") else (j["hand_f"] + j["hand_b"]) * 0.5
	var pp: Dictionary = pet.pose
	var body_y := float(pp.get("body_y", 40.0)) * bs
	var L := float(b.get("body_len", 80)) * bs
	# the pet looks at the girl (head toward her face), happy, cuddled in front of her
	var origin: Vector2
	var pfacing := -1.0
	if j.has("fb"):
		pfacing = 1.0
		origin = hands + Vector2(-L * 0.15, body_y * 0.8)
	else:
		origin = hands + Vector2(L * 0.22, body_y * 0.95 + 12.0)
	var head_up := pp.duplicate()
	head_up["head_tilt"] = -0.45
	head_up["head_dy"] = float(pp.get("head_dy", -30.0)) - 8.0
	head_up["eyes"] = "happy"
	head_up["wag"] = 1.0
	head_up["mouth_open"] = 0.6 if b.get("species") == "dog" else 0.0
	head_up["tongue"] = 1.0 if b.get("species") == "dog" else 0.0
	var pxf := xf * Transform2D(0, Vector2.ONE, 0, origin)
	PetPainter.draw(ci, b, head_up, pfacing, 0.0, 0.0, false, pet.anim_t, pet.blink, pet.accessory, Vector2.ZERO, pet.wet, false, pxf, "side")
	# little floating hearts = the pet is happy in her arms
	ci.draw_set_transform_matrix(pxf)
	for k in 3:
		var ph := fmod(anim_t * 0.6 + k * 0.33, 1.0)
		var hp := Vector2(pfacing * (L * 0.2) + sin(ph * 6.0 + k) * 10.0, -body_y - 30.0 - ph * 60.0)
		ci.draw_colored_polygon(DrawUtil.heart_points(hp, 8.0 + k * 1.5), Color(1.0, 0.45, 0.6, 1.0 - ph))
