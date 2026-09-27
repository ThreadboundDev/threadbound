@tool
class_name GreyboxPolygonWater2D
extends Area2D

@export var lake_presentation := false

@export var air_pocket := false:
	set(value):
		air_pocket = value
		if is_inside_tree():
			_sync_pocket_group()
		queue_redraw()
@export_range(0.0, 1.0) var underwater_opacity := 0.16
var _fill: Polygon2D
var _ripple_visual: Node2D
var _ripples: Array[Dictionary] = []
var _wake_timer := 0.0
var _reported_pocket_limit := false

@export var points := PackedVector2Array([
	Vector2(-512.0, -192.0),
	Vector2(512.0, -192.0),
	Vector2(512.0, 192.0),
	Vector2(-512.0, 192.0),
]):
	set(value):
		points = value
		_refresh()
@export var water_color := Color(0.08, 0.55, 0.98, 0.34):
	set(value):
		water_color = value
		queue_redraw()

@onready var collision: CollisionPolygon2D = $CollisionPolygon2D

var _last_collision_points := PackedVector2Array()


func _ready() -> void:
	_sync_pocket_group()
	_ripple_visual = Node2D.new()
	_ripple_visual.name = "WaterMovementRipples"
	# The water tint stays in front; contact rings render behind the player.
	_ripple_visual.z_as_relative = false
	_ripple_visual.z_index = -1
	add_child(_ripple_visual)
	_ripple_visual.draw.connect(_draw_movement_ripples)
	_fill = Polygon2D.new()
	_fill.name = "WaterPreviewFill"
	var fill_material := ShaderMaterial.new()
	fill_material.shader = load("res://Src/Environment/BlueBiome/Water/polygon_lake.gdshader" if lake_presentation else "res://Src/Environment/Greybox/greybox_lake_fill.gdshader")
	if lake_presentation and air_pocket:
		fill_material.shader = load("res://Src/Environment/BlueBiome/Water/air_pocket_caustics.gdshader")
		_fill.z_as_relative = false
		_fill.z_index = -2
	_fill.material = fill_material
	add_child(_fill)
	_refresh()
	set_process(true)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	_update_water_preview(_delta)
	if is_node_ready() and (
		collision.position != Vector2.ZERO
		or not is_zero_approx(collision.rotation)
		or collision.scale != Vector2.ONE
	):
		collision.position = Vector2.ZERO
		collision.rotation = 0.0
		collision.scale = Vector2.ONE
	if not is_node_ready() or collision.polygon == _last_collision_points:
		return
	points = collision.polygon.duplicate()


func _refresh() -> void:
	queue_redraw()
	update_configuration_warnings()
	if is_node_ready():
		if Engine.is_editor_hint():
			collision.self_modulate = Color(1,1,1,0)
		collision.polygon = points
		_last_collision_points = points.duplicate()


func _draw() -> void:
	if points.size() < 3:
		return
	if air_pocket and not lake_presentation:
		draw_colored_polygon(points, Color(0.60, 0.85, 0.45, 0.22) if Engine.is_editor_hint() else Color(0.85, 0.95, 0.85, 0.06))
	var outline := points.duplicate()
	outline.append(points[0])
	if not lake_presentation or Engine.is_editor_hint():
		draw_polyline(outline, Color(0.8, 0.95, 0.7, 0.8) if air_pocket else Color(0.45, 0.88, 1.0, 0.55), 2.0)
	if Engine.is_editor_hint():
		# Put the label inside a real triangle, not the bounding-box center of a
		# concave volume (which may be outside the water entirely).
		var triangles := Geometry2D.triangulate_polygon(points)
		if triangles.size() >= 3:
			var label_at := (points[triangles[0]] + points[triangles[1]] + points[triangles[2]]) / 3.0
			var label := "DRY AIR POCKET" if air_pocket else "SWIMMABLE WATER"
			label_at.x -= ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x * 0.5
			draw_string(ThemeDB.fallback_font, label_at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)


func _draw_movement_ripples() -> void:
	for ripple in _ripples:
		var age: float = ripple.age
		var radius := 7.0 + age * 55.0
		for segment in 32:
			var a: Vector2 = ripple.position + Vector2.from_angle(float(segment)/32.0*TAU)*radius
			var b: Vector2 = ripple.position + Vector2.from_angle(float(segment+1)/32.0*TAU)*radius
			if _is_visible_water(to_global(a)) and _is_visible_water(to_global(b)) and _is_visible_water(to_global(a.lerp(b, 0.5))):
				_ripple_visual.draw_line(a, b, Color(0.7,0.95,1,(1.0-age)*0.6), 1.5, true)


