class_name BaseGloves
extends Node2D

const AimHelperScript := preload("res://Src/Global/aim_helper.gd")
const GRAPPLE_STRIKE_VFX_SCENE := preload("res://Src/VFX/grapple_strike_vfx.tscn")
const GRAPPLE_STRIKE_TRAIL_VFX_SCENE := preload(
	"res://Src/VFX/grapple_strike_trail_vfx.tscn"
)

var player: CharacterBody2D = null

# ===============================
# NODES
# ===============================
@onready var equipment: Node2D = $Equipment
@onready var animation_player: AnimationPlayer = $Equipment/AnimationPlayer

@onready var right_hand_anchor: Marker2D = $Equipment/RightHandAnchor
@onready var wrist_wrap_pivot: Node2D = $Equipment/RightHandAnchor/WristWrapPivot
@onready var rope_hang_anchor: Node2D = $Equipment/RightHandAnchor/RopeHangAnchor
@onready var grapple_origin: Marker2D = $Equipment/RightHandAnchor/GrappleOrigin

@onready var active_grapple_root: Node2D = $Equipment/ActiveGrappleRoot
@onready var active_rope_line: Line2D = $Equipment/ActiveGrappleRoot/ActiveRopeLine
@onready var active_needle_sprite: Sprite2D = $Equipment/ActiveGrappleRoot/ActiveNeedleSprite
@onready var active_needle_attach_point: Marker2D = $Equipment/ActiveGrappleRoot/ActiveNeedleSprite/ActiveNeedleAttachPoint
@onready var grapple_raycast: RayCast2D = $Equipment/ActiveGrappleRoot/GrappleRayCast

# ===============================
# GRAPPLE SETTINGS
# ===============================
@export var grapple_input_action := "Grapple"
@export var grapple_speed := 1300.0
@export var grapple_max_distance := 360.0
@export var grapple_retract_speed := 1800.0
@export var needle_rotation_offset := -PI / 2.0
@export_flags_2d_physics var grapple_collision_mask := 7
@export_flags_2d_physics var grapple_solid_surface_mask := 1
@export var grapple_surface_resolve_depth := 128.0

# Active rope visuals/physics
@export var active_rope_segment_count := 12
@export var active_rope_gravity := Vector2(0, 900)
@export var active_rope_damping := 0.96
@export var active_rope_constraint_iterations := 8
@export var active_rope_total_length := 360.0

# Grapple attachment arming
@export var grapple_arm_distance: float = 12.0
@export var grapple_arm_delay: float = 0.04
@export var grapple_min_active_speed: float = 40.0
@export_range(0.0, 1.0) var grapple_active_speed_ratio: float = 0.15
@export var grapple_low_speed_grace: float = 0.20
@export var grapple_max_unattached_time: float = 1.25
@export var grapple_spent_retract_delay: float = 0.20

# Base grapple player limit
@export var enforce_player_rope_limit := true
@export var rope_limit_slack := 6.0
@export var rope_limit_pull_strength := 18.0
@export var rope_tangent_max_speed := 380.0
@export var rope_tangent_damping := 0.985
@export var rope_idle_swing_lerp_speed := 5.5
@export var rope_idle_swing_stop_speed := 8.0
@export var rope_jump_force := 760.0

# Base hookshot behavior (enabled only by base_gloves.tscn).
@export var hookshot_enabled := false
@export var hookshot_pull_speed := 900.0
@export var hookshot_surface_offset := 18.0
@export var hookshot_surface_padding := 2.0
@export var hookshot_arrival_distance := 8.0
@export var hookshot_stall_time := 0.18
@export var hookshot_min_progress := 1.0

@export_group("Enemy Grapple Strike")
@export var enemy_grapple_hold_time := 0.72
@export var grapple_strike_approach_speed := 1600.0
@export var grapple_strike_standoff_padding := 20.0
@export var grapple_strike_resolve_slack := 72.0
@export var grapple_strike_damage := 30
@export var grapple_strike_hitstun := 0.22
@export var grapple_strike_hit_pause := 0.05
@export var grapple_strike_knockback_strength := 320.0
@export var grapple_strike_recoil_strength := 360.0
@export var grapple_strike_recoil_lift := 165.0
@export var grapple_strike_screen_shake_strength := 3.4
@export var grapple_strike_screen_shake_duration := 0.08
@export_range(0.0, 0.9, 0.01) var grapple_strike_range_bonus_start_ratio := 0.35
@export_range(1.0, 2.0, 0.01) var grapple_strike_max_range_damage_multiplier := 1.25

# Climbing Variables
@export var rope_climb_speed := 220.0
@export var rope_min_length := 48.0

# Animation lock
@export var grapple_fire_anim_lock_time := 0.14
@export var attack_follow_anim_lock_time := 0.22
@export var save_point_hand_position := Vector2(-12.0, -34.0)
@export var save_point_wrist_rotation := -0.35
var action_anim_lock_timer := 0.0

# ===============================
# GRAPPLE STATE
# ===============================
enum GrappleState {
	STOWED,
	FIRING,
	ATTACHED,
	RETRACTING
}

enum GrappleAttachmentState {
	UNARMED,
	ACTIVE,
	SPENT
}

var grapple_state: GrappleState = GrappleState.STOWED
var grapple_attachment_state: GrappleAttachmentState = GrappleAttachmentState.SPENT

var grapple_direction := Vector2.RIGHT
var grapple_start_position := Vector2.ZERO
var grapple_tip_position := Vector2.ZERO
var grapple_tip_velocity := Vector2.ZERO
var grapple_initial_launch_speed := 0.0
var grapple_active_speed_threshold := 0.0
var grapple_release_timer := 0.0
var grapple_low_speed_timer := 0.0
var grapple_spent_timer := 0.0

var grapple_attached := false
var grapple_attach_position := Vector2.ZERO
var current_rope_length := 0.0
var grapple_target: Node2D = null
var grapple_target_local_position := Vector2.ZERO
var grapple_collision_normal := Vector2.ZERO
var hookshot_enemy_hurtbox: HurtboxComponent = null
var hookshot_previous_distance := INF
var hookshot_stall_timer := 0.0
var enemy_grapple_ready := false
var enemy_grapple_hold_timer := 0.0
var grapple_strike_active := false
var grapple_strike_direction := Vector2.RIGHT
var grapple_strike_launch_range_ratio := 0.0
var grapple_strike_at_strike_distance := false
var _grapple_strike_trail_vfx: GrappleStrikeTrailVFX = null

var active_rope_points: Array[Vector2] = []
var active_rope_previous_points: Array[Vector2] = []

# ===============================
# EQUIPMENT LIFECYCLE
# ===============================
func _ready() -> void:
	visible = true

	# Active grapple exists in world space so it does not mirror-flash
	# when EquipmentMount flips left/right.
	if active_grapple_root:
		active_grapple_root.top_level = true
		active_grapple_root.global_position = Vector2.ZERO
		active_grapple_root.global_rotation = 0.0
		active_grapple_root.global_scale = Vector2.ONE

	_configure_grapple_raycast()
	_reset_active_grapple_visuals()
	print("✅ BaseGloves ready")

