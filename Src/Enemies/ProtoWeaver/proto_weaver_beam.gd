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
@export var beam_width := 38.0
@export var wave_amplitude := 12.0
@export var animation_speed := 18.0

var _state := BeamState.HIDDEN
var _beam_length := 1.0
var _animation_time := 0.0

func _ready() -> void:
	top_level = true
	visible = false
	set_process(false)
	# Keep the beam over arena architecture in the boss-test and encounter
	# scenes while the head-attached muzzle flare still covers its origin.
	z_index = 4

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
	var guide_colors := [POWER_RED, BALANCE_BLUE, ESSENCE_YELLOW]
	for strand in range(3):
		var guide_color: Color = guide_colors[strand]
		guide_color.a = lerpf(0.34, 0.52, pulse) if not is_locked else lerpf(0.58, 0.8, pulse)
		var guide_offset := (float(strand) - 1.0) * (2.2 if is_locked else 4.5)
		var guide_amplitude := (2.0 if is_locked else 5.5) + float(strand) * 0.65
		var guide_points := _build_wave_points(
			guide_offset,
			guide_amplitude,
			1.15 + float(strand) * 0.14
		)
		draw_polyline(guide_points, guide_color, lerpf(1.3, 2.3, pulse) if not is_locked else lerpf(2.1, 3.4, pulse), true)
	if is_locked:
		var lock_spine := _build_wave_points(0.0, 1.2, 1.0)
		draw_polyline(lock_spine, lock_color, lerpf(2.2, 4.0, pulse), true)
	_draw_traveling_knots(0.26 if not is_locked else 0.52, 2.0 if not is_locked else 3.2)
	_draw_muzzle_flare(lerpf(0.55, 0.9, pulse), lock_color if is_locked else tracking_color)

func _draw_animated_beam() -> void:
	var pulse := 0.5 + sin(_animation_time * animation_speed) * 0.5
	var spine := _build_wave_points(0.0, wave_amplitude * 0.2, 1.0)
	var echo_spine := _build_wave_points(0.0, wave_amplitude * 0.34, 0.82)
	draw_polyline(echo_spine, Color(0.16, 0.08, 0.28, 0.14), beam_width * lerpf(2.4, 2.85, pulse), true)
	draw_polyline(spine, glow_color, beam_width * lerpf(2.0, 2.4, pulse), true)
	draw_polyline(spine, Color(0.018, 0.012, 0.035, 0.98), beam_width * lerpf(1.12, 1.24, pulse), true)

	var filament_colors := [POWER_RED, BALANCE_BLUE, ESSENCE_YELLOW]
	for strand in range(3):
		var offset := (float(strand) - 1.0) * beam_width * 0.3
		var strand_points := _build_wave_points(
			offset,
			wave_amplitude * (0.5 + float(strand) * 0.11),
			1.45 + float(strand) * 0.27
		)
		var shadow_points := _build_wave_points(
			offset + 2.0,
			wave_amplitude * (0.5 + float(strand) * 0.11),
			1.45 + float(strand) * 0.27
		)
		draw_polyline(shadow_points, Color(0.01, 0.012, 0.026, 0.72), lerpf(8.0, 11.0, pulse), true)
		draw_polyline(strand_points, filament_colors[strand], lerpf(5.0, 8.0, pulse), true)

	draw_polyline(spine, Color(1.0, 0.82, 0.62, 0.48), beam_width * lerpf(0.52, 0.64, pulse), true)
	draw_polyline(spine, core_color, beam_width * lerpf(0.32, 0.42, pulse), true)
	_draw_traveling_knots(0.9, lerpf(4.0, 6.0, pulse))

	_draw_muzzle_flare(1.0 + pulse * 0.28, core_color)
	_draw_impact_flare(pulse)


func _draw_traveling_knots(alpha: float, radius: float) -> void:
	var knot_spacing := maxf(90.0, segment_length * 2.6)
	var travel := fmod(_animation_time * 320.0, knot_spacing)
	var knot_index := 0
	var cursor := travel
	while cursor < _beam_length:
		var color: Color = [POWER_RED, BALANCE_BLUE, ESSENCE_YELLOW][knot_index % 3]
		color.a = alpha
		var y := sin(cursor * 0.026 - _animation_time * animation_speed) * wave_amplitude * 0.34
		draw_circle(Vector2(cursor, y), radius * 1.8, Color(color.r, color.g, color.b, alpha * 0.15))
		draw_circle(Vector2(cursor, y), radius, color)
		cursor += knot_spacing
		knot_index += 1

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
	for ray in range(15):
		var angle := float(ray) * TAU / 15.0 - _animation_time
		var direction := Vector2.from_angle(angle)
		var ray_length := radius * (1.3 + float(ray % 4) * 0.22)
		draw_line(end + direction * radius * 0.35, end + direction * ray_length, [POWER_RED, BALANCE_BLUE, ESSENCE_YELLOW][ray % 3], 2.5, true)
