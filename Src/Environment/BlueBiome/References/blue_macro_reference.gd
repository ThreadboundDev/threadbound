@tool
class_name BlueMacroReference2D
extends Sprite2D

@export var source_focus := Vector2.ZERO:
	set(value):
		source_focus = value
		_sync_reference()
@export_range(1.0, 20.0, 0.25) var map_scale := 12.0:
	set(value):
		map_scale = maxf(value, 1.0)
		_sync_reference()
@export_range(0.0, 1.0, 0.01) var reference_opacity := 0.22:
	set(value):
		reference_opacity = clampf(value, 0.0, 1.0)
		_sync_reference()
@export var hide_during_play := true


func _ready() -> void:
	_sync_reference()
	if not Engine.is_editor_hint() and hide_during_play:
		visible = false


func _sync_reference() -> void:
	centered = false
	position = -source_focus * map_scale
	scale = Vector2.ONE * map_scale
	modulate = Color(1.0, 1.0, 1.0, reference_opacity)
	z_index = -1000
	show_behind_parent = true
