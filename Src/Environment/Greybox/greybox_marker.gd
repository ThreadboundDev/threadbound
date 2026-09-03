@tool
class_name GreyboxMarker2D
extends Marker2D

@export var label_text := "Annotation":
	set(value):
		label_text = value
		queue_redraw()
@export var marker_color := Color.WHITE:
	set(value):
		marker_color = value
		queue_redraw()
@export_multiline var notes := ""


func _draw() -> void:
	draw_circle(Vector2.ZERO, 18.0, marker_color)
	draw_circle(Vector2.ZERO, 24.0, marker_color, false, 4.0)
	draw_line(Vector2(0, -36), Vector2(0, 36), marker_color, 3.0)
	draw_line(Vector2(-36, 0), Vector2(36, 0), marker_color, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(32, 6), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, marker_color)
