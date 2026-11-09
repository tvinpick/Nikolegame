extends RefCounted
## Catalog, profiles, localization and learning data validation.

var runner: Object


func _c() -> Node:
	return runner.root.get_node("Content")


func test_catalog_valid() -> void:
	var c := _c()
	c.errors.clear()
	var errs: PackedStringArray = c.validate()
	runner.check(errs.is_empty(), "content errors: %s" % ", ".join(errs))
	runner.check(c.items.size() > 60, "catalog has enough items")


func test_every_shop_category_has_items() -> void:
	var c := _c()
	for cat in ["furniture", "pets", "toys", "care", "clothes_girl", "clothes_pet", "wallfloor", "decor", "devices", "themes", "breeds"]:
		var n: int = c.items_in_category(cat).size()
		runner.check(n >= 2, "category %s has >=2 items (has %d)" % [cat, n])


func test_free_essentials_exist() -> void:
	var c := _c()
	var starters: Array = c.starter_items()
	for profile in ["bed", "desk", "dining", "bowl_food", "bowl_water", "pet_bed", "bath", "groom", "wardrobe"]:
		var found := false
		for id in starters:
			if c.item(id).get("interaction_profile") == profile:
				found = true
		runner.check(found, "free starter for %s" % profile)
	runner.check(c.breeds_of("cat").filter(func(b): return b.get("starter_choice", false)).size() >= 2, "free cat choices")
	runner.check(c.breeds_of("dog").filter(func(b): return b.get("starter_choice", false)).size() >= 2, "free dog choices")


func test_every_item_has_a_shop_place() -> void:
	var c := _c()
	for id in c.items.keys():
		var it: Dictionary = c.items[id]
		if it.get("category", "") == "fixed":
			continue
		var place: Array = ShopCatalog.find_place(it)
		runner.check(place[0] != "", "%s is in a shop section" % id)
	for s in ShopCatalog.SECTIONS:
		for sb in s["subs"]:
			runner.check(c.has_item(sb["rep"]), "tab picture %s exists" % sb["rep"])
			runner.check(ShopCatalog.items_in(s["id"], sb["id"]).size() > 0, "sub-section %s/%s not empty" % [s["id"], sb["id"]])


## Part-built pets: every part picture exists, the rig keeps one fixed scale
## (no size jumps between poses) and the mouth point follows the head.
func test_part_pets_complete_and_stable() -> void:
	for sp in ["dog", "cat"]:
		var r: Dictionary = PetRig.rig(sp)
		runner.check(not r.is_empty(), "%s rig loaded" % sp)
		var names := ["body", "chest", "collar", "tag", "ear_near", "ear_far", "tail_0", "tail_1", "tail_2"]
		for i in 6:
			names.append("head_%d" % i)
		for leg in ["fl", "fr", "bl", "br"]:
			names.append(leg + "_up")
			names.append(leg + "_low")
		for n in names:
			runner.check(PetRig.tex(sp, n) != null, "%s part %s" % [sp, n])
	var b: Dictionary = _c().breeds["dog_buddy"]
	var st := {"body_y": float(b["leg_len"]) + float(b["body_h"]) * 0.35}
	var s1 := PetPainter.skeleton(b, st, 0.0, 0.0, false)
	var o1 := PetRig.solve(b, st, s1, 0.0, 0.0, 0.0)
	var sit := st.duplicate()
	sit["tilt"] = 0.55
	var s2 := PetPainter.skeleton(b, sit, 0.0, 0.0, false)
	var o2 := PetRig.solve(b, sit, s2, 0.0, 0.0, 0.0)
	runner.check(absf(o1["Tb"].get_scale().x - o2["Tb"].get_scale().x) < 0.001, "same size standing and sitting")
	runner.check(o1["mouth"].x > s1["sh"].x, "mouth in front of the shoulders")


func test_prices_live_in_config() -> void:
	var c := _c()
	runner.check(int(c.econ("start_coins", -1)) >= 0, "start coins configured")
	runner.check(int(c.econ("session_reward", -1)) > 0, "session reward configured")
	# the cheapest non-free item must be affordable at start
	var cheapest := 1 << 30
	for id in c.items.keys():
		var p: int = c.price(id)
		if p > 0:
			cheapest = min(cheapest, p)
	runner.check(cheapest <= int(c.econ("start_coins", 0)), "start coins can buy a cheap item")


func test_localization_complete() -> void:
	var loc: Node = runner.root.get_node("Loc")
	var bad: PackedStringArray = loc.validate()
	runner.check(bad.is_empty(), "missing translations: %s" % ", ".join(bad))
	for key in ["ex_count_how_many", "ex_put_n", "ex_where_more", "ex_where_less", "ex_plus", "ex_minus", "ex_first_letter", "ex_find_letter", "ex_missing_letter", "ex_shapes_to_outlines", "ex_find_shape", "ex_what_next", "ex_tap_color", "ex_same_color", "ex_mix", "ex_odd_one"]:
		runner.check(loc.has_key(key), "prompt key %s" % key)
	for s in ExerciseGen.SHAPES:
		runner.check(loc.has_key("shape_" + s), "shape name " + s)
	for col in ExerciseGen.COLORS.keys():
		runner.check(loc.has_key("color_" + col), "color name " + col)
	runner.eq(loc.tl("ex_plus", "ru", [2, 3]), "2 плюс 3 — сколько будет?", "ru format")
	runner.eq(loc.tl("ex_plus", "de", [2, 3]), "2 plus 3 – wie viel ist das?", "de format")


func test_learning_data_separate_per_language() -> void:
	var l: Node = runner.root.get_node("Learning")
	var ru: Dictionary = l.lang_data.get("ru", {})
	var de: Dictionary = l.lang_data.get("de", {})
	runner.check(ru.get("words", []).size() >= 10, "ru words")
	runner.check(de.get("words", []).size() >= 10, "de words")
	runner.check(ru.get("alphabet") != de.get("alphabet"), "different alphabets")
	runner.check(str(de.get("alphabet", "")).contains("Ü"), "german umlauts present")
	runner.check(str(ru.get("alphabet", "")).contains("Ж"), "cyrillic present")
	var ru_words := []
	for w in ru["words"]:
		ru_words.append(w["word"])
	for w in de["words"]:
		runner.check(w["word"] not in ru_words, "de word is not a copy: " + w["word"])


func test_learning_icons_are_drawable() -> void:
	# every icon referenced by learning data must be handled by IconPainter (no blank pictures)
	var src := FileAccess.get_file_as_string("res://scripts/ui/icon_painter.gd")
	var l: Node = runner.root.get_node("Learning")
	for lang in ["ru", "de"]:
		for w in l.lang_data[lang]["words"]:
			runner.check(src.contains('"%s"' % w["icon"]), "icon %s drawable" % w["icon"])
	for seq in ExerciseGen.SEQUENCES:
		for ic in seq:
			runner.check(src.contains('"%s"' % ic), "seq icon %s drawable" % ic)
