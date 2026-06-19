extends Node2D

@export var thread_width := 9.0
@export var glow_width := 52.0
@export var motion_speed := 1.15
@export var wiggle_strength := 28.0
@export var loom_origin := Vector2(0, 500)
@export var conduit_top := Vector2(0, -1560)

var _time := 0.0

func _process(delta: float) -> void:
	_time += delta * motion_speed
	queue_redraw()

func _draw() -> void:
	var specs := [
		{
			"color": Color(0.96, 0.18, 0.16, 1.0),
			"offset": -56.0,
			"phase": 0.0,
		},
		{
			"color": Color(1.0, 0.78, 0.22, 1.0),
			"offset": 0.0,
			"phase": 2.1,
		},
		{
			"color": Color(0.22, 0.62, 1.0, 1.0),
			"offset": 56.0,
			"phase": 4.2,
		},
	]

	for spec in specs:
		var points := _thread_points(float(spec["offset"]), float(spec["phase"]))
		var glow_color: Color = spec["color"] as Color
		glow_color.a = 0.12
		draw_polyline(points, glow_color, glow_width * 1.75, true)

	for spec in specs:
		var points := _thread_points(float(spec["offset"]), float(spec["phase"]))
		var glow_color: Color = spec["color"] as Color
		glow_color.a = 0.34
		draw_polyline(points, glow_color, glow_width, true)

	for spec in specs:
		var points := _thread_points(float(spec["offset"]), float(spec["phase"]))
		var mid_color: Color = spec["color"] as Color
		mid_color.a = 0.76
		draw_polyline(points, mid_color, thread_width * 1.8, true)

	for spec in specs:
		var points := _thread_points(float(spec["offset"]), float(spec["phase"]))
		draw_polyline(points, spec["color"] as Color, thread_width, true)

func _thread_points(offset: float, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 44
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var y: float = lerp(loom_origin.y, conduit_top.y, t)
		var base_x: float = lerp(loom_origin.x + offset * 0.18, conduit_top.x + offset, t)
		var twist: float = sin(t * TAU * 3.0 + _time + phase) * wiggle_strength * (0.25 + t * 0.75)
		var counter: float = sin(t * TAU * 7.0 - _time * 1.6 + phase) * wiggle_strength * 0.18
		points.append(Vector2(base_x + twist + counter, y))
	return points
