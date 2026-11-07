class_name Tutorial
extends Control
## First-run hints without long reading: big animated pointer + short voice
## line per step, any step can be skipped. Steps complete by doing the action.

signal finished()

const STEPS := [
	{"key": "tut_floor", "event": "floor"},
	{"key": "tut_object", "event": "furniture"},
	{"key": "tut_pet", "event": "pet"},
	{"key": "tut_desk", "event": "none"},
]

var room: Room
var step := 0
var label: Label
var pointer: Pointer
var t := 0.0


func _ready() -> void:
	theme = UIKit.theme()
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := UIKit.panel()
	var h := UIKit.hbox(16)
	label = UIKit.label("", 34, UIKit.INK, true)
	label.custom_minimum_size = Vector2(700, 0)
	h.add_child(label)
	h.add_child(UIKit.button(Loc.t("tut_skip"), _skip, Color("#d8b9c6"), 180))
	p.add_child(h)
	p.position = Vector2(300, get_viewport_rect().size.y - 220)
	add_child(p)
	pointer = Pointer.new()
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pointer)
	room.floor_tapped.connect(func(_w): _event("floor"))
	room.furniture_tapped.connect(func(_f, _s): _event("furniture"))
	room.pet_tapped.connect(func(_p, _s): _event("pet"))
	_show()


func _show() -> void:
	if step >= STEPS.size():
		_finish()
		return
	var s: Dictionary = STEPS[step]
	label.text = Loc.t(s["key"])
	AudioSvc.say(s["key"])
	if s["event"] == "none":
		get_tree().create_timer(6.0).timeout.connect(func():
			if step < STEPS.size() and STEPS[step]["event"] == "none":
				step += 1
				_show())


func _process(delta: float) -> void:
	t += delta
	if step >= STEPS.size() or room == null:
		return
	var target := Vector2.ZERO
	match STEPS[step]["event"]:
		"floor":
			target = room.world_to_screen(room.girl.position + Vector2(260, 60))
		"furniture":
			var f := room.find_furniture_with_profile("sofa")
			if f == null:
				f = room.find_furniture_with_profile("bed")
			if f:
				room.focus_if_far(f.position)
				target = room.world_to_screen(f.visual_rect().get_center())
		"pet":
			target = room.world_to_screen(room.cat.ground_point() + Vector2(0, -40))
		"none":
			var d := room.find_furniture_with_profile("desk")
			if d:
				room.focus_if_far(d.position)
				target = room.world_to_screen(d.visual_rect().get_center())
	pointer.position = target + Vector2(0, -20 - absf(sin(t * 4.0)) * 30.0)


func _event(e: String) -> void:
	if step < STEPS.size() and STEPS[step]["event"] == e:
		step += 1
		AudioSvc.sfx("sparkle")
		_show()


func _skip() -> void:
	_finish()


func _finish() -> void:
	GameState.set_setting("tutorial_done", true)
	Save.request_save("tutorial")
	finished.emit()
	queue_free()


class Pointer extends Control:
	func _draw() -> void:
		# big friendly hand-arrow pointing down
		var pts := PackedVector2Array([Vector2(-26, -120), Vector2(26, -120), Vector2(26, -50), Vector2(52, -50), Vector2(0, 0), Vector2(-52, -50), Vector2(-26, -50)])
		DrawUtil.poly(self, pts, Color("#ffd86b"))
		draw_circle(Vector2(0, -150), 22, Color(1, 1, 1, 0.7))
