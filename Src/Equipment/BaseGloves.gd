class_name BaseGloves
extends Node2D

var player: CharacterBody2D = null

# ===============================
# NODES
# ===============================
@onready var equipment: Node2D = $Equipment
@onready var animation_player: AnimationPlayer = $Equipment/AnimationPlayer

@onready var right_hand_anchor: Marker2D = $Equipment/RightHandAnchor
@onready var rope_hang_anchor: Node2D = $Equipment/RightHandAnchor/RopeHangAnchor
@onready var grapple_origin: Marker2D = $Equipment/RightHandAnchor/GrappleOrigin

@onready var active_grapple_root: Node2D = $Equipment/ActiveGrappleRoot
@onready var active_rope_line: Line2D = $Equipment/ActiveGrappleRoot/ActiveRopeLine
@onready var active_needle_sprite: Sprite2D = $Equipment/ActiveGrappleRoot/ActiveNeedleSprite
@onready var active_needle_attach_point: Marker2D = $Equipment/ActiveGrappleRoot/ActiveNeedleSprite/ActiveNeedleAttachPoint

# ===============================
# GRAPPLE SETTINGS
# ===============================
@export var grapple_input_action := "Grapple"
@export var grapple_speed := 1300.0
@export var grapple_max_distance := 360.0
@export var grapple_retract_speed := 1800.0
@export var needle_rotation_offset := -PI / 2.0

var action_anim_lock_timer := 0.0
@export var grapple_fire_anim_lock_time := 0.14

# ===============================
# GRAPPLE STATE
# ===============================
enum GrappleState {
	STOWED,
	FIRING,
	EXTENDED,
	RETRACTING
}

var grapple_state: GrappleState = GrappleState.STOWED
var grapple_direction := Vector2.RIGHT
var grapple_start_position := Vector2.ZERO
var grapple_tip_position := Vector2.ZERO

# ===============================
# EQUIPMENT LIFECYCLE
# ===============================
func _ready() -> void:
	visible = true
	_reset_active_grapple_visuals()
	print("✅ BaseGloves ready")

func on_equipped() -> void:
	visible = true
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

	# Do not let idle/run/jump overwrite the grapple fire animation.
	if action_anim_lock_timer > 0.0 and not anim_name.begins_with("equip_grapple"):
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

# ===============================
# GRAPPLE HELPERS
# ===============================
func get_grapple_origin_global_position() -> Vector2:
	if grapple_origin:
		return grapple_origin.global_position

	if player:
		return player.global_position

	return global_position

func _hide_stowed_rope() -> void:
	if rope_hang_anchor:
		rope_hang_anchor.visible = false

func _show_stowed_rope() -> void:
	if rope_hang_anchor:
		rope_hang_anchor.visible = true

		if rope_hang_anchor.has_method("reset_rope"):
			rope_hang_anchor.reset_rope()

func _reset_active_grapple_visuals() -> void:
	grapple_state = GrappleState.STOWED

	if active_grapple_root:
		active_grapple_root.visible = false

	if active_rope_line:
		active_rope_line.points = PackedVector2Array()

	if active_needle_sprite:
		active_needle_sprite.visible = false

	_show_stowed_rope()

func _start_grapple_fire() -> void:
	grapple_start_position = get_grapple_origin_global_position()
	grapple_tip_position = grapple_start_position

	var aim_target := get_global_mouse_position()
	grapple_direction = (aim_target - grapple_start_position).normalized()

	if grapple_direction == Vector2.ZERO:
		grapple_direction = Vector2.RIGHT

	grapple_state = GrappleState.FIRING

	_hide_stowed_rope()

	if active_grapple_root:
		active_grapple_root.visible = true

	if active_needle_sprite:
		active_needle_sprite.visible = true
		active_needle_sprite.global_position = grapple_tip_position

	_play_grapple_fire_animation()
	_update_active_grapple_visuals()

func _begin_grapple_retract() -> void:
	if grapple_state != GrappleState.STOWED:
		grapple_state = GrappleState.RETRACTING

func _update_active_grapple_visuals() -> void:
	if not active_rope_line or not active_needle_sprite:
		return

	var origin_global := get_grapple_origin_global_position()
	var tip_global := grapple_tip_position

	# Convert into ActiveGrappleRoot local space.
	var origin_local := active_grapple_root.to_local(origin_global)
	var tip_local := active_grapple_root.to_local(tip_global)
	var direction_local := tip_local - origin_local

	# Do NOT manually flip the needle.
	active_needle_sprite.flip_h = false
	active_needle_sprite.flip_v = false

	# Rotate locally so parent left/right flipping behaves naturally.
	if direction_local.length() > 0.01:
		active_needle_sprite.rotation = direction_local.angle() + needle_rotation_offset

	# First place the needle near the grapple tip.
	active_needle_sprite.position = tip_local

	# Then correct position so ActiveNeedleAttachPoint lands exactly on tip.
	if active_needle_attach_point:
		var attach_point_local := active_grapple_root.to_local(active_needle_attach_point.global_position)
		var correction := tip_local - attach_point_local
		active_needle_sprite.position += correction

	# Now draw rope from grapple origin to the actual attach point.
	var rope_end_global := tip_global
	if active_needle_attach_point:
		rope_end_global = active_needle_attach_point.global_position

	active_rope_line.points = PackedVector2Array([
		active_rope_line.to_local(origin_global),
		active_rope_line.to_local(rope_end_global)
	])

# ===============================
# ACTIVE ABILITY
# ===============================
func thread_mechanic(delta: float) -> void:
	if action_anim_lock_timer > 0.0:
		action_anim_lock_timer -= delta

	if InputMap.has_action(grapple_input_action):
		if Input.is_action_just_pressed(grapple_input_action):
			if grapple_state == GrappleState.STOWED:
				_start_grapple_fire()
			else:
				_begin_grapple_retract()

		if Input.is_action_just_released(grapple_input_action):
			_begin_grapple_retract()

	match grapple_state:
		GrappleState.STOWED:
			pass

		GrappleState.FIRING:
			grapple_tip_position += grapple_direction * grapple_speed * delta

			var distance := grapple_tip_position.distance_to(grapple_start_position)
			if distance >= grapple_max_distance:
				grapple_state = GrappleState.EXTENDED

			_update_active_grapple_visuals()

		GrappleState.EXTENDED:
			_update_active_grapple_visuals()

		GrappleState.RETRACTING:
			var origin := get_grapple_origin_global_position()
			grapple_tip_position = grapple_tip_position.move_toward(origin, grapple_retract_speed * delta)

			if grapple_tip_position.distance_to(origin) <= 8.0:
				_reset_active_grapple_visuals()
			else:
				_update_active_grapple_visuals()

func process_passive(_delta: float) -> void:
	pass

func on_ability_cooldown_complete() -> void:
	pass
