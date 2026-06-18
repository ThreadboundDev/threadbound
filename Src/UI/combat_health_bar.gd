extends Control
class_name CombatHealthBar

const ART_SIZE := Vector2(1536.0, 1024.0)
const BAR_RECT := Rect2(Vector2(475.0, 486.0), Vector2(918.0, 46.0))
const BAR_RADIUS := 22.0

@export var frame_texture: Texture2D:
	set(value):
		frame_texture = value
		queue_redraw()

@export var max_health := 5:
	set(value):
		max_health = maxi(1, value)
		current_health = clampi(current_health, 0, max_health)
		queue_redraw()

@export var current_health := 5:
	set(value):
		current_health = clampi(value, 0, max_health)
		queue_redraw()

func set_health(current: int, maximum: int) -> void:
	max_health = maximum
	current_health = current

func _draw() -> void:
	if not frame_texture:
		return

	var scale_factor: float = min(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var draw_size := ART_SIZE * scale_factor
	var offset := (size - draw_size) * 0.5
	var fill_rect := Rect2(offset + BAR_RECT.position * scale_factor, BAR_RECT.size * scale_factor)
	var health_ratio := float(current_health) / float(max_health)

	if health_ratio > 0.0:
		var active_rect := fill_rect
		active_rect.size.x *= health_ratio
		var color := _get_health_color(health_ratio)
		draw_rect(active_rect, color)
		_draw_woven_bands(active_rect, color.lightened(0.28), scale_factor)

	draw_texture_rect(frame_texture, Rect2(offset, draw_size), false)

func _get_health_color(ratio: float) -> Color:
	if ratio >= 0.75:
		return Color(0.18, 0.9, 0.22, 1.0).lerp(Color(0.98, 0.86, 0.16, 1.0), (1.0 - ratio) / 0.25)
	if ratio >= 0.45:
		return Color(0.98, 0.86, 0.16, 1.0).lerp(Color(1.0, 0.48, 0.08, 1.0), (0.75 - ratio) / 0.3)
	return Color(1.0, 0.48, 0.08, 1.0).lerp(Color(0.95, 0.05, 0.04, 1.0), (0.45 - ratio) / 0.45)

func _draw_woven_bands(rect: Rect2, band_color: Color, scale_factor: float) -> void:
	var spacing := 30.0 * scale_factor
	var width := 6.0 * scale_factor
	var start_x := rect.position.x - rect.size.y
	var end_x := rect.end.x + rect.size.y
	var x := start_x
	while x < end_x:
		var from_x := clampf(x, rect.position.x, rect.end.x)
		var to_x := clampf(x + rect.size.y, rect.position.x, rect.end.x)
		if to_x > from_x:
			var from_y := rect.end.y - (from_x - x)
			var to_y := rect.end.y - (to_x - x)
			draw_line(Vector2(from_x, from_y), Vector2(to_x, to_y), band_color, width, true)
		x += spacing
