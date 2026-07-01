extends Node

## Central enemy scaling knobs.
## Defaults intentionally multiply to 1.0 so current tuning stays unchanged.

@export var world_scale_modifier := 1.0:
	set(value):
		world_scale_modifier = maxf(0.0, value)

@export var health_scale_modifier := 1.0:
	set(value):
		health_scale_modifier = maxf(0.0, value)

@export var damage_scale_modifier := 1.0:
	set(value):
		damage_scale_modifier = maxf(0.0, value)

@export_group("Future Progression Hooks")
@export var story_progression_modifier := 1.0:
	set(value):
		story_progression_modifier = maxf(0.0, value)

@export var region_progression_modifier := 1.0:
	set(value):
		region_progression_modifier = maxf(0.0, value)

@export var difficulty_modifier := 1.0:
	set(value):
		difficulty_modifier = maxf(0.0, value)

@export var new_game_plus_modifier := 1.0:
	set(value):
		new_game_plus_modifier = maxf(0.0, value)

@export var challenge_modifier := 1.0:
	set(value):
		challenge_modifier = maxf(0.0, value)

func get_global_scale_modifier() -> float:
	return world_scale_modifier \
		* story_progression_modifier \
		* region_progression_modifier \
		* difficulty_modifier \
		* new_game_plus_modifier \
		* challenge_modifier

func get_health_scale_modifier() -> float:
	return get_global_scale_modifier() * health_scale_modifier

func get_damage_scale_modifier() -> float:
	return get_global_scale_modifier() * damage_scale_modifier

func scale_health(base_health: int) -> int:
	return maxi(1, roundi(float(base_health) * get_health_scale_modifier()))

func scale_damage(base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	return maxi(1, roundi(float(base_damage) * get_damage_scale_modifier()))
