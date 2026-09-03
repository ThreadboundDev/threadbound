@tool
extends Control

const SOLID := "res://Src/Environment/Greybox/greybox_block.tscn"
const WATER := "res://Src/Environment/Greybox/greybox_water.tscn"
const HAZARD := "res://Src/Environment/Greybox/greybox_hazard.tscn"
const SLOPE := "res://Src/Environment/Greybox/greybox_slope.tscn"
const MARKER := "res://Src/Environment/Greybox/greybox_marker.tscn"

var plugin: EditorPlugin
@onready var status: Label = %Status


func setup(owner_plugin: EditorPlugin) -> void:
	plugin = owner_plugin


func _ready() -> void:
	%TerrainTiles.pressed.connect(_select_or_add_terrain)
	%Solid.pressed.connect(_add.bind(SOLID, "LargeBlock", true, {}))
	%Water.pressed.connect(_add.bind(WATER, "Water", false, {}))
	%Hazard.pressed.connect(_add.bind(HAZARD, "SpikeHazard", false, {}))
	%SlopeLeft.pressed.connect(_add_gameplay.bind(SLOPE, "SlopeLeft", {"rises_right": false}))
	%SlopeRight.pressed.connect(_add_gameplay.bind(SLOPE, "SlopeRight", {"rises_right": true}))

	%RopeBridge.pressed.connect(_annotation.bind("Rope Bridge", "Structure", "One-way", "Gameplay Edge", "Span", Vector2(640, 96), Color(0.24, 0.88, 1.0, 0.2), "Suspended bridge spanning this region."))
	%PlatformShort.pressed.connect(_annotation.bind("Short Platform", "Surface", "One-way", "Gameplay Edge", "Floor", Vector2(256, 72), Color(0.3, 0.9, 1.0, 0.2), "Short traversable platform."))
	%PlatformLong.pressed.connect(_annotation.bind("Long Platform", "Surface", "One-way", "Gameplay Edge", "Floor", Vector2(512, 72), Color(0.3, 0.9, 1.0, 0.2), "Long traversable platform."))
	%BuildingBase.pressed.connect(_annotation.bind("Building Base", "Structure", "Solid", "Gameplay Backing", "Floor", Vector2(512, 288), Color(0.95, 0.68, 0.25, 0.2), "Lower structural mass and entrances."))
	%BuildingMiddle.pressed.connect(_annotation.bind("Building Middle", "Structure", "None", "Gameplay Backing", "Unspecified", Vector2(512, 288), Color(0.95, 0.72, 0.3, 0.2), "Middle building layer behind gameplay."))
	%BuildingTop.pressed.connect(_annotation.bind("Building Rooftop", "Structure", "One-way", "Gameplay Edge", "Floor", Vector2(512, 160), Color(1.0, 0.78, 0.32, 0.2), "Playable building top or roofline."))
	%Pavilion.pressed.connect(_annotation.bind("Open Pavilion", "Structure", "None", "Gameplay Backing", "Unspecified", Vector2(512, 320), Color(1.0, 0.7, 0.3, 0.2), "Open pavilion structure; preserve sightlines through it."))
	%StoneGround.pressed.connect(_annotation.bind("Stone Ground Treatment", "Surface", "Solid", "Gameplay Edge", "Floor", Vector2(512, 128), Color(0.55, 0.68, 0.82, 0.2), "Painted stone surface treatment over base terrain."))
	%Vegetation.pressed.connect(_annotation.bind("Vegetation", "Vegetation", "None", "Near", "Floor", Vector2(384, 192), Color(0.35, 1.0, 0.48, 0.2), "Grass, flowers, shrubs, or trees. Describe varieties in Notes."))
	%Foreground.pressed.connect(_annotation.bind("Foreground Silhouette", "Atmosphere", "None", "Foreground", "Unspecified", Vector2(512, 320), Color(0.58, 0.48, 1.0, 0.2), "Dark framing art that may overlap the camera edge."))
	%ThreadglassFloor.pressed.connect(_annotation.bind("Threadglass Floor Hazard", "Hazard", "Hazard", "Gameplay Edge", "Floor", Vector2(384, 96), Color(1.0, 0.2, 0.2, 0.22), "Regional hazard skin over a tested greybox spike volume."))
	%ThreadglassWall.pressed.connect(_annotation.bind("Threadglass Wall Hazard", "Hazard", "Hazard", "Gameplay Edge", "Wall Left", Vector2(96, 384), Color(1.0, 0.2, 0.2, 0.22), "Regional hazard attached to a wall."))
	%ThreadglassCeiling.pressed.connect(_annotation.bind("Threadglass Ceiling Hazard", "Hazard", "Hazard", "Gameplay Edge", "Ceiling", Vector2(384, 96), Color(1.0, 0.2, 0.2, 0.22), "Hanging regional hazard."))
	%ThreadglassWater.pressed.connect(_annotation.bind("Threadglass Waterline Hazard", "Hazard", "Hazard", "Gameplay Edge", "Floor", Vector2(384, 112), Color(1.0, 0.2, 0.2, 0.22), "Hazard reeds at the waterline; water remains a separate live volume."))
	%CustomArea.pressed.connect(_annotation.bind("Custom Annotation", "General", "None", "Gameplay Backing", "Unspecified", Vector2(384, 192), Color(0.95, 0.95, 1.0, 0.18), "Describe the intended artwork or gameplay purpose here."))

	%PlayerStart.pressed.connect(_add_marker.bind("Player Start", Color(0.25, 1.0, 0.45, 0.9)))
	%Exit.pressed.connect(_add_marker.bind("Room Exit", Color(0.75, 0.35, 1.0, 0.9)))
	%Enemy.pressed.connect(_add_marker.bind("Enemy", Color(1.0, 0.45, 0.2, 0.9)))
	%Grapple.pressed.connect(_add_marker.bind("Grapple", Color(0.2, 0.9, 1.0, 0.9)))
	%Note.pressed.connect(_add_marker.bind("Note", Color(1.0, 1.0, 1.0, 0.9)))
	%CollisionStrong.pressed.connect(_set_collision_preview.bind(1.0))
	%CollisionFaint.pressed.connect(_set_collision_preview.bind(0.18))


func _select_or_add_terrain() -> void:
	plugin.call("select_or_add_terrain_layer")


func _add(path: String, node_name: String, snap: bool, properties: Dictionary) -> void:
	plugin.call("add_greybox_scene", path, node_name, snap)
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() != 1:
		return
	for property_name in properties:
		selected[0].set(property_name, properties[property_name])


func _add_marker(label_text: String, color: Color) -> void:
	_add(MARKER, label_text.replace(" ", ""), true, {"label_text": label_text, "marker_color": color})


func _add_gameplay(path: String, node_name: String, properties: Dictionary) -> void:
	plugin.call("add_gameplay_scene", path, node_name, properties)


func _annotation(
	title: String,
	category: String,
	collision: String,
	layer: String,
	orientation: String,
	size: Vector2,
	color: Color,
	notes: String
) -> void:
	plugin.call("add_annotation_area", {
		"title": title,
		"category": category,
		"intended_collision": collision,
		"art_layer": layer,
		"orientation": orientation,
		"size": size,
		"annotation_color": color,
		"notes": notes,
	})


func _set_collision_preview(alpha: float) -> void:
	plugin.call("set_greybox_preview_alpha", alpha)


func set_status(message: String, is_error: bool) -> void:
	status.text = message
	status.modulate = Color(1.0, 0.55, 0.55) if is_error else Color(0.75, 0.9, 1.0)
