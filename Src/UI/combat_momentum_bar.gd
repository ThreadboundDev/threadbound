extends Control
class_name CombatMomentumBar

@export var fill_texture: Texture2D:
	set(value):
		fill_texture = value
		queue_redraw()
@export var fill_rect := Rect2(Vector2(0.0, 0.0), Vector2(680.0, 12.0)):
	set(value):
		fill_rect = value
		queue_redraw()

@export_range(0.0, 1.0, 0.01) var value := 0.0:
	set(next_value):
		value = clampf(next_value, 0.0, 1.0)
		queue_redraw()
@export var smooth_fill_speed := 5.5
@export var flow_scroll_speed := 0.34
@export var flow_pulse_speed := 5.5

@export_group("State Tints")
@export var low_tint := Color(0.78, 0.76, 0.7, 0.84)
@export var mid_tint := Color(0.98, 0.95, 0.86, 1.0)
@export var high_tint := Color(1.08, 1.02, 0.78, 1.0)
@export var flow_tint := Color(1.2, 1.12, 0.8, 1.0)

var _display_value := 0.0
var _momentum_state: StringName = &"Low"
var _flow_active := false
var _flow_phase := 0.0

func _process(delta: float) -> void:
	var previous_value := _display_value
	_display_value = move_toward(_display_value, value, smooth_fill_speed * delta)
	if not is_equal_approx(previous_value, _display_value):
		queue_redraw()

	if _flow_active:
		_flow_phase = fmod(_flow_phase + delta * flow_scroll_speed, 1.0)
		queue_redraw()

func set_momentum(next_value: float) -> void:
	value = clampf(next_value, 0.0, 1.0)

func set_momentum_state(state: StringName, flow_active: bool) -> void:
	_momentum_state = state
	_flow_active = flow_active
	if not _flow_active:
		_flow_phase = 0.0
	queue_redraw()

func is_flow_active() -> bool:
	return _flow_active

func _draw() -> void:
	if not fill_texture or _display_value <= 0.0:
		return

	var active_rect := fill_rect
	active_rect.size.x *= _display_value
	var texture_size := fill_texture.get_size()
	var source_span := texture_size.x * _display_value
	if source_span <= 0.0:
		return

	var source_offset := texture_size.x * _flow_phase if _flow_active else 0.0
	var tint := _get_state_tint()
	if _flow_active:
		var pulse := (sin(Time.get_ticks_msec() * 0.001 * flow_pulse_speed) + 1.0) * 0.5
		tint = tint.lerp(Color(1.34, 1.24, 0.9, 1.0), pulse * 0.34)

	_draw_wrapped_texture(active_rect, source_offset, source_span, texture_size.y, tint)

func _draw_wrapped_texture(
	destination: Rect2,
	source_offset: float,
	source_span: float,
	source_height: float,
	tint: Color
) -> void:
	var texture_width := fill_texture.get_width()
	var wrapped_offset := fmod(source_offset, texture_width)
	var first_source_width := minf(source_span, texture_width - wrapped_offset)
	var first_destination_width := destination.size.x * (first_source_width / source_span)
	var first_destination := Rect2(destination.position, Vector2(first_destination_width, destination.size.y))
	var first_source := Rect2(Vector2(wrapped_offset, 0.0), Vector2(first_source_width, source_height))
	draw_texture_rect_region(fill_texture, first_destination, first_source, tint)

	var remaining_source_width := source_span - first_source_width
	if remaining_source_width <= 0.0:
		return

	var second_destination := Rect2(
		destination.position + Vector2(first_destination_width, 0.0),
		Vector2(destination.size.x - first_destination_width, destination.size.y)
	)
	var second_source := Rect2(Vector2.ZERO, Vector2(remaining_source_width, source_height))
	draw_texture_rect_region(fill_texture, second_destination, second_source, tint)

func _get_state_tint() -> Color:
	match _momentum_state:
		&"Flow":
			return flow_tint
		&"High":
			return high_tint
		&"Low":
			return low_tint
		_:
			return mid_tint
