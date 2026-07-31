extends Node

const TENSIONER_SCENE := preload("res://Src/Enemies/Tensioner/tensioner.tscn")
const TELEGRAPH_SCENE := preload("res://Src/VFX/ground_attack_telegraph.tscn")
const WORLD_SCENE_PATH := "res://Src/Environment/World/Chamber Of The First Weave.tscn"
const EXPECTED_BODY_SIZE := Vector2(212.3055, 164.7745)
const EXPECTED_BODY_FLOOR := 0.9025
const EXPECTED_HURT_FLOOR := -2.205
const WALK_FRAME_ALPHA_FOOT_OFFSET := 242.0
const EXPECTED_SPRITE_FOOT := 9.835

var _failures := PackedStringArray()


func _ready() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	var tensioner := TENSIONER_SCENE.instantiate() as Tensioner
	_expect(tensioner != null, "Tensioner scene instantiates.")
	if not tensioner:
		_finish()
		return

	add_child(tensioner)
	await get_tree().process_frame
	_verify_scale_and_floor_anchors(tensioner)
	_verify_attack_shape_and_timing(tensioner)
	_verify_hurt_response(tensioner)
	_verify_landing_plan(tensioner)
	_verify_floor_target_rerouting()
	_verify_ballistic_solution(tensioner)
	_verify_world_instances()
	_verify_marker_cancellation(tensioner)
	await _verify_miss_safe_impact_shake(tensioner)
	await _verify_ground_telegraph()

	tensioner.free()
	_finish()


func _verify_scale_and_floor_anchors(tensioner: Tensioner) -> void:
	var sprite := tensioner.get_node("Visuals/Sprite2D") as Sprite2D
	_expect(sprite != null, "Tensioner has an authored sprite.")
	if sprite:
		_expect(
			sprite.scale.is_equal_approx(Vector2(0.44, 0.44)),
			"Tensioner sprite is exactly 10% larger."
		)
		var sprite_foot := (
			sprite.position.y
			+ WALK_FRAME_ALPHA_FOOT_OFFSET * sprite.scale.y
		)
		_expect(
			is_equal_approx(sprite_foot, EXPECTED_SPRITE_FOOT),
			"Tensioner sprite growth preserves the audited opaque-foot baseline."
		)

	var body_shape_node := tensioner.get_node("CollisionShape2D") as CollisionShape2D
	var hurt_shape_node := tensioner.get_node("Hurtbox/CollisionShape2D") as CollisionShape2D
	var contact_shape_node := (
		tensioner.get_node("ContactHitbox/CollisionShape2D") as CollisionShape2D
	)
	for shape_node in [body_shape_node, hurt_shape_node, contact_shape_node]:
		var rectangle := shape_node.shape as RectangleShape2D if shape_node else null
		_expect(rectangle != null, "Tensioner body-facing collision uses a rectangle.")
		if rectangle:
			_expect(
				rectangle.size.is_equal_approx(EXPECTED_BODY_SIZE),
				"Tensioner body, hurtbox, and contact hitbox are exactly 10% larger."
			)

	if body_shape_node and body_shape_node.shape is RectangleShape2D:
		var body_rectangle := body_shape_node.shape as RectangleShape2D
		_expect(
			is_equal_approx(
				body_shape_node.position.y + body_rectangle.size.y * 0.5,
				EXPECTED_BODY_FLOOR
			),
			"Tensioner body growth preserves its floor edge."
		)
	for shape_node in [hurt_shape_node, contact_shape_node]:
		if shape_node and shape_node.shape is RectangleShape2D:
			var rectangle := shape_node.shape as RectangleShape2D
			_expect(
				is_equal_approx(
					shape_node.position.y + rectangle.size.y * 0.5,
					EXPECTED_HURT_FLOOR
				),
				"Tensioner hurt/contact growth preserves its floor edge."
			)


