class_name RedGloves
extends BaseGloves

enum RedGrappleState {
	STOWED,
	CHARGING,
	FIRING,
	SPENT,
	TENSION,
	RETRACTING
}

@export_group("Red Grapple")
@export var max_charge_time := 1.1
@export_range(0.0, 1.0, 0.01) var charge_percentage := 0.0
@export_range(0.0, 1.0, 0.05) var min_charge_move_multiplier := 0.35
@export var charge_slow_lerp_speed := 7.0
@export var charge_spin_min_speed := 4.0
@export var charge_spin_max_speed := 18.0
@export_range(0.0, 1.0, 0.01) var minimum_tow_charge := 0.22
@export_range(0.1, 1.0, 0.05) var minimum_range_multiplier := 0.65
@export var grapple_range_multiplier := 1.25
@export var tow_acceleration := 6400.0
@export var tow_max_speed := 1320.0
@export var tow_hook_min_lead_distance := 64.0
@export var tow_hook_max_lead_distance := 150.0
@export_range(0.0, 0.45, 0.05) var pull_input_blend := 0.25
@export var tension_window := 0.0
@export var attached_rope_pull_strength := 80.0
@export var attached_tangent_max_speed := 220.0
@export var attached_tangent_damping := 0.90
@export_range(0.1, 1.0, 0.05) var range_falloff_start_ratio := 0.72
@export var range_falloff_drag := 8.5
@export var range_drop_gravity_multiplier := 2.2
@export var charged_modulate := Color(1.6, 0.48, 0.36, 1.0)

var red_grapple_state: RedGrappleState = RedGrappleState.STOWED
var _charge_amount := 0.0
var _base_grapple_max_distance := 0.0
var _base_grapple_speed := 0.0
var _base_active_rope_total_length := 0.0
var _base_wrist_modulate := Color.WHITE
var _base_wrist_rotation := 0.0
var _base_hook_modulate := Color.WHITE
var _base_rope_anchor_rotation := 0.0
var _charge_spin_rotation := 0.0
var _released_charge_amount := 0.0
var _released_charge_curve := 0.0
var _tow_strength := 0.0
var _tension_timer := 0.0
var _range_spent := false
var _tow_visual_direction := Vector2.RIGHT

func _ready() -> void:
	super()
	_base_grapple_max_distance = grapple_max_distance
	_base_grapple_speed = grapple_speed
	_base_active_rope_total_length = active_rope_total_length
	if wrist_wrap_pivot:
		_base_wrist_modulate = wrist_wrap_pivot.modulate
		_base_wrist_rotation = wrist_wrap_pivot.rotation
	if active_needle_sprite:
		_base_hook_modulate = active_needle_sprite.modulate
	if rope_hang_anchor:
		_base_rope_anchor_rotation = rope_hang_anchor.rotation

func on_equipped() -> void:
	super()
	red_grapple_state = RedGrappleState.STOWED
	_charge_amount = 0.0
	charge_percentage = 0.0
	grapple_max_distance = _base_grapple_max_distance
	grapple_speed = _base_grapple_speed
	active_rope_total_length = _base_active_rope_total_length
	_released_charge_amount = 0.0
	_released_charge_curve = 0.0
	_tow_strength = 0.0
	_tension_timer = 0.0
	_range_spent = false
	_tow_visual_direction = Vector2.RIGHT
	_apply_red_raycast_settings()
	_reset_charge_visuals()

func on_unequipped() -> void:
	_reset_charge_visuals()
	super()

func is_base_grapple_restricting() -> bool:
	if red_grapple_state == RedGrappleState.FIRING:
		return _tow_strength > 0.0
	if red_grapple_state == RedGrappleState.TENSION:
		return grapple_attached
	return false

func forces_dash_animation() -> bool:
	return red_grapple_state == RedGrappleState.FIRING and _tow_strength > 0.0

func get_forced_dash_direction() -> Vector2:
	if not forces_dash_animation():
		return Vector2.ZERO
	return _tow_visual_direction

func jump_off_grapple() -> bool:
	return false

func apply_grapple_velocity(delta: float) -> void:
	_process_tow_pull(delta)
	_apply_attached_rope_limit(delta)

