class_name EnemyHurtState
extends EnemyState

var _timer := 0.0

func enter(_previous_state: StringName = &"") -> void:
	_timer = enemy.stats.hurt_time if enemy.stats else 0.18
	enemy.end_attack()

func physics_update(delta: float) -> void:
	if enemy.is_dead:
		state_machine.transition_to(&"Dead")
		return

	enemy.apply_gravity(delta)
	enemy.move_enemy(delta)
	_timer -= delta

	if _timer <= 0.0:
		if enemy.target:
			state_machine.transition_to(&"Chase")
		else:
			state_machine.transition_to(&"Idle")
