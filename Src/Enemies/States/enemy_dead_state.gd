class_name EnemyDeadState
extends EnemyState

func enter(_previous_state: StringName = &"") -> void:
	enemy.die()
