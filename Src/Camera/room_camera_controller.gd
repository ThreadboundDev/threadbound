class_name RoomCameraController
extends Camera2D

## Composes player follow before clamping the camera to the active room zone.
## Boss and cinematic cameras retain exclusive control whenever the player's
## RemoteTransform2D has position updates disabled.

@export var player_path: NodePath = ^"../Player"
@export var camera_follow_path: NodePath = ^"../Player/RemoteTransform2D"
@export var retain_last_zone_between_rooms := true

@export_group("Follow Composition")
@export_range(0.0, 256.0, 1.0) var horizontal_dead_zone := 28.0
@export_range(0.0, 256.0, 1.0) var vertical_dead_zone := 24.0
@export_range(0.0, 256.0, 1.0) var look_ahead_distance := 120.0
@export_range(1.0, 1200.0, 1.0) var full_look_ahead_speed := 500.0
@export_range(0.1, 30.0, 0.1) var look_ahead_response := 10.0
@export_range(0.0, 256.0, 1.0) var dash_look_ahead_distance := 60.0
@export_range(1.0, 1600.0, 1.0) var dash_look_ahead_start_speed := 700.0
@export_range(1.0, 1800.0, 1.0) var full_dash_look_ahead_speed := 1150.0

@export_group("Fall Framing")
@export_range(0.0, 1200.0, 1.0) var fall_look_ahead_start_speed := 180.0
@export_range(1.0, 1600.0, 1.0) var full_fall_look_ahead_speed := 760.0
@export_range(0.0, 256.0, 1.0) var fall_look_ahead_distance := 96.0
@export_range(0.1, 30.0, 0.1) var fall_look_ahead_response := 9.0

var _active_zone: RoomCameraZone2D
var _follow_target := Vector2.ZERO
var _current_look_ahead := Vector2.ZERO
var _follow_initialized := false
var _follow_was_suspended := false

@onready var _player := get_node_or_null(player_path) as Node2D
@onready var _camera_follow := get_node_or_null(
	camera_follow_path
) as RemoteTransform2D


func _ready() -> void:
	# RemoteTransform2D updates during the regular process pass. Running later
	# lets this controller constrain its result without replacing player follow.
	process_priority = 100


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	# The boss introduction disables this follow node while it owns the camera.
	# Do not write any camera state until that ownership has been returned.
	if is_instance_valid(_camera_follow) and not _camera_follow.update_position:
		_follow_was_suspended = true
		_follow_initialized = false
		return

	var player_position := _player.global_position
	if _follow_was_suspended or not _follow_initialized:
		_reset_follow_state(player_position)

	var velocity := _get_player_velocity()
	var desired_position := player_position + _update_look_ahead(velocity, delta)
	_follow_target = _apply_dead_zone(_follow_target, desired_position)

	var matching_zone := _find_zone_for_position(player_position)
	if matching_zone:
		_active_zone = matching_zone
	elif not retain_last_zone_between_rooms:
		_active_zone = null
	if not is_instance_valid(_active_zone):
		return

	if is_instance_valid(_active_zone):
		_follow_target = _active_zone.clamp_camera_center(
			_follow_target,
			_get_world_viewport_half_size()
		)
	global_position = _follow_target


func get_active_zone() -> RoomCameraZone2D:
	return _active_zone


func refresh_active_zone() -> void:
	_active_zone = null


func get_follow_target() -> Vector2:
	return _follow_target


func is_follow_suspended() -> bool:
	var follow := _camera_follow
	if not is_instance_valid(follow):
		follow = get_node_or_null(camera_follow_path) as RemoteTransform2D
	return is_instance_valid(follow) and not follow.update_position


func _reset_follow_state(player_position: Vector2) -> void:
	_follow_target = player_position
	_current_look_ahead = Vector2.ZERO
	_follow_initialized = true
	_follow_was_suspended = false


func _get_player_velocity() -> Vector2:
	if _player is CharacterBody2D:
		return (_player as CharacterBody2D).velocity
	var velocity_value: Variant = _player.get("velocity")
	return velocity_value as Vector2 if velocity_value is Vector2 else Vector2.ZERO


func _get_player_facing(velocity: Vector2) -> float:
	var facing_value: Variant = _player.get("last_direction")
	if facing_value is int or facing_value is float:
		var facing := signf(float(facing_value))
		if not is_zero_approx(facing):
			return facing
	if not is_zero_approx(velocity.x):
		return signf(velocity.x)
	return 1.0


func _update_look_ahead(velocity: Vector2, delta: float) -> Vector2:
	var horizontal_strength := clampf(
		absf(velocity.x) / maxf(full_look_ahead_speed, 1.0),
		0.0,
		1.0
	)
	var dash_speed_range := maxf(
		full_dash_look_ahead_speed - dash_look_ahead_start_speed,
		1.0
	)
	var dash_strength := clampf(
		(absf(velocity.x) - dash_look_ahead_start_speed) / dash_speed_range,
		0.0,
		1.0
	)
	var target_x := (
		_get_player_facing(velocity)
		* (
			look_ahead_distance * horizontal_strength
			+ dash_look_ahead_distance * dash_strength
		)
	)
	var horizontal_weight := 1.0 - exp(-look_ahead_response * delta)
	_current_look_ahead.x = lerpf(
		_current_look_ahead.x,
		target_x,
		horizontal_weight
	)

	var fall_speed_range := maxf(
		full_fall_look_ahead_speed - fall_look_ahead_start_speed,
		1.0
	)
	var fall_strength := clampf(
		(velocity.y - fall_look_ahead_start_speed) / fall_speed_range,
		0.0,
		1.0
	)
	var target_y := fall_look_ahead_distance * fall_strength
	var vertical_weight := 1.0 - exp(-fall_look_ahead_response * delta)
	_current_look_ahead.y = lerpf(
		_current_look_ahead.y,
		target_y,
		vertical_weight
	)
	return _current_look_ahead


func _apply_dead_zone(current: Vector2, desired: Vector2) -> Vector2:
	var result := current
	var difference := desired - current
	if absf(difference.x) > horizontal_dead_zone:
		result.x = desired.x - signf(difference.x) * horizontal_dead_zone
	if absf(difference.y) > vertical_dead_zone:
		result.y = desired.y - signf(difference.y) * vertical_dead_zone
	return result


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