func _verify_attack_shape_and_timing(tensioner: Tensioner) -> void:
	var attack_area_shape := (
		tensioner.get_node("AttackArea/CollisionShape2D") as CollisionShape2D
	)
	var attack_hitbox_shape := (
		tensioner.get_node("AttackHitbox/CollisionShape2D") as CollisionShape2D
	)
	var area_rectangle := attack_area_shape.shape as RectangleShape2D
	var hitbox_rectangle := attack_hitbox_shape.shape as RectangleShape2D
	_expect(
		area_rectangle != null and area_rectangle.size.is_equal_approx(Vector2(310.0, 176.0)),
		"Tensioner keeps its broad AI attack trigger."
	)
	_expect(
		hitbox_rectangle != null and hitbox_rectangle.size.is_equal_approx(Vector2(330.0, 72.0)),
		"Tensioner stomp uses a distinct low 330x72 damaging hitbox."
	)
	_expect(
		is_equal_approx(tensioner.get_node("AttackHitbox").position.y, -36.0),
		"Tensioner stomp hitbox is floor-aligned."
	)

	var stats := tensioner.stats
	_expect(stats != null, "Tensioner has combat stats.")
	if not stats:
		return
	_expect(is_equal_approx(stats.attack_windup, 0.58), "Tensioner windup is 0.58 seconds.")
	_expect(is_equal_approx(stats.attack_active_time, 0.14), "Tensioner active time is 0.14 seconds.")
	_expect(is_equal_approx(stats.attack_recovery, 0.33), "Tensioner recovery is 0.33 seconds.")
	var total_duration := stats.attack_windup + stats.attack_active_time + stats.attack_recovery
	_expect(is_equal_approx(total_duration, 1.05), "Tensioner smash remains a 1.05-second 36-frame attack.")
	var fps := float(tensioner.attack_frame_count) / total_duration
	_expect(
		int(floor(stats.attack_windup * fps)) == 19,
		"Tensioner impact begins at the intended frame-19/20 transition."
	)
	_expect(
		int(floor((stats.attack_windup + stats.attack_active_time) * fps)) == 24,
		"Tensioner active window closes on the intended frame 24."
	)

	var main_telegraph := tensioner.get_node_or_null("GroundAttackTelegraph")
	_expect(main_telegraph is GroundAttackTelegraph, "Tensioner owns its stomp footprint VFX.")
	_expect(
		is_equal_approx(tensioner.call("_get_smash_hitbox_width"), 330.0),
		"Stomp footprint width is derived from the damaging hitbox."
	)
	_expect(
		tensioner.thread_missile_scene != null,
		"Tensioner scene retains its missile projectile."
	)
	_expect(
		tensioner.thread_smash_min_missile_count == 2
		and tensioner.thread_smash_max_missile_count == 4,
		"Tensioner runtime configuration selects a variable two-to-four missile pattern."
	)
	_expect(
		Tensioner.THREAD_SMASH_FLOOR_COLLISION_MASK == 1,
		"Tensioner landing solver raycasts only floor layer 1."
	)
	var damage := tensioner.call("_build_attack_damage") as DamageData
	_expect(
		damage != null
		and is_zero_approx(damage.screen_shake_strength)
		and not damage.use_receiver_screen_shake_fallback,
		"Tensioner damage cannot duplicate its miss-safe impact shake."
	)


func _verify_hurt_response(tensioner: Tensioner) -> void:
	var stats := tensioner.stats
	if not stats:
		return
	_expect(stats.use_polished_hurt_response, "Tensioner opts into polished hurt response.")
	_expect(
		is_equal_approx(stats.incoming_knockback_multiplier, 0.75),
		"Tensioner has heavy 0.75x incoming knockback."
	)
	_expect(
		is_equal_approx(stats.incoming_hitstun_multiplier, 0.90),
		"Tensioner trims incoming hitstun to 0.90x."
	)
	_expect(
		is_equal_approx(stats.hurt_knockback_deceleration, 700.0),
		"Tensioner knockback decelerates at the intended rate."
	)
	_expect(stats.hurt_motion_uses_gravity, "Tensioner hurt motion keeps gravity.")
	_expect(
		is_equal_approx(stats.hurt_visual_recoil_distance, 6.0),
		"Tensioner uses restrained six-pixel visual recoil."
	)
	_expect(
		is_equal_approx(stats.hurt_visual_recoil_duration, 0.13),
		"Tensioner visual recoil lasts 0.13 seconds."
	)


