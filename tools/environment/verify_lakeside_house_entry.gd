extends "res://tools/environment/verify_lakeside_krita.gd"
## Real input and player physics through both opt-in house interiors.
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error("HOUSE_ENTRY_FAIL " + message)

func press_interact(held_frames := 2) -> void:
	await process_frame
	Input.action_press("interact")
	for index in held_frames:
		await process_frame
	Input.action_release("interact")
	# Door travel now owns a short animation, then releases input/cooldown.
	await frames(65)

func approach_exit(house: Node2D, player: CharacterBody2D) -> void:
	player.global_position = Vector2(house.get_node("Door").global_position.x, house.floor_bounds().position.y - house.foot_offset(player) - 2)
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await frames(25)

func check_outside(house: Node2D, player: CharacterBody2D, mask: int, label: String) -> void:
	check(not house.is_player_inside(player), label + ": outside state")
	check(not house.render_model.is_cutaway, label + ": closed facade")
	check(player.collision_mask == mask, label + ": original collision mask restored")
	check(not player.has_meta(house.HOUSE_META), label + ": indoor ownership cleared")
	check(room.get_node("Geometry/RockCollision") not in player.get_collision_exceptions(), label + ": outdoor terrain restored")
	for body: PhysicsBody2D in house._bodies:
		if String(body.name).contains("Roof"):
			check(body not in player.get_collision_exceptions(), label + ": exterior roof stays landable " + str(body.name))
		else:
			check(body in player.get_collision_exceptions(), label + ": player passes exterior interior-floor " + str(body.name))

