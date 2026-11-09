class_name PetRig
extends RefCounted
## Cut-out ("paper doll") pets built from the owner's part sheets
## (assets/pets/parts/<species>/*.png + rig.json): body, 4 two-piece legs,
## 3-piece tail, head with 6 faces, ears, chest bib, collar and tag.
## The quadruped skeleton from PetPainter drives every part, so all poses,
## gaits and transitions are smooth and the size never jumps. Part images are
## never stretched: bones use the parts' own lengths (scale k only).

const FACE_NORMAL := 0
const FACE_HAPPY := 1
const FACE_CLOSED := 2
const FACE_SURPRISED := 3
const FACE_SAD := 4
const FACE_HOLD := 5

static var _rig: Dictionary = {}
static var _tex: Dictionary = {}


static func rig(sp: String) -> Dictionary:
	if _rig.is_empty():
		var f := FileAccess.open("res://assets/pets/parts/rig.json", FileAccess.READ)
		if f:
			var v: Variant = JSON.parse_string(f.get_as_text())
			if typeof(v) == TYPE_DICTIONARY:
				_rig = v
	return _rig.get(sp, {})


static func tex(sp: String, name: String) -> Texture2D:
	var path := "res://assets/pets/parts/%s/%s.png" % [sp, name]
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


static func v2(a: Variant) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


## Transform placing texture point `pivot` at `at`, rotated by `rot`, scaled by k.
static func place(at: Vector2, rot: float, k: float, pivot: Vector2) -> Transform2D:
	return Transform2D(rot, Vector2(k, k), 0.0, at) * Transform2D(0.0, Vector2.ONE, 0.0, -pivot)


## Transform mapping texture axis a0->a1 onto world p0->dir (no stretching).
static func along(a0: Vector2, a1: Vector2, p0: Vector2, dir_angle: float, k: float) -> Transform2D:
	return place(p0, dir_angle - (a1 - a0).angle(), k, a0)


static func _blit(ci: CanvasItem, bx: Transform2D, xf: Transform2D, t: Texture2D, mod := Color.WHITE) -> void:
	if t == null:
		return
	ci.draw_set_transform_matrix(bx * xf)
	ci.draw_texture(t, Vector2.ZERO, mod)


static func face_for(b: Dictionary, p: Dictionary, blink: float, sad: bool) -> int:
	if pf(p, "hold_toy") > 0.5 and b.get("parts", "") == "dog":
		return FACE_HOLD
	var eyes: String = p.get("eyes", "open")
	if pf(p, "curl") > 0.5 or eyes == "closed" or blink > 0.5:
		return FACE_CLOSED
	if eyes == "surprised":
		return FACE_SURPRISED
	if eyes == "happy" or pf(p, "mouth_open") > 0.3 or pf(p, "wag") > 0.9:
		return FACE_HAPPY
	if sad:
		return FACE_SAD
	return FACE_NORMAL


static func pf(p: Dictionary, k: String, d := 0.0) -> float:
	return float(p.get(k, d))


