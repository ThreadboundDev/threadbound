extends Node2D
## Isolated visual audition. Movement below only moves the preview artwork.

const MODEL := preload("res://Src/Tests/Art/EaveRunnerSpriteStudy/eave_runner_sprite_model.tscn")
const CAPTURE_PREFIX := "--capture-dir="
var actor: AnimatedSprite2D
var automatic := true
var paused := false
var large_view := true
var playback_rate := 1.0
var phase := 0
var phase_time := 0.0
var moving := false
var verifying := false
var status: Label
var facing_button: Button
var pause_button: Button
var auto_button: Button
var scale_button: Button
var checks: Array[String] = []

func _ready() -> void:
	verifying = "--verify-eave-sprites" in OS.get_cmdline_user_args()
	actor = MODEL.instantiate()
	actor.position = Vector2(640, 600)
	actor.scale = Vector2.ONE * 0.82
	add_child(actor)
	_build_controls()
	if verifying:
		_verify_study()

func _build_controls() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var title := Label.new()
	title.text = "EAVE RUNNER / SPRITE STUDY"
	title.position = Vector2(40, 26)
	title.add_theme_font_size_override("font_size", 28)
	title.modulate = Color("e2d4b8")
	canvas.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "24 drawings · idle / run / slash · original demo enemy style"
	subtitle.position = Vector2(40, 67)
	subtitle.modulate = Color("a5b7bd")
	canvas.add_child(subtitle)
	var row := HBoxContainer.new()
	row.position = Vector2(40, 110)
	row.add_theme_constant_override("separation", 9)
	canvas.add_child(row)
	for clip: String in ["idle", "run", "slash"]:
		var button := Button.new()
		button.text = clip.capitalize()
		button.custom_minimum_size = Vector2(95, 40)
		button.pressed.connect(_choose.bind(clip))
		row.add_child(button)
	auto_button = Button.new()
	auto_button.text = "Auto: on [A]"
	auto_button.pressed.connect(_toggle_auto)
	row.add_child(auto_button)
	pause_button = Button.new()
	pause_button.text = "Pause [Space]"
	pause_button.pressed.connect(_toggle_pause)
	row.add_child(pause_button)
	facing_button = Button.new()
	facing_button.text = "Face left [F]"
	facing_button.pressed.connect(_flip)
	row.add_child(facing_button)
	scale_button = Button.new()
	scale_button.text = "Gameplay size [G]"
	scale_button.pressed.connect(_toggle_scale)
	row.add_child(scale_button)
	var speed := HSlider.new()
	speed.position = Vector2(1040, 118)
	speed.size = Vector2(190, 24)
	speed.min_value = 0.25
	speed.max_value = 1.5
	speed.step = 0.05
	speed.value = 1.0
	speed.value_changed.connect(func(value: float) -> void:
		playback_rate = value
		actor.speed_scale = 0.0 if paused else value)
	canvas.add_child(speed)
	status = Label.new()
	status.position = Vector2(40, 686)
	status.modulate = Color("d2d8cc")
	canvas.add_child(status)
	var instructions := Label.new()
	instructions.text = "1 / 2 / 3: animation    Left / Right: move and face    Space: pause    F: flip    G: size    A: autoplay"
	instructions.position = Vector2(40, 730)
	instructions.modulate = Color("9eafb4")
	canvas.add_child(instructions)

func _process(delta: float) -> void:
	if actor == null:
		return
	status.text = "%s  |  frame %d / 8  |  %.2fx speed  |  %s" % [str(actor.animation).to_upper(), actor.frame + 1, playback_rate, "large inspection" if large_view else "~180 px gameplay height"]
	if paused or verifying:
		return
	var direction := float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))
	if not is_zero_approx(direction):
		_set_auto(false)
		moving = true
		actor.set_facing(direction)
		actor.play_study_clip(&"run")
		actor.position.x = clampf(actor.position.x + direction * 250.0 * delta * playback_rate, 120.0, 1160.0)
	elif moving:
		moving = false
		actor.play_study_clip(&"idle")
	if automatic:
		phase_time += delta * playback_rate
		var limits := [1.68, 1.95, 0.9]
		if phase_time >= limits[phase]:
			phase_time = 0.0
			phase = (phase + 1) % 3
			actor.play_study_clip([&"idle", &"run", &"slash"][phase], true)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: _choose("idle")
		KEY_2: _choose("run")
		KEY_3: _choose("slash")
		KEY_SPACE: _toggle_pause()
		KEY_F: _flip()
		KEY_G: _toggle_scale()
		KEY_A: _toggle_auto()

func _choose(clip: String) -> void:
	_set_auto(false)
	actor.play_study_clip(clip, true)

