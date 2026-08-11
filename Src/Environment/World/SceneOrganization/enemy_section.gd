@icon("res://addons/at-icons/node/skull.svg")
class_name EnemySection
extends Node

## Groups enemies or a room-specific enemy encounter.

@export var enemy_influence: EnemyInfluenceController.Influence = EnemyInfluenceController.Influence.NONE

func _ready() -> void:
	_watch_branch(self)

func _watch_branch(node: Node) -> void:
	if node is EnemyBase:
		(node as EnemyBase).enemy_influence = enemy_influence
	if not node.child_entered_tree.is_connected(_on_branch_child_entered):
		node.child_entered_tree.connect(_on_branch_child_entered)
	for child in node.get_children():
		_watch_branch(child)

func _on_branch_child_entered(child: Node) -> void:
	_watch_branch(child)
