extends CharacterBody2D

signal action_points_changed(current: int, maximum: int)
signal momentum_changed(value: float)
signal momentum_state_changed(state: StringName, flow_active: bool)
signal save_point_seated(player: CharacterBody2D)
signal stat_upgraded(stat_id: StringName)

const GAME_OVER_OVERLAY_SCENE := preload("res://Src/UI/game_over_overlay.tscn")
const PAUSE_MENU_SCENE := preload("res://Src/UI/PauseMenu/pause_menu.tscn")
const GAME_MENU_SCENE := preload("res://Src/UI/GameMenu/game_menu.tscn")
const RADIAL_MENU_SCENE := preload("res://Src/UI/radial_menu.tscn")
const DEMO_MESSAGE_BOX_SCENE := preload("res://Src/UI/demo_message_box.tscn")
const NEUTRAL_SPECIAL_VFX_SCENE := preload("res://Src/VFX/neutral_special_vfx.tscn")
const DASH_IFRAME_VFX_SCENE := preload("res://Src/VFX/dash_iframe_vfx.tscn")
const PAUSE_OPEN_BLOCK_UNTIL_META := &"pause_open_block_until_msec"
const AimHelperScript := preload("res://Src/Global/aim_helper.gd")
const MEDITATION_SHADER := preload("res://Src/Characters/Player/save_point_meditation.gdshader")
const PATTERN_OVERLAY_SHADER := preload("res://Src/Characters/Player/player_pattern_overlay.gdshader")
const SIT_ANIMATION := &"Sit"
const HURT_ANIMATION := &"Hurt"
const STATIONARY_ATTACK_SUFFIX := "_Stationary"
const BACKPEDAL_ATTACK_SUFFIX := "_Backpedal"
const STATIONARY_ATTACK_MIN_HORIZONTAL_SPEED := 5.0
const LEDGE_CLIMB_ANIMATION := &"Ledge_Climb"
const NEUTRAL_SPECIAL_CHARGE_FIRST_FRAME := 8
const NEUTRAL_SPECIAL_WEAPON_ANCHORS := [
	Vector2(-72.0, -108.0),
	Vector2(-70.0, -108.0),
	Vector2(-68.0, -107.0),
	Vector2(-66.0, -108.0),
	Vector2(-64.0, -108.0),
	Vector2(-62.0, -108.0),
	Vector2(-60.0, -108.0),
	Vector2(-42.0, -109.0),
	Vector2(-13.0, -122.0),
	Vector2(126.0, -7.0),
]
const NEUTRAL_SPECIAL_GROUND_CONTACT := Vector2(134.0, 109.0)
const ATTACK_PROFILE_BASE_DAMAGE := 25.0
const ATTACK_PROFILE_BASE_KNOCKBACK := 260.0
const ATTACK_PROFILE_BASIC := {
	&"damage": 25.0,
	&"hitstun": 0.16,
	&"knockback": 260.0,
	&"hit_pause": 0.040,
	&"screen_shake": 2.25,
}
const ATTACK_PROFILE_MOVING_FINISHER_FIRST := {
	&"damage": 18.0,
	&"hitstun": 0.14,
	&"knockback": 220.0,
	&"hit_pause": 0.030,
	&"screen_shake": 1.8,
}
const ATTACK_PROFILE_MOVING_FINISHER_SECOND := {
	&"damage": 25.0,
	&"hitstun": 0.20,
	&"knockback": 300.0,
	&"hit_pause": 0.045,
	&"screen_shake": 3.0,
}
const ATTACK_PROFILE_STATIONARY_FIRST := {
	&"damage": 23.0,
	&"hitstun": 0.18,
	&"knockback": 270.0,
	&"hit_pause": 0.040,
	&"screen_shake": 2.2,
}
const ATTACK_PROFILE_STATIONARY_SECOND := {
	&"damage": 30.0,
	&"hitstun": 0.25,
	&"knockback": 340.0,
	&"hit_pause": 0.055,
	&"screen_shake": 3.5,
}
const ATTACK_PROFILE_BACKPEDAL_OPENER := {
	&"damage": 21.0,
	&"hitstun": 0.18,
	&"knockback": 290.0,
	&"hit_pause": 0.040,
	&"screen_shake": 2.4,
}
const ATTACK_PROFILE_BACKPEDAL_FINISHER_FIRST := {
	&"damage": 17.0,
	&"hitstun": 0.14,
	&"knockback": 235.0,
	&"hit_pause": 0.030,
	&"screen_shake": 2.4,
}
const ATTACK_PROFILE_BACKPEDAL_FINISHER_SECOND := {
	&"damage": 23.0,
	&"hitstun": 0.20,
	&"knockback": 310.0,
	&"hit_pause": 0.045,
	&"screen_shake": 2.4,
}
const ATTACK_PROFILE_AIR_FIRST := {
	&"damage": 16.0,
	&"hitstun": 0.14,
	&"knockback": 210.0,
	&"hit_pause": 0.030,
	&"screen_shake": 1.6,
}
const ATTACK_PROFILE_AIR_SECOND := {
	&"damage": 21.0,
	&"hitstun": 0.18,
	&"knockback": 275.0,
	&"hit_pause": 0.040,
	&"screen_shake": 2.4,
}

# ===============================
# NODES
# ===============================
@onready var player_animation: AnimatedSprite2D = $"Player Animation"
@onready var equipment_mount: Node2D = $EquipmentMount
@onready var camera = get_node_or_null("../Camera Master/Camera2D/PhantomCameraHost2D/MainFollowCam")
@onready var glow_sprite: Sprite2D = $GlowSprite
@onready var flow_state_aura: Node = get_node_or_null("FlowStateAura")
@onready var ability_cooldown_timer: Timer = $AbilityCooldownTimer
@onready var health_component: HealthComponent = $HealthComponent as HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox as HurtboxComponent
@onready var attack_hitbox: HitboxComponent = $AttackHitbox as HitboxComponent
@onready var attack_collision_polygon: CollisionPolygon2D = $AttackHitbox/SlashCollisionPolygon
@onready var hit_flash: HitFlashComponent = $HitFlashComponent as HitFlashComponent
@onready var weapon_animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_swing_root: Node2D = $EquipmentMount/AttackSwingRoot
@onready var attack_hitbox_anchor: Node2D = $EquipmentMount/AttackSwingRoot/AttackHitboxAnchor/HitboxTransform
@onready var wall_cling_vfx: AnimatedSprite2D = $WallClingVFX as AnimatedSprite2D

# ===============================
# EQUIPMENT SCENES
# ===============================
@export var base_gloves_scene: PackedScene
@export var player_stats: PlayerStats

# Basic combat resource values for the HUD. Gameplay costs can build on these.
@export_range(1, 9999, 1) var max_health := 100
@export_range(0.0, 5.0, 0.05) var death_reset_delay := 0.45

@export_range(1, 6, 1) var max_action_points := 6:
	set(value):
		max_action_points = clampi(value, 1, 6)
		current_action_points = clampi(current_action_points, 0, max_action_points)
		_sync_hud()
		action_points_changed.emit(current_action_points, max_action_points)

@export_range(0, 6, 1) var current_action_points := 6:
	set(value):
		current_action_points = clampi(value, 0, max_action_points)
		_sync_hud()
		action_points_changed.emit(current_action_points, max_action_points)

@export_range(0.5, 30.0, 0.5) var action_point_recharge_time := 10.0

@export_range(0.0, 100.0, 1.0) var momentum := 0.0:
	set(value):
		momentum = clampf(value, 0.0, 100.0)
		_update_momentum_state()
		_sync_hud()
		_sync_flow_vfx_momentum()
		momentum_changed.emit(momentum)

@export_range(0, 999999, 1) var thread_knot_count := 0:
	set(value):
		thread_knot_count = maxi(0, value)
		_sync_hud()

# ===============================
# MOVEMENT TUNABLES
# ===============================
@export var speed: float = 500.0
@export var air_control_mult: float = 0.9
@export var gravity: float = 2200.0
@export var fall_gravity_multiplier: float = 1.55
@export var jump_cut_gravity_multiplier: float = 2.25
@export var max_fall_speed: float = 1500.0
@export var coyote_time: float = 0.1
@export_range(0.0, 0.5, 0.01) var dash_direction_input_buffer_time := 0.22

@export_group("Movement Animation")
@export_range(0.0, 400.0, 5.0) var jump_apex_velocity_threshold := 140.0
@export_range(0.0, 1.0, 0.01) var landing_animation_duration := 0.28
@export_range(0.5, 1.0, 0.01) var landing_visual_scale_multiplier := 0.88
@export_range(0.5, 1.0, 0.01) var grapple_strike_visual_scale_multiplier := 0.82
@export_range(0.5, 1.0, 0.01) var hurt_visual_scale_multiplier := 0.77
@export var landing_visual_offset := Vector2(0.0, 5.0)

# Base grapple movement while rope is taut.
@export_group("Base Grapple Movement")
@export var base_grapple_steer_speed: float = 120.0
@export var base_grapple_steer_accel: float = 500.0
@export_range(0.4, 1.5, 0.05) var grapple_strike_max_duration := 0.85

# Momentum tuning. Abilities should call report_momentum_action(category) when
# they successfully fire, connect, or otherwise complete a meaningful action.
@export_group("Momentum Gains")
@export var momentum_gain_movement := 0.24
@export var momentum_gain_jump := 1.7
@export var momentum_gain_dash := 7.5
@export var momentum_gain_grapple := 8.0
@export var momentum_gain_attack := 3.2
@export var momentum_gain_pogo := 6.5
@export var momentum_gain_utility := 2.4

@export_group("Special Attacks")
@export_range(1, 6, 1) var neutral_special_action_point_cost := 2
@export_range(1.0, 5.0, 0.05) var neutral_special_damage_multiplier := 2.8
@export_range(0.0, 3.0, 0.01) var neutral_special_windup := 0.45
@export_range(0.01, 1.0, 0.01) var neutral_special_active_time := 0.15
@export_range(0.0, 3.0, 0.01) var neutral_special_recovery := 0.60
@export_range(0.25, 3.0, 0.05) var neutral_special_cooldown_multiplier := 1.55
@export_range(0.0, 0.5, 0.01) var neutral_special_dash_cancel_window := 0.22
@export_range(0.1, 1.0, 0.01) var neutral_special_visual_scale_multiplier := 1.0
@export var neutral_special_visual_offset := Vector2(0.0, -20.0)
@export_range(0.0, 0.58, 0.005) var neutral_special_vfx_lead_time := 0.245
@export_range(64.0, 360.0, 1.0) var neutral_special_aoe_radius := 220.0
@export_range(0.1, 0.9, 0.01) var neutral_special_full_force_radius_ratio := 0.45
@export_range(0.1, 1.0, 0.01) var neutral_special_edge_damage_ratio := 0.55
@export_range(0.05, 1.0, 0.01) var neutral_special_hitstun := 0.30
@export_range(0.05, 1.0, 0.01) var neutral_special_edge_hitstun := 0.24
@export_range(1.0, 3.0, 0.05) var neutral_special_knockback_multiplier := 1.55
@export_range(0.1, 1.0, 0.01) var neutral_special_edge_knockback_ratio := 0.75
@export_range(0.0, 1.0, 0.05) var neutral_special_knockback_lift := 0.30
@export_range(0.0, 0.2, 0.005) var neutral_special_hit_pause := 0.065
@export_range(0.0, 16.0, 0.25) var neutral_special_screen_shake_strength := 7.0
@export_range(0.0, 0.4, 0.01) var neutral_special_screen_shake_duration := 0.14
@export_range(0.5, 1.5, 0.01) var neutral_special_swing_pitch := 1.0
@export_range(0.5, 1.5, 0.01) var neutral_special_impact_pitch := 1.0
@export var momentum_gain_equipment_swap := 1.5
@export var momentum_gain_use_after_swap := 7.0

@export_group("Attack Animation Visuals")
@export_range(0.1, 2.0, 0.05) var ground_combo_forward_visual_scale_multiplier := 1.0
@export_range(0.1, 2.0, 0.05) var ground_combo_2_moving_visual_scale_multiplier := 1.0
@export_range(0.1, 2.0, 0.05) var ground_combo_stationary_visual_scale_multiplier := 1.4
@export_range(0.1, 2.0, 0.05) var ground_combo_backpedal_visual_scale_multiplier := 1.25
@export_range(0.1, 2.0, 0.05) var air_attack_visual_scale_multiplier := 1.0

@export_group("Ground Attack Combo")
@export_range(0.05, 1.0, 0.01) var ground_combo_reset_window := 0.45
@export var ground_combo_1_first_strike_frames := Vector2i(3, 5)
@export var ground_combo_1_second_strike_frames := Vector2i(-1, -1)
@export var ground_combo_2_first_strike_frames := Vector2i(2, 4)
@export var ground_combo_2_second_strike_frames := Vector2i(9, 11)
@export var stationary_combo_2_first_strike_frames := Vector2i(5, 9)
@export var stationary_combo_2_second_strike_frames := Vector2i(10, 15)
@export var backpedal_combo_1_first_strike_frames := Vector2i(3, 11)
@export var backpedal_combo_1_second_strike_frames := Vector2i(-1, -1)
@export var backpedal_combo_2_first_strike_frames := Vector2i(5, 12)
@export var backpedal_combo_2_second_strike_frames := Vector2i(13, 16)
@export_range(45.0, 180.0, 1.0) var ground_combo_hitbox_arc_degrees := 130.0
@export_range(32.0, 300.0, 1.0) var ground_combo_forward_hitbox_radius := 145.0

@export_group("Air Double Attack")
@export var air_attack_first_strike_frames := Vector2i(5, 7)
@export var air_attack_second_strike_frames := Vector2i(16, 18)
@export_range(45.0, 180.0, 1.0) var air_attack_hitbox_arc_degrees := 90.0
@export_range(32.0, 300.0, 1.0) var air_attack_hitbox_radius := 160.0
@export_range(0.5, 1.5, 0.01) var double_attack_first_strike_pitch := 0.92
@export_range(0.5, 1.5, 0.01) var double_attack_second_strike_pitch := 1.08

@export_group("Momentum Rules")
@export var momentum_movement_report_interval := 0.16
@export var momentum_movement_min_speed := 90.0
@export var momentum_movement_reference_speed := 520.0
@export var momentum_movement_stale_duration := 5.0
@export var momentum_stale_duration := 7.0
@export_range(0.0, 1.0, 0.05) var momentum_stale_recovery_fraction := 0.25
@export var momentum_stale_penalty := 1.35
@export var momentum_weave_bonus_per_category := 0.16
@export var momentum_weave_recent_count := 4
@export var momentum_use_after_swap_window := 2.5
@export var momentum_low_threshold := 30.0
@export var momentum_high_threshold := 70.0
@export var flow_state_drain_delay := 1.35
@export var flow_state_drain_base := 3.0
@export var flow_state_drain_growth := 0.72
@export var flow_state_drain_max := 13.0
@export var momentum_damage_loss_per_damage := 8.0
@export var momentum_damage_loss_current_scale := 0.06
@export_range(1.0, 100.0, 1.0) var debug_momentum_fill_amount := 25.0
@export_range(1, 9999, 1) var debug_thread_knots_amount := 25
@export_range(0.01, 1.0, 0.01) var debug_identity_step := 0.1

@export_group("Momentum Multipliers")
@export var momentum_action_point_recharge_low := 0.9
@export var momentum_action_point_recharge_mid := 1.0
@export var momentum_action_point_recharge_high := 1.24
@export var momentum_action_point_recharge_flow := 1.32
@export var momentum_move_speed_low := 0.92
@export var momentum_move_speed_mid := 1.0
@export var momentum_move_speed_high := 1.14
@export var momentum_move_speed_flow := 1.2
@export var momentum_jump_low := 0.94
@export var momentum_jump_mid := 1.0
@export var momentum_jump_high := 1.09
@export var momentum_jump_flow := 1.12
@export var momentum_air_control_low := 0.9
@export var momentum_air_control_mid := 1.0
@export var momentum_air_control_high := 1.16
@export var momentum_air_control_flow := 1.22
@export var momentum_grapple_speed_low := 0.94
@export var momentum_grapple_speed_mid := 1.0
@export var momentum_grapple_speed_high := 1.16
@export var momentum_grapple_speed_flow := 1.22
@export var momentum_grapple_pull_low := 0.92
@export var momentum_grapple_pull_mid := 1.0
@export var momentum_grapple_pull_high := 1.16
@export var momentum_grapple_pull_flow := 1.24
@export var momentum_attack_speed_low := 0.94
@export var momentum_attack_speed_mid := 1.0
@export var momentum_attack_speed_high := 1.10
@export var momentum_attack_speed_flow := 1.15
@export var momentum_attack_damage_low := 1.0
@export var momentum_attack_damage_mid := 1.0
@export var momentum_attack_damage_high := 1.05
@export var momentum_attack_damage_flow := 1.10
@export var momentum_dash_speed_low := 0.95
@export var momentum_dash_speed_mid := 1.0
@export var momentum_dash_speed_high := 1.14
@export var momentum_dash_speed_flow := 1.18
@export var momentum_dash_iframe_low := 0.9
@export var momentum_dash_iframe_mid := 1.0
@export var momentum_dash_iframe_high := 1.15
@export var momentum_dash_iframe_flow := 1.3
@export var momentum_coin_vacuum_low := 0.92
@export var momentum_coin_vacuum_mid := 1.0
@export var momentum_coin_vacuum_high := 1.2
@export var momentum_coin_vacuum_flow := 1.45
@export var momentum_decay_resistance_low := 0.0
@export var momentum_decay_resistance_mid := 0.05
@export var momentum_decay_resistance_high := 0.12
@export var momentum_decay_resistance_flow := 0.2

# Equipment flip offsets
@export var equipment_right_offset := Vector2.ZERO
@export var equipment_left_offset := Vector2.ZERO

# Wall Jump / Wall Cling
@export var wall_jump_force: float = 620.0
@export var wall_jump_up_force: float = 680.0
@export var wall_cling_stall_time: float = 0.32
@export var wall_slide_max_speed: float = 620.0
@export_range(0.0, 48.0, 1.0) var wall_cling_visual_standoff := 22.0
@export_group("Ledge Grab")
@export var ledge_forward_reach := 42.0
@export var ledge_head_height := 72.0
@export var ledge_hang_offset := Vector2(28.0, 66.0)
@export var grapple_ledge_assist_duration := 0.18
@export var grapple_ledge_assist_forward_bonus := 18.0
@export var ledge_climb_horizontal_offset := 40.0
@export var ledge_climb_vertical_offset := 48.0
@export_range(0.05, 0.5, 0.01) var ledge_climb_duration := 0.2
@export_range(0.0, 64.0, 1.0) var ledge_climb_arc_height := 18.0
@export var ledge_jump_force := 720.0

