class_name PetPainter
extends RefCounted
## Quadruped skeleton (shoulder/hip + 4 two-bone legs + head + tail) drawn
## from a breed profile. Species have different gaits: dog = trot (diagonal
## pairs), cat = walk (lateral sequence, softer, lower). Planted feet during
## stance -> no sliding.

const D := preload("res://scripts/core/draw_util.gd")


static func pf(p: Dictionary, k: String, d := 0.0) -> float:
	return float(p.get(k, d))


static func gait_offsets(species: String, running: bool) -> Dictionary:
	if species == "dog" or running:
		return {"fl": 0.0, "br": 0.0, "fr": 0.5, "bl": 0.5}
	return {"bl": 0.0, "fl": 0.25, "br": 0.5, "fr": 0.75}


static func stride(b: Dictionary, running: bool) -> float:
	return float(b.get("leg_len", 34)) * (1.7 if running else 1.05)


static func stance_frac(running: bool) -> float:
	return 0.42 if running else 0.62


static func ik(root: Vector2, target: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var d := clampf(root.distance_to(target), absf(l1 - l2) + 0.01, l1 + l2 - 0.01)
	var dir := (target - root).normalized()
	var a := acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
	return root + dir.rotated(-a * bend) * l1


static func skeleton(b: Dictionary, p: Dictionary, gait: float, walk_w: float, running: bool) -> Dictionary:
	var L := float(b.get("body_len", 80))
	var H := float(b.get("body_h", 40))
	var leg := float(b.get("leg_len", 34))
	var species: String = b.get("species", "cat")
	var bob := -absf(sin(gait * TAU * 2.0)) * (2.0 if species == "cat" else 3.5) * walk_w
	var body_y := pf(p, "body_y", leg + H * 0.35) - bob
	var tilt := pf(p, "tilt")
	var dir := Vector2(cos(tilt), -sin(tilt))
	var center := Vector2(pf(p, "body_x"), -body_y)
	var sh := center + dir * L * 0.36
	var hp := center - dir * L * 0.36
	var s := {"center": center, "dir": dir, "sh": sh, "hp": hp, "L": L, "H": H}
	var offs := gait_offsets(species, running)
	var S := stride(b, running)
	var st := stance_frac(running)
	for legname in ["fl", "fr", "bl", "br"]:
		var front: bool = legname.begins_with("f")
		var root: Vector2 = (sh if front else hp) + Vector2(0, H * 0.25)
		var mode: String = p.get("front_mode" if front else "back_mode", "stand")
		var foot := Vector2(root.x + (4.0 if front else -2.0), 0.0)
		match mode:
			"fold":
				foot = Vector2(root.x + leg * 0.55, 0.0)
			"tuck":
				foot = Vector2(root.x + (leg * 0.9 if front else leg * 0.45), -2.0)
			"dangle":
				foot = root + Vector2(4.0, leg * 0.95).rotated(-tilt * 0.3)
			"up":
				foot = root + Vector2(leg * 0.55, -leg * 0.6)
			"paw":
				foot = root + Vector2(leg * 0.6, -leg * 0.35)
			"reach":
				foot = Vector2(root.x + leg * 0.9, 0.0)
			"hidden":
				foot = root + Vector2(0, leg * 0.3)
		if legname.ends_with("r"):
			foot.x += 3.0 if front else -3.0
		var anim_paw := pf(p, "paw_anim")
		if front and legname == "fl" and anim_paw > 0.0:
			foot += Vector2(0, -sin(anim_paw) * 10.0 - 6.0)
		if walk_w > 0.001 and mode == "stand":
			var ph := fmod(gait + float(offs[legname]), 1.0)
			var fx: float
			var fy := 0.0
			if ph < st:
				fx = lerpf(S * 0.5, -S * 0.5, ph / st)
			else:
				var k := (ph - st) / (1.0 - st)
				fx = lerpf(-S * 0.5, S * 0.5, k)
				fy = -sin(k * PI) * leg * (0.32 if running else 0.22)
			var gfoot := Vector2(root.x + fx + (4.0 if front else -2.0), fy)
			foot = foot.lerp(gfoot, walk_w)
		var knee := ik(root, foot, leg * 0.52, leg * 0.52, -1.0 if front else 1.0)
		s[legname] = {"root": root, "knee": knee, "foot": foot}
	# head
	var head_c := sh + Vector2(pf(p, "head_dx", L * 0.16), pf(p, "head_dy", -H * 0.75)).rotated(-tilt * 0.4)
	s["head"] = head_c
	s["head_tilt"] = pf(p, "head_tilt")
	# tail root
	s["tail_root"] = hp + Vector2(-H * 0.1, -H * 0.2).rotated(-tilt)
	return s


static func draw(ci: CanvasItem, b: Dictionary, p: Dictionary, facing: float, gait: float, walk_w: float, running: bool, t: float, blink: float, accessory: Dictionary, origin := Vector2.ZERO, wet := 0.0, sad := false, base := Transform2D.IDENTITY) -> Dictionary:
	var sc := float(b.get("scale", 1.0))
	var fur := Content.color(b.get("fur", "#f2a65a"))
	var fur2 := Content.color(b.get("fur2", "#ffffff"))
	var fur3 := Content.color(b.get("fur3", "#4a4040"))
	if wet > 0.0:
		fur = fur.darkened(0.18 * wet)
		fur2 = fur2.darkened(0.12 * wet)
	var s := skeleton(b, p, gait, walk_w, running)
	ci.draw_set_transform_matrix(base * Transform2D(0.0, Vector2(facing * sc, sc), 0.0, origin))
	var curl := pf(p, "curl")
	if curl > 0.5:
		_curled(ci, b, p, s, fur, fur2, fur3, t, accessory)
	else:
		_standing(ci, b, p, s, fur, fur2, fur3, t, blink, accessory, sad)
	if wet > 0.1:
		for i in 6:
			var bp: Vector2 = s["center"] + Vector2(sin(t * 2.0 + i) * s["L"] * 0.4, -s["H"] * 0.6 - fmod(t * 20.0 + i * 9.0, 40.0))
			ci.draw_circle(bp, 5 + (i % 3) * 2, Color(1, 1, 1, 0.7 * wet))
	ci.draw_set_transform_matrix(base)
	return s


static func _leg(ci: CanvasItem, l: Dictionary, w: float, col: Color, paw_col: Color) -> void:
	D.taper(ci, l["root"], l["knee"], w * 1.25, w, col)
	D.taper(ci, l["knee"], l["foot"], w, w * 0.8, col)
	D.ellipse(ci, l["foot"] + Vector2(3, -2), w * 0.62, w * 0.42, paw_col, true, 0.05)


static func _standing(ci: CanvasItem, b: Dictionary, p: Dictionary, s: Dictionary, fur: Color, fur2: Color, fur3: Color, t: float, blink: float, accessory: Dictionary, sad: bool) -> void:
	var species: String = b.get("species", "cat")
	var L: float = s["L"]
	var H: float = s["H"]
	var leg_w := H * (0.24 if species == "cat" else 0.28)
	var pattern: String = b.get("pattern", "solid")
	var paw := fur2 if pattern in ["tuxedo", "bicolor", "tricolor", "calico"] else fur
	if pattern == "points":
		paw = fur2
	# tail (behind)
	_tail(ci, b, p, s, fur, fur2, t)
	# far legs
	_leg(ci, s["fr"], leg_w, fur.darkened(0.14), paw.darkened(0.14))
	_leg(ci, s["br"], leg_w * 1.1, fur.darkened(0.14), paw.darkened(0.14))
	# body
	var c: Vector2 = s["center"]
	var dir: Vector2 = s["dir"]
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var v := Vector2(cos(a) * L * 0.5, sin(a) * H * 0.5)
		if v.y > 0:
			v.y *= 0.9
		if pattern in ["fluffy", "curly"]:
			v *= 1.0 + 0.06 * sin(a * 9.0)
		pts.append(c + v.rotated(dir.angle()))
	D.poly(ci, pts, fur, true, 0.14)
	# belly / markings
	match pattern:
		"tabby":
			for i in 4:
				var x := -L * 0.25 + i * L * 0.16
				ci.draw_line(c + Vector2(x, -H * 0.45).rotated(dir.angle()), c + Vector2(x + 6, -H * 0.1).rotated(dir.angle()), fur.darkened(0.2), 4, true)
		"tuxedo", "bicolor", "tricolor", "calico":
			var belly := PackedVector2Array()
			for i in 17:
				var a := PI * i / 16.0
				belly.append(c + Vector2(cos(a) * L * 0.4, H * 0.12 + sin(a) * H * 0.33).rotated(dir.angle()))
			ci.draw_colored_polygon(belly, fur2)
			if pattern == "tricolor":
				D.ellipse(ci, c + Vector2(-L * 0.08, -H * 0.2).rotated(dir.angle()), L * 0.28, H * 0.28, fur3, false, 0.0)
			if pattern == "calico":
				D.ellipse(ci, c + Vector2(-L * 0.15, -H * 0.15).rotated(dir.angle()), L * 0.16, H * 0.24, fur2.lerp(fur3, 0.0), false, 0.0)
				D.ellipse(ci, c + Vector2(L * 0.12, -H * 0.22).rotated(dir.angle()), L * 0.12, H * 0.2, fur3, false, 0.0)
		"spots":
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			for i in 9:
				ci.draw_circle(c + Vector2(rng.randf_range(-L * 0.4, L * 0.4), rng.randf_range(-H * 0.35, H * 0.25)).rotated(dir.angle()), rng.randf_range(3.0, 6.0), fur2)
		"points":
			pass
	if accessory.get("style", "") == "sweater":
		var sw := PackedVector2Array()
		for i in 20:
			var a := -PI * 0.95 + PI * 0.9 * i / 19.0
			sw.append(c + Vector2(cos(a) * L * 0.42 + L * 0.06, sin(a) * H * 0.52).rotated(dir.angle()))
		for i in 20:
			var a := PI * 0.05 + PI * 0.9 * i / 19.0
			sw.append(c + Vector2(cos(a) * L * 0.42 + L * 0.06, sin(a) * H * 0.4).rotated(dir.angle()))
		var acol := Content.color(accessory.get("colors", {}).get("main", "#a8dcc8"))
		D.poly(ci, sw, acol, true, 0.1)
		for i in 3:
			var x := -L * 0.1 + i * L * 0.12
			ci.draw_line(c + Vector2(x, -H * 0.4).rotated(dir.angle()), c + Vector2(x, H * 0.3).rotated(dir.angle()), Content.color(accessory["colors"].get("trim", "#e8737f")), 3)
	# near legs
	_leg(ci, s["bl"], leg_w * 1.15, fur, paw)
	_leg(ci, s["fl"], leg_w, fur, paw)
	# neck connection
	var head: Vector2 = s["head"]
	D.taper(ci, s["sh"] + Vector2(0, -H * 0.1), head + Vector2(-4, 6), H * 0.62, H * 0.5, fur, false)
	_head(ci, b, p, s, fur, fur2, fur3, t, blink, accessory, sad)


static func _tail(ci: CanvasItem, b: Dictionary, p: Dictionary, s: Dictionary, fur: Color, fur2: Color, t: float) -> void:
	var root: Vector2 = s["tail_root"]
	var H: float = s["H"]
	var wag := pf(p, "wag")
	var base_a := pf(p, "tail_a", -0.9)   # radians, 0 = straight back
	var sway := sin(t * (12.0 if wag > 0.5 else 2.2)) * (0.45 * wag + 0.12)
	match b.get("tail", "long"):
		"short":
			D.taper(ci, root, root + Vector2(-H * 0.3, -H * 0.15).rotated(sway * 0.6), H * 0.28, H * 0.22, fur)
		"curly":
			var pts := PackedVector2Array()
			for i in 12:
				var k := float(i) / 11.0
				pts.append(root + Vector2(-k * H * 0.4, -k * H * 0.9).rotated(sway * 0.3) + Vector2(cos(k * 4.0) * 8, 0))
			for i in pts.size() - 1:
				D.taper(ci, pts[i], pts[i + 1], H * 0.32 * (1.0 - i / 14.0), H * 0.3 * (1.0 - (i + 1) / 14.0), fur if i < 9 else fur2, false)
		"pom":
			var tip := root + Vector2(-H * 0.4, -H * 0.8).rotated(sway)
			D.taper(ci, root, tip, H * 0.14, H * 0.1, fur)
			D.ellipse(ci, tip, H * 0.25, H * 0.25, fur2)
		_:
			var n := 9
			var prev := root
			var fluffy: bool = b.get("tail", "") == "fluffy"
			var curve := 0.0
			for i in n:
				var k := float(i + 1) / n
				curve += sway * 0.25 + 0.06
				var seg := Vector2(-cos(base_a + curve) * H * 0.2, sin(base_a + curve) * H * 0.2)
				var nxt := prev + seg
				var w := H * (0.24 if fluffy else 0.16) * (1.0 - k * 0.35)
				var col := fur if b.get("pattern", "") != "points" or k < 0.4 else fur2
				if b.get("pattern", "") == "tabby" and i % 2 == 1:
					col = fur.darkened(0.15)
				D.taper(ci, prev, nxt, w, w * 0.92, col, i == 0)
				prev = nxt


static func _head(ci: CanvasItem, b: Dictionary, p: Dictionary, s: Dictionary, fur: Color, fur2: Color, fur3: Color, t: float, blink: float, accessory: Dictionary, sad: bool) -> void:
	var species: String = b.get("species", "cat")
	var c: Vector2 = s["head"]
	var r := float(b.get("head_r", 24))
	var tilt: float = s["head_tilt"]
	var fwd := Vector2(1, 0).rotated(tilt)
	var dn := Vector2(0, 1).rotated(tilt)
	var ear: String = b.get("ear", "pointy")
	var ear_back := pf(p, "ears_back")
	var ear_col := fur if b.get("pattern") != "points" else fur2
	if b.get("pattern") == "tricolor":
		ear_col = fur3
	# far ear
	_ear(ci, ear, c - fwd * r * 0.05 - dn * r * 0.55, r, fwd, dn, ear_col.darkened(0.12), ear_back, true)
	# skull
	var head_col := fur
	D.ellipse(ci, c, r, r * 0.92, head_col, true, 0.1)
	if b.get("pattern") in ["tuxedo", "bicolor"]:
		D.ellipse(ci, c + fwd * r * 0.35 + dn * r * 0.35, r * 0.55, r * 0.45, fur2, false, 0.0)
	if b.get("pattern") == "points":
		D.ellipse(ci, c + fwd * r * 0.4 + dn * r * 0.15, r * 0.55, r * 0.5, fur2, false, 0.0)
	if b.get("pattern") == "tabby":
		for i in 3:
			ci.draw_line(c - dn * r * 0.85 + fwd * (i - 1) * 6, c - dn * r * 0.45 + fwd * (i - 1) * 5, fur.darkened(0.22), 3, true)
	# snout
	var sn := float(b.get("snout", 0.2))
	var snout_c := c + fwd * r * (0.7 + sn * 0.6) + dn * r * 0.28
	D.ellipse(ci, snout_c, r * (0.35 + sn * 0.55), r * 0.36, fur2 if b.get("pattern") in ["bicolor", "tuxedo", "tricolor", "fluffy", "curly"] else fur.lightened(0.12), true, 0.05)
	ci.draw_circle(snout_c + fwd * r * (0.3 + sn * 0.5) - dn * r * 0.08, r * 0.12, Color("#3a2a2e") if species == "dog" else Color("#f08aa0"))
	var mouth_open := pf(p, "mouth_open")
	if mouth_open > 0.3:
		D.ellipse(ci, snout_c + dn * r * 0.3, r * 0.2, r * 0.15 * mouth_open, Color("#c9506a"), false)
		if species == "dog" and pf(p, "tongue") > 0.5:
			D.ellipse(ci, snout_c + dn * r * 0.42 + fwd * 2, r * 0.12, r * 0.2, Color("#f28aa0"), false)
	else:
		ci.draw_arc(snout_c + dn * r * 0.12 + fwd * 2, r * 0.18, 0.2, PI - 0.4, 6, Color(0.25, 0.15, 0.15, 0.8), 2, true)
	if species == "cat":
		for k in 3:
			var wy := -0.06 + k * 0.08
			ci.draw_line(snout_c + dn * r * wy, snout_c + fwd * r * 0.9 + dn * r * (wy * 2.0 - 0.05), Color(1, 1, 1, 0.7), 1.2, true)
	# eye
	var ep := c + fwd * r * 0.38 - dn * r * 0.12
	var eyes: String = p.get("eyes", "open")
	var ec := Content.color(b.get("eyes", "#3a2a26"))
	if eyes == "closed" or blink > 0.5:
		ci.draw_arc(ep, r * 0.18, 0.2, PI - 0.2, 8, Color("#3a2a2e"), 2.5, true)
	elif eyes == "happy":
		ci.draw_arc(ep + dn * r * 0.12, r * 0.18, PI + 0.3, TAU - 0.3, 8, Color("#3a2a2e"), 2.5, true)
	else:
		D.ellipse(ci, ep, r * 0.2, r * 0.24, ec if species == "cat" else Color("#3a2a26"), false, 0.1)
		if species == "cat":
			D.ellipse(ci, ep + fwd * 1, r * 0.07, r * 0.19, Color("#2b2033"), false, 0.0)
		ci.draw_circle(ep - dn * r * 0.08 - fwd * r * 0.04, r * 0.07, Color.WHITE)
		if sad:
			ci.draw_line(ep - dn * r * 0.35 - fwd * r * 0.2, ep - dn * r * 0.28 + fwd * r * 0.2, Color("#3a2a2e"), 2, true)
	# near ear
	_ear(ci, ear, c + fwd * r * 0.12 - dn * r * 0.6, r, fwd, dn, ear_col, ear_back, false)
	if b.get("pattern") == "curly":
		for i in 5:
			ci.draw_circle(c - dn * r * 0.75 + fwd * (i - 2) * r * 0.22, r * 0.2, fur2)
	# accessory on head / neck
	var st: String = accessory.get("style", "")
	var ac: Dictionary = accessory.get("colors", {})
	var neck := c - fwd * r * 0.55 + dn * r * 0.8
	match st:
		"collar":
			D.taper(ci, neck - dn * r * 0.15 - fwd * 4, neck + dn * r * 0.25 + fwd * 8, r * 0.22, r * 0.22, Content.color(ac.get("main", "#e85d75")))
			ci.draw_circle(neck + dn * r * 0.38 + fwd * 8, r * 0.13, Content.color(ac.get("accent", "#f6d36b")))
		"bandana":
			D.poly(ci, PackedVector2Array([neck - dn * r * 0.2 - fwd * 6, neck + fwd * r * 0.5, neck + dn * r * 0.7 + fwd * 4]), Content.color(ac.get("main", "#6f97d6")))
			ci.draw_circle(neck + dn * r * 0.2 + fwd * 6, 2.5, Color.WHITE)
		"bow":
			var bp := c - dn * r * 0.8 - fwd * r * 0.1
			var bcol := Content.color(ac.get("main", "#f59ab8"))
			D.poly(ci, PackedVector2Array([bp, bp + Vector2(-10, -8), bp + Vector2(-10, 7)]), bcol)
			D.poly(ci, PackedVector2Array([bp, bp + Vector2(10, -8), bp + Vector2(10, 7)]), bcol)
			ci.draw_circle(bp, 3.5, bcol.darkened(0.15))


static func _ear(ci: CanvasItem, ear: String, base: Vector2, r: float, fwd: Vector2, dn: Vector2, col: Color, back: float, far: bool) -> void:
	var rot := -back * 0.9
	match ear:
		"floppy", "floppy_curly":
			var tip := base - fwd * r * 0.45 + dn * r * 0.95
			D.poly(ci, PackedVector2Array([base - fwd * r * 0.25, base + fwd * r * 0.2, tip + fwd * r * 0.1, tip - fwd * r * 0.25]), col.darkened(0.08), true, 0.1)
			if ear == "floppy_curly":
				for i in 3:
					ci.draw_circle(base.lerp(tip, 0.3 + i * 0.3) - fwd * 3, r * 0.2, col.lightened(0.05))
		_:
			var big := 1.25 if ear == "pointy_big" else 1.0
			var tip := base + (-dn * r * 0.75 * big - fwd * r * 0.1).rotated(rot)
			var pts := PackedVector2Array([base - fwd * r * 0.32, tip, base + fwd * r * 0.28])
			D.poly(ci, pts, col, true, 0.1)
			if not far:
				ci.draw_colored_polygon(PackedVector2Array([base - fwd * r * 0.18, base.lerp(tip, 0.75), base + fwd * r * 0.14]), Color("#f6b6c4"))


static func _curled(ci: CanvasItem, b: Dictionary, p: Dictionary, s: Dictionary, fur: Color, fur2: Color, fur3: Color, t: float, accessory: Dictionary) -> void:
	var L: float = s["L"]
	var H: float = s["H"]
	var breathe := 1.0 + sin(t * 1.8) * 0.025
	var c := Vector2(0, -H * 0.48)
	# tail wrapped around front
	var tail_pts := PackedVector2Array()
	for i in 14:
		var a := PI * 0.1 + PI * 0.85 * i / 13.0
		tail_pts.append(c + Vector2(cos(a) * L * 0.42, sin(a) * H * 0.55 + 4))
	for i in tail_pts.size() - 1:
		D.taper(ci, tail_pts[i], tail_pts[i + 1], H * 0.22, H * 0.22, fur.darkened(0.05) if b.get("pattern") != "points" else fur2, false)
	D.ellipse(ci, c, L * 0.42 * breathe, H * 0.55 * breathe, fur, true, 0.12)
	if b.get("pattern") == "tabby":
		for i in 4:
			ci.draw_arc(c + Vector2(-L * 0.05, H * 0.1), L * 0.12 + i * 8, PI * 1.15, PI * 1.6, 8, fur.darkened(0.2), 3, true)
	if b.get("pattern") == "spots":
		for i in 6:
			ci.draw_circle(c + Vector2(-L * 0.3 + i * L * 0.12, -H * 0.2 + (i % 2) * H * 0.2), 4, fur2)
	# head resting on the front
	var r := float(b.get("head_r", 24)) * 0.95
	var hc := c + Vector2(L * 0.3, H * 0.05)
	D.ellipse(ci, hc, r, r * 0.88, fur, true, 0.1)
	if b.get("pattern") in ["tuxedo", "bicolor", "points"]:
		D.ellipse(ci, hc + Vector2(r * 0.3, r * 0.3), r * 0.5, r * 0.4, fur2, false, 0.0)
	var ear_col := fur if b.get("pattern") != "points" else fur2
	if b.get("ear", "pointy").begins_with("floppy"):
		D.poly(ci, PackedVector2Array([hc + Vector2(-r * 0.3, -r * 0.5), hc + Vector2(r * 0.1, -r * 0.6), hc + Vector2(-r * 0.2, r * 0.4)]), ear_col.darkened(0.1))
	else:
		D.poly(ci, PackedVector2Array([hc + Vector2(-r * 0.4, -r * 0.55), hc + Vector2(-r * 0.15, -r * 1.25), hc + Vector2(r * 0.15, -r * 0.7)]), ear_col)
	ci.draw_arc(hc + Vector2(r * 0.35, -r * 0.05), r * 0.17, 0.2, PI - 0.2, 8, Color("#3a2a2e"), 2.5, true)
	ci.draw_circle(hc + Vector2(r * 0.9, r * 0.2), r * 0.11, Color("#3a2a2e") if b.get("species") == "dog" else Color("#f08aa0"))
	if accessory.get("style", "") == "collar":
		ci.draw_arc(hc + Vector2(-r * 0.2, r * 0.2), r * 0.85, PI * 0.4, PI * 0.8, 6, Content.color(accessory["colors"]["main"]), 5, true)
