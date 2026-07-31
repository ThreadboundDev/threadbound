class_name BlueGloves
extends BaseGloves

@export_group("Blue Grapple Range")
@export var maximum_grapple_range := 920.0
@export var grapple_fire_speed := 1750.0
@export var blue_rope_climb_speed := 185.0
@export var blue_rope_descend_speed := 230.0

@export_group("Blue Swing Physics")
@export var swing_acceleration := 640.0
@export var short_rope_speed_cap := 820.0
@export var long_rope_speed_cap := 1580.0
@export var rope_pull_strength := 64.0
@export var swing_air_damping := 0.992
@export var swing_no_input_damping := 0.997
@export var rope_resize_damping := 0.985
@export var momentum_decay := 36.0

@export_group("Blue Rhythm Pumping")
@export var blue_apex_input_window := 0.22
@export var blue_input_buffer_time := 0.16
@export var blue_apex_min_speed := 35.0
@export var blue_apex_speed_threshold := 115.0
@export var blue_apex_angle_threshold := 0.34
@export var blue_pump_strength := 245.0
@export var blue_pump_diminishing_return := 1.25
@export var blue_short_rope_pump_bonus := 1.18
@export var blue_long_rope_pump_bonus := 0.88
@export var blue_incorrect_input_damping := 0.94
@export var blue_apex_reward_cooldown := 0.20
@export var stored_swing_momentum_max := 520.0
@export var swing_momentum_report_interval := 0.28

@export_group("Blue Release")
@export var blue_release_velocity_multiplier := 1.08
@export var blue_release_max_speed := 1840.0
@export var blue_release_jump_additive_force := 620.0
@export var blue_release_momentum_bonus := 0.35
@export var blue_release_jump_buffer := 0.12

@export_group("Blue Wall Rappel")
@export var blue_wall_run_enabled := true
@export var blue_wall_run_speed := 360.0
@export var blue_wall_run_anchor_height := 80.0
@export var blue_wall_run_tension_slack := 28.0
@export var blue_wall_run_horizontal_hold := 90.0

@export_group("Blue Debug")
@export var blue_debug_enabled := false
@export var blue_debug_print_interval := 0.35

var stored_swing_momentum := 0.0
var blue_debug_snapshot: Dictionary = {}

var _apex_timer := 0.0
var _apex_reward_cooldown := 0.0
var _momentum_report_cooldown := 0.0
var _debug_print_cooldown := 0.0
var _previous_tangent_speed := 0.0
var _previous_tangent_sign := 0
var _last_horizontal_input_sign := 0
var _buffered_horizontal_input_sign := 0
var _input_buffer_timer := 0.0
var _expected_pump_input_sign := 0
var _last_pump_succeeded := false
var _last_effective_pump := 0.0
var _last_release_velocity := Vector2.ZERO
var _release_jump_buffer_timer := 0.0

func _ready() -> void:
	super()
	_apply_blue_tuning()

func on_equipped() -> void:
	super()
	_apply_blue_tuning()
	_reset_blue_state()

func _reset_blue_state() -> void:
	stored_swing_momentum = 0.0
	_apex_timer = 0.0
	_apex_reward_cooldown = 0.0
	_momentum_report_cooldown = 0.0
	_debug_print_cooldown = 0.0
	_previous_tangent_speed = 0.0
	_previous_tangent_sign = 0
	_last_horizontal_input_sign = 0
	_buffered_horizontal_input_sign = 0
	_input_buffer_timer = 0.0
	_expected_pump_input_sign = 0
	_last_pump_succeeded = false
	_last_effective_pump = 0.0
	_last_release_velocity = Vector2.ZERO
	_release_jump_buffer_timer = 0.0
	blue_debug_snapshot.clear()

func _apply_blue_tuning() -> void:
	grapple_speed = grapple_fire_speed
	grapple_max_distance = maximum_grapple_range
	active_rope_total_length = maximum_grapple_range
	rope_limit_pull_strength = rope_pull_strength
	rope_tangent_max_speed = long_rope_speed_cap
	rope_tangent_damping = 1.0
	rope_jump_force = blue_release_jump_additive_force
	rope_climb_speed = blue_rope_climb_speed
	enforce_player_rope_limit = true

