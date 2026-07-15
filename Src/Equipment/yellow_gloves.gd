class_name YellowGloves
extends BaseGloves

@export_group("Yellow Snap Grapple")
@export var grapple_range := 500.0
@export var snap_delay := 0.08
@export var exit_offset := 12.0
@export var directional_influence_strength := 42.0
@export var collision_probe_distance := 92.0
@export var safe_placement_search_distance := 190.0
@export var safe_placement_attempts := 9

@export_group("Yellow Feel")
@export var yellow_grapple_speed := 3000.0
@export var snap_pull_speed := 700.0
@export var exit_velocity := 430.0
@export var snap_momentum_multiplier := 1.1

var _snap_pending := false
var _snap_input_bias := Vector2.ZERO
var _snap_collision_normal := Vector2.ZERO

func _ready() -> void:
	super()
	_apply_yellow_tuning()

func on_equipped() -> void:
	super()
	_apply_yellow_tuning()
	_snap_pending = false

func _apply_yellow_tuning() -> void:
	grapple_speed = yellow_grapple_speed
	grapple_max_distance = grapple_range
	active_rope_total_length = grapple_range
	enforce_player_rope_limit = false

func is_base_grapple_restricting() -> bool:
	return false

func jump_off_grapple() -> bool:
	return false

func apply_grapple_velocity(_delta: float) -> void:
	pass

func _handle_rope_climb(_delta: float) -> void:
	pass

func _check_grapple_collision(previous_tip: Vector2, new_tip: Vector2) -> void:
	if not grapple_raycast:
		return

	grapple_raycast.global_position = previous_tip
	grapple_raycast.target_position = new_tip - previous_tip
	grapple_raycast.force_raycast_update()

	if not grapple_raycast.is_colliding():
		return

	if not _can_attach_grapple():
		_handle_non_attaching_collision(
			grapple_raycast.get_collision_point(),
			grapple_raycast.get_collision_normal()
		)
		_update_active_grapple_visuals()
		return

	_notify_grapple_collider(grapple_raycast.get_collider())
	grapple_attached = true
	grapple_attachment_state = GrappleAttachmentState.SPENT
	grapple_attach_position = grapple_raycast.get_collision_point()
	_snap_collision_normal = grapple_raycast.get_collision_normal()
	grapple_tip_position = grapple_attach_position
	grapple_tip_velocity = Vector2.ZERO
	grapple_state = GrappleState.ATTACHED
	AudioManager.play_sfx(&"grapple_connect")
	_begin_snap_sequence()
	if player and player.has_method("report_momentum_action"):
		player.report_momentum_action(&"Grapple", snap_momentum_multiplier)

func _begin_snap_sequence() -> void:
	if _snap_pending:
		return
	if not player:
		return

	_snap_pending = true
	_snap_input_bias = _read_directional_bias()
	var origin := get_grapple_origin_global_position()
	var to_anchor := grapple_attach_position - origin
	if to_anchor.length() <= 0.001:
		_finish_snap_sequence()
		return

	player.velocity = to_anchor.normalized() * snap_pull_speed
	_finish_snap_after_delay()

func _finish_snap_after_delay() -> void:
	await get_tree().create_timer(maxf(snap_delay, 0.01), false).timeout
	_finish_snap_sequence()

func _finish_snap_sequence() -> void:
	if not _snap_pending:
		return
	_snap_pending = false

	if not player or not is_instance_valid(player):
		_begin_grapple_retract()
		return

	var destination := _find_safe_snap_destination()
	var exit_direction := _snap_input_bias
	if exit_direction.length() <= 0.001:
		exit_direction = (destination - player.global_position).normalized()
	if exit_direction.length() <= 0.001:
		exit_direction = Vector2.UP

	player.global_position = destination
	player.velocity = exit_direction.normalized() * exit_velocity
	_begin_grapple_retract()

func _find_safe_snap_destination() -> Vector2:
	var platform_top := _find_safe_platform_top_destination()
	if platform_top != Vector2.INF:
		return platform_top

	var same_side := _find_same_side_safe_destination()
	if same_side != Vector2.INF:
		return same_side

	return player.global_position