@export_group("Meditation")
@export var meditation_ap_recharge_multiplier := 2.0
@export var meditation_hold_delay := 0.3
@export_range(0.1, 3.0, 0.05) var meditation_heal_interval := 0.8
@export_range(1.0, 100.0, 1.0) var meditation_momentum_cost_per_pulse := 10.0
@export_range(0.0, 1.0, 0.01) var meditation_health_ceiling_ratio := 0.75
@export_range(0.0, 1.0, 0.01) var meditation_critical_health_ratio := 0.35
@export_range(0.0, 1.0, 0.01) var meditation_wounded_health_ratio := 0.55
@export_range(0.0, 1.0, 0.01) var meditation_critical_heal_ratio := 0.05
@export_range(0.0, 1.0, 0.01) var meditation_wounded_heal_ratio := 0.04
@export_range(0.0, 1.0, 0.01) var meditation_upper_heal_ratio := 0.03
@export_range(0.1, 1.0, 0.05) var meditation_flow_interval_multiplier := 0.75
@export_range(0.5, 1.2, 0.01) var meditation_flow_audio_pitch := 0.78
@export_range(-20.0, 6.0, 0.5) var meditation_flow_audio_volume_db := -4.0

# Debug testing helpers
@export var god_mode_fly_speed: float = 1100.0
@export var god_mode_fly_acceleration: float = 5200.0

@export_group("Save Point Interaction")
@export var save_point_auto_run_speed := 420.0
@export var save_point_arrive_distance := 10.0
@export var save_point_sit_visual_scale := Vector2(0.5, 0.5)
@export var save_point_stand_up_speed_scale: float = 2.0

@export_group("Audio")
@export var footstep_interval := 0.28
@export var footstep_min_speed := 80.0
@export var coin_pickup_audio_cooldown := 0.045

@export_group("Tutorial Messages")
@export_multiline var first_thread_knot_message := "These are Thread Knots. They are used to purchase items and level up."

# Glow configuration
@export var idle_glow_width: float = 1.2
@export var idle_glow_intensity: float = 0.35
@export var charge_glow_max_width: float = 4.0
@export var charge_glow_max_intensity: float = 1.2

# ===============================
# STATE
# ===============================
const ATTACK_DIRECTION_DEADZONE := 0.15
const GRAPPLE_STRIKE_IMPACT_FRAME := 0
const MOMENTUM_CATEGORY_MOVEMENT := &"Movement"
const MOMENTUM_CATEGORY_JUMP := &"Jump"
const MOMENTUM_CATEGORY_DASH := &"Dash"
const MOMENTUM_CATEGORY_GRAPPLE := &"Grapple"
const MOMENTUM_CATEGORY_ATTACK := &"Attack"
const MOMENTUM_CATEGORY_POGO := &"Pogo"
const MOMENTUM_CATEGORY_UTILITY := &"Utility"
const MOMENTUM_CATEGORY_EQUIPMENT_SWAP := &"EquipmentSwap"
const MOMENTUM_CATEGORY_USE_AFTER_SWAP := &"UseAfterSwap"
const MOMENTUM_STATE_LOW := &"Low"
const MOMENTUM_STATE_MID := &"Mid"
const MOMENTUM_STATE_HIGH := &"High"
const MOMENTUM_STATE_FLOW := &"Flow"

var coyote_timer: float = 0.0
var last_direction: int = 1
var is_near_interactable: bool = false
var current_selector = null

var is_wall_clinging: bool = false
var wall_cling_timer: float = 0.0
var has_wall_jumped: bool = false
var air_jump_available: bool = true
var is_ledge_hanging := false
var is_ledge_climbing := false
var _ledge_direction := 0
var _ledge_top := Vector2.ZERO
var _grapple_ledge_assist_timer := 0.0
var _grapple_ledge_assist_direction := 0
var _ledge_climb_elapsed := 0.0
var _ledge_climb_start := Vector2.ZERO
var _ledge_climb_target := Vector2.ZERO
var _ledge_climb_jump_after := false
var is_meditating := false
var _meditation_hold_timer := 0.0
var _meditation_heal_timer := 0.0
var _meditation_started_in_flow := false

var jump_charge_ratio: float = 0.0
var dash_charge_ratio: float = 0.0
var _action_point_recharge_timers: Array[float] = []
var _momentum_staleness: Dictionary = {}
var _momentum_recent_categories: Array[StringName] = []
var _movement_momentum_timer := 0.0
var _movement_momentum_distance := 0.0
var _movement_momentum_last_position := Vector2.ZERO
var _flow_state_active := false
var _flow_state_duration := 0.0
var _flow_state_audio_suspended := false
var _momentum_state: StringName = MOMENTUM_STATE_LOW
var _pending_use_after_swap := false
var _use_after_swap_timer := 0.0
var _momentum_system_ready := false
var _flow_vfx_dash_visual_active := false
var _dash_iframe_timer := 0.0
var _dash_contact_phase_timer := 0.0
var _dash_contact_phasing_active := false
var _dash_direction_intent := 0
var _dash_direction_intent_timer := 0.0
var _position_before_movement := Vector2.ZERO
var _grapple_strike_contact_guard := false
var _debug_momentum_was_pressed := false
var _debug_force_doors_was_pressed := false
var _debug_thread_knots_was_pressed := false
var _debug_no_clip_was_pressed := false
var _debug_identity_power_was_pressed := false
var _debug_identity_balance_was_pressed := false
var _debug_identity_essence_was_pressed := false
var _debug_identity_reset_was_pressed := false
var _debug_flow_toggle_was_pressed := false
var _debug_identity_mix := Vector3.ZERO
var _footstep_timer := 0.0
var _coin_pickup_audio_timer := 0.0
var _thread_knot_tutorial_shown := false
var _debug_no_clip_enabled := false
var _debug_original_collision_layer := 0
var _debug_original_collision_mask := 0

var current_body_anim := ""
var current_equip_anim := ""
var current_weapon_pose_anim := ""
var current_attack_body_anim := "Ground_Attack_Combo_1"
var landing_animation_timer := 0.0
var _movement_facing_before_input := 1

var is_attacking := false
var is_hurt := false
var _hurt_animation_active := false
var is_dead := false
var god_mode_enabled := false
var death_reset_started := false
var attack_direction := Vector2.RIGHT
var attack_timer := 0.0
var attack_cooldown_timer := 0.0
var hurt_timer := 0.0
var attack_active_started := false
var attack_vfx_started := false
var attack_active_finished := false
var _player_default_visual_scale := Vector2.ONE
var _player_default_visual_position := Vector2.ZERO
var current_attack_is_special := false
var current_attack_uses_ground_combo := false
var current_attack_uses_air_double := false
var current_attack_uses_grapple_strike := false
var current_grapple_strike_landed := false
var current_grapple_strike_finished := false
var current_grapple_strike_impact_time := -1.0
var current_grapple_strike_animation_started := false
var ground_combo_family: StringName = &""
var ground_combo_step := -1
var ground_combo_reset_timer := 0.0
var ground_combo_attack_duration := 0.0
var ground_combo_active_strike := -1
var ground_combo_queued := false
var ground_combo_queued_family: StringName = &""
var ground_attack_visual_mode: StringName = &"stationary"
var ground_attack_locked_facing := 1
var air_attack_duration := 0.0
var air_attack_active_strike := -1
var _default_attack_hitbox_polygon := PackedVector2Array()
var _neutral_special_vfx_instance: Node2D = null
var _dash_iframe_vfx_instance: Node2D = null

# Equipment slots
var current_gloves: Node = null
var current_boots: BaseEquipment = null
var current_chest: BaseEquipment = null
var current_pattern: EquipmentPattern = null
var _pattern_visual: AnimatedSprite2D = null

var save_point_interaction_active := false
var _save_point_target_position := Vector2.ZERO
var _save_point_sitting_down := false
var _save_point_seated := false
var _save_point_standing_up := false
var _save_point_controller: Node = null
var _save_point_original_material: Material
var _save_point_original_scale := Vector2.ONE
var _save_point_original_animation_speed_scale: float = 1.0
var _save_point_equipment_was_visible := true
var _save_point_breath_tween: Tween

# ===============================
# READY
# ===============================
func _ready() -> void:
	if not player_stats:
		player_stats = PlayerStats.new()

	_debug_original_collision_layer = collision_layer
	_debug_original_collision_mask = collision_mask
	_player_default_visual_scale = player_animation.scale
	_player_default_visual_position = player_animation.position
	_default_attack_hitbox_polygon = attack_collision_polygon.polygon
	if not player_animation.frame_changed.is_connected(_on_player_animation_frame_changed):
		player_animation.frame_changed.connect(_on_player_animation_frame_changed)
	_ensure_pattern_visual()

	max_health = player_stats.max_health
	health_component.configure(player_stats.max_health)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)

	hurtbox.health_component = health_component
	hurtbox.hurtbox_owner = self

	attack_hitbox.hitbox_owner = self
	attack_hitbox.damage = _build_attack_damage()
	attack_hitbox.hit_landed.connect(_on_attack_hit_landed)

	if not current_boots:
		current_boots = BaseBoots.new(self)
	if not current_chest:
		current_chest = BaseChest.new(self)

	_ensure_action_point_timers()
	add_to_group("player")
	_apply_demo_checkpoint_spawn()
	print("✅ Player ready - Scene-based equipment system active")

	if ability_cooldown_timer:
		ability_cooldown_timer.timeout.connect(_on_ability_cooldown_timeout)

	if base_gloves_scene:
		equip_gloves(base_gloves_scene)
	if EquipManager:
		EquipManager.call_deferred("apply_current_pattern_to_player")

	AudioManager.enter_gameplay_music()
	_movement_momentum_last_position = global_position
	_momentum_system_ready = true
	_sync_flow_vfx_momentum()
	_set_flow_state_visuals(_flow_state_active)
	if OS.is_debug_build():
		print(
			"Flow VFX debug: F10 Power, F11 Balance, F12 Essence, ",
			"Home reset identity, End toggle Flow"
		)
	update_equipment_facing()
	_update_wall_cling_vfx()
	call_deferred("_sync_hud")

# ===============================
# EQUIP / UNEQUIP
# ===============================
func equip_gloves(glove_scene: PackedScene) -> void:
	unequip_gloves()

	current_gloves = glove_scene.instantiate()
	equipment_mount.add_child(current_gloves)

	current_gloves.player = self

	if current_gloves.has_method("on_equipped"):
		current_gloves.on_equipped()

	if _momentum_system_ready:
		report_momentum_action(MOMENTUM_CATEGORY_EQUIPMENT_SWAP)

	update_equipment_facing()

func unequip_gloves() -> void:
	if current_gloves:
		if current_attack_uses_grapple_strike:
			_cancel_current_grapple_strike()
			_finish_cancelled_attack()
		if current_gloves.has_method("on_unequipped"):
			current_gloves.on_unequipped()
		else:
			current_gloves.queue_free()

		current_gloves = null

# ===============================
# PHYSICS PROCESS
# ===============================
func _physics_process(delta: float) -> void:
	_process_debug_inputs()
	_process_audio_timers(delta)
	_process_momentum(delta)
	_process_action_point_recharge(delta)
	_grapple_ledge_assist_timer = maxf(_grapple_ledge_assist_timer - delta, 0.0)

	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, speed * get_momentum_move_speed_multiplier() * delta)
		velocity.y += _get_current_gravity() * delta
		velocity.y = min(velocity.y, max_fall_speed)
		move_and_slide()
		return

	update_combat_timers(delta)

	if save_point_interaction_active:
		_process_save_point_interaction(delta)
		return
	if _process_ledge_climb(delta):
		update_animations(0.0)
		return
	if _process_ledge_hang():
		update_animations(0.0)
		return
	_process_meditation(delta)
	if is_meditating:
		update_animations(0.0)
		return

	var was_on_floor := is_on_floor()

	# Gravity + coyote time
	if god_mode_enabled:
		coyote_timer = coyote_time
		has_wall_jumped = false
		air_jump_available = true
	elif not is_on_floor():
		velocity.y += _get_current_gravity() * delta
		velocity.y = min(velocity.y, max_fall_speed)
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time
		has_wall_jumped = false
		air_jump_available = true

	# Horizontal movement
	_movement_facing_before_input = last_direction
	var horizontal_input := Input.get_axis("move_left", "move_right")
	_update_dash_direction_intent(horizontal_input, delta)
	if horizontal_input != 0 and not is_attacking:
		last_direction = sign(horizontal_input)

	var grapple_restricting := false
	if current_gloves and current_gloves.has_method("is_base_grapple_restricting"):
		grapple_restricting = current_gloves.is_base_grapple_restricting()

	if current_attack_uses_grapple_strike and current_grapple_strike_landed:
		# Preserve the authored recoil through the short attack recovery.
		pass
	elif _is_attack_movement_committed():
		velocity.x = 0.0
	elif not grapple_restricting and not is_hurt:
		var control := 1.0 if is_on_floor() else air_control_mult * get_momentum_air_control_multiplier()
		velocity.x = speed * get_momentum_move_speed_multiplier() * horizontal_input * control
	elif is_hurt:
		velocity.x = move_toward(velocity.x, 0.0, speed * get_momentum_move_speed_multiplier() * delta)

	if god_mode_enabled:
		_apply_god_mode_flight(delta)

	var special_attack_requested := Input.is_action_just_pressed("SpecialAttack")
	var basic_attack_requested := Input.is_action_just_pressed("Attack")
	var attack_requested_this_frame := (
		special_attack_requested or basic_attack_requested
	)

	# Jump remains available during ordinary attacks, but not while a committed
	# strike is still waiting to deliver its authored impact.
	if (
		Input.is_action_just_pressed("Jump")
		and _can_process_jump_input(attack_requested_this_frame)
	):
		var velocity_before_jump := velocity
		if is_wall_clinging:
			is_wall_clinging = false
			wall_cling_timer = 0.0
		elif current_gloves and current_gloves.has_method("jump_off_grapple") and current_gloves.jump_off_grapple():
			pass
		elif current_boots:
			current_boots.handle_primary(delta, BaseEquipment.ActionState.PRESSED)
		if velocity.y < 0.0 and velocity.y < velocity_before_jump.y:
			_play_flow_vfx_jump(velocity)

	# Dash / Dodge
	if Input.is_action_just_pressed("Dash"):
		if current_chest:
			current_chest.handle_secondary(delta, BaseEquipment.ActionState.PRESSED)

	if special_attack_requested:
		start_attack(true)
	elif basic_attack_requested:
		start_attack()

	# Gloves active mechanic
	if current_gloves and current_gloves.has_method("thread_mechanic"):
		current_gloves.thread_mechanic(delta)

	# Passive effects
	if current_gloves and current_gloves.has_method("process_passive"):
		current_gloves.process_passive(delta)
	if current_boots:
		current_boots.process_passive(delta)
	if current_chest:
		current_chest.process_passive(delta)

	# A grapple strike owns approach velocity. Ordinary grapple movement resumes
	# only when that dedicated attack is no longer controlling the player.
	var grapple_strike_controls_velocity := false
	if (
		current_gloves
		and current_gloves.has_method("apply_grapple_strike_velocity")
		and not god_mode_enabled
	):
		grapple_strike_controls_velocity = bool(
			current_gloves.call("apply_grapple_strike_velocity", delta)
		)
	if (
		not grapple_strike_controls_velocity
		and current_gloves
		and current_gloves.has_method("apply_grapple_velocity")
		and not god_mode_enabled
	):
		current_gloves.apply_grapple_velocity(delta)

	var pre_collision_downward_speed := maxf(velocity.y, 0.0)
	_position_before_movement = global_position
	move_and_slide()
	if is_on_floor() and not was_on_floor and not god_mode_enabled:
		landing_animation_timer = landing_animation_duration
		_play_flow_vfx_land(pre_collision_downward_speed)
	elif not is_on_floor():
		landing_animation_timer = 0.0
	elif landing_animation_timer > 0.0:
		landing_animation_timer = maxf(landing_animation_timer - delta, 0.0)
	_process_movement_audio(delta, was_on_floor)
	_process_movement_momentum(delta)

	if not _try_grab_ledge():
		handle_wall_cling(delta)
	update_animations(horizontal_input)

	if current_gloves and current_gloves.has_method("sync_grapple_origin_after_player_move"):
		current_gloves.sync_grapple_origin_after_player_move()

# ===============================
# PROCESS
# ===============================
func _process(_delta: float) -> void:
	_sync_pattern_visual_transform()
	if save_point_interaction_active:
		return

	if OS.is_debug_build():
		var debug_force_doors_pressed := Input.is_key_pressed(KEY_F7)
		if debug_force_doors_pressed and not _debug_force_doors_was_pressed:
			_debug_force_open_demo_doors()
		_debug_force_doors_was_pressed = debug_force_doors_pressed

	if Input.is_action_just_pressed("pause_menu") and not death_reset_started and not _should_block_pause_open():
		_open_pause_menu()

	var requested_game_menu_tab := _get_requested_game_menu_tab()
	if requested_game_menu_tab != &"" and not death_reset_started:
		_open_game_menu(requested_game_menu_tab)

	var menu = _get_or_create_radial_menu()
	if menu:
		menu.update_hold_state(Input.is_action_pressed("open_menu"))

	if is_near_interactable and current_selector and Input.is_action_just_pressed("interact"):
		print("Interacting with: ", current_selector.name)
		if current_selector.has_method("interact"):
			current_selector.interact(self)

func _open_pause_menu() -> void:
	if get_tree().paused:
		return
	if get_tree().get_first_node_in_group("pause_menu"):
		return

	var pause_menu := PAUSE_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(pause_menu)

func _is_non_pause_menu_open() -> bool:
	return (
		get_tree().get_first_node_in_group("game_menu") != null
		or get_tree().get_first_node_in_group("save_point_menu") != null
		or get_tree().get_first_node_in_group("merchant_menu") != null
	)

func _should_block_pause_open() -> bool:
	if _is_non_pause_menu_open():
		return true
	if not get_tree().has_meta(PAUSE_OPEN_BLOCK_UNTIL_META):
		return false

	var block_until_msec := int(get_tree().get_meta(PAUSE_OPEN_BLOCK_UNTIL_META))
	if Time.get_ticks_msec() <= block_until_msec:
		return true

	get_tree().remove_meta(PAUSE_OPEN_BLOCK_UNTIL_META)
	return false

