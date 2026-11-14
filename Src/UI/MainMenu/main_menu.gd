extends Control

const DEMO_SCENE := "res://Src/Environment/World/Chamber Of The First Weave - Demo 2.0.tscn"
const ORIGINAL_DEMO_SCENE := "res://Src/Environment/World/Chamber Of The First Weave.tscn"
const MENU_BUTTON_THEME := preload("res://Src/UI/menu_button_theme.gd")

@export var button_accent := MENU_BUTTON_THEME.CHAMBER
@export var title_screen_preview := false

@onready var options_panel: OptionsPanel = $OptionsPanel as OptionsPanel
@onready var support_panel: PlaytestSupportPanel = $PlaytestSupportPanel as PlaytestSupportPanel
@onready var confirmation_layer: Control = $NewJourneyConfirmation as Control
@onready var confirmation_choices: Array[Control] = [$NewJourneyConfirmation/Panel/Confirm, $NewJourneyConfirmation/Panel/Cancel]
@onready var rows: Array[Control] = [
	$MenuButtons/Continue,
	$MenuButtons/NewJourney,
	$MenuButtons/Settings,
	$MenuButtons/Extras,
	$MenuButtons/Quit,
]

var _selected_index := 1
var _row_tweens: Dictionary = {}
var _showing_options := false
var _showing_support := false
var _confirming_new_journey := false
var _confirmation_index := 1
var _starting_new_journey := false
var _button_theme: Theme

