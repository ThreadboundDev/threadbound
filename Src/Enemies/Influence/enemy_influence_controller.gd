class_name EnemyInfluenceController
extends Node

enum Influence {
	NONE = 0,
	RED = 1,
	BLUE = 2,
	YELLOW = 3,
}

enum YellowPhaseState {
	STABLE,
	UNRAVELING,
	ABSENT,
	REFORMING,
}

const RED_DETECTION_MULTIPLIER := 1.3
const RED_CHASE_MULTIPLIER := 1.15
const RED_ACCELERATION_MULTIPLIER := 1.2
const RED_ATTACK_COOLDOWN_MULTIPLIER := 0.8
const RED_PATROL_WAIT_MULTIPLIER := 0.75

const BLUE_MOVE_MULTIPLIER := 1.2
const BLUE_CHASE_MULTIPLIER := 1.25
const BLUE_ACCELERATION_MULTIPLIER := 1.3
const BLUE_REPOSITION_MULTIPLIER := 1.2

const YELLOW_PHASE_INTERVAL_MIN := 2.8
const YELLOW_PHASE_INTERVAL_MAX := 5.2
const YELLOW_UNRAVEL_DURATION := 0.26
const YELLOW_ABSENT_DURATION := 0.42
const YELLOW_REFORM_DURATION := 0.24
const YELLOW_PHASE_DISTANCE_MIN := 120.0
const YELLOW_PHASE_DISTANCE_MAX := 280.0

var enemy
var influence: Influence = Influence.NONE
var vfx: EnemyInfluenceVFX

var _base_detection_radius := 0.0
var _yellow_phase_state := YellowPhaseState.STABLE
var _yellow_phase_timer := 0.0
var _yellow_phase_interval := 0.0
var _base_visuals_modulate := Color.WHITE
var _rng := RandomNumberGenerator.new()

func configure(owner_enemy, new_influence: Influence) -> void:
	enemy = owner_enemy
	_rng.randomize()
	_capture_detection_radius()
	if enemy.visuals:
		_base_visuals_modulate = enemy.visuals.modulate
	vfx = EnemyInfluenceVFX.new()
	vfx.name = "EnemyInfluenceVFX"
	enemy.add_child(vfx)
	vfx.configure(enemy, new_influence)
	set_influence(new_influence)

func set_influence(new_influence: Influence) -> void:
	if influence == Influence.YELLOW and new_influence != Influence.YELLOW:
		_cancel_yellow_phase()
	influence = new_influence
	_apply_detection_influence()
	if vfx:
		vfx.set_influence(influence)
	_reset_yellow_phase_schedule()

func physics_process(delta: float) -> void:
	if influence != Influence.YELLOW or not enemy or enemy.is_dead:
		return
	match _yellow_phase_state:
		YellowPhaseState.STABLE:
			_update_yellow_phase_schedule(delta)
		YellowPhaseState.UNRAVELING:
			_update_yellow_unravel(delta)
		YellowPhaseState.ABSENT:
			_update_yellow_absence(delta)
		YellowPhaseState.REFORMING:
			_update_yellow_reform(delta)

func is_phasing() -> bool:
	return _yellow_phase_state != YellowPhaseState.STABLE

func get_move_speed_multiplier() -> float:
	return BLUE_MOVE_MULTIPLIER if influence == Influence.BLUE else 1.0

func get_chase_speed_multiplier() -> float:
	match influence:
		Influence.RED:
			return RED_CHASE_MULTIPLIER
		Influence.BLUE:
			return BLUE_CHASE_MULTIPLIER
	return 1.0

func get_acceleration_multiplier() -> float:
	match influence:
		Influence.RED:
			return RED_ACCELERATION_MULTIPLIER
		Influence.BLUE:
			return BLUE_ACCELERATION_MULTIPLIER
	return 1.0

func get_attack_cooldown_multiplier() -> float:
	return RED_ATTACK_COOLDOWN_MULTIPLIER if influence == Influence.RED else 1.0

func get_patrol_wait_multiplier() -> float:
	return RED_PATROL_WAIT_MULTIPLIER if influence == Influence.RED else 1.0

func get_reposition_speed_multiplier() -> float:
	return BLUE_REPOSITION_MULTIPLIER if influence == Influence.BLUE else 1.0

