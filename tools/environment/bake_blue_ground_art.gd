extends SceneTree

const DEFAULT_SCENE := "res://Src/Environment/BlueBiome/Production/blue_chamber_exit_production.tscn"
const GROUND_ART_SOURCE_ID := 1


func _initialize() -> void:
	var scene_path := DEFAULT_SCENE
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		scene_path = String(args[0])
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Could not load scene: %s" % scene_path)
		quit(1)
		return
	var root := packed.instantiate()
	var terrain := root.find_child("GreyboxTerrain", true, false) as TileMapLayer
	var art := root.find_child("BlueGroundArt", true, false) as TileMapLayer
	if terrain == null or art == null:
		push_error("Scene needs both GreyboxTerrain and BlueGroundArt")
		root.free()
		quit(2)
		return
	art.clear()
	var painted_cells := terrain.get_used_cells().size()
	for cell in terrain.get_used_cells():
		var collision_source := terrain.get_cell_source_id(cell)
		if collision_source < 0:
			continue
		art.set_cell(cell, GROUND_ART_SOURCE_ID, _atlas_cell_for(terrain, cell, collision_source), 0)
	art.collision_enabled = false
	var output := PackedScene.new()
	var pack_error := output.pack(root)
	if pack_error != OK:
		push_error("Could not pack scene: %s" % error_string(pack_error))
		root.free()
		quit(pack_error)
		return
	var save_error := ResourceSaver.save(output, scene_path)
	root.free()
	if save_error != OK:
		push_error("Could not save scene: %s" % error_string(save_error))
		quit(save_error)
		return
	print("Baked BlueGroundArt from %d collision cells into %s" % [painted_cells, scene_path])
	quit()


func _atlas_cell_for(terrain: TileMapLayer, cell: Vector2i, collision_source: int) -> Vector2i:
	var has_left := terrain.get_cell_source_id(cell + Vector2i.LEFT) >= 0
	var has_right := terrain.get_cell_source_id(cell + Vector2i.RIGHT) >= 0
	if collision_source == 1:
		if not has_left and not has_right:
			return Vector2i(3, 3)
		return Vector2i(0 if not has_left else (2 if not has_right else 1), 3)
	var has_above := terrain.get_cell_source_id(cell + Vector2i.UP) >= 0
	var has_below := terrain.get_cell_source_id(cell + Vector2i.DOWN) >= 0
	var column := 0 if not has_left else (2 if not has_right else 1)
	var row := 0 if not has_above else (2 if not has_below else 1)
	return Vector2i(column, row)
