@tool
extends Control

const SOLID := "res://Src/Environment/Greybox/greybox_block.tscn"
const WATER := "res://Src/Environment/Greybox/greybox_water.tscn"
const HAZARD := "res://Src/Environment/Greybox/greybox_hazard.tscn"
const SLOPE := "res://Src/Environment/Greybox/greybox_slope.tscn"
const MARKER := "res://Src/Environment/Greybox/greybox_marker.tscn"
const ART_WIDE_HOUSE := "res://Src/Environment/BlueBiome/ArtPlaceables/Buildings/building_wide_house.tscn"
const ART_TOWER_HOUSE := "res://Src/Environment/BlueBiome/ArtPlaceables/Buildings/building_tower_house.tscn"
const ART_STILT_HOUSE := "res://Src/Environment/BlueBiome/ArtPlaceables/Buildings/building_stilt_house.tscn"
const ART_PAVILION := "res://Src/Environment/BlueBiome/ArtPlaceables/Buildings/building_open_pavilion.tscn"
const ART_ROOF_MEDIUM := "res://Src/Environment/BlueBiome/ArtPlaceables/Surfaces/surface_roof_medium.tscn"
const ART_ROOF_LONG := "res://Src/Environment/BlueBiome/ArtPlaceables/Surfaces/surface_roof_long.tscn"
const ART_STONE := "res://Src/Environment/BlueBiome/ArtPlaceables/Surfaces/surface_stone_ground.tscn"
const ART_GRASS := "res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/vegetation_grass_strip.tscn"
const ART_CHERRY := "res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/vegetation_cherry_wind.tscn"
const ART_CHERRY_SHRUB := "res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/vegetation_cherry_shrub.tscn"
const WOOD_PLATFORM_SHORT := "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/wood_platform_short.tscn"
const WOOD_PLATFORM_LONG := "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/wood_platform_long.tscn"
const ART_RAILING := "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/platform_railing.tscn"
const ART_POSTS := "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/platform_posts.tscn"
const ART_BRACE := "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/platform_brace.tscn"
const ART_ROPE_BRIDGE := "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/platform_rope_bridge.tscn"
const ART_CLOTH := "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/platform_cloth.tscn"
const ART_FOREGROUND_FRAME := "res://Src/Environment/BlueBiome/ArtPlaceables/Platforms/house_foreground_frame.tscn"
const THREADGLASS_FLOOR := "res://Src/Environment/BlueBiome/Hazards/threadglass_floor_bed.tscn"
const THREADGLASS_WALL := "res://Src/Environment/BlueBiome/Hazards/threadglass_wall_cluster.tscn"
const THREADGLASS_HANGING := "res://Src/Environment/BlueBiome/Hazards/threadglass_hanging_cluster.tscn"
const THREADGLASS_WATER := "res://Src/Environment/BlueBiome/Hazards/threadglass_waterline_reeds.tscn"
const THREADGLASS_POGO := "res://Src/Environment/BlueBiome/Hazards/threadglass_pogo_crown.tscn"

var plugin: EditorPlugin
@onready var status: Label = %Status


func setup(owner_plugin: EditorPlugin) -> void:
	plugin = owner_plugin


