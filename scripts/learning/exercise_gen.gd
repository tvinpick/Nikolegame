class_name ExerciseGen
extends RefCounted
## Pure, seedable exercise generators for 5 categories (age 6 preschool level).
## Output is plain data; ExerciseGen.check() validates an answer. The notebook UI
## only renders data, so new templates plug in without touching the UI core.
##
## Exercise dict:
##   type: choose | drag_count | drag_match | tap_all
##   category, level, prompt (i18n key), prompt_args (Array), voice (bool)
##   items: Array of display items (for the scene / question)
##   options: Array of {id, icon?, text?, color?, count?, shape?}
##   answer: id (choose) | int (drag_count) | Array of ids (tap_all) | Dictionary shape->slot (drag_match)

const CATEGORIES := ["math", "letters", "shapes", "colors", "logic"]
const COUNT_ICONS := ["apple", "berry", "star", "fish", "flower", "ball", "heart", "leaf"]
const SHAPES := ["circle", "square", "triangle", "star", "heart", "rectangle"]
const COLORS := {
	"red": "#ef5b5b", "yellow": "#f7d046", "blue": "#5b8def", "green": "#62c370",
	"orange": "#f59a3b", "purple": "#a274e0", "pink": "#f58fb8", "brown": "#a8754f",
}
const COLOR_THINGS := {"red": ["apple", "heart"], "yellow": ["sun", "banana", "lemon"], "green": ["leaf", "cucumber", "tree"], "blue": ["ball", "fish"], "orange": ["star"], "purple": ["flower"], "pink": ["flower"], "brown": ["mushroom"]}
const MIXES := [["red", "yellow", "orange"], ["blue", "yellow", "green"], ["red", "blue", "purple"], ["red", "white", "pink"]]
const ODD_GROUPS := {
	"fruit": ["apple", "banana", "pear", "lemon", "watermelon"],
	"animal": ["cat", "dog", "fish", "bird", "duck", "hedgehog"],
	"sky": ["sun", "moon", "star", "cloud"],
	"plant": ["flower", "tree", "leaf", "mushroom"],
}
const SEQUENCES := [["seed", "sprout", "flower"], ["egg", "chick", "bird"], ["moon", "sunrise", "sun"], ["cloud", "rain", "rainbow"]]


static func generate(category: String, level: int, rng: RandomNumberGenerator, lang_data: Dictionary) -> Dictionary:
	level = clampi(level, 1, 3)
	var ex: Dictionary
	match category:
		"math":
			ex = _math(level, rng)
		"letters":
			ex = _letters(level, rng, lang_data)
		"shapes":
			ex = _shapes(level, rng)
		"colors":
			ex = _colors(level, rng)
		"logic":
			ex = _logic(level, rng)
		_:
			ex = _math(level, rng)
	ex["category"] = category
	ex["level"] = level
	return ex


static func session(category: String, level: int, count: int, rng: RandomNumberGenerator, lang_data: Dictionary) -> Array:
	var out: Array = []
	var guard := 0
	while out.size() < count and guard < 50:
		guard += 1
		var ex := generate(category, level, rng, lang_data)
		# avoid two identical prompts in a row
		if out.size() > 0 and JSON.stringify(out[-1].get("answer")) == JSON.stringify(ex.get("answer")) and out[-1].get("prompt") == ex.get("prompt"):
			continue
		out.append(ex)
	return out


static func check(ex: Dictionary, response: Variant) -> bool:
	match ex.get("type", ""):
		"choose":
			return str(response) == str(ex["answer"])
		"drag_count":
			return int(response) == int(ex["answer"])
		"tap_all":
			var a: Array = ex["answer"].duplicate()
			var r: Array = (response as Array).duplicate() if typeof(response) == TYPE_ARRAY else []
			a.sort()
			r.sort()
			return a == r
		"drag_match":
			if typeof(response) != TYPE_DICTIONARY:
				return false
			var ans: Dictionary = ex["answer"]
			if (response as Dictionary).size() != ans.size():
				return false
			for k in ans.keys():
				if str((response as Dictionary).get(k, "")) != str(ans[k]):
					return false
			return true
	return false


## Check one partial step (drag of a single shape onto a slot) — used for instant feedback.
static func check_step(ex: Dictionary, piece: String, target: String) -> bool:
	if ex.get("type") == "drag_match":
		return str(ex["answer"].get(piece, "")) == target
	if ex.get("type") == "tap_all":
		return piece in ex["answer"]
	return false