func on_equipped() -> void:
	visible = true
	_configure_grapple_raycast()
	_show_stowed_rope()

	if rope_hang_anchor and rope_hang_anchor.has_method("reset_rope"):
		rope_hang_anchor.reset_rope()

func on_unequipped() -> void:
	_reset_active_grapple_visuals()
	queue_free()

# ===============================
# ANIMATION
# ===============================
func play_equipment_anim(anim_name: String) -> void:
	if not animation_player:
		return

	if not animation_player.has_animation(anim_name):
		print("Missing glove anim: ", anim_name)
		return

	# Do not let idle/run/jump overwrite action poses.
	if action_anim_lock_timer > 0.0 and not _is_action_equipment_anim(anim_name):
		return

	animation_player.stop()
	animation_player.play(anim_name)
	animation_player.seek(0.0, true)
	animation_player.advance(0.0)

func _play_grapple_fire_animation() -> void:
	action_anim_lock_timer = grapple_fire_anim_lock_time

	var use_diagonal: bool = abs(grapple_direction.y) > 0.35
	if player and absf(grapple_direction.x) > 0.05:
		player.last_direction = -1 if grapple_direction.x < 0.0 else 1
		if player.has_node("Player Animation"):
			var facing_animation := player.get_node("Player Animation") as AnimatedSprite2D
			facing_animation.flip_h = grapple_direction.x < 0.0
		if player.has_method("update_equipment_facing"):
			player.update_equipment_facing()

	if use_diagonal:
		play_equipment_anim("Grapple_Diagonal")

		if player and player.has_node("Player Animation"):
			var body_anim: AnimatedSprite2D = player.get_node("Player Animation")
			if body_anim.sprite_frames.has_animation("Grapple_Diagonal"):
				body_anim.play("Grapple_Diagonal")
	else:
		play_equipment_anim("Grapple_Horizontal")

		if player and player.has_node("Player Animation"):
			var body_anim: AnimatedSprite2D = player.get_node("Player Animation")
			if body_anim.sprite_frames.has_animation("Grapple_Horizontal"):
				body_anim.play("Grapple_Horizontal")

func play_attack_follow_pose(_direction: Vector2, body_anim: String = "") -> void:
	action_anim_lock_timer = attack_follow_anim_lock_time
	if animation_player and animation_player.has_animation(body_anim):
		play_equipment_anim(body_anim)

func sync_equipment_anim_to_body_frame(
	body_anim: String,
	body_frame: int,
	body_fps: float
) -> void:
	if (
		not animation_player
		or body_fps <= 0.0
		or not animation_player.has_animation(body_anim)
		or animation_player.current_animation != body_anim
	):
		return
	animation_player.seek(float(body_frame) / body_fps, true)

func _is_action_equipment_anim(anim_name: String) -> bool:
	return (
		anim_name == "Dash"
		or anim_name.begins_with("Grapple_")
		or anim_name.begins_with("Ground_Attack_")
		or anim_name == "Air_Double_Attack"
		or anim_name == "Neutral_Special_Attack"
	)

func enter_save_point_pose() -> void:
	action_anim_lock_timer = 999.0
	if animation_player:
		animation_player.stop()
	if right_hand_anchor:
		right_hand_anchor.position = save_point_hand_position
	if wrist_wrap_pivot:
		wrist_wrap_pivot.rotation = save_point_wrist_rotation
	if rope_hang_anchor and rope_hang_anchor.has_method("reset_rope"):
		rope_hang_anchor.reset_rope()

func exit_save_point_pose() -> void:
	action_anim_lock_timer = 0.0
	play_equipment_anim("Idle")

# ===============================
# BASIC HELPERS
# ===============================
func get_grapple_origin_global_position() -> Vector2:
	if grapple_origin:
		return grapple_origin.global_position

	if player:
		return player.global_position

	return global_position

func is_grapple_attached() -> bool:
	return grapple_state == GrappleState.ATTACHED

func has_enemy_grapple_target() -> bool:
	return (
		grapple_state == GrappleState.ATTACHED
		and hookshot_enemy_hurtbox != null
		and is_instance_valid(hookshot_enemy_hurtbox)
		and hookshot_enemy_hurtbox.hurtbox_owner is Node2D
	)

func try_start_grapple_strike() -> bool:
	if grapple_strike_active or not has_enemy_grapple_target() or not player:
		return false

	grapple_strike_active = true
	grapple_strike_at_strike_distance = false
	enemy_grapple_ready = false
	enemy_grapple_hold_timer = 0.0
	grapple_strike_direction = _get_enemy_grapple_direction()
	_on_enemy_grapple_strike_started()
	return true

func is_grapple_strike_active() -> bool:
	return grapple_strike_active

func is_grapple_strike_ready_to_animate() -> bool:
	return grapple_strike_active and grapple_strike_at_strike_distance

func is_grapple_strike_contact_guard_active() -> bool:
	return grapple_strike_active

func get_grapple_strike_direction() -> Vector2:
	if grapple_strike_direction.length_squared() <= 0.001:
		return Vector2.RIGHT
	return grapple_strike_direction.normalized()

func apply_grapple_strike_velocity(delta: float) -> bool:
	if not grapple_strike_active:
		return false
	if not has_enemy_grapple_target() or not player:
		cancel_grapple_strike()
		return false

	_update_moving_grapple_target()
	var destination := _get_enemy_grapple_standoff_position()
	var to_destination := destination - player.global_position
	grapple_strike_direction = _get_enemy_grapple_direction()
	_update_grapple_strike_trail()

	if to_destination.length() <= hookshot_arrival_distance:
		player.velocity = Vector2.ZERO
		grapple_strike_at_strike_distance = true
		return true
	if _is_hookshot_pull_blocked(to_destination.normalized()):
		cancel_grapple_strike()
		return false

	var approach_multiplier := 1.0
	if player.has_method("get_momentum_grapple_pull_multiplier"):
		approach_multiplier = maxf(
			1.0,
			float(player.call("get_momentum_grapple_pull_multiplier"))
		)
	var approach_speed := grapple_strike_approach_speed * approach_multiplier
	player.velocity = (
		to_destination.normalized()
		* minf(approach_speed, to_destination.length() / maxf(delta, 0.001))
	)
	return true

