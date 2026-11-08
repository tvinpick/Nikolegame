extends RefCounted
## Atomic save, backup recovery after interrupted/corrupt writes, migrations.

var runner: Object


func _save() -> Node:
	return runner.root.get_node("Save")


func _gs() -> Node:
	return runner.root.get_node("GameState")


func before_each() -> void:
	runner.root.get_node("Economy").new_game()
	for f in ["progress.json", "progress.bak.json", "progress.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_save().save_dir.path_join(f)))


func test_roundtrip() -> void:
	var gs := _gs()
	gs.data["coins"] = 77
	gs.data["girl"]["appearance"]["hair_style"] = "buns"
	runner.check(_save().save_now(), "saved")
	gs.data = gs.default_state()
	runner.eq(_save().load_game(), "main", "loaded main")
	runner.eq(gs.coins(), 77, "coins")
	runner.eq(gs.appearance()["hair_style"], "buns", "appearance")
	runner.check(typeof(gs.data["coins"]) == TYPE_INT, "coins is int after JSON")


func test_corrupt_main_falls_back_to_backup() -> void:
	var gs := _gs()
	gs.data["coins"] = 10
	_save().save_now()
	gs.data["coins"] = 20
	_save().save_now()   # backup now has 10, main has 20
	var f := FileAccess.open(_save().main_path(), FileAccess.WRITE)
	f.store_string("{ broken json")
	f.close()
	gs.data = gs.default_state()
	runner.eq(_save().load_game(), "backup", "used backup")
	runner.eq(gs.coins(), 10, "last good state")


func test_interrupted_write_tmp_recovered() -> void:
	var gs := _gs()
	gs.data["coins"] = 33
	_save().save_now()
	# simulate crash after tmp was written but before rename, with no main/bak
	var text := FileAccess.get_file_as_string(_save().main_path())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_save().main_path()))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_save().backup_path()))
	var f := FileAccess.open(_save().tmp_path(), FileAccess.WRITE)
	f.store_string(text)
	f.close()
	gs.data = gs.default_state()
	runner.eq(_save().load_game(), "tmp", "recovered from tmp")
	runner.eq(gs.coins(), 33, "coins recovered")


func test_migration_v1_to_current() -> void:
	var v1 := {"schema_version": 1, "money": 42, "furniture": [{"id": "bed_rose", "pos": [500, 800]}, {"id": "sofa_mint", "pos": [3000, 790]}], "owned": {"bed_rose": 1, "sofa_mint": 1}, "pets": {}, "settings": {}}
	var d: Dictionary = _save().parse_and_upgrade(JSON.stringify(v1))
	runner.check(not d.is_empty(), "migrated")
	runner.eq(int(d["schema_version"]), SaveMigrations.CURRENT, "schema current")
	runner.eq(int(d["coins"]), 42, "money -> coins")
	runner.eq(d["instances"].size(), 2, "furniture -> instances")
	runner.check(d["learning"].has("limits"), "v3 limits added")
	runner.check(d["daily"].has("max_seen_unix"), "v3 daily guard added")
	runner.check(d.has("surfaces"), "v2 surfaces")


func test_validation_rejects_bad_data() -> void:
	runner.check(SaveMigrations.validate({"coins": -5, "owned": {}, "instances": [], "pets": {}, "settings": {}}).size() > 0, "negative coins rejected")
	runner.check(SaveMigrations.validate({"coins": 5, "owned": {}, "instances": [{"uid": 1, "item_id": "a"}, {"uid": 1, "item_id": "b"}], "pets": {}, "settings": {}}).size() > 0, "duplicate uid rejected")


func test_backup_export_import() -> void:
	var gs := _gs()
	gs.data["coins"] = 123
	var path: String = _save().make_export_file()
	runner.check(path != "", "export written")
	var info: Dictionary = _save().inspect_backup(path)
	runner.check(not info.is_empty(), "backup readable")
	runner.eq(int(info.get("coins", -1)), 123, "backup coins")
	gs.data["coins"] = 1
	runner.check(_save().apply_backup(info), "restored")
	runner.eq(gs.coins(), 123, "coins restored")
	runner.check(_save().inspect_backup("res://project.godot").is_empty(), "non-backup rejected")


func test_offline_needs_bounded() -> void:
	var cfg: Dictionary = runner.root.get_node("Content").econ("needs", {})
	var n := {"satiety": 90.0, "energy": 90.0, "mood": 90.0, "cleanliness": 90.0}
	var a: Dictionary = Room.offline_needs(n, 10.0 * 24 * 3600, cfg)  # 10 days away
	for k in a:
		runner.check(a[k] >= float(cfg.get("offline_floor", 25.0)) - 0.01, "%s not below floor" % k)
	var low := {"satiety": 10.0, "energy": 10.0, "mood": 10.0, "cleanliness": 10.0}
	var b: Dictionary = Room.offline_needs(low, 3600 * 5, cfg)
	for k in b:
		runner.eq(b[k], 10.0, "%s not worsened when already low" % k)
	var c: Dictionary = Room.offline_needs(n, -99999, cfg)
	runner.eq(c, n, "clock rollback changes nothing")


func test_migration_v3_moves_untouched_starters_into_zones() -> void:
	var gs := _gs()
	var d: Dictionary = gs.default_state()
	d["schema_version"] = 3
	d["coins"] = 5
	d["owned"] = {"bed_rose": 1, "desk_wood": 1}
	d["instances"] = [
		{"uid": 1, "item_id": "bed_rose", "x": 660.0, "y": 832.0, "flip": false, "state": {}},   # old default -> moves
		{"uid": 2, "item_id": "desk_wood", "x": 1234.0, "y": 900.0, "flip": false, "state": {}}, # child moved it -> stays
	]
	var m: Dictionary = _save().parse_and_upgrade(JSON.stringify(d))
	runner.eq(int(m["schema_version"]), SaveMigrations.CURRENT, "schema current")
	runner.eq(Vector2(m["instances"][0]["x"], m["instances"][0]["y"]), Vector2(680, 800), "bed moved into bedroom zone")
	runner.eq(Vector2(m["instances"][1]["x"], m["instances"][1]["y"]), Vector2(1234, 900), "child's own placement kept")
