extends Node2D
class_name BalanceWingObjective

@export var thread_scene: PackedScene = preload("res://Src/Pickups/DemoThreads/thread_of_balance_pickup.tscn")
@export var button_paths: Array[NodePath] = []
@export var spawn_parent_path: NodePath = ^""
@export var spawn_offset_from_player := Vector2(0.0, -96.0)

var _buttons: Array[BlueWingButton] = []
var _last_activator: Node = null
var _spawned := false

func _ready() -> void:
	if DemoProgress.has_thread(&"balance"):
		_spawned = true
		return

	_setup_buttons.call_deferred()

func _setup_buttons() -> void:
	_buttons.clear()

	if button_paths.is_empty():
		for child in get_children():
			if child is BlueWingButton:
				_register_button(child as BlueWingButton)
	else:
		for path in button_paths:
			var button := get_node_or_null(path) as BlueWingButton
			if button:
				_register_button(button)

	_check_completion()

func _register_button(button: BlueWingButton) -> void:
	if button in _buttons:
		return

	_buttons.append(button)
	if not button.active_changed.is_connected(_on_button_active_changed):
		button.active_changed.connect(_on_button_active_changed)

func _on_button_active_changed(_button: BlueWingButton, active: bool, activator: Node) -> void:
	if active and activator:
		_last_activator = activator

	_check_completion()

func _check_completion() -> void:
	if _spawned or _buttons.is_empty():
		return

	for button in _buttons:
		if not button.is_active:
			return

	_spawned = true
	_spawn_thread_of_balance(_last_activator)

func _spawn_thread_of_balance(activator: Node = null) -> void:
	if not thread_scene:
		return

	var thread := thread_scene.instantiate() as Node2D
	if not thread:
		return

	var spawn_parent := get_node_or_null(spawn_parent_path)
	if not spawn_parent:
		spawn_parent = get_tree().current_scene
	if not spawn_parent:
		spawn_parent = self

	spawn_parent.add_child(thread)
	var player_node := _resolve_spawn_player(activator)
	thread.global_position = player_node.global_position + spawn_offset_from_player if player_node else global_position + spawn_offset_from_player

func _resolve_spawn_player(activator: Node) -> Node2D:
	var player := activator
	if player and not player.is_in_group("player"):
		player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_first_node_in_group("player")

	return player as Node2D
