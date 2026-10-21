@tool
extends "res://Src/Environment/Greybox/greybox_breakable_wall.gd"
## The map's original painted stone, split along shared fracture boundaries.
## Geometry is visual only; the inherited solid body controls traversal.

const SHATTER := preload("res://Src/Environment/BlueBiome/Prototypes/blue_rock_shatter.gd")
@export var stone_texture: Texture2D = preload("res://Assets/BlueBiome/Art/LakesideMap/quarry_block.png"):
	set(value):
		stone_texture = value
		_mesh_size = Vector2.ZERO
		queue_redraw()
@export var crack_color := Color(0.18, 0.68, 1.0)
@export_range(0, 3, 1) var preview_damage_stage := 0:
	set(value):
		preview_damage_stage = clampi(value, 0, 3)
		queue_redraw()
@export_range(0.6, 4.0, 0.05) var debris_lifetime := 1.8
@export var fracture_seed := 37

var _cells: Array[PackedVector2Array] = []
var _seams: Array[PackedVector2Array] = []
var _stone_alpha: Image
var _mesh_size := Vector2.ZERO
var _mesh_seed := -1
var _pulse := 0.0
var _impact_flash := 0.0
var _light: PointLight2D
var _crack_overlay: Node2D

func _ready() -> void:
	super._ready()
	_ensure_mesh()
	_build_crack_overlay()
	if not Engine.is_editor_hint():
		damaged.connect(_on_damaged)
		_build_light()
	set_process(not Engine.is_editor_hint())

func get_damage_stage() -> int:
	if Engine.is_editor_hint():
		return preview_damage_stage
	if hits_taken == 0:
		return 0
	return clampi(ceili(float(hits_taken) / maxi(1, hits_to_break - 1) * 3.0), 1, 3)

func _process(delta: float) -> void:
	_pulse += delta
	_impact_flash = move_toward(_impact_flash, 0.0, delta * 4.0)
	if _light:
		_light.energy = 0.04 + get_damage_stage() * 0.06 + _impact_flash * 0.25
	queue_redraw()

func _build_light() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_light = PointLight2D.new()
	_light.name = "CrackLight"
	_light.texture = texture
	_light.texture_scale = maxf(size.x, size.y) / 100.0
	_light.color = crack_color
	_light.energy = 0.04
	add_child(_light)

func _on_damaged(_hits: int, _required: int) -> void:
	_impact_flash = 1.0

func _build_crack_overlay() -> void:
	_crack_overlay = Node2D.new()
	_crack_overlay.name = "BlueCracks"
	# Stone receives the lake's tint at depth 12. Emissive cracks remain legible
	# above the water overlay, rather than bleaching the whole rock above it.
	_crack_overlay.z_as_relative = false
	_crack_overlay.z_index = 30
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_crack_overlay.material = unlit
	_crack_overlay.draw.connect(_draw_cracks)
	add_child(_crack_overlay)

func _draw() -> void:
	if _fractured or not stone_texture:
		return
	_ensure_mesh()
	var stage := get_damage_stage()
	var gap := [0.0, 0.45, 0.9, 1.6][stage] as float
	for cell: PackedVector2Array in _cells:
		var uv := PackedVector2Array()
		var center := Vector2.ZERO
		for point: Vector2 in cell:
			uv.append(point / size + Vector2.ONE * 0.5)
			center += point
		center /= cell.size()
		var shifted := PackedVector2Array()
		for point: Vector2 in cell:
			shifted.append(point + center.normalized() * gap)
		draw_polygon(shifted, PackedColorArray([Color.WHITE.lerp(Color(0.65, 0.85, 1.0), _impact_flash * 0.4)]), uv, stone_texture)
	if _crack_overlay:
		_crack_overlay.queue_redraw()

func _draw_cracks() -> void:
	if _fractured or _seams.is_empty():
		return
	var stage := get_damage_stage()
	var count := ceili(_seams.size() * [0.22, 0.48, 0.76, 1.0][stage])
	var width := [0.9, 1.5, 2.3, 3.3][stage] as float
	var brightness := [0.34, 0.48, 0.74, 1.0][stage] as float
	brightness *= 0.94 + sin(_pulse * 2.2) * 0.06
	for index in count:
		var seam := _seams[index]
		# Wide translucent bands give a soft halo without requiring global bloom.
		for halo in [7.0, 4.0, 2.0]:
			var glow := crack_color
			glow.a = brightness * 0.10
			_crack_overlay.draw_polyline(seam, glow, width * halo + 2.0, true)
		_crack_overlay.draw_polyline(seam, Color(0.065, 0.11, 0.15, 0.92), width + 2.0, true)
		var core := crack_color.lerp(Color(0.72, 0.95, 1.0), brightness * 0.65)
		core.a = brightness + _impact_flash * 0.2
		_crack_overlay.draw_polyline(seam, core, width, true)

