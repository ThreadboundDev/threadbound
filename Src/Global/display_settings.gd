extends Node

signal display_settings_changed

const SAVE_PATH := "user://display.cfg"
const SECTION := "graphics"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const FRAME_RATE_LIMITS: Array[int] = [0, 60, 120, 144]
const QUALITY_PRESETS: Array[String] = ["LOW", "MEDIUM", "HIGH"]

var resolution_index := 2
var fullscreen := false
var vsync := true
var frame_rate_limit_index := 0
var quality_preset_index := 2

func _ready() -> void:
	load_settings()
	call_deferred("apply_settings")

func get_resolution_count() -> int:
	return RESOLUTIONS.size()

func get_resolution_label() -> String:
	var resolution := get_resolution()
	return "%d X %d" % [resolution.x, resolution.y]

func get_resolution() -> Vector2i:
	return RESOLUTIONS[clampi(resolution_index, 0, RESOLUTIONS.size() - 1)]

func set_resolution_index(index: int) -> void:
	resolution_index = clampi(index, 0, RESOLUTIONS.size() - 1)
	save_settings()
	apply_settings()

func apply_graphics_settings(
	new_resolution_index: int,
	new_fullscreen: bool,
	new_vsync: bool,
	new_frame_rate_limit_index: int,
	new_quality_preset_index: int
) -> void:
	resolution_index = clampi(new_resolution_index, 0, RESOLUTIONS.size() - 1)
	fullscreen = new_fullscreen
	vsync = new_vsync
	frame_rate_limit_index = clampi(new_frame_rate_limit_index, 0, FRAME_RATE_LIMITS.size() - 1)
	quality_preset_index = clampi(new_quality_preset_index, 0, QUALITY_PRESETS.size() - 1)
	save_settings()
	apply_settings()

func cycle_resolution(step: int) -> void:
	set_resolution_index(resolution_index + step)

func get_fullscreen_label() -> String:
	return "FULLSCREEN" if fullscreen else "WINDOWED"

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	save_settings()
	apply_settings()

func cycle_fullscreen() -> void:
	set_fullscreen(not fullscreen)

func get_vsync_label() -> String:
	return "ON" if vsync else "OFF"

func set_vsync(enabled: bool) -> void:
	vsync = enabled
	save_settings()
	apply_settings()

func cycle_vsync() -> void:
	set_vsync(not vsync)

func get_frame_rate_limit_label() -> String:
	var limit := FRAME_RATE_LIMITS[clampi(frame_rate_limit_index, 0, FRAME_RATE_LIMITS.size() - 1)]
	return "UNLIMITED" if limit <= 0 else str(limit)

func set_frame_rate_limit_index(index: int) -> void:
	frame_rate_limit_index = clampi(index, 0, FRAME_RATE_LIMITS.size() - 1)
	save_settings()
	apply_settings()

func cycle_frame_rate_limit(step: int) -> void:
	set_frame_rate_limit_index(wrapi(frame_rate_limit_index + step, 0, FRAME_RATE_LIMITS.size()))

func get_quality_preset_label() -> String:
	return QUALITY_PRESETS[clampi(quality_preset_index, 0, QUALITY_PRESETS.size() - 1)]

func set_quality_preset_index(index: int) -> void:
	quality_preset_index = clampi(index, 0, QUALITY_PRESETS.size() - 1)
	save_settings()
	apply_settings()

func cycle_quality_preset(step: int) -> void:
	set_quality_preset_index(wrapi(quality_preset_index + step, 0, QUALITY_PRESETS.size()))

func get_resolution_labels() -> Array[String]:
	var labels: Array[String] = []
	for resolution in RESOLUTIONS:
		labels.append("%d X %d" % [resolution.x, resolution.y])
	return labels

func get_frame_rate_limit_labels() -> Array[String]:
	var labels: Array[String] = []
	for limit in FRAME_RATE_LIMITS:
		labels.append("UNLIMITED" if limit <= 0 else str(limit))
	return labels

func apply_settings() -> void:
	# Godot's embedded game window cannot become fullscreen. Reapplying a saved
	# fullscreen preference there repeatedly invalidates the Vulkan swapchain.
	# Keep the preference intact so standalone runs still launch fullscreen.
	var use_fullscreen := fullscreen and not _is_running_in_editor_window()
	if use_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var resolution := get_resolution()
		DisplayServer.window_set_size(resolution)
		if not _is_running_in_editor_window():
			_center_window(resolution)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = FRAME_RATE_LIMITS[clampi(frame_rate_limit_index, 0, FRAME_RATE_LIMITS.size() - 1)]
	_apply_quality_preset()
	display_settings_changed.emit()

func _is_running_in_editor_window() -> bool:
	if not OS.has_feature("editor"):
		return false
	var command_line := OS.get_cmdline_args()
	return command_line.has("-e") or command_line.has("--editor")

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	resolution_index = int(config.get_value(SECTION, "resolution_index", resolution_index))
	resolution_index = clampi(resolution_index, 0, RESOLUTIONS.size() - 1)
	fullscreen = bool(config.get_value(SECTION, "fullscreen", fullscreen))
	vsync = bool(config.get_value(SECTION, "vsync", vsync))
	frame_rate_limit_index = int(config.get_value(SECTION, "frame_rate_limit_index", frame_rate_limit_index))
	frame_rate_limit_index = clampi(frame_rate_limit_index, 0, FRAME_RATE_LIMITS.size() - 1)
	quality_preset_index = int(config.get_value(SECTION, "quality_preset_index", quality_preset_index))
	quality_preset_index = clampi(quality_preset_index, 0, QUALITY_PRESETS.size() - 1)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, "resolution_index", resolution_index)
	config.set_value(SECTION, "fullscreen", fullscreen)
	config.set_value(SECTION, "vsync", vsync)
	config.set_value(SECTION, "frame_rate_limit_index", frame_rate_limit_index)
	config.set_value(SECTION, "quality_preset_index", quality_preset_index)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("DisplaySettings could not save graphics settings: %s." % error_string(error))

func _center_window(resolution: Vector2i) -> void:
	var screen := DisplayServer.window_get_current_screen()
	var screen_position := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var centered_position := screen_position + (screen_size - resolution) / 2
	DisplayServer.window_set_position(centered_position)

func _apply_quality_preset() -> void:
	var root_viewport := get_tree().root
	match get_quality_preset_label():
		"LOW":
			root_viewport.msaa_2d = Viewport.MSAA_DISABLED
			root_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			root_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		"MEDIUM":
			root_viewport.msaa_2d = Viewport.MSAA_2X
			root_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			root_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
		"HIGH":
			root_viewport.msaa_2d = Viewport.MSAA_4X
			root_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			root_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