static func _pick_distinct(pool: Array, n: int, rng: RandomNumberGenerator, exclude: Array = []) -> Array:
	var p: Array = []
	for v in pool:
		if v not in exclude:
			p.append(v)
	_shuffle(p, rng)
	return p.slice(0, min(n, p.size()))


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = a[i]
		a[i] = a[j]
		a[j] = tmp


static func _num_options(answer: int, lo: int, hi: int, rng: RandomNumberGenerator, n := 3) -> Array:
	var vals: Array = [answer]
	var guard := 0
	while vals.size() < n and guard < 100:
		guard += 1
		var v := clampi(answer + rng.randi_range(-3, 3), lo, hi)
		if v not in vals:
			vals.append(v)
	_shuffle(vals, rng)
	var out: Array = []
	for v in vals:
		out.append({"id": str(v), "text": str(v)})
	return out


# ------------------------------------------------------------------ math
static func _math(level: int, rng: RandomNumberGenerator) -> Dictionary:
	var icon: String = COUNT_ICONS[rng.randi_range(0, COUNT_ICONS.size() - 1)]
	var kind := rng.randi_range(0, 2) if level >= 2 else rng.randi_range(0, 1)
	if level == 3:
		kind = rng.randi_range(1, 3)
	match kind:
		0:  # count and choose
			var n := rng.randi_range(1, 5 if level == 1 else 8)
			return {"type": "choose", "prompt": "ex_count_how_many", "prompt_args": [], "icon": icon,
				"items": [{"icon": icon, "count": n}], "options": _num_options(n, 1, 10, rng), "answer": str(n)}
		1:  # put N into basket
			var n := rng.randi_range(2, 4 if level == 1 else (6 if level == 2 else 9))
			return {"type": "drag_count", "prompt": "ex_put_n", "prompt_args": [n], "icon": "berry", "items": [{"icon": "berry", "count": n + rng.randi_range(2, 3)}], "answer": n}
		2:  # compare
			var a := rng.randi_range(1, 7)
			var b := a
			while b == a:
				b = rng.randi_range(1, 7)
			var more := rng.randi_range(0, 1) == 0
			var ans := "left" if (a > b) == more else "right"
			return {"type": "choose", "prompt": "ex_where_more" if more else "ex_where_less", "prompt_args": [], "icon": icon,
				"items": [], "options": [{"id": "left", "icon": icon, "count": a}, {"id": "right", "icon": icon, "count": b}], "answer": ans}
		_:  # add / subtract with pictures within 10
			var plus := rng.randi_range(0, 1) == 0
			var x := rng.randi_range(1, 5)
			var y := rng.randi_range(1, 4)
			if not plus and y > x:
				var t := x
				x = y
				y = t
			var r := x + y if plus else x - y
			return {"type": "choose", "prompt": "ex_plus" if plus else "ex_minus", "prompt_args": [x, y], "icon": icon,
				"items": [{"icon": icon, "count": x}, {"op": "+" if plus else "-"}, {"icon": icon, "count": y}],
				"options": _num_options(r, 0, 10, rng), "answer": str(r)}