func resolve_grapple_strike() -> bool:
	if not grapple_strike_active or not has_enemy_grapple_target() or not player:
		cancel_grapple_strike()
		return false

	_update_moving_grapple_target()
	var target_position := _get_enemy_grapple_center()
	var desired_position := _get_enemy_grapple_standoff_position()
	var close_enough := (
		player.global_position.distance_to(desired_position)
		<= grapple_strike_resolve_slack
	)
	if not close_enough:
		return false

	var strike_direction := (target_position - _get_player_collision_center()).normalized()
	if strike_direction.length_squared() <= 0.001:
		strike_direction = get_grapple_strike_direction()
	grapple_strike_direction = strike_direction
	var impact_position := _get_enemy_grapple_impact_position(strike_direction)
	if _has_world_between_player_and_grapple_target(impact_position):
		cancel_grapple_strike()
		return false

	var damage := DamageData.new()
	var damage_multiplier := 1.0
	if player.has_method("get_momentum_attack_damage_multiplier"):
		damage_multiplier = float(player.call("get_momentum_attack_damage_multiplier"))
	damage_multiplier *= get_grapple_strike_range_damage_multiplier()
	damage.amount = maxi(1, roundi(float(grapple_strike_damage) * damage_multiplier))
	damage.hitstun = grapple_strike_hitstun
	damage.hit_pause = grapple_strike_hit_pause
	damage.screen_shake_strength = grapple_strike_screen_shake_strength
	damage.screen_shake_duration = grapple_strike_screen_shake_duration
	damage.use_receiver_screen_shake_fallback = false
	damage.source = player
	damage.hit_position = impact_position
	var target_knockback_direction := strike_direction
	target_knockback_direction.y = minf(target_knockback_direction.y, -0.24)
	damage.knockback = (
		target_knockback_direction.normalized()
		* grapple_strike_knockback_strength
	)

	var accepted := hookshot_enemy_hurtbox.receive_hit(damage)
	if accepted:
		_spawn_grapple_strike_vfx(impact_position, strike_direction)
		AudioManager.play_sfx(&"grapple_strike")
		var horizontal_recoil_sign := -signf(strike_direction.x)
		if is_zero_approx(horizontal_recoil_sign):
			horizontal_recoil_sign = -signf(float(player.last_direction))
		player.velocity = Vector2(
			horizontal_recoil_sign * grapple_strike_recoil_strength,
			-grapple_strike_recoil_lift
		)
		if player.has_method("report_momentum_action"):
			player.report_momentum_action(&"Attack", 1.35)

	_clear_grapple_strike_state()
	_release_after_enemy_grapple_strike()
	return accepted

func get_grapple_strike_range_damage_multiplier() -> float:
	var bonus_start := clampf(
		grapple_strike_range_bonus_start_ratio,
		0.0,
		0.99
	)
	var range_weight := clampf(
		inverse_lerp(
			bonus_start,
			1.0,
			grapple_strike_launch_range_ratio
		),
		0.0,
		1.0
	)
	var smooth_weight := (
		range_weight
		* range_weight
		* (3.0 - 2.0 * range_weight)
	)
	return lerpf(
		1.0,
		maxf(1.0, grapple_strike_max_range_damage_multiplier),
		smooth_weight
	)

func cancel_grapple_strike(retract := true) -> void:
	if not grapple_strike_active and not enemy_grapple_ready:
		return
	_clear_grapple_strike_state()
	if retract:
		_release_after_enemy_grapple_strike()

func cancel_enemy_grapple_combat() -> void:
	if (
		not has_enemy_grapple_target()
		and not grapple_strike_active
		and not enemy_grapple_ready
	):
		return
	_clear_grapple_strike_state()
	_release_after_enemy_grapple_strike()

func cancel_for_committed_attack() -> void:
	if (
		grapple_state == GrappleState.STOWED
		and not grapple_strike_active
		and not enemy_grapple_ready
	):
		return
	_clear_grapple_strike_state()
	_release_after_enemy_grapple_strike()

func mark_enemy_grapple_ready() -> void:
	enemy_grapple_ready = true
	enemy_grapple_hold_timer = enemy_grapple_hold_time
	if player:
		player.velocity = Vector2.ZERO

func hold_enemy_grapple_ready(delta: float) -> bool:
	if not enemy_grapple_ready:
		return false
	if grapple_strike_active:
		return true
	if not has_enemy_grapple_target() or not player:
		_clear_grapple_strike_state()
		_release_after_enemy_grapple_strike()
		return true

	player.velocity = Vector2.ZERO
	enemy_grapple_hold_timer = maxf(0.0, enemy_grapple_hold_timer - delta)
	if enemy_grapple_hold_timer <= 0.0:
		_clear_grapple_strike_state()
		_release_after_enemy_grapple_strike()
	return true

func apply_enemy_grapple_setup_pull(delta: float, pull_speed: float) -> bool:
	if not has_enemy_grapple_target() or not player:
		return false
	if hold_enemy_grapple_ready(delta):
		return true
	if grapple_strike_active:
		return true

	_update_moving_grapple_target()
	var destination := _get_enemy_grapple_standoff_position()
	var to_destination := destination - player.global_position
	if to_destination.length() <= hookshot_arrival_distance:
		mark_enemy_grapple_ready()
		return true
	if _is_hookshot_pull_blocked(to_destination.normalized()):
		_clear_grapple_strike_state()
		_release_after_enemy_grapple_strike()
		return true

	player.velocity = (
		to_destination.normalized()
		* minf(pull_speed, to_destination.length() / maxf(delta, 0.001))
	)
	return true

func forces_dash_animation() -> bool:
	return (
		grapple_strike_active and not grapple_strike_at_strike_distance
		or (
			hookshot_enabled
			and has_enemy_grapple_target()
			and not enemy_grapple_ready
		)
	)

func get_forced_dash_direction() -> Vector2:
	if not forces_dash_animation():
		return Vector2.ZERO
	if grapple_strike_active:
		return get_grapple_strike_direction()
	if hookshot_enabled and has_enemy_grapple_target() and player:
		var pull_direction := _get_enemy_grapple_standoff_position() - player.global_position
		if pull_direction.length_squared() > 0.001:
			return pull_direction.normalized()
	return Vector2.ZERO

func get_enemy_grapple_center_distance() -> float:
	if not has_enemy_grapple_target():
		return INF
	return _get_player_collision_center().distance_to(_get_enemy_grapple_center())

func get_enemy_grapple_safe_center_distance() -> float:
	if not has_enemy_grapple_target():
		return 0.0
	var away_from_target := (
		_get_player_collision_center() - _get_enemy_grapple_center()
	).normalized()
	if away_from_target.length_squared() <= 0.001:
		away_from_target = -grapple_direction.normalized()
	return (
		_get_collision_extent_along(_get_enemy_grapple_collision_shape(), away_from_target)
		+ _get_collision_extent_along(_get_player_collision_shape(), away_from_target)
		+ grapple_strike_standoff_padding
	)

func _clear_grapple_strike_state() -> void:
	grapple_strike_active = false
	grapple_strike_at_strike_distance = false
	enemy_grapple_ready = false
	enemy_grapple_hold_timer = 0.0
	_stop_grapple_strike_trail()

