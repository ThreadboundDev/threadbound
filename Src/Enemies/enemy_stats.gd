class_name EnemyStats
extends Resource

@export var max_health: int = 3
@export var move_speed: float = 90.0
@export var chase_speed: float = 150.0
@export var acceleration: float = 900.0
@export var gravity: float = 1600.0
@export var max_fall_speed: float = 900.0

@export var patrol_wait_time: float = 0.5
@export var attack_damage: int = 1
@export var contact_damage: int = 1
@export var contact_damage_cooldown: float = 0.45
@export var attack_windup: float = 0.18
@export var attack_active_time: float = 0.14
@export var attack_recovery: float = 0.28
@export var attack_cooldown: float = 0.55
@export var hurt_time: float = 0.18
@export var death_cleanup_delay: float = 0.6
@export var knockback_strength: float = 180.0
@export var contact_knockback_strength: float = 260.0
@export var hit_pause: float = 0.04
@export var screen_shake_strength: float = 3.0
