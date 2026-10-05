extends EnemyBase
## Amphibious elite: tracks during charge, commits to a strike, then exposes recovery.
@export var attack_range := 225.0
@export var swim_speed := 265.0
@export var strike_speed := 760.0
@export var leap_range := 540.0
@export var target_leash := 1500.0
var in_water := false
var attack_phase: StringName = &""
var strike_direction := Vector2.RIGHT
var leap_timer := 0.0
var leap_count := 0
var _leap_cooldown := 0.0
var _phase_timer := 0.0
var _clock := 0.0
var _desired := Vector2.ZERO
var _locked := false
var combo_step := 0
var punches_started := 0
var _body_shape: RectangleShape2D
@onready var bell_visual: Node2D = $Visuals/BellstrikerModel

func _ready() -> void:
	super._ready()
	_body_shape = RectangleShape2D.new()
	$CollisionShape2D.shape = _body_shape
	$Hurtbox/CollisionShape2D.shape = _body_shape
	$AttackHitbox/CollisionShape2D.shape = $AttackHitbox/CollisionShape2D.shape.duplicate()
	attack_hitbox.area_entered.disconnect(attack_hitbox._on_area_entered)
	state_machine.state_changed.connect(_on_state_changed)
	_refresh_medium()
	bell_visual.play_clip(&"swim_idle" if in_water else &"idle")

func _physics_process(delta: float) -> void:
	leap_timer = maxf(0.0, leap_timer - delta)
	_leap_cooldown = maxf(0.0, _leap_cooldown - delta)
	_clock += delta
	_refresh_medium()
	super._physics_process(delta)
	var boxing := in_water and not attack_phase.is_empty()
	_body_shape.size = Vector2(140, 220) if boxing else Vector2(170, 110)
	bell_visual.set_water_motion(in_water, boxing, strike_direction if boxing else velocity, facing)

func _center() -> Vector2:
	return global_position + Vector2(0, -54)

func _point_water(point: Vector2) -> Node:
	for pocket in get_tree().get_nodes_in_group("lake_air_pockets"):
		if pocket.has_method("contains_global_point") and pocket.contains_global_point(point):
			return null
	for volume in get_tree().get_nodes_in_group("lake_water_volumes"):
		if volume.has_method("contains_global_point") and volume.contains_global_point(point):
			return volume
	return null

func _refresh_medium() -> void:
	var was_wet := in_water
	in_water = _point_water(_center()) != null and leap_timer <= 0.0
	motion_mode = MOTION_MODE_FLOATING if in_water else MOTION_MODE_GROUNDED
	if was_wet != in_water:
		bell_visual.splash()
		if state_machine and state_machine.current_state_name in [&"Idle", &"Patrol"]:
			bell_visual.play_clip(&"swim_idle" if in_water else &"idle")

func _refresh_target_availability() -> void:
	if target and (not _can_target_player(target) or global_position.distance_to(target.global_position) > target_leash):
		_release_target()
	if not target and not is_dead:
		for candidate in get_tree().get_nodes_in_group("player"):
			if candidate is CharacterBody2D and global_position.distance_to(candidate.global_position) < 1000.0:
				if _clear_line(candidate.global_position + Vector2(0, -35)):
					add_collision_exception_with(candidate)
					if _try_acquire_target(candidate):
						break

func _on_detection_body_exited(body: Node2D) -> void:
	if body == target and global_position.distance_to(body.global_position) > target_leash:
		_release_target()

