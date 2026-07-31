class_name YellowGloves
extends BaseGloves

const DASH_GHOST_TEXTURE := preload("res://Assets/Threadborne/Dash/dash_frame_normalized.png")

@export_group("Yellow Snap Grapple")
@export var grapple_range := 500.0
@export var snap_delay := 0.22
@export var exit_offset := 12.0
@export var directional_influence_strength := 42.0
@export var collision_probe_distance := 92.0
@export var safe_placement_search_distance := 190.0
@export var safe_placement_attempts := 9
@export_range(10.0, 180.0, 1.0) var platform_phase_cone_degrees := 100.0
@export var platform_phase_max_thickness := 96.0
@export var snap_exit_influence_multiplier := 1.45
@export var cardinal_snap_distance := 96.0
@export var cardinal_snap_spacing := 18.0

@export_group("Yellow Feel")
@export var yellow_grapple_speed := 3000.0
@export var snap_pull_speed := 700.0
@export var exit_velocity := 430.0
@export var snap_exit_velocity_multiplier := 1.35
@export var snap_momentum_multiplier := 1.1
@export var portal_vfx_scale := 0.28
@export var portal_vfx_radius := 84.0
@export var portal_vfx_duration := 0.22
@export var snap_flash_color := Color(1.9, 1.55, 0.35, 1.0)
@export var snap_flash_duration := 0.16

var _snap_pending := false
var _snap_input_bias := Vector2.ZERO
var _snap_collision_normal := Vector2.ZERO
var _snap_platform_phase_requested := false

func _ready() -> void:
	super()
	_apply_yellow_tuning()

func on_equipped() -> void:
	super()
	_apply_yellow_tuning()
	_snap_pending = false
	_snap_platform_phase_requested = false

func _apply_yellow_tuning() -> void:
	grapple_speed = yellow_grapple_speed
	grapple_max_distance = grapple_range
	active_rope_total_length = grapple_range
	enforce_player_rope_limit = false

func is_base_grapple_restricting() -> bool:
	return has_enemy_grapple_target()

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
	for _skipped_collider in range(8):
		grapple_raycast.force_raycast_update()
		if not grapple_raycast.is_colliding():
			return

		var collider := grapple_raycast.get_collider()
		if not _is_valid_hookshot_collider(collider):
			if collider is CollisionObject2D:
				grapple_raycast.add_exception(collider as CollisionObject2D)
				continue
			return

		if not _can_attach_grapple():
			_handle_non_attaching_collision(
				grapple_raycast.get_collision_point(),
				grapple_raycast.get_collision_normal()
			)
			_update_active_grapple_visuals()
			return

		_notify_grapple_collider(collider)
		grapple_attached = true
		grapple_attachment_state = GrappleAttachmentState.SPENT
		grapple_attach_position = grapple_raycast.get_collision_point()
		_snap_collision_normal = grapple_raycast.get_collision_normal()
		grapple_collision_normal = _snap_collision_normal
		_capture_grapple_target(collider)
		grapple_tip_position = grapple_attach_position
		grapple_tip_velocity = Vector2.ZERO
		grapple_state = GrappleState.ATTACHED
		AudioManager.play_sfx(&"grapple_connect")
		if has_enemy_grapple_target():
			_snap_pending = false
			if player and player.has_method("report_momentum_action"):
				player.report_momentum_action(&"Grapple", snap_momentum_multiplier)
			return
		_begin_snap_sequence()
		if player and player.has_method("report_momentum_action"):
			player.report_momentum_action(&"Grapple", snap_momentum_multiplier)
		return

func _begin_snap_sequence() -> void:
	if _snap_pending:
		return
	if not player:
		return

	_snap_pending = true
	_snap_platform_phase_requested = false
	_snap_input_bias = Vector2.ZERO
	var origin := get_grapple_origin_global_position()
	var to_anchor := grapple_attach_position - origin
	if to_anchor.length() <= 0.001:
		_choose_snap_direction(Vector2.UP, false)
		return

	player.velocity = to_anchor.normalized() * snap_pull_speed
	_spawn_yellow_portal_vfx(grapple_attach_position, true)
	_flash_player_snap()

