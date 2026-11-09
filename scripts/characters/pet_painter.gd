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


static func draw(ci: CanvasItem, b: Dictionary, p: Dictionary, facing: float, gait: float, walk_w: float, running: bool, t: float, blink: float, accessory: Dictionary, origin := Vector2.ZERO, wet := 0.0, sad := false, base := Transform2D.IDENTITY, view := "side") -> Dictionary:
	var sc := float(b.get("scale", 1.0))
	var fur := Content.color(b.get("fur", "#f2a65a"))
	var fur2 := Content.color(b.get("fur2", "#ffffff"))
	var fur3 := Content.color(b.get("fur3", "#4a4040"))
	if wet > 0.0:
		fur = fur.darkened(0.18 * wet)
		fur2 = fur2.darkened(0.12 * wet)
	var s := skeleton(b, p, gait, walk_w, running)
	if b.has("sprites") and _draw_sprite(ci, b, p, facing * sc, sc, gait, walk_w, running, t, wet, origin, base):
		ci.draw_set_transform_matrix(base)
		return s
	ci.draw_set_transform_matrix(base * Transform2D(0.0, Vector2(facing * sc, sc), 0.0, origin))
	var curl := pf(p, "curl")
	if view != "side" and curl <= 0.5:
		_frontback(ci, b, p, fur, fur2, fur3, gait, walk_w, t, blink, accessory, view == "back", sad)
	elif curl > 0.5:
		_curled(ci, b, p, s, fur, fur2, fur3, t, accessory)
	else:
		_standing(ci, b, p, s, fur, fur2, fur3, t, blink, accessory, sad)
	if wet > 0.1:
		for i in 6:
			var bp: Vector2 = s["center"] + Vector2(sin(t * 2.0 + i) * s["L"] * 0.4, -s["H"] * 0.6 - fmod(t * 20.0 + i * 9.0, 40.0))
			ci.draw_circle(bp, 5 + (i % 3) * 2, Color(1, 1, 1, 0.7 * wet))
	ci.draw_set_transform_matrix(base)
	return s


# ---------------------------------------------------------------- picture pets
## Breeds with "sprites" are drawn from the owner's style sheet (assets/pets):
## walk / run cycles follow the gait phase, poses map from the pose name.

static var _spr_meta: Dictionary = {}
static var _spr_tex: Dictionary = {}

const SPRITE_POSE := {
	"stand": "stand", "observe": "stand", "sit": "sit", "watch": "sit", "bath": "sit", "held": "sit", "cradle": "sit",
	"lie": "lie", "rest": "lie", "curl": "sleep", "sleep": "sleep",
	"beg": "beg", "beg_up": "beg", "eat": "sniff", "sniff": "sniff", "drink": "sniff",
	"play": "play", "pounce": "play", "play_bow": "play", "chase": "play",
	"groom": "groom", "stretch": "stretch", "scratch": "stretch", "happy": "happy", "trick": "happy",
}
const SPRITE_FALLBACK := {
	"cat": {"beg": "purr", "happy": "purr", "sniff": "sniff", "bark": "purr"},
	"dog": {"groom": "sniff", "stretch": "happy", "purr": "happy"},
}


static func sprite_meta() -> Dictionary:
	if _spr_meta.is_empty():
		var f := FileAccess.open("res://assets/pets/sprites.json", FileAccess.READ)
		if f:
			var v: Variant = JSON.parse_string(f.get_as_text())
			if typeof(v) == TYPE_DICTIONARY:
				_spr_meta = v
	return _spr_meta


static func _sprite_tex(set_name: String, anim: String, i: int) -> Texture2D:
	var path := "res://assets/pets/%s/%s_%d.png" % [set_name, anim, i]
	if not _spr_tex.has(path):
		_spr_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _spr_tex[path]


static func sprite_anim(b: Dictionary, p: Dictionary, walk_w: float, running: bool) -> String:
	var set_name: String = b.get("sprites", "")
	var meta: Dictionary = sprite_meta().get(set_name, {})
	if walk_w > 0.3:
		return "run" if running and meta.has("run") else "walk"
	var anim: String = SPRITE_POSE.get(p.get("spr", "stand"), "stand")
	if pf(p, "curl") > 0.5:
		anim = "sleep"
	if not meta.has(anim):
		anim = SPRITE_FALLBACK.get(b.get("species", "cat"), {}).get(anim, "stand")
	if not meta.has(anim):
		anim = "stand"
	return anim


static func _draw_sprite(ci: CanvasItem, b: Dictionary, p: Dictionary, fx: float, sc: float, gait: float, walk_w: float, running: bool, t: float, wet: float, origin: Vector2, base: Transform2D) -> bool:
	var set_name: String = b.get("sprites", "")
	var meta: Dictionary = sprite_meta().get(set_name, {})
	if meta.is_empty():
		return false
	var anim := sprite_anim(b, p, walk_w, running)
	var frames: Array = meta[anim]
	var i := 0
	if anim in ["walk", "run"]:
		i = int(floor(fmod(gait, 1.0) * frames.size())) % frames.size()
	var tex := _sprite_tex(set_name, anim, i)
	if tex == null:
		return false
	var fm: Dictionary = frames[i]
	var stand_h := float(meta["stand"][0]["h"])
	var k := float(b.get("sprite_h", 120)) / stand_h
	var sy := 1.0
	var bob := 0.0
	match anim:
		"sleep", "lie":
			sy = 1.0 + sin(t * 1.7) * 0.025      # breathing
		"stand", "sit", "beg", "purr":
			bob = sin(t * 2.2) * 1.2
		"play":
			bob = -absf(sin(t * 6.0)) * 6.0
	if bool(fm.get("flip", false)):
		fx = -fx   # this picture faces left on the sheet
	var xf := base * Transform2D(0.0, Vector2(fx * k, sc * k * sy), 0.0, origin + Vector2(0, bob))
	ci.draw_set_transform_matrix(xf)
	var tint := Color(0.85, 0.92, 1.0) if wet > 0.1 else Color.WHITE
	ci.draw_texture(tex, Vector2(-float(fm["ox"]), -float(fm["oy"])), tint)
	if wet > 0.1:
		ci.draw_set_transform_matrix(base * Transform2D(0.0, Vector2(sc, sc), 0.0, origin))
		for j in 6:
			var bp := Vector2(sin(t * 2.0 + j) * 30.0, -60.0 - fmod(t * 20.0 + j * 9.0, 40.0))
			ci.draw_circle(bp, 5 + (j % 3) * 2, Color(1, 1, 1, 0.7 * wet))
	return true


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


