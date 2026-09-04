@tool
extends Control

const SOLID := "res://Src/Environment/Greybox/greybox_block.tscn"
const WATER := "res://Src/Environment/Greybox/greybox_water.tscn"
const HAZARD := "res://Src/Environment/Greybox/greybox_hazard.tscn"
const BUMPER := "res://Src/Environment/Greybox/greybox_bumper.tscn"

var plugin: EditorPlugin
@onready var status: Label = %Status


func setup(owner_plugin: EditorPlugin) -> void:
	plugin = owner_plugin


func _ready() -> void:
	%TerrainTiles.pressed.connect(_select_or_add_terrain)
	%Solid.pressed.connect(_add.bind(SOLID, "LargeBlock", true, {}))
	%OneWay.pressed.connect(_add.bind(SOLID, "OneWayBlock", true, {"one_way": true}))
	%Water.pressed.connect(_add.bind(WATER, "Water", false, {}))
	%Hazard.pressed.connect(_add.bind(HAZARD, "SpikeHazard", false, {}))
	%WaterBulb.pressed.connect(_add.bind(BUMPER, "WaterBulb", false, {}))


func _select_or_add_terrain() -> void:
	plugin.call("select_or_add_terrain_layer")


func _add(path: String, node_name: String, snap: bool, properties: Dictionary) -> void:
	plugin.call("add_greybox_scene", path, node_name, snap)
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() != 1:
		return
	for property_name in properties:
		selected[0].set(property_name, properties[property_name])


func set_status(message: String, is_error: bool) -> void:
	status.text = message
	status.modulate = Color(1.0, 0.55, 0.55) if is_error else Color(0.75, 0.9, 1.0)
