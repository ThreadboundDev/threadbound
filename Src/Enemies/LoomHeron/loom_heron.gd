extends "res://Src/Enemies/WovenGuardians/woven_guardian.gd"
## Ranged cloth-wing sentinel. Telegraphs a locked needle, then descends to recover.
const NEEDLE = preload("res://Src/Enemies/LoomHeron/heron_needle.gd")
@export var needle_speed := 520.0
var _desired_velocity := Vector2.ZERO
var _locked_aim := Vector2.ZERO
var _aim_locked := false
var _shot_released := false
var _patrol_time := 0.0
var _flight_clip: StringName = &""
var _recover_goal := Vector2.ZERO

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	super._ready()

func apply_gravity(_delta: float) -> void:
	pass

func patrol(delta: float) -> void:
	_patrol_time += delta
	var goal := home_position + Vector2(sin(_patrol_time * .45) * patrol_distance, sin(_patrol_time * .9) * 22)
	_desired_velocity = (goal - global_position).limit_length(get_move_speed())

func chase_target(_delta: float) -> void:
	if not target:
		return
	var side := signf(global_position.x - target.global_position.x)
	if side == 0:
		side = -facing
	var goal := target_feet(target) + Vector2(side * 290, -220)
	if goal.distance_to(home_position) > home_leash * .85:
		goal = home_position
	_desired_velocity = (goal - global_position).limit_length(get_chase_speed())
	if absf(target.global_position.x - global_position.x) > 12:
		update_facing(int(signf(target.global_position.x - global_position.x)))

func _safe_move(delta: float) -> void:
	var next := global_position + velocity * delta
	if not dry_at(next - Vector2(0, 70)) or not dry_at(next - Vector2(0, 12)):
		velocity = Vector2.ZERO
		return
	move_and_slide()

func move_enemy(delta: float) -> void:
	if not target and state_machine.current_state_name == &"Idle":
		_desired_velocity = (home_position - global_position).limit_length(get_move_speed())
	velocity = velocity.move_toward(_desired_velocity, stats.acceleration * delta)
	_safe_move(delta)
	var clip: StringName = &"flight" if velocity.length() > 15 else &"idle"
	if clip != _flight_clip:
		_flight_clip = clip
		model.play_clip(clip)

func is_player_in_attack_range() -> bool:
	if not target or not _can_target_player(target):
		return false
	var difference := target_feet(target) - global_position
	return absf(difference.x) > 130 and absf(difference.x) < 560 and difference.y > 65 and difference.y < 360

func begin_attack() -> void:
	super.begin_attack()
	attack_phase = &"windup"
	phase_time = 0
	_aim_locked = false
	_shot_released = false
	velocity = Vector2.ZERO
	_desired_velocity = Vector2.ZERO
	if target:
		update_facing(1 if target.global_position.x > global_position.x else -1)
	model.play_clip(&"needle_aim", stats.attack_windup)

func _lock_aim() -> void:
	_aim_locked = true
	_locked_aim = target_center(target) if is_instance_valid(target) else global_position + Vector2(facing * 300, 80)
	_recover_goal = Vector2(global_position.x, target_feet(target).y - 60) if is_instance_valid(target) else global_position + Vector2(0, 140)
	_recover_goal.y = minf(_recover_goal.y, global_position.y + 210)
	update_facing(1 if _locked_aim.x > global_position.x else -1)

func activate_attack_hitbox() -> void:
	# The shared Attack state requests activation; this attack emits a projectile
	# on the firing clip's release frame and never enables the contact hitbox.
	if not _aim_locked:
		_lock_aim()
	attack_phase = &"fire"
	phase_time = 0
	model.set_tell(0)
	model.play_clip(&"needle_fire", .35)

func _needle_origin() -> Vector2:
	var point: Variant = model.bone_world_position(&"beak_tip")
	return point if point is Vector2 else global_position + Vector2(facing * 78, -140)

func _release_needle() -> void:
	_shot_released = true
	var origin := _needle_origin()
	if not dry_at(origin) or not terrain_ray(global_position - Vector2(0, 85), origin).is_empty():
		return
	var needle := NEEDLE.new()
	needle.source = self
	needle.damage_amount = stats.attack_damage
	needle.position = get_parent().to_local(origin)
	needle.velocity = (_locked_aim - origin).normalized() * needle_speed
	needle.rotation = needle.velocity.angle()
	get_parent().add_child(needle)

func update_attack_motion(delta: float) -> void:
	phase_time += delta
	match attack_phase:
		&"windup":
			model.set_tell(clampf(phase_time / stats.attack_windup, 0, 1))
			if phase_time >= stats.attack_windup - .18 and not _aim_locked:
				_lock_aim()
		&"fire":
			if phase_time >= .10 and not _shot_released:
				_release_needle()
			if phase_time >= .35:
				attack_phase = &"recover"
				phase_time = 0
				model.play_clip(&"low_recover", stats.attack_recovery)
		&"recover":
			# Descend without rushing horizontally at the player. Terrain and the
			# dry-air boundary still constrain this vulnerable recovery movement.
			var destination := _recover_goal
			var floor_hit := terrain_ray(global_position - Vector2(0, 50), global_position + Vector2(0, 48))
			if not floor_hit.is_empty():
				destination = global_position
			var travel := destination - global_position
			velocity = travel.normalized() * minf(230, travel.length() / maxf(delta, .0001))
			_safe_move(delta)

func is_attack_active_complete() -> bool:
	return attack_phase == &"recover"

func is_attack_sequence_complete() -> bool:
	return attack_phase == &"recover" and phase_time >= stats.attack_recovery

func end_attack() -> void:
	super.end_attack()
	_flight_clip = &""
	_desired_velocity = Vector2.ZERO

func begin_polished_hurt_response() -> void:
	super.begin_polished_hurt_response()
	_desired_velocity = Vector2.ZERO

func update_polished_hurt_motion(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, stats.hurt_knockback_deceleration * delta)
	_safe_move(delta)

func _clear_needles() -> void:
	for needle in get_tree().get_nodes_in_group("woven_pins"):
		if needle.source == self:
			needle.queue_free()

func _exit_tree() -> void:
	_clear_needles()

func reset_for_save_point() -> void:
	_clear_needles()
	_desired_velocity = Vector2.ZERO
	_patrol_time = 0
	_flight_clip = &""
	super.reset_for_save_point()

func _guardian_state_changed(state: StringName) -> void:
	super._guardian_state_changed(state)
	_flight_clip = &""