## Everything a frame needs: part transforms in pet-local space.
static func solve(b: Dictionary, p: Dictionary, s: Dictionary, t: float, gait: float, walk_w: float) -> Dictionary:
	var sp: String = b.get("parts", "dog")
	var r := rig(sp)
	var k := float(r.get("k", 0.2))
	var body: Dictionary = r["body"]
	var root_f: Vector2 = s["fl"]["root"]
	var root_b: Vector2 = s["bl"]["root"]
	var sh := v2(body["shoulder"])
	var hp := v2(body["hip"])
	var phi := (root_f - root_b).angle()
	var body_rot := phi - (sh - hp).angle()
	var Tb := place(root_b, body_rot, k, hp)
	var curl := pf(p, "curl") > 0.5
	var lying := curl or pf(p, "body_y", 99.0) < float(b.get("body_h", 40)) * 0.6
	if lying:
		# breathing: the chest rises and falls
		var br := sin(t * 1.7) * 0.025
		var bottom := Vector2(hp.x, 205.0)
		Tb = Tb * Transform2D(0.0, Vector2(1.0, 1.0 + br), 0.0, Vector2(0.0, -bottom.y * br))
	var out := {"k": k, "Tb": Tb, "phi": phi, "sp": sp}
	# legs
	var legs := {}
	for leg in ["fl", "fr", "bl", "br"]:
		var front: bool = leg.begins_with("f")
		var ax: Dictionary = r[leg]
		var a0 := v2(ax["up"][0])
		var a1 := v2(ax["up"][1])
		var b0 := v2(ax["low"][0])
		var b1 := v2(ax["low"][1])
		var lu := a0.distance_to(a1) * k
		var ll := b0.distance_to(b1) * k
		var root: Vector2 = s[leg]["root"]
		if leg.ends_with("r"):
			root += Vector2(5.0 if front else -4.0, -2.0).rotated(phi)
		var knee: Vector2
		var end: Vector2
		if lying:
			# folded neatly: front paws stretched forward under the chin,
			# back legs tucked along the belly with the paw pointing forward
			var g := -ll * 0.22
			if front:
				knee = Vector2(root.x + lu * 0.35, minf(root.y + lu * 0.9, g - ll * 0.05))
				end = knee + Vector2(ll, 0.0).rotated(-0.08)
			else:
				knee = root + Vector2(lu * 0.82, lu * 0.5)
				knee.y = minf(knee.y, g - 2.0)
				end = knee + Vector2(ll, 0.0).rotated(0.05)
			if leg.ends_with("r"):
				knee.x += 6.0
				end.x += 8.0
		else:
			var foot: Vector2 = s[leg]["foot"]
			knee = PetPainter.ik(root, foot, lu, ll, 1.0 if front else -1.0)
			var dir_l := foot - knee
			end = knee + dir_l.normalized() * ll if dir_l.length() > 0.01 else knee + Vector2(0, ll)
		legs[leg] = {"up": along(a0, a1, root, (knee - root).angle(), k), "low": along(b0, b1, knee, (end - knee).angle(), k),
			"knee": knee, "cap": Color(String(ax.get("cap", "#e8c9ad"))), "cap_r": float(ax.get("cap_r", 30.0)) * k}
	out["legs"] = legs
	# tail: 3 pieces following the pose's tail angle, wagging
	var wag := pf(p, "wag")
	var sway := sin(t * (12.0 if wag > 0.5 else 2.2)) * (0.45 * wag + 0.1)
	var base_a := pf(p, "tail_a", -0.9)
	if curl:
		base_a = 0.15
	var troot: Vector2 = Tb * v2(body["tail"])
	var tails := []
	var pos := troot
	var ang := base_a + sway * 0.3
	var bend := -0.32 if sp == "dog" else -0.18   # dog tail curls up, cat tail a soft S
	var ts := 0.85
	for i in 3:
		var nm := "tail_%d" % i
		var axis: Array = r[nm]
		var t0 := v2(axis[0])
		var t1 := v2(axis[1])
		var seg_len := t0.distance_to(t1) * k * ts
		var d := Vector2(-cos(ang), sin(ang)).rotated(phi)
		if pos.y + d.y * seg_len > -5.0:
			d = Vector2(-1.0, -0.05).normalized()   # rest on the floor, never through it
		tails.append(along(t0, t1, pos, d.angle(), k * ts))
		pos += d * seg_len * 0.78
		ang += (bend if not curl else 0.5) + sway * (0.35 + i * 0.2)
	out["tail"] = tails
	# head: rides on the neck, moves with the pose's head offset, tilts
	var hd: Dictionary = r["head"]
	var neck: Vector2 = Tb * v2(body["neck"])
	var L := float(b.get("body_len", 60))
	var H := float(b.get("body_h", 36))
	var stand_head: Vector2 = s["sh"] + Vector2(L * 0.16, -H * 0.75)
	var delta: Vector2 = s["head"] - stand_head
	if curl:
		delta += Vector2(L * 0.12, H * 0.55)
	var head_at := neck + delta * 0.9
	var head_rot := pf(p, "head_tilt") * 0.75 + body_rot * 0.45 + (0.12 if curl else 0.0)
	var Th := place(head_at, head_rot, k, v2(hd["pivot"]))
	out["neck"] = neck
	out["head_at"] = head_at
	out["Th"] = Th
	out["mouth"] = Th * v2(hd["mouth"])
	# ears
	var ear_sway := sin(gait * TAU * 2.0) * 0.14 * walk_w + sin(t * 1.3) * 0.04 - pf(p, "ears_back") * 0.5
	if sp == "cat":
		ear_sway = -pf(p, "ears_back") * 0.5 + (0.18 if fmod(t, 5.3) < 0.18 else 0.0)
	out["ear_near"] = Th * place(v2(hd["ear_near"]), ear_sway, 1.0, v2(r["ear_near"]["pivot"]))
	out["ear_far"] = Th * place(v2(hd["ear_far"]), ear_sway * 0.7, 1.0, v2(r["ear_far"]["pivot"]))
	return out


