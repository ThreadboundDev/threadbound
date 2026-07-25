class_name BaseGloves
extends Node2D

const AimHelperScript := preload("res://Src/Global/aim_helper.gd")

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
@export_flags_2d_physics var grapple_collision_mask := 1

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
@export var hookshot_arrival_damage := 10
@export var hookshot_hitstun := 0.10

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

	if use_diagonal:
		play_equipment_anim("equip_grapple_fire_diagonal")

		if player and player.has_node("Player Animation"):
			var body_anim: AnimatedSprite2D = player.get_node("Player Animation")
			if body_anim.sprite_frames.has_animation("Grapple_Diagonal"):
				body_anim.play("Grapple_Diagonal")
	else:
		play_equipment_anim("equip_grapple_fire_straight")

		if player and player.has_node("Player Animation"):
			var body_anim: AnimatedSprite2D = player.get_node("Player Animation")
			if body_anim.sprite_frames.has_animation("Grapple_Horizontal"):
				body_anim.play("Grapple_Horizontal")

func play_attack_follow_pose(_direction: Vector2, body_anim: String = "") -> void:
	action_anim_lock_timer = attack_follow_anim_lock_time
	var attack_anim := "attack_ground" if body_anim == "Attack" or body_anim == "Neutral_Special_Attack" else "attack_air"
	if animation_player and animation_player.has_animation(attack_anim):
		play_equipment_anim(attack_anim)

func _is_action_equipment_anim(anim_name: String) -> bool:
	return anim_name == "equip_dash" or anim_name.begins_with("equip_grapple") or anim_name.begins_with("attack_")

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
	play_equipment_anim("equip_idle")

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

func is_base_grapple_restricting() -> bool:
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
	# Rebuild exceptions every throw so temporary hitboxes and replaced player
	# collision areas can never be mistaken for a grapple target.
	_reset_grapple_raycast_exceptions()
	grapple_start_position = get_grapple_origin_global_position()
	grapple_tip_position = grapple_start_position

	grapple_direction = AimHelperScript.get_aim_direction(
		self,
		grapple_start_position,
		grapple_direction
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
		active_grapple_root.visible = true

	if active_needle_sprite:
		active_needle_sprite.visible = true
		active_needle_sprite.global_position = grapple_tip_position

	AudioManager.play_sfx(&"grapple")
	_play_grapple_fire_animation()
	_update_active_grapple_visuals()

func _begin_grapple_retract() -> void:
	if grapple_state != GrappleState.STOWED:
		AudioManager.stop_loop(&"grapple_hanging")
		grapple_state = GrappleState.RETRACTING
		grapple_attachment_state = GrappleAttachmentState.SPENT
		grapple_attached = false
		grapple_tip_velocity = Vector2.ZERO

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
		if hookshot_enabled and not _is_valid_hookshot_collider(collider):
			if collider is CollisionObject2D:
				grapple_raycast.add_exception(collider as CollisionObject2D)
				continue
			return

		if not _can_attach_grapple():
			_handle_non_attaching_collision(
				grapple_raycast.get_collision_point(),
				grapple_raycast.get_collision_normal()
			)
			_update_active_grapple_visuals()
			return

		_notify_grapple_collider(collider)
		grapple_attached = true
		grapple_attachment_state = GrappleAttachmentState.SPENT
		grapple_attach_position = grapple_raycast.get_collision_point()
		grapple_collision_normal = grapple_raycast.get_collision_normal()
		_capture_grapple_target(collider)

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
		if (collider_node as CollisionObject2D).get_collision_layer_value(1):
			return true

	if collider_node.has_method("activate_from_grapple"):
		return true

	var parent := collider_node.get_parent()
	return parent != null and parent.has_method("activate_from_grapple")

func _capture_grapple_target(collider: Object) -> void:
	grapple_target = collider as Node2D
	if grapple_target:
		grapple_target_local_position = grapple_target.to_local(grapple_attach_position)

	hookshot_enemy_hurtbox = collider as HurtboxComponent
	if not hookshot_enemy_hurtbox and collider is Node:
		var collider_node := collider as Node
		if collider_node.is_in_group("enemies"):
			hookshot_enemy_hurtbox = collider_node.get_node_or_null("Hurtbox") as HurtboxComponent
		elif collider_node.get_parent() and collider_node.get_parent().is_in_group("enemies"):
			hookshot_enemy_hurtbox = collider_node.get_parent().get_node_or_null("Hurtbox") as HurtboxComponent

	hookshot_previous_distance = INF
	hookshot_stall_timer = 0.0

func _update_moving_grapple_target() -> void:
	if grapple_target and is_instance_valid(grapple_target):
		grapple_attach_position = grapple_target.to_global(grapple_target_local_position)
	else:
		grapple_target = null

func _notify_grapple_collider(collider: Object) -> void:
	if not collider:
		return

	if collider.has_method("activate_from_grapple"):
		collider.activate_from_grapple(player)
		return

	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent and parent.has_method("activate_from_grapple"):
			parent.activate_from_grapple(player)

# ===============================
# ACTIVE GRAPPLE VISUAL UPDATE
# ===============================
func _update_active_grapple_visuals() -> void:
	if not active_rope_line or not active_needle_sprite or not active_grapple_root:
		return

	var origin_global := get_grapple_origin_global_position()
	var tip_global := grapple_tip_position

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

	if active_rope_points.size() > 1:
		for p in active_rope_points:
			line_points.append(active_rope_line.to_local(p))
	else:
		line_points.append(active_rope_line.to_local(origin_global))
		line_points.append(active_rope_line.to_local(tip_global))

	active_rope_line.points = line_points

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

	var destination := grapple_attach_position
	if grapple_collision_normal.length_squared() > 0.001:
		var surface_normal := grapple_collision_normal.normalized()
		destination += surface_normal * _get_hookshot_surface_clearance(surface_normal)

	var to_destination := destination - player.global_position
	var distance := to_destination.length()
	if distance <= hookshot_arrival_distance:
		_finish_hookshot_pull()
		return

	if hookshot_previous_distance == INF or distance <= hookshot_previous_distance - hookshot_min_progress:
		hookshot_previous_distance = distance
		hookshot_stall_timer = 0.0
	else:
		hookshot_stall_timer += delta

	if hookshot_stall_timer >= hookshot_stall_time:
		_finish_hookshot_pull()
		return

	player.velocity = to_destination.normalized() * minf(hookshot_pull_speed, distance / maxf(delta, 0.001))

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

func _finish_hookshot_pull() -> void:
	player.velocity = Vector2.ZERO
	_apply_hookshot_arrival_hit()
	_begin_grapple_retract()

func _apply_hookshot_arrival_hit() -> void:
	if not hookshot_enemy_hurtbox or not is_instance_valid(hookshot_enemy_hurtbox):
		return

	var damage := DamageData.new()
	damage.amount = hookshot_arrival_damage
	damage.hitstun = hookshot_hitstun
	damage.hit_pause = 0.03
	damage.source = player
	damage.hit_position = grapple_attach_position
	hookshot_enemy_hurtbox.receive_hit(damage)

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
