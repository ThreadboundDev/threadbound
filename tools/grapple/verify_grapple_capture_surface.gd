extends Node2D

const BASE_GLOVES_SCENE := preload("res://Src/Equipment/base_gloves.tscn")

func _ready() -> void:
	var player := CharacterBody2D.new()
	add_child(player)
	var gloves := BASE_GLOVES_SCENE.instantiate() as BaseGloves
	player.add_child(gloves)
	gloves.player = player
	gloves.on_equipped()

	var capture_surface := _create_body(Vector2(80.0, 0.0), 4)
	var solid_surface := _create_body(Vector2(120.0, 0.0), 1)
	add_child(capture_surface)
	add_child(solid_surface)
	await get_tree().physics_frame

	gloves.call("_reset_grapple_raycast_exceptions")
	gloves.grapple_state = BaseGloves.GrappleState.FIRING
	gloves.grapple_attachment_state = BaseGloves.GrappleAttachmentState.ACTIVE
	gloves.grapple_attached = false
	gloves.call("_check_grapple_collision", Vector2.ZERO, Vector2(160.0, 0.0))

	if gloves.grapple_state != BaseGloves.GrappleState.ATTACHED:
		_fail("Capture surface did not trigger a grapple attachment.")
		return
	if gloves.grapple_target != solid_surface:
		_fail("Capture surface did not resolve back to the solid collider.")
		return
	if not is_equal_approx(gloves.grapple_attach_position.x, 110.0):
		_fail("Needle did not embed at the solid surface boundary.")
		return

	player.queue_free()
	capture_surface.queue_free()
	solid_surface.queue_free()
	await get_tree().process_frame
	print("GRAPPLE_CAPTURE_SURFACE_VERIFY: PASS")
	get_tree().quit(0)

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

func _fail(message: String) -> void:
	push_error("GRAPPLE_CAPTURE_SURFACE_VERIFY: %s" % message)
	get_tree().quit(1)
