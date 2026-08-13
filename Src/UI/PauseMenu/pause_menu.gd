extends CanvasLayer

@export var selector_offset := Vector2(20.0, -15.0)
@export var selected_scale := Vector2(1.04, 1.04)
@export var normal_scale := Vector2.ONE

@onready var menu_root: Control = $MenuRoot as Control
@onready var selector: TextureRect = $MenuRoot/Selector as TextureRect
@onready var options_panel: OptionsPanel = $OptionsPanel as OptionsPanel
@onready var support_panel: PlaytestSupportPanel = $PlaytestSupportPanel as PlaytestSupportPanel
@onready var rows: Array[Control] = [
	$MenuRoot/Buttons/Resume,
	$MenuRoot/Buttons/Settings,
	$MenuRoot/Buttons/PlaytestSupport,
	$MenuRoot/Buttons/Quit,
]

var _selected_index := 0
var _row_tweens: Dictionary = {}
var _showing_options := false
var _showing_support := false
var _closing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	add_to_group("pause_menu")
	get_tree().paused = true
	_set_player_flow_audio_suspended(true)
	AudioManager.play_pause_music()

	options_panel.visible = false
	support_panel.visible = false
	options_panel.back_requested.connect(_show_main_menu)
	support_panel.back_requested.connect(_show_main_menu)
	for i in rows.size():
		var row := rows[i]
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.pivot_offset = row.size * 0.5
		row.mouse_entered.connect(_select_index.bind(i))
		row.gui_input.connect(_on_row_gui_input.bind(i))

	_select_index(_selected_index, true)

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return

	if _showing_options:
		if event.is_action_pressed("open_menu") or event.is_action_pressed("ui_cancel"):
			_show_main_menu()
			get_viewport().set_input_as_handled()
		return
	if _showing_support:
		if event.is_action_pressed("open_menu") or event.is_action_pressed("ui_cancel"):
			_show_main_menu()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_select_index(_selected_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_select_index(_selected_index + 1)
		get_viewport().set_input_as_handled()
	elif _is_confirm_event(event):
		_activate_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_menu") or event.is_action_pressed("ui_cancel"):
		_resume_game()
		get_viewport().set_input_as_handled()

func _on_row_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_index(index)
		_activate_selected()

func _select_index(index: int, instant := false) -> void:
	if not instant:
		AudioManager.play_ui(&"ui_click")

	_selected_index = wrapi(index, 0, rows.size())
	for i in rows.size():
		_set_row_selected(i, i == _selected_index, instant)

	var row := rows[_selected_index]
	var plaque := row.get_node("Plaque") as TextureRect
	selector.visible = true
	selector.global_position = plaque.global_position + Vector2(plaque.size.x, 0.0) + selector_offset

func _set_row_selected(index: int, is_selected: bool, instant: bool) -> void:
	var row := rows[index]
	var plaque := row.get_node("Plaque") as TextureRect
	var label := row.get_node("Label") as Label
	var target_scale := selected_scale if is_selected else normal_scale
	var target_color := Color(1.0, 0.91, 0.72, 1.0) if is_selected else Color(0.78, 0.70, 0.58, 1.0)

	if instant:
		row.scale = target_scale
		label.modulate = target_color
		return

	if _row_tweens.has(row):
		(_row_tweens[row] as Tween).kill()
	var tween := create_tween()
	_row_tweens[row] = tween
	tween.set_parallel(true)
	tween.tween_property(row, "scale", target_scale, 0.12)
	tween.tween_property(plaque, "modulate", Color.WHITE, 0.12)
	tween.tween_property(label, "modulate", target_color, 0.12)

func _activate_selected() -> void:
	AudioManager.play_ui(&"menu_select")
	match rows[_selected_index].name:
		&"Resume":
			_resume_game()
		&"Settings":
			_show_options()
		&"PlaytestSupport":
			_show_playtest_support()
		&"Quit":
			get_tree().quit()

func _show_options() -> void:
	_showing_options = true
	_showing_support = false
	menu_root.visible = false
	support_panel.visible = false
	options_panel.visible = true

func _show_playtest_support() -> void:
	_showing_support = true
	_showing_options = false
	menu_root.visible = false
	options_panel.visible = false
	support_panel.open()

func _show_main_menu() -> void:
	_showing_options = false
	_showing_support = false
	options_panel.visible = false
	support_panel.visible = false
	menu_root.visible = true
	_select_index(_selected_index, true)

func _resume_game() -> void:
	if _closing:
		return

	_closing = true
	AudioManager.stop_pause_music()
	_set_player_flow_audio_suspended(false)
	get_tree().paused = false
	queue_free()

func _set_player_flow_audio_suspended(is_suspended: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_flow_state_audio_suspended"):
		player.set_flow_state_audio_suspended(is_suspended)

func _is_confirm_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_A
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("Attack") or event.is_action_pressed("Jump")