func thread_mechanic(delta: float) -> void:
	if action_anim_lock_timer > 0.0:
		action_anim_lock_timer -= delta

	if not InputMap.has_action(grapple_input_action):
		return

	match red_grapple_state:
		RedGrappleState.STOWED:
			if Input.is_action_just_pressed(grapple_input_action):
				_begin_charge()

		RedGrappleState.CHARGING:
			_process_charge(delta)
			if Input.is_action_just_released(grapple_input_action):
				_release_charge()

		RedGrappleState.FIRING:
			if Input.is_action_just_pressed(grapple_input_action):
				_begin_red_retract()
				return
			_process_red_fire(delta)

		RedGrappleState.SPENT:
			if Input.is_action_just_pressed(grapple_input_action):
				_begin_red_retract()
				return
			_process_red_spent(delta)

		RedGrappleState.TENSION:
			if Input.is_action_just_pressed(grapple_input_action):
				_begin_red_retract()
				return
			_process_red_tension(delta)

		RedGrappleState.RETRACTING:
			_retract_active_rope(delta)
			_update_active_grapple_visuals()
			if grapple_state == GrappleState.STOWED:
				red_grapple_state = RedGrappleState.STOWED
				grapple_max_distance = _base_grapple_max_distance
				grapple_speed = _base_grapple_speed
				active_rope_total_length = _base_active_rope_total_length

func _begin_charge() -> void:
	if not player:
		return

	red_grapple_state = RedGrappleState.CHARGING
	_charge_amount = 0.0
	charge_percentage = 0.0
	_charge_spin_rotation = 0.0
	grapple_state = GrappleState.STOWED
	_show_stowed_rope()
	_set_charge_rope_spin_enabled(true)
	_released_charge_amount = 0.0
	_released_charge_curve = 0.0
	_tow_strength = 0.0
	_tension_timer = 0.0
	_range_spent = false
	AudioManager.play_sfx(&"grapple")

func _process_charge(delta: float) -> void:
	_charge_amount = clampf(_charge_amount + delta / maxf(max_charge_time, 0.001), 0.0, 1.0)
	charge_percentage = _charge_amount

	if player:
		var charge_curve := _get_charge_curve()
		var target_multiplier := lerpf(1.0, min_charge_move_multiplier, charge_curve)
		var target_x := player.velocity.x * target_multiplier
		player.velocity.x = lerpf(player.velocity.x, target_x, 1.0 - exp(-charge_slow_lerp_speed * delta))

	var spin_speed := lerpf(charge_spin_min_speed, charge_spin_max_speed, _charge_amount)
	if rope_hang_anchor:
		_charge_spin_rotation += spin_speed * delta
		rope_hang_anchor.rotation = _base_rope_anchor_rotation + _charge_spin_rotation
	if wrist_wrap_pivot:
		wrist_wrap_pivot.modulate = _base_wrist_modulate.lerp(charged_modulate, _charge_amount)

func _release_charge() -> void:
	if not player:
		_cancel_charge()
		return

	if not player.has_method("spend_action_points") or not player.spend_action_points(1):
		_cancel_charge()
		return

	grapple_direction = AimHelperScript.get_aim_direction(
		self,
		get_grapple_origin_global_position(),
		grapple_direction
	).normalized()
	if grapple_direction.length() <= 0.001:
		grapple_direction = Vector2.RIGHT

	_released_charge_amount = _charge_amount
	_released_charge_curve = _get_charge_curve()
	_tow_strength = _get_thresholded_charge_strength(_released_charge_amount, minimum_tow_charge)
	grapple_max_distance = _base_grapple_max_distance * lerpf(minimum_range_multiplier, grapple_range_multiplier, _released_charge_curve)
	active_rope_total_length = grapple_max_distance
	grapple_speed = _base_grapple_speed * lerpf(0.75, 1.05, _released_charge_curve)
	_start_red_grapple_fire()
	if player.has_method("report_momentum_action") and _tow_strength > 0.0:
		player.report_momentum_action(&"Grapple", 1.0 + _tow_strength)

func _cancel_charge() -> void:
	red_grapple_state = RedGrappleState.STOWED
	_charge_amount = 0.0
	charge_percentage = 0.0
	_charge_spin_rotation = 0.0
	_released_charge_amount = 0.0
	_released_charge_curve = 0.0
	_tow_strength = 0.0
	_tension_timer = 0.0
	_range_spent = false
	_reset_charge_visuals()

