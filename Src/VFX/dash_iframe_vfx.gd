class_name DashIframeVFX
extends Node2D

const IVORY := Color(1.0, 0.97, 0.84)
const THREAD_GOLD := Color(1.0, 0.70, 0.22)
const PALE_GOLD := Color(1.0, 0.86, 0.52)

@export_range(0.01, 1.0, 0.01) var fade_in_time := 0.045
@export_range(0.01, 1.0, 0.01) var fade_out_time := 0.08
@export_range(8.0, 160.0, 1.0) var shell_radius := 58.0

var _direction := Vector2.RIGHT
var _duration := 0.29
var _elapsed := 0.0
var _playing := false

func _ready() -> void:
	z_index = 55
	visible = false
	set_process(false)

func play(direction: Vector2, duration: float) -> void:
	_direction = direction.normalized()
	if _direction.length_squared() <= 0.001:
		_direction = Vector2.RIGHT
	_duration = maxf(0.01, duration)
	_elapsed = 0.0
	_playing = true
	rotation = _direction.angle()
	visible = true
	set_process(true)
	queue_redraw()

func cancel() -> void:
	_playing = false
	queue_free()

func is_playing() -> bool:
	return _playing

func get_dash_direction() -> Vector2:
	return _direction

func get_remaining_time() -> float:
	return maxf(0.0, _duration - _elapsed)

func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed += delta
	if _elapsed >= _duration:
		_playing = false
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if not _playing:
		return

	var progress := clampf(_elapsed / maxf(_duration, 0.001), 0.0, 1.0)
	var fade_in := clampf(_elapsed / maxf(fade_in_time, 0.001), 0.0, 1.0)
	var fade_out := clampf((_duration - _elapsed) / maxf(fade_out_time, 0.001), 0.0, 1.0)
	var alpha := minf(fade_in, fade_out)
	var pulse := 0.88 + sin(progress * TAU * 3.0) * 0.12

	for layer in range(3):
		var layer_weight := float(layer) / 2.0
		var shell_color := PALE_GOLD.lerp(IVORY, layer_weight)
		shell_color.a = alpha * lerpf(0.44, 0.18, layer_weight)
		var shell_scale := Vector2(
			1.0 + layer_weight * 0.18 + progress * 0.08,
			0.68 + layer_weight * 0.08
		)
		draw_set_transform(Vector2(-6.0 - layer * 5.0, 0.0), 0.0, shell_scale)
		draw_arc(
			Vector2.ZERO,
			shell_radius * pulse,
			-PI * 0.82,
			PI * 0.82,
			34,
			shell_color,
			lerpf(4.0, 1.5, layer_weight),
			true
		)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for strand_index in range(7):
		var strand_weight := float(strand_index) / 6.0
		var y_offset := lerpf(-34.0, 34.0, strand_weight)
		var flutter := sin(progress * TAU * 2.0 + strand_index * 1.7) * 5.0
		var strand_start := Vector2(-82.0 - strand_index * 7.0, y_offset + flutter)
		var strand_end := Vector2(20.0 + strand_index * 2.0, y_offset * 0.55)
		var strand_color := THREAD_GOLD.lerp(IVORY, fmod(float(strand_index), 3.0) * 0.35)
		strand_color.a = alpha * lerpf(0.18, 0.48, 1.0 - absf(strand_weight - 0.5) * 2.0)
		draw_line(
			strand_start,
			strand_end,
			strand_color,
			lerpf(1.0, 2.6, 1.0 - absf(strand_weight - 0.5) * 2.0),
			true
		)

	var core_color := IVORY
	core_color.a = alpha * 0.16
	draw_circle(Vector2(-4.0, 0.0), shell_radius * 0.52, core_color, true, -1.0, true)
