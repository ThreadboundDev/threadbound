extends Node

const CLOUDS := [
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Background/Clouds/blue_cloud_broad.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Background/Clouds/blue_cloud_wisp.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Background/Clouds/blue_cloud_tower.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Background/Clouds/blue_cloud_low_bank.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Background/Clouds/blue_cloud_soft_bank.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Background/Clouds/blue_cloud_small.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Background/Clouds/blue_cloud_streak.tscn"),
	preload("res://Src/Environment/BlueBiome/ArtPlaceables/Background/Clouds/blue_cloud_puff.tscn"),
]
const ROOM := preload("res://Src/Environment/BlueBiome/Prototypes/Experiments/blue_chamber_exit_rooftops_codex_pass.tscn")

const EXPECTED_TEXTURES := [
	"blue_cloud_cell_01.png",
	"blue_cloud_cell_02.png",
	"blue_cloud_cell_04.png",
	"blue_cloud_cell_03.png",
	"blue_cloud_cell_05.png",
	"blue_cloud_cell_07.png",
	"blue_cloud_cell_11.png",
	"blue_cloud_cell_14.png",
]


func _ready() -> void:
	for index: int in CLOUDS.size():
		var packed: PackedScene = CLOUDS[index]
		var cloud := packed.instantiate() as BlueDriftingCloud2D
		assert(cloud != null)
		assert(not cloud.texture is AtlasTexture)
		assert(cloud.texture.get_size().is_equal_approx(Vector2(1024, 512)))
		assert(cloud.texture.resource_path.ends_with(EXPECTED_TEXTURES[index]))
		var used_rect := cloud.texture.get_image().get_used_rect()
		assert(used_rect.position.x > 0 and used_rect.position.y > 0)
		assert(used_rect.end.x < 1024 and used_rect.end.y < 512)
		assert(cloud.material is ShaderMaterial)
		add_child(cloud)
		var start := cloud.position
		cloud._process(1.0)
		assert(not is_equal_approx(cloud.position.x, start.x))
		cloud.queue_free()

	var room := ROOM.instantiate()
	var far_clouds := room.get_node("EnvironmentArt/FarBackground/CloudLayers/FarClouds")
	var mid_clouds := room.get_node("EnvironmentArt/FarBackground/CloudLayers/MidClouds")
	var player_start := room.get_node("Markers/PlayerStart") as Node2D
	assert(far_clouds.get_child_count() == 8)
	assert(mid_clouds.get_child_count() == 8)
	for group: AnchoredParallax2D in [far_clouds, mid_clouds]:
		group._apply_anchor_offset()
		var expected_offset := -player_start.position * (Vector2.ONE - group.scroll_scale)
		assert(group.scroll_offset.is_equal_approx(expected_offset))
	var phases: Dictionary = {}
	for group: Node in [far_clouds, mid_clouds]:
		for child: BlueDriftingCloud2D in group.get_children():
			assert(not child.name.contains("Cloud0"))
			phases[child.motion_phase] = true
	assert(phases.size() == 16)
	room.free()
	print("BLUE_CLOUDS_VERIFY_OK")
	get_tree().quit()
