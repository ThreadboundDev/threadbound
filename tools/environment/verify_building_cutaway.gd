extends Node


func _ready() -> void:
	var packed := load("res://Src/Environment/BlueBiome/Buildings/blue_building_cutaway.tscn") as PackedScene
	assert(packed != null)
	var cutaway := packed.instantiate()
	add_child(cutaway)
	await get_tree().process_frame
	assert(is_equal_approx(cutaway.get_node("Exterior").modulate.a, 1.0))
	assert(is_equal_approx(cutaway.get_node("Interior").modulate.a, cutaway.interior_outside_alpha))
	cutaway.call("_apply_visual_state", true, true)
	assert(is_equal_approx(cutaway.get_node("Exterior").modulate.a, cutaway.exterior_inside_alpha))
	assert(is_equal_approx(cutaway.get_node("Interior").modulate.a, 1.0))
	assert(cutaway.get_node("EntryZone").collision_mask == 1)
	var mock_player := Node2D.new()
	mock_player.add_to_group("player")
	cutaway.call("_on_body_entered", mock_player)
	assert(cutaway.get("_occupants").size() == 1)
	cutaway.call("_on_body_exited", mock_player)
	assert(cutaway.get("_occupants").is_empty())
	mock_player.free()
	cutaway.free()
	print("BUILDING_CUTAWAY_VERIFY_OK")
	get_tree().quit()
