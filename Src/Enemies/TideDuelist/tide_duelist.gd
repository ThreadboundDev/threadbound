extends EnemyBase
## Aquatic skirmisher. Uses the existing enemy states and combat components.

@export var attack_range := 380.0
@export var dash_speed := 1050.0
@export var maximum_dash_distance := 2400.0
@export var footprint_radius := 132.0
@export var patrol_height := 100.0
@export var water_path: NodePath

var swim_goal := Vector2.ZERO
var dash_direction := Vector2.RIGHT
var attack_phase: StringName = &""
var dash_blocked := false
var _water: Node2D
var _patrol_clock := 0.0
var _patrol_sign := 1.0
var _desired_velocity := Vector2.ZERO
var _dash_elapsed := 0.0
var _dash_distance := 0.0
var _terrain_strike_id := 0
var _windup_elapsed := 0.0
var _recovery_elapsed := 0.0
@onready var fish_visual: Node2D = $Visuals/Fish

func _ready() -> void:
	add_to_group("swordfish")
	_water = get_node_or_null(water_path) as Node2D if not water_path.is_empty() else null
	if not _water:
		for volume in get_tree().get_nodes_in_group("lake_water_volumes"):
			if volume.has_method("contains_global_point") and volume.contains_global_point(global_position):
				_water = volume
				break
	super._ready()
	# Sweep the blade explicitly during movement: signal-only overlaps can miss
	# fast passes and cannot reject a player behind a wall or dry pocket.
	attack_hitbox.area_entered.disconnect(attack_hitbox._on_area_entered)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_patrol_sign = float(facing)
	state_machine.state_changed.connect(_on_state_changed)
	if not _water:
		push_warning("Tide Duelist must be placed inside polygon lake water; swimming is paused.")
	elif not _footprint_fits(global_position):
		push_warning("Tide Duelist needs roughly 100 pixels of clearance from the water edge and air pockets.")

func apply_gravity(_delta: float) -> void:
	pass

func set_horizontal_target_speed(speed: float) -> void:
	_desired_velocity = Vector2(speed, 0)

func patrol(_delta: float) -> void:
	_desired_velocity = Vector2.ZERO
	fish_visual.set_attack_tell(0.0)

func chase_target(delta: float) -> void:
	_desired_velocity = Vector2.ZERO
	if is_instance_valid(target):
		var direction := global_position.direction_to(target.global_position)
		if not direction.is_zero_approx():
			var side := 1 if direction.x >= 0.0 else -1
			update_facing(side)
			var aim := atan2(direction.y * side, absf(direction.x))
			visuals.rotation = lerp_angle(visuals.rotation, aim, 1.0 - exp(-5.0 * delta))
		fish_visual.set_attack_tell(0.35)
	else:
		fish_visual.set_attack_tell(0.0)

func move_enemy(delta: float) -> void:
	velocity = velocity.move_toward(_desired_velocity, get_acceleration() * delta)
	if velocity.length() > 5.0:
		_face_direction(velocity.normalized())
	if not _move_in_water(velocity * delta):
		_patrol_sign *= -1.0
		velocity = Vector2.ZERO

func _can_target_player(candidate: Node2D) -> bool:
	return super._can_target_player(candidate) and _point_is_water(candidate.global_position) and _clear_line(candidate.global_position)

func _refresh_target_availability() -> void:
	# Losing the target during a committed swing must not restart patrol or cancel hurt.
	if state_machine and state_machine.current_state_name in [&"Attack", &"Hurt", &"Dead"]:
		if target and not _can_target_player(target):
			_release_target()
		return
	super._refresh_target_availability()

func is_player_in_attack_range() -> bool:
	return is_instance_valid(target) and _can_target_player(target) and global_position.distance_to(target.global_position) <= attack_range

func begin_attack() -> void:
	super.begin_attack()
	fish_visual.set_recovery_shake(0.0)
	dash_direction = global_position.direction_to(target.global_position) if is_instance_valid(target) else Vector2(facing, 0)
	if dash_direction.is_zero_approx():
		dash_direction = Vector2(facing, 0)
	_face_direction(dash_direction)
	velocity = Vector2.ZERO
	dash_blocked = false
	attack_phase = &"windup"
	_windup_elapsed = 0.0
	fish_visual.set_attack_tell(0.35)
	fish_visual.play_clip(&"draw_curl", stats.attack_windup)

