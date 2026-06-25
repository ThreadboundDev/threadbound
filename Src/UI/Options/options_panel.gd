extends Control
class_name OptionsPanel

signal back_requested

@onready var sliders: Array[VolumeSlider] = [
	$Sliders/Master,
	$Sliders/Music,
	$Sliders/BackgroundAudio,
	$Sliders/SFX,
	$Sliders/UI,
]

var _selected_index := 0

func _ready() -> void:
	for slider in sliders:
		slider.focused.connect(_on_slider_focused)
	_select_index(_selected_index, true)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_select_index(_selected_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_select_index(_selected_index + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()

func _select_index(index: int, instant := false) -> void:
	_selected_index = wrapi(index, 0, sliders.size())
	for i in sliders.size():
		sliders[i].set_selected(i == _selected_index)
	if not instant:
		AudioManager.play_ui(&"ui_click")

func _on_slider_focused(slider: VolumeSlider) -> void:
	var index := sliders.find(slider)
	if index >= 0:
		_select_index(index)
