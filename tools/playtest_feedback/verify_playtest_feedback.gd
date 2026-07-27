extends Node

const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")
const OPTION_STEPPER_SCENE := preload("res://Src/UI/Options/option_stepper.tscn")

var failures: Array[String] = []
var _option_press_count := 0

func _ready() -> void:
	await _verify_player_feedback()
	await _verify_controls_accept()

	if failures.is_empty():
		print(
			"Playtest feedback verification passed: ledge grab/pull-over/jump, "
			+ "directional grapple facing, meditation hold, combo finisher scale, "
			+ "and Enter activation are valid."
		)
		get_tree().quit(0)
		return

	for failure in failures:
		push_error(failure)
	get_tree().quit(1)

func _verify_player_feedback() -> void:
	var ledge := _create_static_body(Vector2(64.0, -16.0), Vector2(80.0, 64.0))
	add_child(ledge)

	var player := PLAYER_SCENE.instantiate()
	player.global_position = Vector2.ZERO
	player.last_direction = 1
	player.velocity = Vector2(0.0, 80.0)
	add_child(player)

	await get_tree().physics_frame
	await get_tree().physics_frame
	if not player.is_ledge_hanging:
		failures.append("Player did not grab a reachable ledge while falling.")
	else:
		var ledge_top: Vector2 = player.get("_ledge_top")
		var ledge_direction: int = player.get("_ledge_direction")
		player.call("_climb_from_ledge", false)
		var expected_pull_over := ledge_top + Vector2(
			ledge_direction * player.ledge_climb_horizontal_offset,
			-player.ledge_climb_vertical_offset
		)
		if not player.global_position.is_equal_approx(expected_pull_over):
			failures.append("Ledge pull-over did not place the player on top of the ledge.")

		player.set("is_ledge_hanging", true)
		player.set("_ledge_top", ledge_top)
		player.set("_ledge_direction", ledge_direction)
		player.call("_climb_from_ledge", true)
		if player.is_ledge_hanging or player.velocity.y >= 0.0:
			failures.append("Ledge jump did not release the hang with upward velocity.")

	var sprite := player.get_node("Player Animation") as AnimatedSprite2D
	player.set("current_attack_body_anim", "Ground_Attack_Combo_2")
	player.call("_apply_attack_visual_tuning")
	var expected_finisher_scale: Vector2 = Vector2(0.7, 0.7) * player.ground_combo_forward_finisher_visual_scale_multiplier
	if not sprite.scale.is_equal_approx(expected_finisher_scale):
		failures.append("Forward combo finisher did not receive its larger visual scale.")
	if not is_equal_approx(player.ground_combo_forward_hitbox_radius, 156.0):
		failures.append("Ground-forward attack reach is not tuned to 156 pixels.")
	if not is_equal_approx(player.ground_combo_up_hitbox_radius, 142.0):
		failures.append("Ground-up attack reach is not tuned to 142 pixels.")
	if not is_equal_approx(player.air_attack_hitbox_radius, 160.0):
		failures.append("Air attack reach is not tuned to 160 pixels.")

	var gloves: Node = player.current_gloves
	if not gloves:
		failures.append("Player did not equip base gloves for grapple-facing verification.")
	else:
		gloves.grapple_direction = Vector2.LEFT
		gloves.call("_play_grapple_fire_animation")
		if player.last_direction != -1 or not sprite.flip_h:
			failures.append("Leftward grapple toss did not face the player left.")

		gloves.grapple_direction = Vector2.RIGHT
		gloves.call("_play_grapple_fire_animation")
		if player.last_direction != 1 or sprite.flip_h:
			failures.append("Rightward grapple toss did not face the player right.")

	if not _action_has_physical_key(&"Meditate", KEY_V):
		failures.append("Meditate is not bound to physical V after loading saved controls.")

	ledge.queue_free()
	var floor_body := _create_static_body(Vector2(-300.0, 85.0), Vector2(300.0, 20.0))
	add_child(floor_body)
	player.global_position = Vector2(-300.0, 0.0)
	player.velocity = Vector2(0.0, 120.0)
	player.set("is_ledge_hanging", false)
	player.set("is_attacking", false)

	for _frame in 12:
		await get_tree().physics_frame
	if not player.is_on_floor():
		failures.append("Meditation verifier could not place the player on the test floor.")
	else:
		Input.action_press(&"Meditate")
		for _frame in 24:
			await get_tree().physics_frame
		if not player.is_meditating:
			failures.append("Holding Meditate on the floor did not enter meditation.")
		elif sprite.animation != &"Sit":
			failures.append("Meditation did not select the Sit animation.")
		elif not sprite.scale.is_equal_approx(Vector2(0.5, 0.5)):
			failures.append(
				"Meditation visual scale is %s; expected the atlas-matched (0.5, 0.5)." %
				sprite.scale
			)
		Input.action_release(&"Meditate")

	player.queue_free()
	floor_body.queue_free()

func _verify_controls_accept() -> void:
	var stepper := OPTION_STEPPER_SCENE.instantiate() as OptionStepper
	add_child(stepper)
	stepper.configure_button("OPEN CONTROLS")
	stepper.focus_mode = Control.FOCUS_ALL
	stepper.pressed.connect(_on_option_stepper_pressed)
	stepper.grab_focus()
	await get_tree().process_frame

	var accept_event := InputEventAction.new()
	accept_event.action = &"ui_accept"
	accept_event.pressed = true
	stepper.call("_unhandled_input", accept_event)
	if _option_press_count != 1:
		failures.append("Pressing Enter on a focused option button did not activate it.")
	stepper.queue_free()

func _on_option_stepper_pressed(_stepper: OptionStepper) -> void:
	_option_press_count += 1

func _create_static_body(position: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 0
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision_shape.shape = rectangle
	body.add_child(collision_shape)
	return body

func _action_has_physical_key(action: StringName, expected_key: Key) -> bool:
	if not InputMap.has_action(action):
		return false
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == expected_key:
			return true
	return false