func process_passive(delta: float) -> void:
	_release_jump_buffer_timer = maxf(_release_jump_buffer_timer - delta, 0.0)
	if _release_jump_buffer_timer > 0.0 and Input.is_action_just_pressed("Jump"):
		_apply_buffered_release_jump()

	if grapple_state != GrappleState.ATTACHED:
		stored_swing_momentum = move_toward(stored_swing_momentum, 0.0, momentum_decay * delta)

func _begin_grapple_retract() -> void:
	if grapple_state == GrappleState.ATTACHED:
		_store_release_velocity_prediction()
		_release_jump_buffer_timer = blue_release_jump_buffer
	super()

func _release_after_enemy_grapple_strike() -> void:
	# Combat-forced releases must not award the manual swing-release buffer;
	# it could otherwise overwrite strike recoil, hurt knockback, smash root,
	# or dash movement on the next Jump input.
	_release_jump_buffer_timer = 0.0
	_last_release_velocity = Vector2.ZERO
	super._begin_grapple_retract()

func _handle_rope_climb(delta: float) -> void:
	if grapple_state != GrappleState.ATTACHED:
		return
	if not player:
		return

	var origin := get_grapple_origin_global_position()
	var from_anchor := origin - grapple_attach_position
	if from_anchor.length() > 0.001 and _is_blue_wall_run_candidate(from_anchor.normalized()):
		return

	var climb_direction := 0.0
	if Input.is_action_pressed("move_up"):
		climb_direction -= 1.0
	if Input.is_action_pressed("move_down"):
		climb_direction += 1.0
	if climb_direction == 0.0:
		return

	var old_length := current_rope_length
	var rope_speed := blue_rope_climb_speed if climb_direction < 0.0 else blue_rope_descend_speed
	current_rope_length += climb_direction * rope_speed * delta
	current_rope_length = clampf(current_rope_length, rope_min_length, maximum_grapple_range)

	if not is_equal_approx(old_length, current_rope_length):
		_apply_rope_resize_energy_guard()

func jump_off_grapple() -> bool:
	if grapple_state != GrappleState.ATTACHED:
		return false
	if not player:
		return false

	var release_velocity := _get_release_velocity_prediction()
	if release_velocity.length() <= 0.001:
		release_velocity = Vector2(_get_player_facing_sign(), -0.4).normalized() * blue_release_jump_additive_force

	player.velocity = release_velocity
	stored_swing_momentum *= 0.18
	_last_release_velocity = release_velocity
	_begin_grapple_retract()
	return true

func apply_grapple_velocity(delta: float) -> void:
	if not enforce_player_rope_limit:
		return
	if not player:
		return
	if grapple_state != GrappleState.ATTACHED:
		return

	_tick_blue_timers(delta)

	var origin := get_grapple_origin_global_position()
	var from_anchor := origin - grapple_attach_position
	var distance := from_anchor.length()
	if distance <= 0.001:
		return

	var rope_dir := from_anchor.normalized()
	var tangent := Vector2(-rope_dir.y, rope_dir.x)
	var max_allowed := current_rope_length + rope_limit_slack
	var is_taut := distance >= current_rope_length - rope_limit_slack * 2.0
	var horizontal_input := Input.get_axis("move_left", "move_right")
	var input_sign := _get_axis_sign(horizontal_input)
	var tangent_speed := player.velocity.dot(tangent)
	var effective_speed_cap := _get_effective_swing_speed_cap()

	_update_input_buffer(input_sign, delta)
	_update_apex_window(tangent_speed, rope_dir, is_taut)
	_apply_rhythm_input(tangent, tangent_speed, rope_dir, effective_speed_cap)

	if _apply_blue_wall_run(delta, rope_dir, distance, max_allowed):
		_update_blue_debug(distance, tangent_speed, effective_speed_cap, rope_dir, "WALL_RUN")
		_previous_tangent_speed = player.velocity.dot(tangent)
		_previous_tangent_sign = _get_axis_sign(_previous_tangent_speed)
		return

	if is_taut:
		_apply_swing_input(tangent, horizontal_input, effective_speed_cap, delta)

	if player.is_on_floor() and distance <= max_allowed:
		_update_blue_debug(distance, tangent_speed, effective_speed_cap, rope_dir, "GROUNDED_SLACK")
		_update_previous_tangent(player.velocity.dot(tangent))
		return

	if distance <= max_allowed:
		if absf(horizontal_input) < 0.05:
			_apply_tangent_damping(tangent, swing_no_input_damping, delta)
		_update_blue_debug(distance, tangent_speed, effective_speed_cap, rope_dir, "SLACK")
		_update_previous_tangent(player.velocity.dot(tangent))
		return

	_apply_rope_constraint(rope_dir, tangent, distance, max_allowed, effective_speed_cap, delta)
	_update_blue_debug(distance, player.velocity.dot(tangent), effective_speed_cap, rope_dir, "SWINGING")
	_update_previous_tangent(player.velocity.dot(tangent))

