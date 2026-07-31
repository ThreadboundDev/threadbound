extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var scene := load("res://Assets/chamber_of_first_weave/Blue Wing/FreePlaceProps/blue_bamboo_tall.tscn") as PackedScene
	_check(scene != null, "Reactive prop scene loads")
	if not scene:
		quit(1)
		return
	var decoration := scene.instantiate() as Sprite2D
	root.add_child(decoration)
	await process_frame

	_check(decoration.scale.x >= 0.96 and decoration.scale.x <= 1.04, "Scale variation stays within four percent")
	_check(decoration.has_node("FoliageReactionArea"), "Reaction area is created")

	var player := CharacterBody2D.new()
	player.add_to_group("player")
	player.collision_layer = 1
	player.collision_mask = 0
	player.velocity = Vector2(200.0, 0.0)
	player.position = Vector2(-300.0, 0.0)
	var player_shape_node := CollisionShape2D.new()
	var player_shape := RectangleShape2D.new()
	player_shape.size = Vector2(37.0, 126.0)
	player_shape_node.shape = player_shape
	player.add_child(player_shape_node)
	root.add_child(player)
	await create_timer(0.1).timeout
	player.position = Vector2.ZERO
	await create_timer(0.1).timeout

	_check(not is_zero_approx(decoration.rotation), "Physics overlap starts the sway")
	_check(decoration.has_node("BrushRustle"), "Physics overlap starts the brush sound")
	var brush_player := decoration.get_node_or_null("BrushRustle") as AudioStreamPlayer
	_check(brush_player != null and brush_player.volume_db >= -6.0, "Brush sound is mixed at an audible source level")
	await create_timer(0.6).timeout
	_check(is_zero_approx(decoration.rotation), "Decoration returns to its resting rotation")
	_check(decoration.position.is_equal_approx(Vector2.ZERO), "Decoration returns to its resting position")

	if _failures == 0:
		print("Interactive decoration verification passed.")
	quit(_failures)


func _check(condition: bool, label: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Interactive decoration verification failed: %s" % label)
