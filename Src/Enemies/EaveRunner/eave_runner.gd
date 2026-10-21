extends "res://Src/Enemies/WovenGuardians/woven_guardian.gd"
## Dry-room guardian: brace on a real wall, telegraph, leap/slash, then land.
## Without a reachable wall it throws a pin instead of waiting indefinitely.
const PIN = preload("res://Src/Enemies/EaveRunner/woven_pin.gd")
@export var prefer_wall := true
var wall_mode: StringName = &""
var wall_side := 0
var wall_time := 0.0
var wall_cooldown := 0.0
var attack_kind: StringName = &"throw"
var _locked_target := Vector2.ZERO
var _launch_velocity := Vector2.ZERO
var _aim_locked := false
var _pin_released := false
var _slash_started := false
var _flight_time := 0.0
var _locomotion: StringName = &""

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	wall_cooldown = maxf(0, wall_cooldown - delta)

func wall_contact(side: int) -> bool:
	var first_x := INF
	for height in [28.0, 70.0, 116.0]:
		var start := global_position - Vector2(0, height)
		var hit := terrain_ray(start, start + Vector2(side * 36, 0))
		if hit.is_empty() or hit.normal.x * side > -.9:
			return false
		if first_x == INF:
			first_x = hit.position.x
		elif absf(first_x - hit.position.x) > 5:
			return false
	return true

func _ground_ahead(direction: int) -> bool:
	var probe := global_position + Vector2(direction * 35, 0)
	return dry_at(probe - Vector2(0, 8)) and not terrain_ray(probe - Vector2(0, 20), probe + Vector2(0, 28)).is_empty()

func _nearby_wall_direction() -> int:
	var nearest := 501.0
	var direction := 0
	for side in [-1, 1]:
		var lower := terrain_ray(global_position - Vector2(0, 70), global_position + Vector2(side * 500, -70))
		var upper := terrain_ray(global_position - Vector2(0, 116), global_position + Vector2(side * 500, -116))
		if lower.is_empty() or upper.is_empty() or lower.normal.x * side > -.9 or upper.normal.x * side > -.9:
			continue
		var distance: float = absf(lower.position.x - global_position.x)
		if absf(lower.position.x - upper.position.x) < 5 and distance < nearest and _ground_ahead(side):
			nearest = distance
			direction = side
	return direction

func patrol(delta: float) -> void:
	if is_on_floor() and (is_on_wall() or not _ground_ahead(facing)):
		update_facing(-facing)
	super.patrol(delta)
	if global_position.distance_to(home_position) > home_leash:
		update_facing(int(signf(home_position.x - global_position.x)))
		_target_speed = facing * get_move_speed()

func chase_target(_delta: float) -> void:
	if wall_mode != &"":
		return
	if prefer_wall and wall_cooldown <= 0:
		for side in [-1, 1]:
			if wall_contact(side):
				wall_side = side
				wall_mode = &"attach"
				wall_time = 0
				velocity = Vector2.ZERO
				_target_speed = 0
				update_facing(-side)
				model.play_clip(&"wall_attach", .35)
				return
	# Seek the nearer wall only while it is close and there is safe floor ahead.
	# Movement remains collision driven; no teleporting to an authored perch.
	if prefer_wall and wall_cooldown <= 0 and is_on_floor():
		var side := _nearby_wall_direction()
		if side != 0:
			update_facing(side)
			_target_speed = side * get_chase_speed()
			return
	super.chase_target(_delta)
	if target and absf(target.global_position.x - global_position.x) < 240:
		_target_speed = 0

func apply_gravity(delta: float) -> void:
	if wall_mode == &"":
		super.apply_gravity(delta)

func move_enemy(delta: float) -> void:
	if wall_mode != &"":
		wall_time += delta
		if not wall_contact(wall_side) or not target or wall_time > 3.0:
			_release_wall()
			return
		velocity = Vector2.ZERO
		if wall_time >= .35 and wall_time < .95:
			velocity.y = -250
			var old_y := global_position.y
			move_and_slide()
			if is_on_ceiling() or absf(old_y - global_position.y) < .01:
				wall_time = .95
		if wall_time >= .95 and wall_mode != &"perch":
			wall_mode = &"perch"
			model.play_clip(&"wall_perch")
		return
	velocity.x = move_toward(velocity.x, _target_speed, get_acceleration() * delta)
	if is_on_floor() and velocity.x != 0 and not _ground_ahead(int(signf(velocity.x))):
		velocity.x = 0
	move_and_slide()
	var clip: StringName = &"run" if absf(velocity.x) > 8 else &"idle"
	if clip != _locomotion:
		_locomotion = clip
		model.play_clip(clip)

func is_player_in_attack_range() -> bool:
	if not target or not _can_target_player(target):
		return false
	var difference := target_feet(target) - global_position
	if wall_mode == &"perch":
		return absf(difference.x) < 650 and absf(difference.y) < 420
	if wall_mode != &"" or not is_on_floor():
		return false
	if prefer_wall and wall_cooldown <= 0:
		if _nearby_wall_direction() != 0:
			return false
	return absf(difference.x) <= 480 and absf(difference.y) < 160

