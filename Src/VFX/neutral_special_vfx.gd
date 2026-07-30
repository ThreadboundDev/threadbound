class_name NeutralSpecialVFX
extends Node2D

const IVORY := Color(1.0, 0.96, 0.80)
const GOLD := Color(1.0, 0.69, 0.20)
const HOT_GOLD := Color(1.0, 0.88, 0.48)

@export_range(0.1, 2.0, 0.01) var impact_duration := 0.48

var _radius := 220.0
var _impact_delay := 0.245
var _charge_elapsed := 0.0
var _impact_elapsed := 0.0
var _facing := 1.0
var _has_played := false
var _impact_started := false

func _ready() -> void:
	z_index = 40
	queue_redraw()

func play(radius: float, impact_delay: float, facing: int = 1) -> void:
	_radius = maxf(32.0, radius)
	_impact_delay = maxf(0.01, impact_delay)
	_facing = -1.0 if facing < 0 else 1.0
	_charge_elapsed = 0.0
	_impact_elapsed = 0.0
	_has_played = true
	_impact_started = false
	queue_redraw()

func set_charge_position(world_position: Vector2) -> void:
	if _impact_started:
		return
	global_position = world_position

func trigger_impact(world_position: Vector2) -> void:
	if not _has_played or _impact_started:
		return
	global_position = world_position
	_impact_started = true
	_impact_elapsed = 0.0
	queue_redraw()

func cancel() -> void:
	queue_free()

func _process(delta: float) -> void:
	if not _has_played:
		return

	if _impact_started:
		_impact_elapsed += delta
		if _impact_elapsed >= impact_duration:
			queue_free()
	else:
		_charge_elapsed = minf(_charge_elapsed + delta, _impact_delay)
	queue_redraw()

func _draw() -> void:
	if not _has_played:
		return

	if _impact_started:
		_draw_impact()
	else:
		_draw_gather()

func _draw_gather() -> void:
	var gather := clampf(_charge_elapsed / _impact_delay, 0.0, 1.0)
	var eased_gather := ease(gather, 2.2)
	var pulse := 0.78 + sin(gather * TAU * 3.0) * 0.16
	var charge_radius := minf(86.0, _radius * 0.40)

	for index in range(14):
		var weight := float(index) / 14.0
		var angle := weight * TAU + gather * 0.48 * _facing
		var direction := Vector2.from_angle(angle)
		var tangent := direction.orthogonal() * _facing
		var outer_radius := charge_radius * (1.18 - eased_gather * 0.78)
		var strand_length := lerpf(24.0, 10.0, gather)
		var strand_center := direction * outer_radius + tangent * sin(index * 2.1) * 7.0
		var strand_start := strand_center + direction * strand_length
		var strand_end := strand_center - direction * strand_length * 0.45
		var strand_color := IVORY.lerp(GOLD, fmod(float(index), 3.0) / 2.0)
		strand_color.a = (0.20 + gather * 0.62) * pulse
		draw_line(
			strand_start,
			strand_end,
			strand_color,
			lerpf(1.5, 3.5, gather),
			true
		)

	var gather_ring_color := HOT_GOLD
	gather_ring_color.a = 0.18 + gather * 0.52
	draw_arc(
		Vector2.ZERO,
		lerpf(charge_radius * 0.72, charge_radius * 0.20, eased_gather),
		0.0,
		TAU,
		48,
		gather_ring_color,
		lerpf(2.0, 5.0, gather),
		true
	)

	var core_color := IVORY
	core_color.a = 0.16 + gather * 0.52
	draw_circle(Vector2.ZERO, lerpf(5.0, 14.0, gather), core_color, true, -1.0, true)

func _draw_impact() -> void:
	var impact_age := _impact_elapsed
	var impact := clampf(impact_age / impact_duration, 0.0, 1.0)
	var fade := pow(1.0 - impact, 1.7)
	var primary_radius := lerpf(_radius * 0.08, _radius * 1.04, ease(impact, -1.8))

	var flash_color := IVORY
	flash_color.a = maxf(0.0, 0.72 - impact_age * 5.8)
	draw_circle(
		Vector2.ZERO,
		lerpf(26.0, _radius * 0.36, minf(impact * 2.4, 1.0)),
		flash_color,
		true,
		-1.0,
		true
	)

	var primary_color := HOT_GOLD
	primary_color.a = fade * 0.95
	draw_arc(
		Vector2.ZERO,
		primary_radius,
		0.0,
		TAU,
		64,
		primary_color,
		lerpf(9.0, 2.0, impact),
		true
	)

	var secondary_impact := clampf((impact_age - 0.045) / maxf(0.01, impact_duration - 0.045), 0.0, 1.0)
	var secondary_color := IVORY
	secondary_color.a = pow(1.0 - secondary_impact, 2.0) * 0.72
	draw_arc(
		Vector2.ZERO,
		lerpf(_radius * 0.04, _radius * 0.86, ease(secondary_impact, -1.4)),
		0.0,
		TAU,
		64,
		secondary_color,
		lerpf(5.0, 1.5, secondary_impact),
		true
	)

	for index in range(18):
		var weight := float(index) / 18.0
		var angle := weight * TAU + 0.12 * _facing
		var direction := Vector2.from_angle(angle)
		var distance := lerpf(_radius * 0.18, _radius * 1.12, ease(impact, -1.5))
		var fragment_position := direction * distance
		var fragment_length := lerpf(30.0, 8.0, impact)
		var fragment_color := GOLD if index % 2 == 0 else IVORY
		fragment_color.a = fade * (0.52 + 0.30 * sin(float(index) * 1.7))
		draw_line(
			fragment_position - direction * fragment_length,
			fragment_position,
			fragment_color,
			lerpf(4.5, 1.0, impact),
			true
		)
