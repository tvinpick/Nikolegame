extends Node
## Developer diagnostics: event ring buffer, performance metrics, error capture,
## bug marks, test-state snapshots and ZIP report export.
## Nothing here is sent anywhere automatically. Events live in RAM only; they
## are written to disk only when an adult creates a report in developer mode.

signal overlay_toggled(on: bool)
signal mark_added(mark: Dictionary)

const DEV_DIR := "user://dev"
const REPORT_DIR := "user://dev/reports"
const SHOT_DIR := "user://dev/screenshots"
const MAX_EVENTS := 4000
const FRAME_RING := 3600

var events: Array = []
var frame_times := PackedFloat32Array()
var _ft_idx := 0
var perf_rows: Array = []        # one row per second
var marks: Array = []
var long_frames := 0
var overlay_on := false
var logger: DiagErrorLogger
var recorder: RecorderBridge
var state_provider: Callable = Callable()
var command_log: Array = []      # player commands for limited replay
var rng_seed: int = 0
var _sec_acc := 0.0
var _frames_in_sec := 0
var _ft_sec := PackedFloat32Array()
var session_start_ms := 0
var build_id := ""
var load_times: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	session_start_ms = Time.get_ticks_msec()
	frame_times.resize(FRAME_RING)
	logger = DiagErrorLogger.new()
	OS.add_logger(logger)
	recorder = RecorderBridge.new()
	recorder.name = "Recorder"
	add_child(recorder)
	for d in [DEV_DIR, REPORT_DIR, SHOT_DIR]:
		DirAccess.make_dir_recursive_absolute(d)
	build_id = "%s%s" % [ProjectSettings.get_setting("application/config/version", "0"), "-test" if OS.has_feature("test_build") else ""]
	rng_seed = int(Time.get_unix_time_from_system()) % 100000
	seed(rng_seed)
	event("boot", {"build": build_id, "seed": rng_seed})


func set_seed(s: int) -> void:
	rng_seed = s
	seed(s)
	event("seed", {"seed": s})


func event(name: String, data: Dictionary = {}) -> void:
	events.append({"t": Time.get_ticks_msec() - session_start_ms, "f": Engine.get_process_frames(), "e": name, "d": data})
	if events.size() > MAX_EVENTS:
		events = events.slice(events.size() - MAX_EVENTS)


func command(cmd: Dictionary) -> void:
	var c := cmd.duplicate()
	c["t"] = Time.get_ticks_msec() - session_start_ms
	command_log.append(c)
	if command_log.size() > 500:
		command_log.pop_front()
	event("cmd", cmd)


func _process(delta: float) -> void:
	var ms := delta * 1000.0
	frame_times[_ft_idx % FRAME_RING] = ms
	_ft_idx += 1
	_ft_sec.append(ms)
	if ms > 50.0:
		long_frames += 1
		if ms > 100.0:
			event("long_frame", {"ms": snappedf(ms, 0.1)})
	_sec_acc += delta
	if _sec_acc >= 1.0:
		_sec_acc -= 1.0
		_push_perf_row()


func _push_perf_row() -> void:
	var arr := Array(_ft_sec)
	arr.sort()
	var n := arr.size()
	var row := {
		"t_s": snappedf((Time.get_ticks_msec() - session_start_ms) / 1000.0, 0.1),
		"fps": Engine.get_frames_per_second(),
		"avg_ms": _avg(arr),
		"p50_ms": arr[int(n * 0.5)] if n > 0 else 0.0,
		"p95_ms": arr[min(n - 1, int(n * 0.95))] if n > 0 else 0.0,
		"p99_ms": arr[min(n - 1, int(n * 0.99))] if n > 0 else 0.0,
		"max_ms": arr[n - 1] if n > 0 else 0.0,
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"static_mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"video_mem_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"recording": recorder.state == "recording",
	}
	perf_rows.append(row)
	if perf_rows.size() > 3600:
		perf_rows.pop_front()
	_ft_sec.clear()