func _verify_landing_plan(tensioner: Tensioner) -> void:
	_expect(
		is_equal_approx(tensioner.thread_smash_landing_span, 600.0),
		"Tensioner targets a roughly 600-pixel missile field."
	)
	_expect(
		tensioner.thread_smash_landing_jitter <= Tensioner.THREAD_SMASH_MAX_LANDING_JITTER,
		"Tensioner landing jitter never exceeds 18 pixels."
	)
	_expect(
		is_equal_approx(tensioner.thread_smash_min_flight_time, 0.72)
		and is_equal_approx(tensioner.thread_smash_max_flight_time, 1.02),
		"Tensioner missile flight window is 0.72-1.02 seconds."
	)

	for missile_count in range(2, 5):
		var random_source := RandomNumberGenerator.new()
		random_source.seed = 8000 + missile_count
		var offsets := tensioner.call(
			"_build_thread_smash_landing_offsets",
			missile_count,
			random_source
		) as PackedFloat32Array
		_expect(offsets.size() == missile_count, "Landing plan preserves its 2-4 missile count.")
		if offsets.size() != missile_count:
			continue

		var step := tensioner.thread_smash_landing_span / float(missile_count - 1)
		for index in range(offsets.size()):
			var expected_base := -tensioner.thread_smash_landing_span * 0.5 + step * float(index)
			_expect(
				absf(offsets[index] - expected_base) <= 18.001,
				"Each missile lane remains within the 18-pixel jitter budget."
			)
			if index > 0:
				_expect(
					offsets[index] - offsets[index - 1]
					>= tensioner.thread_smash_min_landing_spacing,
					"Every missile landing lane keeps at least 120 pixels of spacing."
				)

		_expect(
			absf((offsets[-1] - offsets[0]) - tensioner.thread_smash_landing_span) <= 36.001,
			"Missile endpoints cover roughly the configured 600-pixel span."
		)
		var widest_gap := float(tensioner.call(
			"_get_widest_thread_smash_safe_gap",
			offsets
		))
		_expect(
			widest_gap >= tensioner.thread_smash_safe_gap_width,
			"Every deterministic missile plan guarantees a player-sized safe gap."
		)

func _verify_floor_target_rerouting() -> void:
	var probe := FloorTargetProbe.new()
	var requested_offsets := PackedFloat32Array([
		-300.0,
		-100.0,
		100.0,
		300.0,
	])
	var landing_points := probe.call(
		"_build_thread_smash_floor_targets",
		0.0,
		requested_offsets
	) as PackedVector2Array
	_expect(
		landing_points.size() == requested_offsets.size(),
		"Failed floor lanes reroute without reducing a valid two-to-four pattern."
	)
	for landing_point in landing_points:
		_expect(
			not is_equal_approx(landing_point.x, probe.blocked_lane_x),
			"Floor-target rerouting does not retain the rejected lane."
		)
	for index in range(1, landing_points.size()):
		_expect(
			landing_points[index].x - landing_points[index - 1].x
			>= probe.thread_smash_safe_gap_width
				+ probe.thread_smash_marker_radius * 2.0,
			"Rerouted floor targets retain the guaranteed safe spacing."
		)
	probe.free()


func _verify_marker_cancellation(tensioner: Tensioner) -> void:
	var far_marker := TELEGRAPH_SCENE.instantiate() as GroundAttackTelegraph
	var far_missile := tensioner.thread_missile_scene.instantiate() as ThreadMissile
	add_child(far_marker)
	add_child(far_missile)
	far_marker.play_landing_marker(32.0, 1.0)
	far_missile.position = Vector2(240.0, -180.0)
	far_missile.set("_is_impacting", true)
	tensioner.call(
		"_on_thread_smash_missile_collision",
		far_missile,
		far_missile,
		far_marker,
		Vector2.ZERO
	)
	_expect(
		far_marker.is_queued_for_deletion(),
		"An intercepted missile cancels its distant landing marker before false impact."
	)

	var exit_marker := TELEGRAPH_SCENE.instantiate() as GroundAttackTelegraph
	var exit_missile := tensioner.thread_missile_scene.instantiate() as ThreadMissile
	add_child(exit_marker)
	add_child(exit_missile)
	exit_marker.play_landing_marker(32.0, 1.0)
	exit_missile.position = Vector2(-220.0, -160.0)
	tensioner.call(
		"_on_thread_smash_missile_exiting",
		exit_missile,
		exit_marker,
		Vector2.ZERO
	)
	_expect(
		exit_marker.is_queued_for_deletion(),
		"A missile removed away from its floor target cancels the pending marker."
	)
	far_missile.free()
	exit_missile.free()


