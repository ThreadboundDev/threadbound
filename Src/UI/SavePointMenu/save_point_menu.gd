extends CanvasLayer

signal option_selected(option_name: StringName)
signal rise_requested

@export var selector_offset := Vector2(18.0, -10.0)
@export var selected_scale := Vector2(1.04, 1.04)
@export var normal_scale := Vector2.ONE
@export var menu_left_position := Vector2(180.0, 318.0)
@export var menu_right_position := Vector2(1140.0, 318.0)
@export var fade_duration := 0.18
@export var focus_left_center := Vector2(0.28, 0.56)
@export var focus_right_center := Vector2(0.72, 0.56)
@export var focus_radius := Vector2(0.22, 0.33)

@onready var blur_rect: ColorRect = $BlurRect as ColorRect
@onready var menu_root: Control = $MenuRoot as Control
@onready var selector: TextureRect = $MenuRoot/Selector as TextureRect
@onready var rows: Array[Control] = [
	$MenuRoot/Options/Reflect,
	$MenuRoot/Options/Weave,
	$MenuRoot/Options/Listen,
	$MenuRoot/Options/Rise,
]

var _selected_index := 0
var _row_tweens: Dictionary = {}
var _closing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_configure_initial_state()
	for i in rows.size():
		var row := rows[i]
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.pivot_offset = row.size * 0.5
		row.mouse_entered.connect(_select_index.bind(i))
		row.gui_input.connect(_on_row_gui_input.bind(i))

	_select_index(_selected_index, true)

func open(menu_side: int) -> void:
	menu_root.position = menu_right_position if menu_side >= 0 else menu_left_position
	_configure_focus(menu_side)
	_select_index(_selected_index, true)
	blur_rect.modulate.a = 0.0
	menu_root.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(blur_rect, "modulate:a", 1.0, fade_duration)
	tween.tween_property(menu_root, "modulate:a", 1.0, fade_duration)

func close() -> void:
	if _closing:
		return

	_closing = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(blur_rect, "modulate:a", 0.0, fade_duration)
	tween.tween_property(menu_root, "modulate:a", 0.0, fade_duration)
	await tween.finished
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
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
	elif event.is_action_pressed("ui_cancel"):
		rise_requested.emit()
		get_viewport().set_input_as_handled()

func _configure_initial_state() -> void:
	blur_rect.material = blur_rect.material.duplicate()
	blur_rect.visible = true
	menu_root.modulate.a = 0.0
	blur_rect.modulate.a = 0.0

func _configure_focus(menu_side: int) -> void:
	var shader_material := blur_rect.material as ShaderMaterial
	if not shader_material:
		return

	var focus_center := focus_left_center if menu_side >= 0 else focus_right_center
	shader_material.set_shader_parameter("focus_center", focus_center)
	shader_material.set_shader_parameter("focus_radius", focus_radius)
	shader_material.set_shader_parameter("focus_softness", 0.2)

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

	if instant:
		row.scale = target_scale
		label.modulate = Color.WHITE
		return

	if _row_tweens.has(row):
		(_row_tweens[row] as Tween).kill()
	var tween := create_tween()
	_row_tweens[row] = tween
	tween.set_parallel(true)
	tween.tween_property(row, "scale", target_scale, 0.12)
	tween.tween_property(label, "modulate", Color.WHITE, 0.12)
	tween.tween_property(plaque, "modulate", Color.WHITE, 0.12)

func _activate_selected() -> void:
	AudioManager.play_ui(&"menu_select")
	var selected_name := StringName(rows[_selected_index].name)
	if selected_name == &"Rise":
		rise_requested.emit()
		return

	option_selected.emit(selected_name)
	_pulse(rows[_selected_index])

func _pulse(row: Control) -> void:
	if _row_tweens.has(row):
		(_row_tweens[row] as Tween).kill()
	var tween := create_tween()
	_row_tweens[row] = tween
	tween.tween_property(row, "modulate", Color(0.72, 0.66, 0.58, 1.0), 0.08)
	tween.tween_property(row, "modulate", Color.WHITE, 0.14)

func _is_confirm_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_A
	return event.is_action_pressed("ui_accept") or event.is_action_pressed("Attack") or event.is_action_pressed("Jump")
