class_name GirlPainter
extends RefCounted
## Layered 2D skeleton for the girl, drawn procedurally (vector) so it stays
## sharp at 2x zoom. Joints are computed from pose params (FK) and, for feet,
## 2-bone IK: walking feet are planted on the floor during stance (no foot
## sliding), seated feet reach for the floor or dangle naturally.
## Clothes, hair and accessories are attached to the same joints, so every
## outfit follows bones in every pose (sit, sleep, carry).

const D := preload("res://scripts/core/draw_util.gd")

const THIGH := 50.0
const SHIN := 48.0
const FOOT := 20.0
const TORSO := 58.0
const NECK := 9.0
const HEAD_R := 31.0
const UARM := 37.0
const FARM := 35.0
const STAND_HIP := 104.0
const STRIDE := 46.0
const STANCE := 0.56


static func pf(p: Dictionary, k: String, d := 0.0) -> float:
	return float(p.get(k, d))


static func ik(root: Vector2, target: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var d := root.distance_to(target)
	d = clampf(d, absf(l1 - l2) + 0.01, l1 + l2 - 0.01)
	var dir := (target - root).normalized()
	var a := acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
	return root + dir.rotated(-a * bend) * l1


static func dir_of(angle: float) -> Vector2:
	# 0 = straight down, + = forward (toward +x)
	return Vector2(sin(angle), cos(angle))


## Compute joints in body space (facing +x, ground at y=0).
static func joints(p: Dictionary, gait_phase: float, walk_w: float, seat_lift: float) -> Dictionary:
	var j := {}
	var bob := -absf(sin(gait_phase * TAU)) * 3.0 * walk_w
	var hip := Vector2(0, -pf(p, "hip_h", STAND_HIP) + bob * (1.0 - pf(p, "sit_ik")))
	var rot := pf(p, "body_rot")
	var lean := pf(p, "lean")
	j["hip"] = hip
	var torso_dir := Vector2(0, -1).rotated(lean + rot)
	var shoulder := hip + torso_dir * TORSO
	j["shoulder"] = shoulder
	j["neck"] = shoulder + torso_dir * NECK
	j["head"] = j["neck"] + torso_dir.rotated(pf(p, "head")) * (HEAD_R - 4.0)
	j["head_rot"] = lean + rot + pf(p, "head")
	# legs
	for side in ["f", "b"]:
		var th := pf(p, "thigh_" + side)
		var sh := pf(p, "shin_" + side)
		var knee := hip + dir_of(th).rotated(rot) * THIGH
		var ankle := knee + dir_of(sh).rotated(rot) * SHIN
		if pf(p, "sit_ik") > 0.5:
			# seated: knee from thigh, shin reaches toward the floor (y = seat_lift)
			var drop := seat_lift - knee.y
			if drop >= SHIN:
				ankle = knee + Vector2(0.06 * SHIN, SHIN)
			else:
				var ang := acos(clampf(max(drop, 4.0) / SHIN, -1.0, 1.0))
				ankle = knee + Vector2(sin(ang) * SHIN, cos(ang) * SHIN)
		if walk_w > 0.001 and rot == 0.0:
			var ph := fmod(gait_phase + (0.0 if side == "f" else 0.5), 1.0)
			var fx: float
			var fy := 0.0
			if ph < STANCE:
				fx = lerpf(STRIDE * 0.5, -STRIDE * 0.5, ph / STANCE)
			else:
				var s := (ph - STANCE) / (1.0 - STANCE)
				fx = lerpf(-STRIDE * 0.5, STRIDE * 0.5, s)
				fy = -sin(s * PI) * 13.0
			var foot_t := Vector2(fx + 4.0, fy - 6.0)
			var knee_w := ik(hip, foot_t, THIGH, SHIN, 1.0)
			knee = knee.lerp(knee_w, walk_w)
			ankle = ankle.lerp(foot_t, walk_w)
		j["knee_" + side] = knee
		j["ankle_" + side] = ankle
		j["toe_" + side] = ankle + Vector2(FOOT, 2).rotated(rot * (1.0 - pf(p, "sit_ik")))
	# arms
	var swing := sin(gait_phase * TAU) * 0.38 * walk_w
	for side in ["f", "b"]:
		var sgn := 1.0 if side == "f" else -1.0
		var ua := pf(p, "arm_%s_u" % side) - swing * sgn
		var la := pf(p, "arm_%s_l" % side) - swing * sgn * 0.6
		var sh_pt: Vector2 = shoulder + Vector2(-2.0 * sgn, 4).rotated(lean + rot)
		var elbow := sh_pt + dir_of(ua).rotated(lean + rot) * UARM
		var hand := elbow + dir_of(la).rotated(lean + rot) * FARM
		j["sh_" + side] = sh_pt
		j["elbow_" + side] = elbow
		j["hand_" + side] = hand
	return j


static func draw(ci: CanvasItem, p: Dictionary, app: Dictionary, outfit: Dictionary, view: String, facing: float, gait: float, walk_w: float, seat_lift: float, blink: float, origin := Vector2.ZERO, base := Transform2D.IDENTITY) -> Dictionary:
	var skin := Content.color(app.get("skin", "#fde3d3"))
	var hair_c := Content.color(app.get("hair_color", "#6b4532"))
	var eye_c := Content.color(app.get("eye_color", "#5a7fc2"))
	var oc: Dictionary = outfit.get("outfit", {}).get("colors", {})
	var main := Content.color(oc.get("main", "#f59ab8"))
	var accent := Content.color(oc.get("accent", "#ffffff"))
	var trim := Content.color(oc.get("trim", "#e06f97"))
	var style: String = outfit.get("outfit", {}).get("style", "dress")
	var shoe_c := Content.color(outfit.get("shoes", {}).get("colors", {}).get("main", "#f07fa3"))
	var j := joints(p, gait, walk_w, seat_lift)
	ci.draw_set_transform_matrix(base * Transform2D(0.0, Vector2(facing, 1.0), 0.0, origin))
	if view == "side":
		_side(ci, p, j, app, outfit, skin, hair_c, eye_c, main, accent, trim, style, shoe_c, blink)
	else:
		_frontback(ci, p, j, app, outfit, skin, hair_c, eye_c, main, accent, trim, style, shoe_c, blink, view == "back", seat_lift)
	ci.draw_set_transform_matrix(base)
	return j


static func _side(ci: CanvasItem, p: Dictionary, j: Dictionary, app: Dictionary, outfit: Dictionary, skin: Color, hair_c: Color, eye_c: Color, main: Color, accent: Color, trim: Color, style: String, shoe_c: Color, blink: float) -> void:
	var skin_b := skin.darkened(0.1)
	var long_pants := style in ["pajama", "overall"]
	var leg_col_b := main.darkened(0.12) if long_pants else skin_b
	var leg_col_f := main if long_pants else skin
	var rot := pf(p, "body_rot")
	var hold: String = p.get("hold", "")
	var hair_style: String = app.get("hair_style", "long")
	# back hair (behind everything)
	_hair_back(ci, j, hair_style, hair_c, rot, pf(p, "lean"))
	if outfit.get("accessory", {}).get("style", "") == "backpack":
		var ac: Dictionary = outfit["accessory"].get("colors", {})
		var bp: Vector2 = (j["shoulder"] + j["hip"]) * 0.5 + Vector2(-20, 0).rotated(rot + pf(p, "lean"))
		D.rrect(ci, Rect2(bp - Vector2(16, 24), Vector2(28, 46)), 10, Content.color(ac.get("main", "#8ccfb8")))
	# back arm
	D.taper(ci, j["sh_b"], j["elbow_b"], 13, 11, skin_b if style in ["dress", "gown"] else main.darkened(0.12))
	D.taper(ci, j["elbow_b"], j["hand_b"], 11, 9, skin_b)
	ci.draw_circle(j["hand_b"], 7, skin_b)
	# back leg
	D.taper(ci, j["hip"] + Vector2(-4, 0), j["knee_b"], 17, 13, leg_col_b)
	D.taper(ci, j["knee_b"], j["ankle_b"], 13, 10, leg_col_b if style == "pajama" else skin_b)
	_shoe(ci, j["ankle_b"], j["toe_b"], shoe_c.darkened(0.15), outfit)
	# torso
	var lean := pf(p, "lean") + rot
	var up := Vector2(0, -1).rotated(lean)
	var rt := up.orthogonal() * -1.0  # forward
	var sh: Vector2 = j["shoulder"]
	var hp: Vector2 = j["hip"]
	var torso := PackedVector2Array([sh + rt * 15 + up * 2, sh - rt * 16 + up * 2, hp - rt * 19, hp + rt * 17])
	D.poly(ci, torso, main, true, 0.15)
	# skirt / pants top
	match style:
		"dress", "sweater":
			var sk_len := 46.0
			var skirt := PackedVector2Array([hp - rt * 17 + up * 8, hp + rt * 16 + up * 8, hp + rt * 30 - up * sk_len, hp - rt * 28 - up * sk_len])
			if pf(p, "sit_ik") > 0.5 or rot != 0.0:
				# seated: skirt drapes over the thighs
				var kf: Vector2 = j["knee_f"]
				skirt = PackedVector2Array([hp - rt * 17 + up * 8, hp + rt * 12 + up * 10, kf + Vector2(6, -10).rotated(rot), kf + Vector2(6, 10).rotated(rot), hp - rt * 20 - up * 14])
			D.poly(ci, skirt, main if style == "dress" else trim, true, 0.12)
			var hem_a: Vector2 = skirt[skirt.size() - 2]
			var hem_b: Vector2 = skirt[skirt.size() - 3] if skirt.size() > 4 else skirt[2]
			ci.draw_line(hem_a, hem_b, accent, 4, true)
		"gown":
			var kf2: Vector2 = j["ankle_f"]
			var g := PackedVector2Array([hp - rt * 18 + up * 8, hp + rt * 18 + up * 8, Vector2(max(kf2.x, hp.x) + 34, kf2.y - 4), Vector2(min(j["ankle_b"].x, hp.x) - 34, kf2.y - 4)])
			if pf(p, "sit_ik") > 0.5 or rot != 0.0:
				var kf: Vector2 = j["knee_f"]
				g = PackedVector2Array([hp - rt * 18 + up * 8, hp + rt * 12 + up * 10, kf + Vector2(10, -12).rotated(rot), kf + Vector2(4, 26).rotated(rot), hp - rt * 24 - up * 24])
			D.poly(ci, g, main, true, 0.12)
			for i in 3:
				var a: Vector2 = g[0].lerp(g[3], 0.35 + i * 0.2)
				var b: Vector2 = g[1].lerp(g[2], 0.35 + i * 0.2)
				ci.draw_line(a, b, Color(accent, 0.6), 2, true)
		"overall":
			ci.draw_line(sh + rt * 6, hp + rt * 10, trim, 4, true)
			D.rrect(ci, Rect2(hp + rt * -12 - up * 2 + Vector2(-4, -18), Vector2(30, 22)), 4, main.darkened(0.05))
	# front leg
	D.taper(ci, hp + rt * 4, j["knee_f"], 18, 14, leg_col_f)
	D.taper(ci, j["knee_f"], j["ankle_f"], 14, 10, leg_col_f if style == "pajama" else skin)
	if style in ["dress", "sweater"] and pf(p, "sit_ik") < 0.5 and rot == 0.0:
		# redraw skirt front panel so it covers the front thigh top
		var skirt2 := PackedVector2Array([hp - rt * 6 + up * 8, hp + rt * 16 + up * 8, hp + rt * 30 - up * 46, hp - rt * 4 - up * 46])
		D.poly(ci, skirt2, main.lightened(0.04) if style == "dress" else trim.lightened(0.04), false, 0.12)
		ci.draw_line(hp + rt * 30 - up * 46, hp - rt * 28 - up * 46, accent, 4, true)
	_shoe(ci, j["ankle_f"], j["toe_f"], shoe_c, outfit)
	# collar / details
	ci.draw_circle(sh + rt * 2 + up * 1, 9, accent)
	if style == "sweater":
		for i in 3:
			ci.draw_line(sh.lerp(hp, 0.3 + i * 0.2) - rt * 12, sh.lerp(hp, 0.3 + i * 0.2) + rt * 12, accent, 3, true)
	if style == "pajama":
		for i in 3:
			ci.draw_circle(sh.lerp(hp, 0.25 + i * 0.25) + rt * 9, 3, accent)
	if outfit.get("accessory", {}).get("style", "") == "necklace":
		ci.draw_arc(sh + up * -4, 12, 0.3, PI - 0.3, 10, Content.color(outfit["accessory"]["colors"]["main"]), 2.5, true)
		ci.draw_circle(sh + up * -14 + rt * 2, 4, Content.color(outfit["accessory"]["colors"]["accent"]))
	# held item (between body and front arm)
	_held(ci, hold, j, p)
	# head
	_head_side(ci, j, p, app, skin, hair_c, eye_c, blink, hair_style, outfit)
	# front arm (in front of torso & held items)
	var sleeve := main if style != "dress" else skin
	if style == "gown":
		ci.draw_circle(j["sh_f"], 13, main.lightened(0.08))
	D.taper(ci, j["sh_f"], j["elbow_f"], 13, 11, sleeve)
	D.taper(ci, j["elbow_f"], j["hand_f"], 11, 9, skin if style in ["dress", "gown", "overall"] else main)
	ci.draw_circle(j["hand_f"], 7.5, skin)
	if style in ["dress", "overall"]:
		ci.draw_circle(j["sh_f"], 11, main.lightened(0.05))


static func _shoe(ci: CanvasItem, ankle: Vector2, toe: Vector2, col: Color, outfit: Dictionary) -> void:
	var boots: bool = outfit.get("shoes", {}).get("style", "") == "boots"
	if boots:
		D.taper(ci, ankle + (ankle - toe).normalized().rotated(-0.3) * 16, ankle, 13, 13, col)
	D.taper(ci, ankle + Vector2(-3, 1), toe, 12, 10, col)
	ci.draw_line(ankle + Vector2(-2, 6), toe + Vector2(2, 6), col.darkened(0.3), 2, true)


static func _held(ci: CanvasItem, hold: String, j: Dictionary, p: Dictionary) -> void:
	if hold == "":
		return
	var h: Vector2 = j["hand_f"]
	match hold:
		"book":
			var hb: Vector2 = (j["hand_f"] + j["hand_b"]) * 0.5
			D.rrect(ci, Rect2(hb + Vector2(-6, -26), Vector2(32, 26)), 3, Color("#8ec9e8"))
			D.rrect(ci, Rect2(hb + Vector2(-4, -24), Vector2(14, 22)), 2, Color("#ffffff"), false)
		"spoon":
			ci.draw_line(h, h + Vector2(14, -10), Color("#c7d3df"), 4, true)
			ci.draw_circle(h + Vector2(16, -12), 5, Color("#c7d3df"))
		"brush", "comb":
			D.rrect(ci, Rect2(h + Vector2(-4, -8), Vector2(26, 9)), 3, Color("#f7b9cf"))
		"pencil":
			ci.draw_line(h, h + Vector2(12, 10), Color("#f6d36b"), 4, true)
		"teaser":
			var tip := h + Vector2(70, -40)
			ci.draw_line(h, tip, Color("#c9a77a"), 4, true)
			var sway := sin(float(p.get("anim_t", 0.0)) * 6.0) * 14.0
			ci.draw_line(tip, tip + Vector2(14 + sway, 50), Color(0.4, 0.3, 0.3), 1.5, true)
			D.ellipse(ci, tip + Vector2(14 + sway, 56), 6, 10, Color("#f59ab8"), false)
		"ball":
			D.ellipse(ci, h + Vector2(6, -6), 14, 14, Color("#f26b6b"))
		"cup":
			D.rrect(ci, Rect2(h + Vector2(-4, -18), Vector2(16, 18)), 4, Color("#f4a6b7"))
		"shower":
			D.rrect(ci, Rect2(h + Vector2(-2, -10), Vector2(18, 14)), 4, Color("#9ad0ea"))
			for i in 4:
				ci.draw_line(h + Vector2(4 + i * 4, 6), h + Vector2(2 + i * 5, 26), Color(0.6, 0.85, 1.0, 0.7), 2)


static func _hair_back(ci: CanvasItem, j: Dictionary, style: String, col: Color, rot: float, lean: float) -> void:
	var head: Vector2 = j["head"]
	var hr: float = j["head_rot"]
	var down := Vector2(0, 1).rotated(hr)
	var back := Vector2(-1, 0).rotated(hr)
	match style:
		"long":
			var pts := PackedVector2Array([head + back * 20 + down * -18, head + back * 32 + down * 10, head + back * 26 + down * 78, head + back * 4 + down * 84, head + down * 30])
			D.poly(ci, pts, col.darkened(0.08), true, 0.15)
		"braids":
			for k in 2:
				var base := head + back * (8 + k * 14) + down * 18
				for s in 4:
					D.ellipse(ci, base + down * (s * 14) + back * 4, 8, 9, col.darkened(0.06 * k), true, 0.1)
				ci.draw_circle(base + down * 58 + back * 4, 6, Color("#f59ab8"))
		"ponytail":
			var root := head + back * 26 + down * -12
			var tip := root + back * 18 + down * 60
			D.taper(ci, root, root.lerp(tip, 0.5) + back * 6, 22, 18, col.darkened(0.06))
			D.taper(ci, root.lerp(tip, 0.5) + back * 6, tip, 18, 6, col.darkened(0.06))
		"bob":
			D.ellipse(ci, head + back * 8 + down * 10, HEAD_R + 6, HEAD_R + 2, col.darkened(0.08), true, 0.1)
		"buns":
			D.ellipse(ci, head + back * 10 + down * 14, HEAD_R + 2, HEAD_R - 2, col.darkened(0.08), true, 0.1)


static func _head_side(ci: CanvasItem, j: Dictionary, p: Dictionary, app: Dictionary, skin: Color, hair_c: Color, eye_c: Color, blink: float, hair_style: String, outfit: Dictionary) -> void:
	var c: Vector2 = j["head"]
	var hr: float = j["head_rot"]
	var fwd := Vector2(1, 0).rotated(hr)
	var down := Vector2(0, 1).rotated(hr)
	# neck
	D.taper(ci, j["shoulder"], j["neck"] + down * 2, 12, 11, skin.darkened(0.04))
	# face shape: slightly egg-shaped
	var face := D.ellipse_points(c, HEAD_R, HEAD_R * 1.04, 32)
	for i in face.size():
		var v := face[i] - c
		v = v.rotated(-hr)
		if v.x > 0 and v.y > 0:
			v.x *= 0.92
		face[i] = c + v.rotated(hr)
	D.poly(ci, face, skin, true, 0.08)
	# ear
	D.ellipse(ci, c - fwd * HEAD_R * 0.42 + down * 6, 6, 8, skin.darkened(0.05))
	# cheek
	ci.draw_circle(c + fwd * 16 + down * 12, 7, Color(1, 0.55, 0.6, 0.35))
	# eye
	var eyes: String = p.get("eyes", "open")
	var ep := c + fwd * 15 - down * 2
	if eyes == "closed" or blink > 0.5:
		ci.draw_arc(ep + down * 1, 7, 0.2, PI - 0.2, 10, Color("#4a3038"), 3, true)
	elif eyes == "happy":
		ci.draw_arc(ep + down * 4, 7, PI + 0.3, TAU - 0.3, 10, Color("#4a3038"), 3, true)
	else:
		D.ellipse(ci, ep, 7, 9, Color.WHITE, false)
		D.ellipse(ci, ep + fwd * 2, 5.5, 7.5, eye_c, false, 0.2)
		ci.draw_circle(ep + fwd * 2.5, 3.2, Color("#2b2033"))
		ci.draw_circle(ep + fwd * 1 - down * 3, 2.2, Color.WHITE)
		ci.draw_line(ep - down * 9 - fwd * 4, ep - down * 10 + fwd * 7, Color("#4a3038"), 2.5, true)
		ci.draw_line(ep - down * 8 + fwd * 7, ep - down * 11 + fwd * 11, Color("#4a3038"), 2, true)
	# brow
	ci.draw_line(ep - down * 15 - fwd * 3, ep - down * 16 + fwd * 7, hair_c.darkened(0.2), 2.5, true)
	# nose & mouth
	ci.draw_circle(c + fwd * (HEAD_R - 2) + down * 5, 2.5, skin.darkened(0.15))
	var mouth: String = p.get("mouth", "smile")
	var mp := c + fwd * 20 + down * 17
	match mouth:
		"open":
			D.ellipse(ci, mp, 4, 5, Color("#c9506a"), false)
		"o":
			ci.draw_circle(mp, 3.5, Color("#c9506a"))
		"chew":
			ci.draw_line(mp - fwd * 4, mp + fwd * 3, Color("#c9506a"), 3, true)
		_:
			ci.draw_arc(mp - down * 3, 6, 0.3, PI * 0.75, 8, Color("#c9506a"), 2.5, true)
	# front hair
	match hair_style:
		"bob", "long", "braids", "ponytail", "buns":
			var cap := PackedVector2Array()
			for i in 17:
				var a := PI * 0.92 + PI * 1.0 * i / 16.0
				cap.append(c + Vector2(cos(a), sin(a)).rotated(hr) * (HEAD_R + 3))
			cap.append(c + (fwd * 24 - down * 13))
			cap.append(c + (fwd * 12 - down * 15))
			cap.append(c + (fwd * 2 - down * 10))
			cap.append(c + (-fwd * 12 + down * 6))
			D.poly(ci, cap, hair_c, true, 0.12)
			ci.draw_arc(c - down * 6, HEAD_R - 6, PI * 1.2, PI * 1.6, 8, Color(1, 1, 1, 0.3), 3, true)
	if hair_style == "buns":
		for k in 2:
			D.ellipse(ci, c - down * (HEAD_R + 2) + fwd * (-14 + k * 22), 13, 13, hair_c, true, 0.1)
	# hat
	var hat: Dictionary = outfit.get("hat", {})
	if not hat.is_empty():
		_hat(ci, hat, c, fwd, down)
	if outfit.get("accessory", {}).get("style", "") == "glasses":
		var gc := Content.color(outfit["accessory"]["colors"]["main"])
		ci.draw_colored_polygon(D.heart_points(ep + fwd * 2, 9), Color(gc, 0.25))
		var hp := D.heart_points(ep + fwd * 2, 9)
		hp.append(hp[0])
		ci.draw_polyline(hp, gc, 2.5, true)
		ci.draw_line(ep - fwd * 6, c - fwd * 4, gc, 2, true)


static func _hat(ci: CanvasItem, hat: Dictionary, c: Vector2, fwd: Vector2, down: Vector2) -> void:
	var hc: Dictionary = hat.get("colors", {})
	var m := Content.color(hc.get("main", "#e85d75"))
	var a := Content.color(hc.get("accent", "#ffffff"))
	match hat.get("style", "bow"):
		"bow":
			var b := c - down * (HEAD_R - 2) - fwd * 6
			D.poly(ci, PackedVector2Array([b, b + Vector2(-16, -12).rotated(fwd.angle()), b + Vector2(-16, 10).rotated(fwd.angle())]), m)
			D.poly(ci, PackedVector2Array([b, b + Vector2(16, -12).rotated(fwd.angle()), b + Vector2(16, 10).rotated(fwd.angle())]), m)
			ci.draw_circle(b, 5, m.darkened(0.15))
		"crown":
			var base := c - down * (HEAD_R + 2)
			var pts := PackedVector2Array([base - fwd * 18, base - fwd * 18 - down * 18, base - fwd * 9 - down * 8, base - down * 22, base + fwd * 9 - down * 8, base + fwd * 18 - down * 18, base + fwd * 18])
			D.poly(ci, pts, m)
			ci.draw_circle(base - down * 8, 4, a)
		"beanie":
			var cap := PackedVector2Array()
			for i in 13:
				var ang := PI + PI * i / 12.0
				cap.append(c - down * 6 + Vector2(cos(ang), sin(ang)).rotated(fwd.angle()) * (HEAD_R + 5))
			D.poly(ci, cap, m)
			D.rrect(ci, Rect2(c - down * 10 - fwd * (HEAD_R + 4) - Vector2(0, 4), Vector2((HEAD_R + 4) * 2, 12)), 5, a)
			ci.draw_circle(c - down * (HEAD_R + 12), 8, a)
		"wreath":
			for i in 7:
				var ang := PI * 1.05 + PI * 0.9 * i / 6.0
				var p := c + Vector2(cos(ang), sin(ang)).rotated(fwd.angle()) * (HEAD_R + 1)
				ci.draw_circle(p, 6, m if i % 2 == 0 else a)


## Front / back views (symmetric). Used for mirror, window, wardrobe, desk, idle observe.
static func _frontback(ci: CanvasItem, p: Dictionary, j: Dictionary, app: Dictionary, outfit: Dictionary, skin: Color, hair_c: Color, eye_c: Color, main: Color, accent: Color, trim: Color, style: String, shoe_c: Color, blink: float, back: bool, seat_lift: float) -> void:
	var seated := pf(p, "sit_ik") > 0.5
	var hip_h := pf(p, "hip_h", STAND_HIP)
	var hip := Vector2(0, -hip_h)
	var sh := hip + Vector2(0, -TORSO)
	var head := sh + Vector2(0, -NECK - HEAD_R + 6)
	var hair_style: String = app.get("hair_style", "long")
	var long_pants := style in ["pajama", "overall"]
	var arm_raise := pf(p, "fb_arms")   # 0 down, 1 forward/up (reaching), 2 hands on hips
	if back and hair_style in ["long", "braids", "ponytail"]:
		pass
	# legs
	if not seated:
		for sx in [-1.0, 1.0]:
			var lh := hip + Vector2(sx * 9, 0)
			var foot := Vector2(sx * 12, -6)
			D.taper(ci, lh, foot, 17, 11, main if long_pants else skin)
			D.ellipse(ci, foot + Vector2(sx * 2, 2), 10, 7, shoe_c)
	else:
		for sx in [-1.0, 1.0]:
			var knee := hip + Vector2(sx * 12, 10)
			var foot := knee + Vector2(sx * 2, min(seat_lift + 10.0, SHIN))
			if not back:
				D.taper(ci, hip + Vector2(sx * 9, 0), knee, 18, 16, main if long_pants else skin)
				D.taper(ci, knee, foot, 14, 11, main if long_pants else skin)
				D.ellipse(ci, foot, 10, 7, shoe_c)
			else:
				D.ellipse(ci, foot + Vector2(sx * 4, 0), 9, 6, shoe_c.darkened(0.1))
	# back hair behind body for front view
	if not back:
		match hair_style:
			"long":
				D.poly(ci, PackedVector2Array([head + Vector2(-34, -6), head + Vector2(34, -6), head + Vector2(30, 80), head + Vector2(-30, 80)]), hair_c.darkened(0.1), true, 0.1)
			"braids":
				for sx in [-1.0, 1.0]:
					for s in 4:
						D.ellipse(ci, head + Vector2(sx * 30, 16 + s * 14), 8, 9, hair_c.darkened(0.05))
	# torso + skirt
	var torso := PackedVector2Array([sh + Vector2(-17, 0), sh + Vector2(17, 0), hip + Vector2(19, 0), hip + Vector2(-19, 0)])
	D.poly(ci, torso, main, true, 0.12)
	if style in ["dress", "sweater", "gown"]:
		var len := 44.0 if style != "gown" else (hip_h - 8.0 if not seated else 30.0)
		if seated:
			len = 26.0
		var skirt := PackedVector2Array([hip + Vector2(-19, -8), hip + Vector2(19, -8), hip + Vector2(34, len), hip + Vector2(-34, len)])
		D.poly(ci, skirt, main if style != "sweater" else trim, true, 0.12)
		ci.draw_line(hip + Vector2(-34, len), hip + Vector2(34, len), accent, 4, true)
	if outfit.get("accessory", {}).get("style", "") == "backpack" and back:
		D.rrect(ci, Rect2(sh + Vector2(-16, 6), Vector2(32, 46)), 10, Content.color(outfit["accessory"]["colors"]["main"]))
	# arms
	for sx in [-1.0, 1.0]:
		var s := sh + Vector2(sx * 17, 6)
		var e: Vector2
		var h: Vector2
		if arm_raise >= 1.5:  # hands on hips
			e = s + Vector2(sx * 20, 24)
			h = hip + Vector2(sx * 18, -6)
		elif arm_raise > 0.5:
			# reaching forward/up (front view: hands toward centre-up; back view: hidden by body partly)
			e = s + Vector2(sx * 10, -6 if back else 22)
			h = e + Vector2(-sx * 10, -26 if back else 14)
		else:
			e = s + Vector2(sx * 6, UARM)
			h = e + Vector2(sx * 2, FARM)
		var sleeve := skin if style in ["dress", "gown"] else main
		D.taper(ci, s, e, 13, 11, sleeve)
		D.taper(ci, e, h, 11, 9, skin)
		ci.draw_circle(h, 7, skin)
	# head
	D.taper(ci, sh, sh + Vector2(0, -NECK - 2), 13, 12, skin)
	if back:
		D.ellipse(ci, head, HEAD_R, HEAD_R * 1.03, hair_c, true, 0.12)
		ci.draw_arc(head + Vector2(0, -4), HEAD_R - 8, PI * 1.2, PI * 1.7, 8, Color(1, 1, 1, 0.25), 3, true)
		for sx in [-1.0, 1.0]:
			D.ellipse(ci, head + Vector2(sx * (HEAD_R - 2), 6), 5, 7, skin.darkened(0.06))
		match hair_style:
			"long":
				D.poly(ci, PackedVector2Array([head + Vector2(-30, 0), head + Vector2(30, 0), head + Vector2(28, 84), head + Vector2(-28, 84)]), hair_c.darkened(0.04), true, 0.15)
			"ponytail":
				D.taper(ci, head + Vector2(0, -8), head + Vector2(4, 70), 20, 8, hair_c.darkened(0.04))
			"braids":
				for sx in [-1.0, 1.0]:
					for s in 4:
						D.ellipse(ci, head + Vector2(sx * 16, 24 + s * 14), 8, 9, hair_c.darkened(0.05))
			"buns":
				for sx in [-1.0, 1.0]:
					D.ellipse(ci, head + Vector2(sx * 18, -HEAD_R + 2), 13, 13, hair_c)
	else:
		D.ellipse(ci, head, HEAD_R, HEAD_R * 1.04, skin, true, 0.08)
		for sx in [-1.0, 1.0]:
			var ep := head + Vector2(sx * 12, 0)
			if p.get("eyes", "open") == "closed" or blink > 0.5:
				ci.draw_arc(ep + Vector2(0, 1), 6, 0.2, PI - 0.2, 8, Color("#4a3038"), 3, true)
			elif p.get("eyes", "open") == "happy":
				ci.draw_arc(ep + Vector2(0, 4), 6, PI + 0.3, TAU - 0.3, 8, Color("#4a3038"), 3, true)
			else:
				D.ellipse(ci, ep, 6.5, 8.5, Color.WHITE, false)
				D.ellipse(ci, ep + Vector2(0, 1), 5, 7, eye_c, false, 0.2)
				ci.draw_circle(ep + Vector2(0, 1.5), 3, Color("#2b2033"))
				ci.draw_circle(ep + Vector2(-1.5, -2), 2, Color.WHITE)
			ci.draw_circle(head + Vector2(sx * 19, 13), 6, Color(1, 0.55, 0.6, 0.35))
			ci.draw_line(ep + Vector2(-5, -13), ep + Vector2(5, -14), hair_c.darkened(0.2), 2.5, true)
		var mouth: String = p.get("mouth", "smile")
		if mouth == "open" or mouth == "o":
			ci.draw_circle(head + Vector2(0, 17), 4, Color("#c9506a"))
		else:
			ci.draw_arc(head + Vector2(0, 13), 7, 0.4, PI - 0.4, 8, Color("#c9506a"), 2.5, true)
		# bangs
		var cap := PackedVector2Array()
		for i in 17:
			var a := PI + PI * i / 16.0
			cap.append(head + Vector2(cos(a) * (HEAD_R + 3), sin(a) * (HEAD_R + 3)))
		cap.append(head + Vector2(26, -8))
		cap.append(head + Vector2(10, -14))
		cap.append(head + Vector2(-6, -10))
		cap.append(head + Vector2(-24, -8))
		D.poly(ci, cap, hair_c, true, 0.1)
		if hair_style == "buns":
			for sx in [-1.0, 1.0]:
				D.ellipse(ci, head + Vector2(sx * 18, -HEAD_R + 2), 13, 13, hair_c)
		if outfit.get("accessory", {}).get("style", "") == "glasses":
			var gc := Content.color(outfit["accessory"]["colors"]["main"])
			for sx in [-1.0, 1.0]:
				var hp := D.heart_points(head + Vector2(sx * 12, 0), 9)
				hp.append(hp[0])
				ci.draw_polyline(hp, gc, 2.5, true)
	var hat: Dictionary = outfit.get("hat", {})
	if not hat.is_empty():
		_hat(ci, hat, head, Vector2(1, 0), Vector2(0, 1))
