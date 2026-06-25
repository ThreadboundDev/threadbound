extends Control

const DEMO_SCENE := "res://Src/Environment/World/Chamber Of The First Weave.tscn"

@export var selector_offset := Vector2(20.0, -15.0)
@export var selected_scale := Vector2(1.04, 1.04)
@export var normal_scale := Vector2.ONE
@export var disabled_alpha := 0.55

@onready var selector: TextureRect = $Selector as TextureRect
@onready var rows: Array[Control] = [
	$MenuButtons/Continue,
	$MenuButtons/NewJourney,
	$MenuButtons/Settings,
	$MenuButtons/Extras,
	$MenuButtons/Quit,
]

var _selected_index := 1
var _row_tweens: Dictionary = {}

func _ready() -> void:
	AudioManager.play_music(&"music_title")
	for i in rows.size():
		var row := rows[i]
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.pivot_offset = row.size * 0.5
		row.mouse_entered.connect(_select_index.bind(i))
		row.gui_input.connect(_on_row_gui_input.bind(i))

	_select_index(_selected_index, true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_select_index(_selected_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_select_index(_selected_index + 1)
		get_viewport().set_input_as_handled()
	elif _is_confirm_event(event):
		_activate_selected()
		get_viewport().set_input_as_handled()
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
	var target_alpha := 1.0 if _is_row_enabled(index) else disabled_alpha
	var target_color := Color(1.0, 0.91, 0.72, target_alpha) if is_selected else Color(0.78, 0.70, 0.58, target_alpha)

	if instant:
		row.scale = target_scale
		plaque.modulate = Color(1.0, 1.0, 1.0, target_alpha)
		label.modulate = target_color
		return

	if _row_tweens.has(row):
		(_row_tweens[row] as Tween).kill()
	var tween := create_tween()
	_row_tweens[row] = tween
	tween.set_parallel(true)
	tween.tween_property(row, "scale", target_scale, 0.12)
	tween.tween_property(plaque, "modulate", Color(1.0, 1.0, 1.0, target_alpha), 0.12)
	tween.tween_property(label, "modulate", target_color, 0.12)

func _activate_selected() -> void:
	AudioManager.play_ui(&"menu_select")
	match rows[_selected_index].name:
		&"NewJourney":
			AudioManager.play_ui(&"enter_world")
			get_tree().change_scene_to_file(DEMO_SCENE)
		&"Quit":
			get_tree().quit()
		_:
			_pulse_unavailable(rows[_selected_index])

func _pulse_unavailable(row: Control) -> void:
	if _row_tweens.has(row):
		(_row_tweens[row] as Tween).kill()
	var tween := create_tween()
	_row_tweens[row] = tween
	tween.tween_property(row, "modulate", Color(0.72, 0.66, 0.58, 1.0), 0.08)
	tween.tween_property(row, "modulate", Color.WHITE, 0.14)

func _is_row_enabled(index: int) -> bool:
	var row_name := rows[index].name
	return row_name == &"NewJourney" or row_name == &"Quit"

func _is_confirm_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_A
	return event.is_action_pressed("Attack") or event.is_action_pressed("Jump")
