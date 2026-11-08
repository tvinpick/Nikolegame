class_name ItemPreview
extends Control
## Draws any catalog item (furniture, toy, breed, clothes, swatch) scaled to fit.

var item_id := ""
var appearance: Dictionary = {}   # for clothes preview on the girl
var t := 0.0
var animate := false


func _ready() -> void:
	resized.connect(queue_redraw)


func setup(id: String, anim := false) -> void:
	item_id = id
	animate = anim
	set_process(anim)
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var def := Content.item(item_id)
	if def.is_empty():
		return
	var s := size
	var cat: String = def.get("category", "")
	if cat == "breeds":
		var b: Dictionary = Content.breeds[item_id]
		var leg := float(b["leg_len"])
		var H := float(b["body_h"])
		var p := {"body_y": (leg + H * 0.35) * 0.72, "tilt": 0.55, "body_x": -float(b["body_len"]) * 0.12, "back_mode": "fold", "head_dx": float(b["body_len"]) * 0.16, "head_dy": -H * 0.85, "tail_a": 0.1, "front_mode": "stand", "eyes": "open", "wag": 0.5}
		var k: float = min(s.x / (float(b["body_len"]) * 1.8), s.y / ((leg + H) * 2.4))
		PetPainter.draw(self, b, p, 1.0, 0.0, 0.0, false, t, 0.0, {}, Vector2.ZERO, 0.0, false, Transform2D(0, Vector2(k, k), 0, Vector2(s.x * 0.5, s.y * 0.88)))
		draw_set_transform(Vector2.ZERO)
		return
	if cat in ["clothes_girl"]:
		var app := GameState.appearance().duplicate() if appearance.is_empty() else appearance.duplicate()
		app[def.get("slot", "outfit")] = item_id
		var outfit := {}
		for slot in ["outfit", "shoes", "hat", "accessory", "makeup", "earrings"]:
			var id: String = app.get(slot, "none")
			if Content.has_item(id):
				outfit[slot] = Content.item(id)
		if def.get("slot", "") in ["makeup", "earrings", "hat"]:
			# close-up of the face for small things
			var kh := s.y / 120.0
			var pose0: Dictionary = Girl.POSES["stand"].duplicate()
			pose0["eyes"] = "open"
			GirlPainter.draw(self, pose0, app, outfit, "front", 1.0, 0.0, 0.0, 0.0, 0.0, Vector2(0, 205), Transform2D(0, Vector2(kh, kh), 0, Vector2(s.x * 0.5, s.y * 0.05)))
			draw_set_transform(Vector2.ZERO)
			return
		var k2 := s.y / 300.0
		var pose: Dictionary = Girl.POSES["stand"].duplicate()
		pose["eyes"] = "happy"
		GirlPainter.draw(self, pose, app, outfit, "front", 1.0, 0.0, 0.0, 0.0, 0.0, Vector2.ZERO, Transform2D(0, Vector2(k2, k2), 0, Vector2(s.x * 0.5, s.y * 0.95)))
		draw_set_transform(Vector2.ZERO)
		return
	if cat == "clothes_pet":
		var b2: Dictionary = Content.breeds_of("dog")[0]
		var leg2 := float(b2["leg_len"])
		var H2 := float(b2["body_h"])
		var p2 := {"body_y": leg2 + H2 * 0.35, "head_dx": float(b2["body_len"]) * 0.16, "head_dy": -H2 * 0.75, "tail_a": -1.3, "wag": 0.6}
		var k3: float = min(s.x / (float(b2["body_len"]) * 1.8), s.y / ((leg2 + H2) * 2.4))
		PetPainter.draw(self, b2, p2, 1.0, 0.0, 0.0, false, t, 0.0, def, Vector2.ZERO, 0.0, false, Transform2D(0, Vector2(k3, k3), 0, Vector2(s.x * 0.5, s.y * 0.88)))
		draw_set_transform(Vector2.ZERO)
		return
	var sz: Dictionary = def.get("size", {})
	var w := float(sz.get("w", 100))
	var d := float(sz.get("d", 50))
	var h := float(sz.get("h", 100))
	var vis_h := h + d + 40.0
	if def.get("shape", "").begins_with("swatch"):
		w = 130.0
		vis_h = 110.0
	if def.get("placement") == "wall":
		vis_h = h + 10.0
	if def.has("sprite"):
		var st := FurniturePainter.tex(def["sprite"])
		if st:
			vis_h = w * st.get_height() / st.get_width() + 10.0
	var k4: float = min(s.x * 0.86 / max(w, 40.0), s.y * 0.86 / max(vis_h, 40.0))
	var origin := Vector2(s.x * 0.5, s.y * 0.92)
	if def.get("placement") == "wall":
		origin = Vector2(s.x * 0.5, s.y * 0.5)
	draw_set_transform(origin, 0, Vector2(k4, k4))
	var state := Economy.default_instance_state(item_id)
	if def.get("interaction_profile") == "bowl_food":
		state["food"] = 2
	if def.get("interaction_profile") == "bowl_water":
		state["water"] = 2
	if def.has("device"):
		state["on"] = true
	FurniturePainter.draw(self, def, state, {"t": t, "hour": 10.1, "doors": 0.0, "chair_pull": 0.0})
	draw_set_transform(Vector2.ZERO)
