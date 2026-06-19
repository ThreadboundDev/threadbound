class_name AimHelper
extends RefCounted

const DEFAULT_AIM_DEADZONE := 0.2
const MOUSE_AIM_MIN_DISTANCE := 4.0

static func get_aim_direction(context: Node2D, origin: Vector2, fallback: Vector2 = Vector2.RIGHT, deadzone: float = DEFAULT_AIM_DEADZONE) -> Vector2:
	var stick_direction := get_right_stick_direction(deadzone)
	if stick_direction.length() > 0.0:
		return stick_direction

	if context:
		var mouse_direction := context.get_global_mouse_position() - origin
		if mouse_direction.length() >= MOUSE_AIM_MIN_DISTANCE:
			return mouse_direction.normalized()

	if fallback.length() > 0.0:
		return fallback.normalized()

	return Vector2.RIGHT

static func get_right_stick_direction(deadzone: float = DEFAULT_AIM_DEADZONE) -> Vector2:
	for device_id in Input.get_connected_joypads():
		var direction := Vector2(
			Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
		)
		if direction.length() > deadzone:
			return direction.normalized()

	return Vector2.ZERO
