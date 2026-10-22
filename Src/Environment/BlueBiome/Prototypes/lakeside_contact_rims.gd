@tool
extends Node2D
## Textured front contact strips. Reads collision; never moves or adds physics.
@export var collision_path := NodePath("../../RockCollision")
@export_range(0.0, 12.0) var outside_width := 3.0
@export_range(0.0, 64.0) var inside_width := 24.0
var edge_count := 0
var triangle_count := 0
var _signature := 0
var _timer := 0.0

func _ready() -> void:
	z_as_relative = false
	z_index = 3
	call_deferred("rebuild")
	set_process(Engine.is_editor_hint())

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= .5:
		_timer = 0.0
		rebuild()

func solid(point: Vector2, polygons: Array[PackedVector2Array]) -> bool:
	for polygon in polygons:
		if Geometry2D.is_point_in_polygon(point, polygon):
			return true
	return false

func rebuild() -> void:
	var collision := get_node_or_null(collision_path)
	var artwork := get_parent().get_node_or_null("rear_cave")
	if collision == null or artwork == null:
		return
	var polygons: Array[PackedVector2Array] = []
	for node: CollisionPolygon2D in collision.find_children("*", "CollisionPolygon2D", true, false):
		if node.disabled:
			continue
		var world := PackedVector2Array()
		for point in node.polygon:
			world.append(node.to_global(point))
		polygons.append(world)
	var signature := hash([polygons, outside_width, inside_width])
	if signature == _signature:
		return
	_signature = signature
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var strips: Array[PackedVector2Array] = []
	edge_count = 0
	triangle_count = 0
	for polygon in polygons:
		var area := 0.0
		for i in polygon.size():
			area += polygon[i].cross(polygon[(i+1)%polygon.size()])
		for i in polygon.size():
			var a := polygon[i]
			var b := polygon[(i+1)%polygon.size()]
			if a.distance_to(b) < 1.0:
				continue
			var along := (b-a).normalized()
			var normal := Vector2(along.y,-along.x) if area > 0 else Vector2(-along.y,along.x)
			# Feet overlap only floor-facing lips; side/ceiling strips can slice
			# through the visible leg when unrelated back-wall contours overlap.
			if normal.y > -.65:
				continue
			# Reject seams between collision chunks and contours buried in another
			# solid mass. Subdivide long edges so partial seams do not grow caps.
			var divisions := maxi(1, ceili(a.distance_to(b)/24.0))
			for part in divisions:
				var start := a.lerp(b,float(part)/divisions)
				var end := a.lerp(b,float(part+1)/divisions)
				if solid(start.lerp(end,.5)+normal*2.0,polygons):
					continue
				strips.append(PackedVector2Array([start+normal*outside_width,end+normal*outside_width,end-normal*inside_width,start-normal*inside_width]))
				edge_count += 1
	for source: Sprite2D in artwork.get_children():
		if source.texture == null:
			continue
		var rect := source.get_rect()
		var clip := PackedVector2Array([source.to_global(rect.position),source.to_global(Vector2(rect.end.x,rect.position.y)),source.to_global(rect.end),source.to_global(Vector2(rect.position.x,rect.end.y))])
		var bounds := Rect2(clip[0],Vector2.ZERO)
		for point in clip:
			bounds = bounds.expand(point)
		var vertices := PackedVector3Array()
		var uv := PackedVector2Array()
		var indices := PackedInt32Array()
		for strip in strips:
			var strip_bounds := Rect2(strip[0],Vector2.ZERO)
			for point in strip:
				strip_bounds = strip_bounds.expand(point)
			if not bounds.intersects(strip_bounds):
				continue
			for piece in Geometry2D.intersect_polygons(strip,clip):
				var triangles := Geometry2D.triangulate_polygon(piece)
				var offset := vertices.size()
				for point in piece:
					var local := to_local(point)
					vertices.append(Vector3(local.x,local.y,0))
					uv.append((source.to_local(point)-rect.position)/source.texture.get_size())
				for index in triangles:
					indices.append(offset+index)
		if indices.is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_TEX_UV] = uv
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var rim := MeshInstance2D.new()
		rim.name = "Contact_"+source.name
		rim.mesh = mesh
		rim.texture = source.texture
		rim.texture_filter = source.texture_filter
		add_child(rim)
		triangle_count += indices.size()/3