func _get_or_create_radial_menu() -> Node:
	var menu := get_tree().get_first_node_in_group("radial_menu")
	if menu:
		return menu
	if not get_tree().current_scene:
		return null

	menu = RADIAL_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(menu)
	menu.set("player_path", menu.get_path_to(self))
	return menu

func _get_requested_game_menu_tab() -> StringName:
	if Input.is_action_just_pressed("open_inventory"):
		return &"Inventory"
	if Input.is_action_just_pressed("open_map"):
		return &"Map"
	if Input.is_action_just_pressed("open_lore"):
		return &"Lore"
	if Input.is_action_just_pressed("open_controls"):
		return &"Controls"
	return &""

func _open_game_menu(initial_tab: StringName) -> void:
	if get_tree().paused:
		return
	if get_tree().get_first_node_in_group("game_menu"):
		return

	var game_menu := GAME_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(game_menu)
	if game_menu.has_method("open"):
		game_menu.open(initial_tab, _get_game_menu_input_family(initial_tab))

func _get_game_menu_input_family(initial_tab: StringName) -> StringName:
	if _is_game_menu_keyboard_tab_pressed(initial_tab):
		return &"keyboard_mouse"
	if _is_game_menu_controller_tab_pressed(initial_tab):
		return _get_connected_controller_family()
	return &"keyboard_mouse"

func _is_game_menu_keyboard_tab_pressed(initial_tab: StringName) -> bool:
	match initial_tab:
		&"Inventory":
			return Input.is_physical_key_pressed(KEY_I)
		&"Map":
			return Input.is_physical_key_pressed(KEY_M)
		&"Lore":
			return Input.is_physical_key_pressed(KEY_L)
		&"Controls":
			return Input.is_physical_key_pressed(KEY_C)
	return false

func _is_game_menu_controller_tab_pressed(initial_tab: StringName) -> bool:
	var button_index := -1
	match initial_tab:
		&"Inventory":
			button_index = 11
		&"Map":
			button_index = 13
		&"Lore":
			button_index = 12
		&"Controls":
			button_index = 14

	if button_index < 0:
		return false

	for device_id in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(device_id, button_index):
			return true
	return false

func _get_connected_controller_family(device_id := -1) -> StringName:
	var resolved_device_id := device_id
	if resolved_device_id < 0:
		var connected := Input.get_connected_joypads()
		if connected.is_empty():
			return &"xbox"
		resolved_device_id = int(connected[0])

	var joy_name := Input.get_joy_name(resolved_device_id).to_lower()
	if joy_name.contains("playstation") or joy_name.contains("ps5") or joy_name.contains("dualsense") or joy_name.contains("dualshock"):
		return &"ps5"
	if joy_name.contains("nintendo") or joy_name.contains("switch") or joy_name.contains("joy-con") or joy_name.contains("pro controller"):
		return &"nintendo"
	if joy_name.contains("steam"):
		return &"steam"
	return &"xbox"

func _process_debug_inputs() -> void:
	if not OS.is_debug_build():
		return
	_update_god_mode_toggle()
	_update_debug_no_clip_toggle()
	_update_debug_momentum_fill()
	_update_debug_thread_knots()
	_update_debug_flow_vfx_controls()

func _update_god_mode_toggle() -> void:
	if not OS.is_debug_build():
		return
	if Input.is_action_just_pressed("debug_god_mode"):
		god_mode_enabled = not god_mode_enabled
		if god_mode_enabled:
			if health_component:
				health_component.heal(health_component.max_health)
			_complete_tutorial_for_debug()
		_sync_hud()
		print("God mode: ", "ON" if god_mode_enabled else "OFF")

func _update_debug_no_clip_toggle() -> void:
	if not OS.is_debug_build():
		return
	var pressed: bool = Input.is_key_pressed(KEY_F6)
	if pressed and not _debug_no_clip_was_pressed:
		_debug_no_clip_enabled = not _debug_no_clip_enabled
		_apply_debug_no_clip()
		print("No clip: ", "ON" if _debug_no_clip_enabled else "OFF")
	_debug_no_clip_was_pressed = pressed

func _apply_debug_no_clip() -> void:
	if not OS.is_debug_build():
		return
	if _debug_no_clip_enabled:
		collision_layer = 0
		collision_mask = 0
	else:
		collision_layer = _debug_original_collision_layer
		collision_mask = _debug_original_collision_mask

func _complete_tutorial_for_debug() -> void:
	if not OS.is_debug_build():
		return
	_thread_knot_tutorial_shown = true
	DemoProgress.claim_thread(&"power")
	DemoProgress.claim_thread(&"balance")
	DemoProgress.claim_thread(&"essence")
	DemoProgress.mark_tutorial_completed()
	for controller in get_tree().get_nodes_in_group("tutorial_controllers"):
		if controller.has_method("debug_complete_tutorial"):
			controller.call("debug_complete_tutorial")

func _update_debug_momentum_fill() -> void:
	if not OS.is_debug_build():
		return
	var pressed := Input.is_key_pressed(KEY_F8)
	if pressed and not _debug_momentum_was_pressed:
		_change_momentum(debug_momentum_fill_amount)
		print("Debug momentum: ", momentum)
	_debug_momentum_was_pressed = pressed

func _update_debug_thread_knots() -> void:
	if not OS.is_debug_build():
		return
	var pressed := Input.is_key_pressed(KEY_F9)
	if pressed and not _debug_thread_knots_was_pressed:
		collect_thread_knots(debug_thread_knots_amount)
		print("Debug thread knots: +", debug_thread_knots_amount, " total ", thread_knot_count)
	_debug_thread_knots_was_pressed = pressed

func _update_debug_flow_vfx_controls() -> void:
	if not OS.is_debug_build():
		return

	var power_pressed := Input.is_key_pressed(KEY_F10)
	var balance_pressed := Input.is_key_pressed(KEY_F11)
	var essence_pressed := Input.is_key_pressed(KEY_F12)
	var reset_pressed := Input.is_key_pressed(KEY_HOME)
	var flow_pressed := Input.is_key_pressed(KEY_END)

	if power_pressed and not _debug_identity_power_was_pressed:
		_debug_identity_mix.x = minf(
			1.0,
			_debug_identity_mix.x + debug_identity_step
		)
		_apply_debug_identity_mix()
	if balance_pressed and not _debug_identity_balance_was_pressed:
		_debug_identity_mix.y = minf(
			1.0,
			_debug_identity_mix.y + debug_identity_step
		)
		_apply_debug_identity_mix()
	if essence_pressed and not _debug_identity_essence_was_pressed:
		_debug_identity_mix.z = minf(
			1.0,
			_debug_identity_mix.z + debug_identity_step
		)
		_apply_debug_identity_mix()
	if reset_pressed and not _debug_identity_reset_was_pressed:
		_debug_identity_mix = Vector3.ZERO
		if flow_state_aura and flow_state_aura.has_method("clear_identity_override"):
			flow_state_aura.call("clear_identity_override")
		print("Flow identity debug override cleared; using collected threads")
	if flow_pressed and not _debug_flow_toggle_was_pressed:
		set_momentum(0.0 if _flow_state_active else 100.0)
		print("Debug Flow State: ", "ON" if _flow_state_active else "OFF")

	_debug_identity_power_was_pressed = power_pressed
	_debug_identity_balance_was_pressed = balance_pressed
	_debug_identity_essence_was_pressed = essence_pressed
	_debug_identity_reset_was_pressed = reset_pressed
	_debug_flow_toggle_was_pressed = flow_pressed

func _apply_debug_identity_mix() -> void:
	if not OS.is_debug_build():
		return
	if flow_state_aura and flow_state_aura.has_method("set_identity_mix"):
		flow_state_aura.call(
			"set_identity_mix",
			_debug_identity_mix.x,
			_debug_identity_mix.y,
			_debug_identity_mix.z
		)
	print(
		"Flow identity debug mix - Power ",
		roundi(_debug_identity_mix.x * 100.0),
		"%, Balance ",
		roundi(_debug_identity_mix.y * 100.0),
		"%, Essence ",
		roundi(_debug_identity_mix.z * 100.0),
		"%"
	)

func _debug_force_open_demo_doors() -> void:
	if not OS.is_debug_build():
		return
	for door in get_tree().get_nodes_in_group("demo_doors"):
		if door.has_method("debug_force_open"):
			door.debug_force_open()
	print("Debug doors: forced open")

func _apply_god_mode_flight(delta: float) -> void:
	if not OS.is_debug_build():
		return
	var vertical_input := 0.0
	if Input.is_action_pressed("Jump") or Input.is_action_pressed("move_up"):
		vertical_input -= 1.0
	if Input.is_action_pressed("move_down"):
		vertical_input += 1.0

	var target_y := vertical_input * god_mode_fly_speed
	velocity.y = move_toward(velocity.y, target_y, god_mode_fly_acceleration * delta)

# ===============================
# WALL CLING
# ===============================
func handle_wall_cling(delta: float) -> void:
	var on_wall = is_on_wall_only()
	var pushing_into_wall = false
	
	if on_wall:
		var wall_normal_x = get_wall_normal().x
		var input_dir = Input.get_axis("move_left", "move_right")
		pushing_into_wall = input_dir != 0 and sign(input_dir) == -sign(wall_normal_x)

	if on_wall and pushing_into_wall and not is_on_floor():
		if not is_wall_clinging:
			is_wall_clinging = true
			wall_cling_timer = wall_cling_stall_time
			velocity.y = 0.0

		if wall_cling_timer > 0.0:
			wall_cling_timer -= delta
			velocity.y = lerp(velocity.y, -60.0, 0.25)
		else:
			velocity.y += 380.0 * delta
			velocity.y = min(velocity.y, wall_slide_max_speed)
	else:
		is_wall_clinging = false
		wall_cling_timer = 0.0

func _try_grab_ledge() -> bool:
	if is_on_floor() or is_ledge_hanging or is_ledge_climbing or god_mode_enabled or is_hurt or is_attacking or velocity.y < -80.0:
		return false
	var grapple_assist_active := _grapple_ledge_assist_timer > 0.0
	var direction := (
		_grapple_ledge_assist_direction
		if grapple_assist_active
		else last_direction
	)
	if not grapple_assist_active and is_on_wall():
		var normal_x := get_wall_normal().x
		if absf(normal_x) > 0.1:
			direction = int(-signf(normal_x))
	if direction == 0:
		return false
	var forward_reach := ledge_forward_reach
	var wall_sample_offsets: Array[float] = [-12.0]
	if grapple_assist_active:
		forward_reach += grapple_ledge_assist_forward_bonus
		wall_sample_offsets.append_array([0.0, 12.0, 24.0])
	var space := get_world_2d().direct_space_state
	var wall_hit: Dictionary = {}
	for sample_offset in wall_sample_offsets:
		var wall_query := PhysicsRayQueryParameters2D.create(
			global_position + Vector2(0.0, sample_offset),
			global_position + Vector2(direction * forward_reach, sample_offset),
			collision_mask,
			[get_rid()]
		)
		wall_hit = space.intersect_ray(wall_query)
		if not wall_hit.is_empty():
			break
	if wall_hit.is_empty():
		return false
	var clearance_query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0.0, -ledge_head_height), global_position + Vector2(direction * forward_reach, -ledge_head_height), collision_mask, [get_rid()])
	if not space.intersect_ray(clearance_query).is_empty():
		return false
	# Sample just beyond the wall face. Using the full reach places the vertical
	# ray deep inside wide platforms, where a ray that starts inside collision
	# reports no surface and makes ledge grab impossible.
	var top_x: float = (wall_hit.position as Vector2).x + direction * 2.0
	var top_query := PhysicsRayQueryParameters2D.create(Vector2(top_x, global_position.y - ledge_head_height - 30.0), Vector2(top_x, global_position.y + 12.0), collision_mask, [get_rid()])
	var top_hit := space.intersect_ray(top_query)
	if top_hit.is_empty():
		return false
	_ledge_direction = direction
	_ledge_top = top_hit.position
	is_ledge_hanging = true
	is_wall_clinging = false
	_grapple_ledge_assist_timer = 0.0
	velocity = Vector2.ZERO
	global_position = _ledge_top + Vector2(-direction * ledge_hang_offset.x, ledge_hang_offset.y)
	player_animation.flip_h = direction < 0
	return true

func request_grapple_ledge_assist(grapple_position: Vector2) -> void:
	var horizontal_delta := grapple_position.x - global_position.x
	if absf(horizontal_delta) <= 0.01:
		return
	_grapple_ledge_assist_direction = int(signf(horizontal_delta))
	_grapple_ledge_assist_timer = grapple_ledge_assist_duration

func _process_ledge_hang() -> bool:
	if not is_ledge_hanging:
		return false
	velocity = Vector2.ZERO
	global_position = _ledge_top + Vector2(-_ledge_direction * ledge_hang_offset.x, ledge_hang_offset.y)
	if Input.is_action_just_pressed("move_down"):
		is_ledge_hanging = false
	elif Input.is_action_just_pressed("Jump"):
		_start_ledge_climb(true)
	elif Input.is_action_just_pressed("move_up"):
		_start_ledge_climb(false)
	return is_ledge_hanging

func _start_ledge_climb(jump_after: bool) -> void:
	_ledge_climb_start = global_position
	_ledge_climb_target = _ledge_top + Vector2(
		_ledge_direction * ledge_climb_horizontal_offset,
		-ledge_climb_vertical_offset
	)
	_ledge_climb_elapsed = 0.0
	_ledge_climb_jump_after = jump_after
	is_ledge_hanging = false
	is_ledge_climbing = true
	velocity = Vector2.ZERO

func _process_ledge_climb(delta: float) -> bool:
	if not is_ledge_climbing:
		return false

	velocity = Vector2.ZERO
	_ledge_climb_elapsed = minf(_ledge_climb_elapsed + delta, ledge_climb_duration)
	var progress := clampf(_ledge_climb_elapsed / maxf(ledge_climb_duration, 0.001), 0.0, 1.0)
	var eased_progress := smoothstep(0.0, 1.0, progress)
	global_position = _sample_ledge_climb_arc(
		_ledge_climb_start,
		_ledge_climb_target,
		_ledge_direction,
		eased_progress
	)

	if progress < 1.0:
		return true

	global_position = _ledge_climb_target
	is_ledge_climbing = false
	velocity = Vector2(
		_ledge_direction * 120.0,
		-ledge_jump_force if _ledge_climb_jump_after else 0.0
	)
	if _ledge_climb_jump_after:
		_play_flow_vfx_jump(velocity)
		report_momentum_action(MOMENTUM_CATEGORY_JUMP)
	_ledge_climb_jump_after = false
	return true

func _sample_ledge_climb_arc(
	start: Vector2,
	target: Vector2,
	direction: int,
	progress: float
) -> Vector2:
	var t := clampf(progress, 0.0, 1.0)
	var control := Vector2(
		start.x + float(direction) * 8.0,
		target.y - ledge_climb_arc_height
	)
	var inverse := 1.0 - t
	return inverse * inverse * start + 2.0 * inverse * t * control + t * t * target

func _process_meditation(delta: float) -> void:
	var was_meditating := is_meditating
	var interruption_requested := (
		absf(Input.get_axis("move_left", "move_right")) > 0.01
		or Input.is_action_pressed("Jump")
		or Input.is_action_pressed("Dash")
		or Input.is_action_pressed("Attack")
		or Input.is_action_pressed("SpecialAttack")
	)
	var can_meditate := (
		is_on_floor()
		and not is_hurt
		and not is_attacking
		and not is_dead
		and not interruption_requested
	)
	if Input.is_action_pressed("Meditate") and can_meditate:
		_meditation_hold_timer += delta
		if _meditation_hold_timer >= meditation_hold_delay:
			is_meditating = true
			velocity = Vector2.ZERO
	else:
		_meditation_hold_timer = 0.0
		is_meditating = false

	if is_meditating and not was_meditating:
		_meditation_heal_timer = 0.0
		_meditation_started_in_flow = _flow_state_active
		var meditation_audio := AudioManager.play_sfx(
			&"enter_momentum",
			meditation_flow_audio_volume_db,
			0.0
		)
		if meditation_audio:
			meditation_audio.pitch_scale *= meditation_flow_audio_pitch
	elif not is_meditating and was_meditating:
		_meditation_heal_timer = 0.0
		_meditation_started_in_flow = false

	if is_meditating:
		_process_meditation_healing(delta)
	if is_meditating != was_meditating:
		if flow_state_aura and flow_state_aura.has_method("set_meditation_active"):
			flow_state_aura.call("set_meditation_active", is_meditating)
		else:
			_set_flow_state_visuals(is_meditating or _flow_state_active)

func _process_meditation_healing(delta: float) -> void:
	if not _is_meditation_seated() or not _can_apply_meditation_heal_pulse():
		_meditation_heal_timer = 0.0
		return

	var interval := meditation_heal_interval
	if _meditation_started_in_flow:
		interval *= meditation_flow_interval_multiplier
	_meditation_heal_timer += delta
	if _meditation_heal_timer < interval:
		return

	_meditation_heal_timer -= interval
	_apply_meditation_heal_pulse()

func _is_meditation_seated() -> bool:
	if not player_animation or not player_animation.sprite_frames:
		return false
	if player_animation.animation != SIT_ANIMATION:
		return false
	var final_frame := player_animation.sprite_frames.get_frame_count(SIT_ANIMATION) - 1
	return final_frame >= 0 and player_animation.frame >= final_frame

func _can_apply_meditation_heal_pulse() -> bool:
	if not health_component or health_component.max_health <= 0:
		return false
	var health_ceiling := floori(
		float(health_component.max_health) * meditation_health_ceiling_ratio
	)
	return (
		health_component.current_health < health_ceiling
		and momentum >= meditation_momentum_cost_per_pulse
	)

func _apply_meditation_heal_pulse() -> bool:
	if not _can_apply_meditation_heal_pulse():
		return false

	var health_ratio := (
		float(health_component.current_health) / float(health_component.max_health)
	)
	var heal_ratio := meditation_upper_heal_ratio
	if health_ratio < meditation_critical_health_ratio:
		heal_ratio = meditation_critical_heal_ratio
	elif health_ratio < meditation_wounded_health_ratio:
		heal_ratio = meditation_wounded_heal_ratio

	var health_ceiling := floori(
		float(health_component.max_health) * meditation_health_ceiling_ratio
	)
	var heal_amount := mini(
		maxi(1, roundi(float(health_component.max_health) * heal_ratio)),
		health_ceiling - health_component.current_health
	)
	_change_momentum(-meditation_momentum_cost_per_pulse)
	health_component.heal(heal_amount)
	return true

