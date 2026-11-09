extends Node
## Local, versioned, atomic save with last-good backup.
## Write path: serialize -> progress.tmp -> verify by re-parsing -> current file
## becomes progress.bak -> tmp renamed to progress.json.
## Coins + items live in ONE file, so a purchase is atomic by construction.

signal saved(ok: bool)
signal loaded(source: String)

const DIR := "user://save"
const MAIN := "user://save/progress.json"
const BACKUP := "user://save/progress.bak.json"
const TMP := "user://save/progress.tmp"
const EXPORT_DIR := "user://exports"
const BACKUP_TYPE := "skazochny_domik_backup"

var save_dir: String = DIR
var _dirty := false
var _debounce := 0.0
var last_load_source := ""
var save_count := 0
var suspended := false  # tests may disable disk writes
var pre_save: Callable = Callable()  # copies runtime state (positions, needs) into GameState


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(save_dir)
	process_mode = Node.PROCESS_MODE_ALWAYS


func main_path() -> String:
	return save_dir.path_join("progress.json")


func backup_path() -> String:
	return save_dir.path_join("progress.bak.json")


func tmp_path() -> String:
	return save_dir.path_join("progress.tmp")


func _process(delta: float) -> void:
	if _dirty:
		_debounce -= delta
		if _debounce <= 0.0:
			save_now()


## Request an autosave soon (coalesces bursts; never every frame).
func request_save(reason: String = "") -> void:
	_dirty = true
	_debounce = 0.6
	if reason != "":
		Diag.event("save_requested", {"reason": reason})


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST:
			if GameState.data.size() > 0 and last_load_source != "":
				save_now()
			if what == NOTIFICATION_WM_CLOSE_REQUEST:
				get_tree().quit()


func save_now() -> bool:
	_dirty = false
	if suspended:
		return true
	if pre_save.is_valid():
		pre_save.call()
	var d: Dictionary = GameState.data
	d["schema_version"] = SaveMigrations.CURRENT
	var now := int(Time.get_unix_time_from_system())
	d["saved_unix"] = now
	d["last_seen_unix"] = now
	var ok := write_atomic(d)
	save_count += 1
	Diag.event("save", {"ok": ok, "n": save_count})
	saved.emit(ok)
	return ok


func write_atomic(d: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(save_dir)
	var text := JSON.stringify(d, "", false)
	var f := FileAccess.open(tmp_path(), FileAccess.WRITE)
	if f == null:
		push_error("Save: cannot open tmp (%s)" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(text)
	f.flush()
	f.close()
	# verify what hit the disk before replacing the good file
	var check := FileAccess.get_file_as_string(tmp_path())
	var parsed: Variant = JSON.parse_string(check)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save: tmp verification failed")
		return false
	var abs_main := ProjectSettings.globalize_path(main_path())
	var abs_bak := ProjectSettings.globalize_path(backup_path())
	var abs_tmp := ProjectSettings.globalize_path(tmp_path())
	if FileAccess.file_exists(main_path()):
		if FileAccess.file_exists(backup_path()):
			DirAccess.remove_absolute(abs_bak)
		DirAccess.rename_absolute(abs_main, abs_bak)
	var err := DirAccess.rename_absolute(abs_tmp, abs_main)
	if err != OK:
		push_error("Save: rename failed %s" % error_string(err))
		return false
	return true


## Loads progress into GameState. Returns source: "main", "backup", "new".
func load_game() -> String:
	var src := "new"
	var d: Dictionary = {}
	var main := _read_valid(main_path())
	if not main.is_empty():
		d = main
		src = "main"
	else:
		if FileAccess.file_exists(main_path()):
			_quarantine(main_path())
		var bak := _read_valid(backup_path())
		if not bak.is_empty():
			d = bak
			src = "backup"
	if d.is_empty():
		var tmp := _read_valid(tmp_path())  # interrupted write that finished writing tmp
		if not tmp.is_empty():
			d = tmp
			src = "tmp"
	if d.is_empty():
		GameState.data = GameState.default_state()
	else:
		GameState.data = d
	last_load_source = src
	Diag.event("load", {"source": src, "schema": int(GameState.data.get("schema_version", 0))})
	loaded.emit(src)
	return src


func _read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	return parse_and_upgrade(text)


## Parse JSON text, migrate and validate. Returns {} if unusable.
func parse_and_upgrade(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = parsed
	if d.get("type", "") == BACKUP_TYPE and d.has("progress"):
		d = d["progress"]
	d = SaveMigrations.migrate(d)
	d = SaveMigrations.deep_fill(d, GameState.default_state())
	_fix_types(d)
	if SaveMigrations.validate(d).size() > 0:
		return {}
	return d


## JSON turns ints into floats; normalize the fields we compare as ints.
func _fix_types(d: Dictionary) -> void:
	d["coins"] = int(d.get("coins", 0))
	d["next_uid"] = int(d.get("next_uid", 1))
	var owned: Dictionary = d.get("owned", {})
	for k in owned.keys():
		owned[k] = int(owned[k])
	var cons: Dictionary = d.get("consumables", {})
	for k in cons.keys():
		cons[k] = int(cons[k])
	for inst in d.get("instances", []):
		if typeof(inst) == TYPE_DICTIONARY:
			inst["uid"] = int(inst.get("uid", 0))
			if inst.has("host_uid"):
				inst["host_uid"] = int(inst["host_uid"])


func _quarantine(path: String) -> void:
	var stamp := Time.get_datetime_string_from_system(false).replace(":", "").replace("-", "").replace("T", "-")
	DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(save_dir.path_join("progress.corrupt-%s.json" % stamp)))
	Diag.event("save_quarantined", {"file": path.get_file()})


# ---------------------------------------------------------------- export/import

func make_export_file() -> String:
	save_now()
	DirAccess.make_dir_recursive_absolute(EXPORT_DIR)
	var stamp := Time.get_datetime_string_from_system(false).replace(":", "").replace("-", "").replace("T", "-")
	var path := EXPORT_DIR.path_join("domik-backup-%s.json" % stamp)
	var wrapper := {
		"type": BACKUP_TYPE,
		"created_unix": int(Time.get_unix_time_from_system()),
		"created_text": Time.get_datetime_string_from_system(false, true),
		"game_version": ProjectSettings.get_setting("application/config/version", "0"),
		"test_build": GameState.is_test_build,
		"progress": GameState.data,
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(wrapper, "\t"))
	f.close()
	return path


## Inspect a backup file (for the confirmation dialog). Returns {} if invalid.
func inspect_backup(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("type", "") != BACKUP_TYPE:
		return {}
	var d := parse_and_upgrade(text)
	if d.is_empty():
		return {}
	return {"created_text": parsed.get("created_text", "?"), "coins": int(d.get("coins", 0)), "test_build": parsed.get("test_build", false), "data": d}


func apply_backup(info: Dictionary) -> bool:
	if info.is_empty():
		return false
	save_now()  # current progress becomes the backup file, so restore is undoable once
	GameState.data = info["data"]
	var ok := save_now()
	Diag.event("backup_restored", {"ok": ok})
	return ok
