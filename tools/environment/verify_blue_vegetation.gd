extends Node

const VEGETATION := [
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/blue_grass_short_01.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/blue_grass_wind_01.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/blue_grass_fountain_01.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/blue_flower_ground_pink_01.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/blue_flower_wild_pink_01.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/blue_flower_bell_pink_01.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/blue_tree_cherry_young_01.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/blue_tree_cherry_mature_01.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Vegetation/blue_tree_willow_01.tscn"),
]


func _ready() -> void:
	for packed: PackedScene in VEGETATION:
		var plant := packed.instantiate() as Node2D
		assert(plant != null)
		var artwork := plant.get_node("Artwork") as Sprite2D
		assert(artwork != null)
		assert(artwork.texture != null)
		assert(artwork.texture.get_width() >= 1024)
		assert(artwork.texture.get_height() >= 1000)
		assert(artwork.material is ShaderMaterial)
		var displayed_height := artwork.texture.get_height() * artwork.scale.y
		assert(is_equal_approx(artwork.position.y, -displayed_height * 0.5))
		add_child(plant)
		plant.queue_free()
	print("BLUE_VEGETATION_VERIFY_OK")
	get_tree().quit()
