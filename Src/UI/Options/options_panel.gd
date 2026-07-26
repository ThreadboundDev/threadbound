extends Control
class_name OptionsPanel

signal back_requested

const TAB_ORDER: Array[StringName] = [&"Graphics", &"Audio", &"Gameplay", &"Controls"]
const GAME_MENU_SCENE := preload("res://Src/UI/GameMenu/game_menu.tscn")

@onready var tab_labels: Array[Label] = [
	$Tabs/Graphics,
	$Tabs/Audio,
	$Tabs/Gameplay,
	$Tabs/Controls,
]
@onready var pages: Dictionary = {
	&"Graphics": $Pages/Graphics,
	&"Audio": $Pages/Audio,
	&"Gameplay": $Pages/Gameplay,
	&"Controls": $Pages/Controls,
}
@onready var resolution_stepper: Control = $Pages/Graphics/Rows/Resolution as Control
@onready var fullscreen_stepper: Control = $Pages/Graphics/Rows/WindowMode as Control
@onready var vsync_stepper: Control = $Pages/Graphics/Rows/VSync as Control
@onready var frame_limit_stepper: Control = $Pages/Graphics/Rows/FrameRateLimit as Control
@onready var quality_stepper: Control = $Pages/Graphics/Rows/QualityPreset as Control
@onready var sliders: Array[VolumeSlider] = [
	$Pages/Audio/Rows/Master,
	$Pages/Audio/Rows/Music,
	$Pages/Audio/Rows/BackgroundAudio,
	$Pages/Audio/Rows/SFX,
	$Pages/Audio/Rows/UI,
]
@onready var gameplay_steppers: Dictionary = {
	&"difficulty": $Pages/Gameplay/Rows/Difficulty,
	&"auto_save": $Pages/Gameplay/Rows/AutoSave,
	&"tutorial_hints": $Pages/Gameplay/Rows/TutorialHints,
	&"vibration": $Pages/Gameplay/Rows/Vibration,
	&"damage_numbers": $Pages/Gameplay/Rows/DamageNumbers,
}
@onready var controls_items: Array[Control] = [
	$Pages/Controls/Rows/KeyboardMouse,
	$Pages/Controls/Rows/ResetBindings,
]
@onready var controller_choice_row: Control = $Pages/Controls/Rows/Controller as Control

var _selected_tab_index := 0
var _selected_index := 0
var _option_items: Array[Control] = []
var _hovered_tab_index := -1
var _pending_resolution_index := 0
var _pending_fullscreen := false
var _pending_vsync := true
var _pending_frame_rate_limit_index := 0
var _pending_quality_preset_index := 0
var _graphics_dirty := false
var _last_input_family: StringName = &"keyboard_mouse"

