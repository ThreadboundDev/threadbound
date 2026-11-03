extends Node

const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")
const BASE_GRAPPLE_ANIMATION_LIBRARY := preload(
	"res://Src/Equipment/base_grapple_animation_library.tres"
)
const COLORED_GRAPPLE_SCENES := {
	"Blue": preload("res://Src/Equipment/blue_gloves.tscn"),
	"Yellow": preload("res://Src/Equipment/yellow_gloves.tscn"),
}
const COLORED_WRIST_SCENES := {
	"Red": preload("res://Src/Equipment/red_gloves.tscn"),
	"Blue": preload("res://Src/Equipment/blue_gloves.tscn"),
	"Yellow": preload("res://Src/Equipment/yellow_gloves.tscn"),
}
const BASE_GLOVES_SCENE := preload("res://Src/Equipment/base_gloves.tscn")

const EXPECTED_ANIMATIONS := {
	&"Air_Double_Attack": {"frames": 27, "fps": 40.0, "loop": false},
	&"Pogo_Attack": {"frames": 11, "fps": 24.0, "loop": false},
	&"Grapple_Diagonal": {"frames": 6, "fps": 18.0, "loop": false},
	&"Grapple_Horizontal": {"frames": 6, "fps": 18.0, "loop": false},
	&"Grapple_Strike": {"frames": 11, "fps": 40.0, "loop": false},
	&"Ground_Attack_Combo_1": {"frames": 14, "fps": 30.0, "loop": false},
	&"Ground_Attack_Combo_1_Backpedal": {"frames": 14, "fps": 30.0, "loop": false},
	&"Ground_Attack_Combo_2": {"frames": 19, "fps": 30.0, "loop": false},
	&"Ground_Attack_Combo_2_Stationary": {"frames": 19, "fps": 30.0, "loop": false},
	&"Ground_Attack_Combo_2_Backpedal": {"frames": 19, "fps": 30.0, "loop": false},
	&"Hurt": {"frames": 11, "fps": 60.0, "loop": false},
	&"Jump_Apex": {"frames": 4, "fps": 8.0, "loop": true},
	&"Jump_Ascent": {"frames": 4, "fps": 8.0, "loop": true},
	&"Jump_Descent": {"frames": 4, "fps": 8.0, "loop": true},
	&"Jump_Land": {"frames": 4, "fps": 12.0, "loop": false},
	&"Pogo_Rebound": {"frames": 4, "fps": 24.0, "loop": false},
	&"Ledge_Climb": {"frames": 4, "fps": 20.0, "loop": false},
	&"Run": {"frames": 11, "fps": 24.0, "loop": true},
	&"Swim": {"frames": 38, "fps": 24.0, "loop": true},
	&"Sit": {"frames": 48, "fps": 18.0, "loop": false},
	&"Wall_Cling": {"frames": 4, "fps": 6.0, "loop": true},
}

func _ready() -> void:
	var player := PLAYER_SCENE.instantiate()
	var clock := player.get_node("AnimationClock") as PlayerAnimationClock
	var failures: Array[String] = []
	add_child(player)
	_verify_action_catalog(clock, failures)
	_verify_action_timings(clock, failures)
	_verify_hurt_animation(player, clock, failures)
	_verify_movement_visual_tuning(player, failures)
	_verify_jump_glove_frame_sync(player, clock, failures)
	_verify_ground_attack_variant_locking(player, clock, failures)
	_verify_forward_combo_chain(player, failures)
	_verify_retired_up_attack(player, clock, failures)
	_verify_pogo_rebound(player, clock, failures)
	_verify_neutral_special_grapple_pose_sampling(failures)
	_verify_colored_grapple_art_alignment(failures)
	_verify_colored_wrist_art_corrections(failures)
	player.free()
	if failures.is_empty():
		print("PLAYER_ANIMATION_VERIFY_OK: clock metadata, action selection, glove synchronization, ledges, meditation, combo locking and pogo")
	else:
		for failure in failures: push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)

