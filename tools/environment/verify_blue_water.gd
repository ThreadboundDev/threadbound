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
	assert(is_equal_approx(visual.position.x, -water.size.x * 0.5))
	assert(is_equal_approx(visual.position.y, -water.size.y * 0.5))
	assert((visual.material as ShaderMaterial).shader.code.contains("hint_screen_texture"))
	assert((visual.material as ShaderMaterial).shader.code.contains("horizontal_blur_px"))

	var room := ROOM.instantiate()
	assert(room.get_node("WaterVolumes/WestUpperWater/ReflectiveWaterVisual") != null)
	assert(room.get_node("WaterVolumes/CentralLowerWater/ReflectiveWaterVisual") != null)
	assert(room.get_node("WaterVolumes/LakeOverlookWater/ReflectiveWaterVisual") != null)
	room.free()
	print("BLUE_REFLECTIVE_WATER_VERIFY_OK")
	get_tree().quit()