func _ready() -> void:
	for i in tab_labels.size():
		tab_labels[i].mouse_filter = Control.MOUSE_FILTER_STOP
		tab_labels[i].gui_input.connect(_on_tab_gui_input.bind(i))
		tab_labels[i].mouse_entered.connect(_on_tab_mouse_entered.bind(i))
		tab_labels[i].mouse_exited.connect(_on_tab_mouse_exited.bind(i))
	resolution_stepper.focused.connect(_on_option_focused)
	resolution_stepper.changed.connect(_on_resolution_changed)
	resolution_stepper.selected_index.connect(_on_resolution_selected)
	fullscreen_stepper.focused.connect(_on_option_focused)
	fullscreen_stepper.changed.connect(_on_fullscreen_changed)
	fullscreen_stepper.selected_index.connect(_on_fullscreen_selected)
	vsync_stepper.focused.connect(_on_option_focused)
	vsync_stepper.changed.connect(_on_vsync_changed)
	frame_limit_stepper.focused.connect(_on_option_focused)
	frame_limit_stepper.changed.connect(_on_frame_limit_changed)
	frame_limit_stepper.selected_index.connect(_on_frame_limit_selected)
	quality_stepper.focused.connect(_on_option_focused)
	quality_stepper.changed.connect(_on_quality_changed)
	quality_stepper.selected_index.connect(_on_quality_selected)
	for slider in sliders:
		slider.focused.connect(_on_option_focused)
	for setting_name in gameplay_steppers:
		var stepper := gameplay_steppers[setting_name] as Control
		stepper.focused.connect(_on_option_focused)
		stepper.changed.connect(_on_gameplay_setting_changed.bind(setting_name))
		stepper.selected_index.connect(_on_gameplay_setting_selected.bind(setting_name))
	for item in controls_items:
		item.focused.connect(_on_option_focused)
		item.changed.connect(_on_controls_option_changed)
	if controller_choice_row:
		controller_choice_row.visible = false
	_configure_option_rows()
	if not DisplaySettings.display_settings_changed.is_connected(_refresh_graphics_options):
		DisplaySettings.display_settings_changed.connect(_refresh_graphics_options)
	if not GameplaySettings.gameplay_settings_changed.is_connected(_refresh_gameplay_options):
		GameplaySettings.gameplay_settings_changed.connect(_refresh_gameplay_options)
	_refresh_graphics_options()
	_refresh_gameplay_options()
	_select_tab(_selected_tab_index, true)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	_update_input_family_from_event(event)

	if event.is_action_pressed("menu_tab_left"):
		_select_tab(_selected_tab_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_tab_right"):
		_select_tab(_selected_tab_index + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_select_index(_selected_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_select_index(_selected_index + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and TAB_ORDER[_selected_tab_index] == &"Graphics":
		_apply_pending_graphics()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if TAB_ORDER[_selected_tab_index] == &"Graphics" and _graphics_dirty:
			_cancel_pending_graphics()
		back_requested.emit()
		get_viewport().set_input_as_handled()

func _select_tab(index: int, instant := false) -> void:
	_selected_tab_index = wrapi(index, 0, TAB_ORDER.size())
	var selected_tab := TAB_ORDER[_selected_tab_index]
	for tab in pages:
		var page := pages[tab] as Control
		if page:
			page.visible = tab == selected_tab
	_update_tab_visuals()
	_refresh_option_items()
	_select_index(0, true)
	if not instant:
		AudioManager.play_ui(&"menu_select")

func _select_index(index: int, instant := false) -> void:
	if _option_items.is_empty():
		return
	_selected_index = wrapi(index, 0, _option_items.size())
	for i in _option_items.size():
		_option_items[i].call("set_selected", i == _selected_index)
	if not instant:
		AudioManager.play_ui(&"ui_click")

func _on_option_focused(option: Control) -> void:
	var index := _option_items.find(option)
	if index >= 0:
		_select_index(index)

func _on_resolution_changed(_stepper: Control, direction: int) -> void:
	_pending_resolution_index = wrapi(_pending_resolution_index + direction, 0, DisplaySettings.RESOLUTIONS.size())
	_mark_graphics_dirty()
	_refresh_graphics_options()
	AudioManager.play_ui(&"ui_click")

func _on_resolution_selected(_stepper: Control, index: int) -> void:
	_pending_resolution_index = clampi(index, 0, DisplaySettings.RESOLUTIONS.size() - 1)
	_mark_graphics_dirty()
	_refresh_graphics_options()
	AudioManager.play_ui(&"menu_select")

func _on_fullscreen_changed(_stepper: Control, _direction: int) -> void:
	_pending_fullscreen = not _pending_fullscreen
	_mark_graphics_dirty()
	_refresh_graphics_options()
	AudioManager.play_ui(&"ui_click")

func _on_fullscreen_selected(_stepper: Control, index: int) -> void:
	_pending_fullscreen = index == 1
	_mark_graphics_dirty()
	_refresh_graphics_options()
	AudioManager.play_ui(&"menu_select")

func _on_vsync_changed(_stepper: Control, _direction: int) -> void:
	_pending_vsync = not _pending_vsync
	_mark_graphics_dirty()
	_refresh_graphics_options()
	AudioManager.play_ui(&"ui_click")

func _on_frame_limit_changed(_stepper: Control, direction: int) -> void:
	_pending_frame_rate_limit_index = wrapi(_pending_frame_rate_limit_index + direction, 0, DisplaySettings.FRAME_RATE_LIMITS.size())
	_mark_graphics_dirty()
	_refresh_graphics_options()
	AudioManager.play_ui(&"ui_click")

func _on_frame_limit_selected(_stepper: Control, index: int) -> void:
	_pending_frame_rate_limit_index = clampi(index, 0, DisplaySettings.FRAME_RATE_LIMITS.size() - 1)
	_mark_graphics_dirty()
	_refresh_graphics_options()
	AudioManager.play_ui(&"menu_select")

func _on_quality_changed(_stepper: Control, direction: int) -> void:
	_pending_quality_preset_index = wrapi(_pending_quality_preset_index + direction, 0, DisplaySettings.QUALITY_PRESETS.size())
	_mark_graphics_dirty()
	_refresh_graphics_options()
	AudioManager.play_ui(&"ui_click")

func _on_quality_selected(_stepper: Control, index: int) -> void:
	_pending_quality_preset_index = clampi(index, 0, DisplaySettings.QUALITY_PRESETS.size() - 1)
	_mark_graphics_dirty()
	_refresh_graphics_options()
	AudioManager.play_ui(&"menu_select")

func _apply_pending_graphics() -> void:
	DisplaySettings.apply_graphics_settings(
		_pending_resolution_index,
		_pending_fullscreen,
		_pending_vsync,
		_pending_frame_rate_limit_index,
		_pending_quality_preset_index
	)
	_graphics_dirty = false
	_refresh_graphics_options()
	AudioManager.play_ui(&"menu_select")

func _cancel_pending_graphics() -> void:
	_sync_pending_graphics_from_saved()
	_graphics_dirty = false
	_refresh_graphics_options()
	AudioManager.play_ui(&"ui_click")

func _on_gameplay_setting_changed(_stepper: Control, direction: int, setting_name: StringName) -> void:
	if setting_name == &"difficulty":
		GameplaySettings.cycle_difficulty(direction)
	else:
		GameplaySettings.cycle_toggle(setting_name)
	AudioManager.play_ui(&"ui_click")

func _on_gameplay_setting_selected(_stepper: Control, index: int, setting_name: StringName) -> void:
	if setting_name == &"difficulty":
		GameplaySettings.set_difficulty_index(index)
		AudioManager.play_ui(&"menu_select")

func _on_controls_option_changed(_stepper: Control, _direction: int) -> void:
	if _stepper == controls_items[0]:
		_open_controls_overlay(_last_input_family)
	elif _stepper == controls_items[1]:
		InputBindingManager.reset_to_defaults()
	AudioManager.play_ui(&"ui_click")

func _refresh_graphics_options() -> void:
	if resolution_stepper:
		resolution_stepper.call("set_selected_index", _pending_resolution_index)
	if fullscreen_stepper:
		fullscreen_stepper.call("set_selected_index", 1 if _pending_fullscreen else 0)
	if vsync_stepper:
		vsync_stepper.call("set_toggle_checked", _pending_vsync)
	if frame_limit_stepper:
		frame_limit_stepper.call("set_selected_index", _pending_frame_rate_limit_index)
	if quality_stepper:
		quality_stepper.call("set_selected_index", _pending_quality_preset_index)

func _refresh_gameplay_options() -> void:
	(gameplay_steppers[&"difficulty"] as Control).call("set_selected_index", GameplaySettings.difficulty_index)
	(gameplay_steppers[&"auto_save"] as Control).call("set_toggle_checked", GameplaySettings.auto_save)
	(gameplay_steppers[&"tutorial_hints"] as Control).call("set_toggle_checked", GameplaySettings.tutorial_hints)
	(gameplay_steppers[&"vibration"] as Control).call("set_toggle_checked", GameplaySettings.vibration)
	(gameplay_steppers[&"damage_numbers"] as Control).call("set_toggle_checked", GameplaySettings.damage_numbers)

func _refresh_option_items() -> void:
	var selected_tab := TAB_ORDER[_selected_tab_index]
	match selected_tab:
		&"Graphics":
			_option_items = [resolution_stepper, fullscreen_stepper, vsync_stepper, frame_limit_stepper, quality_stepper]
		&"Audio":
			_option_items.assign(sliders)
		&"Gameplay":
			_option_items = [
				gameplay_steppers[&"difficulty"],
				gameplay_steppers[&"auto_save"],
				gameplay_steppers[&"tutorial_hints"],
				gameplay_steppers[&"vibration"],
				gameplay_steppers[&"damage_numbers"],
			]
		&"Controls":
			_option_items.assign(controls_items)
		_:
			_option_items = []

func _on_tab_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_tab(index)

func _on_tab_mouse_entered(index: int) -> void:
	_hovered_tab_index = index
	_update_tab_visuals()

func _on_tab_mouse_exited(index: int) -> void:
	if _hovered_tab_index == index:
		_hovered_tab_index = -1
	_update_tab_visuals()

func _update_tab_visuals() -> void:
	for i in tab_labels.size():
		var selected := i == _selected_tab_index
		var hovered := i == _hovered_tab_index
		tab_labels[i].modulate = Color(1.0, 0.82, 0.36, 1.0) if selected else Color(0.9, 0.72, 0.48, 1.0) if hovered else Color(0.68, 0.58, 0.42, 1.0)

func _configure_option_rows() -> void:
	_sync_pending_graphics_from_saved()
	resolution_stepper.call("configure_dropdown", DisplaySettings.get_resolution_labels(), DisplaySettings.resolution_index)
	fullscreen_stepper.call("configure_dropdown", ["WINDOWED", "FULLSCREEN"], 1 if DisplaySettings.fullscreen else 0)
	vsync_stepper.call("configure_toggle", DisplaySettings.vsync)
	frame_limit_stepper.call("configure_dropdown", DisplaySettings.get_frame_rate_limit_labels(), DisplaySettings.frame_rate_limit_index)
	quality_stepper.call("configure_dropdown", DisplaySettings.QUALITY_PRESETS, DisplaySettings.quality_preset_index)

	(gameplay_steppers[&"difficulty"] as Control).call("configure_dropdown", GameplaySettings.DIFFICULTIES, GameplaySettings.difficulty_index)
	(gameplay_steppers[&"auto_save"] as Control).call("configure_toggle", GameplaySettings.auto_save)
	(gameplay_steppers[&"tutorial_hints"] as Control).call("configure_toggle", GameplaySettings.tutorial_hints)
	(gameplay_steppers[&"vibration"] as Control).call("configure_toggle", GameplaySettings.vibration)
	(gameplay_steppers[&"damage_numbers"] as Control).call("configure_toggle", GameplaySettings.damage_numbers)

	controls_items[0].call("configure_button", "OPEN CONTROLS")
	controls_items[1].call("configure_button", "RESET TO DEFAULTS")

func _sync_pending_graphics_from_saved() -> void:
	_pending_resolution_index = DisplaySettings.resolution_index
	_pending_fullscreen = DisplaySettings.fullscreen
	_pending_vsync = DisplaySettings.vsync
	_pending_frame_rate_limit_index = DisplaySettings.frame_rate_limit_index
	_pending_quality_preset_index = DisplaySettings.quality_preset_index

func _mark_graphics_dirty() -> void:
	_graphics_dirty = (
		_pending_resolution_index != DisplaySettings.resolution_index
		or _pending_fullscreen != DisplaySettings.fullscreen
		or _pending_vsync != DisplaySettings.vsync
		or _pending_frame_rate_limit_index != DisplaySettings.frame_rate_limit_index
		or _pending_quality_preset_index != DisplaySettings.quality_preset_index
	)

func _open_controls_overlay(input_family: StringName) -> void:
	var controls_menu := GAME_MENU_SCENE.instantiate()
	get_tree().root.add_child(controls_menu)
	visible = false
	controls_menu.tree_exited.connect(_on_controls_overlay_closed)
	if controls_menu.has_method("open_controls_only"):
		controls_menu.open_controls_only(input_family)
	else:
		controls_menu.open(&"Controls", input_family)

func _on_controls_overlay_closed() -> void:
	get_tree().paused = true
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_flow_state_audio_suspended"):
		player.set_flow_state_audio_suspended(true)
	visible = true

func _update_input_family_from_event(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		_last_input_family = &"keyboard_mouse"
	elif event is InputEventJoypadButton and event.pressed:
		_last_input_family = _get_controller_family(event.device)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.45:
		_last_input_family = _get_controller_family(event.device)

func _get_controller_family(device_id: int) -> StringName:
	var joy_name := Input.get_joy_name(device_id).to_lower()
	if joy_name.contains("playstation") or joy_name.contains("ps5") or joy_name.contains("dualsense") or joy_name.contains("dualshock"):
		return &"ps5"
	if joy_name.contains("nintendo") or joy_name.contains("switch") or joy_name.contains("joy-con") or joy_name.contains("pro controller"):
		return &"nintendo"
	if joy_name.contains("steam"):
		return &"steam"
	return &"xbox"
