extends Area2D
class_name BalanceWingObjective

@export var thread_scene: PackedScene = preload("res://Src/Pickups/DemoThreads/thread_of_balance_pickup.tscn")
@export var spawn_parent_path: NodePath = ^""
@export var spawn_offset_from_player := Vector2(0.0, -96.0)
@export_range(1.0, 100.0, 1.0) var required_momentum := 100.0
@export var reset_momentum_on_enter := true

var _active_player: Node = null
var _spawned := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if DemoProgress.has_thread(&"balance"):
		_spawned = true
		monitoring = false

func _on_body_entered(body: Node) -> void:
	if _spawned or not body.is_in_group("player"):
		return

	_active_player = body
	if reset_momentum_on_enter and body.has_method("set_momentum"):
		body.set_momentum(0.0)

	if body.has_signal("momentum_changed"):
		var callable := _on_player_momentum_changed.bind(body)
		if not body.is_connected("momentum_changed", callable):
			body.connect("momentum_changed", callable)

func _on_body_exited(body: Node) -> void:
	if body != _active_player:
		return

	_disconnect_player_momentum(body)
	_active_player = null

func _on_player_momentum_changed(value: float, player: Node) -> void:
	if _spawned or value < required_momentum:
		return

	_spawned = true
	_disconnect_player_momentum(player)
	_spawn_thread_of_balance(player)
	monitoring = false

func _disconnect_player_momentum(player: Node) -> void:
	if player and player.has_signal("momentum_changed"):
		var callable := _on_player_momentum_changed.bind(player)
		if player.is_connected("momentum_changed", callable):
			player.disconnect("momentum_changed", callable)

func _spawn_thread_of_balance(player: Node) -> void:
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
	var player_node := player as Node2D
	thread.global_position = player_node.global_position + spawn_offset_from_player if player_node else global_position + spawn_offset_from_player
