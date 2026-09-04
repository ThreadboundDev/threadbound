@tool
class_name GreyboxPolygonWater2D
extends Area2D

@export var points := PackedVector2Array([
	Vector2(-512.0, -192.0),
	Vector2(512.0, -192.0),
	Vector2(512.0, 192.0),
	Vector2(-512.0, 192.0),
]):
	set(value):
		points = value
		_refresh()
@export var water_color := Color(0.06, 0.3, 0.62, 0.92):
	set(value):
		water_color = value
		queue_redraw()

@onready var collision: CollisionPolygon2D = $CollisionPolygon2D

var _last_collision_points := PackedVector2Array()


func _ready() -> void:
	_refresh()
	set_process(true)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not is_node_ready() or collision.polygon == _last_collision_points:
		return
	points = collision.polygon.duplicate()


func _refresh() -> void:
	queue_redraw()
	if is_node_ready():
		collision.polygon = points
		_last_collision_points = points.duplicate()


func _draw() -> void:
	if points.size() < 3:
		return
	draw_colored_polygon(points, water_color)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color(0.45, 0.88, 1.0, 0.95), 5.0)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enter_prototype_water"):
		body.call("enter_prototype_water", self, get_surface_global_y())


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_prototype_water"):
		body.call("exit_prototype_water", self)


func get_surface_global_y() -> float:
	if points.is_empty():
		return global_position.y
	var surface_y := INF
	for point in points:
		surface_y = minf(surface_y, to_global(point).y)
	return surface_y
