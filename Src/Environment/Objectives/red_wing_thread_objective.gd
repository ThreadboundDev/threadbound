extends Node2D
class_name RedWingThreadObjective

@export var enemy_root_path: NodePath = ^"."
@export var spawn_parent_path: NodePath = ^""
@export var thread_scene: PackedScene = preload("res://Src/Pickups/DemoThreads/thread_of_power_pickup.tscn")
@export var spawn_offset_from_player := Vector2(0.0, -96.0)
@export var allow_empty_completion := false
@export_group("Enemy Indicators")
@export var show_enemy_indicators := true
@export var enemy_indicator_offset := Vector2(0.0, -92.0)
@export var enemy_indicator_color := Color(1.0, 0.18, 0.12, 0.9)
@export var edge_indicator_padding := 72.0
@export var edge_indicator_size := 26.0

var _tracked_enemies: Array[EnemyBase] = []
var _enemy_indicators: Dictionary = {}
var _edge_indicator: Polygon2D
var _spawned := false
var _had_tracked_enemies := false

func _process(_delta: float) -> void:
	if show_enemy_indicators:
		_update_enemy_indicators()

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
		_ensure_enemy_indicator(enemy)

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
	_remove_enemy_indicator(enemy)
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
	_clear_enemy_indicators()
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

func _ensure_enemy_indicator(enemy: EnemyBase) -> void:
	if not show_enemy_indicators or not enemy or _enemy_indicators.has(enemy.get_instance_id()):
		return

	var indicator := _make_indicator()
	indicator.name = "%sIndicator" % enemy.name
	add_child(indicator)
	_enemy_indicators[enemy.get_instance_id()] = {
		"enemy": enemy,
		"indicator": indicator,
	}

func _make_indicator() -> Polygon2D:
	var indicator := Polygon2D.new()
	indicator.color = enemy_indicator_color
	indicator.z_index = 95
	indicator.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(-12.0, -22.0),
		Vector2(12.0, -22.0),
	])
	return indicator

func _update_enemy_indicators() -> void:
	var nearest_enemy := _get_nearest_live_enemy()
	var camera := get_viewport().get_camera_2d()
	var visible_rect := _get_camera_world_rect(camera)

	for key in _enemy_indicators.keys():
		var record: Dictionary = _enemy_indicators[key]
		var enemy := record.get("enemy") as EnemyBase
		var indicator := record.get("indicator") as Polygon2D
		if not is_instance_valid(enemy) or enemy.is_dead:
			if indicator:
				indicator.queue_free()
			_enemy_indicators.erase(key)
			continue

		if indicator:
			indicator.visible = true
			indicator.global_position = enemy.global_position + enemy_indicator_offset
			indicator.rotation = 0.0

	_update_edge_indicator(nearest_enemy, visible_rect)

func _get_nearest_live_enemy() -> EnemyBase:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var nearest_enemy: EnemyBase
	var nearest_distance := INF
	for enemy in _tracked_enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue
		var distance := enemy.global_position.distance_squared_to(player.global_position if player else global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	return nearest_enemy

func _get_camera_world_rect(camera: Camera2D) -> Rect2:
	if not camera:
		return Rect2()

	var viewport_size := get_viewport_rect().size
	var half_size := viewport_size * 0.5 / camera.zoom
	return Rect2(camera.global_position - half_size, half_size * 2.0)

func _update_edge_indicator(enemy: EnemyBase, visible_rect: Rect2) -> void:
	if not enemy or visible_rect.size == Vector2.ZERO or visible_rect.has_point(enemy.global_position):
		if _edge_indicator:
			_edge_indicator.visible = false
		return

	if not _edge_indicator:
		_edge_indicator = _make_indicator()
		_edge_indicator.name = "NearestEnemyEdgeIndicator"
		add_child(_edge_indicator)

	var center := visible_rect.get_center()
	var to_enemy := enemy.global_position - center
	if to_enemy.length() <= 0.01:
		to_enemy = Vector2.RIGHT

	var half_size := visible_rect.size * 0.5 - Vector2(edge_indicator_padding, edge_indicator_padding)
	var direction := to_enemy.normalized()
	var scale_factor := minf(
		absf(half_size.x / direction.x) if absf(direction.x) > 0.01 else INF,
		absf(half_size.y / direction.y) if absf(direction.y) > 0.01 else INF
	)
	_edge_indicator.visible = true
	_edge_indicator.global_position = center + direction * scale_factor
	_edge_indicator.rotation = direction.angle() + PI * 0.5
	_edge_indicator.scale = Vector2.ONE * (edge_indicator_size / 24.0)

func _remove_enemy_indicator(enemy: EnemyBase) -> void:
	if not enemy:
		return
	var key := enemy.get_instance_id()
	if not _enemy_indicators.has(key):
		return
	var record: Dictionary = _enemy_indicators[key]
	var indicator := record.get("indicator") as Polygon2D
	if indicator:
		indicator.queue_free()
	_enemy_indicators.erase(key)

func _clear_enemy_indicators() -> void:
	for record in _enemy_indicators.values():
		var indicator := record.get("indicator") as Polygon2D
		if indicator:
			indicator.queue_free()
	_enemy_indicators.clear()
	if _edge_indicator:
		_edge_indicator.queue_free()
		_edge_indicator = null