const HEAD_K := 1.32   # big cute heads (style reference: chibi pets)


static func _muzzle_col(b: Dictionary, fur: Color, fur2: Color) -> Color:
	var pat: String = b.get("pattern", "solid")
	if pat in ["bicolor", "tuxedo", "tricolor", "fluffy", "curly", "calico", "spots"]:
		return fur2
	return fur.lightened(0.42)


## Big glossy eye: dark rim, coloured iris, pupil, two highlights.
static func _cute_eye(ci: CanvasItem, ep: Vector2, rx: float, ry: float, iris: Color, species: String, mode: String, blink: float, far: bool, look := Vector2.ZERO) -> void:
	var ink := Color("#3a2522")
	if mode == "closed" or blink > 0.5:
		ci.draw_arc(ep + Vector2(0, ry * 0.15), rx * 0.95, 0.15, PI - 0.15, 10, ink, maxf(2.0, rx * 0.22), true)
		return
	if mode == "happy":
		ci.draw_arc(ep + Vector2(0, ry * 0.45), rx * 0.95, PI + 0.25, TAU - 0.25, 10, ink, maxf(2.0, rx * 0.24), true)
		return
	if mode == "wink" and not far:
		ci.draw_arc(ep + Vector2(0, ry * 0.45), rx * 0.95, PI + 0.25, TAU - 0.25, 10, ink, maxf(2.0, rx * 0.24), true)
		return
	var k := 0.85 if mode == "surprised" else 1.0
	D.ellipse(ci, ep, rx * k, ry * k, ink, false, 0.0)
	var ic := iris if species == "cat" else Color("#6b3d22")
	D.ellipse(ci, ep + look + Vector2(0, ry * 0.08), rx * 0.82 * k, ry * 0.84 * k, ic, false, 0.0)
	D.ellipse(ci, ep + look + Vector2(0, ry * 0.32), rx * 0.62 * k, ry * 0.4 * k, ic.lightened(0.25), false, 0.0)
	if species == "cat":
		D.ellipse(ci, ep + look + Vector2(0, ry * 0.05), rx * 0.26 * k, ry * 0.7 * k, ink, false, 0.0)
	else:
		D.ellipse(ci, ep + look + Vector2(0, ry * 0.05), rx * 0.48 * k, ry * 0.52 * k, ink, false, 0.0)
	ci.draw_circle(ep + look + Vector2(-rx * 0.3, -ry * 0.35), rx * 0.34, Color.WHITE)
	ci.draw_circle(ep + look + Vector2(rx * 0.32, ry * 0.32), rx * 0.15, Color(1, 1, 1, 0.9))


## Soft fur tufts along an arc (cheeks, chest, head top).
static func _tufts(ci: CanvasItem, c: Vector2, rx: float, ry: float, a0: float, a1: float, n: int, col: Color, depth := 0.22) -> void:
	var pts := PackedVector2Array([c])
	for i in n * 2 + 1:
		var a := lerpf(a0, a1, float(i) / float(n * 2))
		var k := 1.0 + (depth if i % 2 == 1 else 0.0)
		pts.append(c + Vector2(cos(a) * rx * k, sin(a) * ry * k))
	ci.draw_colored_polygon(pts, col)


static func _default_collar(ci: CanvasItem, species: String, neck: Vector2, fwd: Vector2, dn: Vector2, r: float) -> void:
	# style reference: red collar + golden bell (dog), pink bow + bell (cat)
	if species == "dog":
		D.taper(ci, neck - dn * r * 0.2 - fwd * r * 0.1, neck + dn * r * 0.25 + fwd * r * 0.35, r * 0.2, r * 0.2, Color("#d9363e"))
		var bell := neck + dn * r * 0.45 + fwd * r * 0.3
		D.ellipse(ci, bell, r * 0.16, r * 0.16, Color("#f2c33d"), true, 0.15)
		ci.draw_circle(bell + Vector2(0, r * 0.06), r * 0.04, Color("#9a6a12"))
	else:
		D.taper(ci, neck - dn * r * 0.15 - fwd * r * 0.05, neck + dn * r * 0.2 + fwd * r * 0.32, r * 0.14, r * 0.14, Color("#f06f9a"))
		var bp := neck + dn * r * 0.22 + fwd * r * 0.28
		var bc := Color("#f58fb8")
		D.poly(ci, PackedVector2Array([bp, bp + Vector2(-r * 0.36, -r * 0.24), bp + Vector2(-r * 0.36, r * 0.2)]), bc, true, 0.1)
		D.poly(ci, PackedVector2Array([bp, bp + Vector2(r * 0.36, -r * 0.24), bp + Vector2(r * 0.36, r * 0.2)]), bc, true, 0.1)
		D.ellipse(ci, bp + Vector2(0, r * 0.22), r * 0.12, r * 0.12, Color("#f2c33d"), true, 0.15)
		ci.draw_circle(bp, r * 0.08, bc.darkened(0.15))


