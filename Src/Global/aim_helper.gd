class_name AimHelper
extends RefCounted

const DEFAULT_AIM_DEADZONE := 0.2
const MOUSE_AIM_MIN_DISTANCE := 4.0

static func get_aim_direction(context: Node2D, origin: Vector2, fallback: Vector2 = Vector2.RIGHT, deadzone: float = DEFAULT_AIM_DEADZONE) -> Vector2:
	var stick_direction := get_right_stick_direction(deadzone)
	if stick_direction.length() > 0.0:
		return stick_direction
	if _is_controller_active():
		return fallback.normalized() if fallback.length() > 0.0 else Vector2.RIGHT

	if context:
		var mouse_direction := context.get_global_mouse_position() - origin
		if mouse_direction.length() >= MOUSE_AIM_MIN_DISTANCE:
			return mouse_direction.normalized()

	if fallback.length() > 0.0:
		return fallback.normalized()

	return Vector2.RIGHT

static func _is_controller_active() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return false
	var input_tracker := tree.root.get_node_or_null("CustomCursor")
	return (
		input_tracker != null
		and input_tracker.has_method("is_controller_active")
		and bool(input_tracker.call("is_controller_active"))
	)

static func get_right_stick_direction(deadzone: float = DEFAULT_AIM_DEADZONE) -> Vector2:
	for device_id in Input.get_connected_joypads():
		var direction := Vector2(
			Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
		)
		if direction.length() > deadzone:
			return direction.normalized()

	if (
		InputMap.has_action("aim_left")
		and InputMap.has_action("aim_right")
		and InputMap.has_action("aim_up")
		and InputMap.has_action("aim_down")
	):
		var action_direction := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", deadzone)
		if action_direction.length() > 0.0:
			return action_direction.normalized()

	return Vector2.ZERO