func _tick_blue_timers(delta: float) -> void:
	_apex_timer = maxf(_apex_timer - delta, 0.0)
	_apex_reward_cooldown = maxf(_apex_reward_cooldown - delta, 0.0)
	_momentum_report_cooldown = maxf(_momentum_report_cooldown - delta, 0.0)
	_debug_print_cooldown = maxf(_debug_print_cooldown - delta, 0.0)
	_input_buffer_timer = maxf(_input_buffer_timer - delta, 0.0)
	if _input_buffer_timer <= 0.0:
		_buffered_horizontal_input_sign = 0
	stored_swing_momentum = move_toward(stored_swing_momentum, 0.0, momentum_decay * delta)

func _update_input_buffer(input_sign: int, _delta: float) -> void:
	if input_sign != 0 and input_sign != _last_horizontal_input_sign:
		_buffered_horizontal_input_sign = input_sign
		_input_buffer_timer = blue_input_buffer_time
	_last_horizontal_input_sign = input_sign

func _update_apex_window(tangent_speed: float, rope_dir: Vector2, is_taut: bool) -> void:
	if not is_taut:
		return

	var side_sign := _get_axis_sign(rope_dir.x)
	if side_sign == 0 or absf(rope_dir.x) < blue_apex_angle_threshold:
		return

	var tangent_sign := _get_axis_sign(tangent_speed)
	var crossed_zero := _previous_tangent_sign != 0 and tangent_sign != 0 and tangent_sign != _previous_tangent_sign
	var slow_enough := absf(tangent_speed) <= blue_apex_speed_threshold
	var moving_enough := absf(_previous_tangent_speed) >= blue_apex_min_speed or absf(tangent_speed) >= blue_apex_min_speed

	if (slow_enough or crossed_zero) and moving_enough and _apex_reward_cooldown <= 0.0:
		_apex_timer = blue_apex_input_window
		_expected_pump_input_sign = -side_sign

func _apply_rhythm_input(tangent: Vector2, tangent_speed: float, rope_dir: Vector2, speed_cap: float) -> void:
	if _apex_timer <= 0.0 or _apex_reward_cooldown > 0.0:
		return
	if _expected_pump_input_sign == 0:
		return

	var active_input := _buffered_horizontal_input_sign
	if active_input == 0:
		active_input = _get_axis_sign(Input.get_axis("move_left", "move_right"))
	if active_input == 0:
		return

	if active_input == _expected_pump_input_sign:
		var effective_pump := _calculate_effective_pump(absf(tangent_speed), speed_cap)
		var tangent_direction := _get_tangent_direction_for_horizontal_input(tangent, float(_expected_pump_input_sign))
		player.velocity += tangent * tangent_direction * effective_pump
		stored_swing_momentum = minf(stored_swing_momentum + effective_pump * blue_release_momentum_bonus, stored_swing_momentum_max)
		_last_pump_succeeded = true
		_last_effective_pump = effective_pump
		_apex_reward_cooldown = blue_apex_reward_cooldown
		_apex_timer = 0.0
		_buffered_horizontal_input_sign = 0
		_report_blue_momentum_reward()
	else:
		_apply_tangent_damping(tangent, blue_incorrect_input_damping, get_physics_process_delta_time())
		_last_pump_succeeded = false
		_last_effective_pump = 0.0
		_apex_timer = 0.0

func _calculate_effective_pump(current_speed: float, speed_cap: float) -> float:
	var normalized_speed := clampf(current_speed / maxf(speed_cap, 1.0), 0.0, 1.0)
	var remaining_speed := pow(1.0 - normalized_speed, blue_pump_diminishing_return)
	var length_bonus := lerpf(blue_short_rope_pump_bonus, blue_long_rope_pump_bonus, _get_normalized_rope_length())
	return blue_pump_strength * remaining_speed * length_bonus