func verify() -> void:
	room = load(ROOM).instantiate()
	root.add_child(room)
	current_scene = room
	var enemy_masks := {}
	for enemy in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy_masks[enemy.name] = enemy.collision_mask
	await frames(30)
	var player := room.get_node("Player") as CharacterBody2D
	var original_mask := player.collision_mask
	var rock := room.get_node("Geometry/RockCollision") as PhysicsBody2D
	var sentinel := StaticBody2D.new()
	sentinel.collision_layer = 0
	room.add_child(sentinel)
	player.add_collision_exception_with(sentinel)
	var rows: Array[Dictionary] = []
	for label: String in ["Fisher house", "Workshop"]:
		var roof_house := room.get_landmark_house(label) as Node2D
		var roof_prefix := "Fisher" if label == "Fisher house" else "Workshop"
		# Use exposed slopes and ridge. The outermost eaves are embedded in cave
		# art/terrain and intentionally are not free-standing landing surfaces.
		for roof_index in [5, 10, 15]:
			var roof := room.get_node("Geometry/BuildingCollision/" + roof_prefix + "Roof" + str(roof_index)) as StaticBody2D
			player.global_position = roof.global_position - Vector2(0, roof_house.foot_offset(player) + 60)
			player.velocity = Vector2(0, 100)
			player.reset_physics_interpolation()
			await frames(45)
			check(player.is_on_floor(), label + ": actual player lands on roof segment " + str(roof_index))
			var on_roof := false
			for collision_index in player.get_slide_collision_count():
				var collider := player.get_slide_collision(collision_index).get_collider()
				if collider and String(collider.name).begins_with(roof_prefix + "Roof"):
					on_roof = true
			check(on_roof, label + ": roof rather than terrain supports the landing " + str(roof_index))
		room.focus_landmark(label)
		await frames(30)
		var house := room.get_landmark_house(label) as Node2D
		var door := house.get_node("Door") as Area2D
		check_outside(house, player, original_mask, label)
		check(player.is_on_floor(), label + ": outdoor doorway has real ground")
		check(door._prompt.visible and player.get("current_selector") == door, label + ": Enter prompt owns existing interaction")
		for npc in get_nodes_in_group("lakeside_villagers"):
			check(not npc._prompt.visible and not npc._registered, label + ": no greeting through closed walls")
		for mesh: GeometryInstance3D in house.render_model.find_children("*", "GeometryInstance3D", true, false):
			check(mesh.layers == 1, label + ": complete exterior renders behind outside player")
		# Isolate the house collision crossing from the overlapping outdoor rock.
		# No physics frame advances while this temporary fixture exception exists.
		var crossing := player.global_transform
		crossing.origin = Vector2(house.floor_bounds().get_center().x, house.floor_bounds().position.y - house.foot_offset(player) - 14)
		player.add_collision_exception_with(rock)
		check(not player.test_move(crossing, Vector2(0, 28)), label + ": actual player sweeps through exterior house platform")
		player.remove_collision_exception_with(rock)
		var outside_position := player.global_position
		await press_interact(10)
		await frames(20)
		check(house.is_player_inside(player), label + ": held Interact enters once without bouncing back out")
		check(house.render_model.is_cutaway, label + ": facade opens after deliberate entry")
		check(player.get_collision_mask_value(32), label + ": indoor boundaries enabled for player")
		check(rock in player.get_collision_exceptions(), label + ": outdoor rock ignored only indoors")
		check(player.is_on_floor(), label + ": real player stands inside")
		var feet_error: float = absf(player.global_position.y + house.foot_offset(player) - house.floor_bounds().position.y)
		check(feet_error < 0.1, label + ": feet meet visible floor within 0.1px")
		for body: PhysicsBody2D in house._bodies:
			check(body not in player.get_collision_exceptions(), label + ": authored interior collision enabled " + str(body.name))
		for enemy in get_nodes_in_group("enemies"):
			check(enemy.collision_mask == enemy_masks[enemy.name] and (enemy.collision_mask & house.BOUNDARY_LAYER) == 0, label + ": enemy collision unchanged " + str(enemy.name))
		Input.action_press("move_right")
		await frames(90)
		Input.action_release("move_right")
		await frames(3)
		check(house.is_player_inside(player), label + ": walking right stays inside")
		check(player.global_position.x < house.to_global(house.entry_rect.end).x, label + ": solid inside wall stops player")
		Input.action_press("Jump")
		await frames(2)
		Input.action_release("Jump")
		await frames(90)
		check(house.is_player_inside(player) and player.is_on_floor(), label + ": jumping returns to interior floor")
		await approach_exit(house, player)
		check(door._prompt.visible and player.get("current_selector") == door, label + ": Exit prompt owns interaction at inside door")
		await press_interact()
		await frames(25)
		check_outside(house, player, original_mask, label)
		check(player.global_position.distance_to(outside_position) < 1.0, label + ": exit restores recorded outdoor position")
		check(sentinel in player.get_collision_exceptions(), label + ": unrelated collision exception retained")
		# Re-enter, then use the public debug landmark path to leave safely.
		await press_interact()
		await frames(20)
		check(house.is_player_inside(player), label + ": repeated entry works")
		room.focus_landmark("Shore")
		await frames(3)
		check_outside(house, player, original_mask, label + " debug teleport")
		# Direct teleports which bypass the landmark helper also clean up.
		room.focus_landmark(label)
		await frames(30)
		await press_interact()
		await frames(20)
		player.global_position = Vector2(-1000, -610)
		player.velocity = Vector2.ZERO
		await frames(3)
		check_outside(house, player, original_mask, label + " direct teleport")
		# Simulate the real controller's death flag without touching saves/health.
		room.focus_landmark(label)
		await frames(30)
		await press_interact()
		await frames(20)
		player.set("is_dead", true)
		await frames(3)
		check_outside(house, player, original_mask, label + " death")
		player.set("is_dead", false)
		room.focus_landmark("Shore")
		await frames(3)
		rows.append({"house": label, "feet_error_pixels": feet_error, "outside_position": str(outside_position)})
	check(room.get_node("Geometry/BuildingCollision/FisherLoft/Outline").disabled, "Deferred loft remains disabled")
	room.focus_landmark("Tower")
	await frames(25)
	check(room.get_node("Buildings/Tower").render_model.is_cutaway, "Tower retains automatic entry")
	var slip: Node2D = room.get_node("Buildings/BoatSlip")
	player.global_position = slip.global_position + Vector2(-350, -150)
	player.velocity = Vector2.ZERO
	await frames(12)
	check(slip.entry_area == null and not slip.has_method("request_door"), "Boat slip remains an open shelter without door gating")
	# Removing a house while its player remains alive must restore physics.
	room.focus_landmark("Workshop")
	await frames(30)
	await press_interact()
	await frames(20)
	var workshop := room.get_landmark_house("Workshop") as Node2D
	check(workshop.is_player_inside(player), "Enter before house teardown")
	workshop.get_parent().remove_child(workshop)
	workshop.queue_free()
	await frames(3)
	check(player.collision_mask == original_mask and rock not in player.get_collision_exceptions(), "House teardown restores player mask and terrain")
	check(not player.has_meta(&"lakeside_house_interior"), "House teardown clears ownership")
	var fisher := room.get_node("Buildings/FisherHouse") as Node2D
	player.global_position = fisher.outside_destination(player)
	player.velocity = Vector2.ZERO
	await frames(30)
	await press_interact()
	await frames(20)
	check(fisher.is_player_inside(player), "Enter before player removal")
	player.get_parent().remove_child(player)
	player.queue_free()
	await frames(3)
	check(not is_instance_valid(fisher.inside_player) and not fisher.render_model.is_cutaway, "Player removal clears interior and facade")
	check(fisher._terrain_exceptions.is_empty(), "Player removal clears terrain ownership")
	var report := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "houses": rows, "display": DisplayServer.get_name(), "godot": Engine.get_version_info().string}
	DirAccess.make_dir_recursive_absolute("res://tmp/house_entry")
	FileAccess.open("res://tmp/house_entry/verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("HOUSE_ENTRY_CHECKS ", checks, " failures=", failures)
	room.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