func _ready() -> void:
	%TerrainTiles.pressed.connect(_select_or_add_terrain)
	%Solid.pressed.connect(_add.bind(SOLID, "LargeBlock", true, {}))
	%Water.pressed.connect(_add.bind(WATER, "Water", false, {}))
	%Hazard.pressed.connect(_add.bind(HAZARD, "Hazard", false, {}))
	%SlopeLeft.pressed.connect(_add_gameplay.bind(SLOPE, "SlopeLeft", {"rises_right": false}))
	%SlopeRight.pressed.connect(_add_gameplay.bind(SLOPE, "SlopeRight", {"rises_right": true}))
	%GroundArt.pressed.connect(_select_or_add_ground_art)
	%GenerateGroundArt.pressed.connect(_generate_ground_art)
	%PlatformShort.pressed.connect(_add_gameplay.bind(WOOD_PLATFORM_SHORT, "WoodPlatformShort", {}))
	%PlatformLong.pressed.connect(_add_gameplay.bind(WOOD_PLATFORM_LONG, "WoodPlatformLong", {}))
	%ThreadglassFloor.pressed.connect(_add_gameplay.bind(THREADGLASS_FLOOR, "ThreadglassFloor", {}))
	%ThreadglassWall.pressed.connect(_add_gameplay.bind(THREADGLASS_WALL, "ThreadglassWall", {}))
	%ThreadglassHanging.pressed.connect(_add_gameplay.bind(THREADGLASS_HANGING, "ThreadglassHanging", {}))
	%ThreadglassWater.pressed.connect(_add_gameplay.bind(THREADGLASS_WATER, "ThreadglassWater", {}))
	%ThreadglassPogo.pressed.connect(_add_gameplay.bind(THREADGLASS_POGO, "ThreadglassPogo", {}))
	%PlayerStart.pressed.connect(_add_marker.bind("Player Start", Color(0.25, 1.0, 0.45, 0.9)))
	%Exit.pressed.connect(_add_marker.bind("Room Exit", Color(0.75, 0.35, 1.0, 0.9)))
	%Enemy.pressed.connect(_add_marker.bind("Enemy", Color(1.0, 0.45, 0.2, 0.9)))
	%Grapple.pressed.connect(_add_marker.bind("Grapple", Color(0.2, 0.9, 1.0, 0.9)))
	%Annotation.pressed.connect(_add_marker.bind("Annotation", Color(1.0, 1.0, 1.0, 0.9)))
	%WideHouse.pressed.connect(_add_art.bind(ART_WIDE_HOUSE, "WideHouse"))
	%TowerHouse.pressed.connect(_add_art.bind(ART_TOWER_HOUSE, "TowerHouse"))
	%StiltHouse.pressed.connect(_add_art.bind(ART_STILT_HOUSE, "StiltHouse"))
	%Pavilion.pressed.connect(_add_art.bind(ART_PAVILION, "Pavilion"))
	%RoofMedium.pressed.connect(_add_art.bind(ART_ROOF_MEDIUM, "RoofMedium"))
	%RoofLong.pressed.connect(_add_art.bind(ART_ROOF_LONG, "RoofLong"))
	%StoneGround.pressed.connect(_add_art.bind(ART_STONE, "StoneGround"))
	%Grass.pressed.connect(_add_art.bind(ART_GRASS, "Grass"))
	%Cherry.pressed.connect(_add_art.bind(ART_CHERRY, "CherryTree"))
	%CherryShrub.pressed.connect(_add_art.bind(ART_CHERRY_SHRUB, "CherryShrub"))
	%Railing.pressed.connect(_add_art.bind(ART_RAILING, "Railing"))
	%Posts.pressed.connect(_add_art.bind(ART_POSTS, "Posts"))
	%Brace.pressed.connect(_add_art.bind(ART_BRACE, "Brace"))
	%RopeBridge.pressed.connect(_add_art.bind(ART_ROPE_BRIDGE, "RopeBridgeArt"))
	%Cloth.pressed.connect(_add_art.bind(ART_CLOTH, "Cloth"))
	%ForegroundFrame.pressed.connect(_add_art.bind(ART_FOREGROUND_FRAME, "ForegroundFrame"))
	%CollisionStrong.pressed.connect(_set_collision_preview.bind(1.0))
	%CollisionFaint.pressed.connect(_set_collision_preview.bind(0.18))


func _select_or_add_terrain() -> void:
	plugin.call("select_or_add_terrain_layer")


func _select_or_add_ground_art() -> void:
	plugin.call("select_or_add_ground_art_layer")


func _generate_ground_art() -> void:
	plugin.call("generate_ground_art_from_collision")


func _add(path: String, node_name: String, snap: bool, properties: Dictionary) -> void:
	plugin.call("add_greybox_scene", path, node_name, snap)
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() != 1:
		return
	for property_name in properties:
		selected[0].set(property_name, properties[property_name])


func _add_marker(label_text: String, color: Color) -> void:
	_add(MARKER, label_text.replace(" ", ""), true, {"label_text": label_text, "marker_color": color})


func _add_art(path: String, node_name: String) -> void:
	plugin.call("add_art_scene", path, node_name)


func _add_gameplay(path: String, node_name: String, properties: Dictionary) -> void:
	plugin.call("add_gameplay_scene", path, node_name, properties)


func _set_collision_preview(alpha: float) -> void:
	plugin.call("set_greybox_preview_alpha", alpha)


func set_status(message: String, is_error: bool) -> void:
	status.text = message
	status.modulate = Color(1.0, 0.55, 0.55) if is_error else Color(0.75, 0.9, 1.0)
