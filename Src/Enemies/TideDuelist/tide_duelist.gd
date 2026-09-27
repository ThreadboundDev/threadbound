extends EnemyBase
## Aquatic skirmisher. Uses the existing enemy states and combat components.

@export var attack_range := 380.0
@export var dash_speed := 2200.0
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
var _windup_elapsed := 0.0
@onready var fish_visual: Node2D = $Visuals/Fish

func _ready() -> void:
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

func chase_target(_delta: float) -> void:
	_desired_velocity = Vector2.ZERO
	if is_instance_valid(target):
		_face_direction(global_position.direction_to(target.global_position))
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
	attack_phase = &"dash"
	fish_visual.set_attack_tell(0.0)
	_dash_elapsed = 0.0
	attack_hitbox.position = dash_direction * 62.0
	attack_hitbox.rotation = dash_direction.angle()
	fish_visual.play_clip(&"dash", stats.attack_active_time)

func deactivate_attack_hitbox() -> void:
	super.deactivate_attack_hitbox()
	if attack_phase == &"dash":
		attack_phase = &"recover"
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
		if _dash_elapsed < stats.attack_active_time * 0.2:
			velocity = Vector2.ZERO
			return
		if not attack_hitbox.active:
			super.activate_attack_hitbox()
			attack_hitbox.damage.knockback = dash_direction * stats.knockback_strength
		velocity = dash_direction * dash_speed
		if not _move_in_water(velocity * delta, true):
			dash_blocked = true
			deactivate_attack_hitbox()
			velocity = Vector2.ZERO
	elif attack_phase == &"recover":
		velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

func begin_polished_hurt_response() -> void:
	_desired_velocity = Vector2.ZERO
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
	var steps := maxi(1, ceili(global_position.distance_to(destination) / 8.0))
	for step in range(steps + 1):
		if not _point_is_water(global_position.lerp(destination, float(step) / steps)):
			return false
	return true

func _footprint_fits(center: Vector2) -> bool:
	# Conservative envelope includes the bill and curled tail. Check polygon edges
	# too: corner-only tests miss narrow air pockets and concave shoreline notches.
	var footprint := PackedVector2Array()
	for offset in [Vector2(-100,-100), Vector2(100,-100), Vector2(100,100), Vector2(-100,100)]:
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

func _move_in_water(motion: Vector2, damaging := false) -> bool:
	if not is_instance_valid(_water):
		return false
	var steps := maxi(1, ceili(motion.length() / 6.0))
	var step := motion / steps
	for index in range(steps):
		if not _footprint_fits(global_position + step):
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
	dash_blocked = false
	_patrol_clock = 0.0
	_patrol_sign = float(facing)
