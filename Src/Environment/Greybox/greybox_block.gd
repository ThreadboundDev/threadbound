@tool
class_name GreyboxBlock2D
extends StaticBody2D

@export var size := Vector2(256.0, 128.0):
	set(value):
		size = Vector2(maxf(value.x, 8.0), maxf(value.y, 8.0))
		_refresh()
@export var block_color := Color(0.20, 0.22, 0.25, 0.94):
	set(value):
		block_color = value
		queue_redraw()
@export var one_way := false:
	set(value):
		one_way = value
		_refresh()
@export var grid_size := 128.0

@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	queue_redraw()
	if not is_node_ready():
		return
	if Engine.is_editor_hint():
		collision.self_modulate = Color(1,1,1,0)
	var rectangle := collision.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
	else:
		rectangle = rectangle.duplicate() as RectangleShape2D
	collision.shape = rectangle
	rectangle.size = size
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 12.0


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, block_color, true)
	draw_rect(rect, block_color.lightened(0.28), false, 4.0)
	if Engine.is_editor_hint():
		draw_rect(rect, Color(0.40,0.44,0.49,1), true)
		draw_rect(rect, Color(0.75,0.81,0.88), false, 3.0)
		var label := "ONE-WAY" if one_way else "SOLID"
		draw_string(ThemeDB.fallback_font, Vector2(-size.x*.5+8,4), label, HORIZONTAL_ALIGNMENT_LEFT, size.x-16, 20, Color.WHITE)
	if one_way:
		draw_line(Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(size.x * 0.5, -size.y * 0.5), Color.WHITE, 6.0)