func _clear_line(point: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(_center(), point, 1, [get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == target

func apply_gravity(delta: float) -> void:
	if not in_water:
		super.apply_gravity(delta)

func set_horizontal_target_speed(speed: float) -> void:
	_target_speed = speed
	_desired = Vector2(speed, 0)

func patrol(_delta: float) -> void:
	set_horizontal_target_speed(0.0)
	bell_visual.play_clip(&"swim_idle" if in_water else &"idle")

func chase_target(_delta: float) -> void:
	if not is_instance_valid(target):
		set_horizontal_target_speed(0.0)
		return
	var offset := target.global_position - global_position
	if absf(offset.x) > facing_dead_zone:
		update_facing(int(signf(offset.x)))
	if leap_timer > 0.0:
		return
	var target_wet := _point_water(target.global_position + Vector2(0, -35)) != null
	var can_leap := _leap_cooldown <= 0.0 and offset.length() < leap_range and absf(offset.x) > 50.0
	if can_leap and ((in_water and not target_wet and offset.y < 35.0) or (not in_water and is_on_floor() and (offset.y < -80.0 or is_on_wall() or target_wet or not _ground_ahead()))):
		_launch_leap(offset)
		return
	var burst := 1.0 if fmod(_clock, 0.58) < 0.42 else 0.35
	if in_water:
		_desired = offset.normalized() * swim_speed * burst
	else:
		_target_speed = float(facing) * get_chase_speed() * burst if absf(offset.x) > 40.0 else 0.0
	bell_visual.play_clip(&"swim" if in_water else &"walk")

func _ground_ahead() -> bool:
	var origin := global_position + Vector2(float(facing) * 105.0, -10)
	return not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(origin, origin + Vector2(0, 100), 1, [get_rid()])).is_empty()

func _launch_leap(offset: Vector2) -> void:
	var flight := clampf(absf(offset.x) / 570.0, 0.45, 0.8)
	velocity = Vector2(clampf(offset.x / flight, -680, 680), clampf((offset.y - 0.5 * stats.gravity * flight * flight) / flight, -850, -280))
	leap_timer = flight
	_leap_cooldown = 1.25
	leap_count += 1
	in_water = false
	motion_mode = MOTION_MODE_GROUNDED
	bell_visual.play_clip(&"leap", flight)
	bell_visual.splash()

func move_enemy(delta: float) -> void:
	if leap_timer <= 0.0:
		if in_water:
			velocity = velocity.move_toward(_desired, get_acceleration() * delta)
		else:
			velocity.x = move_toward(velocity.x, _target_speed, get_acceleration() * delta)
	move_and_slide()
	if leap_timer > 0.0 and is_on_floor() and velocity.y >= 0.0:
		leap_timer = 0.0
		bell_visual.splash()

func is_player_in_attack_range() -> bool:
	return is_instance_valid(target) and leap_timer <= 0.0 and _center().distance_to(target.global_position + Vector2(0, -35)) <= attack_range and _clear_line(target.global_position + Vector2(0, -35))

func begin_attack() -> void:
	super.begin_attack()
	combo_step = 0
	_begin_punch()

func get_attack_windup() -> float:
	return [0.32, 0.27, 0.62][combo_step]

func _punch_active_time() -> float:
	return [0.12, 0.14, 0.22][combo_step]

func _boxing_clip(name: String) -> StringName:
	return StringName(("water_" if in_water else "") + name)

func _begin_punch() -> void:
	attack_phase = &"charge"
	_phase_timer = 0.0
	_locked = false
	_aim_strike()
	bell_visual.play_clip(_boxing_clip("charge_%d" % (combo_step + 1)), get_attack_windup())

func _aim_strike() -> void:
	if is_instance_valid(target):
		strike_direction = _center().direction_to(target.global_position + Vector2(0, -35))
	if not in_water or strike_direction.is_zero_approx():
		strike_direction = Vector2(float(facing), 0)
	if absf(strike_direction.x) > 0.05:
		update_facing(int(signf(strike_direction.x)))
	attack_hitbox.position = Vector2(0, -54) + strike_direction * 110.0

func activate_attack_hitbox() -> void:
	# The shared Attack state triggers once; subsequent punches are owned here.
	if attack_phase != &"charge":
		return
	attack_phase = &"strike"
	_phase_timer = 0.0
	punches_started += 1
	bell_visual.set_tell(0.0)
	bell_visual.play_clip(_boxing_clip(["jab", "cross", "smash"][combo_step]), _punch_active_time())
	bell_visual.ring_bell(0.75 if combo_step == 2 else 1.15)

func update_attack_motion(delta: float) -> void:
	_phase_timer += delta
	if attack_phase == &"charge":
		velocity.x = move_toward(velocity.x, 0, 2400.0 * delta)
		if in_water:
			velocity.y = move_toward(velocity.y, 0, 2400.0 * delta)
		var windup := get_attack_windup()
		var lock_time := 0.20 if combo_step == 2 else 0.10
		if _phase_timer < windup - lock_time:
			_aim_strike()
		elif not _locked:
			_locked = true
			bell_visual.ring_bell(1.2)
		bell_visual.set_tell(_phase_timer / windup)
		if _phase_timer >= windup:
			activate_attack_hitbox()
	elif attack_phase == &"strike":
		if not attack_hitbox.active and _phase_timer >= 0.03:
			super.activate_attack_hitbox()
			attack_hitbox.damage.amount = EnemyScaling.scale_damage([16, 21, stats.attack_damage][combo_step])
			attack_hitbox.damage.knockback = strike_direction * stats.knockback_strength * (1.0 if combo_step == 2 else 0.45)
			attack_hitbox.damage.hit_pause = 0.055 if combo_step == 2 else 0.025
			($AttackHitbox/CollisionShape2D.shape as CircleShape2D).radius = [72.0, 78.0, 105.0][combo_step]
		var speed: float = strike_speed * [0.47, 0.56, 0.76][combo_step]
		velocity.x = strike_direction.x * speed
		if in_water:
			velocity.y = strike_direction.y * speed
		_sweep_strike(delta)
	elif attack_phase == &"between":
		# Small approach between punches, never tracking during a released punch.
		var approach := Vector2.ZERO
		if is_instance_valid(target) and _clear_line(target.global_position + Vector2(0, -35)):
			var offset := target.global_position + Vector2(0, -35) - _center()
			if offset.length() > 160.0:
				approach = offset.normalized() * 130.0
		velocity.x = move_toward(velocity.x, approach.x, 2400.0 * delta)
		if in_water:
			velocity.y = move_toward(velocity.y, approach.y, 2400.0 * delta)
		if _phase_timer >= 0.18:
			if is_instance_valid(target) and _center().distance_to(target.global_position + Vector2(0, -35)) < attack_range + 180.0 and _clear_line(target.global_position + Vector2(0, -35)):
				combo_step += 1
				_begin_punch()
			else:
				_begin_recovery()
	elif attack_phase == &"recover":
		velocity.x = move_toward(velocity.x, 0, 2400.0 * delta)
		if in_water:
			velocity.y = move_toward(velocity.y, 0, 2400.0 * delta)
	apply_gravity(delta)
	move_and_slide()
	if attack_phase == &"strike" and (_phase_timer >= _punch_active_time() or is_on_wall()):
		deactivate_attack_hitbox()

func _sweep_strike(delta: float) -> void:
	if not attack_hitbox.active:
		return
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = $AttackHitbox/CollisionShape2D.shape
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for sample in range(4):
		query.transform = Transform2D(0, attack_hitbox.global_position + velocity * delta * float(sample) / 3.0)
		for result in get_world_2d().direct_space_state.intersect_shape(query, 16):
			var receiver := result.collider as HurtboxComponent
			if receiver and receiver != hurtbox and _clear_line(_get_hurtbox_feedback_position(receiver)):
				attack_hitbox._on_area_entered(receiver)

func deactivate_attack_hitbox() -> void:
	super.deactivate_attack_hitbox()
	if attack_phase == &"strike":
		bell_visual.impact()
		_phase_timer = 0.0
		if combo_step < 2 and not is_on_wall():
			attack_phase = &"between"
			bell_visual.play_clip(&"box_idle" if in_water else &"idle")
		else:
			_begin_recovery()

func _begin_recovery() -> void:
	attack_phase = &"recover"
	_phase_timer = 0.0
	bell_visual.set_tell(0.0)
	bell_visual.play_clip(_boxing_clip("box_recover"), stats.attack_recovery)

func is_attack_active_complete() -> bool:
	return attack_phase == &"recover"

func is_attack_sequence_complete() -> bool:
	return attack_phase == &"recover" and _phase_timer >= stats.attack_recovery

func end_attack() -> void:
	super.end_attack()
	attack_phase = &""
	combo_step = 0
	bell_visual.set_tell(0.0)

func _try_contact_hurtbox(_area: Area2D) -> bool:
	return false

func begin_polished_hurt_response() -> void:
	super.begin_polished_hurt_response()
	bell_visual.play_clip(&"hurt")

func update_polished_hurt_motion(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, stats.hurt_knockback_deceleration * delta)
	if in_water:
		velocity.y = move_toward(velocity.y, 0, stats.hurt_knockback_deceleration * delta)
	else:
		apply_gravity(delta)
	move_and_slide()

func _on_state_changed(next: StringName) -> void:
	if next == &"Idle" or next == &"Patrol":
		bell_visual.play_clip(&"swim_idle" if in_water else &"idle")
	elif next == &"Dead":
		bell_visual.play_clip(&"dead")

func reset_for_save_point() -> void:
	leap_timer = 0.0
	_leap_cooldown = 0.0
	_desired = Vector2.ZERO
	super.reset_for_save_point()
	_refresh_medium()