static func _head(ci: CanvasItem, b: Dictionary, p: Dictionary, s: Dictionary, fur: Color, fur2: Color, fur3: Color, t: float, blink: float, accessory: Dictionary, sad: bool) -> void:
	var species: String = b.get("species", "cat")
	var pattern: String = b.get("pattern", "solid")
	var c: Vector2 = s["head"] + Vector2(-2, -4)
	var r := float(b.get("head_r", 24)) * HEAD_K
	var tilt: float = s["head_tilt"]
	var fwd := Vector2(1, 0).rotated(tilt)
	var dn := Vector2(0, 1).rotated(tilt)
	var ear: String = b.get("ear", "pointy")
	var ear_back := pf(p, "ears_back")
	var ear_col := fur if pattern != "points" else fur2
	if pattern == "tricolor":
		ear_col = fur3
	var mz := _muzzle_col(b, fur, fur2)
	# far ear
	_ear(ci, ear, c + fwd * r * 0.25 - dn * r * 0.62, r, fwd, dn, ear_col.darkened(0.12), ear_back, true)
	# fluffy cheeks + skull (seen 3/4: face turned toward us and forward)
	_tufts(ci, c + dn * r * 0.2 - fwd * r * 0.15, r * 0.95, r * 0.75, PI * 0.35, PI * 1.05, 4, fur, 0.18)
	D.ellipse(ci, c, r, r * 0.9, fur, true, 0.08)
	_tufts(ci, c - dn * r * 0.62, r * 0.42, r * 0.3, PI * 1.15, PI * 1.85, 3, fur, 0.35)
	match pattern:
		"tuxedo", "bicolor", "tricolor", "spots":
			# white blaze down the face
			D.poly(ci, PackedVector2Array([c + fwd * r * 0.42 - dn * r * 0.85, c + fwd * r * 0.62 - dn * r * 0.85, c + fwd * r * 0.75 + dn * r * 0.2, c + fwd * r * 0.3 + dn * r * 0.2]), fur2, false, 0.0)
		"points":
			D.ellipse(ci, c + fwd * r * 0.5 + dn * r * 0.15, r * 0.6, r * 0.55, fur2, false, 0.0)
		"tabby":
			for i in 3:
				ci.draw_line(c - dn * r * 0.86 + fwd * (r * 0.2 + i * r * 0.16), c - dn * r * 0.5 + fwd * (r * 0.24 + i * r * 0.13), fur.darkened(0.22), maxf(2.0, r * 0.08), true)
			for k in 2:
				ci.draw_line(c - fwd * r * 0.55 + dn * r * (0.05 + k * 0.18), c - fwd * r * 0.2 + dn * r * (0.1 + k * 0.16), fur.darkened(0.2), maxf(2.0, r * 0.07), true)
	# muzzle (soft, light) facing forward
	var sn := float(b.get("snout", 0.2))
	var snout_c := c + fwd * r * (0.62 + sn * 0.45) + dn * r * 0.34
	D.ellipse(ci, snout_c, r * (0.36 + sn * 0.4), r * (0.3 + sn * 0.05), mz, false, 0.04)
	# eyes: big and glossy, the far one a bit smaller (3/4 view)
	var eyes: String = p.get("eyes", "open")
	if sad and eyes == "open":
		eyes = "open"
	var ec := Content.color(b.get("eyes", "#3a2a26"))
	var erx := r * 0.25
	var ery := r * 0.3
	var ep_n := c + fwd * r * 0.12 - dn * r * 0.02
	var ep_f := c + fwd * r * 0.68 - dn * r * 0.06
	_cute_eye(ci, ep_f, erx * 0.78, ery * 0.95, ec, species, eyes, blink, true)
	_cute_eye(ci, ep_n, erx, ery, ec, species, eyes, blink, false)
	if sad or eyes == "surprised":
		for epb in [ep_n, ep_f]:
			var w2 := erx * (1.0 if epb == ep_n else 0.8)
			var tilt_b := 0.25 if sad else -0.1
			ci.draw_line(epb - dn * ery * 1.45 - fwd * w2 * 0.9, epb - dn * ery * (1.45 + tilt_b) + fwd * w2 * 0.9, Color("#3a2522"), maxf(2.0, r * 0.06), true)
	# blush
	D.ellipse(ci, ep_n + dn * ery * 1.35 - fwd * erx * 0.2, erx * 0.7, ery * 0.32, Color(1.0, 0.5, 0.6, 0.45), false, 0.0)
	# nose: rounded triangle with a shine
	var nose := snout_c + fwd * r * (0.28 + sn * 0.38) - dn * r * 0.1
	var ncol := Color("#3a2522") if species == "dog" else Color("#f08aa0")
	var nr := r * (0.15 if species == "dog" else 0.1)
	D.poly(ci, PackedVector2Array([nose - fwd * nr * 1.1 - dn * nr * 0.6, nose + fwd * nr * 1.1 - dn * nr * 0.6, nose + dn * nr * 0.8]), ncol, false, 0.0)
	D.ellipse(ci, nose - dn * nr * 0.3, nr * 1.05, nr * 0.62, ncol, false, 0.0)
	ci.draw_circle(nose - dn * nr * 0.45 - fwd * nr * 0.35, nr * 0.3, Color(1, 1, 1, 0.75))
	# mouth
	var mouth_open := pf(p, "mouth_open")
	var mc := nose + dn * r * 0.2
	var ink := Color(0.3, 0.17, 0.16, 0.9)
	if mouth_open > 0.3:
		var mo := PackedVector2Array()
		for i in 13:
			var aa := PI * i / 12.0
			mo.append(mc + dn * r * 0.05 + Vector2(cos(aa) * r * 0.2, sin(aa) * r * 0.2 * mouth_open + r * 0.02).rotated(tilt))
		D.poly(ci, mo, Color("#a8394d"), false, 0.0)
		if species == "dog" or pf(p, "tongue") > 0.5:
			D.ellipse(ci, mc + dn * r * (0.12 + 0.1 * mouth_open), r * 0.12, r * 0.12 * (0.6 + mouth_open * 0.6), Color("#f47d97"), false, 0.0)
	else:
		ci.draw_line(nose + dn * nr * 0.7, mc, ink, maxf(1.6, r * 0.05), true)
		ci.draw_arc(mc + dn * r * 0.0 - fwd * r * 0.09, r * 0.09, 0.15, PI - 0.4, 6, ink, maxf(1.6, r * 0.05), true)
		ci.draw_arc(mc + dn * r * 0.0 + fwd * r * 0.09, r * 0.09, 0.4, PI - 0.15, 6, ink, maxf(1.6, r * 0.05), true)
	if species == "cat":
		for k in 3:
			var wy := -0.04 + k * 0.07
			ci.draw_line(snout_c + fwd * r * 0.2 + dn * r * wy, snout_c + fwd * r * 1.05 + dn * r * (wy * 2.2 - 0.08), Color(1, 1, 1, 0.75), 1.3, true)
			ci.draw_line(snout_c - fwd * r * 0.3 + dn * r * wy, snout_c - fwd * r * 0.85 + dn * r * (wy * 2.0 - 0.02), Color(1, 1, 1, 0.55), 1.2, true)
	# near ear
	_ear(ci, ear, c - fwd * r * 0.35 - dn * r * 0.58, r, fwd, dn, ear_col, ear_back, false)
	if pattern == "curly":
		for i in 5:
			ci.draw_circle(c - dn * r * 0.75 + fwd * (i - 2) * r * 0.22, r * 0.2, fur2)
	# accessory on head / neck (default: collar with a bell)
	var st: String = accessory.get("style", "")
	var ac: Dictionary = accessory.get("colors", {})
	var neck := c - fwd * r * 0.35 + dn * r * 0.82
	match st:
		"collar":
			D.taper(ci, neck - dn * r * 0.15 - fwd * 4, neck + dn * r * 0.25 + fwd * 8, r * 0.2, r * 0.2, Content.color(ac.get("main", "#e85d75")))
			ci.draw_circle(neck + dn * r * 0.4 + fwd * 8, r * 0.13, Content.color(ac.get("accent", "#f6d36b")))
		"bandana":
			D.poly(ci, PackedVector2Array([neck - dn * r * 0.2 - fwd * 6, neck + fwd * r * 0.55, neck + dn * r * 0.7 + fwd * 4]), Content.color(ac.get("main", "#6f97d6")))
			ci.draw_circle(neck + dn * r * 0.2 + fwd * 6, 2.5, Color.WHITE)
		"bow":
			var bp := c - dn * r * 0.82 + fwd * r * 0.05
			var bcol := Content.color(ac.get("main", "#f59ab8"))
			D.poly(ci, PackedVector2Array([bp, bp + Vector2(-11, -9), bp + Vector2(-11, 8)]), bcol)
			D.poly(ci, PackedVector2Array([bp, bp + Vector2(11, -9), bp + Vector2(11, 8)]), bcol)
			ci.draw_circle(bp, 4, bcol.darkened(0.15))
		"crown":
			pass
		_:
			if st == "" or st == "none":
				_default_collar(ci, species, neck, fwd, dn, r)