func begin_attack() -> void:
	super.begin_attack()
	attack_kind = &"leap" if wall_mode == &"perch" else &"throw"
	attack_phase = &"windup"
	phase_time = 0
	_aim_locked = false
	_pin_released = false
	_slash_started = false
	velocity = Vector2.ZERO
	if target:
		update_facing(1 if target.global_position.x > global_position.x else -1)
	model.play_clip(&"wall_windup" if attack_kind == &"leap" else &"throw_windup", get_attack_windup())

func get_attack_windup() -> float:
	return .6 if attack_kind == &"leap" else .55

func _lock_aim() -> void:
	_aim_locked = true
	_locked_target = target_feet(target) if is_instance_valid(target) else global_position + Vector2(facing * 280, 0)
	update_facing(1 if _locked_target.x > global_position.x else -1)
	# Aim the feet beyond the victim so the forward blade crosses their body.
	var flight := .60
	_launch_velocity = Vector2(clampf((_locked_target.x + facing * 70 - global_position.x) / flight, -720, 720), clampf((_locked_target.y - global_position.y - .5 * stats.gravity * flight * flight) / flight, -650, 240))

func activate_attack_hitbox() -> void:
	if not _aim_locked:
		_lock_aim()
	phase_time = 0
	model.set_tell(0)
	if attack_kind == &"leap":
		_release_wall()
		attack_phase = &"launch"
		_flight_time = 0
		velocity = _launch_velocity
		model.play_clip(&"wall_launch", .18)
	else:
		attack_phase = &"throw"
		model.play_clip(&"throw_release", .35)

func update_attack_motion(delta: float) -> void:
	phase_time += delta
	var previous := global_position
	match attack_phase:
		&"windup":
			model.set_tell(clampf(phase_time / get_attack_windup(), 0, 1))
			if phase_time >= get_attack_windup() - .15 and not _aim_locked:
				_lock_aim()
			if attack_kind == &"throw":
				apply_gravity(delta)
				move_and_slide()
		&"throw":
			apply_gravity(delta)
			velocity.x = 0
			move_and_slide()
			if phase_time >= .1333 and not _pin_released:
				_pin_released = true
				var origin := global_position + Vector2(facing * 38, -118)
				if terrain_ray(global_position - Vector2(0, 100), origin).is_empty():
					var pin := PIN.new()
					pin.source = self
					pin.position = origin
					pin.velocity = (_locked_target - Vector2(0, 70) - origin).normalized() * 560
					get_parent().add_child(pin)
			if phase_time >= .35:
				_start_recovery()
		&"launch", &"slash":
			_flight_time += delta
			if attack_phase == &"launch" and phase_time >= .18:
				attack_phase = &"slash"
				phase_time = 0
				model.play_clip(&"jump_slash", .65)
			if attack_phase == &"slash" and phase_time >= .14 and phase_time < .39:
				if not _slash_started:
					_slash_started = true
					super.activate_attack_hitbox()
			elif attack_hitbox.active:
				super.deactivate_attack_hitbox()
			apply_gravity(delta)
			move_and_slide()
			sweep_hits(previous)
			if (is_on_floor() and _flight_time > .22) or is_on_wall() or is_on_ceiling() or _flight_time > 1.25:
				_start_recovery()
		&"recover":
			apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0, 1100 * delta)
			move_and_slide()

func _start_recovery() -> void:
	super.deactivate_attack_hitbox()
	attack_phase = &"recover"
	phase_time = 0
	velocity.x *= .2
	model.play_clip(&"land_recover", .7)

func is_attack_active_complete() -> bool:
	return attack_phase == &"recover"

func is_attack_sequence_complete() -> bool:
	return attack_phase == &"recover" and phase_time >= .7 and is_on_floor()

func deactivate_attack_hitbox() -> void:
	super.deactivate_attack_hitbox()

func _release_wall() -> void:
	wall_mode = &""
	wall_side = 0
	wall_time = 0
	wall_cooldown = 1.8

func end_attack() -> void:
	super.end_attack()
	if wall_mode != &"":
		_release_wall()
	_locomotion = &""

func begin_polished_hurt_response() -> void:
	_release_wall()
	super.begin_polished_hurt_response()

func _clear_pins() -> void:
	for pin in get_tree().get_nodes_in_group("woven_pins"):
		if pin.source == self:
			pin.queue_free()

func _exit_tree() -> void:
	_clear_pins()

func reset_for_save_point() -> void:
	_clear_pins()
	_release_wall()
	wall_cooldown = 0
	_locomotion = &""
	super.reset_for_save_point()

func _guardian_state_changed(state: StringName) -> void:
	super._guardian_state_changed(state)
	_locomotion = &""
