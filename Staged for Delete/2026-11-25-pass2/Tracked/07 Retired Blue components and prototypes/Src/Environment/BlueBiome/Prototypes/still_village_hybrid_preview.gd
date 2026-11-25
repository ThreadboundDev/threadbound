extends "res://Src/Environment/BlueBiome/Prototypes/still_village_preview.gd"
## Visual comparison only; inherited colliders continue to own traversal.
const OLD_ART := "res://Src/Environment/BlueBiome/ArtPlaceables/"

func _ready() -> void:
	super._ready()
	for child in art.get_children():
		if not child is AnimatedSprite2D:
			child.queue_free()
	for block in $Geometry.get_children():
		if "Wall" in str(block.name):
			continue
		var left: float = block.position.x - block.size.x * 0.5
		var top: float = block.position.y - block.size.y * 0.5
		var count := ceili(block.size.x / 480.0)
		var weights: Array[float] = []
		var total := 0.0
		for i in count:
			var weight: float = [0.8, 1.2, 1.0][i % 3]
			weights.append(weight)
			total += weight
		var cursor := left
		for i in count:
			var width: float = block.size.x * weights[i] / total
			var short := width < 325.0
			var platform := _old_sprite("Platforms/wood_platform_short" if short else "Platforms/wood_platform_long", 2)
			var height_scale: float = [0.72, 0.9, 0.8][i % 3]
			platform.scale = Vector2(width / (209.0 if short else 420.0), height_scale)
			platform.flip_h = i % 2 == 1
			var trim_offset := (8.5 if not platform.flip_h else -8.5) * platform.scale.x if short else 0.0
			platform.position = Vector2(cursor + width*.5 - trim_offset, top + 36*height_scale)
			if i % 3 == 1 and block.name != &"RecoveryFloor":
				var cloth := _old_sprite("Platforms/platform_cloth", -1)
				cloth.scale = Vector2(.24,.24)
				cloth.position = Vector2(cursor + width*.7, top + 52)
			cursor += width
	var house := _old_sprite("Buildings/building_wide_house", -12)
	house.name = "WideStiltHouse"
	house.scale = Vector2(0.92,0.92)
	house.position = Vector2(390,330)
	_water_contact(house, 640.0, [365.0, 467.0, 675.0, 814.0, 952.0, 1169.0, 1384.0])
	var tower := _old_sprite("Buildings/building_tower_house", -12)
	tower.name = "TowerStiltHouse"
	tower.scale = Vector2(.66,.66)
	tower.position = Vector2(3720,180)
	_water_contact(tower, 605.0, [])
	# Painted posts support each hanging globe without the smooth 3D kit.
	for bulb in $Bulbs.get_children():
		var frame := _old_sprite("Platforms/house_foreground_frame", -4)
		frame.scale = Vector2(.55,.65)
		frame.position = bulb.position + Vector2(-12,-65)
		var visual := art.get_node(str(bulb.name) + "Art") as AnimatedSprite2D
		visual.sprite_frames = load("res://Assets/BlueBiome/StillVillage/Bulb/PetalV2/bulb_frames.tres")
		visual.play(&"rush")

func _water_contact(building: Sprite2D, water_y: float, post_pixels: Array) -> void:
	var water := ShaderMaterial.new()
	water.shader = load("res://Assets/BlueBiome/StillVillage/Backgrounds/stilt_water_contact.gdshader")
	water.set_shader_parameter("water_y", water_y)
	building.material = water
	# Quiet, broken contact rings sit at the posts, with no perpetual wave motion.
	for pixel_x in post_pixels:
		var x: float = building.position.x + (float(pixel_x)-building.texture.get_width()*.5)*building.scale.x
		for side in [-1.0,1.0]:
			var ring := Line2D.new()
			ring.z_index = building.z_index + 1
			ring.width = 1.5
			ring.default_color = Color(0.72,0.90,0.93,0.5)
			for j in 9:
				var angle: float = float(j)/8.0*PI
				ring.add_point(Vector2(x + cos(angle)*26, water_y + sin(angle)*3*side))
			art.add_child(ring)

func _old_sprite(scene_path: String, depth: int) -> Sprite2D:
	var source := (load(OLD_ART + scene_path + ".tscn") as PackedScene).instantiate()
	var sprite := source.get_node("Artwork").duplicate() as Sprite2D
	# Copy artwork alone: no second platform collider or grapple target.
	sprite.z_index = depth
	art.add_child(sprite)
	source.free()
	return sprite