static func _ear(ci: CanvasItem, ear: String, base: Vector2, r: float, fwd: Vector2, dn: Vector2, col: Color, back: float, far: bool) -> void:
	var rot := -back * 0.9
	match ear:
		"floppy", "floppy_curly":
			# long soft ear hanging beside the cheek (darker, slightly wavy)
			var tip := base - fwd * r * 0.35 + dn * r * 1.15
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI * i / 12.0
				pts.append(base.lerp(tip, 0.5) + (fwd * cos(a + PI * 0.5) * r * 0.36 + dn * sin(a + PI * 0.5) * r * 0.66).rotated(0.25))
			for i in 13:
				var a2 := PI + PI * i / 12.0
				pts.append(base.lerp(tip, 0.5) + (fwd * cos(a2 + PI * 0.5) * r * 0.3 + dn * sin(a2 + PI * 0.5) * r * 0.6).rotated(0.25))
			D.poly(ci, pts, col.darkened(0.12), true, 0.12)
			if not far:
				ci.draw_arc(base.lerp(tip, 0.55) + fwd * r * 0.05, r * 0.3, PI * 0.2, PI * 0.8, 6, col.darkened(0.25), 2.0, true)
			if ear == "floppy_curly":
				for i in 3:
					ci.draw_circle(base.lerp(tip, 0.3 + i * 0.3) - fwd * 3, r * 0.2, col.lightened(0.05))
		_:
			var big := 1.2 if ear == "pointy_big" else 1.0
			var tip := base + (-dn * r * 0.78 * big - fwd * r * 0.05).rotated(rot)
			var pts := PackedVector2Array([base - fwd * r * 0.34, tip, base + fwd * r * 0.3])
			D.poly(ci, pts, col, true, 0.1)
			if not far:
				var inner := PackedVector2Array([base - fwd * r * 0.2, base.lerp(tip, 0.8), base + fwd * r * 0.16])
				ci.draw_colored_polygon(inner, Color("#f7b2c4"))
				# fluffy ear tufts
				for k in 3:
					ci.draw_line(base + fwd * r * (-0.12 + k * 0.1), base.lerp(tip, 0.45) + fwd * r * (-0.06 + k * 0.06), Color(1, 1, 1, 0.7), 1.4, true)


