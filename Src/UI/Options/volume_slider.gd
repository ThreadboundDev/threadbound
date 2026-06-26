extends Control
class_name VolumeSlider

signal focused(slider: VolumeSlider)

@export var category: StringName = &"music"
@export var label_text := "MUSIC"
@export var value_step := 0.05
@export var knob_center_offset := Vector2(0.0, 0.0)

@onready var label: Label = $Label as Label
@onready var volume_bar: Control = $VolumeBar as Control
@onready var filled_clip: Control = $VolumeBar/FilledClip as Control
@onready var knob: TextureRect = $Knob as TextureRect

var _dragging := false
var _value := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	label.text = label_text
	_refresh_from_audio()
	_update_knob()

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
		_nudge(-value_step)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_nudge(value_step)
		get_viewport().set_input_as_handled()

func set_selected(is_selected: bool) -> void:
	modulate = Color(1.12, 1.06, 0.9, 1.0) if is_selected else Color.WHITE
	if is_selected:
		grab_focus()

func _refresh_from_audio() -> void:
	_value = AudioManager.get_category_volume(category)

func _set_from_local_x(local_x: float) -> void:
	var value := clampf((local_x - volume_bar.position.x) / maxf(volume_bar.size.x, 1.0), 0.0, 1.0)
	_set_value(value)

func _nudge(amount: float) -> void:
	_set_value(clampf(_value + amount, 0.0, 1.0))

func _set_value(value: float) -> void:
	_value = value
	AudioManager.set_category_volume(category, value)
	_update_knob()

func _update_knob() -> void:
	if not volume_bar or not filled_clip or not knob:
		return

	var ratio := clampf(_value, 0.0, 1.0)
	filled_clip.size.x = volume_bar.size.x * ratio
	var knob_x := volume_bar.position.x + ratio * volume_bar.size.x - (knob.size.x * 0.5)
	knob.position.x = knob_x + knob_center_offset.x
	knob.position.y = volume_bar.position.y + (volume_bar.size.y - knob.size.y) * 0.5 + knob_center_offset.y
