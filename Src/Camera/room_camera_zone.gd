@tool
class_name RoomCameraZone2D
extends Area2D

## Defines a room boundary for the room-aware camera. Add either a
## CollisionShape2D with a RectangleShape2D or a CollisionPolygon2D as a child.
## The controller automatically insets this boundary by the visible viewport,
## so the edited shape should follow the room's actual visible edges.

@export var zone_priority := 0
@export_range(0.0, 512.0, 1.0) var edge_padding := 0.0
@export var enabled := true


func _enter_tree() -> void:
	add_to_group(&"room_camera_zones")
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false


func contains_global_point(global_point: Vector2) -> bool:
	var boundary := get_global_boundary()
	return boundary.size() >= 3 and Geometry2D.is_point_in_polygon(
		global_point,
		boundary
	)


func clamp_camera_center(
	desired_center: Vector2,
	viewport_half_size: Vector2
) -> Vector2:
	var boundary := get_global_boundary()
	if boundary.size() < 3:
		return desired_center
	return _clamp_to_inset_convex_polygon(
		desired_center,
		boundary,
		viewport_half_size + Vector2.ONE * edge_padding
	)


func get_global_boundary() -> PackedVector2Array:
	for child in get_children():
		var polygon_node := child as CollisionPolygon2D
		if polygon_node and polygon_node.polygon.size() >= 3:
			var global_polygon := PackedVector2Array()
			for point in polygon_node.polygon:
				global_polygon.append(polygon_node.to_global(point))
			return global_polygon

	for child in get_children():
		var shape_node := child as CollisionShape2D
		if not shape_node or not (shape_node.shape is RectangleShape2D):
			continue
		var rectangle := shape_node.shape as RectangleShape2D
		var half_size := rectangle.size * 0.5
		return PackedVector2Array([
			shape_node.to_global(Vector2(-half_size.x, -half_size.y)),
			shape_node.to_global(Vector2(half_size.x, -half_size.y)),
			shape_node.to_global(Vector2(half_size.x, half_size.y)),
			shape_node.to_global(Vector2(-half_size.x, half_size.y)),
		])

	return PackedVector2Array()


func has_valid_boundary() -> bool:
	var boundary := get_global_boundary()
	return boundary.size() >= 3 and _is_convex(boundary)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var boundary := get_global_boundary()
	if boundary.size() < 3:
		warnings.append(
			"Add a CollisionShape2D with a RectangleShape2D or a "
			+ "CollisionPolygon2D child to define this room."
		)
	elif not _is_convex(boundary):
		warnings.append(
			"Room camera polygons must be convex. Split a concave room into "
			+ "overlapping convex zones and use zone_priority where needed."
		)
	return warnings


func _clamp_to_inset_convex_polygon(
	point: Vector2,
	polygon: PackedVector2Array,
	viewport_half_size: Vector2
) -> Vector2:
	if not _is_convex(polygon):
		return point

	var result := point
	var clockwise := Geometry2D.is_polygon_clockwise(polygon)
	# Project repeatedly because correcting one edge can cross another near a
	# corner. Convex room shapes settle in only a few passes.
	for _pass in 8:
		var changed := false
		for index in polygon.size():
			var edge_start := polygon[index]
			var edge_end := polygon[(index + 1) % polygon.size()]
			var edge := edge_end - edge_start
			if edge.is_zero_approx():
				continue
			var inward_normal := Vector2(-edge.y, edge.x).normalized()
			if clockwise:
				inward_normal = -inward_normal
			var required_distance := (
				absf(inward_normal.x) * viewport_half_size.x
				+ absf(inward_normal.y) * viewport_half_size.y
			)
			var current_distance := (result - edge_start).dot(inward_normal)
			if current_distance + 0.01 >= required_distance:
				continue
			result += inward_normal * (required_distance - current_distance)
			changed = true
		if not changed:
			break

	return result


func _is_convex(polygon: PackedVector2Array) -> bool:
	if polygon.size() < 3:
		return false
	var direction := 0.0
	for index in polygon.size():
		var a := polygon[index]
		var b := polygon[(index + 1) % polygon.size()]
		var c := polygon[(index + 2) % polygon.size()]
		var cross := (b - a).cross(c - b)
		if is_zero_approx(cross):
			continue
		if is_zero_approx(direction):
			direction = signf(cross)
		elif signf(cross) != direction:
			return false
	return not is_zero_approx(direction)
