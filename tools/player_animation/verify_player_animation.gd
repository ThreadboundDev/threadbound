extends Node

const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")

const EXPECTED_ANIMATIONS := {
	&"Air_Double_Attack": {"frames": 27, "fps": 40.0, "loop": false, "cell": Vector2(416, 416)},
	&"Grapple_Diagonal": {"frames": 6, "fps": 18.0, "loop": false, "cell": Vector2(320, 320)},
	&"Grapple_Horizontal": {"frames": 6, "fps": 18.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_1": {"frames": 14, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_1_Stationary": {"frames": 14, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_2": {"frames": 19, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_2_Stationary": {"frames": 19, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Up_Combo_1": {"frames": 10, "fps": 12.5, "loop": false, "cell": Vector2(384, 384)},
	&"Ground_Up_Combo_1_Stationary": {"frames": 10, "fps": 12.5, "loop": false, "cell": Vector2(384, 384)},
	&"Ground_Up_Combo_2": {"frames": 12, "fps": 14.4, "loop": false, "cell": Vector2(384, 384)},
	&"Ground_Up_Combo_2_Stationary": {"frames": 12, "fps": 14.4, "loop": false, "cell": Vector2(384, 384)},
	&"Jump_Apex": {"frames": 4, "fps": 8.0, "loop": true, "cell": Vector2(320, 320)},
	&"Jump_Ascent": {"frames": 4, "fps": 8.0, "loop": true, "cell": Vector2(320, 320)},
	&"Jump_Descent": {"frames": 4, "fps": 8.0, "loop": true, "cell": Vector2(320, 320)},
	&"Jump_Land": {"frames": 4, "fps": 12.0, "loop": false, "cell": Vector2(320, 320)},
	&"Wall_Cling": {"frames": 4, "fps": 6.0, "loop": true, "cell": Vector2(320, 320)},
}

func _ready() -> void:
	var player := PLAYER_SCENE.instantiate()
	add_child(player)

	var sprite := player.get_node("Player Animation") as AnimatedSprite2D
	var failures: Array[String] = []
	if sprite == null:
		failures.append("Player Animation node is missing or is not an AnimatedSprite2D.")
	else:
		_verify_sprite(sprite, failures)
		_verify_stationary_attack_switching(player, sprite, failures)
		_verify_forward_combo_chain(player, failures)

	player.free()
	if failures.is_empty():
		print(
			(
				"Player animation verification passed: %d corrected clips, atlas cells, "
				+ "normalized scale, frame textures, and the capped three-hit forward chain are valid."
			) % EXPECTED_ANIMATIONS.size()
		)
		get_tree().quit(0)
		return

	for failure in failures:
		push_error(failure)
	get_tree().quit(1)

func _verify_sprite(sprite: AnimatedSprite2D, failures: Array[String]) -> void:
	if not sprite.scale.is_equal_approx(Vector2(0.7, 0.7)):
		failures.append("Player Animation scale is %s; expected (0.7, 0.7)." % sprite.scale)

	var frames := sprite.sprite_frames
	for animation_name: StringName in frames.get_animation_names():
		for frame_index in frames.get_frame_count(animation_name):
			var texture := frames.get_frame_texture(animation_name, frame_index)
			var atlas_texture := texture as AtlasTexture
			if atlas_texture == null:
				continue
			if atlas_texture.atlas == null:
				failures.append("%s frame %d has no atlas texture." % [animation_name, frame_index])
				continue

			var region_end := atlas_texture.region.position + atlas_texture.region.size
			var atlas_size := atlas_texture.atlas.get_size()
			if region_end.x > atlas_size.x + 0.01 or region_end.y > atlas_size.y + 0.01:
				failures.append(
					"%s frame %d region %s exceeds atlas size %s." %
					[animation_name, frame_index, atlas_texture.region, atlas_size]
				)

	for animation_name: StringName in EXPECTED_ANIMATIONS:
		var expected: Dictionary = EXPECTED_ANIMATIONS[animation_name]
		if not frames.has_animation(animation_name):
			failures.append("Missing animation: %s." % animation_name)
			continue

		var frame_count := frames.get_frame_count(animation_name)
		if frame_count != expected.frames:
			failures.append(
				"%s has %d frames; expected %d." %
				[animation_name, frame_count, expected.frames]
			)
		if not is_equal_approx(frames.get_animation_speed(animation_name), expected.fps):
			failures.append(
				"%s plays at %.2f fps; expected %.2f." %
				[animation_name, frames.get_animation_speed(animation_name), expected.fps]
			)
		if frames.get_animation_loop(animation_name) != expected.loop:
			failures.append(
				"%s loop setting is %s; expected %s." %
				[animation_name, frames.get_animation_loop(animation_name), expected.loop]
			)

		for frame_index in frame_count:
			var texture := frames.get_frame_texture(animation_name, frame_index)
			if texture == null:
				failures.append("%s frame %d has no texture." % [animation_name, frame_index])
				continue
			if texture is AtlasTexture and not texture.region.size.is_equal_approx(expected.cell):
				failures.append(
					"%s frame %d uses atlas cell %s; expected %s." %
					[animation_name, frame_index, texture.region.size, expected.cell]
				)

func _verify_stationary_attack_switching(
	player: Node,
	sprite: AnimatedSprite2D,
	failures: Array[String]
) -> void:
	const MOVING_ANIMATION := &"Ground_Attack_Combo_1"
	const STATIONARY_ANIMATION := &"Ground_Attack_Combo_1_Stationary"
	const TEST_FRAME := 6
	const TEST_PROGRESS := 0.42

	player.set("current_attack_body_anim", String(MOVING_ANIMATION))
	player.set("current_attack_uses_ground_combo", true)
	player.set("is_attacking", true)
	player.set("current_body_anim", String(MOVING_ANIMATION))
	player.set("velocity", Vector2.ZERO)
	sprite.play(MOVING_ANIMATION)
	sprite.set_frame_and_progress(TEST_FRAME, TEST_PROGRESS)
	player.call("update_animations", 1.0)
	if sprite.animation != STATIONARY_ANIMATION:
		failures.append("Blocked movement input did not select the stationary attack.")
	if sprite.frame != TEST_FRAME or not is_equal_approx(sprite.frame_progress, TEST_PROGRESS):
		failures.append("Moving-to-stationary attack switching did not preserve frame progress.")

	player.set("velocity", Vector2(120.0, 0.0))
	player.call("update_animations", 1.0)
	if sprite.animation != MOVING_ANIMATION:
		failures.append("Real horizontal movement did not select the moving attack.")
	if sprite.frame != TEST_FRAME or not is_equal_approx(sprite.frame_progress, TEST_PROGRESS):
		failures.append("Stationary-to-moving attack switching did not preserve frame progress.")

	sprite.set_frame_and_progress(TEST_FRAME + 1, 0.25)
	player.call("update_animations", 0.0)
	if sprite.animation != STATIONARY_ANIMATION:
		failures.append("Released movement input did not select the stationary attack.")
	if sprite.frame != TEST_FRAME + 1 or not is_equal_approx(sprite.frame_progress, 0.25):
		failures.append("Input-release attack switching did not preserve frame progress.")

	player.set("is_attacking", false)
	player.set("current_attack_uses_ground_combo", false)

func _verify_forward_combo_chain(player: Node, failures: Array[String]) -> void:
	if player.get("ground_combo_1_first_strike_frames") != Vector2i(3, 5):
		failures.append("Forward opener strike window must be frames 3-5.")
	if player.get("ground_combo_1_second_strike_frames") != Vector2i(-1, -1):
		failures.append("Forward opener must have exactly one strike window.")
	if player.get("ground_combo_2_first_strike_frames") != Vector2i(2, 4):
		failures.append("Forward finisher first strike window must be frames 2-4.")
	if player.get("ground_combo_2_second_strike_frames") != Vector2i(9, 11):
		failures.append("Forward finisher second strike window must be frames 9-11.")

	player.call("_reset_ground_combo_chain")
	player.call("_begin_ground_combo_attack", &"forward")
	if player.get("ground_combo_step") != 0:
		failures.append("Forward chain did not begin at step 0.")
	if player.get("current_attack_body_anim") != "Ground_Attack_Combo_1":
		failures.append("Forward chain did not begin with the one-hit opener.")

	player.set("ground_combo_queued", true)
	player.set("ground_combo_queued_family", &"forward")
	player.call("_finish_ground_combo_attack")
	if player.get("ground_combo_step") != 1:
		failures.append("Queued forward input did not advance to the finisher.")
	if player.get("current_attack_body_anim") != "Ground_Attack_Combo_2":
		failures.append("Forward chain did not use the two-hit finisher second.")

	player.set("ground_combo_queued", true)
	player.set("ground_combo_queued_family", &"forward")
	player.call("_finish_ground_combo_attack")
	if player.get("ground_combo_step") != -1 or player.get("ground_combo_family") != &"":
		failures.append("Forward finisher did not cap and reset the combo chain.")
	if player.get("is_attacking"):
		failures.append("Forward finisher incorrectly restarted after the third hit.")

	player.call("_begin_ground_combo_attack", &"forward")
	if player.get("current_attack_body_anim") != "Ground_Attack_Combo_1":
		failures.append("A reset forward chain did not return to the one-hit opener.")
	player.call("_cancel_ground_combo_attack")
	player.set("is_attacking", false)
