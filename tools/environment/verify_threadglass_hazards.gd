extends Node

const HAZARDS := [
	preload("res://Src/Environment/BlueBiome/Hazards/threadglass_floor_bed.tscn"),
	preload("res://Src/Environment/BlueBiome/Hazards/threadglass_wall_cluster.tscn"),
	preload("res://Src/Environment/BlueBiome/Hazards/threadglass_hanging_cluster.tscn"),
	preload("res://Src/Environment/BlueBiome/Hazards/threadglass_waterline_reeds.tscn"),
	preload("res://Src/Environment/BlueBiome/Hazards/threadglass_pogo_crown.tscn"),
]


func _ready() -> void:
	for packed in HAZARDS:
		var hazard := packed.instantiate() as GreyboxHazard2D
		add_child(hazard)
		assert(hazard != null)
		assert(not hazard.debug_draw_enabled)
		var artwork := hazard.get_node_or_null("Artwork") as Sprite2D
		assert(artwork != null)
		assert(artwork.material is ShaderMaterial)
		assert(hazard.get_node_or_null("PogoReceiver") is HurtboxComponent)
		assert(hazard.get_node("CollisionShape2D").shape is RectangleShape2D)
		assert((hazard.get_node("CollisionShape2D").shape as RectangleShape2D).size == hazard.size)
		if hazard.name == "ThreadglassWaterlineReeds":
			var atlas := artwork.texture as AtlasTexture
			assert(atlas != null)
			# Stop at the illustrated waterline: live water provides all pixels below it.
			assert(atlas.region.position.y + atlas.region.size.y <= 825.0)
		hazard.queue_free()
	print("THREADGLASS_HAZARDS_VERIFY_OK")
	get_tree().quit()
