extends Node

const TILE_SET := preload("res://Src/Environment/BlueBiome/ArtPlaceables/Ground/blue_ground_art_tileset.tres")
const ATLAS_SIZE := Vector2i(512, 650)
const TILE_SIZE := Vector2i(128, 128)
const CHAMBER_TEMPLATE := preload("res://Assets/chamber_of_first_weave/Tiles/cotfw_chamber_tileset_256_current.tres")


func _ready() -> void:
	assert(TILE_SET.tile_size == TILE_SIZE)
	assert(TILE_SET.has_source(0))
	var atlas := TILE_SET.get_source(0) as TileSetAtlasSource
	assert(atlas != null)
	assert(atlas.texture != null)
	assert(Vector2i(atlas.texture.get_size()) == ATLAS_SIZE)
	assert(atlas.texture_region_size == TILE_SIZE)
	var chamber_atlas := CHAMBER_TEMPLATE.get_source(0) as TileSetAtlasSource
	assert(chamber_atlas != null)
	assert(atlas.get_tiles_count() == chamber_atlas.get_tiles_count())
	for index in range(chamber_atlas.get_tiles_count()):
		var coordinates := chamber_atlas.get_tile_id(index)
		assert(atlas.has_tile(coordinates))
	assert(TILE_SET.get_terrain_sets_count() == 1)
	assert(TILE_SET.get_terrains_count(0) == 1)
	var image := atlas.texture.get_image()
	assert(image.detect_alpha() != Image.ALPHA_NONE)
	print("BLUE_GROUND_TILES_VERIFY_OK")
	get_tree().quit()
