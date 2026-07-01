@tool
class_name BossHealthBar
extends Control

const FRAME_SOURCE_RECT := Rect2(Vector2(0.0, 90.0), Vector2(1536.0, 520.0))
const ART_SIZE := FRAME_SOURCE_RECT.size
const THREADLING_IDLE_COLUMNS := 6
const THREADLING_IDLE_ROWS := 6
const THREADLING_ICON_FRAME := 0
const THREADLING_ICON_INSET := Rect2(Vector2(42.0, 30.0), Vector2(142.0, 112.0))

@export_group("Boss Bar Layout")
@export var health_fill_rect := Rect2(Vector2(305.0, 360.0), Vector2(950.0, 130.0)):
	set(value):
		health_fill_rect = value
		queue_redraw()
@export var beam_fill_source_rect := Rect2(Vector2.ZERO, Vector2(1536.0, 110.0)):
	set(value):
		beam_fill_source_rect = value
		queue_redraw()
@export var bar_fill_bleed := 5.0:
	set(value):
		bar_fill_bleed = value
		queue_redraw()
@export var left_orb_center := Vector2(202.0, 421.0):
	set(value):
		left_orb_center = value
		queue_redraw()
@export var right_orb_center := Vector2(1332.0, 421.0):
	set(value):
		right_orb_center = value
		queue_redraw()
@export var orb_radius := 92.0:
	set(value):
		orb_radius = value
		queue_redraw()
@export var threadling_icon_scale := Vector2(2.15, 1.75):
	set(value):
		threadling_icon_scale = value
		queue_redraw()
@export var threadling_icon_offset := Vector2(0.0, 6.0):
	set(value):
		threadling_icon_offset = value
		queue_redraw()

@export var editor_preview_alive_links := true:
	set(value):
		editor_preview_alive_links = value
		queue_redraw()

@export var editor_preview_armored_fill := false:
	set(value):
		editor_preview_armored_fill = value
		queue_redraw()

@export_group("Boss Bar Colors")
@export var unarmored_fill_tint := Color(1.0, 0.22, 0.08, 1.0):
	set(value):
		unarmored_fill_tint = value
		queue_redraw()
@export var armored_fill_tint := Color(0.86, 0.88, 0.9, 0.94):
	set(value):
		armored_fill_tint = value
		queue_redraw()

@export_group("Textures")

@export var frame_texture: Texture2D:
	set(value):
		frame_texture = value
		queue_redraw()

@export var fill_texture: Texture2D:
	set(value):
		fill_texture = value
		queue_redraw()

@export var threadling_icon_texture: Texture2D:
	set(value):
		threadling_icon_texture = value
		queue_redraw()

@export var max_health := 1000:
	set(value):
		max_health = maxi(1, value)
		current_health = clampi(current_health, 0, max_health)
		queue_redraw()

@export var current_health := 1000:
	set(value):
		current_health = clampi(value, 0, max_health)
		queue_redraw()

var _link_alive := [false, false]
var _link_respawn_remaining := [0.0, 0.0]
var _link_respawn_duration := [1.0, 1.0]
var _link_pulse_warning_time := 3.0

func set_health(current: int, maximum: int) -> void:
	max_health = maximum
	current_health = current

func set_armor_link_state(index: int, alive: bool, respawn_remaining: float, respawn_duration: float, pulse_warning_time: float) -> void:
	if index < 0 or index >= _link_alive.size():
		return

	_link_alive[index] = alive
	_link_respawn_remaining[index] = maxf(0.0, respawn_remaining)
	_link_respawn_duration[index] = maxf(0.01, respawn_duration)
	_link_pulse_warning_time = maxf(0.01, pulse_warning_time)
	queue_redraw()

func _process(_delta: float) -> void:
	for index in range(_link_alive.size()):
		if not _link_alive[index] and _link_respawn_remaining[index] > 0.0 and _link_respawn_remaining[index] <= _link_pulse_warning_time:
			queue_redraw()
			return