func _verify_pogo_rebound(
	player: CharacterBody2D,
	clock: PlayerAnimationClock,
	failures: Array[String]
) -> void:
	player.call("_begin_air_double_attack", Vector2.DOWN)
	if player.get("current_attack_body_anim") != "Pogo_Attack":
		failures.append("A downward aerial attack did not select the one-strike pogo clip.")
	player.velocity = Vector2(30.0, 400.0)
	player.call("_perform_pogo_rebound")
	if not is_equal_approx(player.velocity.y, -float(player.get("pogo_rebound_speed"))):
		failures.append("Pogo rebound did not apply its configured upward speed.")
	if float(player.get("pogo_rebound_speed")) < 1000.0:
		failures.append("Pogo rebound is weaker than the intended jump-strength launch.")
	if float(player.get("pogo_rebound_gravity_timer")) <= 0.0:
		failures.append("Pogo rebound did not start its gravity grace window.")
	if not is_equal_approx(float(player.call("_get_current_gravity")), float(player.get("gravity"))):
		failures.append("Pogo gravity grace did not protect the launch from jump-cut gravity.")
	if player.get("current_attack_uses_air_double") or player.get("is_attacking"):
		failures.append("Pogo rebound did not release the completed aerial attack.")
	if not is_zero_approx(float(player.get("attack_cooldown_timer"))):
		failures.append("Pogo rebound did not refresh the aerial strike recovery.")
	if clock.animation != &"Pogo_Rebound":
		failures.append("Pogo rebound did not begin its dedicated animation.")


func _verify_colored_grapple_art_alignment(failures: Array[String]) -> void:
	for variant_name in COLORED_GRAPPLE_SCENES:
		var gloves := (COLORED_GRAPPLE_SCENES[variant_name] as PackedScene).instantiate()
		var needle := gloves.get_node("Equipment/RightHandAnchor/RopeHangAnchor/DanglingNeedleSprite") as Sprite2D
		var attach_point := needle.get_node("NeedleAttachPoint") as Marker2D
		var pose_player := gloves.get_node("Equipment/AnimationPlayer") as AnimationPlayer
		if absf(needle.rotation) >= PI * 0.25:
			failures.append("%s dangling needle no longer points outward from its wrist artwork." % variant_name)
		if attach_point.position.x <= 0.0:
			failures.append("%s dangling needle rope attachment is not on its wrist-facing end." % variant_name)
		for animation_name in pose_player.get_animation_list():
			var animation := pose_player.get_animation(animation_name)
			for track_index in animation.get_track_count():
				var track_path := String(animation.track_get_path(track_index))
				if "DanglingNeedleSprite" in track_path or "NeedleAttachPoint" in track_path:
					failures.append("%s art-specific needle correction is unexpectedly animation-keyed." % variant_name)
		gloves.free()

func _verify_colored_wrist_art_corrections(failures: Array[String]) -> void:
	var base_gloves := BASE_GLOVES_SCENE.instantiate()
	var base_pivot := base_gloves.get_node("Equipment/RightHandAnchor/WristWrapPivot") as Node2D
	for variant_name in COLORED_WRIST_SCENES:
		var gloves := (COLORED_WRIST_SCENES[variant_name] as PackedScene).instantiate()
		var pivot := gloves.get_node("Equipment/RightHandAnchor/WristWrapPivot") as Node2D
		var pose_player := gloves.get_node("Equipment/AnimationPlayer") as AnimationPlayer
		if not pivot.transform.is_equal_approx(base_pivot.transform):
			failures.append("%s wrist artwork correction leaked onto the shared animated pivot." % variant_name)
		for animation_name in pose_player.get_animation_list():
			var animation := pose_player.get_animation(animation_name)
			for track_index in animation.get_track_count():
				if "WristWrapSprite" in String(animation.track_get_path(track_index)):
					failures.append("%s art-specific wrist correction is unexpectedly animation-keyed." % variant_name)
		gloves.free()
	base_gloves.free()