func activate_attack_hitbox() -> void:
	if dash_blocked or is_dead:
		return
	_terrain_strike_id += 1
	attack_phase = &"dash"
	fish_visual.set_attack_tell(0.0)
	_dash_elapsed = 0.0
	_dash_distance = 0.0
	_recovery_elapsed = 0.0
	attack_hitbox.position = dash_direction * 82.0
	attack_hitbox.rotation = dash_direction.angle()
	fish_visual.play_clip(&"dash")

func deactivate_attack_hitbox() -> void:
	super.deactivate_attack_hitbox()
	if attack_phase == &"dash":
		attack_phase = &"recover"
		_recovery_elapsed = 0.0
		fish_visual.play_clip(&"recover", stats.attack_recovery)

func end_attack() -> void:
	super.end_attack()
	attack_phase = &""
	_desired_velocity = Vector2.ZERO
	fish_visual.set_attack_tell(0.0)

func update_attack_motion(delta: float) -> void:
	if attack_phase == &"windup":
		_windup_elapsed += delta
		# Last 120 ms: fully curled, aim locked, eye flashes before any damage.
		fish_visual.set_attack_tell(1.0 if _windup_elapsed >= stats.attack_windup - 0.12 else 0.55)
		velocity = Vector2.ZERO
	elif attack_phase == &"dash":
		_dash_elapsed += delta
		# The first two source frames unsheathe the curled bill. The blade must
		# be extended before forward motion and damage become active.
		if _dash_elapsed < 0.04:
			velocity = Vector2.ZERO
			return
		if not attack_hitbox.active:
			super.activate_attack_hitbox()
			attack_hitbox.damage.knockback = dash_direction * stats.knockback_strength
		velocity = dash_direction * dash_speed
		var start := global_position
		if not _move_in_water(velocity * delta, true):
			dash_blocked = true
			deactivate_attack_hitbox()
			velocity = Vector2.ZERO
		else:
			_dash_distance += global_position.distance_to(start)
			if _dash_distance >= maximum_dash_distance:
				dash_blocked = true
				deactivate_attack_hitbox()
				velocity = Vector2.ZERO
	elif attack_phase == &"recover":
		_recovery_elapsed += delta
		velocity = Vector2.ZERO
		var progress := clampf(_recovery_elapsed / maxf(stats.attack_recovery, 0.01), 0.0, 1.0)
		fish_visual.set_recovery_shake(progress)
		if progress >= 0.55 and is_instance_valid(target):
			var reacquire_direction := global_position.direction_to(target.global_position)
			if not reacquire_direction.is_zero_approx():
				var side := 1 if reacquire_direction.x >= 0.0 else -1
				update_facing(side)
				var desired_rotation := atan2(reacquire_direction.y * side, absf(reacquire_direction.x))
				visuals.rotation = lerp_angle(
					visuals.rotation,
					desired_rotation,
					1.0 - exp(-10.0 * delta)
				)
			fish_visual.set_attack_tell(lerpf(0.0, 0.35, inverse_lerp(0.55, 1.0, progress)))
	else:
		velocity = Vector2.ZERO

func is_attack_active_complete() -> bool:
	return attack_phase == &"recover"

func is_attack_sequence_complete() -> bool:
	return attack_phase == &"recover" and _recovery_elapsed >= stats.attack_recovery

func begin_polished_hurt_response() -> void:
	_desired_velocity = Vector2.ZERO
	fish_visual.set_recovery_shake(0.0)
	fish_visual.set_attack_tell(0.0)
	fish_visual.play_clip(&"hurt", maxf(stats.hurt_time, 0.12))

func consume_pending_hurt_duration() -> float:
	return maxf(stats.hurt_time, super.consume_pending_hurt_duration())

func update_polished_hurt_motion(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, stats.hurt_knockback_deceleration * delta)
	if not _move_in_water(velocity * delta):
		velocity = Vector2.ZERO

func _try_contact_hurtbox(_area: Area2D) -> bool:
	# Only the committed blade dash deals damage, never passive swimming contact.
	return false

func _on_state_changed(state: StringName) -> void:
	if state != &"Attack":
		fish_visual.set_recovery_shake(0.0)
	if state in [&"Patrol", &"Idle", &"Chase"]:
		fish_visual.play_clip(&"still")
		fish_visual.set_attack_tell(0.35 if state == &"Chase" else 0.0)
	elif state in [&"Hurt", &"Dead"]:
		fish_visual.set_attack_tell(0.0)