func _ready() -> void:
	AudioManager.play_title_screen_music()
	DemoProgress.load_checkpoint()
	options_panel.visible = false
	support_panel.visible = false
	confirmation_layer.visible = false
	if not DemoProgress.checkpoint_changed.is_connected(_refresh_continue_state):
		DemoProgress.checkpoint_changed.connect(_refresh_continue_state)
	options_panel.back_requested.connect(_hide_options)
	support_panel.back_requested.connect(_hide_playtest_support)
	_button_theme = MENU_BUTTON_THEME.create(button_accent)
	for i in rows.size():
		var row := rows[i]
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.draw.connect(_draw_menu_row.bind(i))
		row.mouse_entered.connect(_select_index.bind(i))
		row.gui_input.connect(_on_row_gui_input.bind(i))
	for i in confirmation_choices.size():
		confirmation_choices[i].mouse_entered.connect(_select_confirmation.bind(i))
		confirmation_choices[i].gui_input.connect(_on_confirmation_gui_input.bind(i))

	_select_index(0 if _can_continue() else 1, true)

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F5:
		get_viewport().set_input_as_handled()
		_request_new_journey()
		return

	if _confirming_new_journey:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			_select_confirmation(1 - _confirmation_index)
			get_viewport().set_input_as_handled()
		elif _is_confirm_event(event):
			_activate_confirmation()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			_hide_new_journey_confirmation()
			get_viewport().set_input_as_handled()
		return

	if _showing_options:
		if event.is_action_pressed("ui_cancel"):
			_hide_options()
			get_viewport().set_input_as_handled()
		return

	if _showing_support:
		if event.is_action_pressed("ui_cancel"):
			_hide_playtest_support()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_select_index(_selected_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_select_index(_selected_index + 1)
		get_viewport().set_input_as_handled()
	elif _is_confirm_event(event):
		get_viewport().set_input_as_handled()
		_activate_selected()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _on_row_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_index(index)
		_activate_selected()

func _select_index(index: int, instant := false) -> void:
	if not instant:
		AudioManager.play_ui(&"ui_click")

	_selected_index = wrapi(index, 0, rows.size())
	for i in rows.size():
		_set_row_selected(i, i == _selected_index)

func _set_row_selected(index: int, is_selected: bool) -> void:
	var row := rows[index]
	var label := row.get_node("Label") as Label
	var target_color := MENU_BUTTON_THEME.TEXT
	if not _is_row_enabled(index):
		target_color = MENU_BUTTON_THEME.DISABLED_TEXT
	elif is_selected:
		target_color = MENU_BUTTON_THEME.ACTIVE_TEXT
	label.modulate = target_color
	row.queue_redraw()

func _draw_menu_row(index: int) -> void:
	var row := rows[index]
	var rect := Rect2(Vector2.ZERO, row.size)
	var enabled := _is_row_enabled(index)
	var selected := index == _selected_index
	var state := &"disabled" if not enabled else (&"hover" if selected else &"normal")
	row.draw_style_box(_button_theme.get_stylebox(state, &"Button"), rect)
	if selected:
		row.draw_style_box(_button_theme.get_stylebox(&"focus", &"Button"), rect)

func _activate_selected() -> void:
	AudioManager.play_ui(&"menu_select")
	match rows[_selected_index].name:
		&"Continue":
			if _can_continue():
				_continue_journey()
			else:
				_pulse_unavailable(rows[_selected_index])
		&"NewJourney":
			_request_new_journey()
		&"Settings":
			_show_options()
		&"Extras":
			_show_playtest_support()
		&"Quit":
			get_tree().quit()
		_:
			_pulse_unavailable(rows[_selected_index])

func _continue_journey() -> void:
	AudioManager.play_ui(&"enter_world")
	if title_screen_preview:
		print("Title screen preview: Continue")
		return
	EquipManager.restore_loadout(DemoProgress.get_checkpoint_loadout())
	get_tree().change_scene_to_file(DemoProgress.get_checkpoint_scene_path())

func _start_new_journey() -> void:
	if title_screen_preview:
		_hide_new_journey_confirmation()
		AudioManager.play_ui(&"enter_world")
		print("Title screen preview: New Journey")
		return
	if _starting_new_journey:
		return
	_starting_new_journey = true
	_confirming_new_journey = false
	confirmation_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_perform_new_journey_transition")

func _perform_new_journey_transition() -> void:
	DemoProgress.clear_run()
	EquipManager.restore_loadout(DemoProgress.get_checkpoint_loadout())
	AudioManager.play_ui(&"enter_world")
	var error := get_tree().change_scene_to_file(DEMO_SCENE)
	if error != OK:
		_starting_new_journey = false
		confirmation_layer.mouse_filter = Control.MOUSE_FILTER_STOP
		push_error("MainMenu: Failed to start a New Journey: %s" % error_string(error))

func _request_new_journey() -> void:
	if _starting_new_journey:
		return
	if not title_screen_preview and not DemoProgress.has_checkpoint():
		_start_new_journey()
		return
	_confirming_new_journey = true
	_confirmation_index = 1
	confirmation_layer.visible = true
	$MenuButtons.visible = false
	_select_confirmation(_confirmation_index, true)

func _hide_new_journey_confirmation() -> void:
	_confirming_new_journey = false
	confirmation_layer.visible = false
	$MenuButtons.visible = true
	_select_index(_selected_index, true)

func _select_confirmation(index: int, instant := false) -> void:
	_confirmation_index = clampi(index, 0, confirmation_choices.size() - 1)
	for i in confirmation_choices.size():
		var choice := confirmation_choices[i]
		var backing := choice.get_node("Backing") as ColorRect
		var label := choice.get_node("Label") as Label
		var selected := i == _confirmation_index
		backing.color = Color(0.30, 0.20, 0.07, 0.96) if selected else Color(0.07, 0.055, 0.035, 0.94)
		label.modulate = Color(1.0, 0.88, 0.64, 1.0) if selected else Color(0.68, 0.61, 0.5, 1.0)
	if not instant:
		AudioManager.play_ui(&"ui_click")

func _activate_confirmation() -> void:
	if _confirmation_index == 0:
		_start_new_journey()
	else:
		_hide_new_journey_confirmation()

func _on_confirmation_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_confirmation(index, true)
		_activate_confirmation()

func _pulse_unavailable(row: Control) -> void:
	if _row_tweens.has(row):
		(_row_tweens[row] as Tween).kill()
	var tween := create_tween()
	_row_tweens[row] = tween
	tween.tween_property(row, "modulate", Color(0.72, 0.66, 0.58, 1.0), 0.08)
	tween.tween_property(row, "modulate", Color.WHITE, 0.14)

func _is_row_enabled(index: int) -> bool:
	var row_name := rows[index].name
	return row_name != &"Continue" or _can_continue()

func _can_continue() -> bool:
	return DemoProgress.has_checkpoint() and DemoProgress.get_checkpoint_scene_path() != ORIGINAL_DEMO_SCENE

func _refresh_continue_state() -> void:
	for i in rows.size():
		_set_row_selected(i, i == _selected_index)

func _show_options() -> void:
	_showing_options = true
	$MenuButtons.visible = false
	options_panel.visible = true

func _hide_options() -> void:
	_showing_options = false
	options_panel.visible = false
	$MenuButtons.visible = true
	_select_index(_selected_index, true)

func _show_playtest_support() -> void:
	_showing_support = true
	$MenuButtons.visible = false
	options_panel.visible = false
	support_panel.open()

func _hide_playtest_support() -> void:
	if not _showing_support:
		return
	_showing_support = false
	support_panel.visible = false
	$MenuButtons.visible = true
	_select_index(_selected_index, true)

func _is_confirm_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_A
	return event.is_action_pressed("Attack") or event.is_action_pressed("Jump")
