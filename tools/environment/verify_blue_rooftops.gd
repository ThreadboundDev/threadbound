extends Node

const ROOFTOPS := [
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Rooftops/blue_rooftop_short_01.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Rooftops/blue_rooftop_medium_01.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Rooftops/blue_rooftop_long_01.tscn"),
]
const EXPECTED_SPANS := [320.0, 640.0, 960.0]


func _ready() -> void:
	for index in range(ROOFTOPS.size()):
		var rooftop := (ROOFTOPS[index] as PackedScene).instantiate() as Node2D
		assert(rooftop != null)
		assert(float(rooftop.get_meta("module_span")) == EXPECTED_SPANS[index])
		var artwork := rooftop.get_node("Artwork") as Sprite2D
		assert(artwork.texture != null)
		assert(artwork.texture.get_width() >= 1900)
		assert(artwork.texture.get_image().detect_alpha() != Image.ALPHA_NONE)
		var landing := rooftop.get_node("OneWayLandingSurface/CollisionShape2D") as CollisionShape2D
		assert(landing.one_way_collision)
		assert(landing.shape is RectangleShape2D)
		var edges := rooftop.get_node("ClimbableEdges") as StaticBody2D
		assert(edges.collision_layer == 1)
		assert(edges.get_child_count() == 2)
		var grapple := rooftop.get_node("GrappleTarget") as Area2D
		assert(grapple.collision_layer == 4)
		var grapple_shape := grapple.get_node("CollisionShape2D").shape as RectangleShape2D
		assert(is_equal_approx(grapple_shape.size.x, EXPECTED_SPANS[index]))
		add_child(rooftop)
		rooftop.queue_free()
	print("BLUE_ROOFTOPS_VERIFY_OK")
	get_tree().quit()

