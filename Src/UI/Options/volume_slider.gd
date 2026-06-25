extends Control
class_name VolumeSlider

signal focused(slider: VolumeSlider)

@export var category: StringName = &"music"
@export var label_text := "MUSIC"
@export var value_step := 0.05
@export var knob_center_offset := Vector2(0.0, 0.0)

@onready var label: Label = $Label as Label
@onready var progress_bar: TextureProgressBar = $VolumeBar as TextureProgressBar
@onready var knob: TextureRect = $Knob as TextureRect

var _dragging := false

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
	progress_bar.value = AudioManager.get_category_volume(category)

func _set_from_local_x(local_x: float) -> void:
	var value := clampf((local_x - progress_bar.position.x) / maxf(progress_bar.size.x, 1.0), 0.0, 1.0)
	_set_value(value)

func _nudge(amount: float) -> void:
	_set_value(clampf(float(progress_bar.value) + amount, 0.0, 1.0))

func _set_value(value: float) -> void:
	progress_bar.value = value
	AudioManager.set_category_volume(category, value)
	_update_knob()

func _update_knob() -> void:
	if not progress_bar or not knob:
		return

	var ratio := clampf(float(progress_bar.value), 0.0, 1.0)
	var knob_x := progress_bar.position.x + ratio * progress_bar.size.x - (knob.size.x * 0.5)
	knob.position.x = knob_x + knob_center_offset.x
	knob.position.y = progress_bar.position.y + (progress_bar.size.y - knob.size.y) * 0.5 + knob_center_offset.y
