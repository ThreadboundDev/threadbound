class_name Tensioner
extends EnemyBase

const GROUND_ATTACK_TELEGRAPH_SCENE := preload("res://Src/VFX/ground_attack_telegraph.tscn")
const THREAD_SMASH_FLOOR_COLLISION_MASK := 1
const THREAD_SMASH_MAX_LANDING_JITTER := 18.0

@export var walk_texture: Texture2D
@export var attack_texture: Texture2D
@export var walk_columns := 6
@export var walk_rows := 4
@export var walk_frame_count := 24
@export var walk_fps := 8.0
@export var chase_fps_multiplier := 1.35
@export var attack_columns := 5
@export var attack_rows := 8
@export var attack_frame_count := 36
@export var walk_visual_offset := Vector2.ZERO
@export var attack_visual_offset := Vector2(5.0, 0.0)
@export var thread_missile_scene: PackedScene
@export_range(2, 4, 1) var thread_smash_min_missile_count := 2
@export_range(2, 4, 1) var thread_smash_max_missile_count := 4
@export_range(480.0, 720.0, 10.0) var thread_smash_landing_span := 600.0
@export_range(120.0, 220.0, 1.0) var thread_smash_min_landing_spacing := 120.0
@export_range(0.0, 18.0, 1.0) var thread_smash_landing_jitter := 18.0
@export_range(72.0, 140.0, 2.0) var thread_smash_safe_gap_width := 96.0
@export_range(20.0, 48.0, 1.0) var thread_smash_marker_radius := 32.0
@export var thread_smash_spawn_offset := Vector2(0.0, -12.0)
@export_range(0.72, 1.02, 0.01) var thread_smash_min_flight_time := 0.72
@export_range(0.72, 1.02, 0.01) var thread_smash_max_flight_time := 1.02
@export_range(80.0, 320.0, 10.0) var thread_smash_floor_ray_start_height := 180.0
@export_range(240.0, 720.0, 10.0) var thread_smash_floor_ray_depth := 480.0
@export_range(0.12, 0.40, 0.01) var thread_smash_impact_vfx_duration := 0.28
@export_range(0.0, 10.0, 0.25) var thread_smash_screen_shake_strength := 4.25
@export_range(0.0, 0.2, 0.01) var thread_smash_screen_shake_duration := 0.10
@export var thread_smash_random_seed := 0

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D
@onready var ground_attack_telegraph: GroundAttackTelegraph = (
	$GroundAttackTelegraph as GroundAttackTelegraph
)

var _animation_timer := 0.0
var _current_frame := 0
var _playing_attack := false
var _base_sprite_scale := Vector2.ONE
var _base_sprite_position := Vector2.ZERO
var _base_cell_size := Vector2.ONE
var _thread_smash_spawned := false
var _thread_smash_rng := RandomNumberGenerator.new()

func _ready() -> void:
	super._ready()
	add_to_group("tensioners")
	if thread_smash_random_seed != 0:
		_thread_smash_rng.seed = thread_smash_random_seed
	else:
		_thread_smash_rng.randomize()

	if visuals.has_node("Body"):
		visuals.get_node("Body").visible = false

	if sprite:
		_base_sprite_scale = sprite.scale
		_base_sprite_position = sprite.position
		if walk_texture:
			_base_cell_size = _get_sheet_cell_size(walk_texture, walk_columns, walk_rows)
		_play_walk_animation()

func _process(delta: float) -> void:
	_update_sprite_animation(delta)

func begin_attack() -> void:
	super.begin_attack()
	_thread_smash_spawned = false
	if sprite and attack_texture:
		_play_attack_animation()
	if ground_attack_telegraph:
		ground_attack_telegraph.play_windup(
			_get_smash_hitbox_width(),
			stats.attack_windup if stats else 0.58
		)

func activate_attack_hitbox() -> void:
	super.activate_attack_hitbox()
	CombatFeedback.screen_shake(
		self,
		thread_smash_screen_shake_strength,
		thread_smash_screen_shake_duration
	)
	if AudioManager.has_sound(&"enemy_stomp_attack_heavy"):
		AudioManager.play_sfx(&"enemy_stomp_attack_heavy")
	else:
		AudioManager.play_sfx(&"enemy_stomp_attack")
	if ground_attack_telegraph:
		ground_attack_telegraph.trigger_impact(
			_get_smash_hitbox_width(),
			thread_smash_impact_vfx_duration
		)
	if not _thread_smash_spawned:
		_thread_smash_spawned = true
		_spawn_thread_smash_missiles()

