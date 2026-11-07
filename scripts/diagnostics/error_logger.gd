class_name DiagErrorLogger
extends Logger
## Captures engine/script errors and warnings into the diagnostics buffer.
## Logger callbacks may run on any thread -> guarded by a mutex.

var _mutex := Mutex.new()
var lines: PackedStringArray = PackedStringArray()
const MAX_LINES := 2000


func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	var kind := "ERROR"
	match error_type:
		ERROR_TYPE_WARNING:
			kind = "WARNING"
		ERROR_TYPE_SCRIPT:
			kind = "SCRIPT_ERROR"
		ERROR_TYPE_SHADER:
			kind = "SHADER_ERROR"
	var msg := "%d %s %s:%d %s() %s %s" % [Time.get_ticks_msec(), kind, file, line, function, code, rationale]
	for bt in script_backtraces:
		if bt != null:
			msg += "\n" + str(bt.format(2, 2))
	_append(msg)


func _log_message(message: String, error: bool) -> void:
	if error:
		_append("%d STDERR %s" % [Time.get_ticks_msec(), message.strip_edges()])


func _append(s: String) -> void:
	_mutex.lock()
	lines.append(s)
	if lines.size() > MAX_LINES:
		lines = lines.slice(lines.size() - MAX_LINES)
	_mutex.unlock()


func snapshot() -> PackedStringArray:
	_mutex.lock()
	var c := lines.duplicate()
	_mutex.unlock()
	return c


func count() -> int:
	_mutex.lock()
	var n := lines.size()
	_mutex.unlock()
	return n
