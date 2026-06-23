extends CanvasLayer

@export var display_time := 4.0
@export var fade_time := 0.18

@onready var panel: Panel = $Panel as Panel
@onready var message_label: Label = $Panel/MarginContainer/MessageLabel as Label

var _tween: Tween

func _ready() -> void:
	add_to_group("demo_message_box")
	visible = false
	panel.modulate.a = 0.0

func show_message(message: String) -> void:
	if _tween:
		_tween.kill()

	message_label.text = message
	visible = true
	panel.modulate.a = 0.0

	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 1.0, fade_time)
	_tween.tween_interval(display_time)
	_tween.tween_property(panel, "modulate:a", 0.0, fade_time)
	_tween.tween_callback(func() -> void: visible = false)