static func draw(ci: CanvasItem, b: Dictionary, p: Dictionary, s: Dictionary, bx: Transform2D, t: float, blink: float, sad: bool, accessory: Dictionary, gait: float, walk_w: float, wet: float) -> bool:
	var sp: String = b.get("parts", "")
	var r := rig(sp)
	if r.is_empty() or tex(sp, "body") == null:
		return false
	var o := solve(b, p, s, t, gait, walk_w)
	var k: float = o["k"]
	var Tb: Transform2D = o["Tb"]
	var tint := Color(0.86, 0.92, 1.0) if wet > 0.1 else Color.WHITE
	var far := Color(tint.r * 0.84, tint.g * 0.82, tint.b * 0.84)
	var legs: Dictionary = o["legs"]
	# shadow under the body
	ci.draw_set_transform_matrix(bx)
	DrawUtil.shadow(ci, Vector2((s["fl"]["foot"].x + s["bl"]["foot"].x) * 0.5, -2.0), float(b.get("body_len", 60)) * 0.62, 8.0, 0.18)
	# tail (behind everything): tip first, base last
	var tails: Array = o["tail"]
	for i in [2, 1, 0]:
		_blit(ci, bx, tails[i], tex(sp, "tail_%d" % i), tint)
	# far legs
	for leg in ["br", "fr"]:
		_draw_leg(ci, bx, sp, leg, legs[leg], far)
	# neck filler (when the head reaches down/up away from the neck socket)
	var neck: Vector2 = o["neck"]
	var head_at: Vector2 = o["head_at"]
	if neck.distance_to(head_at) > 4.0:
		ci.draw_set_transform_matrix(bx)
		var fur := Content.color(b.get("fur", "#d9904a"))
		DrawUtil.taper(ci, neck + Vector2(0, 6.0 * k * 5.0), head_at, 60.0 * k, 50.0 * k, fur, false)
	# body
	_blit(ci, bx, Tb, tex(sp, "body"), tint)
	# near legs
	for leg in ["bl", "fl"]:
		_draw_leg(ci, bx, sp, leg, legs[leg], tint)
	# chest bib + collar
	var bd: Dictionary = r["body"]
	_blit(ci, bx, Tb * place(v2(bd["chest"]), 0.0, 1.0, v2(r["chest"]["pivot"])), tex(sp, "chest"), tint)
	_draw_collar(ci, bx, Tb, r, sp, accessory, tint, t)
	# head with ears
	_blit(ci, bx, o["ear_far"], tex(sp, r["ear_far"].get("tex", "ear_far")), far)
	var face := face_for(b, p, blink, sad)
	_blit(ci, bx, o["Th"], tex(sp, "head_%d" % face), tint)
	_blit(ci, bx, o["ear_near"], tex(sp, r["ear_near"].get("tex", "ear_near")), tint)
	if accessory.get("style", "") == "bow" and sp == "dog":
		_blit(ci, bx, o["Th"] * place(v2(r["head"]["ear_near"]) + Vector2(40, -20), 0.2, 0.45, Vector2(86, 60)), tex("cat", "collar"), Content.color(accessory.get("colors", {}).get("main", "#f59ab8")).lerp(Color.WHITE, 0.4))
	if wet > 0.1:
		ci.draw_set_transform_matrix(bx)
		var c: Vector2 = Tb * Vector2(200, 80)
		for j in 6:
			var bp := c + Vector2(sin(t * 2.0 + j) * 30.0, -40.0 - fmod(t * 20.0 + j * 9.0, 40.0))
			ci.draw_circle(bp, 5 + (j % 3) * 2, Color(1, 1, 1, 0.7 * wet))
	return true


## Lower part, a round "joint" of matching fur, then the upper part on top:
## the two pieces read as one continuous leg.
static func _draw_leg(ci: CanvasItem, bx: Transform2D, sp: String, leg: String, d: Dictionary, mod: Color) -> void:
	_blit(ci, bx, d["low"], tex(sp, leg + "_low"), mod)
	ci.draw_set_transform_matrix(bx)
	var c: Color = d["cap"]
	ci.draw_circle(d["knee"], d["cap_r"] * 0.92, Color(c.r * mod.r, c.g * mod.g, c.b * mod.b))
	_blit(ci, bx, d["up"], tex(sp, leg + "_up"), mod)