func _toggle_auto() -> void:
	_set_auto(not automatic)

func _set_auto(value: bool) -> void:
	automatic = value
	auto_button.text = "Auto: %s [A]" % ("on" if value else "off")
	phase = 0
	phase_time = 0.0
	if value:
		actor.play_study_clip(&"idle", true)

func _toggle_pause() -> void:
	paused = not paused
	actor.speed_scale = 0.0 if paused else playback_rate
	pause_button.text = "Resume [Space]" if paused else "Pause [Space]"

func _flip() -> void:
	actor.flip_h = not actor.flip_h
	facing_button.text = "Face right [F]" if actor.flip_h else "Face left [F]"

func _toggle_scale() -> void:
	large_view = not large_view
	actor.scale = Vector2.ONE * (0.82 if large_view else 0.42)
	scale_button.text = "Gameplay size [G]" if large_view else "Large view [G]"

func _draw() -> void:
	for strip in 50:
		var ratio := float(strip) / 49.0
		draw_rect(Rect2(0, strip * 16, 1280, 16), Color("1e2934").lerp(Color("405258"), ratio))
	# A quiet review stage leaves the silhouette and foot contacts exposed.
	draw_circle(Vector2(640, 380), 192, Color(0.42, 0.56, 0.59, 0.055))
	draw_arc(Vector2(640, 380), 194, 0, TAU, 96, Color(0.52, 0.65, 0.67, 0.11), 1.0, true)
	draw_rect(Rect2(0, 601, 1280, 55), Color("202d34"))
	draw_line(Vector2(0, 600), Vector2(1280, 600), Color("9aada8"), 2.0, true)
	for x in range(0, 1280, 100):
		draw_line(Vector2(x, 604), Vector2(x, 650), Color("46545a"), 1.0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		push_error("Sprite study verification failed: " + description)
		get_tree().quit(1)
	checks.append(description)

func _verify_study() -> void:
	var capture_dir := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(CAPTURE_PREFIX):
			capture_dir = argument.trim_prefix(CAPTURE_PREFIX)
	_check(actor.sprite_frames != null, "Frame resources loaded")
	for clip: String in ["idle", "run", "slash"]:
		_check(actor.sprite_frames.has_animation(clip), clip + " available")
		_check(actor.sprite_frames.get_frame_count(clip) == 8, clip + " has 8 drawings")
		_check(actor.sprite_frames.get_animation_loop(clip) == (clip != "slash"), clip + " loop contract")
		for index in 8:
			var texture := actor.sprite_frames.get_frame_texture(clip, index)
			_check(texture.get_size() == Vector2(512, 512), clip + " frame %d has registered dimensions" % index)
			_check(actor.sprite_frames.get_frame_duration(clip, index) > 0.0, clip + " frame %d has positive timing" % index)
	actor.play_study_clip(&"run", true)
	await get_tree().create_timer(0.18).timeout
	_check(actor.frame > 0, "Run advances through drawings in the engine")
	actor.play_study_clip(&"slash", true)
	await get_tree().create_timer(1.0).timeout
	_check(actor.animation == &"idle", "One-shot slash returns to idle")
	actor.set_facing(-1)
	_check(actor.flip_h, "Left facing mirrors the artwork")
	actor.set_facing(1)
	_check(not actor.flip_h, "Right facing restored")
	_toggle_pause()
	var held := actor.frame
	await get_tree().create_timer(0.15).timeout
	_check(actor.frame == held, "Pause holds the current drawing")
	_toggle_pause()
	_toggle_scale()
	_check(is_equal_approx(actor.scale.x, 0.42), "Gameplay-size view available")
	_toggle_scale()
	_check(is_equal_approx(actor.scale.x, 0.82), "Inspection-size view available")
	if not capture_dir.is_empty() and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(capture_dir)
		actor.speed_scale = 0.0
		for clip: String in ["idle", "run", "slash"]:
			actor.animation = clip
			actor.set_frame_and_progress(3, 0.0)
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			_check(image.save_png(capture_dir.path_join(clip + ".png")) == OK, clip + " GPU capture saved")
		actor.flip_h = true
		await RenderingServer.frame_post_draw
		_check(get_viewport().get_texture().get_image().save_png(capture_dir.path_join("left.png")) == OK, "Left-facing GPU capture saved")
	var report := {"passed": checks.size(), "checks": checks, "renderer": DisplayServer.get_name(), "live_enemy_replaced": false}
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
		var file := FileAccess.open(capture_dir.path_join("verification.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t") + "\n")
	print("EAVE_SPRITE_STUDY_VERIFIED " + JSON.stringify(report))
	get_tree().quit()
