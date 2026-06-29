@tool
extends Control
class_name ControllerCallout

@export var label_text := "Action":
	set(value):
		label_text = value
		_sync_label()

@export var label_position := Vector2.ZERO:
	set(value):
		label_position = value
		_sync_label()

@export var label_size := Vector2(180.0, 42.0):
	set(value):
		label_size = value
		_sync_label()

@export var label_settings: LabelSettings:
	set(value):
		label_settings = value
		_sync_label()

@export var label_alignment := HORIZONTAL_ALIGNMENT_LEFT:
	set(value):
		label_alignment = value
		_sync_label()

@export var points: PackedVector2Array = PackedVector2Array([
	Vector2(170.0, 22.0),
	Vector2(360.0, 22.0),
]):
	set(value):
		points = value
		queue_redraw()

@export var line_texture: Texture2D:
	set(value):
		line_texture = value
		queue_redraw()

@export var endpoint_texture: Texture2D:
	set(value):
		endpoint_texture = value
		queue_redraw()

@export var line_width := 6.0:
	set(value):
		line_width = value
		queue_redraw()

@export var endpoint_size := Vector2(18.0, 22.0):
	set(value):
		endpoint_size = value
		queue_redraw()

@export var line_modulate := Color.WHITE:
	set(value):
		line_modulate = value
		queue_redraw()

@export var show_start_endpoint := true:
	set(value):
		show_start_endpoint = value
		queue_redraw()

@export var show_end_endpoint := true:
	set(value):
		show_end_endpoint = value
		queue_redraw()

var _label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_label()
	_sync_label()

func _draw() -> void:
	if points.size() < 2:
		return

	for i in points.size() - 1:
		_draw_line_segment(points[i], points[i + 1])

	if endpoint_texture:
		if show_start_endpoint:
			_draw_endpoint(points[0])
		if show_end_endpoint:
			_draw_endpoint(points[points.size() - 1])

func _draw_line_segment(from: Vector2, to: Vector2) -> void:
	var delta := to - from
	var length := delta.length()
	if length <= 0.001:
		return

	var angle := delta.angle()
	if line_texture:
		draw_set_transform(from, angle, Vector2.ONE)
		draw_texture_rect(line_texture, Rect2(Vector2(0.0, -line_width * 0.5), Vector2(length, line_width)), false, line_modulate)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_line(from, to, line_modulate, line_width, true)

func _draw_endpoint(center: Vector2) -> void:
	var rect := Rect2(center - endpoint_size * 0.5, endpoint_size)
	draw_texture_rect(endpoint_texture, rect, false, line_modulate)

func _ensure_label() -> void:
	_label = get_node_or_null("Label") as Label
	if _label:
		return

	_label = Label.new()
	_label.name = "Label"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_label.owner = owner

func _sync_label() -> void:
	if not is_inside_tree():
		return

	_ensure_label()
	if not _label:
		return

	_label.text = label_text
	_label.position = label_position
	_label.size = label_size
	_label.label_settings = label_settings
	_label.horizontal_alignment = label_alignment
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
