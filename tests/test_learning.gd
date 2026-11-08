extends RefCounted
## Exercise generators, answer checking, adaptivity, one-time rewards, RU/DE.

var runner: Object


func _l() -> Node:
	return runner.root.get_node("Learning")


func test_generators_produce_valid_answers() -> void:
	var rng := RandomNumberGenerator.new()
	for lang in ["ru", "de"]:
		var data: Dictionary = _l().lang_data[lang]
		for cat in ExerciseGen.CATEGORIES:
			for level in [1, 2, 3]:
				for s in 40:
					rng.seed = s * 31 + level
					var ex := ExerciseGen.generate(cat, level, rng, data)
					runner.check(ex.has("type") and ex.has("answer"), "%s/%d has answer" % [cat, level])
					match ex["type"]:
						"choose":
							var ids := []
							for o in ex["options"]:
								ids.append(str(o["id"]))
							runner.check(str(ex["answer"]) in ids, "%s/%d/%s answer among options" % [cat, level, lang])
							runner.check(ids.size() == _unique(ids).size(), "%s options unique" % cat)
							runner.check(ExerciseGen.check(ex, ex["answer"]), "correct answer accepted")
							for o in ex["options"]:
								if str(o["id"]) != str(ex["answer"]):
									runner.check(not ExerciseGen.check(ex, o["id"]), "wrong answer rejected (%s)" % cat)
						"drag_count":
							runner.check(int(ex["items"][0]["count"]) > int(ex["answer"]), "more berries than needed")
							runner.check(ExerciseGen.check(ex, int(ex["answer"])), "count ok")
							runner.check(not ExerciseGen.check(ex, int(ex["answer"]) + 1), "count too many rejected")
						"drag_match":
							runner.check(ExerciseGen.check(ex, ex["answer"].duplicate()), "full match ok")
							runner.eq(ex["answer"].size(), ex["options"].size(), "every piece has a slot")
						"tap_all":
							runner.check(ExerciseGen.check(ex, ex["answer"].duplicate()), "all targets ok")
							runner.check(not ExerciseGen.check(ex, []), "empty rejected")


func _unique(a: Array) -> Array:
	var d := {}
	for v in a:
		d[v] = true
	return d.keys()


func test_letters_language_specific() -> void:
	var rng := RandomNumberGenerator.new()
	var seen_ru := {}
	var seen_de := {}
	for s in 60:
		rng.seed = s
		var a := ExerciseGen.generate("letters", 1, rng, _l().lang_data["ru"])
		seen_ru[a["answer"]] = true
		rng.seed = s
		var b := ExerciseGen.generate("letters", 1, rng, _l().lang_data["de"])
		seen_de[b["answer"]] = true
	var cyr := false
	for k in seen_ru.keys():
		if str(k).unicode_at(0) >= 0x0400:
			cyr = true
	runner.check(cyr, "russian letters are cyrillic")
	for k in seen_de.keys():
		runner.check(str(k).unicode_at(0) < 0x0400, "german letters are latin: " + str(k))


func test_session_reward_once_and_no_penalty() -> void:
	runner.root.get_node("Economy").new_game()
	var gs: Node = runner.root.get_node("GameState")
	var l := _l()
	var c0: int = gs.coins()
	var info: Dictionary = l.start_session("math", 7)
	var n: int = info["exercises"].size()
	runner.check(n >= 3 and n <= 5, "3..5 exercises")
	# first exercise: one wrong try then right; rest right first time
	var first := true
	while not l.current.get("done", false):
		var ex: Dictionary = l.current_exercise()
		if first:
			var wrong: Variant = -1 if ex["type"] == "drag_count" else "nope"
			var r0: Dictionary = l.answer(wrong)
			runner.check(not r0["correct"] and not r0["advance"], "wrong answer only hints")
			first = false
		var r: Dictionary = l.answer(ex["answer"].duplicate() if typeof(ex["answer"]) in [TYPE_ARRAY, TYPE_DICTIONARY] else ex["answer"])
		runner.check(r["correct"], "correct accepted")
	var paid: int = gs.coins() - c0
	var expected: int = 10 + min((n - 1) * 2, 6)
	runner.eq(paid, expected, "reward = base + independent bonus")
	# a duplicate finish signal must not pay again
	runner.eq(runner.root.get_node("Economy").grant_reward(info["id"], 10, "dup"), 0, "no double pay")
	# answering after finish is harmless
	var r2: Dictionary = l.answer(1)
	runner.check(not r2["correct"], "no-op after finish")


func test_adaptive_level_within_limits() -> void:
	runner.root.get_node("Economy").new_game()
	var l := _l()
	l.set_limits("colors", 1, 2)
	var rec: Array = [true, true, true, true, true]
	runner.root.get_node("GameState").data["learning"]["recent"]["colors"] = rec
	runner.eq(l.adapt("colors"), 2, "level up")
	runner.root.get_node("GameState").data["learning"]["recent"]["colors"] = [true, true, true, true, true]
	runner.eq(l.adapt("colors"), 2, "capped by adult max")
	runner.root.get_node("GameState").data["learning"]["recent"]["colors"] = [false, false, false, false, false]
	runner.eq(l.adapt("colors"), 1, "level down on struggle")
	runner.root.get_node("GameState").data["learning"]["recent"]["colors"] = [false, false, false, false, false]
	runner.eq(l.adapt("colors"), 1, "not below adult min")
