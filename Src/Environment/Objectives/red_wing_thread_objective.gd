extends Node2D
class_name RedWingThreadObjective

@export var enemy_root_path: NodePath = ^"."
@export var spawn_parent_path: NodePath = ^""
@export var thread_scene: PackedScene = preload("res://Src/Pickups/DemoThreads/thread_of_power_pickup.tscn")
@export var spawn_offset_from_player := Vector2(0.0, -96.0)
@export var allow_empty_completion := false

var _tracked_enemies: Array[EnemyBase] = []
var _spawned := false
var _had_tracked_enemies := false

func _ready() -> void:
	if DemoProgress.has_thread(&"power"):
		_spawned = true
		return

	call_deferred("_refresh_enemies")

func _refresh_enemies() -> void:
	_tracked_enemies.clear()

	var enemy_root := get_node_or_null(enemy_root_path)
	if not enemy_root:
		enemy_root = self

	_collect_enemies(enemy_root)
	_had_tracked_enemies = not _tracked_enemies.is_empty()
	for enemy in _tracked_enemies:
		if enemy.health_component and not enemy.health_component.died.is_connected(_on_enemy_died.bind(enemy)):
			enemy.health_component.died.connect(_on_enemy_died.bind(enemy))

	_check_completion()

func _collect_enemies(node: Node) -> void:
	for child in node.get_children():
		if child is EnemyBase:
			var enemy := child as EnemyBase
			if not enemy.is_dead:
				_tracked_enemies.append(enemy)
		_collect_enemies(child)

func _on_enemy_died(_damage: DamageData, enemy: EnemyBase) -> void:
	_tracked_enemies.erase(enemy)
	_check_completion()

func _check_completion() -> void:
	if _spawned or DemoProgress.has_thread(&"power"):
		return
	if _tracked_enemies.is_empty() and (_had_tracked_enemies or allow_empty_completion):
		_spawn_thread_of_power()
	elif not _tracked_enemies.is_empty():
		var any_alive := false
		for enemy in _tracked_enemies:
			if is_instance_valid(enemy) and not enemy.is_dead:
				any_alive = true
				break
		if not any_alive:
			_spawn_thread_of_power()

func _spawn_thread_of_power() -> void:
	if _spawned or not thread_scene:
		return

	var thread := thread_scene.instantiate() as Node2D
	if not thread:
		return

	_spawned = true
	var spawn_parent := get_node_or_null(spawn_parent_path)
	if not spawn_parent:
		spawn_parent = get_tree().current_scene
	if not spawn_parent:
		spawn_parent = self

	spawn_parent.add_child(thread)
	thread.global_position = _get_spawn_position()

func _get_spawn_position() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		return player.global_position + spawn_offset_from_player
	return global_position + spawn_offset_from_player
