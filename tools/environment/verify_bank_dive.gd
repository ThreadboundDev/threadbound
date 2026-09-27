extends Node2D

const PLAYGROUND = preload("res://Src/Environment/BlueBiome/Prototypes/blue_water_playground.tscn")

func _ready() -> void:
	var room = PLAYGROUND.instantiate()
	add_child(room)
	var player = room.get_node("Player")
	var water = room.get_node("IntegratedTestLane/WaterBasin")
	await get_tree().physics_frame
	player.set_physics_process(false)
	player.set_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	assert(water.water_color.a < 0.4)
	for side in [-1, 1]:
		player._prototype_water_surfaces.clear()
		player.position = water.position + Vector2(float(side) * (water.size.x * 0.5 + 55.0), -water.size.y * 0.5 - 220.0)
		player.last_direction = -side
		player.velocity = Vector2.ZERO
		for tick in range(80):
			player.velocity.y += 1500.0 / 60.0
			player.move_and_slide()
			await get_tree().physics_frame
			if player.is_on_floor():
				break
		print("BANK_READY side=",side," position=",player.position," floor=",player.is_on_floor())
		assert(player.can_start_bank_dive())
		if side == -1:
			await _capture("bank")
		await get_tree().process_frame
		await get_tree().process_frame
		assert(water.get_node("DiveEntry").prompt.visible, "Bank prompt must appear at real test-bank position")
		assert(player.start_bank_dive(-side))
		assert(not player.start_bank_dive(-side), "Do not restart an active dive")
		assert(player.live_3d_visual.get("_current_action") == &"jumping_into_water_1")
		assert(not player.is_in_prototype_water(), "Dive begins above water")
		for tick in range(90):
			player._process_bank_dive(1.0 / 60.0)
			await get_tree().physics_frame
			if not player.bank_dive_active:
				break
		print("BANK_ENTERED side=",side," position=",player.position," water=",player.is_in_prototype_water())
		if side == -1:
			await _capture("submerged")
		assert(not player.bank_dive_active)
		assert(player.is_in_prototype_water(), "Bank dive must actually reach the swim volume")
		assert(player.live_3d_visual.get("_current_action") == &"swimming_1")
		assert(not player.can_start_bank_dive())
	print("BANK_DIVE_PASS: both real banks, prompt, above-water takeoff, swimming, no repeated entry")
	room.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("C:/Users/chase/.codex/visualizations/2026/09/14/01a0a082-1409-7791-a66d-d1c90fee4a99/implementation/water_%s.png" % label)
