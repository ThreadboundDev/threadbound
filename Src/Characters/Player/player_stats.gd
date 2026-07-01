class_name PlayerStats
extends Resource

const STARTING_HEALTH := 100
const ENDGAME_HEALTH_TARGET := Vector2i(250, 350)
const STARTING_ATTACK := 25
const ENDGAME_ATTACK_TARGET := Vector2i(45, 60)
const STARTING_SKILL_DAMAGE_MULTIPLIER := 1.0
const ENDGAME_SKILL_DAMAGE_TARGET := Vector2(1.5, 1.8)
const STARTING_AP_RECHARGE_MULTIPLIER := 1.0
const ENDGAME_AP_RECHARGE_TARGET := Vector2(1.3, 1.5)
const STARTING_MOMENTUM_GENERATION_MULTIPLIER := 1.0
const ENDGAME_MOMENTUM_GENERATION_TARGET := Vector2(1.3, 1.5)
const STARTING_RESISTANCE := 0
const ENDGAME_RESISTANCE_TARGET := Vector2i(60, 99)
const MAX_RESISTANCE := 99.0
const MAX_RESISTANCE_MITIGATION := 0.35
const RESISTANCE_MITIGATION_EXPONENT := 0.78
const DIMINISHING_RETURN_EARLY_WEIGHT := 1.0
const DIMINISHING_RETURN_MID_WEIGHT := 0.55
const DIMINISHING_RETURN_LATE_WEIGHT := 0.28
const DIMINISHING_RETURN_VERY_LATE_WEIGHT := 0.12

@export_range(STARTING_HEALTH, ENDGAME_HEALTH_TARGET.y, 1) var max_health: int = STARTING_HEALTH
@export_range(STARTING_ATTACK, ENDGAME_ATTACK_TARGET.y, 1) var attack_damage: int = STARTING_ATTACK
@export_range(STARTING_SKILL_DAMAGE_MULTIPLIER, ENDGAME_SKILL_DAMAGE_TARGET.y, 0.01) var skill_damage_multiplier: float = STARTING_SKILL_DAMAGE_MULTIPLIER
@export_range(STARTING_AP_RECHARGE_MULTIPLIER, ENDGAME_AP_RECHARGE_TARGET.y, 0.01) var action_point_recharge_multiplier: float = STARTING_AP_RECHARGE_MULTIPLIER
@export_range(STARTING_MOMENTUM_GENERATION_MULTIPLIER, ENDGAME_MOMENTUM_GENERATION_TARGET.y, 0.01) var momentum_generation_multiplier: float = STARTING_MOMENTUM_GENERATION_MULTIPLIER
@export_range(STARTING_RESISTANCE, ENDGAME_RESISTANCE_TARGET.y, 1) var resistance: int = STARTING_RESISTANCE
@export_group("Upgrade Curve")
@export_range(1, 99, 1) var early_upgrade_points := 4
@export_range(1, 99, 1) var mid_upgrade_points := 6
@export_range(1, 99, 1) var late_upgrade_points := 8
@export_range(0, 99, 1) var health_upgrade_points := 0
@export_range(0, 99, 1) var attack_upgrade_points := 0
@export_range(0, 99, 1) var skill_damage_upgrade_points := 0
@export_range(0, 99, 1) var ap_recharge_upgrade_points := 0
@export_range(0, 99, 1) var momentum_generation_upgrade_points := 0
@export_range(0, 99, 1) var resistance_upgrade_points := 0
@export var attack_windup: float = 0.045
@export var attack_active_time: float = 0.095
@export var attack_recovery: float = 0.12
@export var attack_cooldown: float = 0.2
@export var hurt_time: float = 0.18
@export var knockback_strength: float = 260.0
@export var hit_pause: float = 0.04
@export var screen_shake_strength: float = 4.0

func get_diminishing_return_weight(point_index: int) -> float:
	if point_index < early_upgrade_points:
		return DIMINISHING_RETURN_EARLY_WEIGHT
	if point_index < early_upgrade_points + mid_upgrade_points:
		return DIMINISHING_RETURN_MID_WEIGHT
	if point_index < early_upgrade_points + mid_upgrade_points + late_upgrade_points:
		return DIMINISHING_RETURN_LATE_WEIGHT
	return DIMINISHING_RETURN_VERY_LATE_WEIGHT

