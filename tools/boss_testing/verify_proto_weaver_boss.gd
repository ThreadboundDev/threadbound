extends Node

const BOSS_SCENE := preload("res://Src/Enemies/ProtoWeaver/proto_weaver.tscn")
const MISSILE_SCENE := preload("res://Src/Enemies/ProtoWeaver/thread_missile.tscn")
const BASE_GLOVES_SCENE := preload("res://Src/Equipment/base_gloves.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	var boss := BOSS_SCENE.instantiate() as ProtoWeaver
	add_child(boss)
	boss.global_position = Vector2(400.0, 400.0)
	_verify_grapple_target(boss)
	_verify_grounded_tuning(boss)
	_verify_laser_tuning(boss)
	_verify_wall_intermission_tuning(boss)
	_verify_missile_landing(boss)
	_verify_color_identities(boss)
	_verify_vertical_responses(boss)
	await _verify_wall_intermission_runtime(boss)
	await _verify_ground_wave_runtime(boss)

	if _failures.is_empty():
		print("Proto-Weaver verification passed: grapple coverage, grounded identities, lane missiles, laser sweeps, and recharge tuning are configured.")
		get_tree().quit(0)
		return

	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _verify_grapple_target(boss: ProtoWeaver) -> void:
	var target := boss.get_node_or_null("UpperBodyGrappleTarget") as Area2D
	_expect(target != null, "Proto-Weaver is missing its upper-body grapple target.")
	if not target:
		return
	_expect(target.get_collision_layer_value(2), "Upper-body grapple target is not on the grapple/hurtbox layer.")
	var collision := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_expect(collision != null and collision.shape is RectangleShape2D, "Upper-body grapple target has no rectangular collision shape.")
	if collision and collision.shape is RectangleShape2D:
		var size := (collision.shape as RectangleShape2D).size
		_expect(size.x >= 280.0 and size.y >= 300.0, "Upper-body grapple target does not cover enough of the visible boss.")

	var grapple_component := boss.get_node_or_null("GrappleTargetComponent") as GrappleTargetComponent
	_expect(grapple_component != null, "Proto-Weaver has no grapple weight component.")
	if grapple_component:
		_expect(not grapple_component.is_pullable(), "Grappling the boss would incorrectly pull the boss toward the player.")

	var gloves := BASE_GLOVES_SCENE.instantiate() as BaseGloves
	_expect(bool(gloves.call("_is_valid_hookshot_collider", target)), "Base grapple rejects the boss's upper-body target.")
	gloves.call("_capture_grapple_target", target)
	_expect(gloves.hookshot_enemy_hurtbox == boss.hurtbox, "Boss upper-body grapple does not resolve strikes back to the combat hurtbox.")
	gloves.free()


func _verify_grounded_tuning(boss: ProtoWeaver) -> void:
	_expect(boss.repulse_trigger_hold_time >= 0.35, "Thread Repulse telegraph is too short to react to.")
	_expect(boss.repulse_internal_cooldown >= 4.0, "Thread Repulse can repeat too frequently.")
	_expect(boss.ground_sweep_telegraph_hold_time > boss.stab_telegraph_hold_time, "Fang does not have a more deliberate telegraph than stab.")
	_expect(boss.threadburst_horizontal_spread >= 850.0, "Threadburst does not cover enough of the arena.")
	_expect(boss.threadburst_flight_time >= 1.1, "Threadburst missiles do not receive enough airtime for a high arc.")
	_expect(boss.threadburst_launch_height <= 100.0, "Threadburst missiles appear in the air instead of launching from the smash.")
	_expect(boss.threadburst_min_missile_count >= 4, "Threadburst does not create enough lanes to matter.")
	var attack_range_shape := boss.get_node("AttackArea/CollisionShape2D") as CollisionShape2D
	var stab_hit_shape := boss.get_node("AttackHitbox/CollisionShape2D") as CollisionShape2D
	_expect(
		attack_range_shape.shape is RectangleShape2D and stab_hit_shape.shape is RectangleShape2D,
		"Proto-Weaver attack detection or stab damage shape is missing."
	)
	if attack_range_shape.shape is RectangleShape2D and stab_hit_shape.shape is RectangleShape2D:
		var range_height := (attack_range_shape.shape as RectangleShape2D).size.y
		var hit_height := (stab_hit_shape.shape as RectangleShape2D).size.y
		_expect(hit_height <= range_height * 0.6, "Stab damage still reaches vertically through most of its AI detection range.")


func _verify_laser_tuning(boss: ProtoWeaver) -> void:
	_expect(is_equal_approx(boss.phase_one_health_ratio, 0.75), "First hanging phase does not begin at 75% health.")
	_expect(is_equal_approx(boss.phase_two_health_ratio, 0.5), "Second hanging phase does not begin at 50% health.")
	_expect(is_equal_approx(boss.phase_three_health_ratio, 0.25), "Final hanging phase does not begin at 25% health.")
	_expect(boss.phase_one_laser_shot_count == 4, "First hanging phase is not the four-shot teaching volley.")
	_expect(boss.phase_two_laser_shot_count == 3, "Second hanging phase is not the three-shot volley plus sweep.")
	_expect(boss.phase_three_laser_event_count == 6, "Final hanging phase does not contain six mixed events.")
	_expect(boss.phase_three_sweep_count == 2, "Final hanging mix does not contain two separated sweeps.")
	_expect(boss.phase_one_sweep_time >= 0.8, "The teaching sweep is too fast.")
	_expect(boss.phase_two_sweep_time < boss.phase_one_sweep_time, "The second sweep should be the faster reversal.")
	_expect(boss.phase_landing_punish_time >= 0.8, "Post-laser recharge is not a meaningful punish window.")
	for _sample in range(12):
		var events := boss.call("_build_final_laser_events") as Array[bool]
		_expect(events.size() == boss.phase_three_laser_event_count, "Final hanging event deck has the wrong size.")
		var sweep_count := 0
		for event_index in range(events.size()):
			if not events[event_index]:
				continue
			sweep_count += 1
			_expect(event_index == 0 or not events[event_index - 1], "Final hanging event deck produced consecutive sweeps.")
		_expect(sweep_count == boss.phase_three_sweep_count, "Final hanging event deck has the wrong sweep count.")


func _verify_wall_intermission_tuning(boss: ProtoWeaver) -> void:
	_expect(boss.wall_phase_break_distance >= 220.0, "Wall phase requires an excessively precise finishing hit.")
	_expect(boss.wall_phase_one_max_duration >= 7.0, "First wall traversal timeout is too short.")
	_expect(boss.wall_phase_two_max_duration > boss.wall_phase_one_max_duration, "Second wall traversal does not allow more chase time.")
	_expect(boss.wall_phase_two_break_damage > boss.wall_phase_one_break_damage, "Second wall traversal does not require a higher break threshold.")
	_expect(boss.wall_knockdown_duration >= 1.5, "Successful wall break does not award a meaningful punish window.")
	_expect(
		boss.wall_phase_two_timing_multiplier < boss.wall_phase_one_timing_multiplier,
		"Second wall phase does not ramp its attack cadence."
	)
	_expect(
		boss.wall_left_offset.x < 0.0 and boss.wall_right_offset.x > 0.0,
		"Wall intermission offsets do not designate opposite arena walls."
	)

	var left_marker := Marker2D.new()
	left_marker.name = "VerifyWallLeft"
	left_marker.position = Vector2(-610.0, -290.0)
	left_marker.rotation = -PI * 0.5
	boss.add_child(left_marker)
	var right_marker := Marker2D.new()
	right_marker.name = "VerifyWallRight"
	right_marker.position = Vector2(630.0, -275.0)
	right_marker.rotation = PI * 0.5
	boss.add_child(right_marker)
	var recovery_marker := Marker2D.new()
	recovery_marker.name = "VerifyRecoveryFloor"
	recovery_marker.position = Vector2(25.0, 0.0)
	boss.add_child(recovery_marker)
	boss.wall_left_marker_path = NodePath("VerifyWallLeft")
	boss.wall_right_marker_path = NodePath("VerifyWallRight")
	boss.recovery_floor_marker_path = NodePath("VerifyRecoveryFloor")

	var target_marker := Node2D.new()
	add_child(target_marker)
	boss.target = target_marker
	target_marker.global_position = boss.call("_get_hang_home_position") + Vector2(180.0, 0.0)
	boss.set("_active_hanging_phase", 0)
	boss.call("_configure_wall_hang_destination")
	_expect(int(boss.get("_wall_side")) == -1, "First wall phase does not choose the wall farthest from the player.")
	_expect(
		is_equal_approx(float(boss.get("_hang_rotation")), -PI * 0.5),
		"Left-wall presentation does not rotate inward by 90 degrees."
	)
	_expect(
		boss.get("_hang_position").is_equal_approx(
			left_marker.global_position
			- boss.wall_hang_foot_offset.rotated(left_marker.global_rotation)
		),
		"Wall phase does not derive the boss body from its editor foot marker."
	)
	_expect(
		boss.get("_hang_anchor").is_equal_approx(left_marker.global_position),
		"Wall thread anchor does not terminate at the editor foot marker."
	)
	_expect(
		boss.call("_get_recovery_floor_position").is_equal_approx(recovery_marker.global_position),
		"Wall phase ignores its recovery-floor marker."
	)

	var phase_one_events: Array[int] = []
	boss.set("_wall_event_bag", [])
	boss.set("_last_wall_event", -1)
	for _event_index in range(5):
		phase_one_events.append(int(boss.call("_take_next_wall_event")))
	_expect(
		not phase_one_events.has(ProtoWeaver.HangingEvent.LASER_SWEEP),
		"Teaching wall phase includes the advanced laser sweep."
	)
	_expect(
		phase_one_events.has(ProtoWeaver.HangingEvent.RED_VOLLEY)
		and phase_one_events.has(ProtoWeaver.HangingEvent.YELLOW_ECHO)
		and phase_one_events.has(ProtoWeaver.HangingEvent.BLUE_WALL_SHEAR),
		"Teaching wall phase does not exercise all three traversal colors."
	)

	boss.set("_active_hanging_phase", 1)
	boss.set("_wall_event_bag", [])
	boss.set("_last_wall_event", -1)
	var phase_two_events: Array[int] = []
	for _event_index in range(6):
		phase_two_events.append(int(boss.call("_take_next_wall_event")))
	_expect(
		phase_two_events.has(ProtoWeaver.HangingEvent.LASER_SWEEP),
		"Second wall phase does not add the laser sweep."
	)
	_expect(
		phase_two_events.count(ProtoWeaver.HangingEvent.RED_VOLLEY) == 2,
		"Second wall phase does not increase Red volley pressure."
	)

	boss.set("_wall_hanging", true)
	boss.set("_wall_break_requested", false)
	boss.set("_wall_phase_elapsed", boss.wall_phase_two_max_duration)
	boss.call("_update_wall_phase_timeout", 0.01)
	_expect(bool(boss.get("_wall_break_requested")), "Wall emergency timeout cannot safely end the traversal phase.")
	_expect(bool(boss.get("_wall_phase_timed_out")), "Wall emergency exit is not distinguishable from player success.")
	boss.set("_wall_hanging", false)
	boss.set("_wall_break_requested", false)
	boss.set("_wall_phase_timed_out", false)
	boss.target = null
	target_marker.queue_free()


func _verify_missile_landing(boss: ProtoWeaver) -> void:
	var patterns: Array[int] = []
	for _pattern_index in range(3):
		patterns.append(int(boss.call("_take_next_threadburst_pattern")))
	_expect(patterns.duplicate().size() == 3, "Threadburst pattern bag did not produce three entries.")
	var unique_patterns: Dictionary = {}
	for pattern in patterns:
		unique_patterns[pattern] = true
	_expect(unique_patterns.size() == 3, "Threadburst repeated a pattern before showing all three layouts.")
	for _layout_index in range(3):
		var lanes := boss.call("_get_threadburst_lane_offsets") as Array[float]
		for lane_index in range(1, lanes.size()):
			_expect(
				lanes[lane_index] - lanes[lane_index - 1] >= boss.threadburst_min_lane_spacing - 0.1,
				"Threadburst generated overlapping landing warnings."
			)

	var target_marker := Node2D.new()
	add_child(target_marker)
	boss.target = target_marker
	target_marker.global_position = Vector2(boss.global_position.x + 260.0, boss.global_position.y)
	_expect(
		is_equal_approx(float(boss.call("_get_threadburst_target_x")), target_marker.global_position.x),
		"Threadburst target anchor is not using the player's current world position at release."
	)
	var right_side_lanes := boss.call("_get_player_side_threadburst_offsets", 5, boss.threadburst_horizontal_spread * 0.5) as Array[float]
	_expect(right_side_lanes.has(0.0), "Player-side Threadburst does not guarantee a lane at the player snapshot.")
	for lane in right_side_lanes:
		_expect(lane >= 0.0, "Player-side Threadburst sent a missile to the side opposite the player.")
	target_marker.global_position.x = boss.global_position.x - 260.0
	var left_side_lanes := boss.call("_get_player_side_threadburst_offsets", 5, boss.threadburst_horizontal_spread * 0.5) as Array[float]
	_expect(left_side_lanes.has(0.0), "Left-side Threadburst does not guarantee a lane at the player snapshot.")
	for lane in left_side_lanes:
		_expect(lane <= 0.0, "Player-side Threadburst sent a missile to the side opposite the player.")
	boss.target = null
	target_marker.queue_free()

	var missile := MISSILE_SCENE.instantiate() as ThreadMissile
	add_child(missile)
	missile.global_position = Vector2(0.0, -180.0)
	missile.launch_to_landing(Vector2(240.0, 0.0), boss.threadburst_flight_time, boss)
	_expect(missile.velocity.x > 0.0, "Thread missile does not steer toward its authored landing lane.")
	_expect(missile.velocity.y < 0.0, "Thread missile does not begin with a readable upward arc.")
	_expect(missile.world_collision_descent_ratio > 0.0, "Thread missiles collide with platforms before completing their ascent.")
	var landing_marker := missile.get("_landing_marker") as ThreadMissileLaserMarker
	_expect(landing_marker != null, "Thread missile did not create its authored landing knot.")
	if landing_marker:
		_expect(landing_marker.top_level, "Thread missile landing knot inherits projectile rotation.")
		landing_marker.update_flight(missile.global_position, 0.75, true)
		_expect(bool(landing_marker.get("_descending")), "Landing knot does not strengthen during descent.")
		var knot_sprite := landing_marker.get("_sprite") as Sprite2D
		_expect(knot_sprite != null and "landing_knot" in knot_sprite.texture.resource_path, "Landing warning is not using the authored knot sheet.")
	var missile_sprite := missile.get_node_or_null("Sprite2D") as Sprite2D
	_expect(missile_sprite != null and "power_spindle" in missile_sprite.texture.resource_path, "Threadburst is not using the fantasy Power Spindle asset.")
	var beam := boss.get_node_or_null("AnimatedBeam") as Node2D
	_expect(beam != null and beam.material == null, "Tri-color laser is still being flattened through the red energy material.")
	missile.queue_free()


func _verify_color_identities(boss: ProtoWeaver) -> void:
	_expect(boss.essence_echo_every_n_attacks > 0, "Essence Echo is not part of the grounded attack cadence.")
	_expect(boss.essence_echo_delay >= 0.45, "Essence Echo repeats before the arrival stab has visually separated from it.")
	_expect(
		boss.threadburst_texture != null and boss.threadburst_texture.resource_path.ends_with("proto_weaver_threadburst.png"),
		"Threadburst did not restore the stable original smash animation sheet."
	)
	_expect(
		boss.cleaned_threadburst_frame_count == 26 and boss.repulse_frame_count == 26,
		"Threadburst and Thread Repulse do not use the stable 26-frame playback window."
	)
	_expect(
		boss.repulse_texture == boss.threadburst_texture,
		"Threadburst and Thread Repulse are not sharing the restored clean source animation."
	)
	var flow_aura := boss.get_node_or_null("Visuals/FlowAura") as ProtoWeaverFlowAura
	_expect(flow_aura != null, "Proto-Weaver is missing its model-following Flow aura.")
	if flow_aura:
		flow_aura.show_power()
		flow_aura.call("_sync_source_sprite")
		var aura_shell := flow_aura.get_node_or_null("SilhouetteShell") as Sprite2D
		_expect(
			aura_shell != null and aura_shell.texture == boss.sprite.texture,
			"Proto-Weaver Flow aura does not follow the live boss animation frame source."
		)
		_expect(
			aura_shell != null
			and aura_shell.material is ShaderMaterial
			and (aura_shell.material as ShaderMaterial).shader.resource_path.ends_with("proto_weaver_flow_aura.gdshader"),
			"Proto-Weaver Flow aura is not using its jagged silhouette shader."
		)
		var aura_material := aura_shell.material as ShaderMaterial if aura_shell else null
		if aura_material:
			flow_aura.show_balance()
			var balance_channel := aura_material.get_shader_parameter("channel_1") as Color
			_expect(
				balance_channel.r < 0.1
				and balance_channel.g < 0.4
				and balance_channel.b > 0.95
				and float(aura_material.get_shader_parameter("ivory_mix_strength")) <= 0.35,
				"Balance attacks do not select the blue boss Flow channel."
			)
			flow_aura.show_essence()
			var essence_channel := aura_material.get_shader_parameter("channel_1") as Color
			_expect(
				essence_channel.r > 0.9 and essence_channel.g > 0.7,
				"Essence Echo does not select the yellow boss Flow channel."
			)
			flow_aura.show_all_channels()
			_expect(
				aura_material.get_shader_parameter("channel_weights") == Vector3.ONE,
				"Hanging laser does not select all three boss Flow channels."
			)
		flow_aura.hide_aura(true)

	var target_marker := Node2D.new()
	add_child(target_marker)
	target_marker.global_position = boss.global_position + Vector2(90.0, 0.0)
	boss.target = target_marker
	boss.call("_spawn_essence_echo_telegraph")
	var destination := boss.get("_pending_essence_destination") as Vector2
	_expect(
		destination.is_equal_approx(target_marker.global_position),
		"Essence Echo does not snapshot the player's current destination."
	)
	var echo := boss.get("_essence_echo_vfx") as ProtoWeaverEssenceEchoVFX
	_expect(echo != null, "Essence Echo did not create its yellow destination clone.")
	if echo:
		var echo_sprite := echo.get_node_or_null("EssenceEcho") as Sprite2D
		_expect(echo.destination_marker_only, "Grounded Yellow clone still behaves as a second attacker.")
		_expect(not echo.monitoring, "Yellow destination clone unexpectedly monitors for player damage.")
		_expect(echo.global_position.is_equal_approx(destination), "Yellow clone is not placed at the boss's blink destination.")
		_expect(echo_sprite != null and echo_sprite.frame == 0, "Yellow destination clone does not begin with a readable formation pose.")
		var old_boss_position := boss.global_position
		boss.call("_activate_essence_echo")
		_expect(boss.global_position.is_equal_approx(destination), "The real boss does not blink to its Yellow clone.")
		_expect(bool(echo.get("_dissipating")), "Yellow clone does not disappear when the real boss arrives.")
		boss.global_position = old_boss_position
		echo.queue_free()
	boss.target = null
	target_marker.queue_free()


func _verify_vertical_responses(boss: ProtoWeaver) -> void:
	_expect(boss.vertical_response_height >= 120.0, "Vertical response triggers on ordinary jumps instead of platform camping.")
	_expect(boss.vertical_response_hold_time >= 0.5, "Vertical response does not give platform traversal time to breathe.")
	_expect(boss.vertical_response_cooldown >= 3.0, "Vertical response can spam anti-air attacks.")

	var elevated_target := Node2D.new()
	add_child(elevated_target)
	elevated_target.global_position = boss.global_position + Vector2(120.0, -boss.vertical_response_height - 40.0)
	boss.target = elevated_target
	boss.call("_update_vertical_response_opportunity", boss.vertical_response_hold_time)
	_expect(bool(boss.call("_can_use_vertical_response")), "Sustained platform camping does not arm a vertical response.")
	_expect(
		boss.is_player_in_attack_range(),
		"An armed vertical response cannot transition the boss from chase into attack."
	)
	_expect(
		is_equal_approx(float(boss.call("_get_threadburst_target_y")), elevated_target.global_position.y - 8.0),
		"Red Threadburst still returns elevated shots harmlessly to the ground lane."
	)
	var first_response := int(boss.call("_take_next_vertical_response_attack"))
	var second_response := int(boss.call("_take_next_vertical_response_attack"))
	_expect(
		first_response == ProtoWeaver.AttackMode.THREADBURST
		and second_response == ProtoWeaver.AttackMode.ESSENCE_ECHO,
		"Vertical responses do not alternate between Red pressure and Yellow displacement."
	)

	boss.call("_spawn_essence_echo_telegraph")
	var elevated_destination := boss.get("_pending_essence_destination") as Vector2
	var elevated_echo := boss.get("_essence_echo_vfx") as ProtoWeaverEssenceEchoVFX
	_expect(elevated_echo != null, "Elevated Yellow response did not summon its destination clone.")
	if elevated_echo:
		_expect(
			elevated_echo.destination_marker_only
			and elevated_echo.global_position.is_equal_approx(elevated_destination)
			and is_equal_approx(elevated_destination.y, elevated_target.global_position.y),
			"Vertical Yellow does not place the boss's blink destination on the player's elevated lane."
		)
		var old_boss_position := boss.global_position
		boss.call("_activate_essence_echo")
		_expect(
			boss.global_position.is_equal_approx(elevated_destination),
			"Vertical Yellow leaves the real boss below the player instead of chasing them."
		)
		boss.global_position = old_boss_position
		elevated_echo.queue_free()
	boss.target = null
	elevated_target.queue_free()


func _verify_wall_intermission_runtime(boss: ProtoWeaver) -> void:
	var target_marker := Node2D.new()
	add_child(target_marker)
	target_marker.global_position = boss.global_position + Vector2(160.0, 0.0)
	boss.target = target_marker
	boss.set("_active_hanging_phase", 0)
	boss.wall_phase_one_max_duration = 0.12
	boss.hang_thread_grow_time = 0.01
	boss.hang_rise_time = 0.03
	boss.hang_return_time = 0.03
	boss.wall_timeout_recovery_duration = 0.01
	boss.call("_start_hanging_laser_sequence")
	await get_tree().create_timer(0.45).timeout
	_expect(not bool(boss.get("_hanging_laser_busy")), "Timed-out wall phase does not return control to the grounded fight.")
	_expect(bool(boss.get("_wall_phase_timed_out")), "Wall runtime did not exercise its emergency timeout.")
	_expect(
		is_equal_approx(boss.visuals.rotation, 0.0),
		"Wall phase leaves the boss presentation rotated after landing."
	)
	_expect(
		is_equal_approx(boss.hurtbox_collision_shape.rotation, 0.0),
		"Wall phase leaves the boss hurtbox rotated after landing."
	)
	boss.target = null
	target_marker.queue_free()


func _verify_ground_wave_runtime(boss: ProtoWeaver) -> void:
	var wave := ProtoWeaverGroundWave.new()
	wave.travel_speed = 0.0
	wave.lifetime = 1.0
	add_child(wave)
	wave.global_position = Vector2(320.0, 320.0)
	wave.launch(1, boss)

	var charge := ProtoWeaverGroundCharge.new()
	charge.configure(1, 1.0)
	add_child(charge)
	var wall_wave := ProtoWeaverGroundWave.new()
	wall_wave.travel_speed = 100.0
	add_child(wall_wave)
	wall_wave.global_position = Vector2(200.0, 100.0)
	wall_wave.launch_surface(Vector2.DOWN, 1, boss)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(wave.is_inside_tree() and charge.is_inside_tree(), "Ground wave or charge VFX failed during its first rendered frames.")
	var wall_wave_start := wall_wave.global_position
	wall_wave.call("_physics_process", 0.1)
	_expect(
		is_equal_approx(wall_wave.global_position.x, wall_wave_start.x)
		and wall_wave.global_position.y > wall_wave_start.y,
		"Blue wall shear does not travel downward along its wall surface."
	)
	_expect(
		is_equal_approx(wall_wave.rotation, PI * 0.5),
		"Blue wall shear is not rotated from ground travel onto the wall."
	)
	var wave_sprite := wave.get("_sprite") as Sprite2D
	var charge_preview := charge.get("_preview_sprite") as Sprite2D
	_expect(
		wave_sprite != null and wave_sprite.texture != null and wave_sprite.hframes == 8,
		"Ground wave is missing its eight-frame transition-smoothed sprite sheet."
	)
	if wave_sprite and wave_sprite.texture:
		_expect(
			"ground_thread_wave_balance_v1" in wave_sprite.texture.resource_path,
			"Ground wave is not using the corrected Balance V1 sheet."
		)
		_verify_full_spiral_travel_frames(wave_sprite.texture)
	if wave_sprite:
		_expect("balance" in wave_sprite.texture.resource_path.to_lower(), "Ground wave is not using the blue Balance sheet.")
		wave.set("_elapsed", wave.growth_time * 0.5)
		wave.call("_update_visual")
		_expect(wave_sprite.frame == 1, "Ground wave does not begin on the authored grounded release frame.")
		var travel_frames: Array[int] = []
		var normalized_heights: Array[float] = []
		var leading_edges: Array[float] = []
		for step in range(8):
			wave.set("_elapsed", wave.growth_time + (float(step) + 0.01) / wave.travel_animation_fps)
			wave.call("_update_visual")
			travel_frames.append(wave_sprite.frame)
			normalized_heights.append(
				float(_get_opaque_frame_height(wave_sprite.texture, wave_sprite.frame, wave_sprite.hframes))
				* absf(wave_sprite.scale.y)
			)
			leading_edges.append(
				wave_sprite.position.x
				+ _get_opaque_frame_right_offset(wave_sprite.texture, wave_sprite.frame, wave_sprite.hframes)
				* absf(wave_sprite.scale.x)
			)
		_expect(
			travel_frames == [2, 3, 4, 5, 6, 5, 4, 3],
			"Ground wave does not use the smooth 2-3-4-5-6-5-4-3 travel cadence."
		)
		_expect(
			normalized_heights.max() - normalized_heights.min() <= 9.0,
			"Ground wave travel frames still jump substantially in visible height."
		)
		_expect(
			leading_edges.max() - leading_edges.min() <= 1.0,
			"Ground wave travel frames do not hold a stable painted leading edge."
		)
		wave.call("_physics_process", 0.0)
		var collision := wave.get("_collision_shape") as CollisionShape2D
		var collision_shape := collision.shape as RectangleShape2D if collision else null
		_expect(
			collision_shape != null
			and collision_shape.size.y * absf(collision.scale.y) <= 112.0
			and collision.position.y + collision_shape.size.y * absf(collision.scale.y) * 0.5 <= 0.0,
			"Ground wave damage extends above the tallest sprite or below its grounded footprint."
		)
	_expect(
		charge_preview != null and charge_preview.frame == 0,
		"Ground wave charge no longer previews the compact spiral release frame."
	)
	if charge_preview:
		charge.set("_elapsed", float(charge.get("_duration")) * 0.38)
		charge.call("_update_preview")
		_expect(charge_preview.scale.x < 0.6, "Ground wave charge orb reaches full size too early.")
		charge.set("_elapsed", charge.get("_duration"))
		charge.call("_update_preview")
		_expect(
			absf(fposmod(charge_preview.rotation, TAU)) <= 0.001,
			"Ground wave charge orb does not finish in frame one's original orientation."
		)
		_expect(
			charge_preview.scale.x >= 0.75,
			"Ground wave charge orb does not grow to the grounded release frame's scale."
		)
		_expect(not charge.z_as_relative and charge.z_index == 3, "Ground wave charge orb renders above foreground grass.")
		_expect(charge.get_child_count() == 1, "Ground wave startup still adds procedural line-art clutter around the sprite.")
	var beam := boss.get_node_or_null("AnimatedBeam") as Node2D
	_expect(wave.material != null, "Ground wave is missing its Balance energy material.")
	_expect(beam != null and beam.material == null, "Braided laser is still inheriting a single-color material.")
	wave.queue_free()
	charge.queue_free()
	wall_wave.queue_free()


func _verify_full_spiral_travel_frames(texture: Texture2D) -> void:
	var image := texture.get_image()
	_expect(image != null and image.get_width() % 8 == 0, "Ground wave atlas cannot be divided into eight clean cells.")
	if not image or image.get_width() % 8 != 0:
		return
	var cell_width := image.get_width() / 8
	var center := cell_width / 2
	for frame_index in range(2, 7):
		var left_pixels := 0
		var right_pixels := 0
		var frame_start := frame_index * cell_width
		for y in range(image.get_height()):
			for x in range(cell_width):
				if image.get_pixel(frame_start + x, y).a <= 0.05:
					continue
				if x < center:
					left_pixels += 1
				else:
					right_pixels += 1
		_expect(
			left_pixels > 250 and right_pixels > 250,
			"Ground wave travel frame %d is visibly sliced on one side." % frame_index
		)


func _get_opaque_frame_height(texture: Texture2D, frame_index: int, hframes: int) -> int:
	var image := texture.get_image()
	if not image or hframes <= 0 or image.get_width() % hframes != 0:
		return 0
	var cell_width := image.get_width() / hframes
	var frame_start := frame_index * cell_width
	var min_y := image.get_height()
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(cell_width):
			if image.get_pixel(frame_start + x, y).a <= 0.05:
				continue
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)
	return maxi(0, max_y - min_y + 1)


func _get_opaque_frame_right_offset(texture: Texture2D, frame_index: int, hframes: int) -> float:
	var image := texture.get_image()
	if not image or hframes <= 0 or image.get_width() % hframes != 0:
		return 0.0
	var cell_width := image.get_width() / hframes
	var frame_start := frame_index * cell_width
	var max_x := -1
	for y in range(image.get_height()):
		for x in range(cell_width):
			if image.get_pixel(frame_start + x, y).a > 0.05:
				max_x = maxi(max_x, x)
	return float(max_x + 1) - float(cell_width) * 0.5


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
