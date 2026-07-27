extends Node

const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")

const EXPECTED_ANIMATIONS := {
	&"Air_Double_Attack": {"frames": 27, "fps": 40.0, "loop": false, "cell": Vector2(416, 416)},
	&"Grapple_Diagonal": {"frames": 6, "fps": 18.0, "loop": false, "cell": Vector2(320, 320)},
	&"Grapple_Horizontal": {"frames": 6, "fps": 18.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_1": {"frames": 14, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_1_Backpedal": {"frames": 14, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_2": {"frames": 19, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_2_Stationary": {"frames": 19, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ground_Attack_Combo_2_Backpedal": {"frames": 19, "fps": 30.0, "loop": false, "cell": Vector2(320, 320)},
	&"Jump_Apex": {"frames": 4, "fps": 8.0, "loop": true, "cell": Vector2(320, 320)},
	&"Jump_Ascent": {"frames": 4, "fps": 8.0, "loop": true, "cell": Vector2(320, 320)},
	&"Jump_Descent": {"frames": 4, "fps": 8.0, "loop": true, "cell": Vector2(320, 320)},
	&"Jump_Land": {"frames": 4, "fps": 12.0, "loop": false, "cell": Vector2(320, 320)},
	&"Ledge_Climb": {"frames": 4, "fps": 20.0, "loop": false, "cell": Vector2(320, 320)},
	&"Run": {"frames": 11, "fps": 24.0, "loop": true, "cell": Vector2(548, 548)},
	&"Sit": {"frames": 48, "fps": 18.0, "loop": false, "cell": Vector2(512, 512)},
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
		_verify_moving_combo_atlas_maps(sprite, failures)
		_verify_movement_visual_tuning(player, failures)
		_verify_ground_attack_variant_locking(player, sprite, failures)
		_verify_forward_combo_chain(player, failures)
		_verify_retired_up_attack(player, sprite, failures)
	_verify_ledge_climb_sheet(failures)
	_verify_restored_run_frames(failures)
	_verify_wall_cling_contact_registration(failures)
	_verify_grounded_attack_registration(failures)
	_verify_grapple_gutter_cleanup(failures)
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
				+ "moving-finisher scale, standalone stationary double hit, locked ground "
				+ "variants, wall-contact registration, ledge climb easing, and the capped "
				+ "three-hit moving chain are valid."
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
	if frames.has_animation(&"Ground_Attack_Combo_1_Stationary"):
		failures.append("Discarded stationary opener is still present in Player SpriteFrames.")
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

func _verify_moving_combo_atlas_maps(
	sprite: AnimatedSprite2D,
	failures: Array[String]
) -> void:
	var expected_maps := {
		&"Ground_Attack_Combo_1": PackedInt32Array([
			0, 1, 2, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
		]),
		&"Ground_Attack_Combo_2": PackedInt32Array([
			0, 1, 3, 4, 4, 5, 6, 7, 8, 8, 9, 9, 10, 11, 12, 13, 14, 15, 16,
		]),
	}
	var frames := sprite.sprite_frames
	for animation_name: StringName in expected_maps:
		var expected_indices: PackedInt32Array = expected_maps[animation_name]
		for frame_index in expected_indices.size():
			var texture := frames.get_frame_texture(animation_name, frame_index) as AtlasTexture
			if texture == null or texture.atlas == null:
				failures.append(
					"%s frame %d is not backed by the moving combo atlas." %
					[animation_name, frame_index]
				)
				continue
			if not texture.atlas.resource_path.ends_with("/ground_combo_02.png"):
				failures.append(
					"%s frame %d uses %s instead of the clean moving combo atlas." %
					[animation_name, frame_index, texture.atlas.resource_path]
				)
				continue
			var atlas_index := (
				int(texture.region.position.y / 320.0) * 5
				+ int(texture.region.position.x / 320.0)
			)
			if atlas_index != expected_indices[frame_index]:
				failures.append(
					"%s frame %d maps to atlas cell %d; expected %d." %
					[
						animation_name,
						frame_index,
						atlas_index,
						expected_indices[frame_index],
					]
				)

func _verify_ledge_climb_sheet(failures: Array[String]) -> void:
	var path := "res://Assets/Threadborne/Player/Normalized_V2/movement/ledge_climb.png"
	var image := _load_imported_image(path)
	if image == null or image.is_empty():
		failures.append("Could not load the ledge climb sheet for alpha verification.")
		return
	if image.get_size() != Vector2i(640, 640):
		failures.append("Ledge climb sheet is %s; expected 640x640." % image.get_size())
		return

	var transparent_pixels := 0
	var total_pixels := image.get_width() * image.get_height()
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 0.01:
				transparent_pixels += 1

	if transparent_pixels < int(total_pixels * 0.8):
		failures.append(
			"Ledge climb background is not transparent enough: %d/%d pixels are transparent." %
			[transparent_pixels, total_pixels]
		)

	var cell_size := Vector2i(image.get_width() / 2, image.get_height() / 2)
	for frame_index in 4:
		var origin := Vector2i(
			(frame_index % 2) * cell_size.x,
			(frame_index / 2) * cell_size.y
		)
		var minimum := cell_size
		var maximum := Vector2i(-1, -1)
		for y in cell_size.y:
			for x in cell_size.x:
				if image.get_pixel(origin.x + x, origin.y + y).a < 0.06:
					continue
				minimum.x = mini(minimum.x, x)
				minimum.y = mini(minimum.y, y)
				maximum.x = maxi(maximum.x, x)
				maximum.y = maxi(maximum.y, y)

		if maximum.x < 0:
			failures.append("Ledge climb frame %d is empty." % frame_index)
			continue
		var gutters := [
			minimum.x,
			minimum.y,
			cell_size.x - 1 - maximum.x,
			cell_size.y - 1 - maximum.y,
		]
		if gutters.min() < 7:
			failures.append(
				"Ledge climb frame %d has clipped padding %s." %
				[frame_index, gutters]
			)

	# The player never wears a scarf. This known upper-back exterior band
	# must remain empty so generated neck cloth cannot enter the active sheet.
	var crest_origin := Vector2i(0, 320)
	for y in range(70, 94):
		for x in range(115, 191):
			if image.get_pixel(crest_origin.x + x, crest_origin.y + y).a > 0.03:
				failures.append("Ledge climb crest contains a forbidden scarf-tail silhouette.")
				return

func _verify_restored_run_frames(failures: Array[String]) -> void:
	var archive_names := {
		1: "frame_00_run_001.png",
		2: "frame_01_run_002.png",
		3: "frame_02_run_003.png",
		4: "frame_03_run_004.png",
		5: "frame_04_run_005.png",
		6: "frame_05_run_006.png",
		12: "frame_06_run_012.png",
		20: "frame_07_run_020.png",
		7: "frame_08_run_007.png",
		18: "frame_09_run_018.png",
		8: "frame_10_run_008.png",
	}
	for frame_number in archive_names:
		var path := (
			"res://Assets/Threadborne/Player/Normalized_V2/run/run_%03d.png" %
			frame_number
		)
		var archive_path := (
			"res://Assets/Threadborne/Player/Normalized_V2/run/old_run/%s" %
			archive_names[frame_number]
		)
		var image := _load_imported_image(path)
		if image == null or image.is_empty():
			failures.append("Could not load restored run frame: %s." % path)
			continue
		if image.get_size() != Vector2i(548, 548):
			failures.append("%s is %s; expected the 548 px runtime canvas." % [path, image.get_size()])
			continue

		var archived_image := Image.load_from_file(archive_path)
		if archived_image == null or archived_image.is_empty():
			failures.append("Could not load archived run source: %s." % archive_path)
			continue
		if image.get_size() != archived_image.get_size():
			failures.append(
				"%s size %s does not match archived source size %s." %
				[path, image.get_size(), archived_image.get_size()]
			)
			continue
		if image.get_data() != archived_image.get_data():
			failures.append(
				"%s no longer matches the approved archived original %s." %
				[path, archive_names[frame_number]]
			)

func _verify_movement_visual_tuning(player: Node, failures: Array[String]) -> void:
	if not is_equal_approx(float(player.get("landing_visual_scale_multiplier")), 0.88):
		failures.append("Jump landing must use the corrected 0.88 visual scale.")
	if not (player.get("save_point_sit_visual_scale") as Vector2).is_equal_approx(
		Vector2(0.5, 0.5)
	):
		failures.append("Meditation must use the atlas-matched 0.50 visual scale.")
	if not is_equal_approx(float(player.get("meditation_ap_recharge_multiplier")), 2.0):
		failures.append("Meditation AP recovery must use the approved 2x multiplier.")
	if not is_equal_approx(float(player.get("meditation_heal_interval")), 0.8):
		failures.append("Meditation healing must pulse every 0.8 seconds.")
	if not is_equal_approx(float(player.get("meditation_momentum_cost_per_pulse")), 10.0):
		failures.append("Meditation healing must consume 10 momentum per pulse.")
	if not is_equal_approx(float(player.get("meditation_health_ceiling_ratio")), 0.75):
		failures.append("Meditation healing must stop at 75% health.")
	if not is_equal_approx(float(player.get("meditation_flow_interval_multiplier")), 0.75):
		failures.append("Flow meditation must use the approved 25% faster pulse cadence.")

	var meditation_timers: Array[float] = [8.0, 3.0, 6.0, 0.0, 0.0, 0.0]
	player.set("_action_point_recharge_timers", meditation_timers)
	if int(player.call("_get_meditation_action_point_target_index")) != 1:
		failures.append("Meditation AP recovery must target the spent point closest to full.")
	var restored_timers: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	player.set("_action_point_recharge_timers", restored_timers)
	if not (player.get("landing_visual_offset") as Vector2).is_equal_approx(Vector2(0.0, 5.0)):
		failures.append("Jump landing must retain its ground contact with a 5 px visual offset.")
	if not is_equal_approx(float(player.get("wall_cling_visual_standoff")), 22.0):
		failures.append("Wall cling visual must sit 22 px away from the collision wall.")
	if not is_equal_approx(float(player.get("ledge_climb_duration")), 0.2):
		failures.append("Ledge climb transition must use the approved 0.2 second duration.")
	if not is_equal_approx(
		float(player.get("ground_combo_stationary_visual_scale_multiplier")),
		1.4
	):
		failures.append("Stationary ground attacks must use the corrected 1.4 visual scale.")
	if not is_equal_approx(
		float(player.get("ground_combo_backpedal_visual_scale_multiplier")),
		1.25
	):
		failures.append("Backpedal ground attacks must use the corrected 1.25 visual scale.")

	var sprite := player.get_node("Player Animation") as AnimatedSprite2D
	player.set("is_ledge_hanging", true)
	player.set("is_ledge_climbing", false)
	player.call("update_animations", 0.0)
	if sprite.animation != &"Wall_Cling" or sprite.frame != 0:
		failures.append("Ledge hold must use the stable first Wall Cling pose.")

	player.set("is_ledge_hanging", false)
	player.set("is_ledge_climbing", true)
	for sample in [
		{"progress": 0.1, "frame": 0},
		{"progress": 0.35, "frame": 1},
		{"progress": 0.6, "frame": 2},
		{"progress": 0.9, "frame": 3},
	]:
		var expected_progress := float(sample["progress"])
		var expected_frame := int(sample["frame"])
		player.set(
			"_ledge_climb_elapsed",
			float(player.get("ledge_climb_duration")) * expected_progress
		)
		player.call("update_animations", 0.0)
		if sprite.animation != &"Ledge_Climb" or sprite.frame != expected_frame:
			failures.append(
				"Ledge climb progress %.2f selected %s frame %d; expected frame %d." %
					[expected_progress, sprite.animation, sprite.frame, expected_frame]
			)
	player.set("is_ledge_climbing", false)

	var start := Vector2(0.0, 100.0)
	var target := Vector2(68.0, -14.0)
	var midpoint := player.call("_sample_ledge_climb_arc", start, target, 1, 0.5) as Vector2
	var linear_midpoint := start.lerp(target, 0.5)
	if midpoint.y >= linear_midpoint.y:
		failures.append("Ledge climb midpoint does not rise above the direct teleport path.")
	if not (player.call("_sample_ledge_climb_arc", start, target, 1, 0.0) as Vector2).is_equal_approx(start):
		failures.append("Ledge climb arc does not begin at the hang position.")
	if not (player.call("_sample_ledge_climb_arc", start, target, 1, 1.0) as Vector2).is_equal_approx(target):
		failures.append("Ledge climb arc does not finish on the ledge.")

func _verify_wall_cling_contact_registration(failures: Array[String]) -> void:
	var path := "res://Assets/Threadborne/Player/Normalized_V2/movement/wall_cling_cycle.png"
	var image := _load_imported_image(path)
	if image == null or image.is_empty():
		failures.append("Could not load the wall cling sheet for contact registration.")
		return

	var cell_size := Vector2i(image.get_width() / 2, image.get_height() / 2)
	var reference_right := -1
	var reference_bottom := -1
	for frame_index in 4:
		var origin := Vector2i(
			(frame_index % 2) * cell_size.x,
			(frame_index / 2) * cell_size.y
		)
		var right := -1
		var bottom := -1
		for y in cell_size.y:
			for x in cell_size.x:
				if image.get_pixel(origin.x + x, origin.y + y).a < 0.18:
					continue
				right = maxi(right, x)
				bottom = maxi(bottom, y)

		if right < 0:
			failures.append("Wall cling frame %d is empty." % frame_index)
			continue
		if frame_index == 0:
			reference_right = right
			reference_bottom = bottom
			continue
		if right != reference_right or bottom != reference_bottom:
			failures.append(
				"Wall cling frame %d contact is (%d, %d); expected (%d, %d)." %
				[frame_index, right, bottom, reference_right, reference_bottom]
			)

func _verify_grounded_attack_registration(failures: Array[String]) -> void:
	for sheet in [
		{
			"path": "res://Assets/Threadborne/Player/Normalized_V2/attacks/ground_combo_01.png",
			"grid": Vector2i(6, 4),
			"frames": PackedInt32Array([
				2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
				12, 13, 14, 15, 16, 17, 18, 19, 20,
			]),
		},
		{
			"path": "res://Assets/Threadborne/Player/Normalized_V2/attacks/ground_combo_02.png",
			"grid": Vector2i(5, 5),
			"frames": PackedInt32Array([
				0, 1, 2, 3, 4, 5, 6, 7, 8,
				9, 10, 11, 12, 13, 14, 15, 16,
			]),
		},
	]:
		var path: String = sheet["path"]
		var image := _load_imported_image(path)
		if image == null or image.is_empty():
			failures.append("Could not load grounded attack sheet: %s." % path)
			continue
		var grid: Vector2i = sheet["grid"]
		var cell_size := Vector2i(image.get_width() / grid.x, image.get_height() / grid.y)
		var reference_bottom := -1
		for frame_value in sheet["frames"]:
			var frame_index := int(frame_value)
			var origin := Vector2i(
				(frame_index % grid.x) * cell_size.x,
				(frame_index / grid.x) * cell_size.y
			)
			var bottom := -1
			var visible_pixels := 0
			for y in cell_size.y:
				for x in cell_size.x:
					if image.get_pixel(origin.x + x, origin.y + y).a >= 0.18:
						bottom = maxi(bottom, y)
						visible_pixels += 1
			if visible_pixels == 0:
				failures.append("%s runtime frame cell %d is empty." % [path, frame_index])
				continue
			if reference_bottom < 0:
				reference_bottom = bottom
			elif abs(bottom - reference_bottom) > 1:
					failures.append(
						"%s frame %d foot baseline is %d; expected %d±1." %
						[path, frame_index, bottom, reference_bottom]
					)

func _verify_grapple_gutter_cleanup(failures: Array[String]) -> void:
	var path := "res://Assets/Threadborne/Player/Normalized_V2/grapple/toss_diagonal_cycle.png"
	var image := _load_imported_image(path)
	if image == null or image.is_empty():
		failures.append("Could not load diagonal grapple sheet for gutter verification.")
		return
	var cell_size := Vector2i(image.get_width() / 3, image.get_height() / 2)
	for cleanup in [
		{"frame": 1, "rect": Rect2i(294, 240, 11, 21)},
		{"frame": 4, "rect": Rect2i(305, 244, 9, 16)},
	]:
		var frame_index := int(cleanup.frame)
		var frame_origin := Vector2i(
			(frame_index % 3) * cell_size.x,
			(frame_index / 3) * cell_size.y
		)
		var rect: Rect2i = cleanup["rect"]
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if image.get_pixel(frame_origin.x + x, frame_origin.y + y).a > 0.03:
					failures.append(
						"Diagonal grapple frame %d retains a detached gutter speck." %
						frame_index
					)
					return

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
	const MOVING_ANIMATION := &"Ground_Attack_Combo_2"
	const STATIONARY_ANIMATION := &"Ground_Attack_Combo_2_Stationary"
	const BACKPEDAL_ANIMATION := &"Ground_Attack_Combo_2_Backpedal"
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

	player.call("_reset_ground_combo_chain")
	player.call("_begin_ground_combo_attack", &"forward", &"stationary")
	if player.get("ground_combo_step") != 1:
		failures.append("Stationary attack did not go directly to the standalone double hit.")
	if player.get("current_attack_body_anim") != String(MOVING_ANIMATION):
		failures.append("Stationary attack did not use the logical two-hit finisher.")
	player.set("current_body_anim", String(MOVING_ANIMATION))
	player.set("velocity", Vector2(120.0, 0.0))
	sprite.play(MOVING_ANIMATION)
	sprite.set_frame_and_progress(TEST_FRAME, TEST_PROGRESS)
	player.call("update_animations", 1.0)
	if sprite.animation != STATIONARY_ANIMATION:
		failures.append("A stationary swing did not use its locked visual variant.")
	if sprite.frame != TEST_FRAME or not is_equal_approx(sprite.frame_progress, TEST_PROGRESS):
		failures.append("Moving-to-stationary visual selection did not preserve frame progress.")
	var expected_stationary_scale := Vector2(0.7, 0.7) * 1.4
	if not sprite.scale.is_equal_approx(expected_stationary_scale):
		failures.append(
			"Stationary frame 6 scale is %s; expected consistent scale %s." %
			[sprite.scale, expected_stationary_scale]
		)
	if not is_equal_approx(sprite.position.y, -2.0):
		failures.append(
			"Stationary frame 6 position is %s; per-frame scaling must not move the character." %
			sprite.position.y
		)

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
	player.call("_reset_ground_combo_chain")

func _verify_forward_combo_chain(player: Node, failures: Array[String]) -> void:
	if player.get("ground_combo_1_first_strike_frames") != Vector2i(3, 5):
		failures.append("Forward opener strike window must be frames 3-5.")
	if player.get("ground_combo_1_second_strike_frames") != Vector2i(-1, -1):
		failures.append("Forward opener must have exactly one strike window.")
	if player.get("ground_combo_2_first_strike_frames") != Vector2i(2, 4):
		failures.append("Forward finisher first strike window must be frames 2-4.")
	if player.get("ground_combo_2_second_strike_frames") != Vector2i(9, 11):
		failures.append("Forward finisher second strike window must be frames 9-11.")
	if player.get("stationary_combo_2_first_strike_frames") != Vector2i(5, 9):
		failures.append("Stationary double hit first strike window must be frames 5-9.")
	if player.get("stationary_combo_2_second_strike_frames") != Vector2i(10, 15):
		failures.append("Stationary double hit second strike window must be frames 10-15.")
	if player.get("backpedal_combo_1_first_strike_frames") != Vector2i(3, 11):
		failures.append("Backpedal opener strike window must be frames 3-11.")
	if player.get("backpedal_combo_2_first_strike_frames") != Vector2i(5, 12):
		failures.append("Backpedal finisher first strike window must be frames 5-12.")
	if player.get("backpedal_combo_2_second_strike_frames") != Vector2i(13, 16):
		failures.append("Backpedal finisher second strike window must be frames 13-16.")
	if not is_equal_approx(
		float(player.get("ground_combo_2_moving_visual_scale_multiplier")),
		1.0
	):
		failures.append("Moving ground finisher must use the atlas-native 1.0 visual scale.")

	player.call("_reset_ground_combo_chain")
	player.set("velocity", Vector2(120.0, 0.0))
	Input.action_press("move_right")
	player.call("_begin_ground_combo_attack", &"forward", &"moving")
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
	Input.action_release("move_right")

	player.call("_begin_ground_combo_attack", &"forward", &"stationary")
	if player.get("ground_combo_step") != 1:
		failures.append("Standalone stationary attack did not begin at the double-hit step.")
	player.set("ground_combo_queued", true)
	player.set("ground_combo_queued_family", &"forward")
	player.call("_finish_ground_combo_attack")
	if player.get("ground_combo_step") != -1 or player.get("ground_combo_family") != &"":
		failures.append("Standalone stationary double hit did not reset after completion.")
	if player.get("is_attacking"):
		failures.append("Standalone stationary double hit incorrectly chained into another attack.")

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
