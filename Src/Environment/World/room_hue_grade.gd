@tool
extends CanvasLayer

const TRANSITION_SETTLE_EPSILON := 0.001

@export var player_path: NodePath = ^"../../Player"
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

@export_group("Wing Grass Recolor")
@export var grass_recolor_enabled := true
@export_range(0.0, 1.0, 0.01) var grass_recolor_strength := 1.0
@export var grass_fade_speed := 2.8
@export var red_grass_color := Color(0.82, 0.16, 0.12, 1.0)
@export var blue_grass_color := Color(0.2, 0.48, 0.95, 1.0)
@export var yellow_grass_color := Color(1.0, 0.7, 0.16, 1.0)
@export var boss_grass_color := Color(0.9, 0.95, 1.0, 1.0)
@export var grass_tilemap_paths: Array[NodePath] = [
	^"../../WorldArt/Architecture/ChamberTileMap",
	^"../../WorldArt/Architecture/ChamberLedgerTileMap",
]

@onready var _player := get_node_or_null(player_path) as Node2D
@onready var _grade_rect := get_node_or_null(grade_rect_path) as ColorRect

var _current_color := Color.WHITE
var _current_strength := 0.0
var _current_grass_strengths := Vector4.ZERO
var _grass_materials: Array[ShaderMaterial] = []
var _last_applied_color := Color(-1.0, -1.0, -1.0, -1.0)
var _last_applied_strength := -1.0
var _last_applied_grass_strengths := Vector4(-1.0, -1.0, -1.0, -1.0)
var _boss_intro_blend := 0.0
var _boss_intro_tween: Tween

func _ready() -> void:
	_sync_room_bounds_from_placeholders()
	_cache_grass_materials()
	_current_color = neutral_color
	_current_grass_strengths = Vector4.ZERO
	_apply_grade(true)
	_apply_grass_static_parameters()
	_apply_grass_grade(true)

	# Keep the editor preview static. Continuously changing shared TileMap
	# materials while editing forces unnecessary redraw and inspector work.
	if Engine.is_editor_hint():
		set_process(false)

func _process(delta: float) -> void:
	if not _player:
		return

	var target := _target_grade_for_position(_player.global_position)
	var target_color: Color = target["color"]
	var target_strength: float = target["strength"]
	var weight := clampf(fade_speed * delta, 0.0, 1.0)

	_current_color = _current_color.lerp(target_color, weight)
	_current_strength = lerpf(_current_strength, target_strength, weight)
	if _colors_close(
		_current_color,
		target_color,
		TRANSITION_SETTLE_EPSILON
	):
		_current_color = target_color
	if absf(_current_strength - target_strength) <= TRANSITION_SETTLE_EPSILON:
		_current_strength = target_strength
	_apply_grade()

	var grass_target_strengths := _target_grass_strengths_for_position(
		_player.global_position
	)
	var grass_weight := clampf(grass_fade_speed * delta, 0.0, 1.0)

	_current_grass_strengths = _current_grass_strengths.lerp(
		grass_target_strengths,
		grass_weight
	)
	if _vector4_close(
		_current_grass_strengths,
		grass_target_strengths,
		TRANSITION_SETTLE_EPSILON
	):
		_current_grass_strengths = grass_target_strengths
	_apply_grass_grade()

func _target_grade_for_position(global_position: Vector2) -> Dictionary:
	if center_neutral_room.has_point(global_position):
		return {"color": neutral_color, "strength": 0.0}

	if _room_contains(bottom_right_polygon, bottom_right_room, global_position):
		return {
			"color": bottom_right_color,
			"strength": max_strength * _boss_intro_blend,
		}
	if _room_contains(bottom_left_polygon, bottom_left_room, global_position):
		return {"color": bottom_left_color, "strength": max_strength}
	if _room_contains(top_right_polygon, top_right_room, global_position):
		return {"color": top_right_color, "strength": max_strength}
	if _room_contains(top_left_polygon, top_left_room, global_position):
		return {"color": top_left_color, "strength": max_strength}

	return {"color": neutral_color, "strength": 0.0}

func _target_grass_strengths_for_position(
	global_position: Vector2
) -> Vector4:
	if not grass_recolor_enabled:
		return Vector4.ZERO

	if center_neutral_room.has_point(global_position):
		return Vector4.ZERO

	if _room_contains(bottom_right_polygon, bottom_right_room, global_position):
		return Vector4(
			0.0,
			0.0,
			0.0,
			grass_recolor_strength * _boss_intro_blend
		)
	if _room_contains(bottom_left_polygon, bottom_left_room, global_position):
		return Vector4(0.0, 0.0, grass_recolor_strength, 0.0)
	if _room_contains(top_right_polygon, top_right_room, global_position):
		return Vector4(0.0, grass_recolor_strength, 0.0, 0.0)
	if _room_contains(top_left_polygon, top_left_room, global_position):
		return Vector4(grass_recolor_strength, 0.0, 0.0, 0.0)

	return Vector4.ZERO

