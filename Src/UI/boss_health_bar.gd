class_name BossHealthBar
extends Control

const ART_SIZE := Vector2(1536.0, 1024.0)
const LEFT_BAR_RECT := Rect2(Vector2(304.0, 382.0), Vector2(430.0, 88.0))
const RIGHT_BAR_RECT := Rect2(Vector2(802.0, 382.0), Vector2(430.0, 88.0))
const LEFT_ORB_CENTER := Vector2(202.0, 421.0)
const RIGHT_ORB_CENTER := Vector2(1332.0, 421.0)
const ORB_RADIUS := 72.0

@export var frame_texture: Texture2D:
	set(value):
		frame_texture = value
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
	draw_texture_rect(frame_texture, Rect2(offset, draw_size), false)

func _draw_health_fill(offset: Vector2, scale_factor: float, health_ratio: float) -> void:
	if health_ratio <= 0.0:
		return

	var color := Color(0.92, 0.04, 0.03, 1.0).lerp(Color(0.28, 0.0, 0.015, 1.0), 1.0 - health_ratio)
	var total_width := LEFT_BAR_RECT.size.x + RIGHT_BAR_RECT.size.x
	var remaining_width := total_width * health_ratio

	var left_width := minf(LEFT_BAR_RECT.size.x, remaining_width)
	if left_width > 0.0:
		var left_rect := Rect2(offset + LEFT_BAR_RECT.position * scale_factor, Vector2(left_width, LEFT_BAR_RECT.size.y) * scale_factor)
		draw_rect(left_rect, color)
		_draw_woven_bands(left_rect, color.lightened(0.22), scale_factor)

	remaining_width -= LEFT_BAR_RECT.size.x
	if remaining_width > 0.0:
		var right_width := minf(RIGHT_BAR_RECT.size.x, remaining_width)
		var right_rect := Rect2(offset + RIGHT_BAR_RECT.position * scale_factor, Vector2(right_width, RIGHT_BAR_RECT.size.y) * scale_factor)
		draw_rect(right_rect, color)
		_draw_woven_bands(right_rect, color.lightened(0.22), scale_factor)

func _draw_orb(offset: Vector2, scale_factor: float, index: int, center: Vector2) -> void:
	var orb_center := offset + center * scale_factor
	var radius := ORB_RADIUS * scale_factor
	var color := Color(0.11, 0.0, 0.015, 0.9)

	if _link_alive[index]:
		color = Color(0.95, 0.04, 0.02, 0.95)
	elif _link_respawn_remaining[index] <= _link_pulse_warning_time and _link_respawn_remaining[index] > 0.0:
		var pulse := (sin(Time.get_ticks_msec() * 0.012) + 1.0) * 0.5
		color = Color(0.25, 0.0, 0.025, 0.9).lerp(Color(0.9, 0.02, 0.02, 0.95), pulse)

	draw_circle(orb_center, radius, color)

func _draw_woven_bands(rect: Rect2, band_color: Color, scale_factor: float) -> void:
	var spacing := 28.0 * scale_factor
	var width := 5.0 * scale_factor
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
