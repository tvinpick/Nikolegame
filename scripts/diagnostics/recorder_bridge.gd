class_name RecorderBridge
extends Node
## Bridge to the Kotlin Android plugin "GameRecorder" (MediaProjection + MediaRecorder).
## Audio strategy (no microphone, ever):
##   * The game's own audio mix is recorded inside Godot with AudioEffectRecord
##     on the Master bus -> WAV. This needs NO RECORD_AUDIO permission.
##   * After stop, the plugin encodes that WAV to AAC and muxes it with the
##     silent MediaProjection video into one MP4 (muxWavIntoMp4).
##   * If muxing fails, the report still contains video.mp4 + game_audio.wav
##     and the limitation is written into report.txt (never claimed as success).

signal state_changed(state: String, info: Dictionary)

const PLUGIN := "GameRecorder"
const REC_DIR := "user://dev/recordings"

var plugin: Object = null
var state := "idle"  # idle | requesting | recording | finishing | error
var started_ms := 0
var current_id := ""
var video_path := ""
var audio_path := ""
var final_path := ""
var last_error := ""
var audio_note := ""
var quality := "medium"
var max_minutes := 5
var _rec_effect: AudioEffectRecord = null
var _rec_effect_idx := -1


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(REC_DIR)
	if Engine.has_singleton(PLUGIN):
		plugin = Engine.get_singleton(PLUGIN)
		_connect_plugin()


func available() -> bool:
	return plugin != null


func _connect_plugin() -> void:
	for sig in ["recording_started", "recording_stopped", "recording_error", "mux_finished", "share_result"]:
		if plugin.has_signal(sig):
			plugin.connect(sig, Callable(self, "_on_" + sig))


func video_time_ms() -> int:
	if state != "recording":
		return -1
	return Time.get_ticks_msec() - started_ms


func start() -> bool:
	if state in ["recording", "requesting", "finishing"]:
		return false
	if not available():
		last_error = "plugin_missing"
		state_changed.emit("error", {"error": last_error})
		return false
	var free_mb := int(plugin.call("getFreeSpaceMb"))
	if free_mb >= 0 and free_mb < 200:
		last_error = "low_storage"
		state_changed.emit("error", {"error": last_error, "free_mb": free_mb})
		return false
	current_id = Time.get_datetime_string_from_system(false).replace(":", "").replace("-", "").replace("T", "-")
	video_path = ProjectSettings.globalize_path(REC_DIR.path_join("rec-%s-video.mp4" % current_id))
	audio_path = ProjectSettings.globalize_path(REC_DIR.path_join("rec-%s-audio.wav" % current_id))
	final_path = ProjectSettings.globalize_path(REC_DIR.path_join("rec-%s.mp4" % current_id))
	state = "requesting"
	state_changed.emit(state, {})
	# The Android consent dialog is shown for EVERY session (MediaProjection requirement).
	plugin.call("startRecording", video_path, _bitrate(), max_minutes * 60, 30)
	return true


func _bitrate() -> int:
	match quality:
		"low":
			return 2_500_000
		"high":
			return 10_000_000
	return 5_000_000


func stop() -> void:
	if state != "recording":
		return
	state = "finishing"
	state_changed.emit(state, {})
	_stop_audio_capture()
	plugin.call("stopRecording")


func _on_recording_started() -> void:
	state = "recording"
	started_ms = Time.get_ticks_msec()
	_start_audio_capture()
	Diag.event("recording_started", {"id": current_id})
	state_changed.emit(state, {})


func _on_recording_stopped(path: String, reason: String) -> void:
	_stop_audio_capture()
	Diag.event("recording_stopped", {"reason": reason})
	if FileAccess.file_exists(audio_path) and FileAccess.file_exists(path):
		state = "finishing"
		plugin.call("muxWavIntoMp4", path, audio_path, final_path)
	else:
		final_path = path
		audio_note = "no_game_audio_file"
		state = "idle"
		state_changed.emit("done", {"path": final_path, "audio": audio_note})


func _on_mux_finished(ok: bool, path: String, err: String) -> void:
	state = "idle"
	if ok:
		final_path = path
		audio_note = "game_mix_muxed"
	else:
		final_path = video_path
		audio_note = "mux_failed:" + err
	Diag.event("mux_finished", {"ok": ok, "err": err})
	state_changed.emit("done", {"path": final_path, "audio": audio_note})


func _on_recording_error(err: String) -> void:
	_stop_audio_capture()
	state = "idle"
	last_error = err
	Diag.event("recording_error", {"error": err})
	state_changed.emit("error", {"error": err})


func _on_share_result(_ok: bool, _msg: String) -> void:
	pass


func _start_audio_capture() -> void:
	var bus := AudioServer.get_bus_index("Master")
	_rec_effect = AudioEffectRecord.new()
	_rec_effect.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(bus, _rec_effect)
	_rec_effect_idx = AudioServer.get_bus_effect_count(bus) - 1
	_rec_effect.set_recording_active(true)


func _stop_audio_capture() -> void:
	if _rec_effect == null:
		return
	_rec_effect.set_recording_active(false)
	var wav := _rec_effect.get_recording()
	if wav != null:
		wav.save_to_wav(audio_path)
	var bus := AudioServer.get_bus_index("Master")
	if _rec_effect_idx >= 0 and _rec_effect_idx < AudioServer.get_bus_effect_count(bus):
		AudioServer.remove_bus_effect(bus, _rec_effect_idx)
	_rec_effect = null
	_rec_effect_idx = -1


func list_recordings() -> Array:
	var out: Array = []
	var d := DirAccess.open(REC_DIR)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".mp4") or f.ends_with(".wav"):
			var p := REC_DIR.path_join(f)
			var fa := FileAccess.open(p, FileAccess.READ)
			var size := fa.get_length() if fa else 0
			out.append({"name": f, "path": p, "size": size})
	return out


func delete_recording(path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func share(path: String, mime: String) -> bool:
	if not available():
		return false
	plugin.call("shareFile", ProjectSettings.globalize_path(path), mime)
	return true