func _draw() -> void:
	if not frame_texture:
		return

	var scale_factor: float = min(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var draw_size := ART_SIZE * scale_factor
	var offset := (size - draw_size) * 0.5
	var health_ratio := float(current_health) / float(max_health)
	var is_armored: bool = _is_armored()
	if Engine.is_editor_hint():
		is_armored = editor_preview_armored_fill

	_draw_orb(offset, scale_factor, 0, left_orb_center, false)
	_draw_orb(offset, scale_factor, 1, right_orb_center, true)
	_draw_health_fill(offset, scale_factor, health_ratio, is_armored)
	draw_texture_rect_region(frame_texture, Rect2(offset, draw_size), FRAME_SOURCE_RECT)

func _draw_health_fill(offset: Vector2, scale_factor: float, health_ratio: float, is_armored: bool) -> void:
	if health_ratio <= 0.0:
		return

	var fill_width := health_fill_rect.size.x * health_ratio
	var source_rect := Rect2(health_fill_rect.position, Vector2(fill_width, health_fill_rect.size.y)).grow(bar_fill_bleed)
	var rect := _source_to_draw_rect(source_rect, offset, scale_factor)
	var color := unarmored_fill_tint
	if is_armored:
		color = armored_fill_tint

	_draw_textured_fill(rect, color, scale_factor, is_armored)

func _draw_orb(offset: Vector2, scale_factor: float, index: int, center: Vector2, flip_icon: bool) -> void:
	var orb_center := offset + (center - FRAME_SOURCE_RECT.position) * scale_factor
	var radius := orb_radius * scale_factor
	var alive: bool = _is_link_alive_for_draw(index)
	var backing_color := Color(0.08, 0.04, 0.035, 0.98)

	if alive:
		backing_color = Color(0.18, 0.04, 0.025, 1.0)

	draw_circle(orb_center, radius * 1.2, Color(1.0, 0.12, 0.04, 0.18 if alive else 0.06))
	draw_circle(orb_center, radius, backing_color)
	_draw_threadling_icon(orb_center, radius, alive, flip_icon)
	if not alive:
		_draw_armor_respawn_wedge(orb_center, radius, index)
	draw_arc(orb_center, radius * 0.98, 0.0, TAU, 48, Color(1.0, 0.58, 0.32, 0.62), 3.0 * scale_factor, true)

func _draw_textured_fill(rect: Rect2, color: Color, scale_factor: float, is_armored: bool) -> void:
	var glow_rect := rect.grow(7.0 * scale_factor)
	var glow_color := Color(1.0, 0.08, 0.02, 0.18)
	var bed_color := Color(0.12, 0.0, 0.02, 0.95)
	var highlight_color := Color(1.0, 0.9, 0.64, 0.22)
	var core_color := Color(1.0, 0.92, 0.7, 0.34)
	if is_armored:
		glow_color = Color(0.78, 0.82, 0.86, 0.14)
		bed_color = Color(0.16, 0.17, 0.18, 0.94)
		highlight_color = Color(0.94, 0.96, 1.0, 0.2)
		core_color = Color(0.96, 0.98, 1.0, 0.3)

	draw_rect(glow_rect, glow_color)
	draw_rect(rect, bed_color)

	if fill_texture:
		draw_texture_rect_region(fill_texture, rect, beam_fill_source_rect, color)
	else:
		draw_rect(rect, color)

	var highlight_rect := Rect2(rect.position + Vector2(0.0, rect.size.y * 0.16), Vector2(rect.size.x, rect.size.y * 0.18))
	draw_rect(highlight_rect, highlight_color)
	draw_line(
		rect.position + Vector2(0.0, rect.size.y * 0.5),
		rect.position + Vector2(rect.size.x, rect.size.y * 0.5),
		core_color,
		2.5 * scale_factor,
		true
	)

func _source_to_draw_rect(source_rect: Rect2, offset: Vector2, scale_factor: float) -> Rect2:
	return Rect2(
		offset + (source_rect.position - FRAME_SOURCE_RECT.position) * scale_factor,
		source_rect.size * scale_factor
	)

func _draw_threadling_icon(center: Vector2, radius: float, alive: bool, flip_icon: bool) -> void:
	if not threadling_icon_texture:
		return

	var cell_size := Vector2(
		float(threadling_icon_texture.get_width()) / float(THREADLING_IDLE_COLUMNS),
		float(threadling_icon_texture.get_height()) / float(THREADLING_IDLE_ROWS)
	)
	var frame_column := THREADLING_ICON_FRAME % THREADLING_IDLE_COLUMNS
	var frame_row := floori(float(THREADLING_ICON_FRAME) / float(THREADLING_IDLE_COLUMNS))
	var source_rect := Rect2(Vector2(frame_column, frame_row) * cell_size + THREADLING_ICON_INSET.position, THREADLING_ICON_INSET.size)
	var icon_size := Vector2(radius * threadling_icon_scale.x, radius * threadling_icon_scale.y)
	var local_rect := Rect2(-icon_size * 0.5 + threadling_icon_offset, icon_size)
	var tint := Color(1.0, 1.0, 1.0, 1.0) if alive else Color(0.34, 0.34, 0.34, 0.92)
	if flip_icon:
		draw_set_transform(center, 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect_region(threadling_icon_texture, local_rect, source_rect, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_set_transform(center, 0.0, Vector2.ONE)
		draw_texture_rect_region(threadling_icon_texture, local_rect, source_rect, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_armor_respawn_wedge(center: Vector2, radius: float, index: int) -> void:
	var duration: float = maxf(0.01, _link_respawn_duration[index])
	var remaining_ratio: float = clampf(_link_respawn_remaining[index] / duration, 0.0, 1.0)
	if remaining_ratio <= 0.0:
		return

	var points := PackedVector2Array()
	points.append(center)
	var start_angle := -PI * 0.5
	var arc_angle := TAU * remaining_ratio
	var steps := maxi(4, ceili(36.0 * remaining_ratio))
	for i in range(steps + 1):
		var angle := start_angle + arc_angle * (float(i) / float(steps))
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)

	draw_colored_polygon(points, Color(0.05, 0.05, 0.055, 0.68))

func _is_armored() -> bool:
	for alive_variant in _link_alive:
		var alive := bool(alive_variant)
		if alive:
			return true
	return false

func _is_link_alive_for_draw(index: int) -> bool:
	if Engine.is_editor_hint() and editor_preview_alive_links:
		return true
	return bool(_link_alive[index])
