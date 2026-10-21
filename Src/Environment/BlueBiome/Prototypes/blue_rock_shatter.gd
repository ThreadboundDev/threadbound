extends Node2D
## Non-colliding painted shards live independently after the wall is removed.

var pieces: Array[Dictionary] = []
var _texture: Texture2D
var _color: Color
var _elapsed := 0.0
var _duration := 1.8
var _gravity := Vector2(0, 100)

func configure(cells: Array[PackedVector2Array], size: Vector2, texture: Texture2D, color: Color, impact: Vector2, duration: float, seed_value: int) -> void:
	_texture = texture
	_color = color
	_duration = duration
	_gravity = global_transform.basis_xform_inv(Vector2(0, 100))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for cell: PackedVector2Array in cells:
		var center := Vector2.ZERO
		for point: Vector2 in cell:
			center += point
		center /= cell.size()
		var polygon := PackedVector2Array()
		var uv := PackedVector2Array()
		for point: Vector2 in cell:
			polygon.append(point - center)
			uv.append(point / size + Vector2.ONE * 0.5)
		pieces.append({"polygon": polygon, "uv": uv, "origin": center,
			"velocity": center.normalized() * rng.randf_range(55, 135) + impact * rng.randf_range(40, 110),
			"spin": rng.randf_range(-1.6, 1.6), "life": duration * rng.randf_range(0.78, 1.0)})
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	if not _texture:
		return
	for piece: Dictionary in pieces:
		var alpha := 1.0 - smoothstep(piece.life * 0.48, piece.life, _elapsed)
		if alpha <= 0.0:
			continue
		var at: Vector2 = piece.origin + piece.velocity * _elapsed + _gravity * _elapsed * _elapsed * 0.5
		draw_set_transform(at, piece.spin * _elapsed, Vector2.ONE * lerpf(1.0, 0.75, _elapsed / _duration))
		var tint := Color.WHITE.lerp(Color(0.63, 0.86, 1.0), maxf(0.0, 1.0 - _elapsed / 0.22) * 0.5)
		tint.a = alpha
		draw_polygon(piece.polygon, PackedColorArray([tint]), piece.uv, _texture)
	draw_set_transform(Vector2.ZERO)
	# Short-lived glints fade before the larger chunks dissolve.
	for index in 18:
		var angle := index * 2.39996
		var travel := _elapsed * (65.0 + index * 6.0)
		var tint := _color.lerp(Color.WHITE, 0.3)
		tint.a = maxf(0, 1.0 - _elapsed / 0.75)
		draw_circle(Vector2.from_angle(angle) * travel, 1.5 + index % 3, tint)
