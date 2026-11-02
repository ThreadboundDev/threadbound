extends Logger
## Bounded, thread-safe diagnostics. Never logs from inside a logger callback.

const LIMIT := 300
var _mutex := Mutex.new()
var _entries: Array[Dictionary] = []
var _error_count := 0
var _warning_count := 0

func _log_message(message: String, error: bool) -> void:
	_append({"level": "stderr" if error else "info", "message": message.left(4096)})

func _log_error(function: String, file: String, line: int, code: String,
		rationale: String, _editor_notify: bool, error_type: int,
		script_backtraces: Array[ScriptBacktrace]) -> void:
	var traces: Array[String] = []
	for trace in script_backtraces:
		traces.append(trace.format().left(8192))
	_append({"level": "warning" if error_type == ERROR_TYPE_WARNING else "error",
		"error_type": error_type, "function": function, "file": file, "line": line,
		"message": (rationale if not rationale.is_empty() else code).left(4096),
		"backtraces": traces})

func _append(entry: Dictionary) -> void:
	entry["ticks_msec"] = Time.get_ticks_msec()
	_mutex.lock()
	if entry.level == "error":
		_error_count += 1
	elif entry.level == "warning":
		_warning_count += 1
	_entries.append(entry)
	if _entries.size() > LIMIT:
		_entries.pop_front()
	_mutex.unlock()

func snapshot() -> Dictionary:
	_mutex.lock()
	var result := {"errors_since_start": _error_count, "warnings_since_start": _warning_count,
		"recent": _entries.duplicate(true), "retained_limit": LIMIT}
	_mutex.unlock()
	return result
