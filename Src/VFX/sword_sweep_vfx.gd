class_name SwordSweepVFX
extends Node2D

## Thin silver strokes sampled from the visible blade, timed to the attack clip.
const SILVER := Color(0.82, 0.91, 0.97)
const TRAIL_PHASE_LENGTH := 0.48
var phase := -1.0
var radius := 195.0
var arc := deg_to_rad(90.0)
var reverse := false
var accents: Array[Color] = []
var stroke_style := 0
var _samples: Array[Dictionary] = []
var _ground_y := INF

func _ready() -> void:
	hide()

func set_sweep(progress: float, reach: float, degrees: float, pose: Transform2D,
	channels: Array[Color], reversed: bool = false,
	blade_world := PackedVector2Array(), style: int = 0) -> void:
	if progress < phase or style != stroke_style or progress < 0.0:
		_samples.clear()
	_ground_y = INF
	phase = progress
	radius = reach
	arc = deg_to_rad(degrees)
	reverse = reversed
	accents = channels.duplicate()
	stroke_style = clampi(style, 0, 4)
	var artwork_pose := pose
	if pose.x.x < 0.0:
		artwork_pose.y = -pose.y
	global_transform = artwork_pose
	visible = phase >= 0.0 and phase < (1.0 if stroke_style == 3 else 1.32)
	if visible and stroke_style != 3 and blade_world.size() == 2:
		# Store world positions so moving/turning the player cannot drag old trails.
		if _samples.is_empty() or phase > float(_samples[-1].phase) + 0.0001:
			_samples.append({"phase": phase, "hilt": blade_world[0], "tip": blade_world[1]})
		while not _samples.is_empty() and phase-float(_samples[0].phase) > (0.85 if stroke_style == 2 else TRAIL_PHASE_LENGTH):
			_samples.pop_front()
		while _samples.size() > 24:
			_samples.pop_front()
	queue_redraw()

func align_ground(world_y: float) -> void:
	if stroke_style == 2:
		_ground_y = world_y
		queue_redraw()

func clear() -> void:
	phase = -1.0
	_samples.clear()
	_ground_y = INF
	hide()
	queue_redraw()

func _draw() -> void:
	if phase < 0.0:
		return
	if stroke_style == 3:
		_draw_spin()
		return
	if _samples.is_empty() or phase >= 1.32:
		return
	var fade := (1.0-smoothstep(0.95, 1.32, phase))*smoothstep(0.0, 0.12, phase)
	# Three narrow, separated lines, matching the spin's restrained accents.
	for band in 3:
		var fraction := 0.68 + float(band)*0.15
		if stroke_style == 2:
			fraction += 0.08
		for i in range(1, _samples.size()):
			var a: Vector2 = _samples[i-1].hilt.lerp(_samples[i-1].tip, fraction)
			var b: Vector2 = _samples[i].hilt.lerp(_samples[i].tip, fraction)
			if a.distance_squared_to(b) < 0.16:
				continue
			var age := clampf(1.0-(phase-float(_samples[i].phase))/(0.85 if stroke_style == 2 else TRAIL_PHASE_LENGTH), 0.0, 1.0)
			var color := SILVER
			color.a = fade*age*(0.58-float(band)*0.12)
			draw_line(to_local(a), to_local(b), color, (2.2-float(band)*0.5)*(0.45+age*0.55)*(1.65 if stroke_style == 2 else 1.0), true)
	# A short blade glint keeps thrusts legible without inventing a curved slash.
	var last: Dictionary = _samples[-1]
	if stroke_style == 4:
		_draw_stab(last, fade)
	var glint := SILVER
	glint.a = fade*0.30
	draw_line(to_local(last.hilt.lerp(last.tip, 0.68)), to_local(last.tip), glint, 1.1, true)
	if is_finite(_ground_y) and phase > 0.35 and phase < 1.10:
		var contact := Vector2(last.tip.x, _ground_y)
		var contact_color := SILVER
		contact_color.a = fade*0.62
		for side in [-1.0, 1.0]:
			draw_line(to_local(contact+Vector2(side*3, 0)), to_local(contact+Vector2(side*27, -9)), contact_color, 1.2, true)


func _draw_spin() -> void:
	if phase > 1.0:
		return
	var direction := -1.0 if reverse else 1.0
	var fade := sin(phase * PI)
	for band in 3:
		var trail := PackedVector2Array()
		for i in 25:
			var angle := (phase*TAU - float(i)/24.0*PI*0.85)*direction
			trail.append(Vector2(cos(angle),sin(angle)*0.38)*(radius*(0.72+band*0.05)))
		draw_polyline(trail, Color(0.72,0.92,1.0,fade*(0.5-band*0.12)), 3.0-band*0.7, true)


func _draw_stab(blade: Dictionary, fade: float) -> void:
	var hilt: Vector2 = blade.hilt
	var tip: Vector2 = blade.tip
	var axis := (tip-hilt).normalized()
	var normal := axis.orthogonal()
	var length := hilt.distance_to(tip)
	# A blade silhouette, not a detached cone: parallel edges and a short point.
	var base := hilt.lerp(tip, 0.12)
	var end := hilt + axis*length*1.3
	var shoulder := hilt + axis*length*1.12
	var width := clampf(length*0.055*1.3, 3.0, 7.0)
	var polygon := PackedVector2Array([to_local(base+normal*width), to_local(shoulder+normal*width*0.65), to_local(end), to_local(shoulder-normal*width*0.65), to_local(base-normal*width)])
	var fill := SILVER
	fill.a = fade*0.16
	draw_colored_polygon(polygon, fill)
	polygon.append(polygon[0])
	var edge := SILVER
	edge.a = fade*0.68
	draw_polyline(polygon, edge, 1.5, true)
