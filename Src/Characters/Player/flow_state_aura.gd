extends Node2D

class FlowAuraLayer:
	extends Node2D

	var source: Node = null
	var layer_id := &"front"

	func _draw() -> void:
		if source and source.has_method("_draw_flow_layer"):
			source._draw_flow_layer(self, layer_id)

@export var active := false:
	set(value):
		var was_active := active
		active = value
		_target_visibility = 1.0 if active else 0.0
		if active:
			visible = true
			set_process(true)
			if not was_active:
				_pulse_age = 0.0

@export_group("Fade")
@export var fade_in_speed := 5.0
@export var fade_out_speed := 4.0

@export_group("Color")
@export var aura_color := Color(0.35, 0.92, 1.0, 0.34)
@export var core_color := Color(1.0, 0.96, 0.64, 0.52)
@export var white_thread_color := Color(0.92, 1.0, 1.0, 0.44)
@export var smoke_color := Color(0.78, 0.94, 1.0, 0.18)

@export_group("Shape")
@export var body_height := 148.0
@export var body_width := 86.0
@export var ground_y := 36.0
@export var aura_ring_radius := Vector2(58.0, 88.0)
@export var aura_ring_width := 2.8
@export var aura_ring_lines := 5

@export_group("Ribbons")
@export var front_layer_z_index := 14
@export var ribbon_count := 8
@export var ribbon_width := 3.8
@export var ribbon_alpha := 0.34
@export var ribbon_drift_strength := 14.0

@export_group("Particles")
@export var spark_count := 18
@export var dust_count := 22
@export var fragment_count := 8
@export var particle_radius := Vector2(64.0, 112.0)

@export_group("Motion")
@export var speed_trail_min_speed := 230.0
@export var speed_trail_length := 82.0
@export var speed_trail_lines := 4
@export var ground_wisp_min_speed := 80.0
@export var ground_wisp_interval := 0.16
@export var ground_wisp_lifetime := 0.55

@export_group("Pulse Burst")
@export var pulse_duration := 0.42
@export var pulse_radius := 118.0
@export var pulse_lines := 22

var _time := 0.0
var _visibility_amount := 0.0
var _target_visibility := 0.0
var _pulse_age := 999.0
var _front_layer: FlowAuraLayer
var _particles: Array[Dictionary] = []
var _wisps: Array[Dictionary] = []
var _wisp_timer := 0.0

func _ready() -> void:
	_ensure_front_layer()
	_seed_particles()
	_target_visibility = 1.0 if active else 0.0
	_visibility_amount = _target_visibility
	visible = _visibility_amount > 0.01
	set_process(visible)

func set_flow_active(is_active: bool) -> void:
	active = is_active

func _process(delta: float) -> void:
	_time += delta
	_pulse_age += delta
	var speed := fade_in_speed if active else fade_out_speed
	_visibility_amount = move_toward(_visibility_amount, _target_visibility, speed * delta)
	visible = _visibility_amount > 0.01

	if visible:
		_update_ground_wisps(delta)
		queue_redraw()
		if _front_layer:
			_front_layer.queue_redraw()
	elif not active:
		set_process(false)

func _draw() -> void:
	if _visibility_amount <= 0.01:
		return

	_draw_ground_glow(self)
	_draw_aura_ring(self)
	_draw_orbit_particles(self)
	_draw_pulse_burst(self)

func _draw_flow_layer(layer: Node2D, layer_id: StringName) -> void:
	if layer_id != &"front" or _visibility_amount <= 0.01:
		return

	_draw_energy_ribbons(layer)
	_draw_speed_trail(layer)
	_draw_ground_wisps(layer)

func _ensure_front_layer() -> void:
	if _front_layer:
		return

	_front_layer = FlowAuraLayer.new()
	_front_layer.name = "FrontEnergyLayer"
	_front_layer.source = self
	_front_layer.layer_id = &"front"
	_front_layer.z_index = front_layer_z_index
	add_child(_front_layer)

func _seed_particles() -> void:
	_particles.clear()
	for i in spark_count + dust_count + fragment_count:
		var kind := &"spark"
		if i >= spark_count + dust_count:
			kind = &"fragment"
		elif i >= spark_count:
			kind = &"dust"

		_particles.append({
			"kind": kind,
			"phase": randf() * TAU,
			"speed": randf_range(0.55, 1.8),
			"radius": Vector2(randf_range(particle_radius.x * 0.42, particle_radius.x), randf_range(particle_radius.y * 0.45, particle_radius.y)),
			"offset": randf_range(-18.0, 18.0),
			"size": randf_range(1.0, 4.6),
		})