func _on_body_entered(body: Node2D) -> void:
	if air_pocket:
		return
	_ripples.append({"position": to_local(body.global_position), "age": 0.0})
	if body.has_method("enter_prototype_water"):
		body.call("enter_prototype_water", self, get_surface_global_y())


func _on_body_exited(body: Node2D) -> void:
	if air_pocket:
		return
	_ripples.append({"position": to_local(body.global_position), "age": 0.0})
	if body.has_method("exit_prototype_water"):
		body.call("exit_prototype_water", self)


func get_surface_global_y() -> float:
	if points.is_empty():
		return global_position.y
	var surface_y := INF
	for point in points:
		surface_y = minf(surface_y, to_global(point).y)
	return surface_y

func contains_global_point(point: Vector2) -> bool:
	return points.size() >= 3 and Geometry2D.is_point_in_polygon(to_local(point), points)

func _sync_pocket_group() -> void:
	if air_pocket:
		add_to_group("lake_air_pockets")
		remove_from_group("lake_water_volumes")
	else:
		remove_from_group("lake_air_pockets")
		add_to_group("lake_water_volumes")

func _update_water_preview(delta: float) -> void:
	if not is_instance_valid(_fill):
		return
	_fill.visible = (not air_pocket or lake_presentation) and points.size() >= 3 and not Geometry2D.triangulate_polygon(points).is_empty()
	_fill.polygon = points if _fill.visible else PackedVector2Array()
	if lake_presentation and air_pocket:
		var boundary := points.slice(0,256)
		var boundary_count := boundary.size()
		boundary.resize(256)
		var bounds := Rect2()
		if not points.is_empty():
			bounds = Rect2(points[0],Vector2.ZERO)
			for point in points:
				bounds = bounds.expand(point)
		_fill.color = Color.WHITE
		_fill.material.set_shader_parameter("boundary", boundary)
		_fill.material.set_shader_parameter("boundary_count", boundary_count)
		_fill.material.set_shader_parameter("pocket_top", bounds.position.y)
		_fill.material.set_shader_parameter("pocket_bottom", bounds.end.y)
		return
	var tint := water_color
	if Engine.is_editor_hint():
		tint = Color(0.10, 0.55, 0.85, 0.5)
	if not Engine.is_editor_hint():
		for body in get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("is_in_prototype_water") and body.is_in_prototype_water():
				tint.a = underwater_opacity
	_fill.color = tint
	if lake_presentation:
		_fill.material.set_shader_parameter("surface_y", get_surface_global_y())
		_fill.material.set_shader_parameter("submerged", tint.a == underwater_opacity)
	var vertices := PackedVector2Array()
	var counts := PackedInt32Array()
	var over_limit := false
	for pocket in get_tree().get_nodes_in_group("lake_air_pockets"):
		if counts.size() >= 16 or vertices.size() + pocket.points.size() > 256:
			over_limit = true
			continue
		counts.append(pocket.points.size())
		for point in pocket.points:
			vertices.append(pocket.to_global(point))
	var count := counts.size()
	if over_limit and not _reported_pocket_limit:
		push_warning("Greybox water visual supports 16 air pockets / 256 total pocket points per scene. Split larger maps into rooms. All pockets still affect swimming.")
	_reported_pocket_limit = over_limit
	vertices.resize(256)
	counts.resize(16)
	_fill.material.set_shader_parameter("air_points", vertices)
	_fill.material.set_shader_parameter("air_counts", counts)
	_fill.material.set_shader_parameter("pocket_count", count)
	for i in range(_ripples.size()-1,-1,-1):
		_ripples[i].age += delta
		if _ripples[i].age >= 1.0:
			_ripples.remove_at(i)
	_wake_timer += delta
	if not Engine.is_editor_hint() and not air_pocket and _wake_timer > 0.12:
		_wake_timer = 0.0
		for body in get_overlapping_bodies():
			if body is CharacterBody2D and body.velocity.length() > 80 and _ripples.size() < 32:
				var point: Vector2 = body.get_water_sample_position() if body.has_method("get_water_sample_position") else body.global_position
				if _is_visible_water(point) and (not body.has_method("is_in_prototype_water") or body.is_in_prototype_water()):
					_ripples.append({"position": to_local(point), "age": 0.0})
	_ripple_visual.queue_redraw()
	queue_redraw()

func _get_configuration_warnings() -> PackedStringArray:
	if points.size() < 3 or Geometry2D.triangulate_polygon(points).is_empty():
		return PackedStringArray(["Draw a closed polygon with at least three points. Edges must not cross; use Air Pocket for holes."])
	return PackedStringArray()

func _is_visible_water(point: Vector2) -> bool:
	if not contains_global_point(point):
		return false
	for pocket in get_tree().get_nodes_in_group("lake_air_pockets"):
		if pocket.contains_global_point(point):
			return false
	return true
