class_name EnemyAttackState
extends EnemyState

var _timer := 0.0
var _active_started := false
var _attack_finished := false

func enter(_previous_state: StringName = &"") -> void:
	_timer = 0.0
	_active_started = false
	_attack_finished = false
	enemy.set_horizontal_target_speed(0.0)
	enemy.begin_attack()

func exit() -> void:
	enemy.end_attack()

func physics_update(delta: float) -> void:
	if enemy.is_dead:
		state_machine.transition_to(&"Dead")
		return

	_timer += delta
	enemy.update_attack_motion(delta)

	var windup := enemy.stats.attack_windup if enemy.stats else 0.18
	var active_time := enemy.stats.attack_active_time if enemy.stats else 0.14
	var recovery := enemy.stats.attack_recovery if enemy.stats else 0.28

	if not _active_started and _timer >= windup:
		_active_started = true
		enemy.activate_attack_hitbox()

	if _active_started and not _attack_finished and _timer >= windup + active_time:
		_attack_finished = true
		enemy.deactivate_attack_hitbox()

	if _timer >= windup + active_time + recovery:
		if enemy.has_method("is_attack_sequence_busy") and enemy.is_attack_sequence_busy():
			return

		if enemy.target and enemy.is_player_in_attack_range() and enemy.can_attack():
			state_machine.transition_to(&"Attack")
		elif enemy.target:
			state_machine.transition_to(&"Chase")
		else:
			state_machine.transition_to(&"Idle")
