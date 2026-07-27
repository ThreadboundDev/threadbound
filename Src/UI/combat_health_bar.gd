extends Control
class_name CombatHealthBar

@export var track_texture: Texture2D:
	set(value):
		track_texture = value
		queue_redraw()
@export var fill_texture: Texture2D:
	set(value):
		fill_texture = value
		queue_redraw()
@export var fill_rect := Rect2(Vector2(0.0, 0.0), Vector2(760.0, 16.0)):
	set(value):
		fill_rect = value
		queue_redraw()
@export_range(0.0, 80.0, 0.5) var corner_radius := 8.0:
	set(value):
		corner_radius = value
		queue_redraw()
@export_range(2, 24, 1) var corner_segments := 10:
	set(value):
		corner_segments = value
		queue_redraw()
@export var track_tint := Color(0.76, 0.69, 0.58, 0.92):
	set(value):
		track_tint = value
		queue_redraw()
@export var leading_edge_color := Color(1.0, 0.88, 0.62, 0.92):
	set(value):
		leading_edge_color = value
		queue_redraw()

@export var max_health := 100:
	set(value):
		max_health = maxi(1, value)
		current_health = clampi(current_health, 0, max_health)
		queue_redraw()

@export var current_health := 100:
	set(value):
		current_health = clampi(value, 0, max_health)
		queue_redraw()

func set_health(current: int, maximum: int) -> void:
	max_health = maximum
	current_health = current

func _draw() -> void:
	if fill_rect.size.x <= 0.0 or fill_rect.size.y <= 0.0:
		return

	if track_texture:
		_draw_textured_rounded_rect(track_texture, fill_rect, 1.0, track_tint, true)

	var health_ratio := float(current_health) / float(max_health)
	if not fill_texture or health_ratio <= 0.0:
		return

	var active_rect := fill_rect
	active_rect.size.x *= health_ratio
	_draw_textured_rounded_rect(fill_texture, active_rect, health_ratio, Color.WHITE, true)

	if health_ratio < 1.0 and active_rect.size.x > 5.0:
		var edge_x := active_rect.end.x - 1.0
		draw_line(
			Vector2(edge_x, active_rect.position.y + 2.0),
			Vector2(edge_x, active_rect.end.y - 2.0),
			leading_edge_color,
			1.5,
			true
		)

func _draw_textured_rounded_rect(
	texture: Texture2D,
	rect: Rect2,
	source_ratio: float,
	tint: Color,
	round_right: bool
) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	var radius := minf(corner_radius, minf(rect.size.y * 0.5, rect.size.x * 0.5))
	var points := _make_rounded_rect_points(rect, radius, true, round_right)
	var texture_size := texture.get_size()
	var source_size := Vector2(texture_size.x * clampf(source_ratio, 0.0, 1.0), texture_size.y)
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	for point in points:
		colors.append(tint)
		var normalized := Vector2(
			(point.x - rect.position.x) / rect.size.x,
			(point.y - rect.position.y) / rect.size.y
		)
		uvs.append(normalized * source_size / texture_size)

	draw_polygon(points, colors, uvs, texture)

func _make_rounded_rect_points(
	rect: Rect2,
	radius: float,
	round_left: bool,
	round_right: bool
) -> PackedVector2Array:
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

func _append_arc(
	points: PackedVector2Array,
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float
) -> void:
	var segments := maxi(corner_segments, 2)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