func _on_enemy_grapple_strike_started() -> void:
	_stop_grapple_strike_trail()
	var trail := GRAPPLE_STRIKE_TRAIL_VFX_SCENE.instantiate() as GrappleStrikeTrailVFX
	if not trail or not player:
		return
	var parent := get_tree().current_scene
	if not parent:
		parent = get_parent()
	if not parent:
		trail.queue_free()
		return
	parent.add_child(trail)
	trail.play(player, grapple_strike_direction)
	_grapple_strike_trail_vfx = trail

func _update_grapple_strike_trail() -> void:
	if is_instance_valid(_grapple_strike_trail_vfx):
		_grapple_strike_trail_vfx.update_direction(grapple_strike_direction)

func _stop_grapple_strike_trail() -> void:
	if is_instance_valid(_grapple_strike_trail_vfx):
		_grapple_strike_trail_vfx.stop()
	_grapple_strike_trail_vfx = null

func _release_after_enemy_grapple_strike() -> void:
	_begin_grapple_retract()

func _get_enemy_grapple_direction() -> Vector2:
	if not player:
		return grapple_direction.normalized()
	var direction := _get_enemy_grapple_center() - _get_player_collision_center()
	if direction.length_squared() <= 0.001:
		direction = grapple_direction
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	return direction.normalized()

func _get_enemy_grapple_standoff_position() -> Vector2:
	if not player:
		return grapple_attach_position

	var target_center := _get_enemy_grapple_center()
	var player_center := _get_player_collision_center()
	var away_from_target := (player_center - target_center).normalized()
	if away_from_target.length_squared() <= 0.001:
		away_from_target = -grapple_direction.normalized()
	if away_from_target.length_squared() <= 0.001:
		away_from_target = Vector2.LEFT

	var center_distance := get_enemy_grapple_safe_center_distance()
	var desired_player_center := target_center + away_from_target * center_distance
	return desired_player_center - _get_player_collision_center_offset()

func _get_enemy_grapple_center() -> Vector2:
	var collision_shape := _get_enemy_grapple_collision_shape()
	if collision_shape:
		return collision_shape.global_position
	if hookshot_enemy_hurtbox and hookshot_enemy_hurtbox.hurtbox_owner is Node2D:
		return (hookshot_enemy_hurtbox.hurtbox_owner as Node2D).global_position
	return grapple_attach_position

func _get_enemy_grapple_impact_position(strike_direction: Vector2) -> Vector2:
	var target_center := _get_enemy_grapple_center()
	var direction := strike_direction.normalized()
	if direction.length_squared() <= 0.001:
		direction = _get_enemy_grapple_direction()
	var target_extent := _get_collision_extent_along(
		_get_enemy_grapple_collision_shape(),
		-direction
	)
	return target_center - direction * target_extent

func _get_enemy_grapple_collision_shape() -> CollisionShape2D:
	if not hookshot_enemy_hurtbox or not is_instance_valid(hookshot_enemy_hurtbox):
		return null
	return hookshot_enemy_hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D

func _get_player_collision_shape() -> CollisionShape2D:
	if not player:
		return null
	return player.get_node_or_null("CollisionShape2D") as CollisionShape2D

func _get_player_collision_center_offset() -> Vector2:
	var collision_shape := _get_player_collision_shape()
	if not collision_shape or not player:
		return Vector2.ZERO
	return collision_shape.global_position - player.global_position

func _get_player_collision_center() -> Vector2:
	if not player:
		return global_position
	return player.global_position + _get_player_collision_center_offset()

func _get_collision_extent_along(
	collision_shape: CollisionShape2D,
	world_direction: Vector2
) -> float:
	if not collision_shape or not collision_shape.shape:
		return 0.0
	var direction := world_direction.normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	var shape_rect := collision_shape.shape.get_rect()
	var corners := [
		shape_rect.position,
		shape_rect.position + Vector2(shape_rect.size.x, 0.0),
		shape_rect.position + Vector2(0.0, shape_rect.size.y),
		shape_rect.end,
	]
	var center := collision_shape.global_position
	var extent := 0.0
	for corner in corners:
		var world_corner := collision_shape.to_global(corner)
		extent = maxf(extent, absf((world_corner - center).dot(direction)))
	return extent

func _has_world_between_player_and_grapple_target(target_position: Vector2) -> bool:
	if not player or not is_inside_tree():
		return true
	var query := PhysicsRayQueryParameters2D.create(
		_get_player_collision_center(),
		target_position,
		1,
		[player.get_rid()]
	)
	query.hit_from_inside = false
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _spawn_grapple_strike_vfx(world_position: Vector2, direction: Vector2) -> void:
	var vfx := GRAPPLE_STRIKE_VFX_SCENE.instantiate() as GrappleStrikeVFX
	if not vfx:
		return
	var parent := get_tree().current_scene
	if not parent:
		parent = get_parent()
	if not parent:
		vfx.queue_free()
		return
	parent.add_child(vfx)
	vfx.global_position = world_position
	vfx.play(direction)

func is_base_grapple_restricting() -> bool:
	if grapple_strike_active:
		return true
	if grapple_state != GrappleState.ATTACHED:
		return false

	if not player:
		return false

	if hookshot_enabled:
		return true

	if player.is_on_floor():
		return false

	var origin := get_grapple_origin_global_position()
	var distance := origin.distance_to(grapple_attach_position)

	return distance > current_rope_length + rope_limit_slack

func jump_off_grapple() -> bool:
	if grapple_state != GrappleState.ATTACHED:
		return false

	if not player:
		return false

	if hookshot_enabled:
		player.velocity = Vector2.ZERO
		_begin_grapple_retract()
		return true

	var origin := get_grapple_origin_global_position()
	var from_anchor := origin - grapple_attach_position

	if from_anchor.length() > 0.001:
		var rope_dir := from_anchor.normalized()
		var tangent := Vector2(-rope_dir.y, rope_dir.x)
		var tangent_speed := player.velocity.dot(tangent)
		tangent_speed = clamp(tangent_speed, -rope_tangent_max_speed, rope_tangent_max_speed)
		player.velocity = tangent * tangent_speed

	player.velocity.y = min(player.velocity.y, -rope_jump_force)
	_begin_grapple_retract()
	return true

# ===============================
# STOWED / ACTIVE VISUALS
# ===============================
func _hide_stowed_rope() -> void:
	if rope_hang_anchor:
		rope_hang_anchor.visible = false

func _show_stowed_rope() -> void:
	if rope_hang_anchor:
		rope_hang_anchor.visible = true

		if rope_hang_anchor.has_method("reset_rope"):
			rope_hang_anchor.reset_rope()

