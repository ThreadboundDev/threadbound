@tool
class_name GreyboxWater2D
extends Area2D

@export var size := Vector2(512.0, 256.0):
	set(value):
		size = Vector2(maxf(value.x, 16.0), maxf(value.y, 16.0))
		_refresh()
@export var water_color := Color(0.08, 0.38, 0.72, 1.0):
	set(value):
		water_color = value
		queue_redraw()
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_refresh()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _refresh() -> void:
	queue_redraw()
	if not is_node_ready():
		return
	var rectangle := collision.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision.shape = rectangle
	rectangle.size = size


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	# Prototype water is a surface, not a dive volume. Keep it opaque so the
	# submerged portion of the player is cleanly masked instead of showing legs.
	draw_rect(rect, Color(water_color.r, water_color.g, water_color.b, 1.0), true)
	draw_rect(rect, Color(0.45, 0.85, 1.0, 0.95), false, 4.0)
	for x in range(int(-size.x * 0.5), int(size.x * 0.5), 32):
		draw_line(Vector2(x, -size.y * 0.5 + 8.0), Vector2(x + 16.0, -size.y * 0.5 + 4.0), Color(0.7, 0.95, 1.0, 0.8), 3.0)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enter_prototype_water"):
		body.call("enter_prototype_water", self, get_surface_global_y())


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_prototype_water"):
		body.call("exit_prototype_water", self)


func get_surface_global_y() -> float:
	return to_global(Vector2(0.0, -size.y * 0.5)).y
