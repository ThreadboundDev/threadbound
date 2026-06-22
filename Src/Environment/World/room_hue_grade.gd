@tool
extends CanvasLayer

@export var player_path: NodePath = ^"../Player"
@export var grade_rect_path: NodePath = ^"RoomHueRect"
@export var fade_speed := 2.8
@export var max_strength := 0.12
@export var neutral_color := Color(1.0, 1.0, 1.0, 1.0)
@export var sync_bounds_from_placeholders := true
@export var remove_placeholder_nodes := true

@export_group("Room Bounds")
@export var top_left_room := Rect2(Vector2(-5700.0, -3480.0), Vector2(5700.0, 5980.0))
@export var top_right_room := Rect2(Vector2(0.0, -3480.0), Vector2(8200.0, 5980.0))
@export var bottom_left_room := Rect2(Vector2(-5700.0, 2500.0), Vector2(5700.0, 3700.0))
@export var bottom_right_room := Rect2(Vector2(0.0, 2500.0), Vector2(8200.0, 3700.0))
@export var center_neutral_room := Rect2(Vector2(-1000.0, 1680.0), Vector2(2000.0, 1620.0))
@export var top_left_polygon := PackedVector2Array()
@export var top_right_polygon := PackedVector2Array()
@export var bottom_left_polygon := PackedVector2Array()
@export var bottom_right_polygon := PackedVector2Array()
@export var placeholder_default_size := Vector2(1200.0, 900.0)

@export_group("Placeholder Node Names")
@export var red_placeholder_name := "Red Shader Goes Here"
@export var blue_placeholder_name := "Blue Shader Goes Here"
@export var yellow_placeholder_name := "Yellow Shader Goes Here"
@export var purple_placeholder_name := "Purple Shader Goes Her"

@export_group("Room Colors")
@export var top_left_color := Color(1.0, 0.28, 0.2, 1.0)
@export var top_right_color := Color(0.28, 0.56, 1.0, 1.0)
@export var bottom_left_color := Color(1.0, 0.78, 0.24, 1.0)
@export var bottom_right_color := Color(0.62, 0.34, 1.0, 1.0)

@onready var _player := get_node_or_null(player_path) as Node2D
@onready var _grade_rect := get_node_or_null(grade_rect_path) as ColorRect

var _current_color := Color.WHITE
var _current_strength := 0.0

func _ready() -> void:
	_sync_room_bounds_from_placeholders()
	_current_color = neutral_color
	_apply_grade()

func _process(delta: float) -> void:
	if not _player or not _grade_rect:
		return

	var target := _target_grade_for_position(_player.global_position)
	var target_color: Color = target["color"]
	var target_strength: float = target["strength"]
	var weight := clampf(fade_speed * delta, 0.0, 1.0)

	_current_color = _current_color.lerp(target_color, weight)
	_current_strength = lerpf(_current_strength, target_strength, weight)
	_apply_grade()

func _target_grade_for_position(global_position: Vector2) -> Dictionary:
	if center_neutral_room.has_point(global_position):
		return {"color": neutral_color, "strength": 0.0}

	if _room_contains(bottom_right_polygon, bottom_right_room, global_position):
		return {"color": bottom_right_color, "strength": max_strength}
	if _room_contains(bottom_left_polygon, bottom_left_room, global_position):
		return {"color": bottom_left_color, "strength": max_strength}
	if _room_contains(top_right_polygon, top_right_room, global_position):
		return {"color": top_right_color, "strength": max_strength}
	if _room_contains(top_left_polygon, top_left_room, global_position):
		return {"color": top_left_color, "strength": max_strength}

	return {"color": neutral_color, "strength": 0.0}

func _apply_grade() -> void:
	if not _grade_rect or not _grade_rect.material:
		return

	var shader_material := _grade_rect.material as ShaderMaterial
	if not shader_material:
		return

	shader_material.set_shader_parameter("hue_color", _current_color)
	shader_material.set_shader_parameter("hue_strength", _current_strength)