func _reset_active_grapple_visuals() -> void:
	AudioManager.stop_loop(&"grapple_hanging")
	grapple_state = GrappleState.STOWED
	grapple_attachment_state = GrappleAttachmentState.SPENT
	grapple_attached = false
	grapple_tip_velocity = Vector2.ZERO
	grapple_initial_launch_speed = 0.0
	grapple_active_speed_threshold = 0.0
	grapple_release_timer = 0.0
	grapple_low_speed_timer = 0.0
	grapple_spent_timer = 0.0
	grapple_target = null
	grapple_target_local_position = Vector2.ZERO
	grapple_collision_normal = Vector2.ZERO
	hookshot_enemy_hurtbox = null
	hookshot_previous_distance = INF
	hookshot_stall_timer = 0.0
	enemy_grapple_ready = false
	enemy_grapple_hold_timer = 0.0
	grapple_strike_active = false
	grapple_strike_at_strike_distance = false
	_stop_grapple_strike_trail()
	grapple_strike_direction = Vector2.RIGHT
	grapple_strike_launch_range_ratio = 0.0
	active_rope_points.clear()
	active_rope_previous_points.clear()

	if active_grapple_root:
		active_grapple_root.visible = false

	if active_rope_line:
		active_rope_line.points = PackedVector2Array()

	if active_needle_sprite:
		active_needle_sprite.visible = false

	_show_stowed_rope()

func _configure_grapple_raycast() -> void:
	if not grapple_raycast:
		return

	grapple_raycast.enabled = true
	grapple_raycast.collide_with_bodies = true
	grapple_raycast.collide_with_areas = true
	grapple_raycast.collision_mask = grapple_collision_mask
	_reset_grapple_raycast_exceptions()

func _reset_grapple_raycast_exceptions() -> void:
	if not grapple_raycast:
		return

	grapple_raycast.clear_exceptions()

	if player:
		grapple_raycast.add_exception(player)
		# RayCast exceptions do not cascade to child collision objects. The
		# player's layer-two Hurtbox must be excluded separately or an airborne
		# throw can attach to the player itself near the wrist.
		var player_hurtbox := player.get_node_or_null("Hurtbox") as CollisionObject2D
		if player_hurtbox:
			grapple_raycast.add_exception(player_hurtbox)

# ===============================
# ROPE PHYSICS
# ===============================
func _reset_active_rope_physics() -> void:
	active_rope_points.clear()
	active_rope_previous_points.clear()

	var origin := get_grapple_origin_global_position()
	var segment_length := active_rope_total_length / float(active_rope_segment_count - 1)

	for i in range(active_rope_segment_count):
		var point := origin + grapple_direction * segment_length * float(i)
		active_rope_points.append(point)
		active_rope_previous_points.append(point)

func _simulate_active_rope(delta: float, pin_end_to_tip: bool = true) -> void:
	if active_rope_points.size() < 2:
		return

	var origin := get_grapple_origin_global_position()
	var last_index := active_rope_points.size() - 1
	var segment_length := active_rope_total_length / float(active_rope_segment_count - 1)

	# Move thrown needle only while firing.
	if grapple_state == GrappleState.FIRING:
		grapple_tip_velocity += active_rope_gravity * delta

		var proposed_tip := grapple_tip_position + grapple_tip_velocity * delta
		var distance_from_start := proposed_tip.distance_to(grapple_start_position)

		if distance_from_start > grapple_max_distance:
			var direction := (proposed_tip - grapple_start_position).normalized()
			grapple_tip_position = grapple_start_position + direction * grapple_max_distance
			grapple_tip_velocity = Vector2.ZERO
		else:
			grapple_tip_position = proposed_tip

	# Pin rope start to hand.
	active_rope_points[0] = origin
	active_rope_previous_points[0] = origin

	# Simulate middle rope points.
	for i in range(1, last_index):
		var current := active_rope_points[i]
		var velocity := (active_rope_points[i] - active_rope_previous_points[i]) * active_rope_damping
		active_rope_previous_points[i] = current
		active_rope_points[i] += velocity + active_rope_gravity * delta * delta

	# Pin rope end to needle/attach point.
	if pin_end_to_tip:
		active_rope_points[last_index] = grapple_tip_position
		active_rope_previous_points[last_index] = grapple_tip_position

	# Keep rope segment lengths stable.
	for _iteration in range(active_rope_constraint_iterations):
		active_rope_points[0] = origin

		if pin_end_to_tip:
			active_rope_points[last_index] = grapple_tip_position

		for i in range(active_rope_points.size() - 1):
			var p1 := active_rope_points[i]
			var p2 := active_rope_points[i + 1]
			var delta_vec := p2 - p1
			var distance := delta_vec.length()

			if distance == 0:
				continue

			var difference := (distance - segment_length) / distance
			var correction := delta_vec * difference

			if i == 0:
				active_rope_points[i + 1] -= correction
			elif pin_end_to_tip and i == last_index - 1:
				active_rope_points[i] += correction
			else:
				active_rope_points[i] += correction * 0.5
				active_rope_points[i + 1] -= correction * 0.5

# ===============================
# GRAPPLE FIRING / COLLISION
# ===============================
func _start_grapple_fire() -> void:
	if active_grapple_root:
		active_grapple_root.visible = false
	if active_needle_sprite:
		active_needle_sprite.visible = false
	if active_rope_line:
		active_rope_line.points = PackedVector2Array()

	# Rebuild exceptions every throw so temporary hitboxes and replaced player
	# collision areas can never be mistaken for a grapple target.
	_reset_grapple_raycast_exceptions()
	grapple_start_position = get_grapple_origin_global_position()
	grapple_tip_position = grapple_start_position

	grapple_direction = AimHelperScript.get_grapple_aim_direction(
		self,
		grapple_start_position,
		grapple_direction,
		grapple_max_distance,
		grapple_collision_mask
	)

	var speed_multiplier: float = 1.0
	if player and player.has_method("get_momentum_grapple_speed_multiplier"):
		speed_multiplier = player.get_momentum_grapple_speed_multiplier()
	grapple_tip_velocity = grapple_direction * grapple_speed * speed_multiplier
	_start_grapple_attachment_tracking()
	_reset_active_rope_physics()

	grapple_state = GrappleState.FIRING
	grapple_attached = false

	_hide_stowed_rope()

	if active_grapple_root:
		active_grapple_root.top_level = true
		active_grapple_root.global_position = Vector2.ZERO
		active_grapple_root.global_rotation = 0.0
		active_grapple_root.global_scale = Vector2.ONE

	if active_needle_sprite:
		active_needle_sprite.global_position = grapple_tip_position

	var grapple_visuals_valid := _update_active_grapple_visuals()
	if grapple_visuals_valid and active_grapple_root:
		active_grapple_root.visible = true
	if grapple_visuals_valid and active_needle_sprite:
		active_needle_sprite.visible = true

	AudioManager.play_sfx(&"grapple")
	_play_grapple_fire_animation()

func _begin_grapple_retract() -> void:
	if grapple_state != GrappleState.STOWED:
		_request_player_ledge_assist()
		_clear_grapple_strike_state()
		AudioManager.stop_loop(&"grapple_hanging")
		grapple_state = GrappleState.RETRACTING
		grapple_attachment_state = GrappleAttachmentState.SPENT
		grapple_attached = false
		grapple_tip_velocity = Vector2.ZERO