func _start_red_grapple_fire() -> void:
	grapple_start_position = get_grapple_origin_global_position()
	grapple_tip_position = grapple_start_position
	grapple_tip_velocity = grapple_direction * grapple_speed
	_reset_active_rope_physics()

	grapple_state = GrappleState.FIRING
	red_grapple_state = RedGrappleState.FIRING
	grapple_attached = false
	_range_spent = false
	_hide_stowed_rope()
	_reset_charge_visuals()

	if active_grapple_root:
		active_grapple_root.top_level = true
		active_grapple_root.global_position = Vector2.ZERO
		active_grapple_root.global_rotation = 0.0
		active_grapple_root.global_scale = Vector2.ONE
		active_grapple_root.visible = true

	if active_needle_sprite:
		active_needle_sprite.visible = true
		active_needle_sprite.global_position = grapple_tip_position
		active_needle_sprite.modulate = charged_modulate

	_apply_red_raycast_settings()
	AudioManager.play_sfx(&"grapple")
	_play_grapple_fire_animation()
	_update_active_grapple_visuals()

func _process_red_fire(delta: float) -> void:
	var previous_tip := grapple_tip_position
	_simulate_red_active_rope(delta)
	_check_red_grapple_collision(previous_tip, grapple_tip_position)

	_update_active_grapple_visuals()
	if _range_spent and red_grapple_state == RedGrappleState.FIRING:
		_begin_red_spent()

func _check_red_grapple_collision(previous_tip: Vector2, new_tip: Vector2) -> void:
	if not grapple_raycast:
		return

	grapple_raycast.global_position = previous_tip
	grapple_raycast.target_position = new_tip - previous_tip
	grapple_raycast.force_raycast_update()

	if grapple_raycast.is_colliding():
		var collider := grapple_raycast.get_collider()
		if not _is_valid_red_anchor(collider):
			return

		_notify_grapple_collider(collider)
		grapple_attached = true
		grapple_attach_position = grapple_raycast.get_collision_point()
		grapple_tip_position = grapple_attach_position
		grapple_tip_velocity = Vector2.ZERO
		AudioManager.play_sfx(&"grapple_connect")
		_begin_red_tension(true)

func _begin_red_retract() -> void:
	AudioManager.stop_loop(&"grapple_hanging")
	grapple_state = GrappleState.RETRACTING
	red_grapple_state = RedGrappleState.RETRACTING
	grapple_attached = false
	grapple_tip_velocity = Vector2.ZERO
	_tow_strength = 0.0

func _begin_red_spent() -> void:
	grapple_state = GrappleState.FIRING
	red_grapple_state = RedGrappleState.SPENT
	grapple_attached = false
	grapple_tip_velocity = Vector2.ZERO
	_tow_strength = 0.0
	_update_active_grapple_visuals()

func _begin_red_tension(embedded: bool) -> void:
	grapple_state = GrappleState.ATTACHED
	red_grapple_state = RedGrappleState.TENSION
	grapple_attached = embedded
	grapple_tip_velocity = Vector2.ZERO
	if embedded:
		grapple_attach_position = grapple_tip_position
		current_rope_length = clampf(
			get_grapple_origin_global_position().distance_to(grapple_attach_position),
			rope_min_length,
			grapple_max_distance
		)
	_tension_timer = tension_window
	_tow_strength = 0.0
	if embedded:
		AudioManager.play_loop(&"grapple_hanging")
	_update_active_grapple_visuals()

func _process_red_spent(delta: float) -> void:
	grapple_tip_velocity = Vector2.ZERO
	_clamp_tip_to_red_rope_length()
	_simulate_active_rope_constraints(delta)
	_update_active_grapple_visuals()

func _process_red_tension(delta: float) -> void:
	if tension_window > 0.0:
		_tension_timer = maxf(_tension_timer - delta, 0.0)
	if grapple_attached:
		grapple_tip_position = grapple_attach_position
	grapple_tip_velocity = Vector2.ZERO
	_simulate_active_rope(delta, true)
	_update_active_grapple_visuals()
	if tension_window > 0.0 and _tension_timer <= 0.0:
		_begin_red_retract()

