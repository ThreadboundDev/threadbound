class_name EnemyPatrolState
extends EnemyState

func enter(_previous_state: StringName = &"") -> void:
	enemy.on_patrol_started()

func physics_update(delta: float) -> void:
	if enemy.is_dead:
		state_machine.transition_to(&"Dead")
		return
	if enemy.is_player_in_attack_range() and enemy.can_attack():
		state_machine.transition_to(&"Attack")
		return
	if enemy.target:
		state_machine.transition_to(&"Chase")
		return

	enemy.patrol(delta)
	enemy.apply_gravity(delta)
	enemy.move_enemy(delta)
