class_name AimHelper
extends RefCounted

const DEFAULT_AIM_DEADZONE := 0.2
const MOUSE_AIM_MIN_DISTANCE := 4.0
const CONTROLLER_GRAPPLE_ASSIST_CONE_DEGREES := 12.0
const CONTROLLER_GRAPPLE_ASSIST_STRENGTH := 0.32
const CONTROLLER_GRAPPLE_ASSIST_RAY_COUNT := 7

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

static func get_grapple_aim_direction(
	context: Node2D,
	origin: Vector2,
	fallback: Vector2,
	max_distance: float,
	collision_mask: int,
	deadzone: float = DEFAULT_AIM_DEADZONE
) -> Vector2:
	var raw_direction := get_aim_direction(context, origin, fallback, deadzone)
	var stick_direction := get_right_stick_direction(deadzone)
	if stick_direction.is_zero_approx() or not _is_controller_active():
		return raw_direction
	if not context or not context.is_inside_tree() or max_distance <= 0.0:
		return raw_direction

	var candidate_directions := _sample_grapple_directions(
		context,
		origin,
		stick_direction,
		max_distance,
		collision_mask
	)
	return apply_directional_assist(
		stick_direction,
		candidate_directions,
		deg_to_rad(CONTROLLER_GRAPPLE_ASSIST_CONE_DEGREES),
		CONTROLLER_GRAPPLE_ASSIST_STRENGTH
	)

static func apply_directional_assist(
	raw_direction: Vector2,
	candidate_directions: Array[Vector2],
	cone_radians: float,
	strength: float
) -> Vector2:
	if raw_direction.is_zero_approx() or candidate_directions.is_empty():
		return raw_direction.normalized()

	var normalized_raw := raw_direction.normalized()
	var best_direction := Vector2.ZERO
	var best_angle := cone_radians + 0.001
	for candidate in candidate_directions:
		if candidate.is_zero_approx():
			continue
		var normalized_candidate := candidate.normalized()
		var angle := absf(normalized_raw.angle_to(normalized_candidate))
		if angle <= cone_radians and angle < best_angle:
			best_angle = angle
			best_direction = normalized_candidate

	if best_direction.is_zero_approx():
		return normalized_raw

	# Assistance fades at the edge of the cone, keeping deliberate stick input
	# dominant and preventing a nearby surface from becoming a hard lock.
	var alignment := 1.0 - clampf(best_angle / maxf(cone_radians, 0.001), 0.0, 1.0)
	var blend_weight := clampf(strength * alignment, 0.0, 1.0)
	return normalized_raw.lerp(best_direction, blend_weight).normalized()

static func _sample_grapple_directions(
	context: Node2D,
	origin: Vector2,
	raw_direction: Vector2,
	max_distance: float,
	collision_mask: int
) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	var world := context.get_world_2d()
	if not world:
		return candidates

	var exclusions: Array[RID] = []
	var root_collision := _find_collision_root(context)
	if root_collision:
		_collect_collision_rids(root_collision, exclusions)

	var ray_count := maxi(CONTROLLER_GRAPPLE_ASSIST_RAY_COUNT, 3)
	var cone_radians := deg_to_rad(CONTROLLER_GRAPPLE_ASSIST_CONE_DEGREES)
	for index in range(ray_count):
		var sample_ratio := float(index) / float(ray_count - 1)
		var angle_offset := lerpf(-cone_radians, cone_radians, sample_ratio)
		var sample_direction := raw_direction.rotated(angle_offset).normalized()
		var query := PhysicsRayQueryParameters2D.create(
			origin,
			origin + sample_direction * max_distance,
			collision_mask,
			exclusions
		)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		var result := world.direct_space_state.intersect_ray(query)
		if not result.is_empty():
			var hit_position: Vector2 = result.get("position", origin)
			var hit_direction := hit_position - origin
			if not hit_direction.is_zero_approx():
				candidates.append(hit_direction.normalized())

	return candidates

static func _find_collision_root(context: Node) -> CollisionObject2D:
	var current := context
	while current:
		if current is CharacterBody2D:
			return current as CollisionObject2D
		current = current.get_parent()
	return null

static func _collect_collision_rids(node: Node, exclusions: Array[RID]) -> void:
	if node is CollisionObject2D:
		exclusions.append((node as CollisionObject2D).get_rid())
	for child in node.get_children():
		_collect_collision_rids(child, exclusions)

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
