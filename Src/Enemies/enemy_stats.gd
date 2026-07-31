class_name EnemyStats
extends Resource

@export var max_health: int = 75
@export var move_speed: float = 90.0
@export var chase_speed: float = 150.0
@export var acceleration: float = 900.0
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 900.0

@export var patrol_wait_time: float = 0.5
@export var attack_damage: int = 18
@export var contact_damage: int = 15
@export var contact_damage_cooldown: float = 0.45
@export var attack_windup: float = 0.18
@export var attack_active_time: float = 0.14
@export var attack_recovery: float = 0.28
@export var attack_cooldown: float = 0.55
@export var hurt_time: float = 0.18
@export var death_cleanup_delay: float = 0.6
@export_range(0, 99, 1) var thread_knot_drop_count: int = 0
@export var thread_knot_drop_speed_min: float = 145.0
@export var thread_knot_drop_speed_max: float = 245.0
@export var thread_knot_drop_upward_bias: float = 180.0
@export var thread_knot_drop_horizontal_bias: float = 24.0
@export var knockback_strength: float = 180.0
@export var contact_knockback_strength: float = 260.0
@export var hit_pause: float = 0.04
@export var screen_shake_strength: float = 3.0

@export_group("Hit Response")
@export var use_polished_hurt_response := false
@export_range(0.0, 0.5, 0.01) var incoming_hit_invulnerability := 0.06
@export_range(0.0, 3.0, 0.05) var incoming_knockback_multiplier := 1.0
@export_range(0.05, 3.0, 0.05) var incoming_hitstun_multiplier := 1.0
@export_range(0.0, 5000.0, 25.0) var hurt_knockback_deceleration := 700.0
@export var hurt_motion_uses_gravity := true
@export_range(0.0, 32.0, 0.5) var hurt_visual_recoil_distance := 8.0
@export_range(0.02, 0.3, 0.01) var hurt_visual_recoil_duration := 0.12
