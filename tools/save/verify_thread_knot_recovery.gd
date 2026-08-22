extends Node

const RecoveryPileScene := preload("res://Src/Pickups/recovery_thread_knot_pile.tscn")
const TestDemoProgress := preload("res://tools/save/test_demo_progress_no_io.gd")

func _ready() -> void:
	var progress_source := FileAccess.get_file_as_string("res://Src/Global/demo_progress.gd")
	var player_source := FileAccess.get_file_as_string("res://Src/Characters/Player/player.gd")
	var merchant_scene_source := FileAccess.get_file_as_string("res://Src/UI/MerchantMenu/merchant_menu.tscn")
	var chamber_scene_source := FileAccess.get_file_as_string("res://Src/Environment/World/Chamber Of The First Weave.tscn")

	assert(progress_source.contains("const SAVE_VERSION := 3"), "Recovery data requires save format version 3")
	for required_key in [
		"held_thread_knots",
		"recovery_thread_knots",
		"recovery_scene_path",
		"recovery_position_x",
		"recovery_position_y",
	]:
		assert(progress_source.contains(required_key), "Missing recovery save key: %s" % required_key)
	assert(progress_source.contains("func claim_recovery_thread_knots()"), "Recovery claim must be atomic")
	assert(player_source.contains("func _drop_held_thread_knots()"), "Player death must deposit held Knots")
	assert(player_source.contains("func _spawn_recovery_thread_knot_pile()"), "Player must restore the recovery pile")
	var death_handler_start := player_source.find("func _on_died")
	var death_handler_end := player_source.find("\nfunc ", death_handler_start + 1)
	var death_handler := player_source.substr(death_handler_start, death_handler_end - death_handler_start)
	assert(death_handler.contains("_drop_held_thread_knots()"), "Ordinary death should deposit held Knots")
	assert(merchant_scene_source.contains("offset_top = -222.0"), "Merchant rows should be lowered")
	assert(chamber_scene_source.contains("position = Vector2(0, -2600)"), "Central soft fill should move upward")
	assert(chamber_scene_source.contains("scale = Vector2(1, 2)"), "Central soft fill should cover the upper room")

	var progress := TestDemoProgress.new()
	progress.set_held_thread_knots(17)
	assert(progress.get_held_thread_knots() == 17, "Held Knots should persist in run state")
	progress.drop_thread_knots(17, "res://test_level.tscn", Vector2(120.0, 340.0))
	assert(progress.get_held_thread_knots() == 0, "Death should empty the held wallet")
	assert(progress.has_recovery_thread_knots("res://test_level.tscn"), "Death should create a scene-bound recovery pile")
	assert(progress.get_recovery_position() == Vector2(120.0, 340.0), "Recovery position should be retained")
	assert(progress.claim_recovery_thread_knots() == 17, "Recovery should return the full dropped amount")
	assert(progress.get_held_thread_knots() == 17, "Recovery should restore the held wallet atomically")
	assert(not progress.has_recovery_thread_knots(), "Claiming should clear the recovery pile")
	progress.drop_thread_knots(9, "res://old.tscn", Vector2.ONE)
	progress.drop_thread_knots(4, "res://new.tscn", Vector2(2.0, 3.0))
	assert(progress.get_recovery_thread_knots() == 4, "A second death should replace the previous pile")
	assert(progress.get_recovery_scene_path() == "res://new.tscn", "Replacement pile should use the latest scene")
	progress.free()

	var pile := RecoveryPileScene.instantiate() as RecoveryThreadKnotPile
	assert(pile != null, "Recovery pile scene should instantiate")
	add_child(pile)
	assert(pile.vacuum_radius == 150.0, "Recovery pile should require a deliberate close approach")
	pile.queue_free()

	print("Thread Knot recovery, merchant layout, and central light verification passed.")
	get_tree().quit(0)
