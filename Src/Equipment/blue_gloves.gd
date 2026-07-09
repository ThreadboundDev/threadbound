class_name BlueGloves
extends BaseGloves

@export_group("Blue Pendulum Grapple")
@export var maximum_grapple_range := 940.0
@export var swing_acceleration := 780.0
@export var swing_momentum_gain := 125.0
@export var momentum_decay := 42.0
@export var maximum_swing_speed := 1280.0
@export var blue_rope_climb_speed := 145.0
@export var jump_off_force := 900.0
@export var jump_off_momentum_bonus := 0.48
@export var apex_timing_window := 0.18

@export_group("Blue Rhythm Tuning")
@export var grapple_fire_speed := 1650.0
@export var rope_pull_strength := 58.0
@export var apex_speed_threshold := 90.0
@export var apex_side_threshold := 0.42
@export var mistimed_momentum_loss := 24.0
@export var stored_swing_momentum_max := 420.0
@export var swing_momentum_report_interval := 0.28

var stored_swing_momentum := 0.0
var _apex_timer := 0.0
var _apex_reward_cooldown := 0.0
var _momentum_report_cooldown := 0.0
var _previous_tangent_speed := 0.0
var _last_horizontal_input_sign := 0

func _ready() -> void:
	super()
	_apply_blue_tuning()

func on_equipped() -> void:
	super()
	_apply_blue_tuning()
	stored_swing_momentum = 0.0
	_apex_timer = 0.0
	_apex_reward_cooldown = 0.0
	_momentum_report_cooldown = 0.0
	_previous_tangent_speed = 0.0
	_last_horizontal_input_sign = 0

func _apply_blue_tuning() -> void:
	grapple_speed = grapple_fire_speed
	grapple_max_distance = maximum_grapple_range
	active_rope_total_length = maximum_grapple_range
	rope_limit_pull_strength = rope_pull_strength
	rope_tangent_max_speed = maximum_swing_speed
	rope_tangent_damping = 1.0
	rope_jump_force = jump_off_force
	rope_climb_speed = blue_rope_climb_speed
	enforce_player_rope_limit = true

func process_passive(delta: float) -> void:
	if grapple_state != GrappleState.ATTACHED:
		stored_swing_momentum = move_toward(stored_swing_momentum, 0.0, momentum_decay * delta)

func _handle_rope_climb(delta: float) -> void:
	if grapple_state != GrappleState.ATTACHED:
		return
	if not player:
		return

	var climb_direction := 0.0
	if Input.is_action_pressed("move_up"):
		climb_direction -= 1.0
	if Input.is_action_pressed("move_down"):
		climb_direction += 1.0
	if climb_direction == 0.0:
		return

	current_rope_length += climb_direction * blue_rope_climb_speed * delta
	current_rope_length = clampf(current_rope_length, rope_min_length, maximum_grapple_range)

func jump_off_grapple() -> bool:
	if grapple_state != GrappleState.ATTACHED:
		return false
	if not player:
		return false

	var origin := get_grapple_origin_global_position()
	var from_anchor := origin - grapple_attach_position
	if from_anchor.length() <= 0.001:
		_begin_grapple_retract()
		return true

	var rope_dir := from_anchor.normalized()
	var tangent := Vector2(-rope_dir.y, rope_dir.x)
	var tangent_speed := player.velocity.dot(tangent)
	var tangent_sign := signf(tangent_speed)
	if is_zero_approx(tangent_sign):
		tangent_sign = signf(player.facing_direction) if player and "facing_direction" in player else 1.0

	var launch_speed := absf(tangent_speed) + jump_off_force + stored_swing_momentum * jump_off_momentum_bonus
	launch_speed = clampf(launch_speed, jump_off_force, maximum_swing_speed + jump_off_force * 0.55)
	var launch_direction := (tangent * tangent_sign + Vector2.UP * 0.38).normalized()
	player.velocity = player.velocity.lerp(launch_direction * launch_speed, 0.82)
	player.velocity.y = minf(player.velocity.y, -jump_off_force * 0.45)

	stored_swing_momentum *= 0.25
	_begin_grapple_retract()
	return true