func _request_player_ledge_assist() -> void:
	if (
		grapple_state != GrappleState.ATTACHED
		or not player
		or has_enemy_grapple_target()
		or not player.has_method("request_grapple_ledge_assist")
	):
		return
	player.call("request_grapple_ledge_assist", grapple_attach_position)

func _start_grapple_attachment_tracking() -> void:
	grapple_attachment_state = GrappleAttachmentState.UNARMED
	grapple_initial_launch_speed = grapple_tip_velocity.length()
	grapple_active_speed_threshold = maxf(
		grapple_min_active_speed,
		grapple_initial_launch_speed * grapple_active_speed_ratio
	)
	grapple_release_timer = 0.0
	grapple_low_speed_timer = 0.0
	grapple_spent_timer = 0.0

func _update_grapple_attachment_tracking(delta: float) -> void:
	if grapple_state != GrappleState.FIRING or grapple_attached:
		return

	grapple_release_timer += delta

	if grapple_attachment_state == GrappleAttachmentState.UNARMED:
		var travel_distance := grapple_tip_position.distance_to(grapple_start_position)
		if grapple_release_timer >= grapple_arm_delay or travel_distance >= grapple_arm_distance:
			grapple_attachment_state = GrappleAttachmentState.ACTIVE

	if grapple_attachment_state == GrappleAttachmentState.ACTIVE:
		if grapple_tip_velocity.length() < grapple_active_speed_threshold:
			grapple_low_speed_timer += delta
		else:
			grapple_low_speed_timer = 0.0

		if grapple_low_speed_timer >= grapple_low_speed_grace:
			_mark_grapple_spent()
	elif grapple_attachment_state == GrappleAttachmentState.SPENT:
		grapple_spent_timer += delta

func _should_retract_unattached_grapple() -> bool:
	if grapple_attached:
		return false
	if grapple_release_timer >= grapple_max_unattached_time:
		return true
	return (
		grapple_attachment_state == GrappleAttachmentState.SPENT
		and grapple_spent_timer >= grapple_spent_retract_delay
	)

func _can_attach_grapple() -> bool:
	return grapple_attachment_state == GrappleAttachmentState.ACTIVE

func _mark_grapple_spent() -> void:
	if grapple_attachment_state == GrappleAttachmentState.SPENT:
		return
	grapple_attachment_state = GrappleAttachmentState.SPENT
	grapple_spent_timer = 0.0

func _handle_non_attaching_collision(collision_point: Vector2, collision_normal: Vector2 = Vector2.ZERO) -> void:
	grapple_tip_position = collision_point
	if collision_normal.length() > 0.001:
		var into_surface_speed := grapple_tip_velocity.dot(-collision_normal)
		if into_surface_speed > 0.0:
			grapple_tip_velocity += collision_normal * into_surface_speed
	else:
		grapple_tip_velocity = Vector2.ZERO
	_mark_grapple_spent()

func _check_grapple_collision(previous_tip: Vector2, new_tip: Vector2) -> void:
	if not grapple_raycast:
		return

	grapple_raycast.global_position = previous_tip
	grapple_raycast.target_position = new_tip - previous_tip

	# A shot can cross an interaction Area2D before reaching level geometry.
	# Skip those volumes within the same cast instead of attaching to invisible
	# prompts or allowing them to hide a valid surface behind them.
	for _skipped_collider in range(8):
		grapple_raycast.force_raycast_update()
		if not grapple_raycast.is_colliding():
			return

		var collider := grapple_raycast.get_collider()
		if not _is_valid_hookshot_collider(collider):
			if collider is CollisionObject2D:
				grapple_raycast.add_exception(collider as CollisionObject2D)
				continue
			return

		var surface_hit := _resolve_grapple_surface(
			previous_tip,
			new_tip,
			collider,
			grapple_raycast.get_collision_point(),
			grapple_raycast.get_collision_normal()
		)
		var surface_point: Vector2 = surface_hit.position
		var surface_normal: Vector2 = surface_hit.normal
		var surface_collider: Object = surface_hit.collider

		if not _can_attach_grapple():
			_handle_non_attaching_collision(
				surface_point,
				surface_normal
			)
			_update_active_grapple_visuals()
			return

		if _notify_grapple_collider(collider):
			grapple_tip_position = surface_point
			_begin_grapple_retract()
			_update_active_grapple_visuals()
			return
		grapple_attached = true
		grapple_attachment_state = GrappleAttachmentState.SPENT
		grapple_attach_position = surface_point
		grapple_collision_normal = surface_normal
		_capture_grapple_target(surface_collider)

		grapple_tip_position = grapple_attach_position
		grapple_tip_velocity = Vector2.ZERO
		grapple_state = GrappleState.ATTACHED
		AudioManager.play_sfx(&"grapple_connect")
		if not hookshot_enabled:
			AudioManager.play_loop(&"grapple_hanging")

		current_rope_length = clamp(
			get_grapple_origin_global_position().distance_to(grapple_attach_position),
			rope_min_length,
			grapple_max_distance
		)

		_update_active_grapple_visuals()
		return