func on_target_acquired() -> void:
	if vfx:
		vfx.trigger_aggro()
	if is_phasing():
		_cancel_yellow_phase()

func on_target_lost() -> void:
	if influence == Influence.YELLOW:
		_reset_yellow_phase_schedule()

func on_enemy_death() -> void:
	_cancel_yellow_phase(false)
	if vfx:
		vfx.set_effect_enabled(false)

func on_enemy_reset() -> void:
	_cancel_yellow_phase(false)
	_restore_enemy_visuals()
	_set_enemy_interactions_enabled(true)
	if enemy and enemy.state_machine:
		enemy.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
	if vfx:
		vfx.set_effect_enabled(true)
	_reset_yellow_phase_schedule()

func _capture_detection_radius() -> void:
	var shape_node := enemy.get_node_or_null("DetectionArea/CollisionShape2D") as CollisionShape2D
	if not shape_node or not shape_node.shape is CircleShape2D:
		return
	shape_node.shape = shape_node.shape.duplicate()
	_base_detection_radius = (shape_node.shape as CircleShape2D).radius

func _apply_detection_influence() -> void:
	if not enemy or _base_detection_radius <= 0.0:
		return
	var shape_node := enemy.get_node_or_null("DetectionArea/CollisionShape2D") as CollisionShape2D
	if not shape_node or not shape_node.shape is CircleShape2D:
		return
	var multiplier := RED_DETECTION_MULTIPLIER if influence == Influence.RED else 1.0
	(shape_node.shape as CircleShape2D).radius = _base_detection_radius * multiplier

func _update_yellow_phase_schedule(delta: float) -> void:
	if not _can_begin_yellow_phase():
		_reset_yellow_phase_schedule()
		return
	_yellow_phase_interval -= delta
	if _yellow_phase_interval <= 0.0:
		_begin_yellow_phase()

func _can_begin_yellow_phase() -> bool:
	if not enemy or enemy.target or not enemy.state_machine:
		return false
	return enemy.state_machine.current_state_name in [&"Idle", &"Patrol"]

func _begin_yellow_phase() -> void:
	_yellow_phase_state = YellowPhaseState.UNRAVELING
	_yellow_phase_timer = 0.0
	enemy.set_horizontal_target_speed(0.0)
	enemy.velocity = Vector2.ZERO
	enemy.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	if vfx:
		vfx.begin_yellow_unravel()

func _update_yellow_unravel(delta: float) -> void:
	_yellow_phase_timer += delta
	var progress := clampf(_yellow_phase_timer / YELLOW_UNRAVEL_DURATION, 0.0, 1.0)
	if enemy.visuals:
		var modulate := _base_visuals_modulate
		modulate.a = lerpf(_base_visuals_modulate.a, 0.08, progress)
		enemy.visuals.modulate = modulate
	if vfx:
		vfx.set_yellow_phase_progress(progress)
	if progress < 1.0:
		return
	_set_enemy_interactions_enabled(false)
	if enemy.visuals:
		enemy.visuals.visible = false
	enemy.global_position = _resolve_yellow_phase_destination()
	_yellow_phase_state = YellowPhaseState.ABSENT
	_yellow_phase_timer = 0.0

func _update_yellow_absence(delta: float) -> void:
	_yellow_phase_timer += delta
	if _yellow_phase_timer < YELLOW_ABSENT_DURATION:
		return
	_yellow_phase_state = YellowPhaseState.REFORMING
	_yellow_phase_timer = 0.0
	if enemy.visuals:
		enemy.visuals.visible = true
		var modulate := _base_visuals_modulate
		modulate.a = 0.05
		enemy.visuals.modulate = modulate
	if vfx:
		vfx.begin_yellow_reform()

func _update_yellow_reform(delta: float) -> void:
	_yellow_phase_timer += delta
	var progress := clampf(_yellow_phase_timer / YELLOW_REFORM_DURATION, 0.0, 1.0)
	if enemy.visuals:
		var modulate := _base_visuals_modulate
		modulate.a = lerpf(0.05, _base_visuals_modulate.a, progress)
		enemy.visuals.modulate = modulate
	if vfx:
		vfx.set_yellow_phase_progress(progress)
	if progress < 1.0:
		return
	_finish_yellow_phase()

