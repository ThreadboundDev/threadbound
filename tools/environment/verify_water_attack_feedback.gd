extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_still_village_hybrid_preview.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	var player = room.get_node("Player")
	player.set_physics_process(false)
	player.set_process(false)
	var visual = player.live_3d_visual
	for direction in [Vector2.UP, Vector2.DOWN]:
		player._begin_air_double_attack(direction)
		assert(player.attack_direction.is_equal_approx(direction), "Vertical input must survive attack setup")
		await process_frame
		visual._process(0.0)
		var blade: PackedVector2Array = visual._get_blade_world_points()
		assert(blade.size() == 2, "Blade must resolve from current bone transforms")
		assert((blade[1]-blade[0]).normalized().dot(direction) > 0.8, "Sword must point along vertical strike")
		assert(visual._current_action == &"air_light_1", "Both vertical attacks use the light sword pose")
		assert(not player.get_sword_sweep_state().is_empty(), "Vertical strikes must have a weapon effect")
		player._finish_air_double_attack()
	var bulb = room.get_node("Bulbs/DashChoice")
	var art = room.get_node("StillVillageArt/DashChoiceArt")
	assert(is_equal_approx(art.speed_scale, 0.4))
	var damage = player._build_attack_damage()
	damage.source = player
	damage.knockback = Vector2.DOWN * 250
	bulb._on_hit_received(damage)
	assert(bulb.release_direction == Vector2.UP)
	assert(art.animation == &"pop" and art.speed_scale == 4.0)
	var spray = room.get_node("StillVillageArt/ReleasedCurrent")
	assert(spray.direction == Vector2.UP and spray.explosiveness == 1.0)
	await create_timer(0.17).timeout
	assert(art.animation == &"spent", "Shell must finish popping with the launch")
	var stroke = visual._sword_sweep
	var colors: Array[Color] = []
	for facing in [-1, 1]:
		for frame in range(8):
			stroke.set_sweep((frame + 0.5) * 1.32 / 8, 195, 90,
				Transform2D(PI if facing < 0 else 0.0, Vector2.ZERO), colors, false,
				PackedVector2Array([Vector2(10,10), Vector2(90,20)]), 2)
			stroke.align_ground(500)
			var baselines = [176,192,209,222,212,207,207,196]
			assert(absf(stroke._sprite.to_global(Vector2(0, baselines[frame]-128)).y-500) < 0.01)
	print("WATER AND ATTACK FEEDBACK: PASS")
	quit()
