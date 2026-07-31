class_name EnemyHealthBar
extends Node2D

@export var bar_size := Vector2(58.0, 7.0):
	set(value):
		bar_size = Vector2(maxf(4.0, value.x), maxf(3.0, value.y))
		queue_redraw()
@export_range(0.0, 48.0, 1.0) var anchor_margin := 16.0
@export_range(0.1, 5.0, 0.1) var visible_duration := 1.8
@export_range(0.05, 1.0, 0.05) var fade_duration := 0.2
@export var outline_color := Color(0.04, 0.025, 0.02, 0.96):
	set(value):
		outline_color = value
		queue_redraw()
@export var track_color := Color(0.18, 0.12, 0.1, 0.94):
	set(value):
		track_color = value
		queue_redraw()
@export var fill_color := Color(0.76, 0.08, 0.075, 1.0):
	set(value):
		fill_color = value
		queue_redraw()
@export var leading_edge_color := Color(1.0, 0.76, 0.38, 0.95):
	set(value):
		leading_edge_color = value
		queue_redraw()

var _health_component: HealthComponent
var _enabled := false
var _health_ratio := 1.0
var _remaining_time := 0.0

func _ready() -> void:
	_hide_bar()

func setup(
	component: HealthComponent,
	owner_hurtbox: HurtboxComponent,
	enabled: bool
) -> void:
	_health_component = component
	_enabled = enabled and _health_component != null
	_auto_position_from_hurtbox(owner_hurtbox)
	_hide_bar()
	if not _enabled:
		return

	if not _health_component.damaged.is_connected(_on_damaged):
		_health_component.damaged.connect(_on_damaged)
	if not _health_component.health_changed.is_connected(_on_health_changed):
		_health_component.health_changed.connect(_on_health_changed)
	if not _health_component.died.is_connected(_on_died):
		_health_component.died.connect(_on_died)
	_sync_health(
		_health_component.current_health,
		_health_component.max_health
	)

func _process(delta: float) -> void:
	if not _enabled or not visible:
		set_process(false)
		return

	_remaining_time = maxf(0.0, _remaining_time - delta)
	if _remaining_time <= 0.0:
		_hide_bar()
		return

	if _remaining_time <= fade_duration:
		modulate.a = clampf(_remaining_time / fade_duration, 0.0, 1.0)
	else:
		modulate.a = 1.0

func _draw() -> void:
	var outer_rect := Rect2(-bar_size * 0.5, bar_size)
	draw_rect(outer_rect, outline_color)

	var inset := Vector2(1.5, 1.5)
	var track_rect := Rect2(
		outer_rect.position + inset,
		outer_rect.size - inset * 2.0
	)
	draw_rect(track_rect, track_color)

	if _health_ratio <= 0.0:
		return

	var fill_rect := track_rect
	fill_rect.size.x *= _health_ratio
	draw_rect(fill_rect, fill_color)
	if _health_ratio < 1.0 and fill_rect.size.x > 2.0:
		var edge_x := fill_rect.end.x - 0.5
		draw_line(
			Vector2(edge_x, fill_rect.position.y),
			Vector2(edge_x, fill_rect.end.y),
			leading_edge_color,
			1.0,
			true
		)

func _on_damaged(_damage: DamageData) -> void:
	if not _enabled or not _health_component:
		return

	_sync_health(
		_health_component.current_health,
		_health_component.max_health
	)
	if _health_component.current_health <= 0:
		_hide_bar()
		return

	_remaining_time = visible_duration + fade_duration
	modulate.a = 1.0
	visible = true
	set_process(true)

func _on_health_changed(current: int, maximum: int) -> void:
	_sync_health(current, maximum)
	if current <= 0 or current >= maximum:
		_hide_bar()

func _on_died(_damage: DamageData) -> void:
	_hide_bar()

func _sync_health(current: int, maximum: int) -> void:
	_health_ratio = clampf(
		float(maxi(0, current)) / float(maxi(1, maximum)),
		0.0,
		1.0
	)
	queue_redraw()

func _hide_bar() -> void:
	_remaining_time = 0.0
	modulate.a = 1.0
	visible = false
	set_process(false)

func _auto_position_from_hurtbox(owner_hurtbox: HurtboxComponent) -> void:
	if not owner_hurtbox:
		position = Vector2(0.0, -72.0)
		return

	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	var found_shape := false
	for child in owner_hurtbox.get_children():
		var collision_shape := child as CollisionShape2D
		if not collision_shape or collision_shape.disabled or not collision_shape.shape:
			continue

		var shape_rect := collision_shape.shape.get_rect()
		var combined_transform := owner_hurtbox.transform * collision_shape.transform
		var corners := PackedVector2Array([
			shape_rect.position,
			Vector2(shape_rect.end.x, shape_rect.position.y),
			shape_rect.end,
			Vector2(shape_rect.position.x, shape_rect.end.y),
		])
		for corner in corners:
			var transformed_corner := combined_transform * corner
			minimum.x = minf(minimum.x, transformed_corner.x)
			minimum.y = minf(minimum.y, transformed_corner.y)
			maximum.x = maxf(maximum.x, transformed_corner.x)
			maximum.y = maxf(maximum.y, transformed_corner.y)
		found_shape = true

	if not found_shape:
		position = Vector2(0.0, -72.0)
		return

	position = Vector2(
		(minimum.x + maximum.x) * 0.5,
		minimum.y - anchor_margin
	)