func _resolve_grapple_surface(
	previous_tip: Vector2,
	new_tip: Vector2,
	collider: Object,
	raw_point: Vector2,
	raw_normal: Vector2
) -> Dictionary:
	var result := {
		"position": raw_point,
		"normal": raw_normal,
		"collider": collider,
	}
	var collider_node := collider as Node
	if not collider_node:
		return result

	var uses_capture_surface := collider_node is TileMapLayer
	if collider_node is CollisionObject2D:
		uses_capture_surface = (
			collider_node as CollisionObject2D
		).get_collision_layer_value(3)
	if not uses_capture_surface:
		return result

	var shot_direction := (new_tip - previous_tip).normalized()
	if shot_direction.length_squared() <= 0.001:
		return result

	var query := PhysicsRayQueryParameters2D.create(
		previous_tip,
		raw_point + shot_direction * grapple_surface_resolve_depth,
		grapple_solid_surface_mask
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if player:
		query.exclude = [player.get_rid()]
	var solid_hit := get_world_2d().direct_space_state.intersect_ray(query)
	if solid_hit.is_empty():
		return result

	result.position = solid_hit.position
	result.normal = solid_hit.normal
	result.collider = solid_hit.collider
	return result

func _is_valid_hookshot_collider(collider: Object) -> bool:
	var collider_node := collider as Node
	if not collider_node:
		return false

	var target_owner := collider_node
	if collider_node is HurtboxComponent and (collider_node as HurtboxComponent).hurtbox_owner:
		target_owner = (collider_node as HurtboxComponent).hurtbox_owner
	elif collider_node.get_parent() and collider_node.get_parent().is_in_group("enemies"):
		target_owner = collider_node.get_parent()

	if target_owner.is_in_group("enemies"):
		return true

	# TileMapLayer owns the chamber's tile collision without inheriting
	# CollisionObject2D, so it must be recognized explicitly as level geometry.
	if collider_node is TileMapLayer:
		return true

	# Solid layer-one bodies are traversable level geometry. Areas are excluded
	# unless they explicitly advertise grapple behavior below.
	if collider_node is CollisionObject2D and not collider_node is Area2D:
		if (
			(collider_node as CollisionObject2D).get_collision_layer_value(1)
			or (collider_node as CollisionObject2D).get_collision_layer_value(3)
		):
			return true

	if collider_node.has_method("activate_from_grapple"):
		return true

	var parent := collider_node.get_parent()
	return parent != null and parent.has_method("activate_from_grapple")

func _capture_grapple_target(collider: Object) -> void:
	grapple_target = collider as Node2D
	if grapple_target:
		grapple_target_local_position = grapple_target.to_local(grapple_attach_position)

	grapple_strike_launch_range_ratio = 0.0
	hookshot_enemy_hurtbox = collider as HurtboxComponent
	if not hookshot_enemy_hurtbox and collider is Node:
		var collider_node := collider as Node
		if collider_node.is_in_group("enemies"):
			hookshot_enemy_hurtbox = collider_node.get_node_or_null("Hurtbox") as HurtboxComponent
		elif collider_node.get_parent() and collider_node.get_parent().is_in_group("enemies"):
			hookshot_enemy_hurtbox = collider_node.get_parent().get_node_or_null("Hurtbox") as HurtboxComponent
	if hookshot_enemy_hurtbox:
		grapple_strike_launch_range_ratio = clampf(
			grapple_start_position.distance_to(grapple_attach_position)
			/ maxf(grapple_max_distance, 1.0),
			0.0,
			1.0
		)

	hookshot_previous_distance = INF
	hookshot_stall_timer = 0.0
	enemy_grapple_ready = false
	enemy_grapple_hold_timer = 0.0
	grapple_strike_active = false
	grapple_strike_at_strike_distance = false

func _update_moving_grapple_target() -> void:
	if grapple_target and is_instance_valid(grapple_target):
		grapple_attach_position = grapple_target.to_global(grapple_target_local_position)
	else:
		grapple_target = null

func _notify_grapple_collider(collider: Object) -> bool:
	if not collider:
		return false

	if collider.has_method("activate_from_grapple"):
		return bool(collider.activate_from_grapple(player))

	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent and parent.has_method("activate_from_grapple"):
			return bool(parent.activate_from_grapple(player))
	return false

# ===============================
# ACTIVE GRAPPLE VISUAL UPDATE
# ===============================
func _update_active_grapple_visuals() -> bool:
	if not active_rope_line or not active_needle_sprite or not active_grapple_root:
		return false

	var origin_global := get_grapple_origin_global_position()
	var tip_global := grapple_tip_position
	if not origin_global.is_finite() or not tip_global.is_finite():
		active_rope_line.points = PackedVector2Array()
		active_grapple_root.visible = false
		active_needle_sprite.visible = false
		return false

	var origin_local := active_grapple_root.to_local(origin_global)
	var tip_local := active_grapple_root.to_local(tip_global)
	var direction_local := tip_local - origin_local

	active_needle_sprite.flip_h = false
	active_needle_sprite.flip_v = false

	if direction_local.length() > 0.01:
		active_needle_sprite.rotation = direction_local.angle() + needle_rotation_offset

	var attach_offset := Vector2.ZERO
	if active_needle_attach_point:
		attach_offset = Vector2(
			active_needle_attach_point.position.x * active_needle_sprite.scale.x,
			active_needle_attach_point.position.y * active_needle_sprite.scale.y
		).rotated(active_needle_sprite.rotation)

	active_needle_sprite.position = tip_local - attach_offset

	var line_points := PackedVector2Array()

	# While the needle is still flying, render only the distance it has
	# actually travelled. The simulation keeps a full slack-rope chain ready
	# for attachment, but exposing that chain here flashes a 360 px line on
	# the first launch frame.
	if grapple_state == GrappleState.FIRING:
		line_points.append(active_rope_line.to_local(origin_global))
		line_points.append(active_rope_line.to_local(tip_global))
	elif active_rope_points.size() > 1:
		for p in active_rope_points:
			line_points.append(active_rope_line.to_local(p))
	else:
		line_points.append(active_rope_line.to_local(origin_global))
		line_points.append(active_rope_line.to_local(tip_global))

	active_rope_line.points = line_points
	return true

func sync_grapple_origin_after_player_move() -> void:
	if grapple_state == GrappleState.STOWED:
		return

	if active_rope_points.size() > 0:
		var origin := get_grapple_origin_global_position()
		active_rope_points[0] = origin
		if active_rope_previous_points.size() > 0:
			active_rope_previous_points[0] = origin

	_update_active_grapple_visuals()
	
# ===============================
# Handle Rope Climbing
# ===============================
func _handle_rope_climb(delta: float) -> void:
	if grapple_state != GrappleState.ATTACHED:
		return

	if not player:
		return

	var climb_direction: float = 0.0

	if Input.is_action_pressed("move_up"):
		climb_direction -= 1.0

	if Input.is_action_pressed("move_down"):
		climb_direction += 1.0

	if climb_direction == 0.0:
		return

	current_rope_length += climb_direction * rope_climb_speed * delta
	current_rope_length = clamp(current_rope_length, rope_min_length, grapple_max_distance)

	print("Rope length: ", current_rope_length)
	
# ===============================
# PLAYER ROPE LIMIT
# ===============================
func apply_grapple_velocity(delta: float) -> void:
	if not enforce_player_rope_limit:
		return

	if not player:
		return

	if grapple_state != GrappleState.ATTACHED:
		return

	if hookshot_enabled:
		_apply_hookshot_pull(delta)
		return

	var origin: Vector2 = get_grapple_origin_global_position()
	var from_anchor: Vector2 = origin - grapple_attach_position
	var distance: float = from_anchor.length()

	if distance <= 0.001:
		return

	var max_allowed: float = current_rope_length + rope_limit_slack
	var rope_dir: Vector2 = from_anchor.normalized()
	var tangent: Vector2 = Vector2(-rope_dir.y, rope_dir.x)

	# Grounded behavior:
	# walk normally while slack exists, but rope becomes a wall at max length.
	if player.is_on_floor():
		if distance > max_allowed:
			var outward_speed: float = player.velocity.dot(rope_dir)
			if outward_speed > 0.0:
				player.velocity -= rope_dir * outward_speed
		return

	_apply_base_idle_swing_resistance(delta, tangent)

	# Airborne behavior:
	# no constraint until rope is taut.
	if distance <= max_allowed:
		return

	# Remove velocity moving farther away from anchor.
	var outward_speed: float = player.velocity.dot(rope_dir)
	if outward_speed > 0.0:
		player.velocity -= rope_dir * outward_speed

	# Clamp sideways swing so base grapple cannot build big momentum.
	var tangent_speed: float = player.velocity.dot(tangent)
	tangent_speed = clamp(tangent_speed, -rope_tangent_max_speed, rope_tangent_max_speed)
	tangent_speed *= pow(rope_tangent_damping, delta * 60.0)

	var inward_speed: float = min(player.velocity.dot(rope_dir), 0.0)
	player.velocity = tangent * tangent_speed + rope_dir * inward_speed

	# Gentle inward correction if already stretched too far.
	var excess: float = distance - max_allowed
	var pull_multiplier: float = 1.0
	if player.has_method("get_momentum_grapple_pull_multiplier"):
		pull_multiplier = player.get_momentum_grapple_pull_multiplier()
	player.velocity -= rope_dir * excess * rope_limit_pull_strength * pull_multiplier * delta

func _apply_hookshot_pull(delta: float) -> void:
	_update_moving_grapple_target()
	if hold_enemy_grapple_ready(delta):
		return

	var destination := grapple_attach_position
	if has_enemy_grapple_target():
		destination = _get_enemy_grapple_standoff_position()
	elif grapple_collision_normal.length_squared() > 0.001:
		var surface_normal := grapple_collision_normal.normalized()
		destination += surface_normal * _get_hookshot_surface_clearance(surface_normal)

	var to_destination := destination - player.global_position
	var distance := to_destination.length()
	if distance <= hookshot_arrival_distance:
		_finish_hookshot_pull(true)
		return
	if _is_hookshot_pull_blocked(to_destination.normalized()):
		_finish_hookshot_pull(false)
		return

	if hookshot_previous_distance == INF or distance <= hookshot_previous_distance - hookshot_min_progress:
		hookshot_previous_distance = distance
		hookshot_stall_timer = 0.0
	else:
		hookshot_stall_timer += delta

	if hookshot_stall_timer >= hookshot_stall_time:
		_finish_hookshot_pull(false)
		return

	player.velocity = to_destination.normalized() * minf(hookshot_pull_speed, distance / maxf(delta, 0.001))

func _is_hookshot_pull_blocked(pull_direction: Vector2) -> bool:
	if not player or pull_direction.length_squared() <= 0.001:
		return false

	# Slide collisions describe the movement attempted on the previous physics
	# step. Release as soon as the hookshot is still pulling into one of those
	# surfaces; otherwise platform seams can alternate normals and gutter the
	# player indefinitely.
	for collision_index in player.get_slide_collision_count():
		var collision := player.get_slide_collision(collision_index)
		if collision and pull_direction.dot(collision.get_normal()) < -0.2:
			return true
	return false

func _get_hookshot_surface_clearance(surface_normal: Vector2) -> float:
	var clearance := hookshot_surface_offset
	if not player:
		return clearance

	var player_shape := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not player_shape or not player_shape.shape:
		return clearance

	var shape_rect := player_shape.shape.get_rect()
	var corners := [
		shape_rect.position,
		shape_rect.position + Vector2(shape_rect.size.x, 0.0),
		shape_rect.position + Vector2(0.0, shape_rect.size.y),
		shape_rect.end,
	]
	var minimum_projection := INF
	for corner in corners:
		var corner_from_player := player_shape.to_global(corner) - player.global_position
		minimum_projection = minf(minimum_projection, corner_from_player.dot(surface_normal))

	if minimum_projection < INF:
		clearance = maxf(clearance, -minimum_projection + hookshot_surface_padding)
	return clearance

func _finish_hookshot_pull(reached_destination := true) -> void:
	player.velocity = Vector2.ZERO
	if reached_destination and has_enemy_grapple_target():
		mark_enemy_grapple_ready()
		return
	_begin_grapple_retract()

func _apply_base_idle_swing_resistance(delta: float, tangent: Vector2) -> void:
	if absf(Input.get_axis("move_left", "move_right")) > 0.05:
		return

	var tangent_speed := player.velocity.dot(tangent)
	if absf(tangent_speed) <= 0.001:
		return

	var decay_weight := 1.0 - exp(-rope_idle_swing_lerp_speed * delta)
	var damped_speed := lerpf(tangent_speed, 0.0, decay_weight)
	if absf(damped_speed) < rope_idle_swing_stop_speed:
		damped_speed = 0.0

	player.velocity += tangent * (damped_speed - tangent_speed)

# ===============================
# MAIN ABILITY LOOP
# ===============================
func thread_mechanic(delta: float) -> void:
	if action_anim_lock_timer > 0.0:
		action_anim_lock_timer -= delta

	# Always check climbing while grapple is attached.
	_handle_rope_climb(delta)

	if InputMap.has_action(grapple_input_action):
		if Input.is_action_just_pressed(grapple_input_action):
			if grapple_state == GrappleState.STOWED:
				if not player.has_method("spend_action_points") or player.spend_action_points(1):
					_start_grapple_fire()
					if player.has_method("report_momentum_action"):
						player.report_momentum_action(&"Grapple")
			else:
				_begin_grapple_retract()

	match grapple_state:
		GrappleState.STOWED:
			pass

		GrappleState.FIRING:
			var previous_tip := grapple_tip_position

			_simulate_active_rope(delta, true)
			_update_grapple_attachment_tracking(delta)
			_check_grapple_collision(previous_tip, grapple_tip_position)

			var distance := grapple_tip_position.distance_to(grapple_start_position)
			if not grapple_attached and distance >= grapple_max_distance:
				_mark_grapple_spent()

			if not grapple_attached and _should_retract_unattached_grapple():
				grapple_tip_velocity = Vector2.ZERO
				_begin_grapple_retract()

			_update_active_grapple_visuals()

		GrappleState.ATTACHED:
			_update_moving_grapple_target()
			grapple_tip_position = grapple_attach_position
			grapple_tip_velocity = Vector2.ZERO

			_simulate_active_rope(delta, true)
			_update_active_grapple_visuals()

		GrappleState.RETRACTING:
			_retract_active_rope(delta)
			_update_active_grapple_visuals()

func _retract_active_rope(delta: float) -> void:
	var origin: Vector2 = get_grapple_origin_global_position()

	grapple_tip_position = grapple_tip_position.move_toward(origin, grapple_retract_speed * delta)

	if active_rope_points.size() > 1:
		for i in range(active_rope_points.size()):
			var t: float = float(i) / float(active_rope_points.size() - 1)
			var target: Vector2 = origin.lerp(grapple_tip_position, t)
			active_rope_points[i] = active_rope_points[i].move_toward(target, grapple_retract_speed * delta)
			active_rope_previous_points[i] = active_rope_points[i]

	if grapple_tip_position.distance_to(origin) <= 8.0:
		_reset_active_grapple_visuals()

func process_passive(_delta: float) -> void:
	pass

func on_ability_cooldown_complete() -> void:
	pass
