@tool
class_name GreyboxPolygonTerrain2D
extends StaticBody2D

## Draw irregular solid terrain by editing CollisionPolygon2D in the 2D editor.
## The polygon is mirrored automatically to GrappleTarget so traversal and grapple
## always use the same silhouette.

@export var one_way := false:
	set(value):
		one_way = value
		_sync_polygon(true)
@export var editor_preview_color := Color(0.16, 0.19, 0.23, 0.42):
	set(value):
		editor_preview_color = value
		queue_redraw()
@export var editor_outline_color := Color(0.68, 0.82, 0.92, 0.9):
	set(value):
		editor_outline_color = value
		queue_redraw()

var _last_polygon := PackedVector2Array()


func _ready() -> void:
	set_process(true)
	_sync_polygon(true)


func _process(_delta: float) -> void:
	_sync_polygon()


func _sync_polygon(force := false) -> void:
	var collision := get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	var grapple_collision := get_node_or_null("GrappleTarget/CollisionPolygon2D") as CollisionPolygon2D
	if collision == null or grapple_collision == null:
		return
	if not force and collision.polygon == _last_polygon:
		return
	_last_polygon = collision.polygon.duplicate()
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 12.0
	grapple_collision.polygon = _last_polygon
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() or _last_polygon.size() < 3:
		return
	draw_colored_polygon(_last_polygon, editor_preview_color)
	var outline := _last_polygon.duplicate()
	outline.append(_last_polygon[0])
	draw_polyline(outline, editor_outline_color, 4.0, true)
