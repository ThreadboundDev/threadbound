extends Node2D

@export var active := false:
	set(value):
		active = value
		_target_visibility = 1.0 if active else 0.0
		if active:
			visible = true
			set_process(true)

@export var fade_in_speed := 5.0
@export var fade_out_speed := 4.0
@export var base_color := Color(0.35, 0.92, 1.0, 0.34)
@export var core_color := Color(1.0, 0.96, 0.64, 0.42)
@export var smoke_color := Color(0.78, 0.94, 1.0, 0.18)
@export var body_height := 136.0
@export var body_width := 76.0
@export var ground_y := 34.0
@export var ribbon_count := 7
@export var ribbon_width := 5.5
@export var pulse_speed := 2.2
@export var drift_strength := 11.0

var _time := 0.0
var _visibility_amount := 0.0
var _target_visibility := 0.0

func _ready() -> void:
	_target_visibility = 1.0 if active else 0.0
	_visibility_amount = _target_visibility
	visible = _visibility_amount > 0.01
	set_process(visible)

func set_flow_active(is_active: bool) -> void:
	active = is_active

func _process(delta: float) -> void:
	_time += delta
	var speed := fade_in_speed if active else fade_out_speed
	_visibility_amount = move_toward(_visibility_amount, _target_visibility, speed * delta)
	visible = _visibility_amount > 0.01
	queue_redraw()
	if not visible and not active:
		set_process(false)

func _draw() -> void:
	if _visibility_amount <= 0.01:
		return

	_draw_ground_glow()
	_draw_energy_ribbons()
	_draw_smoke_wisps()

func _draw_ground_glow() -> void:
	var pulse := 0.5 + sin(_time * pulse_speed) * 0.5
	var alpha := _visibility_amount * (0.18 + pulse * 0.12)
	_draw_ellipse(Vector2(0.0, ground_y), Vector2(body_width * 1.05, 17.0), Color(base_color.r, base_color.g, base_color.b, alpha))
	_draw_ellipse(Vector2(0.0, ground_y - 4.0), Vector2(body_width * 0.62, 9.0), Color(core_color.r, core_color.g, core_color.b, alpha * 0.9))

func _draw_energy_ribbons() -> void:
	var count := maxi(ribbon_count, 1)
	for i in count:
		var ratio := 0.0 if count == 1 else float(i) / float(count - 1)
		var x_base := lerpf(-body_width * 0.5, body_width * 0.5, ratio)
		var phase := _time * (1.9 + ratio * 0.9) + ratio * TAU
		var points := PackedVector2Array()
		var segments := 8
		for segment in segments + 1:
			var t := float(segment) / float(segments)
			var y := lerpf(ground_y, ground_y - body_height, t)
			var taper := 1.0 - t
			var drift := sin(phase + t * TAU * 1.45) * drift_strength * taper
			points.append(Vector2(x_base + drift, y))

		var ribbon_alpha := _visibility_amount * (0.18 + 0.11 * sin(phase))
		var ribbon_color := base_color.lerp(core_color, 0.38 + ratio * 0.24)
		ribbon_color.a = maxf(0.06, ribbon_alpha)
		draw_polyline(points, ribbon_color, ribbon_width * (0.55 + ratio * 0.45), true)

func _draw_smoke_wisps() -> void:
	for i in 5:
		var ratio := float(i) / 4.0
		var phase := _time * 1.25 + ratio * TAU
		var rise := fmod(_time * 22.0 + ratio * 70.0, body_height * 0.85)
		var x := sin(phase * 0.9) * body_width * (0.32 + ratio * 0.08)
		var y := ground_y - 10.0 - rise
		var radius := 7.0 + sin(phase) * 2.0
		var alpha := _visibility_amount * smoke_color.a * (1.0 - rise / (body_height * 0.85))
		draw_circle(Vector2(x, y), maxf(1.0, radius), Color(smoke_color.r, smoke_color.g, smoke_color.b, alpha))

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var segments := 36
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	draw_polygon(points, colors)
