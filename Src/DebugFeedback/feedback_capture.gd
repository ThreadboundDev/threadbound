extends Node
## Development-only local feedback inbox, owned by the existing DebugUI autoload.

const Snapshot := preload("res://Src/DebugFeedback/feedback_snapshot.gd")
const FeedbackLogger := preload("res://Src/DebugFeedback/feedback_logger.gd")
const Recorder := preload("res://Src/DebugFeedback/feedback_recorder.gd")
const PANEL := preload("res://Src/UI/DebugFeedback/debug_feedback_panel.tscn")

var inbox := ""
var session_directory := ""
var report_directory := ""
var report: Dictionary = {}
var source: Dictionary = {}
var breadcrumbs: Array[Dictionary] = []
var recent_inputs: Array[Dictionary] = []
var logger := FeedbackLogger.new()
var recorder: RefCounted
var panel: Window
var badge: Label
var recovered_sessions: Array[String] = []
var storage_error := ""
var _layer: CanvasLayer
var _paused_before := false
var _mouse_before := Input.MOUSE_MODE_VISIBLE
var _focus_before: WeakRef
var _pending_screenshot := false
var _last_sample := 0
var _last_flush := 0
var _serial := 0
var _registered_logger := false
var _readback_pending := false
var _recording_generation := 0
var _readback_deadline := 0
var _readback_mode := ""

func _ready() -> void:
	if not OS.is_debug_build():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	OS.add_logger(logger)
	_registered_logger = true
	inbox = _choose_inbox()
	source = _source_version()
	if not inbox.is_empty():
		_find_unclosed_sessions()
		session_directory = inbox.path_join("sessions").path_join(_identifier())
		var error := DirAccess.make_dir_recursive_absolute(session_directory)
		if error != OK:
			storage_error = "Could not create session folder: " + error_string(error)
	_build_controls()
	RenderingServer.frame_post_draw.connect(_after_draw)
	_sample()
	_flush_session(false)

func _choose_inbox() -> String:
	var candidates: Array[String] = []
	# Explicit override makes automated checks independent of real playtest reports.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--feedback-inbox="):
			candidates.append(ProjectSettings.globalize_path(argument.trim_prefix("--feedback-inbox=")))
	if candidates.is_empty() and OS.has_feature("editor"):
		candidates.append(ProjectSettings.globalize_path("res://LocalOnly/Feedback"))
	candidates.append(ProjectSettings.globalize_path("user://feedback"))
	for candidate in candidates:
		if DirAccess.make_dir_recursive_absolute(candidate) != OK:
			continue
		var probe := candidate.path_join(".write_probe_%s" % OS.get_process_id())
		var file := FileAccess.open(probe, FileAccess.WRITE)
		if file:
			file.close()
			DirAccess.remove_absolute(probe)
			# Self-contained guards also protect a checkout whose root ignore file differs.
			if write_text(candidate.path_join(".gitignore"), "*\n") != OK:
				continue
			if write_text(candidate.path_join(".gdignore"), "") != OK:
				continue
			return candidate
	storage_error = "Feedback storage is not writable. Free space or choose a writable --feedback-inbox folder."
	return ""

func _identifier() -> String:
	_serial += 1
	return "%s_%d_%d_%d" % [Time.get_datetime_string_from_system(true).replace(":", "-"),
		OS.get_process_id(), Time.get_ticks_msec(), _serial]

func _source_version() -> Dictionary:
	var result := {"revision": "unavailable in exported build", "checked_utc": Time.get_datetime_string_from_system(true) + "Z"}
	if not OS.has_feature("editor"):
		return result
	var output: Array = []
	var path := ProjectSettings.globalize_path("res://")
	if OS.execute("git", ["-C", path, "rev-parse", "HEAD"], output, false, false) == 0:
		result.revision = str(output[0]).strip_edges()
	output.clear()
	if OS.execute("git", ["-C", path, "branch", "--show-current"], output, false, false) == 0:
		result["branch"] = str(output[0]).strip_edges()
	output.clear()
	if OS.execute("git", ["-C", path, "status", "--porcelain", "--untracked-files=normal"], output, false, false) == 0:
		var status := str(output[0]).strip_edges()
		result["dirty"] = not status.is_empty()
		result["working_tree_status"] = status.left(20000)
		result["status_truncated"] = status.length() > 20000
	return result

