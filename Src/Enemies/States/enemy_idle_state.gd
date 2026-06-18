class_name EnemyIdleState
extends EnemyState

var _timer := 0.0

func enter(_previous_state: StringName = &"") -> void:
	enemy.set_horizontal_target_speed(0.0)
	_timer = enemy.stats.patrol_wait_time if enemy.stats else 0.4

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

	enemy.apply_gravity(delta)
	enemy.move_enemy(delta)

	_timer -= delta
	if _timer <= 0.0:
		state_machine.transition_to(&"Patrol")