static func _avg(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for v in a:
		s += float(v)
	return s / a.size()


## 1%-low FPS over the frame ring.
func one_percent_low_fps() -> float:
	var n: int = min(_ft_idx, FRAME_RING)
	if n < 10:
		return 0.0
	var arr := Array(frame_times.slice(0, n))
	arr.sort()
	var worst := arr.slice(int(n * 0.99))
	var avg := _avg(worst)
	return 1000.0 / avg if avg > 0 else 0.0


func toggle_overlay() -> void:
	set_overlay(not overlay_on)


func set_overlay(on: bool) -> void:
	overlay_on = on
	overlay_toggled.emit(on)
	event("overlay", {"on": on})


func dev_allowed() -> bool:
	return GameState.is_test_build or bool(GameState.setting("dev_mode", false))


## "Отметить ошибку": screenshot + state + ring buffer position + video timestamp.
func mark_bug(note: String = "") -> Dictionary:
	var stamp := Time.get_ticks_msec() - session_start_ms
	var shot := SHOT_DIR.path_join("mark-%d.png" % stamp)
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(shot)
	var m := {
		"t": stamp,
		"video_ms": recorder.video_time_ms(),
		"note": note,
		"screenshot": shot,
		"event_index": events.size(),
		"state": capture_state(),
	}
	marks.append(m)
	event("bug_mark", {"t": stamp, "video_ms": m["video_ms"]})
	mark_added.emit(m)
	return m


func capture_state() -> Dictionary:
	if state_provider.is_valid():
		return state_provider.call()
	return {}


func device_info() -> Dictionary:
	return {
		"model": OS.get_model_name(),
		"os": OS.get_name(),
		"os_version": OS.get_version(),
		"processor": OS.get_processor_name(),
		"cores": OS.get_processor_count(),
		"locale": OS.get_locale(),
		"screen_size": DisplayServer.screen_get_size(),
		"screen_refresh": DisplayServer.screen_get_refresh_rate(),
		"screen_dpi": DisplayServer.screen_get_dpi(),
		"window_size": DisplayServer.window_get_size(),
		"safe_area": DisplayServer.get_display_safe_area(),
		"renderer": RenderingServer.get_current_rendering_driver_name(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"godot": Engine.get_version_info().get("string", ""),
		"build": build_id,
		"test_build": GameState.is_test_build,
	}


## Strip anything child-personal: learning history detail, backup timestamps.
func sanitized_state(include_learning := false) -> Dictionary:
	var d: Dictionary = GameState.data.duplicate(true)
	if not include_learning:
		var l: Dictionary = d.get("learning", {})
		d["learning"] = {"levels": l.get("levels", {}), "limits": l.get("limits", {})}
	d.erase("tx_log")
	d.erase("created_unix")
	return {"progress": d, "scene": capture_state(), "seed": rng_seed, "commands": command_log}


## Build list of files for the report (shown to the adult before zipping).
func report_manifest() -> Array:
	var files: Array = [
		{"name": "events.jsonl", "kind": "events", "include": true},
		{"name": "performance.csv", "kind": "perf", "include": true},
		{"name": "errors.log", "kind": "errors", "include": true},
		{"name": "device.json", "kind": "device", "include": true},
		{"name": "test_scene_state.json", "kind": "state", "include": true},
		{"name": "report.txt", "kind": "report", "include": true},
	]
	for m in marks:
		if FileAccess.file_exists(m["screenshot"]):
			files.append({"name": "screenshots/" + str(m["screenshot"]).get_file(), "kind": "shot", "src": m["screenshot"], "include": true})
	var rec := recorder.final_path
	if rec != "" and FileAccess.file_exists(rec):
		files.append({"name": "video.mp4", "kind": "video", "src": rec, "include": true})
	if recorder.audio_path != "" and FileAccess.file_exists(recorder.audio_path) and recorder.audio_note != "game_mix_muxed":
		files.append({"name": "game_audio.wav", "kind": "audio", "src": recorder.audio_path, "include": true})
	return files


func export_report(summary: String, manifest: Array = []) -> String:
	if manifest.is_empty():
		manifest = report_manifest()
	var stamp := Time.get_datetime_string_from_system(false).replace(":", "").replace("-", "").replace("T", "-")
	var path := REPORT_DIR.path_join("bug-report-%s.zip" % stamp)
	var zip := ZIPPacker.new()
	if zip.open(path) != OK:
		push_error("Diag: cannot create zip")
		return ""
	for f in manifest:
		if not f.get("include", true):
			continue
		var bytes := PackedByteArray()
		match f["kind"]:
			"events":
				var sb := PackedStringArray()
				for e in events:
					sb.append(JSON.stringify(e))
				bytes = "\n".join(sb).to_utf8_buffer()
			"perf":
				bytes = _perf_csv().to_utf8_buffer()
			"errors":
				bytes = "\n".join(logger.snapshot()).to_utf8_buffer()
			"device":
				bytes = JSON.stringify(device_info(), "\t").to_utf8_buffer()
			"state":
				bytes = JSON.stringify(sanitized_state(), "\t").to_utf8_buffer()
			"report":
				bytes = _report_txt(summary, manifest).to_utf8_buffer()
			_:
				bytes = FileAccess.get_file_as_bytes(f["src"])
		zip.start_file(f["name"])
		zip.write_file(bytes)
		zip.close_file()
	zip.close()
	event("report_exported", {"file": path.get_file()})
	return path


func _perf_csv() -> String:
	var cols := ["t_s", "fps", "avg_ms", "p50_ms", "p95_ms", "p99_ms", "max_ms", "process_ms", "physics_ms", "nodes", "objects", "static_mem_mb", "video_mem_mb", "draw_calls", "recording"]
	var lines := PackedStringArray([",".join(cols)])
	for r in perf_rows:
		var vals := PackedStringArray()
		for c in cols:
			var v: Variant = r.get(c, "")
			vals.append(str(snappedf(v, 0.01)) if typeof(v) == TYPE_FLOAT else str(v))
		lines.append(",".join(vals))
	return "\n".join(lines)


func _report_txt(summary: String, manifest: Array) -> String:
	var s := PackedStringArray()
	s.append("Мой сказочный домик — диагностический отчёт")
	s.append("build: %s   godot: %s" % [build_id, Engine.get_version_info().get("string", "")])
	s.append("device: %s / %s %s" % [OS.get_model_name(), OS.get_name(), OS.get_version()])
	s.append("session length: %.1f s   seed: %d" % [(Time.get_ticks_msec() - session_start_ms) / 1000.0, rng_seed])
	s.append("fps now: %.0f   1%%-low: %.1f   long frames (>50ms): %d" % [Engine.get_frames_per_second(), one_percent_low_fps(), long_frames])
	s.append("errors captured: %d" % logger.count())
	s.append("")
	s.append("Описание:")
	s.append(summary if summary != "" else "(нет)")
	s.append("")
	s.append("Отметки (%d):" % marks.size())
	for m in marks:
		s.append("  t=%.1fs video=%s note=%s" % [m["t"] / 1000.0, ("%.1fs" % (m["video_ms"] / 1000.0)) if int(m["video_ms"]) >= 0 else "—", m["note"]])
	s.append("")
	s.append("Видео/звук: %s" % _video_note())
	s.append("Файлы:")
	for f in manifest:
		if f.get("include", true):
			s.append("  " + f["name"])
	s.append("")
	s.append("Replay: фиксированный seed + журнал команд в test_scene_state.json. Повторяемость физики и расписания ОС НЕ гарантируется.")
	s.append("Личные данные ребёнка и полная история обучения по умолчанию не включены.")
	return "\n".join(s)


func _video_note() -> String:
	if recorder.final_path == "":
		return "запись не велась"
	match recorder.audio_note:
		"game_mix_muxed":
			return "MP4 с микшем звука игры (записан внутри Godot, микрофон не используется)"
		"no_game_audio_file":
			return "ВНИМАНИЕ: видео без звука — файл звука игры не создан"
	if recorder.audio_note.begins_with("mux_failed"):
		return "ВНИМАНИЕ: видео без звука (ошибка объединения: %s); звук игры приложен отдельно game_audio.wav" % recorder.audio_note
	return recorder.audio_note


func list_reports() -> Array:
	var out: Array = []
	var d := DirAccess.open(REPORT_DIR)
	if d:
		for f in d.get_files():
			if f.ends_with(".zip"):
				out.append(REPORT_DIR.path_join(f))
	out.sort()
	return out


func share_report(path: String) -> bool:
	return recorder.share(path, "application/zip")