# ---------------------------------------------------------------- front / back / in arms
## Walking toward / away from the player and sitting in the girl's arms use the
## owner's ready pictures (views.json), scaled to the same height as the
## side-view pet, so the size stays the same when the pet turns.

static var _views: Dictionary = {}
static var _side_h: Dictionary = {}


static func views(sp: String) -> Dictionary:
	if _views.is_empty():
		var f := FileAccess.open("res://assets/pets/parts/views.json", FileAccess.READ)
		if f:
			var v: Variant = JSON.parse_string(f.get_as_text())
			if typeof(v) == TYPE_DICTIONARY:
				_views = v
	return _views.get(sp, {})


## Height of the standing side-view pet (floor to the top of the head), pet-local units.
static func side_height(b: Dictionary) -> float:
	var sp: String = b.get("parts", "dog")
	if not _side_h.has(sp):
		var st := {"body_y": float(b.get("leg_len", 40)) + float(b.get("body_h", 36)) * 0.35}
		var s := PetPainter.skeleton(b, st, 0.0, 0.0, false)
		var o := solve(b, st, s, 0.0, 0.0, 0.0)
		var th: Transform2D = o["Th"]
		var ht := tex(sp, "head_0")
		var top := 0.0
		if ht:
			for x in [0.3, 0.5, 0.7]:
				top = minf(top, (th * Vector2(ht.get_width() * x, 0.0)).y)
		_side_h[sp] = -top
	return _side_h[sp]


## Draws a ready picture: "front" / "back" walk frames (by gait) or "arms".
static func draw_view(ci: CanvasItem, b: Dictionary, anim: String, gait: float, bx: Transform2D, height_k := 0.95, mod := Color.WHITE) -> bool:
	var sp: String = b.get("parts", "")
	var frames: Array = views(sp).get(anim, [])
	if frames.is_empty():
		return false
	var i := 0
	if frames.size() > 1:
		i = int(floor(fmod(gait, 1.0) * frames.size())) % frames.size()
	var t := tex(sp, "view_%s_%d" % [anim, i])
	if t == null:
		return false
	var hmax := 0.0
	for f in frames:
		hmax = maxf(hmax, float(f["h"]))
	var k := side_height(b) * height_k / hmax
	var fm: Dictionary = frames[i]
	ci.draw_set_transform_matrix(bx * Transform2D(0.0, Vector2(k, k), 0.0, Vector2.ZERO))
	if anim != "arms":
		DrawUtil.shadow(ci, Vector2(0, -2.0 / k), float(fm["w"]) * 0.42, 14.0, 0.18)
	ci.draw_texture(t, Vector2(-float(fm["ox"]), -float(fm["oy"])), mod)
	return true


static func _draw_collar(ci: CanvasItem, bx: Transform2D, Tb: Transform2D, r: Dictionary, sp: String, accessory: Dictionary, tint: Color, t: float) -> void:
	var bd: Dictionary = r["body"]
	var st: String = accessory.get("style", "")
	var col := Color.WHITE
	if st in ["collar", "bandana"]:
		col = Content.color(accessory.get("colors", {}).get("main", "#ffffff")).lerp(Color.WHITE, 0.35)
	var cs := float(r["collar"].get("scale", 0.7))
	if st == "bandana":
		ci.draw_set_transform_matrix(bx * Tb)
		var c := v2(bd["collar"])
		var acol := Content.color(accessory.get("colors", {}).get("main", "#6f97d6"))
		DrawUtil.poly(ci, PackedVector2Array([c + Vector2(-60, -6), c + Vector2(50, -14), c + Vector2(10, 70)]), acol, true, 0.1)
		ci.draw_circle(c + Vector2(0, 20), 6, Color.WHITE)
		return
	_blit(ci, bx, Tb * place(v2(bd["collar"]), 0.15, cs, v2(r["collar"]["pivot"])), tex(sp, "collar"), Color(tint.r * col.r, tint.g * col.g, tint.b * col.b))
	var sw := sin(t * 2.5) * 0.12
	_blit(ci, bx, Tb * place(v2(bd["tag"]), sw, 0.55, v2(r["tag"]["pivot"])), tex(sp, "tag"), tint)