func _process_tow_pull(delta: float) -> void:
	if not player:
		return
	if red_grapple_state != RedGrappleState.FIRING:
		return
	if _tow_strength <= 0.0:
		return

	var to_hook := grapple_tip_position - player.global_position
	if to_hook.length() <= 0.001:
		return

	var hook_direction := to_hook.normalized()
	var pull_direction := hook_direction
	var input_direction := _read_pull_input_direction()
	if input_direction.length() > 0.001:
		pull_direction = hook_direction.lerp(input_direction, pull_input_blend).normalized()

	if player.is_on_floor() and pull_direction.y > -0.2:
		pull_direction.y = 0.0
		if pull_direction.length() <= 0.001:
			pull_direction = Vector2(signf(grapple_direction.x), 0.0)
		pull_direction = pull_direction.normalized()

	_tow_visual_direction = pull_direction
	var force := tow_acceleration * _tow_strength * delta
	var current_along_pull := player.velocity.dot(pull_direction)
	var speed_cap := tow_max_speed * lerpf(0.35, 1.0, _tow_strength)
	if current_along_pull < speed_cap:
		var allowed_force := maxf(speed_cap - current_along_pull, 0.0)
		player.velocity += pull_direction * minf(force, allowed_force)

func _apply_attached_rope_limit(delta: float) -> void:
	if not player:
		return
	if red_grapple_state != RedGrappleState.TENSION:
		return
	if not grapple_attached:
		return

	var origin := get_grapple_origin_global_position()
	var from_anchor := origin - grapple_attach_position
	var distance := from_anchor.length()
	if distance <= 0.001:
		return

	var max_allowed := current_rope_length + rope_limit_slack
	if distance <= max_allowed:
		return

	var rope_dir := from_anchor.normalized()
	var outward_speed := player.velocity.dot(rope_dir)
	if outward_speed > 0.0:
		player.velocity -= rope_dir * outward_speed

	var tangent := Vector2(-rope_dir.y, rope_dir.x)
	var tangent_speed := player.velocity.dot(tangent)
	tangent_speed = clampf(tangent_speed, -attached_tangent_max_speed, attached_tangent_max_speed)
	tangent_speed *= pow(attached_tangent_damping, delta * 60.0)

	var inward_speed := minf(player.velocity.dot(rope_dir), 0.0)
	player.velocity = tangent * tangent_speed + rope_dir * inward_speed

	var excess := distance - max_allowed
	player.velocity -= rope_dir * excess * attached_rope_pull_strength * delta

func _get_charge_curve() -> float:
	return smoothstep(0.0, 1.0, _charge_amount)

func _get_thresholded_charge_strength(charge: float, threshold: float) -> float:
	if charge <= threshold:
		return 0.0
	return smoothstep(0.0, 1.0, inverse_lerp(threshold, 1.0, charge))

func _read_pull_input_direction() -> Vector2:
	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input.length() > 1.0:
		input = input.normalized()
	return input

func _apply_red_raycast_settings() -> void:
	if not grapple_raycast:
		return

	grapple_raycast.collide_with_bodies = true
	grapple_raycast.collide_with_areas = false
	grapple_raycast.collision_mask = grapple_collision_mask

func _is_valid_red_anchor(collider: Object) -> bool:
	if not collider:
		return false
	if collider is CharacterBody2D:
		return false
	if collider is RigidBody2D:
		return false
	if collider is StaticBody2D:
		return true
	if collider is AnimatableBody2D:
		return true
	if collider is TileMap:
		return true
	return collider.get_class() == "TileMapLayer"

func _simulate_red_active_rope(delta: float) -> void:
	if active_rope_points.size() < 2:
		return

	var throw_direction := grapple_direction.normalized()
	if throw_direction.length() <= 0.001:
		throw_direction = Vector2.RIGHT

	var from_start := grapple_tip_position - grapple_start_position
	var forward_distance := maxf(from_start.dot(throw_direction), 0.0)
	var falloff_start := grapple_max_distance * range_falloff_start_ratio
	var falloff_t := 0.0
	if grapple_max_distance > falloff_start:
		falloff_t = clampf((forward_distance - falloff_start) / (grapple_max_distance - falloff_start), 0.0, 1.0)

	if falloff_t > 0.0:
		var forward_speed := grapple_tip_velocity.dot(throw_direction)
		if forward_speed > 0.0:
			var drag_weight := 1.0 - exp(-range_falloff_drag * falloff_t * delta)
			grapple_tip_velocity -= throw_direction * forward_speed * drag_weight

	grapple_tip_velocity += active_rope_gravity * lerpf(1.0, range_drop_gravity_multiplier, falloff_t) * delta
	grapple_tip_position += grapple_tip_velocity * delta
	_clamp_tip_to_red_tow_lead()

	from_start = grapple_tip_position - grapple_start_position
	forward_distance = from_start.dot(throw_direction)
	if forward_distance > grapple_max_distance:
		var overshoot := forward_distance - grapple_max_distance
		grapple_tip_position -= throw_direction * overshoot
		var outward_speed := grapple_tip_velocity.dot(throw_direction)
		if outward_speed > 0.0:
			grapple_tip_velocity -= throw_direction * outward_speed
		_range_spent = true

	_clamp_tip_to_red_rope_length()
	_simulate_active_rope_constraints(delta)

