extends Node

const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")

const EXPECTED_ANIMATIONS := {
	&"Air_Double_Attack": {"frames": 27, "fps": 40.0, "loop": false, "cell": Vector2(416, 416)},
	&"Grapple_Diagonal": {"frames": 6, "fps": 18.0, "loop": false, "cell": Vector2(320, 320)},
	&"Grapple_Horizontal": {"frames": 6, "fps": 18.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_1": {"frames": 14, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_1_Stationary": {"frames": 14, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_1_Backpedal": {"frames": 14, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_2": {"frames": 19, "fps": 30.0, "loop": false, "cell": Vector2(448, 448)},
	&"Ground_Attack_Combo_2_Stationary": {"frames": 19, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_2_Backpedal": {"frames": 19, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Jump_Apex": {"frames": 4, "fps": 8.0, "loop": true, "cell": Vector2(320, 320)},
	&"Jump_Ascent": {"frames": 4, "fps": 8.0, "loop": true, "cell": Vector2(320, 320)},
	&"Jump_Descent": {"frames": 4, "fps": 8.0, "loop": true, "cell": Vector2(320, 320)},
	&"Jump_Land": {"frames": 4, "fps": 12.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ledge_Hang": {"frames": 4, "fps": 5.0, "loop": true, "cell": Vector2(320, 320)},
	&"Sit": {"frames": 48, "fps": 12.0, "loop": false, "cell": Vector2(512, 512)},
	&"Wall_Cling": {"frames": 4, "fps": 6.0, "loop": true, "cell": Vector2(320, 320)},
}

func _ready() -> void:
	var player := PLAYER_SCENE.instantiate()
	var sprite := player.get_node("Player Animation") as AnimatedSprite2D
	var failures: Array[String] = []
	if sprite == null:
		failures.append("Player Animation node is missing or is not an AnimatedSprite2D.")
	else:
		_verify_editor_authored_animations(sprite, failures)

	add_child(player)
	if sprite != null:
		_verify_sprite(sprite, failures)
		_verify_ground_attack_variant_locking(player, sprite, failures)
		_verify_forward_combo_chain(player, failures)
		_verify_retired_up_attack(player, sprite, failures)
	_verify_ledge_transparency(failures)
	_verify_sheet_cell_gutters(
		"res://Assets/Threadborne/Player/Normalized_V2/attacks/stationary_combo_01.png",
		Vector2i(5, 5),
		14,
		16,
		failures
	)
	_verify_sheet_cell_gutters(
		"res://Assets/Threadborne/Player/Normalized_V2/attacks/stationary_combo_02.png",
		Vector2i(6, 4),
		19,
		16,
		failures
	)

	player.free()
	if failures.is_empty():
		print(
			(
				"Player animation verification passed: %d corrected clips, atlas cells, "
				+ "normalized scale, locked ground variants, widened forward coverage, "
				+ "and the capped three-hit forward chain are valid."
			) % EXPECTED_ANIMATIONS.size()
		)
		get_tree().quit(0)
		return

	for failure in failures:
		push_error(failure)
	get_tree().quit(1)

func _verify_editor_authored_animations(
	sprite: AnimatedSprite2D,
	failures: Array[String]
) -> void:
	for animation_name: StringName in EXPECTED_ANIMATIONS:
		if not sprite.sprite_frames.has_animation(animation_name):
			failures.append(
				"%s is not serialized in the Player SpriteFrames resource." % animation_name
			)

func _verify_sprite(sprite: AnimatedSprite2D, failures: Array[String]) -> void:
	if not sprite.scale.is_equal_approx(Vector2(0.7, 0.7)):
		failures.append("Player Animation scale is %s; expected (0.7, 0.7)." % sprite.scale)

	var frames := sprite.sprite_frames
	for animation_name: StringName in frames.get_animation_names():
		if String(animation_name).begins_with("Ground_Up_Combo_"):
			failures.append("Retired upward ground animation is still active: %s." % animation_name)
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

func _verify_ledge_transparency(failures: Array[String]) -> void:
	var path := "res://Assets/Threadborne/Player/Normalized_V2/movement/ledge_hang.png"
	var image := _load_imported_image(path)
	if image == null or image.is_empty():
		failures.append("Could not load the ledge hang sheet for alpha verification.")
		return

	var transparent_pixels := 0
	var total_pixels := image.get_width() * image.get_height()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 0.01:
				transparent_pixels += 1

	if transparent_pixels < int(total_pixels * 0.8):
		failures.append(
			"Ledge hang background is not transparent enough: %d/%d pixels are transparent." %
			[transparent_pixels, total_pixels]
		)

func _verify_sheet_cell_gutters(
	path: String,
	grid: Vector2i,
	used_frames: int,
	minimum_gutter: int,
	failures: Array[String]
) -> void:
	var image := _load_imported_image(path)
	if image == null or image.is_empty():
		failures.append("Could not load %s for atlas gutter verification." % path)
		return

	var cell_size := Vector2i(image.get_width() / grid.x, image.get_height() / grid.y)
	for frame_index in used_frames:
		var frame_origin := Vector2i(
			(frame_index % grid.x) * cell_size.x,
			(frame_index / grid.x) * cell_size.y
		)
		var min_x := cell_size.x
		var min_y := cell_size.y
		var max_x := -1
		var max_y := -1
		for y in cell_size.y:
			for x in cell_size.x:
				if image.get_pixel(frame_origin.x + x, frame_origin.y + y).a <= 0.03:
					continue
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)

		if max_x < 0:
			failures.append("%s frame %d is empty." % [path, frame_index])
			continue

		var gutters := [
			min_x,
			min_y,
			cell_size.x - 1 - max_x,
			cell_size.y - 1 - max_y,
		]
		if gutters.min() < minimum_gutter:
			failures.append(
				"%s frame %d has clipped padding %s; expected at least %d px." %
				[path, frame_index, gutters, minimum_gutter]
			)

func _load_imported_image(path: String) -> Image:
	var texture := load(path) as Texture2D
	if texture == null:
		return null
	return texture.get_image()

func _verify_ground_attack_variant_locking(
	player: Node,
	sprite: AnimatedSprite2D,
	failures: Array[String]
) -> void:
	const MOVING_ANIMATION := &"Ground_Attack_Combo_1"
	const STATIONARY_ANIMATION := &"Ground_Attack_Combo_1_Stationary"
	const BACKPEDAL_ANIMATION := &"Ground_Attack_Combo_1_Backpedal"
	const TEST_FRAME := 6
	const TEST_PROGRESS := 0.42

	player.set("last_direction", 1)
	player.set("velocity", Vector2.ZERO)
	if player.call("_select_ground_attack_visual_mode", 1.0) != &"stationary":
		failures.append("Blocked horizontal movement did not select the stationary attack.")
	player.set("velocity", Vector2(120.0, 0.0))
	if player.call("_select_ground_attack_visual_mode", 1.0) != &"moving":
		failures.append("Forward movement did not select the moving attack.")
	player.set("velocity", Vector2(-120.0, 0.0))
	if player.call("_select_ground_attack_visual_mode", -1.0) != &"backpedal":
		failures.append("Movement opposite the attack facing did not select the backpedal attack.")

	player.set("current_attack_body_anim", String(MOVING_ANIMATION))
	player.set("current_attack_uses_ground_combo", true)
	player.set("is_attacking", true)
	player.set("current_body_anim", String(MOVING_ANIMATION))
	player.set("ground_attack_visual_mode", &"stationary")
	player.set("velocity", Vector2(120.0, 0.0))
	sprite.play(MOVING_ANIMATION)
	sprite.set_frame_and_progress(TEST_FRAME, TEST_PROGRESS)
	player.call("update_animations", 1.0)
	if sprite.animation != STATIONARY_ANIMATION:
		failures.append("A stationary swing did not use its locked visual variant.")
	if sprite.frame != TEST_FRAME or not is_equal_approx(sprite.frame_progress, TEST_PROGRESS):
		failures.append("Moving-to-stationary visual selection did not preserve frame progress.")

	player.set("velocity", Vector2(-120.0, 0.0))
	player.call("update_animations", -1.0)
	if sprite.animation != STATIONARY_ANIMATION:
		failures.append("Stationary visual selection changed in the middle of a swing.")
	if sprite.frame != TEST_FRAME or not is_equal_approx(sprite.frame_progress, TEST_PROGRESS):
		failures.append("Locked stationary playback lost frame progress.")

	player.set("ground_attack_visual_mode", &"backpedal")
	player.call("update_animations", -1.0)
	if sprite.animation != BACKPEDAL_ANIMATION:
		failures.append("A new backpedal swing did not use the backpedal visual variant.")
	if sprite.frame != TEST_FRAME or not is_equal_approx(sprite.frame_progress, TEST_PROGRESS):
		failures.append("Stationary-to-backpedal visual selection did not preserve frame progress.")

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
	if player.get("stationary_combo_1_first_strike_frames") != Vector2i(4, 11):
		failures.append("Stationary opener strike window must be frames 4-11.")
	if player.get("stationary_combo_2_first_strike_frames") != Vector2i(5, 9):
		failures.append("Stationary finisher first strike window must be frames 5-9.")
	if player.get("stationary_combo_2_second_strike_frames") != Vector2i(10, 15):
		failures.append("Stationary finisher second strike window must be frames 10-15.")
	if player.get("backpedal_combo_1_first_strike_frames") != Vector2i(3, 11):
		failures.append("Backpedal opener strike window must be frames 3-11.")
	if player.get("backpedal_combo_2_first_strike_frames") != Vector2i(5, 12):
		failures.append("Backpedal finisher first strike window must be frames 5-12.")
	if player.get("backpedal_combo_2_second_strike_frames") != Vector2i(13, 16):
		failures.append("Backpedal finisher second strike window must be frames 13-16.")

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

func _verify_retired_up_attack(
	player: Node,
	sprite: AnimatedSprite2D,
	failures: Array[String]
) -> void:
	if player.call("_get_ground_combo_family", Vector2.UP) != &"forward":
		failures.append("Upward ground input did not route to the forward combo.")
	if not is_equal_approx(float(player.get("ground_combo_hitbox_arc_degrees")), 130.0):
		failures.append("Forward ground hit coverage must use the approved 130-degree arc.")
	if sprite.sprite_frames.has_animation(&"Ground_Up_Combo_1"):
		failures.append("Ground_Up_Combo_1 still exists in the active Player SpriteFrames.")
	if sprite.sprite_frames.has_animation(&"Ground_Up_Combo_2"):
		failures.append("Ground_Up_Combo_2 still exists in the active Player SpriteFrames.")