func _ensure_mesh() -> void:
	if _mesh_size == size and _mesh_seed == fracture_seed:
		return
	_mesh_size = size
	_mesh_seed = fracture_seed
	_cells.clear()
	_seams.clear()
	_stone_alpha = stone_texture.get_image() if stone_texture else null
	if _stone_alpha and _stone_alpha.is_compressed():
		_stone_alpha.decompress()
	var rng := RandomNumberGenerator.new()
	rng.seed = fracture_seed
	var seeds: Array[Vector2] = []
	for row in 5:
		for column in 3:
			seeds.append(Vector2((column + rng.randf_range(0.18, 0.82)) / 3.0, (row + rng.randf_range(0.18, 0.82)) / 5.0) * size - size * 0.5)
	var seen: Dictionary = {}
	for origin: Vector2 in seeds:
		var cell := PackedVector2Array([-size * 0.5, Vector2(size.x, -size.y) * 0.5, size * 0.5, Vector2(-size.x, size.y) * 0.5])
		for other: Vector2 in seeds:
			if origin == other:
				continue
			cell = _clip_cell(cell, (origin + other) * 0.5, other - origin)
		_cells.append(cell)
		for index in cell.size():
			var a := cell[index]
			var b := cell[(index + 1) % cell.size()]
			if (is_equal_approx(absf(a.x), size.x * 0.5) and is_equal_approx(a.x, b.x)) or (is_equal_approx(absf(a.y), size.y * 0.5) and is_equal_approx(a.y, b.y)):
				continue
			var key_a := Vector2i((a * 100.0).round())
			var key_b := Vector2i((b * 100.0).round())
			var key := str(key_a) + ":" + str(key_b) if key_a < key_b else str(key_b) + ":" + str(key_a)
			if seen.has(key):
				continue
			seen[key] = true
			var seam := PackedVector2Array([a])
			var steps := maxi(3, ceili(a.distance_to(b) / 13.0))
			var normal := (b - a).orthogonal().normalized()
			for step in range(1, steps):
				seam.append(a.lerp(b, float(step) / steps) + normal * rng.randf_range(-2.4, 2.4))
			seam.append(b)
			# The source stamp has a transparent, chipped silhouette. Crack strokes
			# must stop at that silhouette rather than outlining the texture rectangle.
			_seams.append_array(_clip_stroke_to_stone(seam))
	# Sort spatially so the small starter fissure branches through the rock as it weakens.
	_seams.sort_custom(func(a: PackedVector2Array, b: PackedVector2Array): return a[0].distance_to(Vector2(-size.x * 0.12, size.y * 0.08)) < b[0].distance_to(Vector2(-size.x * 0.12, size.y * 0.08)))

func _clip_stroke_to_stone(stroke: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var run := PackedVector2Array()
	for index in range(stroke.size() - 1):
		var a := stroke[index]
		var b := stroke[index + 1]
		var steps := maxi(1, ceili(a.distance_to(b)))
		for step in steps + 1:
			var point := a.lerp(b, float(step) / steps)
			var uv := point / size + Vector2.ONE * 0.5
			var opaque := false
			if _stone_alpha and uv.x >= 0 and uv.x < 1 and uv.y >= 0 and uv.y < 1:
				opaque = _stone_alpha.get_pixel(int(uv.x * _stone_alpha.get_width()), int(uv.y * _stone_alpha.get_height())).a > 0.85
			if opaque:
				if run.is_empty() or run[-1].distance_to(point) > 0.25:
					run.append(point)
			elif not run.is_empty():
				if run.size() > 1:
					result.append(run)
				run = PackedVector2Array()
	if run.size() > 1:
		result.append(run)
	return result

func _clip_cell(points: PackedVector2Array, midpoint: Vector2, normal: Vector2) -> PackedVector2Array:
	var clipped := PackedVector2Array()
	for index in points.size():
		var a := points[index]
		var b := points[(index + 1) % points.size()]
		var da := (a - midpoint).dot(normal)
		var db := (b - midpoint).dot(normal)
		if da <= 0.0:
			clipped.append(a)
		if (da < 0.0 and db > 0.0) or (da > 0.0 and db < 0.0):
			clipped.append(a.lerp(b, da / (da - db)))
	return clipped

func _spawn_fracture_effect(source: Node) -> void:
	var effect := Node2D.new()
	effect.set_script(SHATTER)
	effect.name = "BlueRockShatter"
	get_parent().add_child(effect, true)
	effect.global_transform = global_transform
	effect.z_index = z_index
	var direction := Vector2.RIGHT
	if source is Node2D:
		direction = source.global_position.direction_to(global_position)
	effect.configure(_cells, size, stone_texture, crack_color, global_transform.basis_xform_inv(direction).normalized(), debris_lifetime, fracture_seed)
