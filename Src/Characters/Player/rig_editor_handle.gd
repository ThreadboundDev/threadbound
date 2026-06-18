@tool
extends Node2D

@export var handle_color: Color = Color(0.35, 0.9, 1.0, 0.95):
	set(value):
		handle_color = value
		queue_redraw()

@export_range(4.0, 64.0, 1.0) var handle_radius: float = 18.0:
	set(value):
		handle_radius = value
		queue_redraw()

@export var draw_look_direction: bool = false:
	set(value):
		draw_look_direction = value
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var outline := Color.BLACK
	outline.a = 0.75
	draw_circle(Vector2.ZERO, handle_radius + 3.0, outline)
	draw_circle(Vector2.ZERO, handle_radius, handle_color)
	draw_arc(Vector2.ZERO, handle_radius + 6.0, 0.0, TAU, 32, handle_color, 2.0)
	draw_line(Vector2(-handle_radius * 1.35, 0.0), Vector2(handle_radius * 1.35, 0.0), outline, 3.0)
	draw_line(Vector2(0.0, -handle_radius * 1.35), Vector2(0.0, handle_radius * 1.35), outline, 3.0)
	draw_line(Vector2(-handle_radius * 1.2, 0.0), Vector2(handle_radius * 1.2, 0.0), Color.WHITE, 1.0)
	draw_line(Vector2(0.0, -handle_radius * 1.2), Vector2(0.0, handle_radius * 1.2), Color.WHITE, 1.0)

	if draw_look_direction:
		draw_line(Vector2.ZERO, Vector2(handle_radius * 2.4, 0.0), handle_color, 4.0)
		draw_line(Vector2(handle_radius * 2.4, 0.0), Vector2(handle_radius * 1.75, -handle_radius * 0.4), handle_color, 4.0)
		draw_line(Vector2(handle_radius * 2.4, 0.0), Vector2(handle_radius * 1.75, handle_radius * 0.4), handle_color, 4.0)

@warning_ignore("native_method_override")
func _edit_get_rect() -> Rect2:
	var size := handle_radius * 3.2
	return Rect2(Vector2(-size * 0.5, -size * 0.5), Vector2(size, size))

@warning_ignore("native_method_override")
func _edit_is_selected_on_click(point: Vector2, tolerance: float) -> bool:
	return point.length() <= handle_radius + tolerance