func _sync_room_bounds_from_placeholders() -> void:
	if not sync_bounds_from_placeholders:
		return

	var root := get_tree().edited_scene_root if Engine.is_editor_hint() else get_tree().current_scene
	if not root:
		root = get_tree().root

	top_left_room = _placeholder_rect_or_existing(root, red_placeholder_name, top_left_room)
	top_right_room = _placeholder_rect_or_existing(root, blue_placeholder_name, top_right_room)
	bottom_left_room = _placeholder_rect_or_existing(root, yellow_placeholder_name, bottom_left_room)
	bottom_right_room = _placeholder_rect_or_existing(root, purple_placeholder_name, bottom_right_room)

	top_left_polygon = _placeholder_polygon_or_existing(root, red_placeholder_name, top_left_polygon)
	top_right_polygon = _placeholder_polygon_or_existing(root, blue_placeholder_name, top_right_polygon)
	bottom_left_polygon = _placeholder_polygon_or_existing(root, yellow_placeholder_name, bottom_left_polygon)
	bottom_right_polygon = _placeholder_polygon_or_existing(root, purple_placeholder_name, bottom_right_polygon)

func _placeholder_rect_or_existing(root: Node, placeholder_name: String, existing: Rect2) -> Rect2:
	var placeholder := _find_node_recursive(root, placeholder_name)
	if not placeholder and placeholder_name.ends_with(" Her"):
		placeholder = _find_node_recursive(root, "%se" % placeholder_name)
	if not placeholder:
		return existing

	var rect := _rect_from_placeholder(placeholder, existing)
	if remove_placeholder_nodes and not Engine.is_editor_hint():
		placeholder.queue_free()
	elif placeholder is CanvasItem:
		(placeholder as CanvasItem).visible = false
	return rect

func _placeholder_polygon_or_existing(root: Node, placeholder_name: String, existing: PackedVector2Array) -> PackedVector2Array:
	var placeholder := _find_placeholder(root, placeholder_name)
	if not placeholder:
		return existing

	var polygon_node := placeholder as CollisionPolygon2D
	if polygon_node:
		var global_polygon := PackedVector2Array()
		for point in polygon_node.polygon:
			global_polygon.append(polygon_node.to_global(point))
		return global_polygon

	return existing

func _find_placeholder(root: Node, placeholder_name: String) -> Node:
	var placeholder := _find_node_recursive(root, placeholder_name)
	if not placeholder and placeholder_name.ends_with(" Her"):
		placeholder = _find_node_recursive(root, "%se" % placeholder_name)
	return placeholder

func _find_node_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node

	for child in node.get_children():
		var found := _find_node_recursive(child, target_name)
		if found:
			return found
	return null

func _rect_from_placeholder(placeholder: Node, fallback: Rect2) -> Rect2:
	var shape_node := placeholder as CollisionShape2D
	if not shape_node:
		shape_node = _first_collision_shape_child(placeholder)

	if shape_node and shape_node.shape is RectangleShape2D:
		var rectangle_shape := shape_node.shape as RectangleShape2D
		var center := shape_node.global_position
		var size := Vector2(
			absf(rectangle_shape.size.x * shape_node.global_scale.x),
			absf(rectangle_shape.size.y * shape_node.global_scale.y)
		)
		return Rect2(center - size * 0.5, size).abs()

	if placeholder is Node2D:
		var center := (placeholder as Node2D).global_position
		return Rect2(center - placeholder_default_size * 0.5, placeholder_default_size).abs()

	return fallback

func _room_contains(room_polygon: PackedVector2Array, room_rect: Rect2, global_position: Vector2) -> bool:
	if room_polygon.size() >= 3:
		return Geometry2D.is_point_in_polygon(global_position, room_polygon)
	return room_rect.has_point(global_position)

func _first_collision_shape_child(node: Node) -> CollisionShape2D:
	for child in node.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
		var nested := _first_collision_shape_child(child)
		if nested:
			return nested
	return null
