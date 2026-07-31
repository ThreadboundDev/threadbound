class_name GrappleStrikeVFX
extends Node2D

const IVORY := Color(1.0, 0.97, 0.84)
const GOLD := Color(1.0, 0.72, 0.24)

@export_range(0.05, 0.5, 0.01) var lifetime := 0.20
@export_range(0.4, 1.0, 0.01) var visual_scale := 0.72

var _elapsed := 0.0
var _direction := Vector2.RIGHT
var _playing := false

func _ready() -> void:
	z_index = 82
	queue_redraw()

func play(direction: Vector2) -> void:
	_direction = direction.normalized()
	if _direction.length_squared() <= 0.001:
		_direction = Vector2.RIGHT
	_elapsed = 0.0
	_playing = true
	rotation = _direction.angle()
	scale = Vector2.ONE * visual_scale
	queue_redraw()

func _process(delta: float) -> void:
	if not _playing:
		return

	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if not _playing:
		return

	var progress := clampf(_elapsed / maxf(lifetime, 0.01), 0.0, 1.0)
	var fade := pow(1.0 - progress, 1.7)
	var flare_length := lerpf(18.0, 58.0, ease(progress, -1.8))
	var core := IVORY
	core.a = fade * 0.92
	var accent := GOLD
	accent.a = fade * 0.78

	draw_circle(Vector2.ZERO, lerpf(12.0, 3.0, progress), core, true, -1.0, true)
	draw_arc(
		Vector2.ZERO,
		lerpf(10.0, 34.0, progress),
		-0.92,
		0.92,
		24,
		accent,
		lerpf(5.0, 1.0, progress),
		true
	)

	for index in range(7):
		var offset := (float(index) - 3.0) * 5.5
		var strand_start := Vector2(-flare_length * 0.48, offset * 0.34)
		var strand_end := Vector2(flare_length, offset)
		var strand_color := IVORY if index % 2 == 0 else GOLD
		strand_color.a = fade * (0.76 - absf(offset) * 0.018)
		draw_line(
			strand_start,
			strand_end,
			strand_color,
			lerpf(3.4, 0.8, progress),
			true
		)
