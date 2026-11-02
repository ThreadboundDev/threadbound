extends SceneTree
## Run with --headless for diagnostics, or a window for real capture/AVI checks.
## Always redirect the inbox: -- --feedback-inbox=res://tmp/feedback-verification

const Capture := preload("res://Src/DebugFeedback/feedback_capture.gd")
const Recorder := preload("res://Src/DebugFeedback/feedback_recorder.gd")
var failures: Array[String] = []
var checks := 0

class TestWorld extends Node2D:
	var leaked_shortcuts := 0
	func _unhandled_key_input(event: InputEvent) -> void:
		if event is InputEventKey and event.ctrl_pressed and event.keycode == KEY_F1:
			leaked_shortcuts += 1

class TestPlayer extends CharacterBody2D:
	var momentum := 42.0
	var action_points := 2
	var is_attacking := true
	var current_body_anim := "test_run"
	var god_mode_enabled := true
	var current_gloves: Node
	var current_boots: Node

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func _run() -> void:
	var capture := root.get_node("DebugUI/FeedbackCapture")
	check(capture.inbox.contains("tmp"), "Tests must use an isolated tmp inbox.")
	if not capture.inbox.contains("tmp"):
		quit(1)
		return
	var world := TestWorld.new()
	world.name = "FeedbackTestLevel"
	root.add_child(world)
	current_scene = world
	var player := TestPlayer.new()
	player.name = "TestPlayer"
	world.add_child(player)
	player.add_to_group("player")
	player.current_gloves = Node.new()
	player.current_gloves.name = "SceneOwnedGloves"
	player.add_child(player.current_gloves)
	player.current_boots = Node.new()
	player.current_boots.name = "DetachedBoots"
	player.position = Vector2(123, 456)
	player.velocity = Vector2(90, -20)
	var block := Polygon2D.new()
	block.polygon = PackedVector2Array([Vector2(100, 100), Vector2(400, 100), Vector2(400, 350), Vector2(100, 350)])
	block.color = Color(0.2, 0.7, 0.9)
	world.add_child(block)
	await process_frame
	await process_frame
	push_warning("FEEDBACK_TEST deliberate warning")
	push_error("FEEDBACK_TEST deliberate error")
	check(capture.logger.snapshot().errors_since_start >= 1, "Engine errors reach the logger.")
	check(capture.logger.snapshot().warnings_since_start >= 1, "Engine warnings reach the logger.")
	for index in 310:
		capture.logger._log_message("bounded test %d" % index, false)
	check(capture.logger.snapshot().recent.size() == 300, "Log retention is bounded.")
	var shortcut := InputEventKey.new()
	shortcut.keycode = KEY_F1
	shortcut.ctrl_pressed = true
	shortcut.pressed = true
	Input.parse_input_event(shortcut)
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		await process_frame
	check(paused, "Feedback pauses gameplay.")
	check(capture.panel.visible, "Feedback form opens.")
	check(world.leaked_shortcuts == 0, "Shortcut is consumed before scene debug keys.")
	check(not capture.report.capture.paused, "Report records the pre-pause state.")
	check(capture.report.capture.player.global_position.x == 123, "Player position is captured.")
	check(capture.report.capture.player.momentum == 42, "Player momentum is captured.")
	check(capture.report.capture.player.action_points == 2, "Player AP is captured.")
	check(capture.report.capture.player.is_attacking, "Player action state is captured.")
	check(capture.report.capture.equipment.player_slots.current_gloves.node.ends_with("SceneOwnedGloves"),
		"Scene-owned equipment is captured even without manager references.")
	check(not capture.report.capture.equipment.player_slots.current_boots.inside_tree,
		"Detached equipment is represented without querying an invalid scene path.")
	check(capture.report.capture.scene_name == "FeedbackTestLevel", "Scene is captured.")
	check(capture.report.capture.environment.has("gameplay_settings"), "Difficulty/settings are captured.")
	check(capture.report.source.revision.length() == 40, "Source revision is captured.")
	if DisplayServer.get_name() == "headless":
		check(not capture.report.capture_errors.is_empty(), "Headless missing media is explicit.")
	else:
		var image := Image.load_from_file(capture.report_directory.path_join("screenshot.png"))
		check(image != null and not image.is_empty(), "Real screenshot is saved.")
		check(not image.get_pixel(200, 200).is_equal_approx(Color.BLACK), "Screenshot contains the test world.")
		await RenderingServer.frame_post_draw
		capture.panel.get_texture().get_image().save_png(capture.inbox.path_join("form-preview.png"))
	var directory: String = capture.report_directory
	capture.panel.description.text = "First line\nSecond line — gameplay/art feedback."
	capture.panel.expected.text = "Expected result"
	capture.panel.reproduction.text = "Run, then jump"
	capture.panel._autosave()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("report.json")))
	check(data.status == "draft", "Typing saves a draft.")
	check(data.fields.description.contains("Second line"), "Draft preserves multiline Unicode notes.")
	capture.panel._save()
	data = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("report.json")))
	check(data.status == "ready", "Save marks feedback ready.")
	check(FileAccess.file_exists(directory.path_join("report.md")), "Readable report exists.")
	check(FileAccess.get_file_as_string(capture.inbox.path_join("latest.txt")).strip_edges() == directory,
		"Latest handoff points to the saved report.")
	check(capture.handoff().contains(directory), "Handoff includes the exact local path.")
	capture.panel._close()
	check(not paused, "Closing restores an unpaused game.")
	var action_event := InputEventAction.new()
	action_event.action = &"Jump"
	action_event.pressed = true
	capture._input(action_event)
	check(capture.recent_inputs.back().action == "Jump", "Short bound action presses enter the input history.")
	paused = true
	capture.request_feedback()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		await process_frame
	capture.panel._close()
	check(paused, "Closing preserves a previously paused menu.")
	paused = false
	if DisplayServer.get_name() != "headless":
		# Exercise the live viewport recording path, not just the AVI encoder.
		capture.toggle_recording()
		check(capture.recorder != null, "Recording starts during gameplay.")
		await create_timer(0.45).timeout
		capture.toggle_recording()
		await RenderingServer.frame_post_draw
		await process_frame
		check(capture.panel.visible, "Stopping a recording opens feedback.")
		check(capture.report.attachments.recording.captured_frames > 1, "Live viewport frames are recorded.")
		check(FileAccess.file_exists(capture.report_directory.path_join("recording.avi")), "Live recording produces an AVI.")
		capture.panel._close()
	# Deterministic synthetic frames verify AVI structure independently of GPU timing.
	var recorder := Recorder.new()
	var clip_directory: String = capture.inbox.path_join("avi-check")
	DirAccess.make_dir_recursive_absolute(clip_directory)
	recorder.start(clip_directory)
	for color in [Color.RED, Color.GREEN, Color.BLUE]:
		var frame := Image.create(160, 90, false, Image.FORMAT_RGB8)
		frame.fill(color)
		recorder.capture(frame)
		await create_timer(0.12).timeout
	var clip := recorder.finish()
	check(clip.captured_frames == 3, "Recorder saves all captured frames.")
	check(clip.get("file", "") == "recording.avi", "Recorder finishes an AVI.")
	var avi := FileAccess.get_file_as_bytes(clip_directory.path_join("recording.avi"))
	check(avi.slice(0, 4).get_string_from_ascii() == "RIFF", "AVI has a RIFF header.")
	check(avi.decode_u32(4) == avi.size() - 8, "RIFF size matches the complete file.")
	check(avi.slice(8, 12).get_string_from_ascii() == "AVI ", "AVI signature is valid.")
	# Broken destinations must return errors, without pretending a save succeeded.
	check(Capture.write_text(capture.inbox.path_join("missing/subfolder/report.txt"), "test") != OK,
		"Unwritable destination is reported.")
	capture._flush_session(false)
	var session: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(capture.session_directory.path_join("session.json")))
	check(not session.closed_cleanly, "Active session is marked unclosed.")
	check(not session.breadcrumbs.is_empty(), "Recovery session contains breadcrumbs.")
	check(FileAccess.file_exists(capture.inbox.path_join(".gdignore")), "Inbox is excluded from Godot imports.")
	check(FileAccess.get_file_as_string(capture.inbox.path_join(".gitignore")).strip_edges() == "*",
		"Inbox protects local reports independently of repository ignore rules.")
	var fake_prior: String = capture.inbox.path_join("sessions/forced-exit-test")
	DirAccess.make_dir_recursive_absolute(fake_prior)
	Capture.write_json(fake_prior.path_join("session.json"), {"pid": 2147483647, "closed_cleanly": false})
	capture._find_unclosed_sessions()
	check(capture.recovered_sessions.has("forced-exit-test"), "Unclosed sessions are discoverable after restart.")
	Capture.write_json(capture.inbox.path_join("verification.json"), {"checks": checks, "failures": failures,
		"report": directory, "clip": clip_directory.path_join("recording.avi"), "display": DisplayServer.get_name()})
	for failure in failures:
		printerr("FAIL: " + failure)
	print("FEEDBACK_VERIFICATION: %d checks; %d failures" % [checks, failures.size()])
	player.current_boots.free()
	quit(0 if failures.is_empty() else 1)
