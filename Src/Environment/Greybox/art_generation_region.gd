@tool
class_name ArtGenerationRegion2D
extends Polygon2D

@export var section_name := "Terrain Section A":
	set(value):
		section_name = value
		queue_redraw()
@export_enum("Far", "Mid", "Gameplay Back", "Gameplay Edge", "Foreground") var art_layer := "Gameplay Edge":
	set(value):
		art_layer = value
		queue_redraw()
@export_enum("Ground", "Ceiling", "Left Wall", "Right Wall", "Platform", "Structure", "Decoration") var asset_category := "Ground":
	set(value):
		asset_category = value
		queue_redraw()
@export_enum("Floor", "Ceiling", "Wall Left", "Wall Right", "Span", "Mixed") var surface_orientation := "Floor":
	set(value):
		surface_orientation = value
		queue_redraw()
@export_range(0.5, 4.0, 0.25) var pixels_per_world_unit := 2.0:
	set(value):
		pixels_per_world_unit = value
		queue_redraw()
@export_range(0.0, 512.0, 8.0) var overlap_padding := 128.0:
	set(value):
		overlap_padding = value
		queue_redraw()
@export_multiline var notes := ""
@export var guide_color := Color(0.96, 0.38, 0.82, 0.16):
	set(value):
		guide_color = value
		color = guide_color
		queue_redraw()
@export var show_measurements := true:
	set(value):
		show_measurements = value
		queue_redraw()


func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false
	else:
		color = guide_color


func get_world_bounds() -> Rect2:
	if polygon.is_empty():
		return Rect2(global_position, Vector2.ZERO)
	var first := to_global(polygon[0])
	var bounds := Rect2(first, Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(to_global(point))
	return bounds


func get_generation_spec() -> Dictionary:
	var bounds := get_world_bounds()
	var world_points: Array[Dictionary] = []
	for point in polygon:
		var world_point := to_global(point)
		world_points.append({"x": world_point.x, "y": world_point.y})
	return {
		"section_name": section_name,
		"art_layer": art_layer,
		"asset_category": asset_category,
		"surface_orientation": surface_orientation,
		"pixels_per_world_unit": pixels_per_world_unit,
		"overlap_padding_world": overlap_padding,
		"world_position": {"x": global_position.x, "y": global_position.y},
		"world_polygon": world_points,
		"world_bounds": {"x": bounds.position.x, "y": bounds.position.y, "width": bounds.size.x, "height": bounds.size.y},
		"target_pixel_size": {"width": ceili(bounds.size.x * pixels_per_world_unit), "height": ceili(bounds.size.y * pixels_per_world_unit)},
		"notes": notes,
	}


func _draw() -> void:
	if not Engine.is_editor_hint() or polygon.is_empty():
		return
	draw_polyline(polygon, Color(1.0, 0.55, 0.9, 0.95), 5.0, true)
	if not show_measurements:
		return
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	var target := Vector2i(ceil(bounds.size.x * pixels_per_world_unit), ceil(bounds.size.y * pixels_per_world_unit))
	var heading := "%s  |  %.0f x %.0f wu  |  %d x %d px" % [section_name, bounds.size.x, bounds.size.y, target.x, target.y]
	draw_string(ThemeDB.fallback_font, bounds.position + Vector2(12.0, 30.0), heading, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(1.0, 0.82, 0.96, 1.0))