func _face_direction(direction: Vector2) -> void:
	var side := 1 if direction.x >= 0.0 else -1
	update_facing(side)
	visuals.rotation = atan2(direction.y * side, absf(direction.x))

func _point_is_water(point: Vector2) -> bool:
	if not is_instance_valid(_water) or not _water.contains_global_point(point):
		return false
	for pocket in get_tree().get_nodes_in_group("lake_air_pockets"):
		if pocket.contains_global_point(point):
			return false
	return true

func _clear_line(destination: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, destination, collision_mask, [get_rid()])
	# Player bodies are on the terrain layer too; ignore every player on this ray.
	var exclusions: Array[RID] = [get_rid()]
	for player in get_tree().get_nodes_in_group("player"):
		if player is CollisionObject2D:
			exclusions.append(player.get_rid())
	query.exclude = exclusions
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		return false
	# Sample tightly enough that narrow dry seams cannot be skipped between two
	# otherwise-valid water points.
	var steps := maxi(1, ceili(global_position.distance_to(destination) / 3.0))
	for step in range(steps + 1):
		if not _point_is_water(global_position.lerp(destination, float(step) / steps)):
			return false
	return true

func _footprint_fits(center: Vector2) -> bool:
	# Conservative envelope includes the bill and curled tail. Check polygon edges
	# too: corner-only tests miss narrow air pockets and concave shoreline notches.
	var footprint := PackedVector2Array()
	for offset in [
		Vector2(-footprint_radius,-footprint_radius),
		Vector2(footprint_radius,-footprint_radius),
		Vector2(footprint_radius,footprint_radius),
		Vector2(-footprint_radius,footprint_radius),
	]:
		var point: Vector2 = center + offset
		if not _point_is_water(point):
			return false
		footprint.append(point)
	if not _point_is_water(center):
		return false
	var boundaries: Array[Node] = get_tree().get_nodes_in_group("lake_air_pockets")
	boundaries.append(_water)
	for boundary in boundaries:
		var polygon: PackedVector2Array = boundary.points
		for index in range(polygon.size()):
			var a: Vector2 = boundary.to_global(polygon[index])
			var b: Vector2 = boundary.to_global(polygon[(index + 1) % polygon.size()])
			if boundary != _water and Geometry2D.is_point_in_polygon(a, footprint):
				return false
			for edge in range(4):
				if Geometry2D.segment_intersects_segment(a, b, footprint[edge], footprint[(edge+1)%4]) != null:
					return false
	return true

func can_fracture_terrain() -> bool:
	return not is_dead and attack_phase == &"dash" and attack_hitbox.active

func get_terrain_strike_id() -> int:
	return _terrain_strike_id

func _move_in_water(motion: Vector2, damaging := false) -> bool:
	if not is_instance_valid(_water):
		return false
	var steps := maxi(1, ceili(motion.length() / 6.0))
	var step := motion / steps
	for index in range(steps):
		if not _footprint_fits(global_position + step):
			return false
		# Probe before moving so a fracture releases collision before the dash advances.
		var obstacle := move_and_collide(step, true)
		if obstacle:
			var wall := obstacle.get_collider() as Node
			if not damaging or not is_instance_valid(wall) or not wall.has_method("fracture_from_swordfish"):
				return false
			if not wall.call("fracture_from_swordfish", self):
				return false
		var collision := move_and_collide(step)
		if collision:
			return false
		if damaging and attack_hitbox.active:
			_check_dash_hits()
	return true

func _check_dash_hits() -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = ($AttackHitbox/CollisionShape2D as CollisionShape2D).shape
	query.transform = attack_hitbox.global_transform
	query.collision_mask = attack_hitbox.collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result in get_world_2d().direct_space_state.intersect_shape(query):
		var box := result.collider as HurtboxComponent
		if box and box.hurtbox_owner is Node2D and _clear_line(box.hurtbox_owner.global_position):
			attack_hitbox._on_area_entered(box)

func reset_for_save_point() -> void:
	super.reset_for_save_point()
	visuals.rotation = 0.0
	fish_visual.set_recovery_shake(0.0)
	fish_visual.reset_living_motion()
	dash_blocked = false
	_patrol_clock = 0.0
	_patrol_sign = float(facing)
