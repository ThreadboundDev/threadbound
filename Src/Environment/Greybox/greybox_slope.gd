@tool
class_name GreyboxSlope2D
extends StaticBody2D

@export var size := Vector2(512.0, 256.0):
	set(value):
		size = Vector2(maxf(value.x, 32.0), maxf(value.y, 32.0))
		_refresh()
@export var rises_right := true:
	set(value):
		rises_right = value
		_refresh()
@export var slope_color := Color(0.18, 0.25, 0.29, 0.94):
	set(value):
		slope_color = value
		queue_redraw()


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	queue_redraw()
	if not is_node_ready():
		return
	var points := _points()
	$CollisionPolygon2D.polygon = points
	$GrappleTarget/CollisionPolygon2D.polygon = points


func _points() -> PackedVector2Array:
	var half := size * 0.5
	if rises_right:
		return PackedVector2Array([Vector2(-half.x, half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y)])
	return PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])


func _draw() -> void:
	var points := _points()
	draw_colored_polygon(points, slope_color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), slope_color.lightened(0.3), 4.0)