func _build_attack_damage() -> DamageData:
	var damage := super._build_attack_damage()
	# The ground impact itself owns one shake, even when the player dodges.
	damage.screen_shake_strength = 0.0
	damage.use_receiver_screen_shake_fallback = false
	return damage

func modify_outgoing_hit_damage(
	damage: DamageData,
	target_hurtbox: HurtboxComponent
) -> DamageData:
	damage = super.modify_outgoing_hit_damage(damage, target_hurtbox)
	if not damage or not target_hurtbox:
		return damage

	var smash_origin := global_position
	if attack_hitbox:
		smash_origin = attack_hitbox.global_position
	var target_position := target_hurtbox.global_position
	if target_hurtbox.hurtbox_owner is Node2D:
		target_position = (
			target_hurtbox.hurtbox_owner as Node2D
		).global_position
	var knockback_direction := (target_position - smash_origin).normalized()
	if knockback_direction.length_squared() <= 0.001:
		knockback_direction = Vector2(float(facing), -0.3)
	knockback_direction.y = minf(knockback_direction.y, -0.3)
	damage.knockback = knockback_direction.normalized() * stats.knockback_strength
	return damage

func end_attack() -> void:
	super.end_attack()
	if ground_attack_telegraph:
		ground_attack_telegraph.cancel_telegraph()
	if sprite and walk_texture:
		_play_walk_animation()

func _play_walk_animation() -> void:
	_playing_attack = false
	_animation_timer = 0.0
	_current_frame = 0
	_configure_sprite_sheet(walk_texture, walk_columns, walk_rows)
	if sprite:
		sprite.position = _base_sprite_position + walk_visual_offset

func _play_attack_animation() -> void:
	_playing_attack = true
	_animation_timer = 0.0
	_current_frame = 0
	_configure_sprite_sheet(attack_texture, attack_columns, attack_rows)
	if sprite:
		sprite.position = _base_sprite_position + attack_visual_offset

func _configure_sprite_sheet(texture: Texture2D, columns: int, rows: int) -> void:
	if not sprite or not texture:
		return

	sprite.texture = texture
	sprite.hframes = max(1, columns)
	sprite.vframes = max(1, rows)
	sprite.frame = 0
	sprite.scale = _get_scale_for_sheet(texture, sprite.hframes, sprite.vframes)

func _get_sheet_cell_size(texture: Texture2D, columns: int, rows: int) -> Vector2:
	if not texture:
		return Vector2.ONE

	return Vector2(
		float(texture.get_width()) / float(max(1, columns)),
		float(texture.get_height()) / float(max(1, rows))
	)

func _get_scale_for_sheet(texture: Texture2D, columns: int, rows: int) -> Vector2:
	var cell_size := _get_sheet_cell_size(texture, columns, rows)
	if cell_size.x <= 0.0 or cell_size.y <= 0.0:
		return _base_sprite_scale

	return Vector2(
		_base_sprite_scale.x * (_base_cell_size.x / cell_size.x),
		_base_sprite_scale.y * (_base_cell_size.y / cell_size.y)
	)

func _update_sprite_animation(delta: float) -> void:
	if not sprite:
		return

	var frame_count := attack_frame_count if _playing_attack else walk_frame_count
	frame_count = clampi(frame_count, 1, max(1, sprite.hframes * sprite.vframes))

	var fps := _get_attack_fps() if _playing_attack else _get_walk_fps()
	if fps <= 0.0:
		return

	_animation_timer += delta
	var next_frame := int(floor(_animation_timer * fps))
	if _playing_attack:
		_current_frame = mini(next_frame, frame_count - 1)
	else:
		_current_frame = next_frame % frame_count

	sprite.frame = _current_frame

func _get_walk_fps() -> float:
	if state_machine and state_machine.current_state_name == &"Chase":
		return walk_fps * chase_fps_multiplier
	return walk_fps

func _get_attack_fps() -> float:
	if not stats:
		return 24.0

	var attack_duration := stats.attack_windup + stats.attack_active_time + stats.attack_recovery
	if attack_duration <= 0.0:
		return 24.0

	return float(max(1, attack_frame_count)) / attack_duration