# ------------------------------------------------------------------ letters
static func _letters(level: int, rng: RandomNumberGenerator, data: Dictionary) -> Dictionary:
	var words: Array = data.get("words", [])
	var distract: String = data.get("distractor_letters", "АБВ")
	if words.is_empty():
		return {"type": "choose", "prompt": "ex_missing_data", "items": [], "options": [{"id": "a", "text": "?"}], "answer": "a"}
	var kind := 0 if level == 1 else rng.randi_range(0, 1 if level == 2 else 2)
	match kind:
		0, 1:
			var w: Dictionary = words[rng.randi_range(0, words.size() - 1)]
			var first: String = str(w["word"]).substr(0, 1).to_upper()
			var letters: Array = [first]
			var guard := 0
			while letters.size() < (3 if level == 1 else 4) and guard < 100:
				guard += 1
				var c := distract.substr(rng.randi_range(0, distract.length() - 1), 1)
				if c not in letters:
					letters.append(c)
			_shuffle(letters, rng)
			var opts: Array = []
			for c in letters:
				opts.append({"id": c, "text": c})
			if kind == 0:
				return {"type": "choose", "prompt": "ex_first_letter", "prompt_args": [], "word": w["word"], "items": [{"icon": w["icon"], "count": 1, "caption": w["word"]}], "options": opts, "answer": first, "speak_word": w["word"]}
			return {"type": "choose", "prompt": "ex_find_letter", "prompt_args": [first], "items": [], "options": opts, "answer": first, "speak_letter": first}
		_:
			var sw: Array = data.get("short_words", words)
			var w2: Dictionary = sw[rng.randi_range(0, sw.size() - 1)]
			var word: String = str(w2["word"]).to_upper()
			var idx := rng.randi_range(1, word.length() - 1)
			var missing := word.substr(idx, 1)
			var shown := word.substr(0, idx) + "_" + word.substr(idx + 1)
			var letters2: Array = [missing]
			var guard2 := 0
			while letters2.size() < 3 and guard2 < 100:
				guard2 += 1
				var c2 := distract.substr(rng.randi_range(0, distract.length() - 1), 1)
				if c2 not in letters2 and c2 not in word:
					letters2.append(c2)
			_shuffle(letters2, rng)
			var opts2: Array = []
			for c in letters2:
				opts2.append({"id": c, "text": c})
			return {"type": "choose", "prompt": "ex_missing_letter", "prompt_args": [], "word": w2["word"], "items": [{"icon": w2["icon"], "count": 1, "caption": shown}], "options": opts2, "answer": missing, "speak_word": w2["word"]}


# ------------------------------------------------------------------ shapes
static func _shapes(level: int, rng: RandomNumberGenerator) -> Dictionary:
	var kind := 0 if level == 1 else rng.randi_range(0, 1)
	if level == 3 and rng.randi_range(0, 2) == 0:
		kind = 2
	match kind:
		0:  # drag into matching outlines
			var n := 2 if level == 1 else (3 if level == 2 else 4)
			var shapes := _pick_distinct(SHAPES, n, rng)
			var ans := {}
			var slots: Array = []
			for s in shapes:
				ans[s] = "slot_" + s
				slots.append({"id": "slot_" + s, "shape": s})
			_shuffle(slots, rng)
			var pieces: Array = []
			var cols := COLORS.keys()
			for s in shapes:
				pieces.append({"id": s, "shape": s, "color": COLORS[cols[rng.randi_range(0, cols.size() - 1)]]})
			_shuffle(pieces, rng)
			return {"type": "drag_match", "prompt": "ex_shapes_to_outlines", "prompt_args": [], "items": slots, "options": pieces, "answer": ans}
		1:  # find shape by name
			var opts := _pick_distinct(SHAPES, 3 if level < 3 else 4, rng)
			var target: String = opts[rng.randi_range(0, opts.size() - 1)]
			var o: Array = []
			for s in opts:
				o.append({"id": s, "shape": s, "color": COLORS.values()[rng.randi_range(0, 7)]})
			return {"type": "choose", "prompt": "ex_find_shape", "prompt_args": ["shape_" + target], "items": [], "options": o, "answer": target}
		_:  # shape pattern
			var ab := _pick_distinct(SHAPES, 2, rng)
			var seq: Array = [ab[0], ab[1], ab[0], ab[1], ab[0]]
			var items: Array = []
			for s in seq:
				items.append({"shape": s, "color": "#8fb3e8"})
			var o2: Array = []
			for s in _pick_distinct(SHAPES, 2, rng, [ab[1]]) + [ab[1]]:
				o2.append({"id": s, "shape": s, "color": "#8fb3e8"})
			_shuffle(o2, rng)
			return {"type": "choose", "prompt": "ex_what_next", "prompt_args": [], "items": items + [{"q": true}], "options": o2, "answer": ab[1]}


