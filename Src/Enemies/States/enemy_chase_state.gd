class_name EnemyChaseState
extends EnemyState

func physics_update(delta: float) -> void:
	if enemy.is_dead:
		state_machine.transition_to(&"Dead")
		return
	if not enemy.target:
		state_machine.transition_to(&"Idle")
		return
	if enemy.is_player_in_attack_range() and enemy.can_attack():
		state_machine.transition_to(&"Attack")
		return

	enemy.chase_target(delta)
	enemy.apply_gravity(delta)
	enemy.move_enemy(delta)