func _spawn_thread_smash_missiles() -> void:
	if not thread_missile_scene:
		return

	var parent := get_parent()
	if not parent:
		parent = self

	var minimum_count := clampi(thread_smash_min_missile_count, 2, 4)
	var maximum_count := clampi(thread_smash_max_missile_count, minimum_count, 4)
	var missile_count := _thread_smash_rng.randi_range(minimum_count, maximum_count)
	var landing_offsets := _build_thread_smash_landing_offsets(missile_count, _thread_smash_rng)
	var landing_center_x := global_position.x
	if target and is_instance_valid(target):
		landing_center_x = target.global_position.x
	var landing_points := _build_thread_smash_floor_targets(
		landing_center_x,
		landing_offsets
	)
	if landing_points.size() < minimum_count:
		return

	for landing_point in landing_points:
		var missile := thread_missile_scene.instantiate() as ThreadMissile
		if not missile:
			continue

		parent.add_child(missile)
		missile.global_position = global_position + thread_smash_spawn_offset

		var minimum_flight_time := minf(
			thread_smash_min_flight_time,
			thread_smash_max_flight_time
		)
		var maximum_flight_time := maxf(
			thread_smash_min_flight_time,
			thread_smash_max_flight_time
		)
		var flight_time := _thread_smash_rng.randf_range(
			maxf(0.05, minimum_flight_time),
			maxf(0.05, maximum_flight_time)
		)
		var launch_velocity := _solve_thread_smash_ballistic_velocity(
			missile.global_position,
			landing_point,
			flight_time,
			missile.arc_gravity
		)
		var landing_marker := _spawn_thread_smash_landing_marker(
			landing_point,
			flight_time
		)
		if landing_marker:
			missile.area_entered.connect(
				_on_thread_smash_missile_collision.bind(
					missile,
					landing_marker,
					landing_point
				)
			)
			missile.body_entered.connect(
				_on_thread_smash_missile_collision.bind(
					missile,
					landing_marker,
					landing_point
				)
			)
			missile.tree_exiting.connect(
				_on_thread_smash_missile_exiting.bind(
					missile,
					landing_marker,
					landing_point
				),
				CONNECT_ONE_SHOT
			)
		missile.launch(launch_velocity, self)


func _build_thread_smash_floor_targets(
	landing_center_x: float,
	landing_offsets: PackedFloat32Array
) -> PackedVector2Array:
	var landing_points := PackedVector2Array()
	var half_span := thread_smash_landing_span * 0.5 + thread_smash_landing_jitter
	var field_min_x := landing_center_x - half_span
	var field_max_x := landing_center_x + half_span
	var search_step := maxf(24.0, thread_smash_marker_radius)
	var maximum_search_steps := maxi(
		1,
		ceili(thread_smash_landing_span / search_step)
	)

	for landing_offset in landing_offsets:
		var desired_x := landing_center_x + landing_offset
		var landing_point := Vector2(INF, INF)
		for search_index in range(maximum_search_steps + 1):
			var candidate_x := desired_x
			if search_index > 0:
				var search_ring := ceili(float(search_index) * 0.5)
				var search_direction := -1.0 if search_index % 2 == 1 else 1.0
				candidate_x += search_direction * search_ring * search_step
			if candidate_x < field_min_x or candidate_x > field_max_x:
				continue
			if not _thread_smash_lane_has_safe_spacing(candidate_x, landing_points):
				continue

			var candidate_point := _find_thread_smash_floor_point(candidate_x)
			if is_finite(candidate_point.x) and is_finite(candidate_point.y):
				landing_point = candidate_point
				break

		if is_finite(landing_point.x) and is_finite(landing_point.y):
			landing_points.append(landing_point)

	var ordered_points: Array[Vector2] = []
	for landing_point in landing_points:
		ordered_points.append(landing_point)
	ordered_points.sort_custom(
		func(left: Vector2, right: Vector2) -> bool:
			return left.x < right.x
	)
	return PackedVector2Array(ordered_points)


func _thread_smash_lane_has_safe_spacing(
	candidate_x: float,
	landing_points: PackedVector2Array
) -> bool:
	var safe_spacing := maxf(
		thread_smash_min_landing_spacing,
		thread_smash_safe_gap_width + thread_smash_marker_radius * 2.0
	)
	for landing_point in landing_points:
		if absf(candidate_x - landing_point.x) < safe_spacing:
			return false
	return true


func _build_thread_smash_landing_offsets(
	missile_count: int,
	random_source: RandomNumberGenerator
) -> PackedFloat32Array:
	var safe_count := clampi(missile_count, 2, 4)
	var jitter := clampf(
		thread_smash_landing_jitter,
		0.0,
		THREAD_SMASH_MAX_LANDING_JITTER
	)
	var clear_gap_spacing := thread_smash_safe_gap_width + thread_smash_marker_radius * 2.0
	var guaranteed_base_spacing := maxf(
		thread_smash_min_landing_spacing,
		clear_gap_spacing
	) + jitter * 2.0
	var span := maxf(
		thread_smash_landing_span,
		guaranteed_base_spacing * float(safe_count - 1)
	)
	var step := span / float(safe_count - 1)
	var half_span := span * 0.5
	var offsets := PackedFloat32Array()

	for index in range(safe_count):
		var base_offset := -half_span + step * float(index)
		var landing_jitter := random_source.randf_range(-jitter, jitter)
		offsets.append(base_offset + landing_jitter)

	offsets.sort()
	return offsets


