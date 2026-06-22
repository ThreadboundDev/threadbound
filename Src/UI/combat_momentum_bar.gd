extends Control
class_name CombatMomentumBar

@export var fill_texture: Texture2D:
	set(value):
		fill_texture = value
		queue_redraw()
@export var fill_rect := Rect2(Vector2(0.0, 0.0), Vector2(680.0, 34.0)):
	set(value):
		fill_rect = value
		queue_redraw()
@export var texture_source_rect := Rect2(Vector2.ZERO, Vector2(1536.0, 175.0)):
	set(value):
		texture_source_rect = value
		queue_redraw()

@export_range(0.0, 1.0, 0.01) var value := 0.0:
	set(next_value):
		value = clampf(next_value, 0.0, 1.0)
		queue_redraw()
@export var smooth_fill_speed := 5.5

var _display_value := 0.0

func _process(delta: float) -> void:
	var previous_value := _display_value
	_display_value = move_toward(_display_value, value, smooth_fill_speed * delta)
	if not is_equal_approx(previous_value, _display_value):
		queue_redraw()

func set_momentum(next_value: float) -> void:
	value = clampf(next_value, 0.0, 1.0)

func _draw() -> void:
	if not fill_texture or _display_value <= 0.0:
		return

	var active_rect := fill_rect
	active_rect.size.x *= _display_value
	var source_rect := texture_source_rect
	source_rect.size.x *= _display_value
	draw_texture_rect_region(fill_texture, active_rect, source_rect)