func _get_current_gravity() -> float:
	if velocity.y < 0.0:
		if not Input.is_action_pressed("Jump"):
			return gravity * jump_cut_gravity_multiplier
		return gravity

	return gravity * fall_gravity_multiplier

# ===============================
# ANIMATION
# ===============================
func play_character_anim(body_anim: String) -> void:
	var body_changed := current_body_anim != body_anim
	var equipment_anim := body_anim

	if body_changed:
		current_body_anim = body_anim
		player_animation.play(body_anim)
		if not is_attacking:
			_play_weapon_pose_anim(body_anim)

	if current_gloves:
		if body_changed or current_equip_anim != equipment_anim:
			current_equip_anim = equipment_anim

			if current_gloves.has_method("play_equipment_anim"):
				current_gloves.play_equipment_anim(equipment_anim)

func update_animations(dir: float) -> void:
	if not player_animation or not player_animation.sprite_frames:
		return

	if save_point_interaction_active:
		_set_flow_vfx_dash_visual_active(false)
		return
	if is_meditating and player_animation.sprite_frames.has_animation(SIT_ANIMATION):
		_set_flow_vfx_dash_visual_active(false)
		player_animation.rotation = 0.0
		player_animation.scale = save_point_sit_visual_scale
		play_character_anim(SIT_ANIMATION)
		return
	if is_ledge_hanging and player_animation.sprite_frames.has_animation(&"Wall_Cling"):
		_set_flow_vfx_dash_visual_active(false)
		player_animation.rotation = 0.0
		player_animation.scale = _player_default_visual_scale
		player_animation.position = _player_default_visual_position
		play_character_anim("Wall_Cling")
		player_animation.pause()
		player_animation.set_frame_and_progress(0, 0.0)
		return
	if is_ledge_climbing:
		_set_flow_vfx_dash_visual_active(false)
		_play_ledge_climb_pose()
		return
	if player_animation.scale != _player_default_visual_scale:
		player_animation.scale = _player_default_visual_scale
	if player_animation.position != _player_default_visual_position:
		player_animation.position = _player_default_visual_position
	if (
		is_hurt
		and _hurt_animation_active
		and player_animation.sprite_frames.has_animation(HURT_ANIMATION)
	):
		_set_flow_vfx_dash_visual_active(false)
		player_animation.rotation = 0.0
		player_animation.scale = _player_default_visual_scale * hurt_visual_scale_multiplier
		player_animation.speed_scale = 1.0
		if current_body_anim != HURT_ANIMATION:
			current_body_anim = HURT_ANIMATION
			player_animation.play(HURT_ANIMATION)
			current_equip_anim = HURT_ANIMATION
			if current_gloves and current_gloves.has_method("play_equipment_anim"):
				current_gloves.play_equipment_anim(HURT_ANIMATION)
		return

	if current_attack_uses_grapple_strike and not current_grapple_strike_animation_started:
		var strike_ready := (
			current_gloves
			and current_gloves.has_method("is_grapple_strike_ready_to_animate")
			and bool(current_gloves.call("is_grapple_strike_ready_to_animate"))
		)
		if strike_ready:
			_begin_grapple_strike_impact_animation()
		else:
			_play_grapple_strike_approach_animation()
			return

	if is_attacking and player_animation.sprite_frames.has_animation(current_attack_body_anim):
		_set_flow_vfx_dash_visual_active(false)
		player_animation.rotation = 0.0
		_apply_attack_visual_tuning()
		_play_attack_visual_animation(_get_ground_combo_visual_animation(dir))
		return
	
	var is_dashing := false
	var is_grapple_strike_dash := false
	if current_chest and "is_dashing" in current_chest:
		is_dashing = current_chest.is_dashing
	if current_gloves and current_gloves.has_method("forces_dash_animation") and current_gloves.forces_dash_animation():
		is_dashing = true
		is_grapple_strike_dash = true
	var forced_dash_direction := Vector2.ZERO
	if current_gloves and current_gloves.has_method("get_forced_dash_direction"):
		forced_dash_direction = current_gloves.get_forced_dash_direction()
	var dash_visual_active: bool = bool(is_dashing) and player_animation.sprite_frames.has_animation("Dash")
	var dash_vfx_direction := forced_dash_direction if forced_dash_direction.length() > 0.001 else velocity
	_set_flow_vfx_dash_visual_active(dash_visual_active, dash_vfx_direction)
	
	if dash_visual_active:
		play_character_anim("Dash")
		player_animation.rotation = 0.0
		if is_grapple_strike_dash:
			player_animation.scale = (
				_player_default_visual_scale
				* grapple_strike_visual_scale_multiplier
			)
		if forced_dash_direction.length() > 0.001:
			_apply_directional_dash_pose(forced_dash_direction)
			update_equipment_facing()

	elif is_wall_clinging and player_animation.sprite_frames.has_animation("Wall_Cling"):
		player_animation.rotation = 0.0
		var wall_direction := _get_wall_visual_direction()
		player_animation.position = _player_default_visual_position - Vector2(
			float(wall_direction) * wall_cling_visual_standoff,
			0.0
		)
		play_character_anim("Wall_Cling")

	elif not is_on_floor():
		player_animation.rotation = 0.0
		if absf(velocity.y) <= jump_apex_velocity_threshold and player_animation.sprite_frames.has_animation("Jump_Apex"):
			play_character_anim("Jump_Apex")
		elif velocity.y < 0.0 and player_animation.sprite_frames.has_animation("Jump_Ascent"):
			play_character_anim("Jump_Ascent")
		else:
			play_character_anim("Jump_Descent")

	elif landing_animation_timer > 0.0 and absf(dir) < 0.01 and player_animation.sprite_frames.has_animation("Jump_Land"):
		player_animation.rotation = 0.0
		player_animation.scale = _player_default_visual_scale * landing_visual_scale_multiplier
		player_animation.position = _player_default_visual_position + landing_visual_offset
		play_character_anim("Jump_Land")

	elif dir != 0 and player_animation.sprite_frames.has_animation("Run"):
		player_animation.rotation = 0.0
		play_character_anim("Run")

	elif player_animation.sprite_frames.has_animation("Idle"):
		player_animation.rotation = 0.0
		play_character_anim("Idle")

	if (
		velocity.x != 0
		and (
			not dash_visual_active
			or forced_dash_direction.length() <= 0.001
		)
	):
		player_animation.flip_h = velocity.x < 0
		update_equipment_facing()

	_update_wall_cling_vfx()

func _play_grapple_strike_approach_animation() -> void:
	if not player_animation.sprite_frames.has_animation(&"Dash"):
		return
	var direction := attack_direction
	if current_gloves and current_gloves.has_method("get_grapple_strike_direction"):
		direction = current_gloves.call("get_grapple_strike_direction")
	_set_flow_vfx_dash_visual_active(true, direction)
	play_character_anim("Dash")
	player_animation.scale = (
		_player_default_visual_scale * grapple_strike_visual_scale_multiplier
	)
	_apply_directional_dash_pose(direction)
	update_equipment_facing()

func _begin_grapple_strike_impact_animation() -> void:
	if not player_animation.sprite_frames.has_animation(&"Grapple_Strike"):
		return
	current_grapple_strike_animation_started = true
	current_attack_body_anim = "Grapple_Strike"
	_set_flow_vfx_dash_visual_active(false)
	player_animation.rotation = 0.0
	player_animation.scale = _player_default_visual_scale
	player_animation.position = _player_default_visual_position
	player_animation.speed_scale = maxf(0.1, get_momentum_attack_speed_multiplier())
	_play_weapon_attack_anim()
	play_character_anim("Grapple_Strike")

func _apply_directional_dash_pose(direction: Vector2) -> void:
	if direction.length() <= 0.001:
		player_animation.rotation = 0.0
		return

	var dash_direction := direction.normalized()
	if absf(dash_direction.x) > 0.001:
		player_animation.flip_h = dash_direction.x < 0.0

	var source_angle := dash_direction.angle()
	if player_animation.flip_h:
		source_angle = wrapf(source_angle + PI, -PI, PI)
	player_animation.rotation = source_angle

func update_equipment_facing() -> void:
	if not equipment_mount:
		return

	if player_animation.flip_h:
		equipment_mount.scale.x = -1
		equipment_mount.position = equipment_left_offset
	else:
		equipment_mount.scale.x = 1
		equipment_mount.position = equipment_right_offset

	_apply_attack_direction()

func _update_wall_cling_vfx() -> void:
	if not wall_cling_vfx:
		return

	var should_show := is_wall_clinging and not is_on_floor()
	wall_cling_vfx.visible = should_show
	if not should_show:
		wall_cling_vfx.stop()
		return

	var wall_direction := _get_wall_visual_direction()

	wall_cling_vfx.position = Vector2(20.0 * float(wall_direction), -54.0)
	wall_cling_vfx.flip_h = wall_direction > 0
	if not wall_cling_vfx.is_playing():
		wall_cling_vfx.play("cling")

func _play_ledge_climb_pose() -> void:
	player_animation.rotation = 0.0
	player_animation.scale = _player_default_visual_scale
	player_animation.position = _player_default_visual_position
	if not player_animation.sprite_frames.has_animation(LEDGE_CLIMB_ANIMATION):
		return

	var progress := clampf(
		_ledge_climb_elapsed / maxf(ledge_climb_duration, 0.001),
		0.0,
		1.0
	)
	play_character_anim(String(LEDGE_CLIMB_ANIMATION))
	var frame_count := player_animation.sprite_frames.get_frame_count(
		LEDGE_CLIMB_ANIMATION
	)
	if frame_count <= 0:
		return
	var pose_frame := clampi(
		floori(clampf(progress, 0.0, 0.999) * float(frame_count)),
		0,
		frame_count - 1
	)
	player_animation.set_frame_and_progress(pose_frame, 0.0)

func _get_wall_visual_direction() -> int:
	var wall_direction := int(-signf(get_wall_normal().x))
	if wall_direction == 0:
		wall_direction = -1 if player_animation.flip_h else 1
	return wall_direction

