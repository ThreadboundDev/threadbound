@tool
class_name GreyboxAnnotationArea2D
extends Area2D

@export var title := "Custom Annotation":
	set(value):
		title = value
		queue_redraw()
@export_multiline var notes := ""
@export_enum("General", "Structure", "Surface", "Hazard", "Vegetation", "Atmosphere", "Transition", "Secret") var category := "General":
	set(value):
		category = value
		queue_redraw()
@export_enum("None", "Solid", "One-way", "Hazard", "Water") var intended_collision := "None":
	set(value):
		intended_collision = value
		queue_redraw()
@export_enum("Far Background", "Midground", "Gameplay Backing", "Gameplay Edge", "Near", "Foreground") var art_layer := "Gameplay Backing":
	set(value):
		art_layer = value
		queue_redraw()
@export_enum("Unspecified", "Floor", "Wall Left", "Wall Right", "Ceiling", "Span") var orientation := "Unspecified":
	set(value):
		orientation = value
		queue_redraw()
@export var size := Vector2(384.0, 192.0):
	set(value):
		size = Vector2(maxf(value.x, 24.0), maxf(value.y, 24.0))
		_refresh_shape()
@export var annotation_color := Color(0.28, 0.82, 1.0, 0.2):
	set(value):
		annotation_color = value
		queue_redraw()
@export var show_region := true:
	set(value):
		show_region = value
		queue_redraw()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_refresh_shape()


func _refresh_shape() -> void:
	queue_redraw()
	if not is_node_ready():
		return
	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision_shape.shape = rectangle
	rectangle.size = size


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var half_size := size * 0.5
	var rect := Rect2(-half_size, size)
	var solid_color := annotation_color
	solid_color.a = clampf(annotation_color.a, 0.04, 0.42)
	var edge_color := annotation_color
	edge_color.a = 0.95
	if show_region:
		draw_rect(rect, solid_color, true)
		draw_rect(rect, edge_color, false, 4.0)
	var heading_position := Vector2(-half_size.x + 14.0, -half_size.y + 30.0)
	draw_string(ThemeDB.fallback_font, heading_position, title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 22, edge_color)
	var details := "%s • %s • %s" % [intended_collision, art_layer, orientation]
	draw_string(ThemeDB.fallback_font, heading_position + Vector2(0.0, 27.0), details, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28.0, 15, edge_color)