func _verify_neutral_special_grapple_pose_sampling(failures: Array[String]) -> void:
	var animation := BASE_GRAPPLE_ANIMATION_LIBRARY.get_animation(&"Neutral_Special_Attack")
	if animation == null:
		failures.append("Base grapple is missing its neutral-special follow animation.")
		return

	for track_index in animation.get_track_count():
		if animation.track_get_interpolation_type(track_index) != Animation.INTERPOLATION_NEAREST:
			failures.append(
				"Base grapple neutral-special track %d interpolates between clock frames." %
				track_index
			)
		if animation.value_track_get_update_mode(track_index) != Animation.UPDATE_DISCRETE:
			failures.append(
				"Base grapple neutral-special track %d does not update on discrete frames." %
					track_index
			)

func _verify_jump_glove_frame_sync(
	player: Node,
	clock: PlayerAnimationClock,
	failures: Array[String]
) -> void:
	player.call("play_character_anim", "Jump_Ascent")
	var gloves := player.get("current_gloves") as Node2D
	if gloves == null:
		failures.append("Jump glove frame sync could not find the equipped gloves.")
		return
	var glove_player := gloves.get_node_or_null("Equipment/AnimationPlayer") as AnimationPlayer
	var hand_anchor := gloves.get_node_or_null("Equipment/RightHandAnchor") as Node2D
	if glove_player == null or hand_anchor == null:
		failures.append("Jump glove frame sync is missing its animation nodes.")
		return
	clock.set_frame_and_progress(1, 0.75)
	player.call("_sync_current_glove_pose_to_body_frame")
	if not is_equal_approx(glove_player.current_animation_position, 0.125):
		failures.append("Jump glove playback did not lock to displayed body frame 1.")
	if not hand_anchor.position.is_equal_approx(Vector2(-18, -15)):
		failures.append(
			"Jump frame 1 glove is at %s instead of its authored wrist position." %
				hand_anchor.position
		)

func _verify_action_catalog(
	clock: PlayerAnimationClock,
	failures: Array[String]
) -> void:
	for animation_name: StringName in EXPECTED_ANIMATIONS:
		if not clock.has_animation(animation_name):
			failures.append(
				"%s is not serialized in the action timing data." % animation_name
			)

func _verify_action_timings(clock: PlayerAnimationClock, failures: Array[String]) -> void:
	if clock.has_animation(&"Ground_Attack_Combo_1_Stationary"):
		failures.append("Discarded stationary opener remains in the action clock.")
	for name in clock.get_animation_names():
		if name.begins_with("Ground_Up_Combo_"):
			failures.append("Retired upward attack remains active: %s" % name)
	for name: StringName in EXPECTED_ANIMATIONS:
		var expected: Dictionary = EXPECTED_ANIMATIONS[name]
		if not clock.has_animation(name):
			failures.append("Missing action: %s" % name)
			continue
		if clock.get_frame_count(name) != expected.frames:
			failures.append("%s frame count changed." % name)
		if not is_equal_approx(clock.get_animation_speed(name),expected.fps):
			failures.append("%s FPS changed." % name)
		if clock.get_animation_loop(name) != expected.loop:
			failures.append("%s loop mode changed." % name)
		for index in clock.get_frame_count(name):
			if not is_equal_approx(clock.get_frame_duration(name,index),1.0):
				failures.append("%s frame %d duration changed." % [name,index])

func _verify_hurt_animation(
	player: CharacterBody2D,
	clock: PlayerAnimationClock,
	failures: Array[String]
) -> void:
	player.is_hurt = true
	player._hurt_animation_active = true
	player.update_animations(0.0)
	if clock.animation != &"Hurt":
		failures.append("Hurt does not take animation priority while the player is hurt.")
	player.is_hurt = false
	player.update_animations(0.0)
	if clock.animation == &"Hurt":
		failures.append("Hurt remains active after the hurt state clears.")
	player.is_hurt = true
	player._hurt_animation_active = false
	player.update_animations(0.0)
	if clock.animation == &"Hurt":
		failures.append("Airborne damage incorrectly forces the grounded Hurt animation.")
	player.is_hurt = false


