extends Control
class_name BrightnessSlider

signal focused(slider: BrightnessSlider)
signal value_changed(value: float)

@export var label_text := "BRIGHTNESS"
@export var value_step := 0.05
@export var knob_center_offset := Vector2.ZERO

@onready var label: Label = $Label as Label
@onready var volume_bar: Control = $VolumeBar as Control
@onready var filled_clip: Control = $VolumeBar/FilledClip as Control
@onready var knob: TextureRect = $Knob as TextureRect

var _dragging := false
var _value := DisplaySettings.DEFAULT_BRIGHTNESS

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_visuals()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			focused.emit(self)
			_set_from_local_x(event.position.x)
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_set_from_local_x(event.position.x)
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not has_focus():
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_set_value(_value - value_step, true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_set_value(_value + value_step, true)
		get_viewport().set_input_as_handled()

func set_selected(is_selected: bool) -> void:
	modulate = Color(1.12, 1.06, 0.9, 1.0) if is_selected else Color.WHITE
	if is_selected:
		grab_focus()

func set_value(value: float) -> void:
	_set_value(value, false)

func get_value() -> float:
	return _value

func _set_from_local_x(local_x: float) -> void:
	var value := clampf(
		(local_x - volume_bar.position.x) / maxf(volume_bar.size.x, 1.0),
		0.0,
		1.0
	)
	_set_value(value, true)

func _set_value(value: float, emit_change: bool) -> void:
	var snapped := snappedf(clampf(value, 0.0, 1.0), value_step)
	if is_equal_approx(_value, snapped):
		return
	_value = snapped
	_update_visuals()
	if emit_change:
		value_changed.emit(_value)

func _update_visuals() -> void:
	if label:
		label.text = "%s — %d%%" % [label_text, roundi(_value * 100.0)]
	if not volume_bar or not filled_clip or not knob:
		return
	var ratio := clampf(_value, 0.0, 1.0)
	filled_clip.size.x = volume_bar.size.x * ratio
	var knob_x := volume_bar.position.x + ratio * volume_bar.size.x - knob.size.x * 0.5
	knob.position.x = knob_x + knob_center_offset.x
	knob.position.y = volume_bar.position.y + (volume_bar.size.y - knob.size.y) * 0.5 + knob_center_offset.y