## Sleeping: lying low on the belly, back legs folded, front paws stretched out,
## head resting on the paws with closed eyes, tail along the floor; the body
## gently rises and falls. Reads clearly as a sleeping cat / dog (not a ball).
static func _curled(ci: CanvasItem, b: Dictionary, p: Dictionary, s: Dictionary, fur: Color, fur2: Color, fur3: Color, t: float, accessory: Dictionary) -> void:
	var L: float = s["L"]
	var H: float = s["H"]
	var species: String = b.get("species", "cat")
	var pattern: String = b.get("pattern", "solid")
	var br := sin(t * 1.7)                     # slow breathing
	var rise := br * H * 0.035
	var paw_col := fur2 if pattern in ["tuxedo", "bicolor", "tricolor", "points", "calico"] else fur.lightened(0.1)
	var tail_col := fur.darkened(0.06) if pattern != "points" else fur2
	var fluffy: bool = b.get("tail", "") in ["fluffy", "curly"] or pattern == "fluffy"
	var line := Color("#3a2a2e")
	D.shadow(ci, Vector2(0, -2), L * 0.62, H * 0.16)
	# tail (behind body for dogs, wrapped along the floor to the front for cats)
	if species == "cat":
		var tp := PackedVector2Array()
		for i in 16:
			var k := float(i) / 15.0
			var x := lerpf(-L * 0.5, L * 0.28, k)
			var y := -H * 0.32 * (1.0 - smoothstep(0.0, 0.35, k)) - H * 0.07
			tp.append(Vector2(x - sin(k * PI) * L * 0.08, y))
		for i in tp.size() - 1:
			var w := H * (0.24 if fluffy else 0.17) * (1.0 - float(i) / 30.0)
			D.taper(ci, tp[i], tp[i + 1], w, w, tail_col if not (pattern == "tabby" and i % 3 == 2) else fur.darkened(0.2), false)
	else:
		var tail_kind: String = b.get("tail", "long")
		var tl := 0.18 if tail_kind in ["short", "pom"] else 0.32
		var t0 := Vector2(-L * 0.5, -H * 0.36)
		var t1 := Vector2(-L * (0.5 + tl), -H * 0.08 + sin(t * 0.9) * 1.5)
		D.taper(ci, t0, t1, H * (0.24 if fluffy else 0.16), H * 0.1, tail_col)
		if tail_kind == "pom":
			ci.draw_circle(t1, H * 0.18, fur2)
	# far front paw
	D.taper(ci, Vector2(L * 0.22, -H * 0.3), Vector2(L * 0.56, -H * 0.1), H * 0.24, H * 0.2, fur.darkened(0.08))
	D.ellipse(ci, Vector2(L * 0.6, -H * 0.1), H * 0.17, H * 0.11, paw_col.darkened(0.08), true, 0.05)
	# body: low loaf, back slightly raised at the hips
	var c := Vector2(-L * 0.06, -H * 0.42 - rise * 0.5)
	D.ellipse(ci, c, L * 0.5, H * 0.44 + rise, fur, true, 0.12)
	# folded back leg (haunch) with the paw tucked in front of it
	var hpc := Vector2(-L * 0.3, -H * 0.4 - rise * 0.5)
	D.ellipse(ci, hpc, H * 0.5, H * 0.4 + rise * 0.5, fur.darkened(0.03), true, 0.08)
	ci.draw_arc(hpc + Vector2(H * 0.05, H * 0.05), H * 0.36, PI * 1.05, PI * 1.85, 10, fur.darkened(0.22), 2.0, true)
	D.ellipse(ci, Vector2(-L * 0.12, -H * 0.08), H * 0.2, H * 0.11, paw_col, true, 0.05)
	# markings
	match pattern:
		"tabby":
			for i in 4:
				var sx := -L * 0.32 + i * L * 0.16
				ci.draw_line(Vector2(sx, c.y - H * 0.42), Vector2(sx + 4, c.y - H * 0.16), fur.darkened(0.22), 4, true)
		"spots", "calico":
			var sc2 := fur3 if pattern == "calico" else fur2
			for i in 5:
				D.ellipse(ci, c + Vector2(-L * 0.3 + i * L * 0.14, -H * 0.12 * float(i % 2) - H * 0.05), 6 + (i % 2) * 4, 5 + (i % 3) * 2, sc2, false, 0.0)
		"tuxedo", "bicolor", "tricolor", "points":
			D.ellipse(ci, c + Vector2(L * 0.12, H * 0.22), L * 0.3, H * 0.16, fur2 if pattern != "points" else fur.lightened(0.15), false, 0.0)
			if pattern == "tricolor":
				D.ellipse(ci, c + Vector2(-L * 0.08, -H * 0.18), L * 0.26, H * 0.2, fur3, false, 0.0)
	# head resting on the paws
	var r := float(b.get("head_r", 24))
	var hc := Vector2(L * 0.45, -H * 0.42 - rise * 0.3)
	var ear_col := fur if pattern != "points" else fur2
	if pattern == "tricolor":
		ear_col = fur3
	var ear: String = b.get("ear", "pointy")
	if not ear.begins_with("floppy"):
		var big := 1.2 if ear == "pointy_big" else 1.0
		D.poly(ci, PackedVector2Array([hc + Vector2(-r * 0.75, -r * 0.35), hc + Vector2(-r * 0.75, -r * 1.05 * big), hc + Vector2(-r * 0.25, -r * 0.7)]), ear_col.darkened(0.1), true, 0.08)
	D.ellipse(ci, hc, r * 1.02, r * 0.86, fur, true, 0.1)
	if pattern in ["tuxedo", "bicolor", "points", "fluffy", "tricolor"]:
		D.ellipse(ci, hc + Vector2(r * 0.35, r * 0.3), r * 0.55, r * 0.42, fur2, false, 0.0)
	if pattern == "tabby":
		for i in 3:
			ci.draw_line(hc + Vector2(-r * 0.2 + i * 6, -r * 0.82), hc + Vector2(-r * 0.15 + i * 5, -r * 0.45), fur.darkened(0.22), 3, true)
	# snout down on the paws
	var sn := float(b.get("snout", 0.2))
	var snc := hc + Vector2(r * (0.62 + sn * 0.5), r * 0.32)
	D.ellipse(ci, snc, r * (0.32 + sn * 0.5), r * 0.32, fur2 if pattern in ["bicolor", "tuxedo", "tricolor", "fluffy", "curly"] else fur.lightened(0.12), true, 0.05)
	ci.draw_circle(snc + Vector2(r * (0.28 + sn * 0.45), -r * 0.08), r * 0.11, line if species == "dog" else Color("#f08aa0"))
	ci.draw_arc(snc + Vector2(r * 0.02, r * 0.1), r * 0.14, 0.3, PI - 0.3, 6, Color(0.25, 0.15, 0.15, 0.7), 1.8, true)
	# closed, peaceful eyes + a little blush
	var ep := hc + Vector2(r * 0.32, -r * 0.08)
	ci.draw_arc(ep, r * 0.2, 0.15, PI - 0.15, 10, line, 2.6, true)
	for k in 2:
		ci.draw_line(ep + Vector2(-r * 0.12 + k * r * 0.24, r * 0.17), ep + Vector2(-r * 0.15 + k * r * 0.3, r * 0.27), line, 1.4, true)
	D.ellipse(ci, ep + Vector2(r * 0.05, r * 0.38), r * 0.16, r * 0.09, Color(1.0, 0.55, 0.65, 0.45), false, 0.0)
	if species == "cat":
		for k in 2:
			ci.draw_line(snc + Vector2(0, r * 0.02 + k * r * 0.1), snc + Vector2(r * 0.8, r * (0.0 + k * 0.16)), Color(1, 1, 1, 0.65), 1.2, true)
	# near ear
	if ear.begins_with("floppy"):
		var tip := hc + Vector2(-r * 0.35, r * 0.75)
		var ep2 := PackedVector2Array()
		for i in 20:
			var a2 := TAU * i / 20.0
			ep2.append(hc + Vector2(-r * 0.32, r * 0.12) + Vector2(cos(a2) * r * 0.34, sin(a2) * r * 0.66).rotated(0.25))
		D.poly(ci, ep2, ear_col.darkened(0.1), true, 0.1)
		if ear == "floppy_curly":
			for i in 3:
				ci.draw_circle(hc.lerp(tip, 0.3 + i * 0.3) + Vector2(-r * 0.25, 0), r * 0.2, ear_col.lightened(0.05))
	else:
		var big2 := 1.2 if ear == "pointy_big" else 1.0
		var e0 := hc + Vector2(-r * 0.45, -r * 0.55)
		var etip := hc + Vector2(-r * 0.25, -r * 1.2 * big2)
		var e1 := hc + Vector2(r * 0.1, -r * 0.78)
		D.poly(ci, PackedVector2Array([e0, etip, e1]), ear_col, true, 0.08)
		ci.draw_colored_polygon(PackedVector2Array([e0.lerp(e1, 0.2), e0.lerp(etip, 0.2).lerp(e1.lerp(etip, 0.8), 0.5), e0.lerp(e1, 0.8)]), Color("#f6b6c4"))
	if pattern == "curly":
		for i in 4:
			ci.draw_circle(hc + Vector2(-r * 0.4 + i * r * 0.25, -r * 0.75), r * 0.2, fur2)
	# near front paw peeking out under the chin
	D.ellipse(ci, Vector2(L * 0.66, -H * 0.06), H * 0.18, H * 0.12, paw_col, true, 0.05)
	for k in 2:
		ci.draw_line(Vector2(L * 0.66 + H * 0.05 * k + H * 0.03, -H * 0.12), Vector2(L * 0.66 + H * 0.05 * k + H * 0.03, -H * 0.02), paw_col.darkened(0.25), 1.2, true)
	# collar / bandana stays visible
	var st: String = accessory.get("style", "")
	if st in ["collar", "bandana"]:
		var acol := Content.color(accessory.get("colors", {}).get("main", "#e85d75"))
		ci.draw_arc(hc + Vector2(-r * 0.15, r * 0.1), r * 0.9, PI * 0.45, PI * 0.85, 8, acol, 5, true)
	elif st == "bow":
		var bp := hc + Vector2(-r * 0.05, -r * 0.85)
		var bcol := Content.color(accessory.get("colors", {}).get("main", "#f59ab8"))
		D.poly(ci, PackedVector2Array([bp, bp + Vector2(-10, -8), bp + Vector2(-10, 7)]), bcol)
		D.poly(ci, PackedVector2Array([bp, bp + Vector2(10, -8), bp + Vector2(10, 7)]), bcol)
		ci.draw_circle(bp, 3.5, bcol.darkened(0.15))


