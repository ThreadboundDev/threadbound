extends Node
class_name EssencePhaseVisual

@export var enemy_root_path: NodePath = ^"."
@export_range(0.5, 10.0, 0.1) var minimum_interval := 2.4
@export_range(0.5, 10.0, 0.1) var maximum_interval := 4.2
@export_range(0.05, 1.0, 0.01) var fade_out_duration := 0.13
@export_range(0.0, 1.0, 0.01) var phase_hold_duration := 0.1
@export_range(0.05, 1.0, 0.01) var fade_in_duration := 0.2
@export_range(0.1, 1.0, 0.05) var minimum_alpha := 0.42
@export var essence_color := Color(1.0, 0.78, 0.18, 1.0)

var _phase_timers: Dictionary = {}
var _phase_tweens: Dictionary = {}

func _ready() -> void:
	_register_enemies.call_deferred()

func _process(delta: float) -> void:
	for enemy_variant in _phase_timers.keys():
		var enemy := enemy_variant as EnemyBase
		if not is_instance_valid(enemy):
			_phase_timers.erase(enemy_variant)
			continue
		if enemy.is_dead:
			continue
		var remaining := float(_phase_timers[enemy]) - delta
		if remaining <= 0.0:
			_begin_phase(enemy)
			remaining = randf_range(minimum_interval, maximum_interval)
		_phase_timers[enemy] = remaining

func _register_enemies() -> void:
	var enemy_root := get_node_or_null(enemy_root_path)
	if not enemy_root:
		enemy_root = self
	_collect_enemies(enemy_root)

func _collect_enemies(node: Node) -> void:
	for child in node.get_children():
		if child is EnemyBase:
			var enemy := child as EnemyBase
			_phase_timers[enemy] = randf_range(0.6, maximum_interval)
			if (
				enemy.health_component
				and not enemy.health_component.died.is_connected(
					_on_enemy_died.bind(enemy)
				)
			):
				enemy.health_component.died.connect(_on_enemy_died.bind(enemy))
		_collect_enemies(child)

func _begin_phase(enemy: EnemyBase) -> void:
	if not enemy.visuals:
		return
	var base_modulate := enemy.visuals.modulate
	var phased_modulate := base_modulate.lerp(essence_color, 0.42)
	phased_modulate.a = minimum_alpha
	var tween := enemy.visuals.create_tween()
	if _phase_tweens.has(enemy):
		var previous := _phase_tweens[enemy] as Tween
		if previous and previous.is_valid():
			previous.kill()
	_phase_tweens[enemy] = tween
	tween.tween_property(
		enemy.visuals,
		"modulate",
		phased_modulate,
		fade_out_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(phase_hold_duration)
	tween.tween_property(
		enemy.visuals,
		"modulate",
		base_modulate,
		fade_in_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_spawn_essence_echo(enemy)

func _on_enemy_died(_damage: DamageData, enemy: EnemyBase) -> void:
	_phase_timers.erase(enemy)
	if not _phase_tweens.has(enemy):
		return
	var tween := _phase_tweens[enemy] as Tween
	if tween and tween.is_valid():
		tween.kill()
	_phase_tweens.erase(enemy)

func _spawn_essence_echo(enemy: EnemyBase) -> void:
	var source := _find_sprite(enemy.visuals)
	var parent := enemy.get_parent()
	if not source or not source.texture or not parent:
		return
	var echo := Sprite2D.new()
	echo.name = "%sEssenceEcho" % enemy.name
	echo.texture = source.texture
	echo.hframes = source.hframes
	echo.vframes = source.vframes
	echo.frame = source.frame
	echo.region_enabled = source.region_enabled
	echo.region_rect = source.region_rect
	echo.centered = source.centered
	echo.offset = source.offset
	echo.flip_h = source.flip_h
	echo.flip_v = source.flip_v
	echo.z_as_relative = false
	echo.z_index = enemy.z_index - 1
	parent.add_child(echo)
	echo.global_transform = source.global_transform
	echo.modulate = Color(essence_color.r, essence_color.g, essence_color.b, 0.62)
	var echo_tween := echo.create_tween()
	echo_tween.set_parallel(true)
	echo_tween.tween_property(echo, "modulate:a", 0.0, fade_out_duration + phase_hold_duration + fade_in_duration)
	echo_tween.tween_property(echo, "scale", echo.scale * 1.08, fade_out_duration + phase_hold_duration + fade_in_duration)
	echo_tween.set_parallel(false)
	echo_tween.tween_callback(echo.queue_free)

func _find_sprite(node: Node) -> Sprite2D:
	for child in node.get_children():
		if child is Sprite2D and (child as Sprite2D).visible:
			return child as Sprite2D
		var nested := _find_sprite(child)
		if nested:
			return nested
	return null
