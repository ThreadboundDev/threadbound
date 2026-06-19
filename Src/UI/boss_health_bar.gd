class_name BossHealthBar
extends Control

const FRAME_SOURCE_RECT := Rect2(Vector2(0.0, 90.0), Vector2(1536.0, 520.0))
const ART_SIZE := FRAME_SOURCE_RECT.size
const LEFT_BAR_RECT := Rect2(Vector2(304.0, 382.0), Vector2(430.0, 88.0))
const RIGHT_BAR_RECT := Rect2(Vector2(802.0, 382.0), Vector2(430.0, 88.0))
const LEFT_ORB_CENTER := Vector2(202.0, 421.0)
const RIGHT_ORB_CENTER := Vector2(1332.0, 421.0)
const ORB_RADIUS := 72.0
const BEAM_FILL_REGION := Rect2(Vector2(0.0, 360.0), Vector2(1536.0, 310.0))
const BAR_FILL_BLEED := 18.0

@export var frame_texture: Texture2D:
	set(value):
		frame_texture = value
		queue_redraw()

@export var fill_texture: Texture2D:
	set(value):
		fill_texture = value
		queue_redraw()

@export var max_health := 10:
	set(value):
		max_health = maxi(1, value)
		current_health = clampi(current_health, 0, max_health)
		queue_redraw()

@export var current_health := 10:
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

	_draw_orb(offset, scale_factor, 0, LEFT_ORB_CENTER)
	_draw_orb(offset, scale_factor, 1, RIGHT_ORB_CENTER)
	_draw_health_fill(offset, scale_factor, health_ratio)
	draw_texture_rect_region(frame_texture, Rect2(offset, draw_size), FRAME_SOURCE_RECT)

func _draw_health_fill(offset: Vector2, scale_factor: float, health_ratio: float) -> void:
	if health_ratio <= 0.0:
		return

	var color := Color(1.0, 0.34, 0.26, 1.0).lerp(Color(0.42, 0.02, 0.05, 1.0), 1.0 - health_ratio)
	var total_width := LEFT_BAR_RECT.size.x + RIGHT_BAR_RECT.size.x
	var remaining_width := total_width * health_ratio

	var left_width := minf(LEFT_BAR_RECT.size.x, remaining_width)
	if left_width > 0.0:
		var left_source_rect := Rect2(LEFT_BAR_RECT.position, Vector2(left_width, LEFT_BAR_RECT.size.y)).grow(BAR_FILL_BLEED)
		var left_rect := _source_to_draw_rect(
			left_source_rect,
			offset,
			scale_factor
		)
		_draw_textured_fill(left_rect, color, scale_factor)

	remaining_width -= LEFT_BAR_RECT.size.x
	if remaining_width > 0.0:
		var right_width := minf(RIGHT_BAR_RECT.size.x, remaining_width)
		var right_source_rect := Rect2(RIGHT_BAR_RECT.position, Vector2(right_width, RIGHT_BAR_RECT.size.y)).grow(BAR_FILL_BLEED)
		var right_rect := _source_to_draw_rect(
			right_source_rect,
			offset,
			scale_factor
		)
		_draw_textured_fill(right_rect, color, scale_factor)

func _draw_orb(offset: Vector2, scale_factor: float, index: int, center: Vector2) -> void:
	var orb_center := offset + (center - FRAME_SOURCE_RECT.position) * scale_factor
	var radius := ORB_RADIUS * scale_factor
	var color := Color(0.11, 0.0, 0.015, 0.9)

	if _link_alive[index]:
		color = Color(1.0, 0.15, 0.08, 0.95)
	elif _link_respawn_remaining[index] <= _link_pulse_warning_time and _link_respawn_remaining[index] > 0.0:
		var pulse := (sin(Time.get_ticks_msec() * 0.012) + 1.0) * 0.5
		color = Color(0.22, 0.0, 0.025, 0.9).lerp(Color(1.0, 0.18, 0.08, 0.95), pulse)

	draw_circle(orb_center, radius * 1.2, Color(1.0, 0.12, 0.04, color.a * 0.18))
	draw_circle(orb_center, radius, color)
	draw_arc(orb_center, radius * 0.98, 0.0, TAU, 48, Color(1.0, 0.58, 0.32, 0.62), 3.0 * scale_factor, true)

func _draw_textured_fill(rect: Rect2, color: Color, scale_factor: float) -> void:
	var glow_rect := rect.grow(7.0 * scale_factor)
	draw_rect(glow_rect, Color(1.0, 0.08, 0.02, 0.18))
	draw_rect(rect, Color(0.12, 0.0, 0.02, 0.95))

	if fill_texture:
		draw_texture_rect_region(fill_texture, rect, BEAM_FILL_REGION, color)
	else:
		draw_rect(rect, color)

	var highlight_rect := Rect2(rect.position + Vector2(0.0, rect.size.y * 0.16), Vector2(rect.size.x, rect.size.y * 0.18))
	draw_rect(highlight_rect, Color(1.0, 0.9, 0.64, 0.22))
	draw_line(
		rect.position + Vector2(0.0, rect.size.y * 0.5),
		rect.position + Vector2(rect.size.x, rect.size.y * 0.5),
		Color(1.0, 0.92, 0.7, 0.34),
		2.5 * scale_factor,
		true
	)

func _source_to_draw_rect(source_rect: Rect2, offset: Vector2, scale_factor: float) -> Rect2:
	return Rect2(
		offset + (source_rect.position - FRAME_SOURCE_RECT.position) * scale_factor,
		source_rect.size * scale_factor
	)
