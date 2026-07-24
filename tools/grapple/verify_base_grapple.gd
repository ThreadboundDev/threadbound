extends Node

const BASE_GLOVES_SCENE := preload("res://Src/Equipment/base_gloves.tscn")

var failures: Array[String] = []

func _ready() -> void:
	var player := _create_player()
	add_child(player)

	var gloves := BASE_GLOVES_SCENE.instantiate() as BaseGloves
	player.add_child(gloves)
	gloves.player = player
	gloves.on_equipped()

	var ignored_interaction_area := _create_area(Vector2(70.0, 0.0), 2)
	add_child(ignored_interaction_area)
	var wall := _create_body(Vector2(120.0, 0.0), 1)
	add_child(wall)
	await get_tree().physics_frame

	_prepare_active_shot(gloves)
	gloves.call("_check_grapple_collision", Vector2.ZERO, Vector2(160.0, 0.0))
	if gloves.grapple_state != BaseGloves.GrappleState.ATTACHED:
		failures.append("Hookshot did not attach after crossing player/interaction areas.")
	elif gloves.grapple_target != wall:
		failures.append("Hookshot attached to an invisible area instead of solid environment geometry.")

	var upward_clearance: float = gloves.call("_get_hookshot_surface_clearance", Vector2.UP)
	if upward_clearance < 65.0:
		failures.append(
			"Upward surface clearance %.2f does not clear the player's full collision shape." %
			upward_clearance
		)

	var tile_layer := TileMapLayer.new()
	if not gloves.call("_is_valid_hookshot_collider", tile_layer):
		failures.append("TileMapLayer collision was not recognized as valid level geometry.")
	tile_layer.free()

	var enemy := Node2D.new()
	enemy.add_to_group("enemies")
	var enemy_hurtbox := Area2D.new()
	enemy.add_child(enemy_hurtbox)
	if not gloves.call("_is_valid_hookshot_collider", enemy_hurtbox):
		failures.append("Enemy collision area was not recognized as a valid hookshot target.")
	enemy.free()

	gloves.call("_reset_active_grapple_visuals")
	gloves.grapple_state = BaseGloves.GrappleState.ATTACHED
	gloves.grapple_attached = true
	gloves.grapple_attach_position = Vector2(200.0, 0.0)
	gloves.grapple_collision_normal = Vector2.ZERO
	gloves.grapple_target = null
	for _frame in range(12):
		gloves.call("_apply_hookshot_pull", 0.02)
	if gloves.grapple_state != BaseGloves.GrappleState.RETRACTING:
		failures.append("A blocked hookshot did not release after its no-progress timeout.")

	player.queue_free()
	ignored_interaction_area.queue_free()
	wall.queue_free()

	if failures.is_empty():
		print(
			"Base grapple verification passed: self/trigger filtering, collider-sized "
			+ "surface clearance, and deterministic stalled-pull release are valid."
		)
		get_tree().quit(0)
		return

	for failure in failures:
		push_error(failure)
	get_tree().quit(1)

func _create_player() -> CharacterBody2D:
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group("player")

	var body_shape := CollisionShape2D.new()
	body_shape.name = "CollisionShape2D"
	body_shape.position = Vector2(0.0, 6.0)
	var body_rectangle := RectangleShape2D.new()
	body_rectangle.size = Vector2(37.0, 126.0)
	body_shape.shape = body_rectangle
	player.add_child(body_shape)

	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.position = Vector2(40.0, 0.0)
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 0
	var hurtbox_shape := CollisionShape2D.new()
	var hurtbox_rectangle := RectangleShape2D.new()
	hurtbox_rectangle.size = Vector2(20.0, 40.0)
	hurtbox_shape.shape = hurtbox_rectangle
	hurtbox.add_child(hurtbox_shape)
	player.add_child(hurtbox)
	return player

func _create_area(position: Vector2, layer: int) -> Area2D:
	var area := Area2D.new()
	area.position = position
	area.collision_layer = layer
	area.collision_mask = 0
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20.0, 40.0)
	collision_shape.shape = rectangle
	area.add_child(collision_shape)
	return area

func _create_body(position: Vector2, layer: int) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = position
	body.collision_layer = layer
	body.collision_mask = 0
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20.0, 80.0)
	collision_shape.shape = rectangle
	body.add_child(collision_shape)
	return body

func _prepare_active_shot(gloves: BaseGloves) -> void:
	gloves.call("_reset_grapple_raycast_exceptions")
	gloves.grapple_state = BaseGloves.GrappleState.FIRING
	gloves.grapple_attachment_state = BaseGloves.GrappleAttachmentState.ACTIVE
	gloves.grapple_attached = false
