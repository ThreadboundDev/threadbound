extends Control
class_name CombatHealthBar

@export var negative_texture: Texture2D:
	set(value):
		negative_texture = value
		queue_redraw()
@export var green_texture: Texture2D:
	set(value):
		green_texture = value
		queue_redraw()
@export var yellow_texture: Texture2D:
	set(value):
		yellow_texture = value
		queue_redraw()
@export var orange_texture: Texture2D:
	set(value):
		orange_texture = value
		queue_redraw()
@export var red_texture: Texture2D:
	set(value):
		red_texture = value
		queue_redraw()

@export var fill_rect := Rect2(Vector2(0.0, 0.0), Vector2(760.0, 82.0)):
	set(value):
		fill_rect = value
		queue_redraw()
@export var texture_source_rect := Rect2(Vector2.ZERO, Vector2(1774.0, 887.0)):
	set(value):
		texture_source_rect = value
		queue_redraw()
@export_range(0.0, 80.0, 0.5) var corner_radius := 15.0:
	set(value):
		corner_radius = value
		queue_redraw()
@export_range(2, 24, 1) var corner_segments := 10:
	set(value):
		corner_segments = value
		queue_redraw()
@export var round_fill_leading_edge := false:
	set(value):
		round_fill_leading_edge = value
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
	var health_ratio := float(current_health) / float(max_health)

	if negative_texture:
		_draw_textured_rounded_rect(negative_texture, fill_rect, texture_source_rect, true, true)

	if health_ratio > 0.0:
		var active_texture := _get_health_texture(health_ratio)
		if active_texture:
			var active_rect := fill_rect
			active_rect.size.x *= health_ratio
			var source_rect := texture_source_rect
			source_rect.size.x *= health_ratio
			_draw_textured_rounded_rect(active_texture, active_rect, source_rect, true, round_fill_leading_edge or is_equal_approx(health_ratio, 1.0))

func _get_health_texture(ratio: float) -> Texture2D:
	if ratio >= 0.75:
		return green_texture
	if ratio >= 0.5:
		return yellow_texture
	if ratio >= 0.25:
		return orange_texture
	return red_texture

func _draw_textured_rounded_rect(texture: Texture2D, rect: Rect2, source_rect: Rect2, round_left: bool, round_right: bool) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	var radius := minf(corner_radius, minf(rect.size.y * 0.5, rect.size.x * 0.5))
	var points := _make_rounded_rect_points(rect, radius, round_left, round_right)
	var texture_size := texture.get_size()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	for point in points:
		colors.append(Color.WHITE)
		var normalized := Vector2(
			(point.x - rect.position.x) / rect.size.x,
			(point.y - rect.position.y) / rect.size.y
		)
		var source_point := source_rect.position + normalized * source_rect.size
		uvs.append(source_point / texture_size)

	draw_polygon(points, colors, uvs, texture)

func _make_rounded_rect_points(rect: Rect2, radius: float, round_left: bool, round_right: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var left := rect.position.x
	var top := rect.position.y
	var right := rect.end.x
	var bottom := rect.end.y
	var center_left_top := Vector2(left + radius, top + radius)
	var center_right_top := Vector2(right - radius, top + radius)
	var center_right_bottom := Vector2(right - radius, bottom - radius)
	var center_left_bottom := Vector2(left + radius, bottom - radius)

	if round_left:
		_append_arc(points, center_left_top, radius, PI, PI * 1.5)
	else:
		points.append(Vector2(left, top))

	if round_right:
		_append_arc(points, center_right_top, radius, PI * 1.5, TAU)
	else:
		points.append(Vector2(right, top))

	if round_right:
		_append_arc(points, center_right_bottom, radius, 0.0, PI * 0.5)
	else:
		points.append(Vector2(right, bottom))

	if round_left:
		_append_arc(points, center_left_bottom, radius, PI * 0.5, PI)
	else:
		points.append(Vector2(left, bottom))

	return points

func _append_arc(points: PackedVector2Array, center: Vector2, radius: float, start_angle: float, end_angle: float) -> void:
	var segments := maxi(corner_segments, 2)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
