extends Node2D

const PLAYER = preload("res://Src/Characters/Player/player.tscn")
const REVIEW_DIR = "C:/Users/chase/.codex/visualizations/2026/09/14/01a0a082-1409-7791-a66d-d1c90fee4a99/implementation"
var hit_count := 0

func _ready() -> void:
	var player = PLAYER.instantiate()
	add_child(player)
	await get_tree().process_frame
	player.set_physics_process(false)
	player.set_process(false)
	player.position = Vector2(400, 300)
	for camera in player.find_children("*", "Camera2D", true, false):
		camera.enabled = false
	var visual: PlayerLive3DVisual = player.live_3d_visual
	var stroke := SwordSweepVFX.new()
	add_child(stroke)
	var no_accents: Array[Color] = []
	for style in range(3):
		for frame in range(8):
			stroke.set_sweep((frame + 0.5) * (0.85 if style == 1 else 1.32) / 8.0, 195.0, 90.0,
				Transform2D(PI, Vector2.ZERO), no_accents, false, PackedVector2Array(), style)
			assert(stroke.atlas_frame == frame and stroke.stroke_style == style)
			assert(stroke.global_transform.x.x < 0 and stroke.global_transform.y.y > 0)
	stroke.clear()
	assert(not stroke.visible)
	stroke.queue_free()
	var animator: AnimationPlayer = visual.get("_animation_player")
	var skeleton: Skeleton3D = visual.get("_skeleton")
	var moving_body: Array[Quaternion] = []
	for source_frame in [1, 4, 7, 12, 16]:
		visual._play_action(&"jump_1", &"", 0.0, true)
		animator.seek(float(source_frame + 6) / 30.0, true)
		var jump_body: Dictionary = {}
		for bone in range(skeleton.get_bone_count()):
			if skeleton.get_bone_name(bone) not in ["upper_arm.R", "forearm.R", "hand.R"]:
				jump_body[bone] = skeleton.get_bone_pose_rotation(bone)
		visual.play_air_attack(1.0)
		animator.seek(float(source_frame) / 30.0, true)
		for bone in jump_body:
			assert(absf(skeleton.get_bone_pose_rotation(bone).dot(jump_body[bone])) > 0.9999,
				"Non-sword-arm bones must follow the moving jump")
		moving_body.append(skeleton.get_bone_pose_rotation(skeleton.find_bone("thigh.R")))
	assert(absf(moving_body[0].dot(moving_body[-1])) < 0.999,
		"The jump body must move during the attack")
	var elbow_angles: Array[float] = []
	for source_frame in [3, 6]:
		animator.seek(float(source_frame) / 30.0, true)
		var shoulder := skeleton.get_bone_global_pose(skeleton.find_bone("upper_arm.R")).origin
		var elbow := skeleton.get_bone_global_pose(skeleton.find_bone("forearm.R")).origin
		var hand := skeleton.get_bone_global_pose(skeleton.find_bone("hand.R")).origin
		elbow_angles.append((shoulder-elbow).angle_to(hand-elbow))
	assert(elbow_angles[1] > elbow_angles[0] + 0.4, "Elbow must visibly open through the cut")
	assert(visual.get_action_duration(&"air_light_1") > 0.3)
	assert(visual.get_action_duration(&"attack_1") > 0.0, "Preserve overhead special candidate")
	visual.play_gameplay_animation(&"Block_Backpedal")
	assert(animator.speed_scale > 0)
	visual.play_gameplay_animation(&"Block_Forward")
	assert(animator.speed_scale < 0)
	var backward_start := animator.current_animation_position
	animator.advance(0.05)
	assert(animator.current_animation_position < backward_start)
	visual.play_gameplay_animation(&"Block_Backpedal")
	assert(animator.speed_scale > 0)
	var target := HurtboxComponent.new()
	add_child(target)
	target.hit_received.connect(func(_damage): hit_count += 1)
	for speed in [1.0, 1.35, 1.8, 2.5]:
		for facing in [-1, 1]:
			player.last_direction = facing
			player.air_attack_playback_speed = speed
			player._begin_air_double_attack(Vector2(facing, 0))
			assert(visual.get("_current_action") == &"air_light_1")
			hit_count = 0
			for frame in range(25):
				animator.seek(float(frame) / 30.0, true)
				player._update_air_double_attack()
				player.attack_hitbox._on_area_entered(target)
				player.attack_hitbox._on_area_entered(target)
			assert(hit_count == 1, "Exactly one hit per neutral air activation")
			player._cancel_air_double_attack()
			assert(not player.attack_hitbox.active)
	# Advance the real animation clock at varied rendering rates and speeds.
	for fps in [30, 60, 120]:
		for speed in [1.0, 1.35, 1.8, 2.5]:
			player.air_attack_playback_speed = speed
			player._begin_air_double_attack(Vector2.RIGHT)
			hit_count = 0
			for tick in range(ceil(1.0 * fps)):
				animator.advance(1.0 / float(fps))
				player._update_air_double_attack()
				player.attack_hitbox._on_area_entered(target)
			assert(hit_count == 1, "One strike must survive playback speed and frame-rate changes")
			player._finish_air_double_attack()
	player.last_direction = 1
	player._begin_air_double_attack(Vector2.LEFT)
	assert(player.last_direction == -1 and player.attack_direction == Vector2.LEFT)
	player._cancel_air_double_attack()
	player.last_direction = 1
	player.air_attack_playback_speed = 1.35
	player._begin_air_double_attack(Vector2.RIGHT)
	player.flow_state_aura.set_identity_mix(1.0, 0.4, 0.0)
	var channels: Array[Color] = player.flow_state_aura.get_attack_identity_channels()
	assert(channels.size() == 2 and is_equal_approx(channels[1].a, 0.4))
	channels.clear()
	assert(player.flow_state_aura.get_attack_identity_channels().size() == 2)
	if DisplayServer.get_name() != "headless":
		RenderingServer.set_default_clear_color(Color(0.08, 0.12, 0.17))
		animator.pause()
		DirAccess.make_dir_recursive_absolute(REVIEW_DIR)
		for frame in range(17):
			animator.seek(float(frame) / 30.0, true)
			visual._update_sword_smears(0.0)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(REVIEW_DIR + "/air_review_%02d.png" % frame)
			visual.sword_smear_enabled = false
			visual._update_sword_smears(0.0)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(REVIEW_DIR + "/air_body_%02d.png" % frame)
			visual.sword_smear_enabled = true
	player._finish_air_double_attack()
	if DisplayServer.get_name() != "headless":
		for strike in range(3):
			player._begin_ground_combo_attack(&"forward", &"forward")
			player.ground_combo_step = strike
			visual.play_ground_combo_strike(strike, false, 1.45)
			animator.pause()
			var windows: Array[Vector2i] = player._get_ground_combo_strike_frames()
			var frame := (windows[0].x + windows[0].y) / 2.0
			animator.seek(frame / 30.0, true)
			visual._update_sword_smears(0.0)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(REVIEW_DIR + "/ground_review_%d.png" % strike)
			player._finish_cancelled_attack()
	visual._update_sword_smears(0.0)
	assert(not visual.get("_sword_sweep").visible)
	print("AIR_LIGHT_PASS: single hit, both facings, four speeds, reverse guard, identity snapshot, cleanup")
	player.queue_free()
	target.queue_free()
	await get_tree().process_frame
	get_tree().quit()
