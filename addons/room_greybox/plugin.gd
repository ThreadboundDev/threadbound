@tool
extends EditorPlugin

const DOCK_SCENE := preload("res://addons/room_greybox/room_greybox_dock.tscn")
const TILE_LAYER_SCENE := preload("res://Src/Environment/Greybox/greybox_tile_layer.tscn")
const ANNOTATION_AREA_SCENE := preload("res://Src/Environment/Greybox/greybox_annotation_area.tscn")
const GROUND_ART_LAYER_SCENE := preload("res://Src/Environment/BlueBiome/ArtPlaceables/Ground/blue_ground_art_layer.tscn")
const GROUND_ART_SOURCE_ID := 1

var dock: Control


func _enter_tree() -> void:
	dock = DOCK_SCENE.instantiate()
	dock.call("setup", self)
	add_control_to_bottom_panel(dock, "Room Greybox")


func _exit_tree() -> void:
	if is_instance_valid(dock):
		remove_control_from_bottom_panel(dock)
		dock.queue_free()


func add_greybox_scene(scene_path: String, base_name: String, snap_to_grid: bool) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		dock.call("set_status", "Open or create a 2D scene first.", true)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		dock.call("set_status", "Could not load %s" % scene_path, true)
		return
	var instance := packed.instantiate()
	instance.name = _unique_child_name(root, base_name)
	var parent := _preferred_parent(root)
	parent.add_child(instance)
	instance.owner = root
	if instance is Node2D:
		var position := _placement_position(root, parent)
		if snap_to_grid:
			position = position.snapped(Vector2(128.0, 128.0))
		(instance as Node2D).position = position
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(instance)
	dock.call("set_status", "Added %s. Move/resize it in the inspector." % instance.name, false)


func add_art_scene(scene_path: String, base_name: String) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		dock.call("set_status", "Open or create a 2D scene first.", true)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		dock.call("set_status", "Could not load %s" % scene_path, true)
		return
	var art_parent := root.find_child("ArtPlaceables", false, false) as Node2D
	if art_parent == null:
		art_parent = Node2D.new()
		art_parent.name = "ArtPlaceables"
		root.add_child(art_parent)
		art_parent.owner = root
	var instance := packed.instantiate() as Node2D
	instance.name = _unique_child_name(art_parent, base_name)
	art_parent.add_child(instance)
	instance.owner = root
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() == 1 and selected[0] is Node2D:
		instance.global_position = (selected[0] as Node2D).global_position
	_select_node(instance)
	dock.call("set_status", "Added collision-free %s. Position, scale, flip, and layer it freely." % instance.name, false)


func add_gameplay_scene(scene_path: String, base_name: String, properties: Dictionary) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		dock.call("set_status", "Open or create a 2D scene first.", true)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		dock.call("set_status", "Could not load %s" % scene_path, true)
		return
	var geometry_parent := root.find_child("Geometry", false, false) as Node2D
	if geometry_parent == null:
		geometry_parent = Node2D.new()
		geometry_parent.name = "Geometry"
		root.add_child(geometry_parent)
		geometry_parent.owner = root
	var instance := packed.instantiate() as Node2D
	instance.name = _unique_child_name(geometry_parent, base_name)
	geometry_parent.add_child(instance)
	instance.owner = root
	for property_name in properties:
		instance.set(property_name, properties[property_name])
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() == 1 and selected[0] is Node2D:
		instance.global_position = (selected[0] as Node2D).global_position
	_select_node(instance)
	dock.call("set_status", "Added playable %s. Its artwork and collision share one movable root." % instance.name, false)


func add_annotation_area(properties: Dictionary) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		dock.call("set_status", "Open or create a 2D scene first.", true)
		return
	var annotation_parent := root.find_child("Annotations", false, false) as Node2D
	if annotation_parent == null:
		annotation_parent = Node2D.new()
		annotation_parent.name = "Annotations"
		root.add_child(annotation_parent)
		annotation_parent.owner = root
	var selected := EditorInterface.get_selection().get_selected_nodes()
	var annotation := ANNOTATION_AREA_SCENE.instantiate() as GreyboxAnnotationArea2D
	var title := str(properties.get("title", "Annotation"))
	annotation.name = _unique_child_name(annotation_parent, title.replace(" ", ""))
	annotation_parent.add_child(annotation)
	annotation.owner = root
	for property_name in properties:
		annotation.set(property_name, properties[property_name])
	if selected.size() == 1 and selected[0] is Node2D:
		annotation.global_position = (selected[0] as Node2D).global_position
	_select_node(annotation)
	dock.call(
		"set_status",
		"Added %s annotation. Resize it and edit its title, intent, layer, orientation, or notes in the Inspector." % title,
		false
	)