func get_diminishing_return_total(points: int) -> float:
	var total := 0.0
	for point_index in maxi(0, points):
		total += get_diminishing_return_weight(point_index)
	return total

func apply_stat_upgrade(stat_id: StringName, points := 1) -> bool:
	if points <= 0:
		return false

	match stat_id:
		&"health":
			health_upgrade_points += points
		&"attack":
			attack_upgrade_points += points
		&"skill_damage":
			skill_damage_upgrade_points += points
		&"ap_recharge":
			ap_recharge_upgrade_points += points
		&"momentum_generation":
			momentum_generation_upgrade_points += points
		&"resistance":
			resistance_upgrade_points += points
		_:
			return false

	recalculate_upgrade_stats()
	return true

func recalculate_upgrade_stats() -> void:
	max_health = roundi(lerpf(float(STARTING_HEALTH), float(ENDGAME_HEALTH_TARGET.y), _get_upgrade_progress(health_upgrade_points)))
	attack_damage = roundi(lerpf(float(STARTING_ATTACK), float(ENDGAME_ATTACK_TARGET.y), _get_upgrade_progress(attack_upgrade_points)))
	skill_damage_multiplier = lerpf(STARTING_SKILL_DAMAGE_MULTIPLIER, ENDGAME_SKILL_DAMAGE_TARGET.y, _get_upgrade_progress(skill_damage_upgrade_points))
	action_point_recharge_multiplier = lerpf(STARTING_AP_RECHARGE_MULTIPLIER, ENDGAME_AP_RECHARGE_TARGET.y, _get_upgrade_progress(ap_recharge_upgrade_points))
	momentum_generation_multiplier = lerpf(STARTING_MOMENTUM_GENERATION_MULTIPLIER, ENDGAME_MOMENTUM_GENERATION_TARGET.y, _get_upgrade_progress(momentum_generation_upgrade_points))
	resistance = roundi(lerpf(float(STARTING_RESISTANCE), float(ENDGAME_RESISTANCE_TARGET.y), _get_upgrade_progress(resistance_upgrade_points)))

func get_upgrade_points(stat_id: StringName) -> int:
	match stat_id:
		&"health":
			return health_upgrade_points
		&"attack":
			return attack_upgrade_points
		&"skill_damage":
			return skill_damage_upgrade_points
		&"ap_recharge":
			return ap_recharge_upgrade_points
		&"momentum_generation":
			return momentum_generation_upgrade_points
		&"resistance":
			return resistance_upgrade_points
	return 0

func get_stat_display_value(stat_id: StringName) -> String:
	match stat_id:
		&"health":
			return str(max_health)
		&"attack":
			return str(attack_damage)
		&"skill_damage":
			return "%d%%" % roundi(skill_damage_multiplier * 100.0)
		&"ap_recharge":
			return "%d%%" % roundi(action_point_recharge_multiplier * 100.0)
		&"momentum_generation":
			return "%d%%" % roundi(momentum_generation_multiplier * 100.0)
		&"resistance":
			return "%d%%" % roundi(get_resistance_mitigation() * 100.0)
	return ""

func get_next_stat_display_value(stat_id: StringName) -> String:
	var preview := duplicate(true) as PlayerStats
	if not preview:
		return get_stat_display_value(stat_id)
	preview.apply_stat_upgrade(stat_id)
	return preview.get_stat_display_value(stat_id)

func _get_upgrade_progress(points: int) -> float:
	var target_points := early_upgrade_points + mid_upgrade_points + late_upgrade_points + 10
	var target_total := maxf(0.001, get_diminishing_return_total(target_points))
	return clampf(get_diminishing_return_total(points) / target_total, 0.0, 1.0)

func get_resistance_mitigation() -> float:
	if resistance <= 0:
		return 0.0

	var resistance_ratio := clampf(float(resistance) / MAX_RESISTANCE, 0.0, 1.0)
	return clampf(
		MAX_RESISTANCE_MITIGATION * pow(resistance_ratio, RESISTANCE_MITIGATION_EXPONENT),
		0.0,
		MAX_RESISTANCE_MITIGATION
	)
