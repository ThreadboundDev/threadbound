@tool
class_name BlueReflectiveWater2D
extends ColorRect

@export var fallback_size := Vector2(512.0, 256.0):
	set(value):
		fallback_size = Vector2(maxf(value.x, 16.0), maxf(value.y, 16.0))
		_sync_to_water_volume()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_to_water_volume()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	_sync_to_water_volume()


func _sync_to_water_volume() -> void:
	var target_size := fallback_size
	var water_volume := get_parent()
	if water_volume != null:
		var parent_size: Variant = water_volume.get("size")
		if parent_size is Vector2:
			target_size = parent_size
	# The parent volume owns world scaling. A stale child scale or position makes
	# this Control stretch from its top-left pivot and visibly leave the hitbox.
	# Reassert the complete local rect, not only its size, on every editor sync.
	scale = Vector2.ONE
	rotation = 0.0
	position = -target_size * 0.5
	size = target_size
