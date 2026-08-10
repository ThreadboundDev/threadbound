class_name ProtoWeaverBeam
extends Node2D

enum BeamState {
	HIDDEN,
	TRACKING,
	LOCKED,
	FIRING,
}

const POWER_RED := Color(1.0, 0.035, 0.012, 0.9)
const BALANCE_BLUE := Color(0.035, 0.3, 1.0, 0.9)
const ESSENCE_YELLOW := Color(1.0, 0.78, 0.08, 0.9)

@export var tracking_color := Color(0.92, 0.97, 1.0, 0.68)
@export var lock_color := Color(1.0, 0.96, 0.82, 0.94)
@export var glow_color := Color(0.2, 0.08, 0.32, 0.2)
@export var core_color := Color(1.0, 0.98, 0.92, 1.0)
@export var segment_length := 42.0
@export var beam_width := 30.0
@export var wave_amplitude := 10.0
@export var animation_speed := 18.0

var _state := BeamState.HIDDEN
var _beam_length := 1.0
var _animation_time := 0.0

func _ready() -> void:
	top_level = true
	visible = false
	set_process(false)
	z_index = -1

func set_beam(global_start: Vector2, global_end: Vector2) -> void:
	global_position = global_start
	var delta := global_end - global_start
	_beam_length = maxf(1.0, delta.length())
	rotation = delta.angle()
	queue_redraw()

func show_tracking() -> void:
	_set_state(BeamState.TRACKING)

func show_locked() -> void:
	_set_state(BeamState.LOCKED)

func show_firing() -> void:
	_set_state(BeamState.FIRING)

func hide_beam() -> void:
	_set_state(BeamState.HIDDEN)

func is_presenting() -> bool:
	return _state != BeamState.HIDDEN

func _set_state(next_state: BeamState) -> void:
	_state = next_state
	visible = next_state != BeamState.HIDDEN
	set_process(visible)
	if next_state == BeamState.FIRING:
		_animation_time = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	_animation_time += delta
	queue_redraw()

func _draw() -> void:
	match _state:
		BeamState.TRACKING:
			_draw_tracking_line(false)
		BeamState.LOCKED:
			_draw_tracking_line(true)
		BeamState.FIRING:
			_draw_animated_beam()

func _draw_tracking_line(is_locked: bool) -> void:
	var pulse := 0.5 + sin(_animation_time * 11.0) * 0.5
	var color := lock_color if is_locked else tracking_color
	var width := lerpf(3.0, 5.0, pulse) if is_locked else lerpf(1.5, 2.5, pulse)
	var dash := maxf(12.0, segment_length)
	var gap := dash * 0.42
	var cursor := fmod(_animation_time * 150.0, dash + gap)
	while cursor < _beam_length:
		var end_x := minf(_beam_length, cursor + dash)
		var segment_index := floori(cursor / maxf(1.0, dash + gap))
		var segment_color := color
		if not is_locked:
			segment_color = [POWER_RED, BALANCE_BLUE, ESSENCE_YELLOW][segment_index % 3]
			segment_color.a = color.a
		draw_line(Vector2(cursor, 0.0), Vector2(end_x, 0.0), segment_color, width, true)
		cursor += dash + gap
	_draw_muzzle_flare(lerpf(0.55, 0.9, pulse), color)

func _draw_animated_beam() -> void:
	var pulse := 0.5 + sin(_animation_time * animation_speed) * 0.5
	var spine := _build_wave_points(0.0, wave_amplitude * 0.2, 1.0)
	draw_polyline(spine, glow_color, beam_width * lerpf(2.2, 2.7, pulse), true)
	draw_polyline(spine, Color(0.055, 0.025, 0.08, 0.96), beam_width * lerpf(1.04, 1.18, pulse), true)

	var filament_colors := [POWER_RED, BALANCE_BLUE, ESSENCE_YELLOW]
	for strand in range(3):
		var offset := (float(strand) - 1.0) * beam_width * 0.3
		var strand_points := _build_wave_points(
			offset,
			wave_amplitude * (0.5 + float(strand) * 0.11),
			1.45 + float(strand) * 0.27
		)
		draw_polyline(strand_points, filament_colors[strand], lerpf(4.0, 6.5, pulse), true)

	draw_polyline(spine, core_color, beam_width * lerpf(0.2, 0.3, pulse), true)

	_draw_muzzle_flare(1.0 + pulse * 0.28, core_color)
	_draw_impact_flare(pulse)

func _build_wave_points(offset: float, amplitude: float, frequency: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := maxi(12, ceili(_beam_length / 48.0))
	for step in range(steps + 1):
		var ratio := float(step) / float(steps)
		var envelope := sin(ratio * PI)
		var wave := sin(
			ratio * TAU * (3.0 * frequency)
			- _animation_time * animation_speed * frequency
		)
		points.append(Vector2(ratio * _beam_length, offset + wave * amplitude * envelope))
	return points

func _draw_muzzle_flare(scale_factor: float, color: Color) -> void:
	var radius := beam_width * scale_factor
	draw_circle(Vector2.ZERO, radius * 1.45, Color(color.r, color.g, color.b, 0.13))
	draw_circle(Vector2.ZERO, radius * 0.52, Color(color.r, color.g, color.b, 0.92))
	for ray in range(9):
		var angle := float(ray) * TAU / 9.0 + _animation_time * 0.7
		var direction := Vector2.from_angle(angle)
		var ray_color: Color = [POWER_RED, BALANCE_BLUE, ESSENCE_YELLOW][ray % 3] if _state == BeamState.FIRING else color
		draw_line(direction * radius * 0.25, direction * radius, ray_color, 2.0, true)

func _draw_impact_flare(pulse: float) -> void:
	var end := Vector2(_beam_length, 0.0)
	var radius := beam_width * lerpf(0.8, 1.4, pulse)
	draw_circle(end, radius * 1.7, Color(0.2, 0.08, 0.32, 0.16))
	draw_circle(end, radius * 0.48, core_color)
	for ray in range(9):
		var angle := float(ray) * TAU / 9.0 - _animation_time
		var direction := Vector2.from_angle(angle)
		draw_line(end + direction * radius * 0.4, end + direction * radius * 1.55, [POWER_RED, BALANCE_BLUE, ESSENCE_YELLOW][ray % 3], 3.0, true)