func start_boss_intro_grade(duration: float = 1.2) -> void:
	if _boss_intro_blend >= 1.0:
		return
	if _boss_intro_tween and _boss_intro_tween.is_valid():
		_boss_intro_tween.kill()

	_boss_intro_tween = create_tween()
	_boss_intro_tween.set_trans(Tween.TRANS_CUBIC)
	_boss_intro_tween.set_ease(Tween.EASE_IN_OUT)
	_boss_intro_tween.tween_property(
		self,
		"_boss_intro_blend",
		1.0,
		maxf(0.01, duration)
	)

func get_boss_intro_grade_blend() -> float:
	return _boss_intro_blend

func _apply_grade(force := false) -> void:
	if not _grade_rect or not _grade_rect.material:
		return

	var shader_material := _grade_rect.material as ShaderMaterial
	if not shader_material:
		return

	if (
		not force
		and _current_color == _last_applied_color
		and _current_strength == _last_applied_strength
	):
		return

	shader_material.set_shader_parameter("hue_color", _current_color)
	shader_material.set_shader_parameter("hue_strength", _current_strength)
	_last_applied_color = _current_color
	_last_applied_strength = _current_strength

func _cache_grass_materials() -> void:
	_grass_materials.clear()
	for tilemap_path in grass_tilemap_paths:
		var canvas_item := get_node_or_null(tilemap_path) as CanvasItem
		if not canvas_item:
			continue

		var shader_material := canvas_item.material as ShaderMaterial
		if shader_material and not _grass_materials.has(shader_material):
			_grass_materials.append(shader_material)

func _apply_grass_static_parameters() -> void:
	for shader_material in _grass_materials:
		shader_material.set_shader_parameter(
			"red_luminance_basis",
			_grass_luminance_basis(red_grass_color)
		)
		shader_material.set_shader_parameter(
			"blue_luminance_basis",
			_grass_luminance_basis(blue_grass_color)
		)
		shader_material.set_shader_parameter(
			"yellow_luminance_basis",
			_grass_luminance_basis(yellow_grass_color)
		)
		shader_material.set_shader_parameter(
			"boss_luminance_basis",
			_grass_luminance_basis(boss_grass_color)
		)
		shader_material.set_shader_parameter(
			"red_bounds",
			_rect_shader_bounds(top_left_room)
		)
		shader_material.set_shader_parameter(
			"blue_bounds",
			_rect_shader_bounds(top_right_room)
		)
		shader_material.set_shader_parameter(
			"yellow_bounds",
			_rect_shader_bounds(bottom_left_room)
		)
		shader_material.set_shader_parameter(
			"boss_bounds",
			_rect_shader_bounds(bottom_right_room)
		)

func _apply_grass_grade(force := false) -> void:
	if _grass_materials.is_empty():
		_cache_grass_materials()
		_apply_grass_static_parameters()

	if (
		not force
		and _current_grass_strengths == _last_applied_grass_strengths
	):
		return

	for shader_material in _grass_materials:
		shader_material.set_shader_parameter(
			"wing_strengths",
			_current_grass_strengths
		)
	_last_applied_grass_strengths = _current_grass_strengths

func _grass_luminance_basis(color: Color) -> Vector3:
	var luminance := maxf(
		color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722,
		0.001
	)
	return Vector3(
		color.r / luminance,
		color.g / luminance,
		color.b / luminance
	)

func _rect_shader_bounds(rect: Rect2) -> Vector4:
	var normalized := rect.abs()
	return Vector4(
		normalized.position.x,
		normalized.position.y,
		normalized.end.x,
		normalized.end.y
	)

func _colors_close(a: Color, b: Color, epsilon: float) -> bool:
	return (
		absf(a.r - b.r) <= epsilon
		and absf(a.g - b.g) <= epsilon
		and absf(a.b - b.b) <= epsilon
		and absf(a.a - b.a) <= epsilon
	)

func _vector4_close(a: Vector4, b: Vector4, epsilon: float) -> bool:
	return (
		absf(a.x - b.x) <= epsilon
		and absf(a.y - b.y) <= epsilon
		and absf(a.z - b.z) <= epsilon
		and absf(a.w - b.w) <= epsilon
	)

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
