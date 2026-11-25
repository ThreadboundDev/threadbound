@tool
extends TileMapLayer

const GROUND_ART_SOURCE_ID := 0

@export var collision_source_path := NodePath("../../Geometry/GreyboxTerrain")
@export var rebuild_when_empty := true:
	set(value):
		rebuild_when_empty = value
		if value and is_inside_tree():
			call_deferred("rebuild_from_collision")


func _ready() -> void:
	if rebuild_when_empty and get_used_cells().is_empty():
		call_deferred("rebuild_from_collision")


func rebuild_from_collision() -> void:
	var terrain := get_node_or_null(collision_source_path) as TileMapLayer
	if terrain == null:
		return
	clear()
	for cell in terrain.get_used_cells():
		var collision_source := terrain.get_cell_source_id(cell)
		if collision_source < 0:
			continue
		set_cell(cell, GROUND_ART_SOURCE_ID, _atlas_cell_for(terrain, cell, collision_source), 0)


func _atlas_cell_for(terrain: TileMapLayer, cell: Vector2i, collision_source: int) -> Vector2i:
	var has_left := terrain.get_cell_source_id(cell + Vector2i.LEFT) >= 0
	var has_right := terrain.get_cell_source_id(cell + Vector2i.RIGHT) >= 0
	if collision_source == 1:
		# One-way platforms use the straight floor art until dedicated caps exist.
		return Vector2i(1, 0)
	var has_above := terrain.get_cell_source_id(cell + Vector2i.UP) >= 0
	var has_below := terrain.get_cell_source_id(cell + Vector2i.DOWN) >= 0
	var column := 0 if not has_left else (2 if not has_right else 1)
	var row := 0 if not has_above else (2 if not has_below else 1)
	return Vector2i(column, row)
