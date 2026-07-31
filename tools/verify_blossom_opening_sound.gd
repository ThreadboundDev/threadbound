extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var scene := load("res://Src/Environment/SavePoints/blossom_of_eryndor.tscn") as PackedScene
	_check(scene != null, "Blossom scene loads")
	if not scene:
		quit(1)
		return

	var blossom := scene.instantiate() as Area2D
	root.add_child(blossom)
	await process_frame
	_check(not blossom.is_open(), "Blossom starts closed")

	var player := CharacterBody2D.new()
	player.add_to_group("player")
	player.collision_layer = 1
	player.collision_mask = 0
	player.position = Vector2(1200.0, 0.0)
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(37.0, 126.0)
	shape_node.shape = shape
	player.add_child(shape_node)
	root.add_child(player)
	await create_timer(0.1).timeout

	player.position = Vector2.ZERO
	await create_timer(0.1).timeout
	_check(blossom.is_open(), "Player proximity opens the blossom")
	var sound_player := blossom.get_node_or_null("BlossomOpenSound") as AudioStreamPlayer
	_check(sound_player != null, "Opening creates the blossom sound")
	_check(sound_player != null and sound_player.playing, "Blossom sound is playing")
	_check(sound_player != null and sound_player.volume_db >= -4.0, "Blossom sound has an audible source level")

	player.position = Vector2(1200.0, 0.0)
	await create_timer(0.1).timeout
	_check(not blossom.is_open(), "Leaving starts closing the blossom")
	player.position = Vector2.ZERO
	await create_timer(0.1).timeout
	_check(blossom.is_open(), "Re-entering can reverse the closing animation")
	var opening_sound_count := 0
	for child in blossom.get_children():
		if child.name.to_lower().begins_with("blossomopensound"):
			opening_sound_count += 1
	_check(opening_sound_count == 1, "Reversing an incomplete close does not replay the sound")

	if _failures == 0:
		print("Blossom opening sound verification passed.")
	blossom.queue_free()
	player.queue_free()
	await process_frame
	quit(_failures)


func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Blossom opening sound verification failed: %s" % label)