func _update_ground_wisps(delta: float) -> void:
	var speed := _get_parent_speed()
	_wisp_timer -= delta
	if active and speed >= ground_wisp_min_speed and _wisp_timer <= 0.0:
		_wisp_timer = ground_wisp_interval
		_wisps.append({
			"age": 0.0,
			"x": randf_range(-body_width * 0.42, body_width * 0.42),
			"side": -signf(_get_parent_velocity().x) if absf(_get_parent_velocity().x) > 1.0 else randf_range(-1.0, 1.0),
			"height": randf_range(22.0, 42.0),
			"width": randf_range(7.0, 16.0),
		})

	for i in range(_wisps.size() - 1, -1, -1):
		_wisps[i]["age"] = float(_wisps[i].get("age", 0.0)) + delta
		if float(_wisps[i].get("age", 0.0)) >= ground_wisp_lifetime:
			_wisps.remove_at(i)

func _draw_ground_glow(canvas: CanvasItem) -> void:
	var pulse := 0.5 + sin(_time * 2.2) * 0.5
	var alpha := _visibility_amount * (0.16 + pulse * 0.14)
	_draw_ellipse(canvas, Vector2(0.0, ground_y), Vector2(body_width * 1.1, 18.0), Color(aura_color.r, aura_color.g, aura_color.b, alpha))
	_draw_ellipse(canvas, Vector2(0.0, ground_y - 3.0), Vector2(body_width * 0.62, 8.0), Color(core_color.r, core_color.g, core_color.b, alpha * 1.25))

func _draw_aura_ring(canvas: CanvasItem) -> void:
	for i in aura_ring_lines:
		var phase := _time * (1.1 + float(i) * 0.17) + float(i) * 1.7
		var points := _make_jittered_ellipse_points(
			Vector2(0.0, ground_y - body_height * 0.52),
			aura_ring_radius + Vector2(sin(phase) * 2.5, cos(phase * 0.8) * 3.0),
			48,
			phase,
			5.0 + float(i) * 0.9
		)
		var color := aura_color.lerp(white_thread_color, 0.28 + float(i) * 0.08)
		color.a = _visibility_amount * (0.08 + 0.035 * float(i))
		canvas.draw_polyline(points, color, aura_ring_width, true)

func _draw_orbit_particles(canvas: CanvasItem) -> void:
	for particle in _particles:
		var kind: StringName = particle.get("kind", &"dust")
		var phase := float(particle.get("phase", 0.0)) + _time * float(particle.get("speed", 1.0))
		var radius: Vector2 = particle.get("radius", particle_radius)
		var pos := Vector2(cos(phase) * radius.x, ground_y - body_height * 0.5 + sin(phase * 1.37) * radius.y + float(particle.get("offset", 0.0)))
		var size := float(particle.get("size", 2.0))
		var alpha := _visibility_amount

		if kind == &"spark":
			_draw_spark(canvas, pos, size * 1.35, Color(white_thread_color.r, white_thread_color.g, white_thread_color.b, alpha * 0.48))
		elif kind == &"fragment":
			_draw_fragment(canvas, pos, size, Color(core_color.r, core_color.g, core_color.b, alpha * 0.38), phase)
		else:
			canvas.draw_circle(pos, size, Color(smoke_color.r, smoke_color.g, smoke_color.b, alpha * 0.5))

func _draw_energy_ribbons(canvas: CanvasItem) -> void:
	var count := maxi(ribbon_count, 1)
	for i in count:
		var ratio := 0.0 if count == 1 else float(i) / float(count - 1)
		var x_base := lerpf(-body_width * 0.56, body_width * 0.56, ratio)
		var phase := _time * (2.2 + ratio * 1.15) + ratio * TAU
		var points := PackedVector2Array()
		var segments := 14
		for segment in segments + 1:
			var t := float(segment) / float(segments)
			var y := lerpf(ground_y + 2.0, ground_y - body_height, t)
			var taper := sin(t * PI)
			var drift := sin(phase + t * TAU * 1.65) * ribbon_drift_strength * taper
			var cross := cos(phase * 0.7 + t * TAU * 2.0) * ribbon_drift_strength * 0.34 * taper
			points.append(Vector2(x_base + drift + cross, y))

		var color := aura_color.lerp(white_thread_color, 0.45 + ratio * 0.24)
		color.a = _visibility_amount * ribbon_alpha * (0.68 + 0.32 * sin(phase))
		canvas.draw_polyline(points, color, ribbon_width * (0.55 + ratio * 0.45), true)

