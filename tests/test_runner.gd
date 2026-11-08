extends SceneTree
## Headless test runner:  godot --headless --path . -s tests/test_runner.gd [-- --only=name --report=path]
## Discovers tests/test_*.gd, runs every func test_*() (may be async), prints a
## summary, writes a JSON report, exits with code 1 on any failure.

var results: Array = []
var current := ""
var failures: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# autoloads are ready at this point; never touch the child's real save
	var save: Node = root.get_node("Save")
	save.save_dir = "user://test_save"
	save.suspended = false
	DirAccess.make_dir_recursive_absolute(save.save_dir)
	var only := ""
	var report := "user://test_report.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
		elif a.begins_with("--report="):
			report = a.substr(9)
	var files: Array = []
	var d := DirAccess.open("res://tests")
	for f in d.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_runner.gd":
			files.append(f)
	files.sort()
	var t0 := Time.get_ticks_msec()
	for f in files:
		if only != "" and not f.contains(only):
			continue
		var script: GDScript = load("res://tests/" + f)
		var inst: Object = script.new()
		if inst.has_method("setup"):
			inst.set("tree", self)
		for m in inst.get_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			current = "%s::%s" % [f.get_basename(), name]
			failures = []
			inst.set("runner", self)
			if inst.has_method("before_each"):
				await inst.call("before_each")
			var start := Time.get_ticks_msec()
			await inst.call(name)
			if inst.has_method("after_each"):
				await inst.call("after_each")
			var ok := failures.is_empty()
			results.append({"name": current, "ok": ok, "ms": Time.get_ticks_msec() - start, "failures": failures.duplicate()})
			print(("  PASS " if ok else "  FAIL ") + current + ("" if ok else "\n      " + "\n      ".join(failures)))
	var passed := 0
	for r in results:
		if r["ok"]:
			passed += 1
	var summary := {"total": results.size(), "passed": passed, "failed": results.size() - passed, "ms": Time.get_ticks_msec() - t0, "godot": Engine.get_version_info().get("string", ""), "results": results}
	var f2 := FileAccess.open(report, FileAccess.WRITE)
	if f2:
		f2.store_string(JSON.stringify(summary, "\t"))
		f2.close()
	print("\nTESTS: %d passed, %d failed (%d ms)" % [passed, results.size() - passed, summary["ms"]])
	quit(0 if passed == results.size() else 1)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func eq(a: Variant, b: Variant, msg: String) -> void:
	if a != b:
		failures.append("%s (got %s, expected %s)" % [msg, str(a), str(b)])