func _clamp_tip_to_red_tow_lead() -> void:
	if red_grapple_state != RedGrappleState.FIRING:
		return
	if _tow_strength <= 0.0:
		return

	var origin := get_grapple_origin_global_position()
	var from_origin := grapple_tip_position - origin
	var distance := from_origin.length()
	if distance <= 0.001:
		return

	var max_lead := lerpf(tow_hook_min_lead_distance, tow_hook_max_lead_distance, _tow_strength)
	if distance <= max_lead:
		return

	var lead_direction := from_origin / distance
	grapple_tip_position = origin + lead_direction * max_lead
	var outward_speed := grapple_tip_velocity.dot(lead_direction)
	if outward_speed > 0.0:
		grapple_tip_velocity -= lead_direction * outward_speed

func _clamp_tip_to_red_rope_length() -> void:
	var origin := get_grapple_origin_global_position()
	var from_origin := grapple_tip_position - origin
	var distance := from_origin.length()
	if distance <= grapple_max_distance or distance <= 0.001:
		return

	var rope_direction := from_origin / distance
	grapple_tip_position = origin + rope_direction * grapple_max_distance
	var outward_speed := grapple_tip_velocity.dot(rope_direction)
	if outward_speed > 0.0:
		grapple_tip_velocity -= rope_direction * outward_speed
	_range_spent = true

func _simulate_active_rope_constraints(delta: float) -> void:
	if active_rope_points.size() < 2:
		return

	var origin := get_grapple_origin_global_position()
	var last_index := active_rope_points.size() - 1
	var segment_length := active_rope_total_length / float(active_rope_segment_count - 1)

	active_rope_points[0] = origin
	active_rope_previous_points[0] = origin

	for i in range(1, last_index):
		var current := active_rope_points[i]
		var point_velocity := (active_rope_points[i] - active_rope_previous_points[i]) * active_rope_damping
		active_rope_previous_points[i] = current
		active_rope_points[i] += point_velocity + active_rope_gravity * delta * delta

	active_rope_points[last_index] = grapple_tip_position
	active_rope_previous_points[last_index] = grapple_tip_position

	for _iteration in range(active_rope_constraint_iterations):
		active_rope_points[0] = origin
		active_rope_points[last_index] = grapple_tip_position

		for i in range(active_rope_points.size() - 1):
			var p1 := active_rope_points[i]
			var p2 := active_rope_points[i + 1]
			var delta_vec := p2 - p1
			var distance := delta_vec.length()
			if distance == 0:
				continue

			var difference := (distance - segment_length) / distance
			var correction := delta_vec * difference

			if i == 0:
				active_rope_points[i + 1] -= correction
			elif i == last_index - 1:
				active_rope_points[i] += correction
			else:
				active_rope_points[i] += correction * 0.5
				active_rope_points[i + 1] -= correction * 0.5

func _set_charge_rope_spin_enabled(enabled: bool) -> void:
	if not rope_hang_anchor:
		return

	rope_hang_anchor.set_physics_process(not enabled)
	if enabled:
		if rope_hang_anchor.has_method("reset_rope"):
			rope_hang_anchor.reset_rope()
		rope_hang_anchor.rotation = _base_rope_anchor_rotation

func _reset_charge_visuals() -> void:
	if rope_hang_anchor:
		rope_hang_anchor.set_physics_process(true)
		rope_hang_anchor.rotation = _base_rope_anchor_rotation
		if rope_hang_anchor.has_method("reset_rope"):
			rope_hang_anchor.reset_rope()
	if wrist_wrap_pivot:
		wrist_wrap_pivot.modulate = _base_wrist_modulate
		wrist_wrap_pivot.rotation = _base_wrist_rotation
	if active_needle_sprite:
		active_needle_sprite.modulate = _base_hook_modulate
