extends Node

const WATER_VOLUME := preload("res://Src/Environment/Greybox/greybox_water.tscn")
const REFLECTIVE_VISUAL := preload("res://Src/Environment/BlueBiome/Water/blue_reflective_water.tscn")
const ROOM := preload("res://Src/Environment/BlueBiome/Production/blue_chamber_exit_production.tscn")


func _ready() -> void:
	var water := WATER_VOLUME.instantiate() as GreyboxWater2D
	water.size = Vector2(736.0, 304.0)
	var visual := REFLECTIVE_VISUAL.instantiate() as BlueReflectiveWater2D
	water.add_child(visual)
	add_child(water)
	await get_tree().process_frame

	assert(visual.material is ShaderMaterial)
	assert(visual.z_index == 21)
	assert(not visual.z_as_relative)
	assert(visual.size.is_equal_approx(water.size))
	water.scale = Vector2(3.0, 1.75)
	visual.call("_sync_to_water_volume")
	var expected_global_left := water.to_global(Vector2(-water.size.x * 0.5, 0.0)).x
	var expected_global_right := water.to_global(Vector2(water.size.x * 0.5, 0.0)).x
	var visual_global_left := visual.get_global_transform() * Vector2.ZERO
	var visual_global_right := visual.get_global_transform() * Vector2(visual.size.x, 0.0)
	assert(
		is_equal_approx(visual_global_left.x, expected_global_left),
		"Scaled water artwork must share the collision volume's global left edge."
	)
	assert(
		is_equal_approx(visual_global_right.x, expected_global_right),
		"Scaled water artwork must share the collision volume's global right edge."
	)
	assert(is_equal_approx(visual.position.x, -water.size.x * 0.5))
	assert(is_equal_approx(visual.position.y, -water.size.y * 0.5))
	visual.position = Vector2(170.0, -40.0)
	visual.scale = Vector2(2.75, 0.6)
	visual.call("_sync_to_water_volume")
	assert(visual.scale == Vector2.ONE, "Water artwork must not keep an independent scale.")
	assert(
		visual.position.is_equal_approx(-water.size * 0.5),
		"Water artwork must recenter over its collision after a stale transform."
	)
	assert(visual.size.is_equal_approx(water.size))
	assert((visual.material as ShaderMaterial).shader.code.contains("hint_screen_texture"))
	assert((visual.material as ShaderMaterial).shader.code.contains("horizontal_blur_px"))

	var room := ROOM.instantiate()
	add_child(room)
	await get_tree().process_frame
	assert(room.get_node("WaterVolumes/WestUpperWater/ReflectiveWaterVisual") != null)
	assert(room.get_node("WaterVolumes/CentralLowerWater/ReflectiveWaterVisual") != null)
	assert(room.get_node("WaterVolumes/LakeOverlookWater/ReflectiveWaterVisual") != null)
	for water_path in [
		"WaterVolumes/WestUpperWater",
		"WaterVolumes/CentralLowerWater",
		"WaterVolumes/LakeOverlookWater",
	]:
		var room_water := room.get_node(water_path) as GreyboxWater2D
		var room_visual := room_water.get_node("ReflectiveWaterVisual") as BlueReflectiveWater2D
		_assert_visual_matches_volume(room_visual, room_water)
	var west_collision := room.get_node("WaterVolumes/WestUpperWater/CollisionShape2D") as CollisionShape2D
	var central_collision := room.get_node("WaterVolumes/CentralLowerWater/CollisionShape2D") as CollisionShape2D
	assert(west_collision.shape != central_collision.shape, "Water volumes must not share collision shapes.")
	assert(
		(west_collision.shape as RectangleShape2D).size.is_equal_approx(
			(room.get_node("WaterVolumes/WestUpperWater") as GreyboxWater2D).size
		),
		"West water collision must retain its own dimensions."
	)
	room.queue_free()
	print("BLUE_REFLECTIVE_WATER_VERIFY_OK")
	get_tree().quit()


func _assert_visual_matches_volume(visual: BlueReflectiveWater2D, water: GreyboxWater2D) -> void:
	var expected_left := water.to_global(Vector2(-water.size.x * 0.5, 0.0)).x
	var expected_right := water.to_global(Vector2(water.size.x * 0.5, 0.0)).x
	var actual_left := (visual.get_global_transform() * Vector2.ZERO).x
	var actual_right := (visual.get_global_transform() * Vector2(visual.size.x, 0.0)).x
	assert(is_equal_approx(actual_left, expected_left), "Room water visual left edge is misaligned.")
	assert(is_equal_approx(actual_right, expected_right), "Room water visual right edge is misaligned.")
