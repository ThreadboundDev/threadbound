extends Node2D
## Preferred filled sweep, promoted from the isolated October 30 study.
## World-space blade samples; presentation only. Impacts require confirmed hits.
@export_range(1.0,1.35,0.01) var reach_extension := 1.14
@export_range(0.016,0.15,0.001) var trail_seconds := 0.075
@export var thread_color := Color("dabd82")
var samples: Array[Dictionary] = []
var age := 0.0
var contact_age := 1.0
var contact_position := Vector2.ZERO
var contact_direction := Vector2.RIGHT

func _ready() -> void:
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unlit
	z_index = 25

func advance(delta: float, emitting: bool, blade := PackedVector2Array()) -> void:
	age += delta
	contact_age += delta
	while not samples.is_empty() and age - float(samples[0].time) > trail_seconds:
		samples.pop_front()
	if emitting and blade.size() == 2:
		var hilt := blade[0]
		var axis := blade[1] - hilt
		if not samples.is_empty() and blade[1].distance_to(samples[-1].blade) > 180.0:
			samples.clear()
		# The bright leading edge still meets the weapon; the outer silhouette
		# extends its gesture without replacing the sword with a larger mesh.
		samples.append({"time":age, "inner":hilt+axis*0.28, "blade":blade[1], "outer":hilt+axis*reach_extension})
		while samples.size() > 32: samples.pop_front()
	queue_redraw()

func clear_trail() -> void:
	samples.clear()
	queue_redraw()

func impact(world_position: Vector2, direction := Vector2.RIGHT) -> void:
	contact_age = 0.0
	contact_position = world_position
	contact_direction = direction.normalized()
	queue_redraw()

func _draw() -> void:
	if samples.size() >= 2:
		var path := _smooth_samples()
		var edge := PackedVector2Array()
		for sample in path:
			edge.append(to_local(sample.outer))
		for i in range(1,path.size()):
			var a: Dictionary = path[i-1]
			var b: Dictionary = path[i]
			if a.outer.distance_to(b.outer) > 180.0: continue
			var life := clampf(1.0-(age-float(b.time))/trail_seconds,0.0,1.0)
			var polygon := PackedVector2Array([to_local(a.inner),to_local(a.outer),to_local(b.outer),to_local(b.inner)])
			_draw_strip_quad(polygon,Color(0.61,0.83,0.88,0.18+0.35*life))
			var cut_a: Vector2 = a.inner.lerp(a.outer,0.65)
			var cut_b: Vector2 = b.inner.lerp(b.outer,0.65)
			_draw_strip_quad(PackedVector2Array([to_local(cut_a),to_local(a.outer),to_local(b.outer),to_local(cut_b)]),Color(0.95,0.98,0.92,0.25+0.46*life))
		var fade := clampf(1.0-(age-float(samples[-1].time))/trail_seconds,0.0,1.0)
		draw_polyline(edge,Color(0.98,1.0,0.96,0.85*fade),2.6,true)
		# Sparse flax fibers give the effect a Threadbound accent.
		for fraction in [0.38,0.54]:
			var fiber := PackedVector2Array()
			for sample in path:
				fiber.append(to_local(sample.inner.lerp(sample.outer,fraction)))
			draw_polyline(fiber,Color(thread_color,0.58*fade),1.2,true)
		var last: Dictionary = samples[-1]
		draw_line(to_local(last.inner),to_local(last.blade),Color(1.0,1.0,0.97,0.9*fade),3.2,true)
	if contact_age < 0.13:
		var p := contact_age/0.13
		var center := to_local(contact_position)
		var axis := contact_direction
		var normal := axis.orthogonal()
		var fade := 1.0-p
		if p < 0.45:
			var size := lerpf(9.0,2.0,p/0.45)
			draw_colored_polygon(PackedVector2Array([center+axis*size*1.7,center+normal*size,center-axis*size,center-normal*size]),Color(1.0,0.99,0.91,fade))
		for i in 7:
			var ray := axis.rotated(float(i)*TAU/7.0+0.18)
			var start := center+ray*(5.0+p*16.0)
			var end := center+ray*(18.0+p*(24.0+float(i%3)*9.0))
			draw_line(start,end,Color(thread_color,fade),1.8*fade+0.5,true)

func _smooth_samples() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(samples.size()-1):
		var a: Dictionary = samples[maxi(0,i-1)]
		var b: Dictionary = samples[i]
		var c: Dictionary = samples[i+1]
		var d: Dictionary = samples[mini(samples.size()-1,i+2)]
		for j in 4:
			var t := float(j)/4.0
			var point := {"time":lerpf(b.time,c.time,t)}
			for key in ["inner","outer"]:
				var origin: Vector2 = b[key]
				point[key] = origin.cubic_interpolate(c[key],a[key],d[key],t)
			var life := clampf(1.0-(age-float(point.time))/trail_seconds,0.0,1.0)
			point.inner = point.outer.lerp(point.inner,pow(life,0.7))
			result.append(point)
	result.append(samples[-1])
	return result

func _draw_strip_quad(points: PackedVector2Array, color: Color) -> void:
	# A projected 3D sword can reverse across itself. Explicit triangles avoid
	# invalid bow-tie polygons; zero-area samples contribute no surface.
	for ids in [[0,1,2],[0,2,3]]:
		var a := points[ids[0]]
		var b := points[ids[1]]
		var c := points[ids[2]]
		if absf((b-a).cross(c-a)) > 0.05:
			draw_colored_polygon(PackedVector2Array([a,b,c]),color)