func _finish_yellow_phase() -> void:
	_yellow_phase_state = YellowPhaseState.STABLE
	_yellow_phase_timer = 0.0
	_restore_enemy_visuals()
	_set_enemy_interactions_enabled(true)
	if enemy.state_machine:
		enemy.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
	if vfx:
		vfx.finish_yellow_phase()
	_reset_yellow_phase_schedule()

func _cancel_yellow_phase(restore_interactions := true) -> void:
	if _yellow_phase_state == YellowPhaseState.STABLE:
		return
	_yellow_phase_state = YellowPhaseState.STABLE
	_yellow_phase_timer = 0.0
	_restore_enemy_visuals()
	if restore_interactions:
		_set_enemy_interactions_enabled(true)
	if enemy and enemy.state_machine:
		enemy.state_machine.process_mode = Node.PROCESS_MODE_INHERIT
	if vfx:
		vfx.finish_yellow_phase()

func _restore_enemy_visuals() -> void:
	if not enemy or not enemy.visuals:
		return
	enemy.visuals.visible = true
	enemy.visuals.modulate = _base_visuals_modulate

func _set_enemy_interactions_enabled(enabled: bool) -> void:
	if not enemy:
		return
	var body_shape := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape:
		body_shape.set_deferred("disabled", not enabled)
	if enemy.hurtbox:
		enemy.hurtbox.set_deferred("monitorable", enabled)
	if enemy.detection_area:
		enemy.detection_area.set_deferred("monitoring", enabled)
	if enemy.attack_area:
		enemy.attack_area.set_deferred("monitoring", enabled)
	if enemy.contact_hitbox:
		enemy.contact_hitbox.set_deferred("monitoring", enabled)
	if not enabled:
		enemy.deactivate_attack_hitbox()

func _reset_yellow_phase_schedule() -> void:
	_yellow_phase_interval = _rng.randf_range(
		YELLOW_PHASE_INTERVAL_MIN,
		YELLOW_PHASE_INTERVAL_MAX
	)

func _resolve_yellow_phase_destination() -> Vector2:
	var fallback: Vector2 = enemy.global_position
	var is_flying: bool = enemy.stats and enemy.stats.gravity <= 0.01
	for attempt in 8:
		var distance := _rng.randf_range(
			YELLOW_PHASE_DISTANCE_MIN,
			YELLOW_PHASE_DISTANCE_MAX
		)
		var direction := -1.0 if _rng.randf() < 0.5 else 1.0
		var candidate_x := clampf(
			enemy.global_position.x + distance * direction,
			enemy.home_position.x - enemy.patrol_distance * 1.35,
			enemy.home_position.x + enemy.patrol_distance * 1.35
		)
		var candidate := Vector2(candidate_x, enemy.global_position.y)
		if is_flying:
			candidate.y = clampf(
				enemy.global_position.y + _rng.randf_range(-90.0, 90.0),
				enemy.home_position.y - 150.0,
				enemy.home_position.y + 150.0
			)
		else:
			candidate = _ground_candidate(candidate_x)
		if candidate != Vector2.INF and _position_is_clear(candidate):
			return candidate
	return fallback

func _ground_candidate(candidate_x: float) -> Vector2:
	var space_state: PhysicsDirectSpaceState2D = enemy.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		Vector2(candidate_x, enemy.global_position.y - 220.0),
		Vector2(candidate_x, enemy.global_position.y + 520.0),
		1,
		[enemy.get_rid()]
	)
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return Vector2.INF
	return Vector2(
		candidate_x,
		(result["position"] as Vector2).y - _body_bottom_offset() - 2.0
	)

func _body_bottom_offset() -> float:
	var shape_node := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not shape_node or not shape_node.shape:
		return 0.0
	var half_height := 0.0
	if shape_node.shape is RectangleShape2D:
		half_height = (shape_node.shape as RectangleShape2D).size.y * 0.5
	elif shape_node.shape is CapsuleShape2D:
		half_height = (shape_node.shape as CapsuleShape2D).height * 0.5
	elif shape_node.shape is CircleShape2D:
		half_height = (shape_node.shape as CircleShape2D).radius
	return shape_node.position.y + half_height

func _position_is_clear(candidate: Vector2) -> bool:
	var shape_node := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not shape_node or not shape_node.shape:
		return true
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.transform = shape_node.global_transform
	query.transform.origin += candidate - enemy.global_position
	query.collision_mask = 1
	query.exclude = [enemy.get_rid()]
	return enemy.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