func _get_widest_thread_smash_safe_gap(offsets: PackedFloat32Array) -> float:
	if offsets.size() < 2:
		return 0.0

	var widest_gap := 0.0
	for index in range(1, offsets.size()):
		var clear_gap := (
			offsets[index]
			- offsets[index - 1]
			- thread_smash_marker_radius * 2.0
		)
		widest_gap = maxf(widest_gap, clear_gap)
	return widest_gap


func _find_thread_smash_floor_point(world_x: float) -> Vector2:
	var world := get_world_2d()
	if not world:
		return Vector2(INF, INF)

	var reference_y := global_position.y
	if target and is_instance_valid(target):
		reference_y = target.global_position.y
	var ray_start := Vector2(
		world_x,
		minf(global_position.y, reference_y) - thread_smash_floor_ray_start_height
	)
	var ray_end := Vector2(
		world_x,
		maxf(global_position.y, reference_y) + thread_smash_floor_ray_depth
	)
	var query := PhysicsRayQueryParameters2D.create(
		ray_start,
		ray_end,
		THREAD_SMASH_FLOOR_COLLISION_MASK
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var excluded_rids: Array[RID] = []
	if target is CollisionObject2D:
		excluded_rids.append((target as CollisionObject2D).get_rid())
	query.exclude = excluded_rids

	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return Vector2(INF, INF)
	return hit.get("position", Vector2(INF, INF)) as Vector2


func _solve_thread_smash_ballistic_velocity(
	start_position: Vector2,
	landing_position: Vector2,
	flight_time: float,
	gravity: float
) -> Vector2:
	var safe_flight_time := maxf(0.05, flight_time)
	var displacement := landing_position - start_position
	return Vector2(
		displacement.x / safe_flight_time,
		(
			displacement.y
			- 0.5 * maxf(0.0, gravity) * safe_flight_time * safe_flight_time
		) / safe_flight_time
	)


func _spawn_thread_smash_landing_marker(
	landing_position: Vector2,
	flight_time: float
) -> GroundAttackTelegraph:
	var marker := GROUND_ATTACK_TELEGRAPH_SCENE.instantiate() as GroundAttackTelegraph
	if not marker:
		return null

	var marker_parent := get_tree().current_scene
	if not marker_parent:
		marker_parent = get_parent()
	if not marker_parent:
		marker_parent = self
	marker_parent.add_child(marker)
	marker.global_position = landing_position + Vector2(0.0, -2.0)
	marker.play_landing_marker(thread_smash_marker_radius, flight_time)
	return marker


func _on_thread_smash_missile_collision(
	_collision: Node,
	missile: ThreadMissile,
	landing_marker: GroundAttackTelegraph,
	landing_position: Vector2
) -> void:
	if not is_instance_valid(missile) or not bool(missile.get("_is_impacting")):
		return
	_cancel_early_thread_smash_marker(
		missile,
		landing_marker,
		landing_position
	)


func _on_thread_smash_missile_exiting(
	missile: Variant,
	landing_marker: Variant,
	landing_position: Vector2
) -> void:
	_cancel_early_thread_smash_marker(
		missile,
		landing_marker,
		landing_position
	)


func _cancel_early_thread_smash_marker(
	missile: Variant,
	landing_marker: Variant,
	landing_position: Vector2
) -> void:
	if not is_instance_valid(landing_marker):
		return
	var marker := landing_marker as GroundAttackTelegraph
	if not marker:
		return
	var landing_tolerance := maxf(48.0, thread_smash_marker_radius * 1.5)
	if (
		not is_instance_valid(missile)
		or not missile is ThreadMissile
		or (missile as ThreadMissile).global_position.distance_to(landing_position)
			> landing_tolerance
	):
		marker.cancel_telegraph()


func _get_smash_hitbox_width() -> float:
	var hitbox_node := attack_hitbox
	if not hitbox_node:
		hitbox_node = get_node_or_null("AttackHitbox") as HitboxComponent
	if not hitbox_node:
		return 330.0
	var shape_node := hitbox_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not shape_node:
		return 330.0
	var rectangle := shape_node.shape as RectangleShape2D
	if not rectangle:
		return 330.0
	return rectangle.size.x