func _draw_speed_trail(canvas: CanvasItem) -> void:
	var velocity := _get_parent_velocity()
	var speed := velocity.length()
	if speed < speed_trail_min_speed:
		return

	var direction := -velocity.normalized()
	var strength := _visibility_amount * clampf((speed - speed_trail_min_speed) / 420.0, 0.0, 1.0)
	for i in speed_trail_lines:
		var vertical := lerpf(-body_height * 0.64, -body_height * 0.12, float(i) / maxf(1.0, speed_trail_lines - 1.0))
		var start := Vector2(0.0, ground_y + vertical)
		var end := start + direction * (speed_trail_length * (0.75 + float(i) * 0.18))
		var color := white_thread_color.lerp(aura_color, 0.35)
		color.a = strength * (0.22 - float(i) * 0.03)
		canvas.draw_line(start, end, color, 2.0 + float(i) * 0.4, true)
		canvas.draw_line(start + Vector2(0.0, 5.0), end + Vector2(randf_range(-5.0, 5.0), 5.0), Color(core_color.r, core_color.g, core_color.b, color.a * 0.65), 1.2, true)

func _draw_ground_wisps(canvas: CanvasItem) -> void:
	for wisp in _wisps:
		var age := float(wisp.get("age", 0.0))
		var t := clampf(age / maxf(ground_wisp_lifetime, 0.001), 0.0, 1.0)
		var alpha := _visibility_amount * (1.0 - t) * 0.42
		var x := float(wisp.get("x", 0.0)) + float(wisp.get("side", 1.0)) * t * 18.0
		var height := float(wisp.get("height", 30.0))
		var width := float(wisp.get("width", 10.0))
		var points := PackedVector2Array()
		for i in 6:
			var r := float(i) / 5.0
			points.append(Vector2(x + sin(r * TAU + _time * 3.0) * width * (1.0 - r), ground_y - r * height))
		canvas.draw_polyline(points, Color(white_thread_color.r, white_thread_color.g, white_thread_color.b, alpha), 2.0, true)

func _draw_pulse_burst(canvas: CanvasItem) -> void:
	if _pulse_age > pulse_duration:
		return

	var t := clampf(_pulse_age / maxf(pulse_duration, 0.001), 0.0, 1.0)
	var alpha := _visibility_amount * (1.0 - t) * 0.72
	var radius := lerpf(18.0, pulse_radius, t)
	var center := Vector2(0.0, ground_y - body_height * 0.5)
	for i in pulse_lines:
		var angle := TAU * float(i) / float(pulse_lines)
		var inner := center + Vector2(cos(angle), sin(angle)) * radius * 0.45
		var outer := center + Vector2(cos(angle), sin(angle)) * radius
		canvas.draw_line(inner, outer, Color(core_color.r, core_color.g, core_color.b, alpha), 2.0, true)

func _draw_spark(canvas: CanvasItem, position: Vector2, size: float, color: Color) -> void:
	canvas.draw_line(position + Vector2(-size, 0.0), position + Vector2(size, 0.0), color, 1.3, true)
	canvas.draw_line(position + Vector2(0.0, -size), position + Vector2(0.0, size), color, 1.3, true)
	canvas.draw_circle(position, size * 0.18, color)

func _draw_fragment(canvas: CanvasItem, position: Vector2, size: float, color: Color, rotation: float) -> void:
	var points := PackedVector2Array([
		position + Vector2(size, 0.0).rotated(rotation),
		position + Vector2(0.0, size * 0.55).rotated(rotation),
		position + Vector2(-size, 0.0).rotated(rotation),
		position + Vector2(0.0, -size * 0.55).rotated(rotation),
	])
	canvas.draw_colored_polygon(points, color)

func _make_jittered_ellipse_points(center: Vector2, radius: Vector2, segments: int, phase: float, jitter: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments + 1:
		var angle := TAU * float(i) / float(segments)
		var wobble := sin(angle * 5.0 + phase) * jitter + cos(angle * 3.0 - phase * 0.8) * jitter * 0.45
		points.append(center + Vector2(cos(angle) * (radius.x + wobble), sin(angle) * (radius.y + wobble)))
	return points

func _draw_ellipse(canvas: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var segments := 44
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		colors.append(color)
	canvas.draw_polygon(points, colors)

func _get_parent_velocity() -> Vector2:
	var character_body := get_parent() as CharacterBody2D
	return character_body.velocity if character_body else Vector2.ZERO

func _get_parent_speed() -> float:
	return _get_parent_velocity().length()