# ------------------------------------------------------------------ colors
static func _colors(level: int, rng: RandomNumberGenerator) -> Dictionary:
	var kind := 0 if level == 1 else rng.randi_range(0, 1)
	if level == 3 and rng.randi_range(0, 1) == 0:
		kind = 2
	var names: Array = COLORS.keys()
	match kind:
		0:  # tap all of color X
			var target: String = names[rng.randi_range(0, names.size() - 1)]
			var n_target := 2 if level == 1 else 3
			var opts: Array = []
			var ans: Array = []
			var others := _pick_distinct(names, 6 - n_target, rng, [target])
			for i in n_target:
				opts.append({"id": "t%d" % i, "shape": "circle", "color": COLORS[target], "cname": target})
				ans.append("t%d" % i)
			for i in others.size():
				opts.append({"id": "o%d" % i, "shape": "circle", "color": COLORS[others[i]], "cname": others[i]})
			_shuffle(opts, rng)
			return {"type": "tap_all", "prompt": "ex_tap_color", "prompt_args": ["color_" + target], "items": [], "options": opts, "answer": ans}
		1:  # match same colour as sample
			var target2: String = names[rng.randi_range(0, names.size() - 1)]
			var o: Array = []
			for c in _pick_distinct(names, 3, rng, [target2]) + [target2]:
				o.append({"id": c, "shape": "heart", "color": COLORS[c]})
			_shuffle(o, rng)
			return {"type": "choose", "prompt": "ex_same_color", "prompt_args": [], "items": [{"shape": "square", "color": COLORS[target2]}], "options": o, "answer": target2}
		_:  # mixing
			var mix: Array = MIXES[rng.randi_range(0, MIXES.size() - 1)]
			var col_a: String = COLORS.get(mix[0], "#ffffff") if mix[0] != "white" else "#ffffff"
			var col_b: String = COLORS.get(mix[1], "#ffffff") if mix[1] != "white" else "#ffffff"
			var o3: Array = []
			for c in _pick_distinct(names, 2, rng, [mix[2], mix[0], mix[1]]) + [mix[2]]:
				o3.append({"id": c, "shape": "drop", "color": COLORS[c]})
			_shuffle(o3, rng)
			return {"type": "choose", "prompt": "ex_mix", "prompt_args": [], "items": [{"shape": "drop", "color": col_a}, {"op": "+"}, {"shape": "drop", "color": col_b}], "options": o3, "answer": mix[2]}


# ------------------------------------------------------------------ logic
static func _logic(level: int, rng: RandomNumberGenerator) -> Dictionary:
	var kind := rng.randi_range(0, 1) if level == 1 else rng.randi_range(0, 2)
	match kind:
		0:  # pattern AB / ABC with icons
			var pool := ["apple", "star", "heart", "fish", "flower", "ball", "leaf", "moon"]
			var parts := _pick_distinct(pool, 2 if level < 3 else 3, rng)
			var seq: Array = []
			var length := 5 if parts.size() == 2 else 6
			for i in length:
				seq.append(parts[i % parts.size()])
			var nxt: String = parts[length % parts.size()]
			var items: Array = []
			for s in seq:
				items.append({"icon": s, "count": 1})
			var o: Array = []
			for s in _pick_distinct(pool, 2, rng, [nxt]) + [nxt]:
				o.append({"id": s, "icon": s})
			_shuffle(o, rng)
			return {"type": "choose", "prompt": "ex_what_next", "prompt_args": [], "items": items + [{"q": true}], "options": o, "answer": nxt}
		1:  # odd one out
			var groups := ODD_GROUPS.keys()
			_shuffle(groups, rng)
			var same := _pick_distinct(ODD_GROUPS[groups[0]], 3, rng)
			var odd: String = ODD_GROUPS[groups[1]][rng.randi_range(0, ODD_GROUPS[groups[1]].size() - 1)]
			var o2: Array = []
			for s in same + [odd]:
				o2.append({"id": s, "icon": s})
			_shuffle(o2, rng)
			return {"type": "choose", "prompt": "ex_odd_one", "prompt_args": [], "items": [], "options": o2, "answer": odd}
		_:  # picture sequence: what comes next
			var sq: Array = SEQUENCES[rng.randi_range(0, SEQUENCES.size() - 1)]
			var items2: Array = [{"icon": sq[0], "count": 1}, {"icon": sq[1], "count": 1}, {"q": true}]
			var o3: Array = [{"id": sq[2], "icon": sq[2]}, {"id": sq[0], "icon": sq[0]}]
			var extra: String = ["leaf", "ball", "fish"][rng.randi_range(0, 2)]
			o3.append({"id": extra, "icon": extra})
			_shuffle(o3, rng)
			return {"type": "choose", "prompt": "ex_what_next", "prompt_args": [], "items": items2, "options": o3, "answer": sq[2]}