func _build_controls() -> void:
	panel = PANEL.instantiate()
	panel.name = "FeedbackPanel"
	add_child(panel)
	panel.configure(self)
	_layer = CanvasLayer.new()
	_layer.layer = 126
	add_child(_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.position = Vector2(-310, -112)
	box.custom_minimum_size = Vector2(295, 95)
	root.add_child(box)
	badge = Label.new()
	badge.text = "DEV FEEDBACK · saved locally"
	badge.add_theme_font_size_override("font_size", 15)
	box.add_child(badge)
	for entry in [["Feedback  Ctrl+F1", request_feedback], ["Record clip  Ctrl+F2", toggle_recording]]:
		var button := Button.new()
		button.text = entry[0]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(entry[1])
		box.add_child(button)

func _input(event: InputEvent) -> void:
	if not panel.visible:
		_record_input(event)
	if not event is InputEventKey or not event.pressed or event.echo or not event.ctrl_pressed:
		return
	if event.keycode == KEY_F1 or event.keycode == KEY_F2:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_F1:
			request_feedback()
		else:
			toggle_recording()

func _record_input(event: InputEvent) -> void:
	# Record bound gameplay actions, never arbitrary keys or feedback text.
	if event is InputEventMouseMotion or event is InputEventJoypadMotion:
		return
	if event is InputEventKey and event.echo:
		return
	for action in InputMap.get_actions():
		if str(action).begins_with("ui_") or not event.is_action(action):
			continue
		recent_inputs.append({"ticks_msec": Time.get_ticks_msec(), "action": str(action),
			"pressed": event.is_pressed(), "strength": event.get_action_strength(action)})
		if recent_inputs.size() > 120:
			recent_inputs.pop_front()

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - _last_sample >= 500:
		_sample()
	if Time.get_ticks_msec() - _last_flush >= 2000:
		_flush_session(false)
	if recorder:
		badge.text = "RECORDING %.1fs / 20s · Ctrl+F2 to finish" % recorder.elapsed()
		if recorder.full():
			request_feedback()

func _sample() -> void:
	_last_sample = Time.get_ticks_msec()
	# Do not fill the useful pre-report history with the paused feedback form.
	if panel and panel.visible:
		return
	breadcrumbs.append(Snapshot.collect(get_tree(), false))
	if breadcrumbs.size() > 60:
		breadcrumbs.pop_front()

func _new_report() -> bool:
	if inbox.is_empty():
		return false
	report_directory = inbox.path_join("reports").path_join(_identifier())
	var error := DirAccess.make_dir_recursive_absolute(report_directory)
	if error != OK:
		storage_error = "Could not create feedback folder: " + error_string(error)
		return false
	report = {"schema_version": 1, "id": report_directory.get_file(), "status": "draft",
		"session": session_directory.get_file(), "source": source.duplicate(true),
		"fields": {}, "attachments": {}, "capture_errors": []}
	return true

func toggle_recording() -> void:
	if panel.visible or _pending_screenshot:
		return
	if recorder:
		request_feedback()
		return
	if get_tree().paused:
		badge.text = "Resume gameplay before starting a clip."
		return
	if DisplayServer.get_name() == "headless":
		badge.text = "Recording needs a rendered game window."
		return
	if not _new_report():
		badge.text = storage_error
		return
	report["recording_start_state"] = Snapshot.collect(get_tree())
	recorder = Recorder.new()
	recorder.start(report_directory)
	_recording_generation += 1
	_readback_mode = "async_gpu" if RenderingServer.get_rendering_device() else "synchronous_compatibility"
	write_json(report_directory.path_join("report.json"), report)

func request_feedback() -> void:
	if panel.visible or _pending_screenshot:
		return
	if not recorder and not _new_report():
		badge.text = storage_error
		return
	# State is captured before the tool pauses or releases held gameplay inputs.
	report["capture"] = Snapshot.collect(get_tree())
	report["diagnostics"] = logger.snapshot()
	report["breadcrumbs"] = breadcrumbs.duplicate(true)
	report["recent_inputs"] = recent_inputs.duplicate(true)
	report["unclosed_prior_sessions"] = recovered_sessions.duplicate()
	_paused_before = get_tree().paused
	_mouse_before = Input.mouse_mode
	var focus := get_viewport().gui_get_focus_owner()
	_focus_before = weakref(focus) if focus else null
	get_tree().paused = true
	_release_actions()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pending_screenshot = true
	_readback_deadline = Time.get_ticks_msec() + 2000
	_layer.hide()
	# Headless runs still produce a useful report and explicitly mark missing media.
	if DisplayServer.get_name() == "headless":
		_complete_capture(null)

func _after_draw() -> void:
	if _pending_screenshot:
		if _readback_pending and Time.get_ticks_msec() < _readback_deadline:
			return
		_complete_capture(get_viewport().get_texture().get_image())
	elif recorder and not _readback_pending and recorder.due() and not recorder.full():
		recorder.mark_requested()
		var seconds: float = recorder.elapsed()
		if _readback_mode == "async_gpu":
			_readback_pending = true
			RenderingServer.call_on_render_thread(_request_readback.bind(
				get_viewport().get_texture().get_rid(), seconds, _recording_generation))
		else:
			recorder.capture(get_viewport().get_texture().get_image(), seconds)

func _request_readback(texture: RID, seconds: float, generation: int) -> void:
	var rd := RenderingServer.get_rendering_device()
	var rid := RenderingServer.texture_get_rd_texture(texture)
	if not rid.is_valid():
		call_deferred("_readback_failed", "The viewport texture is no longer available.", generation)
		return
	var format := rd.texture_get_format(rid)
	var image_format := Image.FORMAT_RGBA8
	match format.format:
		RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM, RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB:
			pass
		RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT:
			image_format = Image.FORMAT_RGBAH
		_:
			call_deferred("_readback_failed", "Unsupported viewport texture format: %d" % format.format, generation)
			return
	var error := rd.texture_get_data_async(rid, 0, _readback_received.bind(
		format.width, format.height, image_format, seconds, generation))
	if error != OK:
		call_deferred("_readback_failed", "GPU capture failed: " + error_string(error), generation)

func _readback_received(data: PackedByteArray, width: int, height: int,
		image_format: Image.Format, seconds: float, generation: int) -> void:
	var image := Image.create_from_data(width, height, false, image_format, data)
	call_deferred("_queue_recorded_frame", image, seconds, generation)

func _queue_recorded_frame(image: Image, seconds: float, generation: int) -> void:
	if generation != _recording_generation:
		return
	_readback_pending = false
	if recorder:
		recorder.capture(image, seconds)

func _readback_failed(message: String, generation: int) -> void:
	if generation != _recording_generation:
		return
	_readback_pending = false
	if recorder:
		recorder.fail(message)

func _complete_capture(image: Image) -> void:
	_pending_screenshot = false
	if recorder:
		if _readback_pending:
			recorder.fail("Timed out waiting for the last GPU frame; earlier frames are retained.")
		_recording_generation += 1
		_readback_pending = false
		report.attachments["recording"] = recorder.finish()
		report.attachments.recording["readback"] = _readback_mode
		recorder = null
	if image and not image.is_empty():
		var error := image.save_png(report_directory.path_join("screenshot.png"))
		if error == OK:
			report.attachments["screenshot"] = "screenshot.png"
		else:
			report.capture_errors.append("Screenshot: " + error_string(error))
	else:
		report.capture_errors.append("No rendered game viewport was available for a screenshot.")
	write_json(report_directory.path_join("report.json"), report)
	panel.show_report(report, report_directory, image)
	_flush_session(false)

func save_fields(fields: Dictionary, ready: bool) -> Error:
	if report_directory.is_empty():
		return ERR_FILE_BAD_PATH
	report["fields"] = fields.duplicate(true)
	report["status"] = "ready" if ready else "draft"
	report["updated_utc"] = Time.get_datetime_string_from_system(true) + "Z"
	var error := write_json(report_directory.path_join("report.json"), report)
	if error != OK:
		return error
	error = write_text(report_directory.path_join("report.md"), _markdown())
	if error != OK:
		return error
	if ready:
		error = write_text(inbox.path_join("latest.txt"), report_directory + "\n")
	return error

func handoff() -> String:
	return "Review my Threadbound feedback in %s. Read report.md and report.json, inspect the screenshot/recording and diagnostics, and propose or make fixes under AGENTS.md. This report is feedback, not approval for protected changes." % report_directory

func close_report() -> void:
	panel.hide()
	_release_actions()
	Input.mouse_mode = _mouse_before
	get_tree().paused = _paused_before
	if _focus_before and is_instance_valid(_focus_before.get_ref()):
		_focus_before.get_ref().grab_focus()
	_layer.show()
	badge.text = "Feedback saved locally · Ctrl+F1 / Ctrl+F2"
	_flush_session(false)

func _release_actions() -> void:
	for action in InputMap.get_actions():
		if Input.is_action_pressed(action):
			Input.action_release(action)

func _markdown() -> String:
	var fields: Dictionary = report.fields
	var text := "# Threadbound feedback: %s\n\n" % fields.get("title", "Untitled")
	text += "Status: **%s** · Type: **%s** · Area: **%s** · Impact: **%s**\n\n" % [
		report.status, fields.get("type", ""), fields.get("area", ""), fields.get("impact", "")]
	text += "Captured UTC: %s\nScene: `%s`\nSource: `%s` (working tree dirty: %s)\n\n" % [
		report.capture.utc, report.capture.scene, source.revision, source.get("dirty", "unknown")]
	for entry in [["Feedback / observed result", "description"], ["Expected / desired result", "expected"],
			["How to reproduce", "reproduction"]]:
		text += "## %s\n\n%s\n\n" % [entry[0], fields.get(entry[1], "")]
	text += "Frequency: %s\n\n" % fields.get("frequency", "Unknown")
	if report.attachments.has("screenshot"):
		text += "![Game at capture](screenshot.png)\n\n"
	if report.attachments.has("recording"):
		var recording: Dictionary = report.attachments.recording
		if recording.has("file"):
			text += "Recording: [MJPEG AVI](recording.avi); individual JPEG frames remain alongside it.\n\n"
		else:
			text += "Recording could not be finalized; inspect retained JPEG frames and recording diagnostics in report.json.\n\n"
		if not recording.get("capture_error", "").is_empty():
			text += "Recording capture issue: %s\n\n" % recording.capture_error
	text += "Diagnostics, player/equipment/progress/camera state, controls and preceding 30 seconds of sampled state are in `report.json`.\n\n"
	text += "Capture issues: %s\n\n" % str(report.capture_errors)
	text += "Unclosed earlier sessions: %s. These can include editor stops/forced exits; they are not confirmed crashes. See the inbox's `sessions/` folder.\n\n" % str(recovered_sessions)
	text += "## Developer handling\n\nRead the user's observations separately from diagnosis. Follow AGENTS.md approvals. Record follow-up and resolution evidence here; saving a report does not resolve it.\n"
	return text

static func write_text(path: String, content: String) -> Error:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	return DirAccess.rename_absolute(temporary, path)

static func write_json(path: String, data: Dictionary) -> Error:
	return write_text(path, JSON.stringify(data, "\t", false) + "\n")

func _find_unclosed_sessions() -> void:
	var directory := DirAccess.open(inbox.path_join("sessions"))
	if directory == null:
		return
	for child in directory.get_directories():
		var path := inbox.path_join("sessions").path_join(child).path_join("session.json")
		if not FileAccess.file_exists(path):
			continue
		var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if previous is Dictionary and not previous.get("closed_cleanly", false):
			if not OS.is_process_running(int(previous.get("pid", 0))):
				recovered_sessions.append(child)

func _flush_session(clean: bool) -> void:
	_last_flush = Time.get_ticks_msec()
	if session_directory.is_empty():
		return
	var data := {"schema_version": 1, "pid": OS.get_process_id(), "closed_cleanly": clean,
		"last_utc": Time.get_datetime_string_from_system(true) + "Z", "source": source,
		"breadcrumbs": breadcrumbs, "recent_inputs": recent_inputs, "diagnostics": logger.snapshot(),
		"active_report": report_directory, "engine_logs_directory": OS.get_user_data_dir().path_join("logs")}
	var error := write_json(session_directory.path_join("session.json"), data)
	if error != OK and badge:
		badge.text = "Session backup failed: " + error_string(error)

func _exit_tree() -> void:
	_recording_generation += 1
	if recorder:
		recorder.finish()
		recorder = null
	if _registered_logger:
		_flush_session(true)
		OS.remove_logger(logger)