## Front (walking toward the viewer) / back (walking away) views.
## Legs lift in the same gait order as the side view, so steps stay in rhythm.
static func _frontback(ci: CanvasItem, b: Dictionary, p: Dictionary, fur: Color, fur2: Color, fur3: Color, gait: float, walk_w: float, t: float, blink: float, accessory: Dictionary, back: bool, sad: bool) -> void:
	var species: String = b.get("species", "cat")
	var H := float(b.get("body_h", 40))
	var leg := float(b.get("leg_len", 34))
	var r := float(b.get("head_r", 24))
	var pattern: String = b.get("pattern", "solid")
	var bob := -absf(sin(gait * TAU * 2.0)) * 2.5 * walk_w
	var body_c := Vector2(0, -leg - H * 0.32 + bob)
	var bw := H * 0.62
	var lw := H * (0.22 if species == "cat" else 0.26)
	var offs := gait_offsets(species, false)
	var paw := fur2 if pattern in ["tuxedo", "bicolor", "tricolor", "calico", "points"] else fur
	var legs_near := ["fl", "fr"] if not back else ["bl", "br"]
	var legs_far := ["bl", "br"] if not back else ["fl", "fr"]
	# far pair (partly hidden by the body)
	for i in 2:
		var name: String = legs_far[i]
		var sx := -1.0 if i == 0 else 1.0
		var ph := fmod(gait + float(offs[name]), 1.0)
		var lift := sin(ph * TAU) * 0.5 + 0.5
		lift = lift * leg * 0.18 * walk_w
		var top := Vector2(sx * bw * 0.45, body_c.y + H * 0.1)
		D.taper(ci, top, Vector2(sx * bw * 0.5, -3 - lift), lw, lw * 0.8, fur.darkened(0.15))
	# tail behind (front view) - peeks above the body
	if not back:
		var sway := sin(t * (12.0 if pf(p, "wag") > 0.5 else 2.5)) * 0.5
		D.taper(ci, body_c + Vector2(0, -H * 0.2), body_c + Vector2(sin(sway) * H * 0.6, -H * 0.95), H * 0.16, H * 0.1, fur.darkened(0.08))
	# head behind the body when seen from the back
	if back:
		_fb_ears(ci, b, body_c + Vector2(0, -H * 0.55), r, fur, fur3)
		D.ellipse(ci, body_c + Vector2(0, -H * 0.55), r * 0.95, r * 0.85, fur.darkened(0.04), true, 0.1)
	# body seen end-on
	D.ellipse(ci, body_c, bw, H * 0.58, fur, true, 0.14)
	if not back and pattern in ["tuxedo", "bicolor", "tricolor", "calico", "fluffy", "curly"]:
		D.ellipse(ci, body_c + Vector2(0, H * 0.12), bw * 0.5, H * 0.38, fur2, false, 0.0)
	if pattern == "tabby":
		for k in 3:
			ci.draw_arc(body_c + Vector2(0, -H * 0.1), bw * (0.5 + k * 0.15), PI * 1.25, PI * 1.75, 8, fur.darkened(0.2), 3, true)
	if accessory.get("style", "") == "sweater":
		D.ellipse(ci, body_c + Vector2(0, -H * 0.05), bw * 0.95, H * 0.45, Content.color(accessory.get("colors", {}).get("main", "#a8dcc8")), true, 0.1)
	# near pair
	for i in 2:
		var name2: String = legs_near[i]
		var sx2 := -1.0 if i == 0 else 1.0
		var ph2 := fmod(gait + float(offs[name2]), 1.0)
		var lift2 := (sin(ph2 * TAU) * 0.5 + 0.5) * leg * 0.22 * walk_w
		var top2 := Vector2(sx2 * bw * 0.4, body_c.y + H * 0.25)
		var foot := Vector2(sx2 * bw * 0.42, -2 - lift2)
		D.taper(ci, top2, foot, lw * 1.1, lw * 0.85, fur)
		D.ellipse(ci, foot + Vector2(0, -1), lw * 0.62, lw * 0.4, paw, true, 0.05)
	if back:
		# tail in front, swinging
		var sway2 := sin(t * (12.0 if pf(p, "wag") > 0.5 else 2.5)) * 0.6
		var root := body_c + Vector2(0, -H * 0.15)
		var tip := root + Vector2(sin(sway2) * H * 0.7, -H * 0.9)
		var tail_type: String = b.get("tail", "long")
		if tail_type == "short":
			tip = root + Vector2(sin(sway2) * H * 0.2, -H * 0.3)
		D.taper(ci, root, tip, H * 0.2, H * 0.12, fur if pattern != "points" else fur2)
		if tail_type == "pom":
			D.ellipse(ci, tip, H * 0.25, H * 0.25, fur2)
		return
	# face toward the viewer
	var hc := body_c + Vector2(0, -H * 0.5)
	_fb_ears(ci, b, hc, r, fur if pattern != "points" else fur2, fur3)
	D.ellipse(ci, hc, r, r * 0.92, fur, true, 0.1)
	if pattern in ["tuxedo", "bicolor", "points"]:
		D.ellipse(ci, hc + Vector2(0, r * 0.35), r * 0.6, r * 0.45, fur2, false, 0.0)
	if pattern == "tabby":
		for k in 3:
			ci.draw_line(hc + Vector2((k - 1) * 6, -r * 0.85), hc + Vector2((k - 1) * 5, -r * 0.45), fur.darkened(0.22), 3, true)
	var sn := float(b.get("snout", 0.2))
	D.ellipse(ci, hc + Vector2(0, r * 0.38), r * (0.3 + sn * 0.25), r * (0.24 + sn * 0.15), fur2 if pattern != "solid" else fur.lightened(0.15), false, 0.05)
	ci.draw_circle(hc + Vector2(0, r * 0.25), r * 0.13, Color("#3a2a2e") if species == "dog" else Color("#f08aa0"))
	ci.draw_arc(hc + Vector2(-r * 0.1, r * 0.38), r * 0.12, 0.1, PI - 0.3, 6, Color(0.25, 0.15, 0.15, 0.8), 2, true)
	ci.draw_arc(hc + Vector2(r * 0.1, r * 0.38), r * 0.12, 0.3, PI - 0.1, 6, Color(0.25, 0.15, 0.15, 0.8), 2, true)
	if pf(p, "tongue") > 0.5 and species == "dog":
		D.ellipse(ci, hc + Vector2(0, r * 0.62), r * 0.12, r * 0.18, Color("#f28aa0"), false)
	var ec := Content.color(b.get("eyes", "#3a2a26"))
	for sx in [-1.0, 1.0]:
		var ep := hc + Vector2(sx * r * 0.38, -r * 0.08)
		if p.get("eyes", "open") == "closed" or blink > 0.5:
			ci.draw_arc(ep, r * 0.16, 0.2, PI - 0.2, 8, Color("#3a2a2e"), 2.5, true)
		elif p.get("eyes", "open") == "happy":
			ci.draw_arc(ep + Vector2(0, r * 0.1), r * 0.16, PI + 0.3, TAU - 0.3, 8, Color("#3a2a2e"), 2.5, true)
		else:
			D.ellipse(ci, ep, r * 0.18, r * 0.22, ec if species == "cat" else Color("#3a2a26"), false, 0.1)
			if species == "cat":
				D.ellipse(ci, ep, r * 0.06, r * 0.17, Color("#2b2033"), false, 0.0)
			ci.draw_circle(ep + Vector2(-r * 0.05, -r * 0.08), r * 0.06, Color.WHITE)
			if sad:
				ci.draw_line(ep + Vector2(-sx * r * 0.2, -r * 0.3), ep + Vector2(sx * r * 0.15, -r * 0.24), Color("#3a2a2e"), 2, true)
		if species == "cat":
			for k in 2:
				ci.draw_line(hc + Vector2(sx * r * 0.3, r * (0.35 + k * 0.1)), hc + Vector2(sx * r * 1.05, r * (0.25 + k * 0.15)), Color(1, 1, 1, 0.7), 1.2, true)
	var st: String = accessory.get("style", "")
	if st == "collar":
		ci.draw_arc(hc + Vector2(0, r * 0.4), r * 0.75, PI * 0.15, PI * 0.85, 10, Content.color(accessory["colors"]["main"]), r * 0.18, true)
		ci.draw_circle(hc + Vector2(0, r * 1.12), r * 0.12, Content.color(accessory["colors"].get("accent", "#f6d36b")))
	elif st == "bandana":
		D.poly(ci, PackedVector2Array([hc + Vector2(-r * 0.6, r * 0.75), hc + Vector2(r * 0.6, r * 0.75), hc + Vector2(0, r * 1.3)]), Content.color(accessory["colors"]["main"]))
	elif st == "bow":
		var bp := hc + Vector2(r * 0.5, -r * 0.75)
		var bc := Content.color(accessory["colors"]["main"])
		D.poly(ci, PackedVector2Array([bp, bp + Vector2(-10, -8), bp + Vector2(-10, 7)]), bc)
		D.poly(ci, PackedVector2Array([bp, bp + Vector2(10, -8), bp + Vector2(10, 7)]), bc)


