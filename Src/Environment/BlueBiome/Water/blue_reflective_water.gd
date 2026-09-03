@tool
class_name BlueReflectiveWater2D
extends ColorRect

@export var fallback_size := Vector2(512.0, 256.0):
	set(value):
		fallback_size = Vector2(maxf(value.x, 16.0), maxf(value.y, 16.0))
		_sync_to_water_volume()

var _last_synced_size := Vector2.ZERO


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
	if target_size.is_equal_approx(_last_synced_size):
		return
	_last_synced_size = target_size
	offset_left = -target_size.x * 0.5
	offset_top = -target_size.y * 0.5
	offset_right = target_size.x * 0.5
	offset_bottom = target_size.y * 0.5

