extends SceneTree

var landed := 0

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	var visual = player.live_3d_visual
	visual.set_process(false)
	var water := Node2D.new()
	world.add_child(water)
	player._prototype_water_surfaces[water] = -1000.0
	await process_frame
	var anchor := Vector3.ZERO
	var ground: Animation = visual._animation_player.get_animation(visual._clips[&"slash_2"])
	var idle: Animation = visual._animation_player.get_animation(visual._clips[&"water_idle_1"])
	var screen_anchor := Vector2.ZERO
	for side in [-1, 1]:
		player.last_direction = side
		player.velocity = Vector2(side * 240, -75)
		player._begin_air_double_attack(Vector2(side, 0))
		for step in 3:
			assert(player.water_combo_step == step)
			assert(visual._current_action == StringName("water_combo_%d" % (step + 1)))
			var playback: float = player.water_combo_playback_speed * maxf(0.1, player.get_momentum_attack_speed_multiplier())
			assert(is_equal_approx(visual._animation_player.speed_scale, playback), "Water combo uses its tuned playback speed")
			assert(is_equal_approx(player.air_attack_duration, visual.get_action_duration(visual._current_action) / playback), "Strike timer must match the faster animation")
			assert(not player._is_attack_movement_committed(), "Water combo cannot lock swimming movement")
			visual._animation_player.play(visual._clips[visual._current_action], 0.0)
			visual._animation_player.pause()
			var window: Vector2i = player._get_air_attack_active_frames()
			var combo: Animation = visual._animation_player.get_animation(visual._clips[visual._current_action])
			var source_start: float = [0.0, 1.15, 2.33][step]
			assert(is_equal_approx(combo.length, visual.get_ground_combo_segment_duration(step, false)), "Water strikes reuse ground segment lengths")
			# Only leg rotations are adapted; all other grounded transforms survive.
			for track in combo.get_track_count():
				var bone := combo.track_get_path(track).get_subname(0)
				var type := combo.track_get_type(track)
				var source_track := -1
				for candidate in ground.get_track_count():
					var path := ground.track_get_path(candidate)
					if ground.track_get_type(candidate) == type and path.get_subname_count() == 1 and path.get_subname(0) == bone:
						source_track = candidate
						break
				assert(source_track >= 0)
				var leg_rotation: bool = bone in visual.LOWER_BODY_BONES and bone != &"pelvis" and type == Animation.TYPE_ROTATION_3D
				var swim_track := -1
				if leg_rotation:
					for candidate in idle.get_track_count():
						var path := idle.track_get_path(candidate)
						if idle.track_get_type(candidate) == type and path.get_subname_count() == 1 and path.get_subname(0) == bone:
							swim_track = candidate
							break
					assert(swim_track >= 0)
				var first_leg := Quaternion.IDENTITY
				var leg_movement := 0.0
				var swim_difference := 0.0
				for frame in range(ceili(combo.length * 30.0) + 1):
					var sample := minf(frame/30.0, combo.length)
					var source_time := source_start + sample
					if type == Animation.TYPE_ROTATION_3D:
						var expected := ground.rotation_track_interpolate(source_track, source_time)
						var actual := combo.rotation_track_interpolate(track, sample)
						if leg_rotation:
							var swim_pose := idle.rotation_track_interpolate(swim_track, fmod(source_time, idle.length))
							var motion := ground.rotation_track_interpolate(source_track, 0.0).inverse() * expected
							var water_pose := swim_pose * Quaternion.IDENTITY.slerp(motion, visual.water_attack_leg_motion_strength)
							expected = expected.slerp(water_pose, visual.water_attack_swim_leg_blend).normalized()
							if frame == 0:
								first_leg = actual
							leg_movement = maxf(leg_movement, first_leg.angle_to(actual))
							swim_difference = maxf(swim_difference, swim_pose.angle_to(actual))
						assert(absf(expected.dot(actual)) > 0.9999, "Grounded upper body / dynamic swimming legs must match")
					elif type == Animation.TYPE_POSITION_3D:
						assert(ground.position_track_interpolate(source_track, source_time).is_equal_approx(combo.position_track_interpolate(track, sample)), "Grounded bone positions must be preserved")
					elif type == Animation.TYPE_SCALE_3D:
						assert(ground.scale_track_interpolate(source_track, source_time).is_equal_approx(combo.scale_track_interpolate(track, sample)), "Grounded bone scales must be preserved")
				if leg_rotation and String(bone).begins_with("thigh"):
					assert(leg_movement > deg_to_rad(2), "Swimming attack thighs cannot be frozen")
					assert(swim_difference > deg_to_rad(2), "Thighs retain attack articulation, not just swim idle")
			for frame in range(0, roundi(visual.get_action_duration(visual._current_action)*30.0)+1):
				visual._animation_player.seek(frame/30.0, true)
				visual._process(1.0/60.0)
				var pelvis: Vector3 = visual._skeleton.to_global(visual._skeleton.get_bone_global_pose(visual._pelvis_index).origin)
				if step == 0 and frame == 0:
					anchor = pelvis
				var projected: Vector2 = visual._camera.unproject_position(pelvis) - Vector2(visual._viewport.size) * 0.5
				if side < 0:
					projected.x *= -1.0
				var screen: Vector2 = visual._display.to_global(projected)
				if step == 0 and frame == 0:
					screen_anchor = screen
				assert(pelvis.distance_to(anchor) < 0.015, "Combo pelvis must stay anchored across all frames")
				assert(screen.distance_to(screen_anchor) < 1.0, "Forward tilt cannot introduce attack-frame jumps")
				assert(is_equal_approx(visual._display.rotation, deg_to_rad(visual.water_attack_forward_tilt_degrees) * side), "Attack leans into the locked facing, not the travel direction")
			visual._animation_player.seek((window.x-1)/30.0, true)
			player.update_combat_timers(0.001)
			assert(not player.attack_hitbox.active, "Windup cannot damage")
			visual._animation_player.seek((window.x+1)/30.0, true)
			player.update_combat_timers(0.001)
			assert(player.attack_hitbox.active)
			player.last_direction = -side
			assert(visual._get_visual_facing(0.1) == side, "Facing stays locked during a strike")
			assert(player.get_sword_sweep_state().reverse == (side < 0), "Trail direction stays locked with the strike")
			player.last_direction = side
			for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				var covered := Geometry2D.is_point_in_polygon(direction*100, player.attack_collision_polygon.polygon)
				assert(covered == (step == 2 or direction == Vector2.RIGHT), "Only the flipping finisher covers every side")
			var box = load("res://Src/Components/hurtbox_component.gd").new()
			world.add_child(box)
			box.hit_received.connect(func(_damage): landed += 1)
			var before := landed
			player.attack_hitbox._on_area_entered(box)
			player.attack_hitbox._on_area_entered(box)
			assert(landed == before+1, "Each strike may damage a target only once")
			box.queue_free()
			player.start_attack(false)
			player.start_attack(false)
			assert(player.water_combo_step == step, "Buffered clicks cannot skip strikes")
			player.attack_timer = player.air_attack_duration
			player.update_combat_timers(0.001)
		assert(not player.is_attacking and player.water_combo_step == -1, "Third hit ends combo")
	# One press stops after one strike; cancellation and leaving water drop input.
	player._begin_air_double_attack(Vector2.RIGHT)
	player.attack_timer = player.air_attack_duration
	player.update_combat_timers(0.001)
	assert(not player.is_attacking)
	player._begin_air_double_attack(Vector2.RIGHT)
	player.start_attack(false)
	player._cancel_attack_for_dash()
	assert(player.water_combo_step == -1 and not player.water_combo_queued)
	player._begin_air_double_attack(Vector2.RIGHT)
	player.start_attack(false)
	player._prototype_water_surfaces.clear()
	player.update_combat_timers(0.001)
	assert(not player.is_attacking and not player.water_combo_queued)
	visual._process(0.0)
	assert(is_zero_approx(visual._display.rotation), "Tilt clears after water exit")
	# All joints join smoothly at the existing segment cuts. The swim phase and
	# authored-motion reference cannot reset between clicks in a buffered combo.
	for step in 2:
		var previous: Animation = visual._animation_player.get_animation(visual._clips[StringName("water_combo_%d" % (step + 1))])
		var next: Animation = visual._animation_player.get_animation(visual._clips[StringName("water_combo_%d" % (step + 2))])
		for track in previous.get_track_count():
			if previous.track_get_type(track) == Animation.TYPE_ROTATION_3D:
				assert(absf(previous.rotation_track_interpolate(track, previous.length).dot(next.rotation_track_interpolate(track, 0.0))) > .9999, "Combo rotations join without leg pose snaps")
	print("WATER_COMBO_PASS: dynamic swim/attack legs, preserved upper body and flip, seamless handoffs, both tilts, all-frame anchoring, timing, movement, coverage, deduplication, buffering, cancellation, water exit")
	quit()