func _apply_swing_input(tangent: Vector2, horizontal_input: float, speed_cap: float, delta: float) -> void:
	if absf(horizontal_input) < 0.05:
		_apply_tangent_damping(tangent, swing_no_input_damping, delta)
		return

	var input_alignment := Vector2(horizontal_input, 0.0).dot(tangent)
	if absf(input_alignment) < 0.02:
		return

	var normalized_speed := clampf(absf(player.velocity.dot(tangent)) / maxf(speed_cap, 1.0), 0.0, 1.0)
	var control_room := 1.0 - normalized_speed * 0.45
	var momentum_multiplier := 1.0 + stored_swing_momentum / maxf(stored_swing_momentum_max, 1.0)
	player.velocity += tangent * input_alignment * swing_acceleration * control_room * momentum_multiplier * delta

func _apply_rope_constraint(
	rope_dir: Vector2,
	tangent: Vector2,
	distance: float,
	max_allowed: float,
	speed_cap: float,
	delta: float
) -> void:
	var outward_speed := player.velocity.dot(rope_dir)
	if outward_speed > 0.0:
		player.velocity -= rope_dir * outward_speed

	var tangent_speed := clampf(player.velocity.dot(tangent), -speed_cap, speed_cap)
	tangent_speed *= pow(swing_air_damping, delta * 60.0)
	var inward_speed := minf(player.velocity.dot(rope_dir), 0.0)
	player.velocity = tangent * tangent_speed + rope_dir * inward_speed

	var excess := distance - max_allowed
	var pull_multiplier := 1.0
	if player.has_method("get_momentum_grapple_pull_multiplier"):
		pull_multiplier = player.get_momentum_grapple_pull_multiplier()
	player.velocity -= rope_dir * excess * rope_limit_pull_strength * pull_multiplier * delta

func _apply_tangent_damping(tangent: Vector2, damping: float, delta: float) -> void:
	var tangent_speed := player.velocity.dot(tangent)
	if absf(tangent_speed) <= 0.001:
		return
	var damped_speed := tangent_speed * pow(damping, delta * 60.0)
	player.velocity += tangent * (damped_speed - tangent_speed)

func _apply_rope_resize_energy_guard() -> void:
	if not player:
		return
	var origin := get_grapple_origin_global_position()
	var from_anchor := origin - grapple_attach_position
	if from_anchor.length() <= 0.001:
		return
	var tangent := Vector2(-from_anchor.normalized().y, from_anchor.normalized().x)
	_apply_tangent_damping(tangent, rope_resize_damping, get_physics_process_delta_time())

func _get_release_velocity_prediction() -> Vector2:
	if not player:
		return Vector2.ZERO

	var origin := get_grapple_origin_global_position()
	var from_anchor := origin - grapple_attach_position
	if from_anchor.length() <= 0.001:
		return player.velocity

	var rope_dir := from_anchor.normalized()
	var tangent := Vector2(-rope_dir.y, rope_dir.x)
	var tangent_speed := player.velocity.dot(tangent)
	var tangent_velocity := tangent * tangent_speed
	var preserved_velocity := player.velocity.lerp(tangent_velocity, 0.35)
	var upward_boost := Vector2.UP * blue_release_jump_additive_force
	var momentum_boost := 1.0 + stored_swing_momentum / maxf(stored_swing_momentum_max, 1.0) * blue_release_momentum_bonus
	var release_velocity := (preserved_velocity * blue_release_velocity_multiplier + upward_boost) * momentum_boost

	if release_velocity.length() > blue_release_max_speed:
		release_velocity = release_velocity.normalized() * blue_release_max_speed

	return release_velocity

func _store_release_velocity_prediction() -> void:
	_last_release_velocity = _get_release_velocity_prediction()

func _apply_buffered_release_jump() -> void:
	if not player:
		return
	if _last_release_velocity.length() <= 0.001:
		return
	player.velocity = _last_release_velocity
	_last_release_velocity = Vector2.ZERO
	_release_jump_buffer_timer = 0.0

