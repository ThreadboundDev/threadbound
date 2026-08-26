@tool
class_name BlueGreyboxRoom2D
extends Node2D

@export var room_id := "blue_room"
@export var display_name := "Blue Room"
@export var macro_focus := Vector2.ZERO:
	set(value):
		macro_focus = value
		_sync_reference()
@export var planning_bounds := Vector2(1920.0, 1080.0):
	set(value):
		planning_bounds = Vector2(maxf(value.x, 256.0), maxf(value.y, 256.0))
		queue_redraw()
@export_multiline var design_intent := ""


func _ready() -> void:
	_sync_reference()
	queue_redraw()


func _sync_reference() -> void:
	var reference := get_node_or_null("MacroReference") as BlueMacroReference2D
	if reference:
		reference.source_focus = macro_focus


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var rect := Rect2(-planning_bounds * 0.5, planning_bounds)
	draw_rect(rect, Color(0.2, 0.7, 1.0, 0.08), true)
	draw_rect(rect, Color(0.35, 0.82, 1.0, 0.9), false, 12.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-planning_bounds.x * 0.5 + 32.0, -planning_bounds.y * 0.5 + 58.0),
		display_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		42,
		Color(0.75, 0.94, 1.0, 0.95)
	)