func set_greybox_preview_alpha(alpha: float) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		dock.call("set_status", "Open or create a 2D scene first.", true)
		return
	var targets: Array[CanvasItem] = []
	_collect_greybox_visuals(root, targets)
	if targets.is_empty():
		dock.call("set_status", "No greybox terrain or large blocks found.", true)
		return
	var undo := get_undo_redo()
	undo.create_action("Set greybox preview opacity")
	for target in targets:
		var old_color := target.self_modulate
		var new_color := old_color
		new_color.a = alpha
		undo.add_do_property(target, "self_modulate", new_color)
		undo.add_undo_property(target, "self_modulate", old_color)
	undo.commit_action()
	dock.call("set_status", "Greybox preview opacity set to %d%%. Collision is unchanged." % roundi(alpha * 100.0), false)


func _collect_greybox_visuals(node: Node, targets: Array[CanvasItem]) -> void:
	if node is TileMapLayer and node.name == "GreyboxTerrain":
		targets.append(node as CanvasItem)
	elif node is GreyboxBlock2D:
		targets.append(node as CanvasItem)
	for child in node.get_children():
		_collect_greybox_visuals(child, targets)


func select_or_add_terrain_layer() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		dock.call("set_status", "Open or create a 2D scene first.", true)
		return
	var existing := root.find_child("GreyboxTerrain", true, false) as TileMapLayer
	if existing != null:
		_select_node(existing)
		dock.call("set_status", "Terrain layer selected. Paint dark-grey tiles with the TileMap palette.", false)
		return
	var layer := TILE_LAYER_SCENE.instantiate() as TileMapLayer
	var parent := _preferred_parent(root)
	parent.add_child(layer)
	layer.owner = root
	_select_node(layer)
	dock.call("set_status", "Terrain layer created. Choose a tile below and paint in the 2D view.", false)


func select_or_add_ground_art_layer() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		dock.call("set_status", "Open or create a 2D scene first.", true)
		return
	var layer := _get_or_create_ground_art(root)
	_select_node(layer)
	dock.call("set_status", "Ground art selected. It is decorative only; collision remains on GreyboxTerrain.", false)


func generate_ground_art_from_collision() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		dock.call("set_status", "Open or create a 2D scene first.", true)
		return
	var terrain := root.find_child("GreyboxTerrain", true, false) as TileMapLayer
	if terrain == null:
		dock.call("set_status", "Create or select GreyboxTerrain first.", true)
		return
	var layer := _get_or_create_ground_art(root)
	layer.clear()
	var painted := 0
	for cell in terrain.get_used_cells():
		var collision_source := terrain.get_cell_source_id(cell)
		if collision_source < 0:
			continue
		layer.set_cell(cell, GROUND_ART_SOURCE_ID, _ground_art_atlas_cell(terrain, cell, collision_source), 0)
		painted += 1
	_select_node(layer)
	dock.call("set_status", "Generated %d varied ground-art tiles. Edit or repaint them freely; physics is unchanged." % painted, false)


func _ground_art_atlas_cell(terrain: TileMapLayer, cell: Vector2i, collision_source: int) -> Vector2i:
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


func _get_or_create_ground_art(root: Node) -> TileMapLayer:
	var existing := root.find_child("BlueGroundArt", true, false) as TileMapLayer
	if existing != null:
		return existing
	var art_parent := root.find_child("ArtPlaceables", false, false) as Node2D
	if art_parent == null:
		art_parent = Node2D.new()
		art_parent.name = "ArtPlaceables"
		root.add_child(art_parent)
		art_parent.owner = root
	var layer := GROUND_ART_LAYER_SCENE.instantiate() as TileMapLayer
	art_parent.add_child(layer)
	layer.owner = root
	return layer


func _select_node(node: Node) -> void:
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(node)
	EditorInterface.edit_node(node)


func _preferred_parent(root: Node) -> Node:
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() == 1 and selected[0] is Node2D:
		var selected_node := selected[0] as Node2D
		if (
			selected_node is GreyboxBlock2D
			or selected_node is GreyboxWater2D
			or selected_node is GreyboxHazard2D
			or selected_node is GreyboxMarker2D
			or selected_node is GreyboxAnnotationArea2D
			or selected_node is TileMapLayer
		):
			return selected_node.get_parent()
		return selected_node
	return root


func _placement_position(root: Node, parent: Node) -> Vector2:
	if parent != root and parent is Node2D:
		return Vector2(256.0, 0.0)
	return Vector2.ZERO


func _unique_child_name(parent: Node, base_name: String) -> String:
	var candidate := base_name
	var suffix := 2
	while parent.has_node(NodePath(candidate)):
		candidate = "%s%d" % [base_name, suffix]
		suffix += 1
	return candidate
