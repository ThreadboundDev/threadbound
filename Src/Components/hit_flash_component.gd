class_name HitFlashComponent
extends Node

@export var target_path: NodePath
@export var flash_color := Color(1.0, 0.25, 0.25, 1.0)
@export var flash_duration := 0.08

@onready var target: CanvasItem = get_node_or_null(target_path)

var _base_modulate := Color.WHITE
var _tween: Tween

func _ready() -> void:
	if target:
		_base_modulate = target.modulate

func flash(color: Color = flash_color, duration: float = flash_duration) -> void:
	if not target:
		return

	if _tween:
		_tween.kill()

	target.modulate = color
	_tween = create_tween()
	_tween.tween_property(target, "modulate", _base_modulate, max(0.01, duration))
