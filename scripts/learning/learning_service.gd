extends Node
## Learning sessions: generation, adaptive level per category, aggregated stats,
## and an idempotent reward event handed to Economy (the wallet pays, not us).

signal session_started(info: Dictionary)
signal session_finished(result: Dictionary)

var lang_data: Dictionary = {}   # lang -> data
var current: Dictionary = {}     # active session
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	for lang in ["ru", "de"]:
		var f := FileAccess.open("res://content/learning/%s.json" % lang, FileAccess.READ)
		if f:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if typeof(d) == TYPE_DICTIONARY:
				lang_data[lang] = d
	rng.randomize()


func level_of(category: String) -> int:
	return int(GameState.data["learning"]["levels"].get(category, 1))


func limits_of(category: String) -> Array:
	var l: Variant = GameState.data["learning"]["limits"].get(category, [1, 3])
	return [int(l[0]), int(l[1])]


func set_limits(category: String, lo: int, hi: int) -> void:
	lo = clampi(lo, 1, 3)
	hi = clampi(hi, lo, 3)
	GameState.data["learning"]["limits"][category] = [lo, hi]
	var lv := clampi(level_of(category), lo, hi)
	GameState.data["learning"]["levels"][category] = lv
	Save.request_save("limits")


func exercises_count(level: int) -> int:
	var cfg: Dictionary = Content.econ("exercises_per_session", {"min": 3, "max": 5})
	return clampi(2 + level, int(cfg["min"]), int(cfg["max"]))


func start_session(category: String, seed_value: int = -1) -> Dictionary:
	if seed_value >= 0:
		rng.seed = seed_value
	var lvl := clampi(level_of(category), limits_of(category)[0], limits_of(category)[1])
	var l: Dictionary = GameState.data["learning"]
	l["session_counter"] = int(l.get("session_counter", 0)) + 1
	var sid := "learn-%d-%d" % [int(GameState.data.get("created_unix", 0)) % 100000, int(l["session_counter"])]
	var data: Dictionary = lang_data.get(Loc.learn_lang, lang_data.get("ru", {}))
	var exs := ExerciseGen.session(category, lvl, exercises_count(lvl), rng, data)
	current = {"id": sid, "category": category, "level": lvl, "exercises": exs, "index": 0, "first_try": 0, "attempts_cur": 0, "results": [], "done": false, "lang": Loc.learn_lang}
	Save.request_save("session_start")  # persist the counter so ids never repeat
	Diag.event("learn_start", {"cat": category, "level": lvl, "n": exs.size()})
	session_started.emit(current)
	return current


func current_exercise() -> Dictionary:
	if current.is_empty() or current["index"] >= current["exercises"].size():
		return {}
	return current["exercises"][current["index"]]


## Report an answer. Returns {"correct": bool, "advance": bool, "finished": bool}
func answer(response: Variant) -> Dictionary:
	var ex := current_exercise()
	if ex.is_empty():
		return {"correct": false, "advance": false, "finished": current.get("done", false)}
	var ok := ExerciseGen.check(ex, response)
	current["attempts_cur"] = int(current["attempts_cur"]) + 1
	if not ok:
		Diag.event("learn_try", {"ok": false})
		return {"correct": false, "advance": false, "finished": false}
	var first := int(current["attempts_cur"]) == 1
	if first:
		current["first_try"] = int(current["first_try"]) + 1
	current["results"].append(first)
	_record(current["category"], first)
	current["index"] = int(current["index"]) + 1
	current["attempts_cur"] = 0
	var finished: bool = current["index"] >= current["exercises"].size()
	if finished:
		_finish()
	return {"correct": true, "advance": true, "finished": finished}


## Register a wrong partial step (e.g. dropped shape in wrong outline) as an attempt.
func note_wrong_step() -> void:
	if not current.is_empty():
		current["attempts_cur"] = int(current["attempts_cur"]) + 1


func _record(category: String, first_try: bool) -> void:
	var l: Dictionary = GameState.data["learning"]
	var st: Dictionary = l["stats"].get(category, {"sessions": 0, "exercises": 0, "first_try": 0})
	st["exercises"] = int(st.get("exercises", 0)) + 1
	if first_try:
		st["first_try"] = int(st.get("first_try", 0)) + 1
	l["stats"][category] = st
	var rec: Array = l["recent"].get(category, [])
	rec.append(first_try)
	while rec.size() > 10:
		rec.pop_front()
	l["recent"][category] = rec


func _finish() -> void:
	current["done"] = true
	var cat: String = current["category"]
	var l: Dictionary = GameState.data["learning"]
	var st: Dictionary = l["stats"].get(cat, {})
	st["sessions"] = int(st.get("sessions", 0)) + 1
	l["stats"][cat] = st
	var new_level := adapt(cat)
	var base := int(Content.econ("session_reward", 10))
	var bonus: int = min(int(current["first_try"]) * int(Content.econ("independent_bonus_per_exercise", 2)), int(Content.econ("max_independent_bonus", 6)))
	var paid := Economy.grant_reward(current["id"], base + bonus, "learning_" + cat)
	var result := {"id": current["id"], "category": cat, "coins": paid, "base": base, "bonus": bonus, "first_try": current["first_try"], "total": current["exercises"].size(), "level": new_level}
	Diag.event("learn_done", result)
	session_finished.emit(result)


## Adaptive difficulty: >=80% first-try over last 5+ -> up; <=40% -> down. Within adult limits.
func adapt(category: String) -> int:
	var l: Dictionary = GameState.data["learning"]
	var rec: Array = l["recent"].get(category, [])
	var lv := level_of(category)
	var lim := limits_of(category)
	if rec.size() >= 5:
		var good := 0
		for r in rec:
			if r:
				good += 1
		var ratio := float(good) / rec.size()
		if ratio >= 0.8 and lv < lim[1]:
			lv += 1
			l["recent"][category] = []
		elif ratio <= 0.4 and lv > lim[0]:
			lv -= 1
			l["recent"][category] = []
	lv = clampi(lv, lim[0], lim[1])
	l["levels"][category] = lv
	return lv


func abort() -> void:
	if not current.is_empty() and not current.get("done", false):
		Diag.event("learn_abort", {"cat": current.get("category")})
	current = {}


func summary() -> Dictionary:
	var out := {}
	var l: Dictionary = GameState.data["learning"]
	for c in ExerciseGen.CATEGORIES:
		var st: Dictionary = l["stats"].get(c, {})
		out[c] = {"level": level_of(c), "limits": limits_of(c), "sessions": int(st.get("sessions", 0)), "exercises": int(st.get("exercises", 0)), "first_try": int(st.get("first_try", 0))}
	return out
