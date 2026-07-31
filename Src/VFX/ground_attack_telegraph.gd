class_name GroundAttackTelegraph
extends Node2D

enum TelegraphMode {
	INACTIVE,
	WINDUP,
	IMPACT,
	LANDING,
}

@export_group("Palette")
@export var warning_color := Color(0.52, 0.24, 0.78, 1.0)
@export var highlight_color := Color(0.96, 0.88, 1.0, 1.0)
@export var ground_fill_color := Color(0.28, 0.10, 0.43, 1.0)

@export_group("Shape")
@export_range(4.0, 48.0, 1.0) var ground_ellipse_height := 18.0
@export_range(4, 32, 1) var stitch_count := 16
@export_range(0.04, 0.30, 0.01) var landing_impact_duration := 0.14

var _mode := TelegraphMode.INACTIVE
var _elapsed := 0.0
var _duration := 0.01
var _half_width := 32.0
var _landing_radius := 32.0
var _free_when_finished := false
var _landing_impact := false


func _ready() -> void:
	z_index = 18
	visible = false
	set_process(false)


func play_windup(full_width: float, duration: float) -> void:
	_half_width = maxf(16.0, full_width * 0.5)
	_duration = maxf(0.01, duration)
	_elapsed = 0.0
	_mode = TelegraphMode.WINDUP
	_free_when_finished = false
	_landing_impact = false
	visible = true
	set_process(true)
	queue_redraw()


func trigger_impact(full_width: float, duration: float) -> void:
	_half_width = maxf(16.0, full_width * 0.5)
	_duration = maxf(0.01, duration)
	_elapsed = 0.0
	_mode = TelegraphMode.IMPACT
	_free_when_finished = false
	_landing_impact = false
	visible = true
	set_process(true)
	queue_redraw()


func play_landing_marker(radius: float, flight_time: float) -> void:
	_landing_radius = maxf(12.0, radius)
	_half_width = _landing_radius
	_duration = maxf(0.05, flight_time)
	_elapsed = 0.0
	_mode = TelegraphMode.LANDING
	_free_when_finished = true
	_landing_impact = false
	visible = true
	set_process(true)
	queue_redraw()


func cancel_telegraph() -> void:
	if _free_when_finished:
		queue_free()
		return
	_finish()


func get_mode() -> TelegraphMode:
	return _mode


func get_full_width() -> float:
	return _half_width * 2.0


func get_duration() -> float:
	return _duration


func _process(delta: float) -> void:
	if _mode == TelegraphMode.INACTIVE:
		return

	_elapsed += delta
	if _mode == TelegraphMode.WINDUP:
		_elapsed = minf(_elapsed, _duration)
	elif _elapsed >= _duration:
		if _mode == TelegraphMode.LANDING:
			_mode = TelegraphMode.IMPACT
			_elapsed = 0.0
			_duration = landing_impact_duration
			_half_width = _landing_radius
			_landing_impact = true
		else:
			_finish()
			return
	queue_redraw()


func _finish() -> void:
	_mode = TelegraphMode.INACTIVE
	_elapsed = 0.0
	visible = false
	set_process(false)
	queue_redraw()
	if _free_when_finished:
		queue_free()


func _draw() -> void:
	match _mode:
		TelegraphMode.WINDUP:
			_draw_windup()
		TelegraphMode.IMPACT:
			_draw_impact()
		TelegraphMode.LANDING:
			_draw_landing_marker()


func _draw_windup() -> void:
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	var pulse := 0.88 + sin(progress * TAU * 3.0) * 0.12
	var ellipse_height := ground_ellipse_height

	var fill := ground_fill_color
	fill.a = lerpf(0.05, 0.20, progress) * pulse
	draw_colored_polygon(_ellipse_points(_half_width, ellipse_height, 48, false), fill)

	var outline := warning_color
	outline.a = lerpf(0.24, 0.78, progress) * pulse
	_draw_ellipse_outline(_half_width, ellipse_height, outline, lerpf(1.5, 3.5, progress))
	_draw_stitches(_half_width, ellipse_height, outline, lerpf(1.0, 2.5, progress))

	var focus := highlight_color
	focus.a = lerpf(0.12, 0.72, progress)
	var focus_width := lerpf(_half_width * 0.82, _half_width * 0.14, ease(progress, 1.6))
	_draw_ellipse_outline(focus_width, maxf(4.0, ellipse_height * focus_width / _half_width), focus, 2.0)