func _apply_blue_wall_run(delta: float, rope_dir: Vector2, distance: float, max_allowed: float) -> bool:
	if not _is_blue_wall_run_candidate(rope_dir):
		return false

	var vertical_input := Input.get_axis("move_up", "move_down")
	if absf(vertical_input) < 0.05:
		return false

	var target_y := vertical_input * blue_wall_run_speed
	player.velocity.y = move_toward(player.velocity.y, target_y, blue_wall_run_speed * 6.0 * delta)

	var wall_normal_x := player.get_wall_normal().x
	if not is_zero_approx(wall_normal_x):
		player.velocity.x = -signf(wall_normal_x) * blue_wall_run_horizontal_hold

	if distance > max_allowed:
		var outward_speed := player.velocity.dot(rope_dir)
		if outward_speed > 0.0:
			player.velocity -= rope_dir * outward_speed

	return true

func _is_blue_wall_run_candidate(rope_dir: Vector2) -> bool:
	if not blue_wall_run_enabled:
		return false
	if not player:
		return false
	if not player.has_method("is_on_wall_only") or not player.is_on_wall_only():
		return false
	if player.is_on_floor():
		return false

	var origin := get_grapple_origin_global_position()
	var anchor_above := origin.y - grapple_attach_position.y
	if anchor_above < blue_wall_run_anchor_height:
		return false

	var distance := origin.distance_to(grapple_attach_position)
	if distance < current_rope_length - blue_wall_run_tension_slack:
		return false

	return rope_dir.y > 0.1

func _get_effective_swing_speed_cap() -> float:
	return lerpf(short_rope_speed_cap, long_rope_speed_cap, _get_normalized_rope_length())

func _get_normalized_rope_length() -> float:
	var length_range := maxf(maximum_grapple_range - rope_min_length, 1.0)
	return clampf((current_rope_length - rope_min_length) / length_range, 0.0, 1.0)

func _get_tangent_direction_for_horizontal_input(tangent: Vector2, horizontal_input: float) -> float:
	var alignment := Vector2(horizontal_input, 0.0).dot(tangent)
	if is_zero_approx(alignment):
		return signf(horizontal_input)
	return signf(alignment)

func _update_previous_tangent(tangent_speed: float) -> void:
	_previous_tangent_speed = tangent_speed
	_previous_tangent_sign = _get_axis_sign(tangent_speed)

func _get_axis_sign(value: float) -> int:
	if value > 0.05:
		return 1
	if value < -0.05:
		return -1
	return 0

func _get_player_facing_sign() -> float:
	if player and player.has_node("Player Animation"):
		var body_anim := player.get_node("Player Animation") as AnimatedSprite2D
		if body_anim:
			return -1.0 if body_anim.flip_h else 1.0
	if player and absf(player.velocity.x) > 0.05:
		return signf(player.velocity.x)
	return 1.0

func _report_blue_momentum_reward() -> void:
	if _momentum_report_cooldown > 0.0:
		return
	if player and player.has_method("report_momentum_action"):
		var reward_scale := 1.15 + stored_swing_momentum / maxf(stored_swing_momentum_max, 1.0)
		player.report_momentum_action(&"Grapple", reward_scale)
	_momentum_report_cooldown = swing_momentum_report_interval

func _update_blue_debug(
	rope_distance: float,
	tangent_speed: float,
	speed_cap: float,
	rope_dir: Vector2,
	state_name: String
) -> void:
	if not OS.is_debug_build() or not blue_debug_enabled:
		return

	blue_debug_snapshot = {
		"state": state_name,
		"rope_length": current_rope_length,
		"normalized_rope_length": _get_normalized_rope_length(),
		"rope_distance": rope_distance,
		"tangent_speed": tangent_speed,
		"linear_speed": player.velocity.length() if player else 0.0,
		"rope_angle": rope_dir.angle(),
		"inside_apex_window": _apex_timer > 0.0,
		"expected_pump_direction": _expected_pump_input_sign,
		"last_pump_succeeded": _last_pump_succeeded,
		"last_effective_pump": _last_effective_pump,
		"swing_speed_cap": speed_cap,
		"release_prediction": _get_release_velocity_prediction().length(),
	}

	if _debug_print_cooldown > 0.0:
		return

	print("Blue Grapple Debug: ", blue_debug_snapshot)
	_debug_print_cooldown = blue_debug_print_interval
