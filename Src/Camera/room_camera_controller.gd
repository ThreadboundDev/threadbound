class_name RoomCameraController
extends Camera2D

## Clamps the camera to the active RoomCameraZone2D while retaining the
## existing RemoteTransform2D follow and Camera2D position smoothing.

@export var player_path: NodePath = ^"../Player"
@export var camera_follow_path: NodePath = ^"../Player/RemoteTransform2D"
@export var retain_last_zone_between_rooms := true

var _active_zone: RoomCameraZone2D

@onready var _player := get_node_or_null(player_path) as Node2D
@onready var _camera_follow := get_node_or_null(
	camera_follow_path
) as RemoteTransform2D


func _ready() -> void:
	# RemoteTransform2D updates during the regular process pass. Running later
	# lets this controller constrain its result without replacing player follow.
	process_priority = 100


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return
	# The boss introduction disables this follow node while it owns the camera.
	# Suspending here keeps room clamping out of cinematic camera movement.
	if is_instance_valid(_camera_follow) and not _camera_follow.update_position:
		return

	var matching_zone := _find_zone_for_position(_player.global_position)
	if matching_zone:
		_active_zone = matching_zone
	elif not retain_last_zone_between_rooms:
		_active_zone = null
	if not is_instance_valid(_active_zone):
		return

	global_position = _active_zone.clamp_camera_center(
		_player.global_position,
		_get_world_viewport_half_size()
	)


func get_active_zone() -> RoomCameraZone2D:
	return _active_zone


func refresh_active_zone() -> void:
	_active_zone = null


func _find_zone_for_position(global_point: Vector2) -> RoomCameraZone2D:
	var best_zone: RoomCameraZone2D
	for node in get_tree().get_nodes_in_group(&"room_camera_zones"):
		var zone := node as RoomCameraZone2D
		if not zone or not zone.enabled or not zone.contains_global_point(global_point):
			continue
		if not best_zone or zone.zone_priority > best_zone.zone_priority:
			best_zone = zone
	return best_zone


func _get_world_viewport_half_size() -> Vector2:
	var safe_zoom := Vector2(
		maxf(absf(zoom.x), 0.001),
		maxf(absf(zoom.y), 0.001)
	)
	return get_viewport_rect().size * 0.5 / safe_zoom