static func _fb_ears(ci: CanvasItem, b: Dictionary, hc: Vector2, r: float, col: Color, fur3: Color) -> void:
	var ear: String = b.get("ear", "pointy")
	if b.get("pattern") == "tricolor":
		col = fur3
	for sx in [-1.0, 1.0]:
		if ear.begins_with("floppy"):
			D.poly(ci, PackedVector2Array([hc + Vector2(sx * r * 0.55, -r * 0.6), hc + Vector2(sx * r * 1.05, -r * 0.2), hc + Vector2(sx * r * 0.95, r * 0.55), hc + Vector2(sx * r * 0.6, r * 0.3)]), col.darkened(0.08), true, 0.1)
		else:
			var big := 1.25 if ear == "pointy_big" else 1.0
			D.poly(ci, PackedVector2Array([hc + Vector2(sx * r * 0.2, -r * 0.7), hc + Vector2(sx * r * 0.7 * big, -r * 1.35 * big), hc + Vector2(sx * r * 0.88, -r * 0.35)]), col, true, 0.1)
			ci.draw_colored_polygon(PackedVector2Array([hc + Vector2(sx * r * 0.32, -r * 0.7), hc + Vector2(sx * r * 0.68 * big, -r * 1.18 * big), hc + Vector2(sx * r * 0.78, -r * 0.45)]), Color("#f6b6c4"))
