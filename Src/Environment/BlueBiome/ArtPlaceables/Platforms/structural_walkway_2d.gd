@tool
extends "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/walkway_stamp_2d.gd"
## Convenience assembly of independent painted parts. Physics stays in the room.
enum Structure { PONTOON, BRACED }
@export var structure: Structure = Structure.PONTOON
@export var waterline_offset := 27.0
@export var support_anchor := Vector2(-50,240)
@export var rock_inset_left := 0.0
@export var rock_inset_right := 0.0
@export var rear_rail_visible := true
@export var front_rail_visible := true
@export var floats_visible := true
@export var braces_visible := true
@export_range(.1,.5,.01) var rail_detail_scale := .32
@export_range(0.0,.8,.05) var front_center_opening := .50
@export var front_rail_offset := Vector2(0,12)
var _signature := 0
func _ready() -> void: _sync_parts()
func _process(_delta: float) -> void: _sync_parts()
func exposed_span() -> Vector2:
	return Vector2(minf(rock_inset_left,span_width),maxf(rock_inset_left,span_width-rock_inset_right))
func _draw() -> void:
	# Components own their drawing, including separately layered front rails.
	pass
func _sync_parts() -> void:
	if not has_node("Deck"): return
	var signature := hash([structure,stamp,span_width,detail_scale,waterline_offset,support_anchor,rock_inset_left,rock_inset_right,rear_rail_visible,front_rail_visible,floats_visible,braces_visible,rail_detail_scale,front_center_opening,front_rail_offset])
	if signature == _signature: return
	_signature = signature
	for label in ["Deck","RearRail","FrontRail","PontoonFloats","SupportBraces"]:
		var part = get_node(label)
		part.span_width = span_width
		part.detail_scale = rail_detail_scale if label in ["RearRail","FrontRail"] else detail_scale
		part.stamp = Stamp.RAILED_VERANDA if label in ["RearRail","FrontRail"] else stamp
		part.rock_inset_left = rock_inset_left
		part.rock_inset_right = rock_inset_right
		part.waterline_offset = waterline_offset
		part.support_anchor = support_anchor
	$RearRail.visible = rear_rail_visible
	$FrontRail.visible = front_rail_visible
	$FrontRail.open_center = front_center_opening
	$FrontRail.position = front_rail_offset
	$PontoonFloats.visible = floats_visible and structure == Structure.PONTOON
	$SupportBraces.visible = braces_visible and structure == Structure.BRACED
func _get_configuration_warnings() -> PackedStringArray:
	if structure == Structure.BRACED and support_anchor.y <= 15:
		return ["Place Support Anchor below the deck, inside supporting rock/building."]
	return []