func process_passive(delta: float) -> void:
	if has_enemy_grapple_target():
		apply_enemy_grapple_setup_pull(delta, snap_pull_speed)
		return
	if not _snap_pending:
		return
	_hold_snap_primed(delta)
	_process_snap_choice_input()

func _on_enemy_grapple_strike_started() -> void:
	_snap_pending = false
	_snap_platform_phase_requested = false

func _release_after_enemy_grapple_strike() -> void:
	_snap_pending = false
	_snap_platform_phase_requested = false
	_begin_grapple_retract()

func _hold_snap_primed(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return

	var to_anchor := grapple_attach_position - player.global_position
	if to_anchor.length() > 0.001:
		player.velocity = player.velocity.move_toward(to_anchor.normalized() * snap_pull_speed, snap_pull_speed * delta * 8.0)

func _process_snap_choice_input() -> void:
	if Input.is_action_just_pressed("move_left"):
		_choose_snap_direction(Vector2.LEFT, false)
	elif Input.is_action_just_pressed("move_right"):
		_choose_snap_direction(Vector2.RIGHT, false)
	elif Input.is_action_just_pressed("move_up"):
		_choose_snap_direction(Vector2.UP, true)
	elif Input.is_action_just_pressed("move_down"):
		_choose_snap_direction(Vector2.DOWN, true)

func _choose_snap_direction(direction: Vector2, platform_phase_requested: bool) -> void:
	if not _snap_pending:
		return
	_snap_input_bias = direction.normalized()
	_snap_platform_phase_requested = platform_phase_requested
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

	_spawn_dash_snap_ghost(player.global_position, exit_direction, false)
	player.global_position = destination
	player.velocity = exit_direction.normalized() * exit_velocity * snap_exit_velocity_multiplier
	_spawn_yellow_portal_vfx(destination, false)
	_spawn_dash_snap_ghost(destination, exit_direction, true)
	_flash_player_snap()
	_snap_platform_phase_requested = false
	_begin_grapple_retract()

func _find_safe_snap_destination() -> Vector2:
	var phased_platform := _find_safe_platform_phase_destination()
	if phased_platform != Vector2.INF:
		return phased_platform

	var cardinal := _find_cardinal_safe_destination()
	if cardinal != Vector2.INF:
		return cardinal

	var same_side := _find_same_side_safe_destination()
	if same_side != Vector2.INF:
		return same_side

	return player.global_position

func _find_safe_platform_phase_destination() -> Vector2:
	if absf(_snap_collision_normal.y) <= 0.35:
		return Vector2.INF
	if not _wants_platform_phase():
		return Vector2.INF

	if _snap_input_bias.y < 0.0:
		return _find_safe_platform_top_destination()
	if _snap_input_bias.y > 0.0:
		return _find_safe_platform_bottom_destination()

	return Vector2.INF

func _find_safe_platform_top_destination() -> Vector2:
	if _snap_collision_normal.y <= 0.35:
		return Vector2.INF

	var space_state := get_world_2d().direct_space_state
	var attempts := maxi(safe_placement_attempts, 1)
	var step := safe_placement_search_distance / float(attempts)
	var start_index := -int(floor(float(attempts - 1) * 0.5))
	var player_bottom := _get_player_bottom_offset()
	var horizontal_bias := _snap_input_bias.x * directional_influence_strength * snap_exit_influence_multiplier

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
		var platform_thickness := grapple_attach_position.y - point.y
		if platform_thickness < 0.0 or platform_thickness > platform_phase_max_thickness:
			continue

		var candidate := point - Vector2(0.0, player_bottom + exit_offset)
		candidate.x += _snap_input_bias.x * directional_influence_strength * snap_exit_influence_multiplier
		if _is_safe_standing_position(candidate):
			return candidate

	return Vector2.INF

func _find_safe_platform_bottom_destination() -> Vector2:
	if _snap_collision_normal.y >= -0.35:
		return Vector2.INF

	var space_state := get_world_2d().direct_space_state
	var attempts := maxi(safe_placement_attempts, 1)
	var step := safe_placement_search_distance / float(attempts)
	var start_index := -int(floor(float(attempts - 1) * 0.5))
	var player_top := absf(_get_player_top_offset())
	var horizontal_bias := _snap_input_bias.x * directional_influence_strength * snap_exit_influence_multiplier

	for i in range(attempts):
		var offset_x := horizontal_bias + float(start_index + i) * step
		var ray_start := grapple_attach_position + Vector2(offset_x, safe_placement_search_distance)
		var ray_end := grapple_attach_position + Vector2(offset_x, -collision_probe_distance)
		var hit := _raycast_world(space_state, ray_start, ray_end)
		if hit.is_empty():
			continue

		var normal := hit.get("normal", Vector2.ZERO) as Vector2
		if normal.y < 0.45:
			continue

		var point := hit.get("position", Vector2.ZERO) as Vector2
		var platform_thickness := point.y - grapple_attach_position.y
		if platform_thickness < 0.0 or platform_thickness > platform_phase_max_thickness:
			continue

		var candidate := point + Vector2(0.0, player_top + exit_offset)
		candidate.x += _snap_input_bias.x * directional_influence_strength * snap_exit_influence_multiplier
		if _is_safe_snap_position(candidate):
			return candidate

	return Vector2.INF

func _find_cardinal_safe_destination() -> Vector2:
	if _snap_input_bias.length() <= 0.001:
		return Vector2.INF

	var direction := _snap_input_bias.normalized()
	var normal := _snap_collision_normal
	if normal.length() <= 0.001:
		normal = (get_grapple_origin_global_position() - grapple_attach_position).normalized()
	if normal.length() <= 0.001:
		normal = -direction

	var surface_clearance := _get_player_extent_along(normal) + exit_offset
	var base_position := grapple_attach_position + normal.normalized() * surface_clearance
	var perpendicular := Vector2(-direction.y, direction.x)
	var attempts := maxi(safe_placement_attempts, 1)
	var distance_step := cardinal_snap_spacing
	var start_distance := maxf(cardinal_snap_distance * 0.55, _get_player_extent_along(direction) + exit_offset)

	for i in range(attempts):
		var distance := start_distance + float(i) * distance_step
		var primary_candidate := base_position + direction * distance * snap_exit_influence_multiplier
		if _is_safe_snap_position(primary_candidate):
			return primary_candidate

		var side_offset := perpendicular * cardinal_snap_spacing * float(i + 1)
		var candidate_a := primary_candidate + side_offset
		if _is_safe_snap_position(candidate_a):
			return candidate_a

		var candidate_b := primary_candidate - side_offset
		if _is_safe_snap_position(candidate_b):
			return candidate_b

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
	base_candidate += _snap_input_bias * directional_influence_strength * snap_exit_influence_multiplier

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

func _is_safe_snap_position(candidate: Vector2) -> bool:
	return not _player_shape_overlaps(candidate)

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

func _read_snap_aim_direction() -> Vector2:
	var input := _read_directional_bias()
	if input.length() > 0.15:
		return input.normalized()

	if player:
		var mouse_direction := get_global_mouse_position() - player.global_position
		if mouse_direction.length() > 0.001:
			return mouse_direction.normalized()

	return Vector2.ZERO

func _wants_platform_phase() -> bool:
	if not _snap_platform_phase_requested:
		return false
	if _snap_input_bias.length() <= 0.001:
		return false

	var half_angle := deg_to_rad(platform_phase_cone_degrees * 0.5)
	var upward_dot := _snap_input_bias.normalized().dot(Vector2.UP)
	return upward_dot >= cos(half_angle)

func _spawn_yellow_portal_vfx(world_position: Vector2, entering: bool) -> void:
	var parent := get_tree().current_scene
	if not parent:
		return

	var root := Node2D.new()
	root.global_position = world_position
	root.z_index = 30
	root.scale = Vector2.ONE * (0.72 if entering else 1.12)
	root.modulate = Color(1.0, 0.84, 0.24, 0.0)
	parent.add_child(root)

	var radius := maxf(portal_vfx_radius * portal_vfx_scale, 8.0)
	for i in range(3):
		var ring := Line2D.new()
		ring.closed = true
		ring.width = 3.0 - float(i) * 0.55
		ring.default_color = Color(1.0, 0.82, 0.24, 0.88 - float(i) * 0.18)
		ring.antialiased = true
		ring.points = _make_portal_ring_points(radius + float(i) * 9.0)
		ring.rotation = float(i) * 0.38
		root.add_child(ring)

	var tween := root.create_tween()
	var end_scale := Vector2.ONE * (1.22 if entering else 0.58)
	tween.tween_property(root, "modulate:a", 0.9, portal_vfx_duration * 0.22)
	tween.parallel().tween_property(root, "scale", end_scale, portal_vfx_duration).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(root, "rotation", 0.42 if entering else -0.36, portal_vfx_duration)
	tween.tween_property(root, "modulate:a", 0.0, portal_vfx_duration * 0.55)
	tween.tween_callback(root.queue_free)

func _make_portal_ring_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 32
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		var wobble := 1.0 + sin(angle * 5.0) * 0.035
		points.append(Vector2(cos(angle) * radius * 0.62 * wobble, sin(angle) * radius * 1.0 * wobble))
	return points

func _spawn_dash_snap_ghost(world_position: Vector2, direction: Vector2, exiting: bool) -> void:
	var parent := get_tree().current_scene
	if not parent:
		return

	var ghost := Sprite2D.new()
	ghost.texture = DASH_GHOST_TEXTURE
	ghost.global_position = world_position
	ghost.z_index = 29
	ghost.scale = Vector2(0.32, 0.35)
	_apply_directional_dash_ghost_pose(ghost, direction)
	ghost.modulate = Color(1.0, 0.86, 0.22, 0.0)
	parent.add_child(ghost)

	var travel_direction := direction.normalized() if direction.length() > 0.001 else Vector2.UP
	var offset := travel_direction * (24.0 if exiting else -18.0)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.82, snap_flash_duration * 0.25)
	tween.parallel().tween_property(ghost, "global_position", world_position + offset, snap_flash_duration)
	tween.parallel().tween_property(ghost, "scale", ghost.scale * 1.08, snap_flash_duration)
	tween.tween_property(ghost, "modulate:a", 0.0, snap_flash_duration * 0.55)
	tween.tween_callback(ghost.queue_free)

func _apply_directional_dash_ghost_pose(ghost: Sprite2D, direction: Vector2) -> void:
	if direction.length() <= 0.001:
		ghost.rotation = 0.0
		return

	var dash_direction := direction.normalized()
	ghost.flip_h = dash_direction.x < -0.001
	var source_angle := dash_direction.angle()
	if ghost.flip_h:
		source_angle = wrapf(source_angle + PI, -PI, PI)
	ghost.rotation = source_angle

func _flash_player_snap() -> void:
	if not player:
		return

	var target := player.get_node_or_null("Player Animation") as CanvasItem
	if not target:
		return

	var base_color := target.modulate
	var tween := target.create_tween()
	tween.tween_property(target, "modulate", snap_flash_color, snap_flash_duration * 0.32)
	tween.tween_property(target, "modulate", base_color, snap_flash_duration * 0.68)

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