func _find_safe_platform_top_destination() -> Vector2:
	if _snap_collision_normal.y <= 0.35:
		return Vector2.INF

	var space_state := get_world_2d().direct_space_state
	var attempts := maxi(safe_placement_attempts, 1)
	var step := safe_placement_search_distance / float(attempts)
	var start_index := -int(floor(float(attempts - 1) * 0.5))
	var player_bottom := _get_player_bottom_offset()
	var horizontal_bias := _snap_input_bias.x * directional_influence_strength

	for i in range(attempts):
		var offset_x := horizontal_bias + float(start_index + i) * step
		var ray_start := grapple_attach_position + Vector2(offset_x, -safe_placement_search_distance)
		var ray_end := grapple_attach_position + Vector2(offset_x, collision_probe_distance)
		var hit := _raycast_world(space_state, ray_start, ray_end)
		if hit.is_empty():
			continue

		var normal := hit.get("normal", Vector2.ZERO) as Vector2
		if normal.y > -0.45:
			continue

		var point := hit.get("position", Vector2.ZERO) as Vector2
		var candidate := point - Vector2(0.0, player_bottom + exit_offset)
		candidate.x += _snap_input_bias.x * directional_influence_strength
		if _is_safe_standing_position(candidate):
			return candidate

	return Vector2.INF

func _find_same_side_safe_destination() -> Vector2:
	var normal := _snap_collision_normal
	if normal.length() <= 0.001:
		normal = (get_grapple_origin_global_position() - grapple_attach_position).normalized()
	if normal.length() <= 0.001:
		normal = Vector2.UP

	var attempts := maxi(safe_placement_attempts, 1)
	var tangent := Vector2(-normal.y, normal.x)
	var player_extent := _get_player_extent_along(normal)
	var base_candidate := _candidate_from_surface(grapple_attach_position, normal, player_extent + exit_offset)
	base_candidate += _snap_input_bias * directional_influence_strength

	for i in range(attempts):
		var pair_index := int(ceil(float(i) * 0.5))
		var side := -1.0 if i % 2 == 1 else 1.0
		var tangent_offset := tangent * side * float(pair_index) * (safe_placement_search_distance / float(attempts))
		var candidate := base_candidate + tangent_offset
		if _is_safe_standing_position(candidate):
			return candidate

	return Vector2.INF

func _candidate_from_surface(surface_point: Vector2, normal: Vector2, clearance: float) -> Vector2:
	if absf(normal.y) > absf(normal.x):
		if normal.y < 0.0:
			return surface_point - Vector2(0.0, _get_player_bottom_offset() + exit_offset)
		return surface_point + Vector2(0.0, absf(_get_player_top_offset()) + exit_offset)

	return surface_point + normal.normalized() * clearance

func _is_safe_standing_position(candidate: Vector2) -> bool:
	if _player_shape_overlaps(candidate):
		return false
	if not _has_floor_beneath(candidate):
		return false
	return true

func _player_shape_overlaps(candidate: Vector2) -> bool:
	var collision_shape := _get_player_collision_shape()
	if not collision_shape or not collision_shape.shape:
		return false

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = collision_shape.shape
	params.transform = Transform2D(collision_shape.global_rotation, candidate + _get_player_shape_offset())
	params.collision_mask = player.collision_mask
	params.exclude = [player.get_rid()]
	params.margin = 1.0

	var hits := get_world_2d().direct_space_state.intersect_shape(params, 1)
	return not hits.is_empty()

func _has_floor_beneath(candidate: Vector2) -> bool:
	var bottom := _get_player_bottom_offset()
	var from := candidate + Vector2(0.0, bottom + 2.0)
	var to := from + Vector2.DOWN * collision_probe_distance
	var hit := _raycast_world(get_world_2d().direct_space_state, from, to)
	if hit.is_empty():
		return false

	var normal := hit.get("normal", Vector2.ZERO) as Vector2
	return normal.y < -0.35

func _raycast_world(space_state: PhysicsDirectSpaceState2D, from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, player.collision_mask, [player.get_rid()])
	query.hit_from_inside = false
	return space_state.intersect_ray(query)

func _read_directional_bias() -> Vector2:
	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input.length() > 1.0:
		input = input.normalized()
	return input

func _get_player_collision_shape() -> CollisionShape2D:
	if not player:
		return null
	return player.get_node_or_null("CollisionShape2D") as CollisionShape2D

func _get_player_shape_offset() -> Vector2:
	var collision_shape := _get_player_collision_shape()
	if not collision_shape:
		return Vector2.ZERO
	return collision_shape.global_position - player.global_position

func _get_player_rect_extents() -> Vector2:
	var collision_shape := _get_player_collision_shape()
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect := collision_shape.shape as RectangleShape2D
		return rect.size * 0.5 * collision_shape.global_scale.abs()
	return Vector2(20.0, 64.0)

func _get_player_bottom_offset() -> float:
	return _get_player_shape_offset().y + _get_player_rect_extents().y

func _get_player_top_offset() -> float:
	return _get_player_shape_offset().y - _get_player_rect_extents().y

func _get_player_extent_along(direction: Vector2) -> float:
	var extents := _get_player_rect_extents()
	var dir := direction.normalized().abs()
	return extents.dot(dir)
