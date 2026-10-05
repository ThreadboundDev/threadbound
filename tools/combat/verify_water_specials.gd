extends SceneTree
## Real player/animations/combat, with a synthetic water volume and manual ticks.
var hits := 0
func _initialize() -> void:
	call_deferred("run")

func rotation_track(animation: Animation, bone: StringName) -> int:
	for index in animation.get_track_count():
		var path := animation.track_get_path(index)
		if animation.track_get_type(index) == Animation.TYPE_ROTATION_3D and path.get_subname_count() == 1 and path.get_subname(0) == bone:
			return index
	return -1

func run() -> void:
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
	await physics_frame
	for direction in [0, 1, -1]:
		player._cancel_attack_for_dash()
		player.attack_cooldown_timer = 0
		player.refill_action_points()
		player.last_direction = -1 if direction < 0 else 1
		player.velocity = Vector2(170,-80)
		var before_ap: int = player.current_action_points
		var input := "move_left" if direction < 0 else "move_right"
		if direction:
			Input.action_press(input)
		player.start_attack(true)
		Input.action_release(input)
		assert(player.is_attacking and player.current_attack_is_special)
		assert(player.current_attack_is_spin == (direction != 0))
		assert(player.current_action_points == before_ap - player.neutral_special_action_point_cost)
		assert(player.velocity == Vector2(170,-80), "Ability entry preserves swimming momentum")
		assert(not player._is_attack_movement_committed(), "Water abilities do not plant the player")
		var action: StringName = &"water_spin_special" if direction else &"water_neutral_special"
		assert(visual._current_action == action)
		var source_name: StringName = &"attack_2" if direction else &"power_up_1"
		var authored: Animation = visual._animation_player.get_animation(visual._clips[source_name])
		var animation: Animation = visual._animation_player.get_animation(visual._clips[action])
		var idle: Animation = visual._animation_player.get_animation(visual._clips[&"water_idle_1"])
		assert(is_equal_approx(animation.length, authored.length), "Original ability timeline is preserved")
		# Curves retain the original sword/arm motion, with swimming leg curves.
		for bone in [&"upper_arm.R", &"forearm.R", &"hand.R", &"thigh.L", &"foot.R"]:
			var source := idle if bone in visual.LOWER_BODY_BONES else authored
			var source_track := rotation_track(source, bone)
			var destination := rotation_track(animation, bone)
			assert(source_track >= 0 and destination >= 0)
			for frame in range(ceili(animation.length * 30.0) + 1):
				var time := minf(float(frame)/30.0, animation.length)
				var source_time: float = fmod(time, idle.length) if source == idle else time
				var expected := source.rotation_track_interpolate(source_track, source_time)
				var actual := animation.rotation_track_interpolate(destination, time)
				assert(absf(expected.dot(actual)) > 0.9999, "Authored upper body / swim legs match")
		visual._animation_player.play(visual._clips[action], 0.0)
		visual._animation_player.pause()
		var anchor := Vector3.ZERO
		for frame in range(ceili(animation.length * 30.0) + 1):
			visual._animation_player.seek(minf(frame/30.0,animation.length), true)
			visual._process(0.0)
			var pelvis: Vector3 = visual._skeleton.to_global(visual._skeleton.get_bone_global_pose(visual._pelvis_index).origin)
			if frame == 0:
				anchor = pelvis
			assert(pelvis.distance_to(anchor) < 0.015, "Ability cannot move the rendered swimmer independently")
			assert(is_zero_approx(visual._display.rotation), "Abilities stay upright instead of following travel pitch")
			assert(visual._display.flip_h == (direction < 0), "Ability facing is locked")
		# Actual physics retains vertical steering; directional active burst owns X.
		visual._animation_player.seek(0, true)
		Input.action_press("move_up")
		player._physics_process(1.0/60.0)
		Input.action_release("move_up")
		assert(player.velocity.y < -80.0, "Windup allows upward swimming")
		if direction:
			visual._animation_player.seek(7.0/30.0, true)
			player.update_combat_timers(0.001)
			assert(not player.attack_hitbox.active)
			visual._animation_player.seek(9.0/30.0, true)
		else:
			player.attack_timer = player.neutral_special_windup - 0.01
			player.update_combat_timers(0.001)
			assert(not player.attack_hitbox.active)
			player.attack_timer = player.neutral_special_windup
		player.update_combat_timers(0.001)
		assert(player.attack_hitbox.active)
		if direction:
			Input.action_press("move_up")
			player._physics_process(1.0/60.0)
			Input.action_release("move_up")
			assert(is_equal_approx(player.velocity.x, float(direction)*player.spin_special_dash_speed))
			assert(player.velocity.y < -80.0, "Active spin retains vertical steering")
		var center: Vector2 = player.get_node("CollisionShape2D").global_position
		assert(player.attack_hitbox.global_position.is_equal_approx(center), "Water AOE is centered on the swimmer")
		if not direction:
			assert(player._get_neutral_special_chest_anchor_position().is_equal_approx(center), "Neutral VFX matches water hitbox")
			assert(is_instance_valid(player._neutral_special_vfx_instance))
		for side in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			assert(Geometry2D.is_point_in_polygon(side*100, player.attack_collision_polygon.polygon), "Radial ability coverage")
		var target = load("res://Src/Components/hurtbox_component.gd").new()
		world.add_child(target)
		target.global_position = center + Vector2(50,0)
		target.hit_received.connect(func(_damage): hits += 1)
		var before_hits := hits
		player.attack_hitbox._on_area_entered(target)
		player.attack_hitbox._on_area_entered(target)
		assert(hits == before_hits + 1, "One damage event per ability")
		target.queue_free()
		# Medium transitions swap poses at the same clip time, without AP/hit resets.
		var phase := minf(animation.length * 0.4, animation.length - 0.01)
		visual._animation_player.seek(phase, true)
		var ap: int = player.current_action_points
		player._prototype_water_surfaces.clear()
		visual._process(0.0)
		assert(visual._current_action == source_name)
		assert(absf(visual.get_current_action_position() - phase) < 0.001)
		assert(player.current_action_points == ap and player.attack_hitbox.active)
		player._prototype_water_surfaces[water] = -1000.0
		visual._process(0.0)
		assert(visual._current_action == action and absf(visual.get_current_action_position()-phase) < 0.001)
		assert(player.current_action_points == ap)
		if direction:
			visual._animation_player.seek(26.0/30.0, true)
		else:
			player.attack_timer = player.neutral_special_windup + player.neutral_special_active_time
		player.update_combat_timers(0.001)
		assert(not player.attack_hitbox.active)
		player.attack_timer = player.spin_special_duration if direction else (player.neutral_special_windup + player.neutral_special_active_time + player.neutral_special_recovery)
		player.update_combat_timers(0.001)
		assert(not player.is_attacking and not player.current_attack_is_spin)
		assert(not player.can_start_attack(true), "Cooldown is retained after completion")
		print("PASS underwater ability ", direction, ": source motion, anchor, movement, AP, damage, medium transitions, cleanup")
	# No AP means no ability, and dry airborne initiation is still disallowed.
	player.attack_cooldown_timer = 0
	player.refill_action_points()
	player.spend_action_points(player.max_action_points)
	player.start_attack(true)
	assert(not player.is_attacking)
	player.refill_action_points()
	player.start_attack(true)
	assert(player.is_attacking)
	player._cancel_attack_for_dash()
	assert(not player.is_attacking and not player.attack_hitbox.active and not is_instance_valid(player._neutral_special_vfx_instance))
	# Receiving a hit must also cancel both abilities, without leaving live AOE.
	for spin in [false, true]:
		player.attack_cooldown_timer = 0
		player.refill_action_points()
		if spin:
			Input.action_press("move_left")
		player.start_attack(true)
		Input.action_release("move_left")
		assert(player.is_attacking)
		var incoming := DamageData.new()
		incoming.amount = 1
		incoming.hitstun = 0.1
		incoming.hit_pause = 0.0
		incoming.use_receiver_screen_shake_fallback = false
		player._on_damaged(incoming)
		visual._process(0.0)
		assert(player.is_hurt and not player.is_attacking and not player.current_attack_is_special and not player.current_attack_is_spin)
		assert(not player.attack_hitbox.active and not is_instance_valid(player._neutral_special_vfx_instance))
		assert(is_zero_approx(visual._model_root.position.x) and is_zero_approx(visual._model_root.position.z), "Special root compensation resets on interruption")
		player.is_hurt = false
		player.hurt_timer = 0.0
	player._prototype_water_surfaces.clear()
	player.attack_cooldown_timer = 0
	assert(not player.can_start_attack(true), "Dry airborne specials remain unavailable")
	print("WATER_SPECIALS_PASS")
	world.queue_free()
	await process_frame
	quit()