func _draw_impact() -> void:
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	var fade := pow(1.0 - progress, 1.6)
	var size_multiplier := 0.76 if _landing_impact else 1.0
	var shockwave_width := lerpf(_half_width * 0.10, _half_width * 1.08, ease(progress, -1.5))
	var shockwave_height := lerpf(4.0, ground_ellipse_height * size_multiplier * 1.35, progress)

	var flash := highlight_color
	flash.a = fade * (0.72 if _landing_impact else 0.94)
	_draw_ellipse_outline(shockwave_width, shockwave_height, flash, lerpf(6.0, 1.0, progress))

	var wake := warning_color
	wake.a = fade * 0.72
	var wake_width := lerpf(_half_width * 0.05, _half_width * 0.86, ease(progress, -1.2))
	_draw_ellipse_outline(wake_width, maxf(3.0, shockwave_height * 0.62), wake, lerpf(4.0, 1.0, progress))

	var ground_flash := ground_fill_color
	ground_flash.a = fade * 0.30
	draw_colored_polygon(
		_ellipse_points(_half_width * lerpf(0.42, 1.0, progress), ground_ellipse_height, 40, false),
		ground_flash
	)

	var fragment_count := 8 if _landing_impact else 14
	for index in range(fragment_count):
		var ratio := float(index) / float(maxi(1, fragment_count - 1))
		var direction := -1.0 if index % 2 == 0 else 1.0
		var x_position := lerpf(-_half_width * 0.88, _half_width * 0.88, ratio)
		var fragment_start := Vector2(x_position, -2.0)
		var fragment_end := fragment_start + Vector2(
			direction * lerpf(5.0, 15.0, progress),
			-lerpf(18.0, 4.0, progress) * (0.75 + absf(x_position) / _half_width * 0.25)
		)
		var fragment := highlight_color if index % 3 == 0 else warning_color
		fragment.a = fade * 0.68
		draw_line(fragment_start, fragment_end, fragment, lerpf(2.5, 1.0, progress), true)


func _draw_landing_marker() -> void:
	var progress := clampf(_elapsed / _duration, 0.0, 1.0)
	var pulse := 0.86 + sin(progress * TAU * 4.0) * 0.14
	var ellipse_height := maxf(7.0, _landing_radius * 0.34)

	var fill := ground_fill_color
	fill.a = lerpf(0.04, 0.18, progress)
	draw_colored_polygon(_ellipse_points(_landing_radius, ellipse_height, 36, false), fill)

	var stitches := warning_color
	stitches.a = lerpf(0.30, 0.86, progress) * pulse
	_draw_stitches(_landing_radius, ellipse_height, stitches, lerpf(1.5, 2.8, progress))

	var countdown := highlight_color
	countdown.a = lerpf(0.22, 0.92, progress)
	var countdown_radius := lerpf(_landing_radius * 0.82, _landing_radius * 0.16, ease(progress, 1.7))
	_draw_ellipse_outline(
		countdown_radius,
		maxf(3.0, ellipse_height * countdown_radius / _landing_radius),
		countdown,
		lerpf(1.2, 3.0, progress)
	)


func _draw_stitches(
	horizontal_radius: float,
	vertical_radius: float,
	color: Color,
	width: float
) -> void:
	var segment_count := maxi(4, stitch_count)
	for index in range(segment_count):
		if index % 2 != 0:
			continue
		var start_angle := TAU * float(index) / float(segment_count)
		var end_angle := TAU * float(index + 1) / float(segment_count)
		var start := Vector2(
			cos(start_angle) * horizontal_radius,
			sin(start_angle) * vertical_radius
		)
		var finish := Vector2(
			cos(end_angle) * horizontal_radius,
			sin(end_angle) * vertical_radius
		)
		draw_line(start, finish, color, width, true)


func _draw_ellipse_outline(
	horizontal_radius: float,
	vertical_radius: float,
	color: Color,
	width: float
) -> void:
	draw_polyline(
		_ellipse_points(horizontal_radius, vertical_radius, 48, true),
		color,
		width,
		true
	)


func _ellipse_points(
	horizontal_radius: float,
	vertical_radius: float,
	segments: int,
	close_shape: bool
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var point_count := maxi(8, segments)
	var final_index := point_count if close_shape else point_count - 1
	for index in range(final_index + 1):
		var angle := TAU * float(index % point_count) / float(point_count)
		points.append(Vector2(
			cos(angle) * horizontal_radius,
			sin(angle) * vertical_radius
		))
	return points
