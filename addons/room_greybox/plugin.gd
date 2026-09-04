@tool
extends EditorPlugin

const DOCK_SCENE := preload("res://addons/room_greybox/room_greybox_dock.tscn")
const TILE_LAYER_SCENE := preload("res://Src/Environment/Greybox/greybox_tile_layer.tscn")

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
	_select_node(instance)
	dock.call("set_status", "Added %s. Move and resize it in the Inspector." % instance.name, false)


func select_or_add_terrain_layer() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		dock.call("set_status", "Open or create a 2D scene first.", true)
		return
	var existing := root.find_child("GreyboxTerrain", true, false) as TileMapLayer
	if existing != null:
		_select_node(existing)
		dock.call("set_status", "Terrain selected. Paint solid or one-way tiles with the TileMap palette.", false)
		return
	var layer := TILE_LAYER_SCENE.instantiate() as TileMapLayer
	var parent := _preferred_parent(root)
	parent.add_child(layer)
	layer.owner = root
	_select_node(layer)
	dock.call("set_status", "Terrain created. Choose a solid or one-way tile and paint in the 2D view.", false)


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
			or selected_node is GreyboxPolygonWater2D
			or selected_node is GreyboxHazard2D
			or selected_node is GreyboxBumper2D
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