func apply_grapple_velocity(delta: float) -> void:
	if not enforce_player_rope_limit:
		return
	if not player:
		return
	if grapple_state != GrappleState.ATTACHED:
		return

	_apex_timer = maxf(_apex_timer - delta, 0.0)
	_apex_reward_cooldown = maxf(_apex_reward_cooldown - delta, 0.0)
	_momentum_report_cooldown = maxf(_momentum_report_cooldown - delta, 0.0)

	var origin := get_grapple_origin_global_position()
	var from_anchor := origin - grapple_attach_position
	var distance := from_anchor.length()
	if distance <= 0.001:
		return

	var max_allowed := current_rope_length + rope_limit_slack
	var rope_dir := from_anchor.normalized()
	var tangent := Vector2(-rope_dir.y, rope_dir.x)
	var horizontal_input := Input.get_axis("move_left", "move_right")
	var input_sign := int(signf(horizontal_input))

	var tangent_speed := player.velocity.dot(tangent)
	_update_apex_window(tangent_speed, rope_dir)
	_apply_rhythm_input(input_sign, rope_dir, delta)
	_apply_swing_input(tangent, horizontal_input, delta)

	stored_swing_momentum = move_toward(stored_swing_momentum, 0.0, momentum_decay * delta)

	if distance <= max_allowed:
		_previous_tangent_speed = tangent_speed
		return

	var outward_speed := player.velocity.dot(rope_dir)
	if outward_speed > 0.0:
		player.velocity -= rope_dir * outward_speed

	tangent_speed = player.velocity.dot(tangent)
	tangent_speed = clampf(tangent_speed, -maximum_swing_speed, maximum_swing_speed)

	var inward_speed := minf(player.velocity.dot(rope_dir), 0.0)
	player.velocity = tangent * tangent_speed + rope_dir * inward_speed

	var excess := distance - max_allowed
	var pull_multiplier: float = 1.0
	if player.has_method("get_momentum_grapple_pull_multiplier"):
		pull_multiplier = player.get_momentum_grapple_pull_multiplier()
	player.velocity -= rope_dir * excess * rope_limit_pull_strength * pull_multiplier * delta

	_previous_tangent_speed = tangent_speed

func _update_apex_window(tangent_speed: float, rope_dir: Vector2) -> void:
	var crossed_zero := not is_zero_approx(_previous_tangent_speed) and signf(_previous_tangent_speed) != signf(tangent_speed)
	var is_high_side_apex := absf(tangent_speed) <= apex_speed_threshold and absf(rope_dir.x) >= apex_side_threshold
	if (crossed_zero or is_high_side_apex) and _apex_reward_cooldown <= 0.0:
		_apex_timer = apex_timing_window

func _apply_rhythm_input(input_sign: int, rope_dir: Vector2, delta: float) -> void:
	if input_sign == 0:
		return

	var changed_direction := _last_horizontal_input_sign != 0 and input_sign != _last_horizontal_input_sign
	var pumping_toward_center := signf(float(input_sign)) == -signf(rope_dir.x) and absf(rope_dir.x) >= apex_side_threshold
	if _apex_timer > 0.0 and _apex_reward_cooldown <= 0.0 and (changed_direction or pumping_toward_center):
		stored_swing_momentum = minf(stored_swing_momentum + swing_momentum_gain, stored_swing_momentum_max)
		_apex_reward_cooldown = apex_timing_window * 1.75
		_apex_timer = 0.0
		_report_blue_momentum_reward()
	elif changed_direction and _apex_timer <= 0.0:
		stored_swing_momentum = maxf(stored_swing_momentum - mistimed_momentum_loss * delta, 0.0)

	_last_horizontal_input_sign = input_sign

func _apply_swing_input(tangent: Vector2, horizontal_input: float, delta: float) -> void:
	if absf(horizontal_input) < 0.05:
		return

	var input_alignment := Vector2(horizontal_input, 0.0).dot(tangent)
	var momentum_multiplier := 1.0 + stored_swing_momentum / maxf(stored_swing_momentum_max, 1.0)
	player.velocity += tangent * input_alignment * swing_acceleration * momentum_multiplier * delta

func _report_blue_momentum_reward() -> void:
	if _momentum_report_cooldown > 0.0:
		return
	if player and player.has_method("report_momentum_action"):
		var reward_scale := 1.15 + stored_swing_momentum / maxf(stored_swing_momentum_max, 1.0)
		player.report_momentum_action(&"Grapple", reward_scale)
	_momentum_report_cooldown = swing_momentum_report_interval
