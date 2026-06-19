extends CanvasLayer

@export var player_path: NodePath = ^"../Player"
@export var grade_rect_path: NodePath = ^"RoomHueRect"
@export var fade_speed := 2.8
@export var max_strength := 0.12
@export var neutral_color := Color(1.0, 1.0, 1.0, 1.0)

@export_group("Room Bounds")
@export var top_left_room := Rect2(Vector2(-5700.0, -3480.0), Vector2(5700.0, 5980.0))
@export var top_right_room := Rect2(Vector2(0.0, -3480.0), Vector2(8200.0, 5980.0))
@export var bottom_left_room := Rect2(Vector2(-5700.0, 2500.0), Vector2(5700.0, 3700.0))
@export var bottom_right_room := Rect2(Vector2(0.0, 2500.0), Vector2(8200.0, 3700.0))
@export var center_neutral_room := Rect2(Vector2(-1000.0, 1680.0), Vector2(2000.0, 1620.0))

@export_group("Room Colors")
@export var top_left_color := Color(1.0, 0.28, 0.2, 1.0)
@export var top_right_color := Color(0.28, 0.56, 1.0, 1.0)
@export var bottom_left_color := Color(1.0, 0.78, 0.24, 1.0)
@export var bottom_right_color := Color(0.62, 0.34, 1.0, 1.0)

@onready var _player := get_node_or_null(player_path) as Node2D
@onready var _grade_rect := get_node_or_null(grade_rect_path) as ColorRect

var _current_color := Color.WHITE
var _current_strength := 0.0

func _ready() -> void:
	_current_color = neutral_color
	_apply_grade()

func _process(delta: float) -> void:
	if not _player or not _grade_rect:
		return

	var target := _target_grade_for_position(_player.global_position)
	var target_color: Color = target["color"]
	var target_strength: float = target["strength"]
	var weight := clampf(fade_speed * delta, 0.0, 1.0)

	_current_color = _current_color.lerp(target_color, weight)
	_current_strength = lerpf(_current_strength, target_strength, weight)
	_apply_grade()

func _target_grade_for_position(global_position: Vector2) -> Dictionary:
	if center_neutral_room.has_point(global_position):
		return {"color": neutral_color, "strength": 0.0}

	if bottom_right_room.has_point(global_position):
		return {"color": bottom_right_color, "strength": max_strength}
	if bottom_left_room.has_point(global_position):
		return {"color": bottom_left_color, "strength": max_strength}
	if top_right_room.has_point(global_position):
		return {"color": top_right_color, "strength": max_strength}
	if top_left_room.has_point(global_position):
		return {"color": top_left_color, "strength": max_strength}

	return {"color": neutral_color, "strength": 0.0}

func _apply_grade() -> void:
	if not _grade_rect or not _grade_rect.material:
		return

	var material := _grade_rect.material as ShaderMaterial
	if not material:
		return

	material.set_shader_parameter("hue_color", _current_color)
	material.set_shader_parameter("hue_strength", _current_strength)
