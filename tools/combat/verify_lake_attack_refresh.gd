extends SceneTree
## Run with Godot --headless --path . --script res://tools/combat/verify_lake_attack_refresh.gd

var player: CharacterBody2D
var hits: Array[DamageData] = []

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0,100)
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(3000,40)
	floor_shape.shape = rectangle
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	player = load("res://Src/Characters/Player/player.tscn").instantiate()
	player.position = Vector2(0,-180)
	world.add_child(player)
	for i in 90:
		await physics_frame
	assert(player.is_on_floor(), "Test player must land")
	player.set_physics_process(false)
	var visual = player.live_3d_visual
	visual.set_process(false)
	assert(visual.get_action_duration(&"attack_2") > 1.0)
	for direction in [-1,1]:
		player.attack_cooldown_timer = 0.0
		player.refill_action_points()
		var action := "move_left" if direction < 0 else "move_right"
		Input.action_press(action)
		player.start_attack(true)
		Input.action_release(action)
		assert(player.current_attack_is_spin)
		assert(player.current_action_points == player.max_action_points-player.neutral_special_action_point_cost)
		assert(player.last_direction == direction)
		visual._animation_player.play(visual._clips[visual._current_action], 0.0)
		visual._animation_player.pause()
		visual._animation_player.seek(7.0/30.0,true)
		player.update_combat_timers(0.01)
		assert(not player.attack_hitbox.active)
		visual._animation_player.seek(12.0/30.0,true)
		player.update_combat_timers(0.01)
		assert(player.attack_hitbox.active)
		for side in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			assert(Geometry2D.is_point_in_polygon(side*130,player.attack_collision_polygon.polygon))
			var target = load("res://Src/Components/hurtbox_component.gd").new()
			target.position = player.attack_hitbox.global_position+side*130
			world.add_child(target)
			target.hit_received.connect(func(damage: DamageData): hits.append(damage))
			var before := hits.size()
			player.attack_hitbox._on_area_entered(target)
			player.attack_hitbox._on_area_entered(target)
			assert(hits.size()==before+1, "Spin must hit each target once")
			assert(hits[-1].knockback.normalized().dot(side)>0.99)
			target.queue_free()
		visual._animation_player.seek(26.0/30.0,true)
		player.update_combat_timers(0.01)
		assert(not player.attack_hitbox.active)
		player.attack_timer = player.spin_special_duration
		player.update_combat_timers(0.01)
		assert(not player.is_attacking and not player.current_attack_is_spin)
	# Directionless special is still the existing explosion.
	player.attack_cooldown_timer = 0.0
	player.refill_action_points()
	player.start_attack(true)
	assert(player.current_attack_is_special and not player.current_attack_is_spin)
	player._cancel_attack_for_dash()
	var water := Node2D.new()
	world.add_child(water)
	player._prototype_water_surfaces[water] = 0.0
	assert(not player.can_start_attack(true), "No underwater special yet")
	for movement in [Vector2.ZERO,Vector2(300,0),Vector2(0,-300)]:
		player.velocity = movement
		player.attack_cooldown_timer = 0.0
		player.start_attack(false)
		assert(player.current_attack_uses_air_double and not player.current_attack_uses_ground_combo)
		assert(visual._current_action == &"water_attack_idle")
		if movement.length() > 20:
			assert(player.attack_direction.dot(movement.normalized()) > 0.99)
		visual._animation_player.play(visual._clips[visual._current_action], 0.0)
		visual._animation_player.pause()
		visual._animation_player.seek(6.0/30.0,true)
		player.update_combat_timers(0.01)
		assert(not player.attack_hitbox.active)
		visual._animation_player.seek(8.0/30.0,true)
		visual._process(0.016)
		player.update_combat_timers(0.01)
		assert(player.attack_hitbox.active)
		assert(visual._lower_sampler_action == &"water_attack_move")
		assert(visual._water_attack_blend > 0.9 if movement.length()>20 else visual._water_attack_blend < 0.1)
		visual._animation_player.seek(12.0/30.0,true)
		player.update_combat_timers(0.01)
		assert(not player.attack_hitbox.active)
		player.attack_timer = player.air_attack_duration
		player.update_combat_timers(0.01)
		assert(not player.is_attacking)
	player._prototype_water_surfaces.clear()
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		player.attack_cooldown_timer = 0.0
		player._begin_air_double_attack(direction)
		var expected: StringName = &"air_attack_up" if direction.y < 0 else (&"air_attack_down" if direction.y > 0 else &"air_attack_forward")
		assert(visual._current_action == expected)
		assert(absf(player.air_attack_duration - visual.get_action_duration(expected) / (player.air_attack_playback_speed * player.get_momentum_attack_speed_multiplier())) < 0.02)
		visual._animation_player.play(visual._clips[visual._current_action], 0.0)
		visual._animation_player.pause()
		visual._animation_player.seek((0.0 if direction.y != 0 else 6.0)/30.0,true)
		player.update_combat_timers(0.01)
		assert(not player.attack_hitbox.active)
		visual._animation_player.seek((1.0 if direction.y != 0 else 7.0)/30.0,true)
		visual._process(0.016)
		player.update_combat_timers(0.01)
		assert(player.attack_hitbox.active)
		var blade: PackedVector3Array = visual._get_blade_model_points()
		var blade_axis := (blade[1]-blade[0]).normalized()
		if direction == Vector2.UP:
			assert(blade_axis.y > 0.95, "Up clip must point the actual sword upward")
		elif direction == Vector2.DOWN:
			assert(blade_axis.y < -0.95, "Down clip must point the actual sword downward")
		visual._animation_player.seek((6.0 if direction.y != 0 else 12.0)/30.0,true)
		player.update_combat_timers(0.01)
		assert(not player.attack_hitbox.active)
		player._cancel_attack_for_dash()
	# Finishing an unqueued hit resets immediately; buffered clicks still chain.
	player._begin_ground_combo_attack(&"forward")
	assert(player.ground_combo_step == 0)
	player.ground_combo_queued = true
	player.ground_combo_queued_family = &"forward"
	player._finish_ground_combo_attack()
	assert(player.ground_combo_step == 1 and player.is_attacking)
	player._finish_ground_combo_attack()
	assert(player.ground_combo_reset_timer == 0.0)
	player._begin_ground_combo_attack(&"forward")
	assert(player.ground_combo_step == 0, "Click after stopped hit two must start hit one")
	player._cancel_attack_for_dash()
	player._begin_air_double_attack(Vector2.UP)
	visual._animation_player.play(visual._clips[&"air_attack_up"], 0.0)
	visual._animation_player.seek(0.08, true)
	visual._process(0.016)
	var blade_points: PackedVector3Array = visual._get_blade_model_points()
	for point in blade_points:
		var pixel: Vector2 = visual._camera.unproject_position(point)
		assert(pixel.y > 12 and pixel.y < visual._viewport.size.y-12, "Sword must fit inside render texture")
	assert(visual.get_action_duration(&"air_attack_forward") < 0.55)
	assert(visual.get_action_duration(&"water_attack_idle") > 0.7)
	print("PASS: spin input/AP/radial single hits/frame windows/cleanup; neutral preserved; water single slash at rest, moving and vertical")
	quit()