# ===============================
# COMBAT
# ===============================
func update_combat_timers(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	if not is_attacking and ground_combo_reset_timer > 0.0:
		ground_combo_reset_timer -= delta
		if ground_combo_reset_timer <= 0.0:
			_reset_ground_combo_chain()

	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0:
			is_hurt = false

	if not is_attacking:
		return

	attack_timer += delta
	_sync_attack_hitbox_to_anchor()
	if current_attack_uses_ground_combo:
		_update_ground_combo_attack()
		return
	if current_attack_uses_air_double:
		_update_air_double_attack()
		return

	var attack_speed_multiplier := maxf(0.1, get_momentum_attack_speed_multiplier())
	var windup := player_stats.attack_windup / attack_speed_multiplier
	var active_time := player_stats.attack_active_time / attack_speed_multiplier
	var recovery := player_stats.attack_recovery / attack_speed_multiplier
	if current_attack_is_special:
		# The authored neutral-special animation is 48 frames at 40 FPS (1.2 s).
		# Keep its combat phases on that same timeline so it cannot be cut short.
		windup = neutral_special_windup
		active_time = neutral_special_active_time
		recovery = neutral_special_recovery
		if not attack_vfx_started and attack_timer >= maxf(0.0, windup - neutral_special_vfx_lead_time):
			attack_vfx_started = true
			_play_weapon_attack_anim()
			_play_neutral_special_vfx()
		if attack_vfx_started and not attack_active_started:
			_update_neutral_special_vfx_anchor()

	if not attack_active_started and attack_timer >= windup:
		attack_active_started = true
		if current_attack_is_special:
			attack_collision_polygon.polygon = _build_circle_hitbox_polygon(
				neutral_special_aoe_radius
			)
			_trigger_neutral_special_impact_vfx()
			_play_neutral_special_impact_audio()
		if current_attack_uses_grapple_strike:
			attack_hitbox.disable()
			_try_resolve_current_grapple_strike()
		else:
			_sync_attack_hitbox_to_anchor()
			attack_hitbox.damage = _build_attack_damage()
			attack_hitbox.enable()
		if current_attack_is_special:
			CombatFeedback.screen_shake(
				self,
				neutral_special_screen_shake_strength,
				neutral_special_screen_shake_duration
			)
		if not current_attack_uses_grapple_strike:
			_play_flow_vfx_attack_swing(
				attack_direction,
				ground_combo_hitbox_arc_degrees,
				0
			)

	if (
		current_attack_uses_grapple_strike
		and attack_active_started
		and not current_grapple_strike_finished
	):
		_try_resolve_current_grapple_strike()

	if attack_active_started and not attack_active_finished and attack_timer >= windup + active_time:
		attack_active_finished = true
		attack_hitbox.disable()

	var attack_end := windup + active_time + recovery
	if current_attack_uses_grapple_strike:
		if current_grapple_strike_landed:
			attack_end = current_grapple_strike_impact_time + recovery
		elif not current_grapple_strike_finished:
			attack_end = maxf(attack_end, grapple_strike_max_duration)
	var waiting_for_grapple_strike_frame := (
		current_attack_uses_grapple_strike
		and current_grapple_strike_animation_started
		and not current_grapple_strike_finished
		and player_animation.animation == &"Grapple_Strike"
		and player_animation.frame < GRAPPLE_STRIKE_IMPACT_FRAME
	)
	if attack_timer >= attack_end and not waiting_for_grapple_strike_frame:
		if current_attack_uses_grapple_strike:
			_cancel_current_grapple_strike()
		is_attacking = false
		current_attack_is_special = false
		attack_hitbox.disable()
		_reset_attack_hitbox_polygon()
		_reset_weapon_visuals()

func start_attack(is_special := false) -> void:
	if not is_special and is_attacking and current_attack_uses_ground_combo:
		ground_combo_queued = true
		ground_combo_queued_family = _get_ground_combo_family(_get_attack_input_direction())
		return

	if not can_start_attack(is_special):
		return
	if is_special and not spend_action_points(neutral_special_action_point_cost):
		return
	if is_special:
		if (
			current_gloves
			and current_gloves.has_method("cancel_for_committed_attack")
		):
			current_gloves.call("cancel_for_committed_attack")
		_cancel_neutral_special_vfx()

	var grapple_strike_started := false
	if (
		not is_special
		and current_gloves
		and current_gloves.has_method("try_start_grapple_strike")
	):
		grapple_strike_started = bool(
			current_gloves.call("try_start_grapple_strike")
		)

	if (
		grapple_strike_started
		and current_gloves.has_method("get_grapple_strike_direction")
	):
		attack_direction = current_gloves.call("get_grapple_strike_direction")
	else:
		attack_direction = _get_attack_input_direction()
	if (
		not is_special
		and not grapple_strike_started
		and is_on_floor()
		and not _is_grapple_restricting()
	):
		_begin_ground_combo_attack(_get_ground_combo_family(attack_direction))
		return
	if not is_special and not grapple_strike_started and not is_on_floor():
		_begin_air_double_attack(attack_direction)
		return

	var attack_audio: AudioStreamPlayer = null
	if not grapple_strike_started:
		var attack_audio_key := &"player_smash_swing" if is_special else &"player_attack"
		attack_audio = AudioManager.play_sfx(attack_audio_key, 0.0, 0.0)
	if attack_audio and is_special:
		attack_audio.pitch_scale *= neutral_special_swing_pitch
	is_attacking = true
	current_attack_is_special = is_special
	current_attack_uses_ground_combo = false
	current_attack_uses_air_double = false
	current_attack_uses_grapple_strike = grapple_strike_started
	current_grapple_strike_landed = false
	current_grapple_strike_finished = false
	current_grapple_strike_impact_time = -1.0
	current_grapple_strike_animation_started = false
	if current_attack_uses_grapple_strike:
		_sync_current_grapple_strike_direction()
	attack_timer = 0.0
	if current_attack_is_special:
		velocity.x = 0.0
	var cooldown := player_stats.attack_cooldown
	if current_attack_is_special:
		cooldown *= neutral_special_cooldown_multiplier
	attack_cooldown_timer = cooldown / maxf(0.1, get_momentum_attack_speed_multiplier())
	attack_active_started = false
	attack_vfx_started = not current_attack_is_special
	attack_active_finished = false
	_reset_attack_hitbox_polygon()
	if current_attack_is_special:
		current_attack_body_anim = _get_special_body_animation()
	elif current_attack_uses_grapple_strike:
		current_attack_body_anim = "Grapple_Strike"
	else:
		current_attack_body_anim = _get_attack_body_animation()
	update_equipment_facing()
	if not current_attack_is_special and not current_attack_uses_grapple_strike:
		_play_weapon_attack_anim()

	if player_animation and player_animation.sprite_frames.has_animation(current_attack_body_anim):
		_apply_attack_visual_tuning()
		play_character_anim(current_attack_body_anim)
		if current_gloves and current_gloves.has_method("play_attack_follow_pose"):
			current_gloves.play_attack_follow_pose(attack_direction, _get_equipment_attack_follow_anim())

func _try_resolve_current_grapple_strike() -> void:
	if (
		not current_attack_uses_grapple_strike
		or current_grapple_strike_finished
		or not current_gloves
		or not current_gloves.has_method("resolve_grapple_strike")
	):
		return
	if (
		not current_grapple_strike_animation_started
		or player_animation.animation != &"Grapple_Strike"
		or player_animation.frame < GRAPPLE_STRIKE_IMPACT_FRAME
	):
		return

	_sync_current_grapple_strike_direction()
	current_grapple_strike_landed = bool(
		current_gloves.call("resolve_grapple_strike")
	)
	if current_grapple_strike_landed:
		current_grapple_strike_finished = true
		current_grapple_strike_impact_time = attack_timer
		return

	if (
		not current_gloves.has_method("is_grapple_strike_active")
		or not bool(current_gloves.call("is_grapple_strike_active"))
	):
		current_grapple_strike_finished = true

func _sync_current_grapple_strike_direction() -> void:
	if (
		not current_attack_uses_grapple_strike
		or not current_gloves
		or not current_gloves.has_method("get_grapple_strike_direction")
	):
		return

	var strike_direction: Vector2 = current_gloves.call(
		"get_grapple_strike_direction"
	)
	if strike_direction.length_squared() <= 0.001:
		return
	attack_direction = strike_direction.normalized()
	if absf(attack_direction.x) <= ATTACK_DIRECTION_DEADZONE:
		return

	var next_facing := -1 if attack_direction.x < 0.0 else 1
	if last_direction == next_facing:
		return
	last_direction = next_facing
	if player_animation:
		player_animation.flip_h = last_direction < 0
	update_equipment_facing()

func _cancel_current_grapple_strike() -> void:
	if (
		current_gloves
		and current_gloves.has_method("cancel_grapple_strike")
	):
		current_gloves.call("cancel_grapple_strike", true)
	current_attack_uses_grapple_strike = false
	current_grapple_strike_landed = false
	current_grapple_strike_finished = false
	current_grapple_strike_impact_time = -1.0
	current_grapple_strike_animation_started = false
	_grapple_strike_contact_guard = false

func _cancel_enemy_grapple_combat() -> void:
	if (
		current_gloves
		and current_gloves.has_method("cancel_enemy_grapple_combat")
	):
		current_gloves.call("cancel_enemy_grapple_combat")
	current_attack_uses_grapple_strike = false
	current_grapple_strike_landed = false
	current_grapple_strike_finished = false
	current_grapple_strike_impact_time = -1.0
	current_grapple_strike_animation_started = false
	_grapple_strike_contact_guard = false

func _finish_cancelled_attack() -> void:
	is_attacking = false
	current_attack_is_special = false
	attack_timer = 0.0
	attack_active_started = false
	attack_active_finished = false
	attack_vfx_started = false
	_cancel_ground_combo_attack()
	_cancel_air_double_attack()
	_cancel_neutral_special_vfx()
	attack_hitbox.disable()
	_reset_attack_hitbox_polygon()
	_reset_weapon_visuals()

func _begin_ground_combo_attack(
	family: StringName,
	visual_mode_override: StringName = &""
) -> void:
	var requested_visual_mode := visual_mode_override
	if requested_visual_mode == &"":
		requested_visual_mode = _select_ground_attack_visual_mode(
			Input.get_axis("move_left", "move_right")
		)

	if requested_visual_mode == &"stationary":
		# Stationary combat uses its good double-hit clip as one complete move,
		# rather than chaining through the discarded stationary opener.
		ground_combo_step = 1
	elif (
		family != ground_combo_family
		or ground_combo_reset_timer <= 0.0 and not current_attack_uses_ground_combo
	):
		ground_combo_step = 0
	else:
		ground_combo_step = mini(ground_combo_step + 1, 1)

	ground_combo_family = &"forward"
	ground_combo_reset_timer = 0.0
	ground_combo_queued = false
	ground_combo_queued_family = &""
	ground_combo_active_strike = -1
	ground_attack_visual_mode = requested_visual_mode
	if ground_attack_visual_mode == &"backpedal":
		if visual_mode_override == &"":
			ground_attack_locked_facing = _movement_facing_before_input
		last_direction = ground_attack_locked_facing
	else:
		ground_attack_locked_facing = last_direction
	if ground_attack_visual_mode == &"stationary":
		velocity.x = 0.0
	current_attack_uses_ground_combo = true
	current_attack_is_special = false
	is_attacking = true
	attack_timer = 0.0
	attack_active_started = false
	attack_active_finished = false

	attack_direction = Vector2(float(last_direction), 0.0)
	current_attack_body_anim = "Ground_Attack_Combo_%d" % (ground_combo_step + 1)

	if player_animation:
		player_animation.flip_h = last_direction < 0
		var attack_speed_multiplier := maxf(0.1, get_momentum_attack_speed_multiplier())
		var frame_count := player_animation.sprite_frames.get_frame_count(current_attack_body_anim)
		var animation_fps := player_animation.sprite_frames.get_animation_speed(current_attack_body_anim)
		ground_combo_attack_duration = float(frame_count) / maxf(animation_fps * attack_speed_multiplier, 0.1)
		player_animation.speed_scale = attack_speed_multiplier

	attack_cooldown_timer = player_stats.attack_cooldown / maxf(0.1, get_momentum_attack_speed_multiplier())
	attack_collision_polygon.polygon = _build_ground_combo_sector_polygon()
	attack_hitbox.damage = _build_attack_damage()
	attack_hitbox.disable()
	_sync_attack_hitbox_to_anchor()
	_play_weapon_attack_anim()

	if player_animation and player_animation.sprite_frames.has_animation(current_attack_body_anim):
		_apply_attack_visual_tuning()
		_play_attack_visual_animation(
			_get_ground_combo_visual_animation(Input.get_axis("move_left", "move_right"))
		)
		if current_gloves and current_gloves.has_method("play_attack_follow_pose"):
			current_gloves.play_attack_follow_pose(attack_direction, _get_equipment_attack_follow_anim())

func _update_ground_combo_attack() -> void:
	var strike_frames := _get_ground_combo_strike_frames()
	var next_strike := _get_strike_for_frame(
		player_animation.frame,
		strike_frames[0],
		strike_frames[1]
	)

	if next_strike != ground_combo_active_strike:
		attack_hitbox.disable()
		ground_combo_active_strike = next_strike
		if ground_combo_active_strike >= 0:
			attack_hitbox.damage = _build_attack_damage()
			attack_hitbox.enable()
			_play_double_attack_strike_audio(ground_combo_active_strike)
			_play_flow_vfx_attack_swing(
				attack_direction,
				ground_combo_hitbox_arc_degrees,
				ground_combo_active_strike
			)
	if ground_combo_active_strike >= 0:
		_retry_active_attack_overlaps()

	if attack_timer >= ground_combo_attack_duration:
		_finish_ground_combo_attack()

func _finish_ground_combo_attack() -> void:
	var queued_family := ground_combo_queued_family
	var should_chain := ground_combo_queued and queued_family != &""
	var completed_visual_mode := ground_attack_visual_mode
	var completed_forward_finisher := (
		ground_combo_family == &"forward" and ground_combo_step >= 1
	)
	attack_hitbox.disable()
	attack_collision_polygon.polygon = _default_attack_hitbox_polygon
	is_attacking = false
	current_attack_uses_ground_combo = false
	ground_combo_active_strike = -1
	ground_combo_queued = false
	ground_combo_queued_family = &""
	if completed_forward_finisher:
		_reset_ground_combo_chain()
	else:
		ground_combo_reset_timer = ground_combo_reset_window
	_reset_weapon_visuals()

	if should_chain and not completed_forward_finisher and not is_dead and not is_hurt:
		attack_cooldown_timer = 0.0
		_begin_ground_combo_attack(queued_family, completed_visual_mode)

func _begin_air_double_attack(direction: Vector2) -> void:
	current_attack_is_special = false
	current_attack_uses_ground_combo = false
	current_attack_uses_air_double = true
	is_attacking = true
	attack_timer = 0.0
	attack_active_started = false
	attack_active_finished = false
	air_attack_active_strike = -1
	current_attack_body_anim = "Air_Double_Attack"

	if direction.length() <= ATTACK_DIRECTION_DEADZONE:
		direction = Vector2(float(last_direction), 0.0)
	attack_direction = direction.normalized()
	if abs(attack_direction.x) > ATTACK_DIRECTION_DEADZONE:
		last_direction = int(sign(attack_direction.x))

	if player_animation:
		player_animation.flip_h = last_direction < 0
		var attack_speed_multiplier := maxf(0.1, get_momentum_attack_speed_multiplier())
		var frame_count := player_animation.sprite_frames.get_frame_count(current_attack_body_anim)
		var animation_fps := player_animation.sprite_frames.get_animation_speed(current_attack_body_anim)
		air_attack_duration = float(frame_count) / maxf(animation_fps * attack_speed_multiplier, 0.1)
		player_animation.speed_scale = attack_speed_multiplier

	attack_cooldown_timer = player_stats.attack_cooldown / maxf(0.1, get_momentum_attack_speed_multiplier())
	attack_collision_polygon.polygon = _build_attack_sector_polygon(
		air_attack_hitbox_arc_degrees,
		air_attack_hitbox_radius
	)
	attack_hitbox.damage = _build_attack_damage()
	attack_hitbox.disable()
	_sync_attack_hitbox_to_anchor()
	_play_weapon_attack_anim()

	if player_animation and player_animation.sprite_frames.has_animation(current_attack_body_anim):
		_apply_attack_visual_tuning()
		play_character_anim(current_attack_body_anim)
		if current_gloves and current_gloves.has_method("play_attack_follow_pose"):
			current_gloves.play_attack_follow_pose(attack_direction, _get_equipment_attack_follow_anim())

func _update_air_double_attack() -> void:
	var next_strike := _get_strike_for_frame(
		player_animation.frame,
		air_attack_first_strike_frames,
		air_attack_second_strike_frames
	)

	if next_strike != air_attack_active_strike:
		attack_hitbox.disable()
		air_attack_active_strike = next_strike
		if air_attack_active_strike >= 0:
			attack_hitbox.damage = _build_attack_damage()
			attack_hitbox.enable()
			_play_double_attack_strike_audio(air_attack_active_strike)
			_play_flow_vfx_attack_swing(
				attack_direction,
				air_attack_hitbox_arc_degrees,
				air_attack_active_strike
			)
	if air_attack_active_strike >= 0:
		_retry_active_attack_overlaps()

	if attack_timer >= air_attack_duration:
		_finish_air_double_attack()

func _retry_active_attack_overlaps() -> void:
	if (
		not attack_hitbox
		or not attack_hitbox.active
		or not attack_hitbox.monitoring
	):
		return
	for area in attack_hitbox.get_overlapping_areas():
		attack_hitbox.call("_on_area_entered", area)

func _finish_air_double_attack() -> void:
	attack_hitbox.disable()
	attack_collision_polygon.polygon = _default_attack_hitbox_polygon
	is_attacking = false
	current_attack_uses_air_double = false
	air_attack_active_strike = -1
	_reset_weapon_visuals()

func _get_ground_combo_strike_frames() -> Array[Vector2i]:
	if ground_attack_visual_mode == &"stationary":
		return [
			stationary_combo_2_first_strike_frames,
			stationary_combo_2_second_strike_frames
		]
	if ground_attack_visual_mode == &"backpedal":
		if ground_combo_step == 0:
			return [
				backpedal_combo_1_first_strike_frames,
				backpedal_combo_1_second_strike_frames
			]
		return [
			backpedal_combo_2_first_strike_frames,
			backpedal_combo_2_second_strike_frames
		]

	match current_attack_body_anim:
		"Ground_Attack_Combo_1":
			return [ground_combo_1_first_strike_frames, ground_combo_1_second_strike_frames]
		"Ground_Attack_Combo_2":
			return [ground_combo_2_first_strike_frames, ground_combo_2_second_strike_frames]
		_:
			return [Vector2i(-1, -1), Vector2i(-1, -1)]

func _get_strike_for_frame(frame: int, first_frames: Vector2i, second_frames: Vector2i) -> int:
	if frame >= first_frames.x and frame <= first_frames.y:
		return 0
	if frame >= second_frames.x and frame <= second_frames.y:
		return 1
	return -1

func _play_double_attack_strike_audio(strike_index: int) -> void:
	var strike_audio := AudioManager.play_sfx(&"player_attack", 0.0, 0.0)
	if not strike_audio:
		return
	strike_audio.pitch_scale *= (
		double_attack_first_strike_pitch
		if strike_index == 0
		else double_attack_second_strike_pitch
	)

func _reset_ground_combo_chain() -> void:
	ground_combo_family = &""
	ground_combo_step = -1
	ground_combo_reset_timer = 0.0
	ground_combo_queued = false
	ground_combo_queued_family = &""
	ground_attack_locked_facing = last_direction

func _cancel_ground_combo_attack() -> void:
	current_attack_uses_ground_combo = false
	ground_combo_active_strike = -1
	_reset_ground_combo_chain()

func _cancel_air_double_attack() -> void:
	current_attack_uses_air_double = false
	air_attack_active_strike = -1

func _get_ground_combo_family(_direction: Vector2) -> StringName:
	return &"forward"

func _build_ground_combo_sector_polygon() -> PackedVector2Array:
	return _build_attack_sector_polygon(
		ground_combo_hitbox_arc_degrees,
		ground_combo_forward_hitbox_radius
	)

func _build_attack_sector_polygon(arc_degrees: float, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	var half_arc := deg_to_rad(arc_degrees * 0.5)
	const ARC_SEGMENTS := 6
	for index in range(ARC_SEGMENTS + 1):
		var weight := float(index) / float(ARC_SEGMENTS)
		var angle := lerpf(-half_arc, half_arc, weight)
		points.append(Vector2.from_angle(angle) * radius)
	return points

func _build_circle_hitbox_polygon(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	const CIRCLE_SEGMENTS := 16
	for index in range(CIRCLE_SEGMENTS):
		var angle := TAU * float(index) / float(CIRCLE_SEGMENTS)
		points.append(Vector2.from_angle(angle) * radius)
	return points

func _reset_attack_hitbox_polygon() -> void:
	if attack_collision_polygon:
		attack_collision_polygon.set_deferred(
			"polygon",
			_default_attack_hitbox_polygon
		)

func can_start_attack(is_special := false) -> bool:
	if is_dead or is_hurt or is_attacking or attack_cooldown_timer > 0.0:
		return false
	if is_special and not is_on_floor():
		return false
	if (
		current_chest
		and current_chest.has_method("is_dash_active")
		and bool(current_chest.call("is_dash_active"))
	):
		return false
	return true

func _can_process_jump_input(attack_requested_this_frame: bool) -> bool:
	return (
		not attack_requested_this_frame
		and not _is_attack_movement_committed()
		and not _tutorial_is_consuming_ui_accept()
		and not is_near_interactable
	)

func _tutorial_is_consuming_ui_accept() -> bool:
	for controller in get_tree().get_nodes_in_group("tutorial_controllers"):
		if (
			controller.has_method("is_consuming_ui_accept")
			and bool(controller.call("is_consuming_ui_accept"))
		):
			return true
	return false

func can_start_dash() -> bool:
	if (
		is_dead
		or is_hurt
		or save_point_interaction_active
		or is_meditating
		or is_ledge_hanging
		or is_ledge_climbing
	):
		return false
	if not is_attacking:
		return true
	return _is_attack_in_dash_cancel_window()

func prepare_for_dash(direction: int = 0) -> void:
	var should_cancel_attack := (
		is_attacking and _is_attack_in_dash_cancel_window()
	)
	_cancel_enemy_grapple_combat()
	if should_cancel_attack:
		_finish_cancelled_attack()
	if direction != 0:
		last_direction = signi(direction)
		if player_animation:
			player_animation.flip_h = last_direction < 0
		update_equipment_facing()
	_dash_direction_intent_timer = 0.0

func _update_dash_direction_intent(horizontal_input: float, delta: float) -> void:
	if not is_zero_approx(horizontal_input):
		_dash_direction_intent = int(signf(horizontal_input))
		_dash_direction_intent_timer = dash_direction_input_buffer_time
		return
	_dash_direction_intent_timer = maxf(0.0, _dash_direction_intent_timer - delta)

func get_dash_direction_intent() -> int:
	var held_direction := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(held_direction):
		return int(signf(held_direction))
	if _dash_direction_intent_timer > 0.0 and _dash_direction_intent != 0:
		return _dash_direction_intent
	return last_direction if last_direction != 0 else 1

func _is_attack_movement_committed() -> bool:
	if not is_attacking:
		return false
	if current_attack_is_special:
		return not attack_active_finished
	if current_attack_uses_ground_combo and ground_attack_visual_mode == &"stationary":
		if not player_animation:
			return true
		return player_animation.frame <= stationary_combo_2_second_strike_frames.y
	if not current_attack_uses_ground_combo and not current_attack_uses_air_double:
		return not attack_active_finished
	return false

func _is_attack_in_dash_cancel_window() -> bool:
	if not is_attacking:
		return true
	if current_attack_is_special:
		var attack_end := (
			neutral_special_windup
			+ neutral_special_active_time
			+ neutral_special_recovery
		)
		return (
			attack_timer < neutral_special_windup
			or attack_active_finished
			and attack_timer >= attack_end - neutral_special_dash_cancel_window
		)
	if current_attack_uses_grapple_strike:
		return (
			current_grapple_strike_landed
			or current_grapple_strike_finished
		)
	if current_attack_uses_ground_combo:
		var strike_frames := _get_ground_combo_strike_frames()
		return (
			_has_not_reached_attack_strike_frames(strike_frames)
			or _has_passed_attack_strike_frames(strike_frames)
		)
	if current_attack_uses_air_double:
		var strike_frames: Array[Vector2i] = [
			air_attack_first_strike_frames,
			air_attack_second_strike_frames,
		]
		return (
			_has_not_reached_attack_strike_frames(strike_frames)
			or _has_passed_attack_strike_frames(strike_frames)
		)
	return not attack_active_started or attack_active_finished

func _has_not_reached_attack_strike_frames(strike_frames: Array[Vector2i]) -> bool:
	if not player_animation:
		return false
	var first_active_frame := 1000000
	for frame_window in strike_frames:
		if frame_window.x >= 0:
			first_active_frame = mini(first_active_frame, frame_window.x)
	return first_active_frame < 1000000 and player_animation.frame < first_active_frame

func _has_passed_attack_strike_frames(strike_frames: Array[Vector2i]) -> bool:
	if not player_animation:
		return false
	var final_active_frame := -1
	for frame_window in strike_frames:
		final_active_frame = maxi(final_active_frame, frame_window.y)
	return final_active_frame >= 0 and player_animation.frame > final_active_frame

func _cancel_attack_for_dash() -> void:
	if current_attack_uses_grapple_strike:
		_cancel_current_grapple_strike()
	_finish_cancelled_attack()

func _play_weapon_attack_anim() -> void:
	if not weapon_animation_player:
		return

	if not weapon_animation_player.has_animation("quick_attack"):
		return

	weapon_animation_player.stop()
	weapon_animation_player.play("quick_attack")

func _play_weapon_pose_anim(body_anim: String) -> void:
	if not weapon_animation_player:
		return

	var pose_anim := "weapon_%s" % body_anim.to_lower()
	if not weapon_animation_player.has_animation(pose_anim):
		pose_anim = "weapon_idle"
	if not weapon_animation_player.has_animation(pose_anim):
		return
	if current_weapon_pose_anim == pose_anim and weapon_animation_player.current_animation == pose_anim:
		return

	current_weapon_pose_anim = pose_anim
	weapon_animation_player.play(pose_anim)

func _reset_weapon_visuals() -> void:
	if player_animation:
		player_animation.scale = _player_default_visual_scale
		player_animation.position = _player_default_visual_position
		player_animation.speed_scale = 1.0
	if attack_swing_root:
		attack_swing_root.rotation = 0.0

	if not weapon_animation_player:
		return

	var weapon_pose_body_anim := current_body_anim
	if (
		current_body_anim.ends_with(STATIONARY_ATTACK_SUFFIX)
		or current_body_anim.ends_with(BACKPEDAL_ATTACK_SUFFIX)
	):
		weapon_pose_body_anim = current_attack_body_anim
	if weapon_animation_player.has_animation("weapon_%s" % weapon_pose_body_anim.to_lower()):
		_play_weapon_pose_anim(weapon_pose_body_anim)
		return

	if not weapon_animation_player.has_animation("RESET"):
		return

	weapon_animation_player.play("RESET")
	weapon_animation_player.seek(0.0, true)

func _apply_attack_visual_tuning() -> void:
	if not player_animation:
		return

	var scale_multiplier := 1.0
	var visual_offset := Vector2.ZERO
	if current_attack_is_special:
		scale_multiplier = neutral_special_visual_scale_multiplier
		visual_offset = neutral_special_visual_offset
	elif current_attack_body_anim.begins_with("Ground_Attack_Combo_"):
		if ground_attack_visual_mode == &"stationary":
			scale_multiplier = ground_combo_stationary_visual_scale_multiplier
		elif ground_attack_visual_mode == &"backpedal":
			scale_multiplier = ground_combo_backpedal_visual_scale_multiplier
		elif current_attack_body_anim == "Ground_Attack_Combo_2":
			scale_multiplier = ground_combo_2_moving_visual_scale_multiplier
		else:
			scale_multiplier = ground_combo_forward_visual_scale_multiplier
	elif current_attack_body_anim == "Air_Double_Attack":
		scale_multiplier = air_attack_visual_scale_multiplier
	if player_animation.flip_h:
		visual_offset.x = -visual_offset.x
	player_animation.scale = _player_default_visual_scale * scale_multiplier
	player_animation.position = _player_default_visual_position + visual_offset

func _on_player_animation_frame_changed() -> void:
	if is_attacking:
		_apply_attack_visual_tuning()

func _select_ground_attack_visual_mode(dir: float) -> StringName:
	if absf(dir) <= 0.01 or absf(velocity.x) < STATIONARY_ATTACK_MIN_HORIZONTAL_SPEED:
		return &"stationary"
	var committed_facing := float(_movement_facing_before_input)
	if dir * committed_facing < 0.0 and velocity.x * committed_facing < 0.0:
		return &"backpedal"
	return &"moving"

func _get_ground_combo_visual_animation(_dir: float) -> StringName:
	var moving_animation := StringName(current_attack_body_anim)
	if not current_attack_uses_ground_combo:
		return moving_animation

	var suffix := (
		BACKPEDAL_ATTACK_SUFFIX
		if ground_attack_visual_mode == &"backpedal"
		else STATIONARY_ATTACK_SUFFIX
	)
	if ground_attack_visual_mode == &"moving":
		return moving_animation

	var variant_animation := StringName(
		"%s%s" % [current_attack_body_anim, suffix]
	)
	return (
		variant_animation
		if player_animation.sprite_frames.has_animation(variant_animation)
		else moving_animation
	)

func _play_attack_visual_animation(body_anim: StringName) -> void:
	var moving_animation := StringName(current_attack_body_anim)
	var stationary_animation := StringName(
		"%s%s" % [current_attack_body_anim, STATIONARY_ATTACK_SUFFIX]
	)
	var backpedal_animation := StringName(
		"%s%s" % [current_attack_body_anim, BACKPEDAL_ATTACK_SUFFIX]
	)
	var preserve_progress := (
		StringName(current_body_anim) == moving_animation
		or StringName(current_body_anim) == stationary_animation
		or StringName(current_body_anim) == backpedal_animation
	)
	var previous_frame := player_animation.frame
	var previous_progress := player_animation.frame_progress

	play_character_anim(String(body_anim))
	if not preserve_progress:
		return

	var frame_count := player_animation.sprite_frames.get_frame_count(body_anim)
	if frame_count <= 0:
		return
	player_animation.set_frame_and_progress(
		mini(previous_frame, frame_count - 1),
		previous_progress
	)

func _get_attack_input_direction() -> Vector2:
	var direction := AimHelperScript.get_aim_direction(
		self,
		global_position,
		Vector2(float(last_direction), 0.0),
		ATTACK_DIRECTION_DEADZONE
	)

	if abs(direction.x) > ATTACK_DIRECTION_DEADZONE:
		last_direction = int(sign(direction.x))
		if player_animation:
			player_animation.flip_h = direction.x < 0.0

	return direction

func _get_attack_body_animation() -> String:
	if not player_animation or not player_animation.sprite_frames:
		return "Ground_Attack_Combo_1"

	if is_on_floor() and not _is_grapple_restricting():
		return "Ground_Attack_Combo_1"

	var attack_anim := "Attack_Forward"
	if attack_direction.y < -0.6 and abs(attack_direction.y) >= abs(attack_direction.x):
		attack_anim = "Attack_Up"
	elif attack_direction.y > 0.6 and abs(attack_direction.y) >= abs(attack_direction.x):
		attack_anim = "Attack_Down"
	elif abs(attack_direction.y) > 0.25 and abs(attack_direction.x) > 0.25:
		attack_anim = "Attack_Diagonal"

	if player_animation.sprite_frames.has_animation(attack_anim):
		return attack_anim
	if player_animation.sprite_frames.has_animation("Air_Double_Attack"):
		return "Air_Double_Attack"
	return "Ground_Attack_Combo_1"

func _get_special_body_animation() -> String:
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation("Neutral_Special_Attack"):
		return "Neutral_Special_Attack"
	return "Ground_Attack_Combo_1"

func _get_equipment_attack_follow_anim() -> String:
	return current_attack_body_anim

func _is_grapple_restricting() -> bool:
	if current_gloves and current_gloves.has_method("is_base_grapple_restricting"):
		return current_gloves.is_base_grapple_restricting()
	return false

func _apply_attack_direction() -> void:
	var direction := attack_direction
	if direction.length() <= ATTACK_DIRECTION_DEADZONE:
		direction = Vector2(float(last_direction), 0.0)
	direction = direction.normalized()

	if attack_swing_root and equipment_mount:
		var local_direction := equipment_mount.global_transform.basis_xform_inv(direction).normalized()
		attack_swing_root.rotation = local_direction.angle()
		_sync_attack_hitbox_to_anchor()

func _sync_attack_hitbox_to_anchor() -> void:
	if not attack_hitbox:
		return
	if current_attack_is_special:
		attack_hitbox.global_transform = global_transform
		attack_hitbox.global_position = _get_neutral_special_ground_contact_position()
		return
	if current_attack_uses_ground_combo or current_attack_uses_air_double:
		attack_hitbox.global_transform = global_transform
		attack_hitbox.global_rotation = attack_direction.angle()
		return
	if not attack_hitbox_anchor:
		return

	attack_hitbox.global_transform = attack_hitbox_anchor.global_transform

func _build_attack_damage() -> DamageData:
	var data := DamageData.new()
	if current_attack_is_special:
		data.amount = roundi(
			float(player_stats.attack_damage)
			* neutral_special_damage_multiplier
			* player_stats.skill_damage_multiplier
			* get_momentum_attack_damage_multiplier()
		)
		data.hitstun = neutral_special_hitstun
		data.hit_pause = neutral_special_hit_pause
		# The ground impact requests its shake even when the smash misses.
		data.use_receiver_screen_shake_fallback = false
	else:
		var profile := _get_current_attack_profile()
		var attack_upgrade_scale := (
			float(player_stats.attack_damage)
			/ ATTACK_PROFILE_BASE_DAMAGE
		)
		data.amount = maxi(
			1,
			roundi(
				float(profile.get(&"damage", ATTACK_PROFILE_BASE_DAMAGE))
				* attack_upgrade_scale
				* get_momentum_attack_damage_multiplier()
			)
		)
		data.hitstun = float(profile.get(&"hitstun", player_stats.hurt_time))
		data.hit_pause = float(profile.get(&"hit_pause", player_stats.hit_pause))
		data.screen_shake_strength = float(profile.get(&"screen_shake", 0.0))
		data.screen_shake_duration = 0.06
		data.use_receiver_screen_shake_fallback = false

	var knockback_direction := attack_direction
	if knockback_direction.length() <= ATTACK_DIRECTION_DEADZONE:
		knockback_direction = Vector2(float(last_direction), 0.0)
	if current_attack_is_special:
		data.knockback = (
			knockback_direction.normalized()
			* player_stats.knockback_strength
			* neutral_special_knockback_multiplier
		)
	else:
		var profile := _get_current_attack_profile()
		var knockback_upgrade_scale := (
			player_stats.knockback_strength
			/ ATTACK_PROFILE_BASE_KNOCKBACK
		)
		data.knockback = (
			knockback_direction.normalized()
			* float(profile.get(&"knockback", ATTACK_PROFILE_BASE_KNOCKBACK))
			* knockback_upgrade_scale
		)
	return data

func _get_hurtbox_feedback_position(target_hurtbox: HurtboxComponent) -> Vector2:
	for child in target_hurtbox.get_children():
		var collision_shape := child as CollisionShape2D
		if collision_shape and not collision_shape.disabled and collision_shape.shape:
			return collision_shape.global_position
	return target_hurtbox.global_position

func modify_outgoing_hit_damage(
	damage: DamageData,
	target_hurtbox: HurtboxComponent
) -> DamageData:
	if not target_hurtbox:
		return damage

	var target_position := target_hurtbox.global_position
	var target_owner := target_hurtbox.hurtbox_owner as Node2D
	if target_owner:
		target_position = target_owner.global_position
	damage.hit_position = _get_hurtbox_feedback_position(target_hurtbox)
	if not current_attack_is_special:
		return damage

	var radial_direction := (
		target_position
		- _get_neutral_special_ground_contact_position()
	)
	var target_distance := radial_direction.length()
	if radial_direction.length() <= ATTACK_DIRECTION_DEADZONE:
		radial_direction = Vector2(float(last_direction), 0.0)
	radial_direction = radial_direction.normalized()
	radial_direction.y -= neutral_special_knockback_lift
	radial_direction = radial_direction.normalized()

	var full_force_radius := (
		neutral_special_aoe_radius
		* neutral_special_full_force_radius_ratio
	)
	var falloff_range := maxf(
		neutral_special_aoe_radius - full_force_radius,
		0.001
	)
	var linear_falloff := clampf(
		(target_distance - full_force_radius) / falloff_range,
		0.0,
		1.0
	)
	var smooth_falloff := linear_falloff * linear_falloff * (3.0 - 2.0 * linear_falloff)
	damage.amount = maxi(
		1,
		roundi(
			float(damage.amount)
			* lerpf(1.0, neutral_special_edge_damage_ratio, smooth_falloff)
		)
	)
	damage.hitstun = lerpf(
		neutral_special_hitstun,
		neutral_special_edge_hitstun,
		smooth_falloff
	)
	damage.knockback = (
		radial_direction
		* player_stats.knockback_strength
		* neutral_special_knockback_multiplier
		* lerpf(1.0, neutral_special_edge_knockback_ratio, smooth_falloff)
	)
	return damage

func _get_current_attack_profile() -> Dictionary:
	if current_attack_uses_air_double:
		return (
			ATTACK_PROFILE_AIR_SECOND
			if air_attack_active_strike == 1
			else ATTACK_PROFILE_AIR_FIRST
		)
	if not current_attack_uses_ground_combo:
		return ATTACK_PROFILE_BASIC

	var is_second_strike := ground_combo_active_strike == 1
	match ground_attack_visual_mode:
		&"stationary":
			return (
				ATTACK_PROFILE_STATIONARY_SECOND
				if is_second_strike
				else ATTACK_PROFILE_STATIONARY_FIRST
			)
		&"backpedal":
			if ground_combo_step <= 0:
				return ATTACK_PROFILE_BACKPEDAL_OPENER
			return (
				ATTACK_PROFILE_BACKPEDAL_FINISHER_SECOND
				if is_second_strike
				else ATTACK_PROFILE_BACKPEDAL_FINISHER_FIRST
			)
		_:
			if ground_combo_step <= 0:
				return ATTACK_PROFILE_BASIC
			return (
				ATTACK_PROFILE_MOVING_FINISHER_SECOND
				if is_second_strike
				else ATTACK_PROFILE_MOVING_FINISHER_FIRST
			)

func set_action_points(current: int, maximum: int = max_action_points) -> void:
	max_action_points = maximum
	current_action_points = current
	_ensure_action_point_timers()

func spend_action_points(amount: int) -> bool:
	if amount <= 0:
		return true
	_ensure_action_point_timers()
	if current_action_points < amount:
		return false

	var spent := 0
	for i in range(max_action_points - 1, -1, -1):
		if _action_point_recharge_timers[i] <= 0.0:
			_action_point_recharge_timers[i] = action_point_recharge_time
			spent += 1
			if spent >= amount:
				break

	current_action_points = _count_available_action_points()
	return true

func restore_action_points(amount: int) -> void:
	if amount <= 0:
		return

	_ensure_action_point_timers()
	var restored := 0
	for i in max_action_points:
		if _action_point_recharge_timers[i] > 0.0:
			_action_point_recharge_timers[i] = 0.0
			restored += 1
			if restored >= amount:
				break

	current_action_points = _count_available_action_points()

func refill_action_points() -> void:
	_ensure_action_point_timers()
	for i in _action_point_recharge_timers.size():
		_action_point_recharge_timers[i] = 0.0
	current_action_points = max_action_points
	AudioManager.play_ui(&"loot_special_item")

func set_momentum(value: float) -> void:
	momentum = value
	if momentum >= 100.0 and not _flow_state_active:
		_enter_flow_state()
	elif momentum < 100.0 and _flow_state_active:
		_exit_flow_state()

func collect_thread_knots(amount: int) -> void:
	var gained_amount := maxi(0, amount)
	var previous_thread_knots := thread_knot_count
	thread_knot_count += gained_amount
	if _coin_pickup_audio_timer <= 0.0:
		AudioManager.play_ui(&"coin_pickup")
		_coin_pickup_audio_timer = coin_pickup_audio_cooldown
	if gained_amount > 0 and previous_thread_knots <= 0 and not _thread_knot_tutorial_shown:
		_thread_knot_tutorial_shown = true
		if not _try_show_tutorial_thread_knot_prompt():
			_show_first_thread_knot_message()

func _try_show_tutorial_thread_knot_prompt() -> bool:
	for controller in get_tree().get_nodes_in_group("tutorial_controllers"):
		if controller.has_method("handle_first_thread_knot_tutorial"):
			var handled: bool = controller.handle_first_thread_knot_tutorial()
			if handled:
				return true
	return false

func _show_first_thread_knot_message() -> void:
	if first_thread_knot_message.is_empty():
		return

	var box: Node = get_tree().get_first_node_in_group("demo_message_box")
	if not box:
		box = DEMO_MESSAGE_BOX_SCENE.instantiate()
		var parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
		parent.add_child(box)
	if box.has_method("show_message"):
		box.call("show_message", first_thread_knot_message)

func can_weave_stat_upgrade(cost: int) -> bool:
	return thread_knot_count >= maxi(0, cost)

func weave_stat_upgrade(stat_id: StringName, cost: int = 0) -> bool:
	var upgrade_cost := maxi(0, cost)
	if not player_stats or not can_weave_stat_upgrade(upgrade_cost):
		return false

	var previous_max_health := player_stats.max_health
	if not player_stats.apply_stat_upgrade(stat_id):
		return false

	if upgrade_cost > 0:
		thread_knot_count -= upgrade_cost

	_apply_player_stats_after_upgrade(previous_max_health)
	AudioManager.play_ui(&"loot_special_item")
	stat_upgraded.emit(stat_id)
	return true

func get_weave_stat_display(stat_id: StringName) -> String:
	if not player_stats:
		return ""
	return player_stats.get_stat_display_value(stat_id)

func get_weave_stat_preview(stat_id: StringName) -> String:
	if not player_stats:
		return ""
	return player_stats.get_next_stat_display_value(stat_id)

func get_weave_stat_points(stat_id: StringName) -> int:
	if not player_stats:
		return 0
	return player_stats.get_upgrade_points(stat_id)

func _apply_player_stats_after_upgrade(previous_max_health: int) -> void:
	max_health = player_stats.max_health
	if health_component:
		var health_delta := maxi(0, player_stats.max_health - previous_max_health)
		health_component.max_health = player_stats.max_health
		health_component.current_health = clampi(health_component.current_health + health_delta, 0, health_component.max_health)
		health_component.health_changed.emit(health_component.current_health, health_component.max_health)
	_sync_hud()

func _sync_hud() -> void:
	if not is_inside_tree():
		return

	var hud := get_tree().get_first_node_in_group("combat_hud")
	if not hud:
		return

	if hud.has_method("set_health") and health_component:
		hud.set_health(health_component.current_health, health_component.max_health)
	if hud.has_method("set_action_points"):
		hud.set_action_points(current_action_points, max_action_points)
	if hud.has_method("set_action_point_cooldowns"):
		hud.set_action_point_cooldowns(_get_action_point_cooldown_ratios())
	if hud.has_method("set_momentum"):
		hud.set_momentum(momentum)
	if hud.has_method("set_momentum_state"):
		hud.set_momentum_state(_momentum_state, _flow_state_active)
	if hud.has_method("set_thread_knots"):
		hud.set_thread_knots(thread_knot_count)
	if hud.has_method("set_pattern_texture"):
		hud.set_pattern_texture(
			current_pattern.hud_overlay if current_pattern else null,
			current_pattern != null
		)

func apply_equipment_pattern(pattern: EquipmentPattern) -> void:
	current_pattern = pattern
	_ensure_pattern_visual()
	if _pattern_visual:
		_pattern_visual.visible = current_pattern != null
		var pattern_material := _pattern_visual.material as ShaderMaterial
		if pattern_material:
			pattern_material.set_shader_parameter(
				"pattern_texture",
				current_pattern.textile_texture if current_pattern else null
			)
	_sync_hud()

func get_pattern_action_point_recharge_multiplier() -> float:
	return current_pattern.action_point_recharge_multiplier if current_pattern else 1.0

func get_pattern_momentum_generation_multiplier() -> float:
	return current_pattern.momentum_generation_multiplier if current_pattern else 1.0

func _ensure_pattern_visual() -> void:
	if _pattern_visual or not player_animation:
		return
	_pattern_visual = AnimatedSprite2D.new()
	_pattern_visual.name = "PatternClothingOverlay"
	_pattern_visual.sprite_frames = player_animation.sprite_frames
	_pattern_visual.z_index = player_animation.z_index + 1
	_pattern_visual.visible = false
	var pattern_material := ShaderMaterial.new()
	pattern_material.shader = PATTERN_OVERLAY_SHADER
	_pattern_visual.material = pattern_material
	add_child(_pattern_visual)
	_sync_pattern_visual_transform()

func _sync_pattern_visual_transform() -> void:
	if not _pattern_visual or not player_animation:
		return
	_pattern_visual.sprite_frames = player_animation.sprite_frames
	_pattern_visual.animation = player_animation.animation
	_pattern_visual.frame = player_animation.frame
	_pattern_visual.frame_progress = player_animation.frame_progress
	_pattern_visual.speed_scale = 0.0
	_pattern_visual.position = player_animation.position
	_pattern_visual.rotation = player_animation.rotation
	_pattern_visual.scale = player_animation.scale
	_pattern_visual.flip_h = player_animation.flip_h
	_pattern_visual.flip_v = player_animation.flip_v
	_pattern_visual.modulate = player_animation.modulate

func _process_action_point_recharge(delta: float) -> void:
	_ensure_action_point_timers()
	var meditation_multiplier := meditation_ap_recharge_multiplier if is_meditating else 1.0
	var recharge_delta := delta * get_momentum_action_point_recharge_multiplier() * player_stats.action_point_recharge_multiplier * get_pattern_action_point_recharge_multiplier() * meditation_multiplier
	var changed := false
	if is_meditating:
		var target_index := _get_meditation_action_point_target_index()
		if target_index >= 0:
			_action_point_recharge_timers[target_index] = maxf(
				0.0,
				_action_point_recharge_timers[target_index] - recharge_delta
			)
			changed = true
	else:
		for i in _action_point_recharge_timers.size():
			if _action_point_recharge_timers[i] <= 0.0:
				continue

			_action_point_recharge_timers[i] = maxf(0.0, _action_point_recharge_timers[i] - recharge_delta)
			changed = true

	if changed:
		current_action_points = _count_available_action_points()
		_sync_hud()

func _get_meditation_action_point_target_index() -> int:
	var target_index := -1
	var shortest_remaining_time := INF
	for i in _action_point_recharge_timers.size():
		var remaining_time := _action_point_recharge_timers[i]
		if remaining_time <= 0.0 or remaining_time >= shortest_remaining_time:
			continue

		target_index = i
		shortest_remaining_time = remaining_time
	return target_index

func _ensure_action_point_timers() -> void:
	while _action_point_recharge_timers.size() < max_action_points:
		_action_point_recharge_timers.append(0.0)
	while _action_point_recharge_timers.size() > max_action_points:
		_action_point_recharge_timers.pop_back()

func _count_available_action_points() -> int:
	_ensure_action_point_timers()
	var available := 0
	for timer in _action_point_recharge_timers:
		if timer <= 0.0:
			available += 1
	return clampi(available, 0, max_action_points)

func _get_action_point_cooldown_ratios() -> Array[float]:
	_ensure_action_point_timers()
	var ratios: Array[float] = []
	var recharge_time := maxf(action_point_recharge_time, 0.001)
	for timer in _action_point_recharge_timers:
		ratios.append(clampf(timer / recharge_time, 0.0, 1.0))
	return ratios

func report_momentum_action(category: StringName, strength: float = 1.0) -> void:
	if strength <= 0.0:
		return

	_apply_momentum_category(category, strength)

	if _pending_use_after_swap and category != MOMENTUM_CATEGORY_EQUIPMENT_SWAP and category != MOMENTUM_CATEGORY_USE_AFTER_SWAP and category != MOMENTUM_CATEGORY_MOVEMENT:
		_pending_use_after_swap = false
		_use_after_swap_timer = 0.0
		_apply_momentum_category(MOMENTUM_CATEGORY_USE_AFTER_SWAP, 1.0)

func start_dash_iframe(duration: float, direction := Vector2.ZERO) -> void:
	var iframe_multiplier := maxf(
		1.0,
		get_momentum_dash_iframe_multiplier()
	)
	var safe_duration := maxf(0.0, duration) * iframe_multiplier
	_dash_iframe_timer = maxf(_dash_iframe_timer, safe_duration)
	_dash_contact_phase_timer = maxf(
		_dash_contact_phase_timer,
		safe_duration
	)
	_set_dash_contact_phasing(_dash_contact_phase_timer > 0.0)
	_play_dash_iframe_vfx(direction, _dash_iframe_timer)

func _set_dash_contact_phasing(is_active: bool) -> void:
	if _dash_contact_phasing_active == is_active:
		return
	_dash_contact_phasing_active = is_active


func is_dash_contact_phasing() -> bool:
	return _dash_contact_phasing_active

func stop_dash_on_enemy_contact(_enemy_position_x: float) -> void:
	if current_chest and current_chest.has_method("stop_dash_on_enemy_contact"):
		current_chest.stop_dash_on_enemy_contact()
	# Enemy contact is Area2D-based, so it does not participate in
	# move_and_slide(). Restore the position from immediately before this
	# physics step to make it behave like a solid wall during the dash.
	global_position.x = _position_before_movement.x
	velocity.x = 0.0

func _play_dash_iframe_vfx(direction: Vector2, duration: float) -> void:
	if not DASH_IFRAME_VFX_SCENE or not is_inside_tree():
		return

	if not is_instance_valid(_dash_iframe_vfx_instance):
		_dash_iframe_vfx_instance = DASH_IFRAME_VFX_SCENE.instantiate() as Node2D
		if not _dash_iframe_vfx_instance:
			return
		add_child(_dash_iframe_vfx_instance)
		_dash_iframe_vfx_instance.position = Vector2(0.0, -36.0)

	var dash_direction := direction
	if dash_direction.length_squared() <= 0.001:
		dash_direction = Vector2(float(last_direction), 0.0)
	if _dash_iframe_vfx_instance.has_method("play"):
		_dash_iframe_vfx_instance.call(
			"play",
			dash_direction.normalized(),
			duration
		)

func _cancel_dash_iframe() -> void:
	_dash_iframe_timer = 0.0
	_dash_contact_phase_timer = 0.0
	_set_dash_contact_phasing(false)
	if is_instance_valid(_dash_iframe_vfx_instance):
		if _dash_iframe_vfx_instance.has_method("cancel"):
			_dash_iframe_vfx_instance.call("cancel")
		else:
			_dash_iframe_vfx_instance.queue_free()
	_dash_iframe_vfx_instance = null

func get_momentum_action_point_recharge_multiplier() -> float:
	return _get_momentum_multiplier(momentum_action_point_recharge_low, momentum_action_point_recharge_mid, momentum_action_point_recharge_high, momentum_action_point_recharge_flow)

func get_momentum_move_speed_multiplier() -> float:
	return _get_momentum_multiplier(momentum_move_speed_low, momentum_move_speed_mid, momentum_move_speed_high, momentum_move_speed_flow)

func get_momentum_jump_multiplier() -> float:
	return _get_momentum_multiplier(momentum_jump_low, momentum_jump_mid, momentum_jump_high, momentum_jump_flow)

func get_momentum_air_control_multiplier() -> float:
	return _get_momentum_multiplier(momentum_air_control_low, momentum_air_control_mid, momentum_air_control_high, momentum_air_control_flow)

func get_momentum_grapple_speed_multiplier() -> float:
	return _get_momentum_multiplier(momentum_grapple_speed_low, momentum_grapple_speed_mid, momentum_grapple_speed_high, momentum_grapple_speed_flow)

func get_momentum_grapple_pull_multiplier() -> float:
	return _get_momentum_multiplier(momentum_grapple_pull_low, momentum_grapple_pull_mid, momentum_grapple_pull_high, momentum_grapple_pull_flow)

func get_momentum_attack_speed_multiplier() -> float:
	if _flow_state_active:
		return momentum_attack_speed_flow
	if momentum >= momentum_high_threshold:
		return momentum_attack_speed_high
	return _get_momentum_multiplier(momentum_attack_speed_low, momentum_attack_speed_mid, momentum_attack_speed_high, momentum_attack_speed_flow)

func get_momentum_attack_damage_multiplier() -> float:
	if _flow_state_active:
		return momentum_attack_damage_flow
	if momentum >= momentum_high_threshold:
		return momentum_attack_damage_high
	return _get_momentum_multiplier(
		momentum_attack_damage_low,
		momentum_attack_damage_mid,
		momentum_attack_damage_high,
		momentum_attack_damage_flow
	)

func get_momentum_dash_speed_multiplier() -> float:
	return _get_momentum_multiplier(momentum_dash_speed_low, momentum_dash_speed_mid, momentum_dash_speed_high, momentum_dash_speed_flow)

func get_momentum_dash_iframe_multiplier() -> float:
	return _get_momentum_multiplier(momentum_dash_iframe_low, momentum_dash_iframe_mid, momentum_dash_iframe_high, momentum_dash_iframe_flow)

func get_coin_vacuum_multiplier() -> float:
	return _get_momentum_multiplier(momentum_coin_vacuum_low, momentum_coin_vacuum_mid, momentum_coin_vacuum_high, momentum_coin_vacuum_flow)

func _process_momentum(delta: float) -> void:
	if _dash_iframe_timer > 0.0:
		_dash_iframe_timer = maxf(0.0, _dash_iframe_timer - delta)
	if _dash_contact_phase_timer > 0.0:
		_dash_contact_phase_timer = maxf(0.0, _dash_contact_phase_timer - delta)
		if _dash_contact_phase_timer <= 0.0:
			_set_dash_contact_phasing(false)

	if _pending_use_after_swap:
		_use_after_swap_timer -= delta
		if _use_after_swap_timer <= 0.0:
			_pending_use_after_swap = false

	if not _flow_state_active:
		return

	_flow_state_duration += delta
	if _flow_state_duration < flow_state_drain_delay:
		return

	var active_flow_time := _flow_state_duration - flow_state_drain_delay
	var drain := minf(flow_state_drain_base + active_flow_time * flow_state_drain_growth, flow_state_drain_max)
	_change_momentum(-drain * delta)
	if momentum <= 0.0:
		_exit_flow_state()

func _process_audio_timers(delta: float) -> void:
	if _footstep_timer > 0.0:
		_footstep_timer = maxf(0.0, _footstep_timer - delta)
	if _coin_pickup_audio_timer > 0.0:
		_coin_pickup_audio_timer = maxf(0.0, _coin_pickup_audio_timer - delta)

func _process_movement_audio(_delta: float, was_on_floor: bool) -> void:
	var on_floor := is_on_floor()
	if on_floor and not was_on_floor and not god_mode_enabled:
		AudioManager.play_sfx(&"player_land")

	if on_floor and not is_dead and not is_hurt and absf(velocity.x) >= footstep_min_speed and _footstep_timer <= 0.0:
		AudioManager.play_sfx(&"player_footstep")
		_footstep_timer = footstep_interval

func _process_movement_momentum(delta: float) -> void:
	var moved_distance := global_position.distance_to(_movement_momentum_last_position)
	_movement_momentum_last_position = global_position

	if is_dead or is_hurt:
		_movement_momentum_distance = 0.0
		return

	_movement_momentum_distance += moved_distance
	_movement_momentum_timer -= delta
	if _movement_momentum_timer > 0.0:
		return

	var sample_time := maxf(momentum_movement_report_interval, 0.001)
	var sample_speed := _movement_momentum_distance / sample_time
	_movement_momentum_timer = momentum_movement_report_interval
	_movement_momentum_distance = 0.0

	if sample_speed < momentum_movement_min_speed:
		return

	var strength := clampf(sample_speed / maxf(momentum_movement_reference_speed, 1.0), 0.15, 1.6)
	report_momentum_action(MOMENTUM_CATEGORY_MOVEMENT, strength)

func _apply_momentum_category(category: StringName, strength: float) -> void:
	var base_gain := _get_momentum_base_gain(category)
	if base_gain == 0.0:
		return

	if category == MOMENTUM_CATEGORY_MOVEMENT:
		var movement_stale_timer := float(_momentum_staleness.get(category, 0.0))
		var movement_duration := maxf(momentum_movement_stale_duration, 0.001)
		var movement_stale_multiplier := maxf(0.0, 1.0 - movement_stale_timer / movement_duration)
		var movement_gain := base_gain * strength * movement_stale_multiplier * _get_momentum_gain_curve_multiplier() * player_stats.momentum_generation_multiplier * get_pattern_momentum_generation_multiplier()
		_change_momentum(movement_gain)
		_reduce_other_momentum_staleness(category)
		_momentum_staleness[category] = minf(movement_duration, movement_stale_timer + momentum_movement_report_interval)
		_update_recent_momentum_categories(category)
		return

	var stale_duration := maxf(momentum_stale_duration, 0.001)
	var stale_timer := float(_momentum_staleness.get(category, 0.0))
	var stale_ratio := clampf(stale_timer / stale_duration, 0.0, 1.0)
	var stale_multiplier := maxf(0.0, 1.0 - stale_ratio)
	var gain := base_gain * strength * stale_multiplier * _get_momentum_gain_curve_multiplier() * _get_weaving_multiplier(category) * player_stats.momentum_generation_multiplier * get_pattern_momentum_generation_multiplier()

	if stale_ratio >= 1.0:
		gain -= momentum_stale_penalty

	_change_momentum(gain)
	_reduce_other_momentum_staleness(category)
	_momentum_staleness[category] = stale_duration
	_update_recent_momentum_categories(category)

	if category == MOMENTUM_CATEGORY_EQUIPMENT_SWAP:
		_pending_use_after_swap = true
		_use_after_swap_timer = momentum_use_after_swap_window

func _get_momentum_base_gain(category: StringName) -> float:
	match category:
		MOMENTUM_CATEGORY_MOVEMENT:
			return momentum_gain_movement
		MOMENTUM_CATEGORY_JUMP:
			return momentum_gain_jump
		MOMENTUM_CATEGORY_DASH:
			return momentum_gain_dash
		MOMENTUM_CATEGORY_GRAPPLE:
			return momentum_gain_grapple
		MOMENTUM_CATEGORY_ATTACK:
			return momentum_gain_attack
		MOMENTUM_CATEGORY_POGO:
			return momentum_gain_pogo
		MOMENTUM_CATEGORY_UTILITY:
			return momentum_gain_utility
		MOMENTUM_CATEGORY_EQUIPMENT_SWAP:
			return momentum_gain_equipment_swap
		MOMENTUM_CATEGORY_USE_AFTER_SWAP:
			return momentum_gain_use_after_swap
	return 0.0

func _get_momentum_gain_curve_multiplier() -> float:
	if momentum < momentum_low_threshold:
		return 1.05
	if momentum < momentum_high_threshold:
		return 1.0
	if momentum < 100.0:
		var high_span := maxf(1.0, 100.0 - momentum_high_threshold)
		return lerpf(0.58, 0.22, (momentum - momentum_high_threshold) / high_span)
	return 0.15

func _get_weaving_multiplier(category: StringName) -> float:
	if _momentum_recent_categories.is_empty() or _momentum_recent_categories.back() == category:
		return 1.0

	var distinct := {}
	for recent_category in _momentum_recent_categories:
		if recent_category != category:
			distinct[recent_category] = true

	return 1.0 + minf(0.6, float(distinct.size()) * momentum_weave_bonus_per_category)

func _reduce_other_momentum_staleness(category: StringName) -> void:
	for key in _momentum_staleness.keys():
		if key == category:
			continue
		var timer := float(_momentum_staleness[key])
		var duration := momentum_movement_stale_duration if key == MOMENTUM_CATEGORY_MOVEMENT else momentum_stale_duration
		var reduction := maxf(duration, 0.001) * momentum_stale_recovery_fraction
		_momentum_staleness[key] = maxf(0.0, timer - reduction)

func _update_recent_momentum_categories(category: StringName) -> void:
	_momentum_recent_categories.append(category)
	while _momentum_recent_categories.size() > momentum_weave_recent_count:
		_momentum_recent_categories.pop_front()

func _change_momentum(amount: float) -> void:
	if amount == 0.0:
		return

	momentum = clampf(momentum + amount, 0.0, 100.0)
	if momentum >= 100.0 and not _flow_state_active:
		_enter_flow_state()

func _enter_flow_state() -> void:
	if _flow_state_active:
		return

	_flow_state_active = true
	_flow_state_duration = 0.0
	AudioManager.play_sfx(&"enter_momentum")
	_sync_flow_state_audio()
	_set_flow_state_visuals(true)
	_update_momentum_state()

func _exit_flow_state() -> void:
	if not _flow_state_active:
		return

	_flow_state_active = false
	_flow_state_duration = 0.0
	_sync_flow_state_audio()
	_set_flow_state_visuals(false)
	_update_momentum_state()

func set_flow_state_audio_suspended(is_suspended: bool) -> void:
	_flow_state_audio_suspended = is_suspended
	_sync_flow_state_audio()

func _sync_flow_state_audio() -> void:
	if _flow_state_active and not _flow_state_audio_suspended:
		AudioManager.play_loop(&"momentum_aura")
	else:
		AudioManager.stop_loop(&"momentum_aura")

func _set_flow_state_visuals(is_active: bool) -> void:
	if flow_state_aura and flow_state_aura.has_method("set_flow_active"):
		flow_state_aura.set_flow_active(is_active)

func _sync_flow_vfx_momentum() -> void:
	if flow_state_aura and flow_state_aura.has_method("set_momentum_amount"):
		flow_state_aura.call("set_momentum_amount", momentum)

func _play_neutral_special_vfx() -> void:
	if not NEUTRAL_SPECIAL_VFX_SCENE or not is_inside_tree():
		return

	_cancel_neutral_special_vfx()
	var vfx := NEUTRAL_SPECIAL_VFX_SCENE.instantiate() as Node2D
	if not vfx:
		return

	var host: Node = get_tree().current_scene
	if not host:
		host = get_tree().root
	host.add_child(vfx)
	_neutral_special_vfx_instance = vfx
	vfx.global_position = _get_neutral_special_weapon_anchor_position()
	if vfx.has_method("play"):
		vfx.call(
			"play",
			neutral_special_aoe_radius,
			neutral_special_vfx_lead_time,
			last_direction,
			neutral_special_full_force_radius_ratio
		)

func _update_neutral_special_vfx_anchor() -> void:
	if not is_instance_valid(_neutral_special_vfx_instance):
		_neutral_special_vfx_instance = null
		return

	var anchor_position := _get_neutral_special_weapon_anchor_position()
	if _neutral_special_vfx_instance.has_method("set_charge_position"):
		_neutral_special_vfx_instance.call("set_charge_position", anchor_position)
	else:
		_neutral_special_vfx_instance.global_position = anchor_position

func _trigger_neutral_special_impact_vfx() -> void:
	if not is_instance_valid(_neutral_special_vfx_instance):
		_neutral_special_vfx_instance = null
		return

	var impact_position := _get_neutral_special_ground_contact_position()
	if _neutral_special_vfx_instance.has_method("trigger_impact"):
		_neutral_special_vfx_instance.call("trigger_impact", impact_position)
	else:
		_neutral_special_vfx_instance.global_position = impact_position

func _play_neutral_special_impact_audio() -> void:
	var impact_audio := AudioManager.play_sfx(&"player_smash_impact", -1.5, 0.0)
	if impact_audio:
		impact_audio.pitch_scale *= neutral_special_impact_pitch

func _cancel_neutral_special_vfx() -> void:
	if not is_instance_valid(_neutral_special_vfx_instance):
		_neutral_special_vfx_instance = null
		return
	if _neutral_special_vfx_instance.has_method("cancel"):
		_neutral_special_vfx_instance.call("cancel")
	else:
		_neutral_special_vfx_instance.queue_free()
	_neutral_special_vfx_instance = null

func _get_neutral_special_weapon_anchor_position() -> Vector2:
	if not player_animation:
		return global_position

	var anchor_index := clampi(
		player_animation.frame - NEUTRAL_SPECIAL_CHARGE_FIRST_FRAME,
		0,
		NEUTRAL_SPECIAL_WEAPON_ANCHORS.size() - 1
	)
	var local_anchor: Vector2 = NEUTRAL_SPECIAL_WEAPON_ANCHORS[anchor_index]
	if player_animation.flip_h:
		local_anchor.x = -local_anchor.x
	return player_animation.to_global(local_anchor)

func _get_neutral_special_ground_contact_position() -> Vector2:
	if not player_animation:
		return global_position

	var local_contact := NEUTRAL_SPECIAL_GROUND_CONTACT
	if player_animation.flip_h:
		local_contact.x = -local_contact.x
	return player_animation.to_global(local_contact)

func _play_flow_vfx_attack_swing(
	direction: Vector2,
	arc_degrees: float,
	strike_index: int
) -> void:
	if not flow_state_aura or not flow_state_aura.has_method("play_attack_swing"):
		return
	var swing_direction := direction
	if swing_direction.length() <= ATTACK_DIRECTION_DEADZONE:
		swing_direction = Vector2(float(last_direction), 0.0)
	flow_state_aura.call(
		"play_attack_swing",
		swing_direction.normalized(),
		arc_degrees,
		strike_index
	)

func _set_flow_vfx_dash_visual_active(
	is_active: bool,
	direction := Vector2.ZERO
) -> void:
	if _flow_vfx_dash_visual_active == is_active:
		return
	_flow_vfx_dash_visual_active = is_active
	if not is_active or not flow_state_aura or not flow_state_aura.has_method("play_dash"):
		return
	var dash_direction := direction
	if dash_direction.length() <= 0.001:
		dash_direction = Vector2(float(last_direction), 0.0)
	flow_state_aura.call("play_dash", dash_direction.normalized())

func _play_flow_vfx_jump(direction: Vector2) -> void:
	if not flow_state_aura or not flow_state_aura.has_method("play_jump"):
		return
	var jump_direction := direction
	if jump_direction.length() <= 0.001:
		jump_direction = Vector2.UP
	flow_state_aura.call("play_jump", jump_direction.normalized())

func _play_flow_vfx_land(impact_speed: float) -> void:
	if flow_state_aura and flow_state_aura.has_method("play_land"):
		flow_state_aura.call("play_land", impact_speed)

func _lose_momentum_from_damage(damage: DamageData) -> void:
	var severity := maxf(1.0, float(damage.amount))
	var resistance := _get_momentum_multiplier(momentum_decay_resistance_low, momentum_decay_resistance_mid, momentum_decay_resistance_high, momentum_decay_resistance_flow)
	var loss := (momentum_damage_loss_per_damage * severity) + (momentum * momentum_damage_loss_current_scale * severity)
	_change_momentum(-loss * (1.0 - clampf(resistance, 0.0, 0.9)))

func _get_momentum_multiplier(low_value: float, mid_value: float, high_value: float, flow_value: float) -> float:
	if _flow_state_active:
		return flow_value

	if momentum <= momentum_low_threshold:
		return lerpf(low_value, mid_value, clampf(momentum / maxf(momentum_low_threshold, 1.0), 0.0, 1.0))
	if momentum < momentum_high_threshold:
		return mid_value

	var high_span := maxf(1.0, 100.0 - momentum_high_threshold)
	return lerpf(mid_value, high_value, clampf((momentum - momentum_high_threshold) / high_span, 0.0, 1.0))

func _update_momentum_state() -> void:
	var next_state := MOMENTUM_STATE_MID
	if _flow_state_active:
		next_state = MOMENTUM_STATE_FLOW
	elif momentum < momentum_low_threshold:
		next_state = MOMENTUM_STATE_LOW
	elif momentum >= momentum_high_threshold:
		next_state = MOMENTUM_STATE_HIGH

	if next_state == _momentum_state:
		return

	_momentum_state = next_state
	momentum_state_changed.emit(_momentum_state, _flow_state_active)

func _on_attack_hit_landed(_hurtbox: HurtboxComponent, _damage: DamageData) -> void:
	if attack_direction.y > 0.55 and not is_on_floor():
		report_momentum_action(MOMENTUM_CATEGORY_POGO)
	else:
		report_momentum_action(MOMENTUM_CATEGORY_ATTACK, 1.25)

func _on_health_changed(_current: int, _maximum: int) -> void:
	_sync_hud()

func should_ignore_health_damage(_damage: DamageData) -> bool:
	return god_mode_enabled or _dash_iframe_timer > 0.0

func should_ignore_enemy_contact(_enemy: Node = null) -> bool:
	if _dash_iframe_timer > 0.0:
		return true
	if _grapple_strike_contact_guard:
		return true
	if (
		current_gloves
		and current_gloves.has_method("is_grapple_strike_contact_guard_active")
	):
		return bool(
			current_gloves.call("is_grapple_strike_contact_guard_active")
		)
	return false

func set_grapple_strike_contact_guard(is_active: bool) -> void:
	_grapple_strike_contact_guard = is_active

func modify_incoming_health_damage(damage: DamageData) -> DamageData:
	if not player_stats or player_stats.resistance <= 0:
		return damage

	var modified := damage.duplicate_for_hit(
		damage.source,
		damage.hit_position
	)
	var mitigation := player_stats.get_resistance_mitigation()
	modified.amount = maxi(1, roundi(float(damage.amount) * (1.0 - mitigation)))
	return modified

func receive_ignored_health_hit(damage: DamageData) -> void:
	if _dash_iframe_timer > 0.0 and not god_mode_enabled:
		_sync_hud()
		return

	_on_damaged(damage)
	_sync_hud()

func _on_damaged(damage: DamageData) -> void:
	_cancel_dash_iframe()
	_cancel_enemy_grapple_combat()
	_hurt_animation_active = is_on_floor()
	is_hurt = true
	hurt_timer = damage.hitstun if damage.hitstun > 0.0 else player_stats.hurt_time
	is_attacking = false
	current_attack_is_special = false
	_cancel_ground_combo_attack()
	_cancel_air_double_attack()
	_cancel_neutral_special_vfx()
	attack_hitbox.disable()
	_reset_attack_hitbox_polygon()
	_reset_weapon_visuals()
	AudioManager.play_sfx(&"player_damage")

	if hit_flash:
		hit_flash.flash(Color(1.0, 0.35, 0.35, 1.0), 0.08)

	var knockback := damage.knockback
	if knockback == Vector2.ZERO and damage.source is Node2D:
		var source_node := damage.source as Node2D
		knockback = Vector2(sign(global_position.x - source_node.global_position.x) * player_stats.knockback_strength, -90.0)

	velocity = knockback
	_lose_momentum_from_damage(damage)
	if damage.screen_shake_strength > 0.0:
		CombatFeedback.screen_shake(
			self,
			damage.screen_shake_strength,
			damage.screen_shake_duration
		)
	elif damage.use_receiver_screen_shake_fallback:
		CombatFeedback.screen_shake(
			self,
			player_stats.screen_shake_strength,
			0.08
		)
	CombatFeedback.hit_pause(self, damage.hit_pause)

func _on_died(_damage: DamageData) -> void:
	if death_reset_started:
		return

	var tutorial_controller: Node = get_tree().get_first_node_in_group("tutorial_controllers")
	if tutorial_controller and tutorial_controller.has_method("handle_player_tutorial_death"):
		var handled_by_tutorial: bool = tutorial_controller.call("handle_player_tutorial_death", self)
		if handled_by_tutorial:
			return

	_exit_flow_state()
	_cancel_dash_iframe()
	_cancel_enemy_grapple_combat()
	AudioManager.stop_loop(&"grapple_hanging")
	is_dead = true
	death_reset_started = true
	is_attacking = false
	current_attack_is_special = false
	_cancel_ground_combo_attack()
	_cancel_air_double_attack()
	_cancel_neutral_special_vfx()
	attack_hitbox.disable()
	_reset_attack_hitbox_polygon()
	_reset_weapon_visuals()
	call_deferred("_show_game_over_after_death")

func _show_game_over_after_death() -> void:
	if death_reset_delay > 0.0:
		await get_tree().create_timer(death_reset_delay, true, false, true).timeout

	if not is_inside_tree():
		return

	var overlay := GAME_OVER_OVERLAY_SCENE.instantiate()
	get_tree().root.add_child(overlay)

	if overlay.has_signal("completed"):
		await overlay.completed

	_reload_scene_after_death()

func _reload_scene_after_death() -> void:
	if not is_inside_tree():
		return

	var error := get_tree().reload_current_scene()
	if error != OK:
		push_warning("Player: Failed to reload current scene after death.")

func revive_for_tutorial(respawn_position: Vector2) -> void:
	is_dead = false
	death_reset_started = false
	is_hurt = false
	hurt_timer = 0.0
	is_attacking = false
	current_attack_is_special = false
	_cancel_enemy_grapple_combat()
	_cancel_ground_combo_attack()
	_cancel_air_double_attack()
	_cancel_neutral_special_vfx()
	_cancel_dash_iframe()
	attack_timer = 0.0
	attack_cooldown_timer = 0.0
	attack_active_started = false
	attack_active_finished = false
	is_wall_clinging = false
	wall_cling_timer = 0.0
	is_ledge_hanging = false
	is_ledge_climbing = false
	velocity = Vector2.ZERO
	global_position = respawn_position
	_movement_momentum_last_position = global_position
	_exit_flow_state()
	AudioManager.stop_loop(&"grapple_hanging")
	if current_gloves and current_gloves.has_method("_reset_active_grapple_visuals"):
		current_gloves.call("_reset_active_grapple_visuals")
	if attack_hitbox:
		attack_hitbox.disable()
	_reset_attack_hitbox_polygon()
	if health_component:
		health_component.is_dead = false
		health_component.current_health = health_component.max_health
		health_component.health_changed.emit(health_component.current_health, health_component.max_health)
	refill_action_points()
	_reset_weapon_visuals()
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation("Idle"):
		play_character_anim("Idle")
	_sync_hud()

# ===============================
# CHARGE / COOLDOWN HELPERS
# ===============================
func set_jump_charge_level(level: float) -> void:
	jump_charge_ratio = clamp(level, 0.0, 1.0)

func set_dash_charge_level(level: float) -> void:
	dash_charge_ratio = clamp(level, 0.0, 1.0)

func start_ability_cooldown(duration: float) -> void:
	if ability_cooldown_timer:
		ability_cooldown_timer.wait_time = duration
		ability_cooldown_timer.start()

func _on_ability_cooldown_timeout() -> void:
	if current_boots and current_boots.has_method("on_ability_cooldown_complete"):
		current_boots.on_ability_cooldown_complete()
	if current_gloves and current_gloves.has_method("on_ability_cooldown_complete"):
		current_gloves.on_ability_cooldown_complete()

# ===============================
# SAVE POINT INTERACTION
# ===============================
func begin_save_point_interaction(save_point: Node, sit_target_position: Vector2) -> bool:
	if save_point_interaction_active or is_dead:
		return false

	save_point_interaction_active = true
	_save_point_controller = save_point
	_save_point_target_position = sit_target_position
	_save_point_sitting_down = false
	_save_point_seated = false
	_save_point_standing_up = false
	is_near_interactable = false
	current_selector = null
	is_attacking = false
	is_hurt = false
	current_attack_is_special = false
	_cancel_enemy_grapple_combat()
	_cancel_ground_combo_attack()
	_cancel_air_double_attack()
	_cancel_neutral_special_vfx()
	is_wall_clinging = false
	wall_cling_timer = 0.0
	is_ledge_hanging = false
	is_ledge_climbing = false
	attack_timer = 0.0
	attack_cooldown_timer = 0.0
	velocity = Vector2.ZERO
	if player_animation:
		_save_point_original_scale = player_animation.scale
		_save_point_original_animation_speed_scale = player_animation.speed_scale
	if equipment_mount:
		_save_point_equipment_was_visible = equipment_mount.visible
	if attack_hitbox:
		attack_hitbox.disable()
	_reset_attack_hitbox_polygon()
	_reset_weapon_visuals()
	return true

func end_save_point_interaction() -> void:
	if not save_point_interaction_active:
		return
	if _save_point_standing_up:
		return

	_save_point_standing_up = true
	_stop_save_point_breathing(false)
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation(SIT_ANIMATION):
		player_animation.animation = SIT_ANIMATION
		player_animation.frame = maxi(player_animation.sprite_frames.get_frame_count(SIT_ANIMATION) - 1, 0)
		player_animation.speed_scale = _save_point_original_animation_speed_scale * save_point_stand_up_speed_scale
		player_animation.play_backwards(SIT_ANIMATION)
		await player_animation.animation_finished
	_complete_save_point_interaction()

func recover_at_save_point() -> void:
	if health_component:
		health_component.heal(health_component.max_health)
	refill_action_points()
	_sync_hud()

func _apply_demo_checkpoint_spawn() -> void:
	if not DemoProgress.has_checkpoint():
		return

	var current_scene := get_tree().current_scene
	if not current_scene or current_scene.scene_file_path != DemoProgress.get_checkpoint_scene_path():
		return

	global_position = DemoProgress.get_checkpoint_position()
	_movement_momentum_last_position = global_position

func _complete_save_point_interaction() -> void:
	save_point_interaction_active = false
	_save_point_controller = null
	_save_point_sitting_down = false
	_save_point_seated = false
	_save_point_standing_up = false
	velocity = Vector2.ZERO
	_restore_save_point_visual_state()
	if current_gloves and current_gloves.has_method("exit_save_point_pose"):
		current_gloves.exit_save_point_pose()
	_restore_save_point_equipment()
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation("Idle"):
		play_character_anim("Idle")

func _process_save_point_interaction(delta: float) -> void:
	if _save_point_sitting_down or _save_point_seated or _save_point_standing_up:
		return

	var target_delta := _save_point_target_position - global_position
	if abs(target_delta.x) > save_point_arrive_distance:
		var direction := int(sign(target_delta.x))
		last_direction = direction
		if player_animation:
			player_animation.flip_h = direction < 0
		update_equipment_facing()
		velocity.x = float(direction) * save_point_auto_run_speed
		velocity.y += _get_current_gravity() * delta
		velocity.y = min(velocity.y, max_fall_speed)
		move_and_slide()
		if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation("Run"):
			play_character_anim("Run")
		return

	global_position = _save_point_target_position
	velocity = Vector2.ZERO
	_save_point_sitting_down = true
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation(SIT_ANIMATION):
		player_animation.scale = save_point_sit_visual_scale
		_hide_save_point_equipment()
		play_character_anim(String(SIT_ANIMATION))
		if current_gloves and current_gloves.has_method("enter_save_point_pose"):
			current_gloves.enter_save_point_pose()
		call_deferred("_complete_save_point_sit_down")
	else:
		_complete_save_point_sit_down()

func _complete_save_point_sit_down() -> void:
	if player_animation and player_animation.sprite_frames and player_animation.sprite_frames.has_animation(SIT_ANIMATION):
		await player_animation.animation_finished
		player_animation.frame = maxi(player_animation.sprite_frames.get_frame_count(SIT_ANIMATION) - 1, 0)
	_save_point_sitting_down = false
	_save_point_seated = true
	_start_save_point_breathing()
	save_point_seated.emit(self)

func _start_save_point_breathing() -> void:
	if not player_animation:
		return

	_save_point_original_material = player_animation.material
	var seated_scale := player_animation.scale
	var meditation_material := ShaderMaterial.new()
	meditation_material.shader = MEDITATION_SHADER
	player_animation.material = meditation_material

	if _save_point_breath_tween:
		_save_point_breath_tween.kill()
	_save_point_breath_tween = create_tween()
	_save_point_breath_tween.set_loops()
	_save_point_breath_tween.tween_property(player_animation, "scale", seated_scale * Vector2(1.015, 0.992), 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_save_point_breath_tween.tween_property(player_animation, "scale", seated_scale, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_save_point_breathing(restore_scale := true) -> void:
	if _save_point_breath_tween:
		_save_point_breath_tween.kill()
		_save_point_breath_tween = null
	if player_animation:
		player_animation.material = _save_point_original_material
		if restore_scale:
			player_animation.scale = _save_point_original_scale
			player_animation.speed_scale = _save_point_original_animation_speed_scale

func _restore_save_point_visual_state() -> void:
	if player_animation:
		player_animation.material = _save_point_original_material
		player_animation.scale = _save_point_original_scale
		player_animation.speed_scale = _save_point_original_animation_speed_scale

func _hide_save_point_equipment() -> void:
	if equipment_mount:
		equipment_mount.visible = false

func _restore_save_point_equipment() -> void:
	if equipment_mount:
		equipment_mount.visible = _save_point_equipment_was_visible

# ===============================
# INTERACTABLES
# ===============================
func _on_interactable_entered(area: Area2D) -> void:
	is_near_interactable = true
	current_selector = area

func _on_interactable_exited(area: Area2D) -> void:
	is_near_interactable = false
	if current_selector == area:
		current_selector = null
