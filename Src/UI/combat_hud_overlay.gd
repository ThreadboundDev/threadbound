@tool
extends Control
class_name CombatHUDOverlay

const ART_SIZE := Vector2(1254.0, 1254.0)
const ORB_CENTERS := [
	Vector2(383.0, 251.0),
	Vector2(871.0, 251.0),
	Vector2(192.0, 615.0),
	Vector2(1062.0, 615.0),
	Vector2(383.0, 1000.0),
	Vector2(871.0, 1000.0),
]

@export_range(1, 6, 1) var max_action_points := 6:
	set(value):
		max_action_points = clampi(value, 1, 6)
		current_action_points = clampi(current_action_points, 0, max_action_points)
		queue_redraw()

@export_range(0, 6, 1) var current_action_points := 6:
	set(value):
		current_action_points = clampi(value, 0, max_action_points)
		queue_redraw()

@export_range(0.0, 1.0, 0.01) var momentum := 0.0:
	set(value):
		momentum = clampf(value, 0.0, 1.0)
		queue_redraw()

@export var active_orb_color := Color(0.95, 0.72, 0.28, 0.9)
@export var inactive_orb_color := Color(0.05, 0.06, 0.08, 0.58)
@export var draw_procedural_orbs := false:
	set(value):
		draw_procedural_orbs = value
		queue_redraw()
@export var action_point_orb_texture: Texture2D:
	set(value):
		action_point_orb_texture = value
		queue_redraw()
@export_range(80.0, 260.0, 1.0) var orb_texture_diameter := 188.0:
	set(value):
		orb_texture_diameter = value
		queue_redraw()
@export_range(0.0, 1.0, 0.01) var inactive_orb_alpha := 0.42:
	set(value):
		inactive_orb_alpha = value
		queue_redraw()

var rune_colors: Array[Color] = []
var rune_available: Array[bool] = []

func _ready() -> void:
	_configure_default_runes()

func set_rune_states(colors: Array[Color], availability: Array[bool]) -> void:
	rune_colors = colors.duplicate()
	rune_available = availability.duplicate()
	_configure_default_runes()
	queue_redraw()

func _draw() -> void:
	_configure_default_runes()
	var scale_factor: float = min(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var offset: Vector2 = (size - ART_SIZE * scale_factor) * 0.5

	for i in ORB_CENTERS.size():
		if i >= max_action_points:
			continue

		var center: Vector2 = offset + ORB_CENTERS[i] * scale_factor
		var radius: float = 62.0 * scale_factor
		var available := rune_available[i] and i < current_action_points
		var color := rune_colors[i] if available else inactive_orb_color
		if draw_procedural_orbs:
			_draw_action_point_orb(center, scale_factor, color, available)
		draw_arc(center, radius * 0.82, 0.0, TAU, 48, color.lightened(0.35), 2.0 * scale_factor, true)
		if available:
			_draw_rune(center, radius * 0.48, scale_factor, color)

func _draw_action_point_orb(center: Vector2, scale_factor: float, color: Color, available: bool) -> void:
	if action_point_orb_texture:
		var diameter := orb_texture_diameter * scale_factor
		var rect := Rect2(center - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter)
		var tint := Color.WHITE if available else Color(0.55, 0.57, 0.62, inactive_orb_alpha)
		draw_texture_rect(action_point_orb_texture, rect, false, tint)
		return

	draw_circle(center, 62.0 * scale_factor, color)

func _draw_rune(center: Vector2, radius: float, scale_factor: float, rune_color: Color) -> void:
	var color := rune_color.lightened(0.55)
	var width := 2.0 * scale_factor
	draw_line(center + Vector2(0, -radius), center + Vector2(radius * 0.42, 0), color, width, true)
	draw_line(center + Vector2(radius * 0.42, 0), center + Vector2(0, radius), color, width, true)
	draw_line(center + Vector2(0, radius), center + Vector2(-radius * 0.42, 0), color, width, true)
	draw_line(center + Vector2(-radius * 0.42, 0), center + Vector2(0, -radius), color, width, true)
	draw_line(center + Vector2(-radius * 0.68, 0), center + Vector2(radius * 0.68, 0), color, width, true)

func _configure_default_runes() -> void:
	while rune_colors.size() < 6:
		rune_colors.append(active_orb_color)
	while rune_available.size() < 6:
		rune_available.append(rune_available.size() < current_action_points)