func _verify_ballistic_solution(tensioner: Tensioner) -> void:
	var start := Vector2(-30.0, -12.0)
	var landing := Vector2(280.0, 0.0)
	var flight_time := 0.87
	var gravity := 1650.0
	var velocity := tensioner.call(
		"_solve_thread_smash_ballistic_velocity",
		start,
		landing,
		flight_time,
		gravity
	) as Vector2
	var solved_landing := (
		start
		+ velocity * flight_time
		+ Vector2(0.0, 0.5 * gravity * flight_time * flight_time)
	)
	_expect(
		solved_landing.is_equal_approx(landing),
		"Tensioner analytically solves missile velocity to the marked floor point."
	)


func _verify_world_instances() -> void:
	var file := FileAccess.open(WORLD_SCENE_PATH, FileAccess.READ)
	_expect(file != null, "First Weave world scene opens for override verification.")
	if not file:
		return
	var source := file.get_as_text()
	_expect(
		not source.contains("thread_missile_scene = null"),
		"Central-chamber Tensioners no longer disable their missiles."
	)
	for obsolete_property in [
		"thread_smash_horizontal_spread",
		"thread_smash_min_launch_speed",
		"thread_smash_max_launch_speed",
		"thread_smash_horizontal_force",
		"thread_smash_velocity_jitter",
	]:
		_expect(
			not source.contains(obsolete_property),
			"World instances contain no obsolete launch override: %s." % obsolete_property
		)


func _verify_miss_safe_impact_shake(tensioner: Tensioner) -> void:
	var camera := Camera2D.new()
	camera.enabled = true
	add_child(camera)
	camera.make_current()
	await get_tree().process_frame

	tensioner.activate_attack_hitbox()
	var camera_id := camera.get_instance_id()
	var shake_state := CombatFeedback._shake_states.get(camera_id, {}) as Dictionary
	_expect(
		not shake_state.is_empty()
		and is_equal_approx(
			float(shake_state.get("strength", 0.0)),
			tensioner.thread_smash_screen_shake_strength
		),
		"Tensioner stomp requests its activation-owned shake even without a player hit."
	)
	tensioner.deactivate_attack_hitbox()
	var shake_tween := shake_state.get("tween") as Tween
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
	CombatFeedback._shake_states.erase(camera_id)
	camera.free()


func _verify_ground_telegraph() -> void:
	var telegraph := TELEGRAPH_SCENE.instantiate() as GroundAttackTelegraph
	_expect(telegraph != null, "Ground attack telegraph scene instantiates.")
	if not telegraph:
		return
	add_child(telegraph)

	telegraph.play_windup(330.0, 0.58)
	_expect(
		telegraph.get_mode() == GroundAttackTelegraph.TelegraphMode.WINDUP,
		"Ground footprint enters windup mode."
	)
	_expect(is_equal_approx(telegraph.get_full_width(), 330.0), "Ground footprint matches hitbox width.")
	_expect(is_equal_approx(telegraph.get_duration(), 0.58), "Ground footprint matches attack windup.")
	telegraph.call("_process", 0.58)
	_expect(
		telegraph.get_mode() == GroundAttackTelegraph.TelegraphMode.WINDUP,
		"Completed windup remains visible until hitbox activation."
	)

	telegraph.trigger_impact(330.0, 0.28)
	_expect(
		telegraph.get_mode() == GroundAttackTelegraph.TelegraphMode.IMPACT,
		"Ground footprint becomes an impact shockwave."
	)
	telegraph.call("_process", 0.28)
	_expect(
		telegraph.get_mode() == GroundAttackTelegraph.TelegraphMode.INACTIVE,
		"Impact shockwave finishes cleanly."
	)
	telegraph.queue_free()
	await get_tree().process_frame


class FloorTargetProbe:
	extends Tensioner

	var blocked_lane_x := -100.0

	func _find_thread_smash_floor_point(world_x: float) -> Vector2:
		if is_equal_approx(world_x, blocked_lane_x):
			return Vector2(INF, INF)
		return Vector2(world_x, 0.0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error("Tensioner attack verification: " + message)


func _finish() -> void:
	if _failures.is_empty():
		print("Tensioner attack verification passed.")
		get_tree().quit(0)
		return
	print("Tensioner attack verification failed with %d issue(s)." % _failures.size())
	get_tree().quit(1)
