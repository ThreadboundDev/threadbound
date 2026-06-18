class_name EnemyStateMachine
extends Node

signal state_changed(state_name: StringName)

@export var initial_state: StringName = &"Idle"

var enemy: EnemyBase
var current_state: EnemyState
var current_state_name: StringName = &""
var states: Dictionary = {}

func initialize(owner_enemy: EnemyBase) -> void:
	enemy = owner_enemy
	states.clear()

	for child in get_children():
		if child is EnemyState:
			var state := child as EnemyState
			state.setup(enemy, self)
			states[StringName(child.name)] = state

	transition_to(initial_state)

func transition_to(state_name: StringName) -> void:
	if not states.has(state_name):
		push_warning("EnemyStateMachine: missing state %s" % state_name)
		return

	if current_state:
		current_state.exit()

	var previous := current_state_name
	current_state_name = state_name
	current_state = states[state_name]
	current_state.enter(previous)
	state_changed.emit(current_state_name)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
