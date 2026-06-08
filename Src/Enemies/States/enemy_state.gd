class_name EnemyState
extends Node

var enemy: EnemyBase
var state_machine: EnemyStateMachine

func setup(owner_enemy: EnemyBase, machine: EnemyStateMachine) -> void:
	enemy = owner_enemy
	state_machine = machine

func enter(_previous_state: StringName = &"") -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func update(_delta: float) -> void:
	pass
