extends Node

const ROOM_PATHS := [
	"res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_chamber_exit_rooftops.tscn",
	"res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_village.tscn",
	"res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lower_shore.tscn",
	"res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_peasant_fields.tscn",
	"res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_irrigation_channel.tscn",
	"res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_hidden_cistern.tscn",
	"res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_shrine_approach.tscn",
	"res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_old_shrine.tscn",
	"res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_hermits_lake.tscn",
	"res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_waterfall_ascent.tscn",
]
const OVERVIEW := preload("res://Src/Environment/BlueBiome/Prototypes/blue_biome_greybox_overview.tscn")


func _ready() -> void:
	var room_ids: Dictionary = {}
	for path in ROOM_PATHS:
		var packed := load(path) as PackedScene
		assert(packed != null, "Could not load %s" % path)
		var room := packed.instantiate() as BlueGreyboxRoom2D
		assert(room != null)
		assert(not String(room.room_id).is_empty())
		assert(not room_ids.has(room.room_id), "Duplicate room ID: %s" % room.room_id)
		room_ids[room.room_id] = true
		assert(room.get_node("Geometry/GreyboxTerrain") is TileMapLayer)
		assert(room.get_node("WaterVolumes") is Node2D)
		assert(room.get_node("Hazards") is Node2D)
		assert(room.get_node("Player") != null)
		room.call("_sync_reference")
		var reference := room.get_node("MacroReference") as BlueMacroReference2D
		assert(reference.source_focus == room.macro_focus)
		assert(reference.map_scale == 12.0)
		room.free()

	var overview := OVERVIEW.instantiate()
	assert(overview.get_node("Rooms").get_child_count() == ROOM_PATHS.size())
	assert((overview.get_node("MacroReference") as BlueMacroReference2D).map_scale == 12.0)
	overview.free()
	print("BLUE_GREYBOX_ROOMS_VERIFY_OK")
	get_tree().quit()
