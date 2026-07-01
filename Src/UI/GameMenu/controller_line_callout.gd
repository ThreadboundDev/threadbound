@tool
extends Control
class_name ControllerLineCallout

@export var action_text := "Action":
	set(value):
		action_text = value
		_sync_text()

@export var input_text := "Input":
	set(value):
		input_text = value
		_sync_text()

@export var text_box_offset := Vector2(28.0, -22.0):
	set(value):
		text_box_offset = value
		_sync_positions()

@export var line_texture: Texture2D:
	set(value):
		line_texture = value
		_sync_line_style()

@export var endpoint_texture: Texture2D:
	set(value):
		endpoint_texture = value
		_sync_endpoint_style()

@export var line_width := 4.0:
	set(value):
		line_width = value
		_sync_line_style()

@export var endpoint_scale := Vector2(0.2, 0.2):
	set(value):
		endpoint_scale = value
		_sync_endpoint_style()

@onready var line: Line2D = $Line as Line2D
@onready var start_point: Sprite2D = get_node_or_null("StartPoint") as Sprite2D
@onready var end_point: Sprite2D = $EndPoint as Sprite2D
@onready var text_box: Control = $TextBox as Control
@onready var action_label: Label = $TextBox/ActionLabel as Label
@onready var input_label: Label = get_node_or_null("TextBox/InputLabel") as Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_all()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_positions()

func _sync_all() -> void:
	_sync_text()
	_sync_line_style()
	_sync_endpoint_style()
	_sync_positions()

func _sync_text() -> void:
	if not is_inside_tree():
		return
	if action_label:
		action_label.text = action_text
	if input_label:
		input_label.text = input_text

func _sync_line_style() -> void:
	if not is_inside_tree() or not line:
		return
	line.width = line_width
	line.texture = line_texture
	line.texture_mode = Line2D.LINE_TEXTURE_TILE

func _sync_endpoint_style() -> void:
	if not is_inside_tree():
		return
	for point in [start_point, end_point]:
		if point:
			point.texture = endpoint_texture
			point.scale = endpoint_scale

func _sync_positions() -> void:
	if not is_inside_tree() or not line or line.points.size() < 2:
		return

	var first_point := line.points[0]
	var last_point := line.points[line.points.size() - 1]
	if start_point:
		start_point.position = first_point
	if end_point:
		end_point.position = last_point
	if text_box:
		text_box.position = last_point + text_box_offset