func _verify_movement_visual_tuning(player: Node, failures: Array[String]) -> void:
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
	if not is_equal_approx(float(player.get("prototype_swim_visual_scale_multiplier")), 0.78):
		failures.append("Swimming must use the corrected 0.78 visual scale multiplier.")
	var meditation_timers: Array[float] = [8.0, 3.0, 6.0, 0.0, 0.0, 0.0]
	player.set("_action_point_recharge_timers", meditation_timers)
	if int(player.call("_get_meditation_action_point_target_index")) != 1:
		failures.append("Meditation AP recovery must target the spent point closest to full.")
	var restored_timers: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	player.set("_action_point_recharge_timers", restored_timers)
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

	var clock := player.get_node("AnimationClock") as PlayerAnimationClock
	player.set("is_ledge_hanging", true)
	player.set("is_ledge_climbing", false)
	player.call("update_animations", 0.0)
	if clock.animation != &"Wall_Cling" or clock.frame != 0:
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
		if clock.animation != &"Ledge_Climb" or clock.frame != expected_frame:
			failures.append(
				"Ledge climb progress %.2f selected %s frame %d; expected frame %d." %
					[expected_progress, clock.animation, clock.frame, expected_frame]
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


func _verify_ground_attack_variant_locking(
	player: Node,
	clock: PlayerAnimationClock,
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
	clock.play(MOVING_ANIMATION)
	clock.set_frame_and_progress(TEST_FRAME, TEST_PROGRESS)
	player.call("update_animations", 1.0)
	if clock.animation != STATIONARY_ANIMATION:
		failures.append("A stationary swing did not use its locked visual variant.")
	if player.call("_get_equipment_attack_follow_anim") != String(STATIONARY_ANIMATION):
		failures.append("Stationary attack selected the moving glove follow pose.")
	var equipped_gloves := player.get("current_gloves") as Node2D
	if equipped_gloves == null or not equipped_gloves.scale.is_equal_approx(Vector2(1.4, 1.4)):
		failures.append("Stationary attack did not scale its glove pose with the body.")
	if clock.frame != TEST_FRAME or not is_equal_approx(clock.frame_progress, TEST_PROGRESS):
		failures.append("Moving-to-stationary visual selection did not preserve frame progress.")
	player.set("velocity", Vector2(-120.0, 0.0))
	player.call("update_animations", -1.0)
	if clock.animation != STATIONARY_ANIMATION:
		failures.append("Stationary visual selection changed in the middle of a swing.")
	if clock.frame != TEST_FRAME or not is_equal_approx(clock.frame_progress, TEST_PROGRESS):
		failures.append("Locked stationary playback lost frame progress.")

	player.set("ground_attack_visual_mode", &"backpedal")
	player.call("update_animations", -1.0)
	if clock.animation != BACKPEDAL_ANIMATION:
		failures.append("A new backpedal swing did not use the backpedal visual variant.")
	if player.call("_get_equipment_attack_follow_anim") != String(BACKPEDAL_ANIMATION):
		failures.append("Backpedal attack selected the moving glove follow pose.")
	if equipped_gloves == null or not equipped_gloves.scale.is_equal_approx(Vector2(1.25, 1.25)):
		failures.append("Backpedal attack did not scale its glove pose with the body.")
	if clock.frame != TEST_FRAME or not is_equal_approx(clock.frame_progress, TEST_PROGRESS):
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
	clock: PlayerAnimationClock,
	failures: Array[String]
) -> void:
	if player.call("_get_ground_combo_family", Vector2.UP) != &"forward":
		failures.append("Upward ground input did not route to the forward combo.")
	if not is_equal_approx(float(player.get("ground_combo_hitbox_arc_degrees")), 130.0):
		failures.append("Forward ground hit coverage must use the approved 130-degree arc.")
	if clock.has_animation(&"Ground_Up_Combo_1"):
		failures.append("Ground_Up_Combo_1 still exists in the active action timing data.")
	if clock.has_animation(&"Ground_Up_Combo_2"):
		failures.append("Ground_Up_Combo_2 still exists in the active action timing data.")
	if clock.has_animation(&"Attack"):
		failures.append("Retired green-smear Attack still exists in the active action timing data.")
