extends EnemyBase
## Grounded hook skirmisher: readable draw, short planted step, and recovery.
var attack_phase: StringName = &""
var _sweep_elapsed := 0.0
var _walking := false
@onready var model: Node2D = $Visuals/Model

func _ready() -> void:
	super._ready()
	attack_hitbox.area_entered.disconnect(attack_hitbox._on_area_entered)
	state_machine.state_changed.connect(_on_state_changed)

func _try_contact_hurtbox(_area: Area2D) -> bool:
	return false

func _dry_at(point: Vector2) -> bool:
	for pocket in get_tree().get_nodes_in_group("lake_air_pockets"):
		if pocket.contains_global_point(point):
			return true
	for water in get_tree().get_nodes_in_group("lake_water_volumes"):
		if water.contains_global_point(point):
			return false
	return true

func _ray(from: Vector2, to: Vector2) -> Dictionary:
	var excludes: Array[RID] = [get_rid()]
	for player in get_tree().get_nodes_in_group("player"):
		if player is CollisionObject2D:
			excludes.append(player.get_rid())
	return get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, collision_mask, excludes))

func _ground_ahead(direction: float, distance := 36.0) -> bool:
	var probe := global_position + Vector2(direction * distance, 0)
	return _dry_at(probe - Vector2(0, 4)) and not _ray(probe - Vector2(0,24), probe + Vector2(0,32)).is_empty()

func _can_target_player(candidate: Node2D) -> bool:
	return super._can_target_player(candidate) and _dry_at(candidate.global_position - Vector2(0,8)) and absf(candidate.global_position.y - global_position.y) < 110.0 and _ray(global_position - Vector2(0,75), candidate.global_position - Vector2(0,65)).is_empty()

func _refresh_target_availability() -> void:
	if state_machine and state_machine.current_state_name in [&"Attack", &"Hurt", &"Dead"]:
		if target and not _can_target_player(target):
			_release_target()
		return
	super._refresh_target_availability()

func is_player_in_attack_range() -> bool:
	return is_on_floor() and is_instance_valid(target) and _can_target_player(target) and absf(target.global_position.x - global_position.x) <= 135.0

func patrol(delta: float) -> void:
	if is_on_floor() and (is_on_wall() or not _ground_ahead(facing)):
		update_facing(-facing)
	super.patrol(delta)

func chase_target(delta: float) -> void:
	super.chase_target(delta)
	if is_instance_valid(target) and absf(target.global_position.x - global_position.x) < 90.0:
		set_horizontal_target_speed(0.0)

func move_enemy(delta: float) -> void:
	velocity.x = move_toward(velocity.x, _target_speed, get_acceleration() * delta)
	_guard_edge(delta)
	move_and_slide()
	_update_walk()

func _guard_edge(delta: float) -> void:
	if is_on_floor() and absf(velocity.x) > 0.01 and not _ground_ahead(signf(velocity.x), maxf(36.0, absf(velocity.x) * delta + 24.0)):
		velocity.x = 0.0

func _update_walk() -> void:
	if state_machine.current_state_name in [&"Attack", &"Hurt", &"Dead"]:
		return
	var walking := absf(velocity.x) > 5.0 and is_on_floor()
	if walking != _walking:
		_walking = walking
		model.play_clip(&"walk" if walking else &"idle")
	if walking:
		model.animator.speed_scale = clampf(absf(velocity.x) / 65.0, 0.4, 1.8)

func begin_attack() -> void:
	super.begin_attack()
	if is_instance_valid(target):
		update_facing(1 if target.global_position.x >= global_position.x else -1)
	velocity.x = 0.0
	attack_phase = &"windup"
	model.animator.speed_scale = 1.0
	model.play_clip(&"windup", stats.attack_windup)

func activate_attack_hitbox() -> void:
	attack_phase = &"sweep"
	_sweep_elapsed = 0.0
	model.play_clip(&"sweep", stats.attack_active_time)

func update_attack_motion(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = 0.0
	if attack_phase == &"sweep":
		_sweep_elapsed += delta
		# Let the hook leave the raised draw pose before the damaging sweep.
		if _sweep_elapsed >= stats.attack_active_time * 0.35:
			if not attack_hitbox.active:
				super.activate_attack_hitbox()
			velocity.x = facing * 105.0
	_guard_edge(delta)
	move_and_slide()
	if attack_hitbox.active:
		_check_sweep_hits()

func _check_sweep_hits() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = ($AttackHitbox/CollisionShape2D as CollisionShape2D).shape
	query.transform = attack_hitbox.global_transform
	query.collision_mask = attack_hitbox.collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result in get_world_2d().direct_space_state.intersect_shape(query):
		var box := result.collider as HurtboxComponent
		if box and box.hurtbox_owner is Node2D:
			var destination: Vector2 = box.global_position
			if _ray(global_position - Vector2(0,75), destination).is_empty():
				attack_hitbox._on_area_entered(box)

func deactivate_attack_hitbox() -> void:
	super.deactivate_attack_hitbox()
	if attack_phase == &"sweep":
		attack_phase = &"recover"
		model.play_clip(&"recover", stats.attack_recovery)

func end_attack() -> void:
	super.end_attack()
	attack_phase = &""
	set_horizontal_target_speed(0.0)

func consume_pending_hurt_duration() -> float:
	return maxf(stats.hurt_time, super.consume_pending_hurt_duration())

func begin_polished_hurt_response() -> void:
	super.begin_polished_hurt_response()
	model.animator.speed_scale = 1.0
	model.play_clip(&"hurt", stats.hurt_time)

func update_polished_hurt_motion(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, stats.hurt_knockback_deceleration * delta)
	_guard_edge(delta)
	move_and_slide()

func _on_state_changed(state: StringName) -> void:
	if state in [&"Idle", &"Patrol", &"Chase"]:
		_walking = false
		model.animator.speed_scale = 1.0
		model.play_clip(&"idle")
