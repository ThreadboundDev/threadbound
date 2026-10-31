@tool
extends Node2D
## Art only. Origin and WalkPlane mark the LEFT edge of the existing walking surface.
## Physics stays with the room; rails draw behind actors through this node's z_index.

enum Stamp { PLANK_CROSSING, RAILED_VERANDA, ENGAWA_BALCONY, BROKEN_TIMBER }

const PROFILES := [
	{"texture": preload("res://Assets/BlueBiome/Art/WalkwayStamps/B04_Simple_Plank_Crossing.png"), "walk_y": 126.0, "left": 260.0, "right": 1900.0},
	{"texture": preload("res://Assets/BlueBiome/Art/WalkwayStamps/J03_Japanese_Veranda.png"), "walk_y": 248.0, "left": 220.0, "right": 1946.0},
	{"texture": preload("res://Assets/BlueBiome/Art/WalkwayStamps/A04_Japanese_Engawa_Landing.png"), "walk_y": 445.0, "left": 500.0, "right": 1500.0},
	{"texture": preload("res://Assets/BlueBiome/Art/WalkwayStamps/J04_Matched_Broken_Bridge.png"), "walk_y": 230.0, "left": 0.0, "right": 0.0},
]

@export var stamp: Stamp = Stamp.PLANK_CROSSING:
	set(value):
		stamp = value
		queue_redraw()
@export_range(32.0, 4096.0, 1.0, "or_greater") var span_width := 512.0:
	set(value):
		span_width = maxf(32.0, value)
		queue_redraw()
@export_range(0.05, 1.0, 0.01) var detail_scale := 0.24:
	set(value):
		detail_scale = maxf(0.05, value)
		queue_redraw()

func source_texture() -> Texture2D:
	return PROFILES[stamp].texture

func get_draw_sections() -> Array[Dictionary]:
	return get_draw_sections_for(span_width,stamp,detail_scale)

func get_draw_sections_for(width: float, selected_stamp: int, sizing: float) -> Array[Dictionary]:
	var profile: Dictionary = PROFILES[selected_stamp]
	var size: Vector2 = profile.texture.get_size()
	var sections: Array[Dictionary] = []
	# A broken pair must keep its transparent gap and splintered ends. Fit it
	# uniformly as one image; never repeat the middle or imply a continuous floor.
	if selected_stamp == Stamp.BROKEN_TIMBER:
		var pair_scale := width / size.x
		sections.append({"source": Rect2(Vector2.ZERO, size), "target": Rect2(Vector2(0, -profile.walk_y * pair_scale), size * pair_scale)})
		return sections
	var left: float = profile.left
	var right: float = size.x - profile.right
	# Tiny spans shrink ALL details uniformly only when both end caps cannot fit.
	var unit := minf(sizing, width / (left + right))
	var y: float = -profile.walk_y * unit
	sections.append({"source": Rect2(0, 0, left, size.y), "target": Rect2(0, y, left * unit, size.y * unit)})
	var cursor := left * unit
	var end := width - right * unit
	while cursor < end - 0.0001:
		var pixels := minf(profile.right - left, (end - cursor) / unit)
		sections.append({"source": Rect2(left, 0, pixels, size.y), "target": Rect2(cursor, y, pixels * unit, size.y * unit)})
		cursor += pixels * unit
	sections.append({"source": Rect2(profile.right, 0, right, size.y), "target": Rect2(end, y, right * unit, size.y * unit)})
	return sections

func _draw() -> void:
	for section: Dictionary in get_draw_sections():
		draw_texture_rect_region(source_texture(), section.target, section.source)

func _get_configuration_warnings() -> PackedStringArray:
	if stamp == Stamp.BROKEN_TIMBER:
		return ["Art-only broken pair: author separate left/right colliders if placed. Never put continuous collision across the transparent gap."]
	return []
