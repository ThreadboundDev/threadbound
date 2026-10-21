extends SceneTree
## Real HUD bindings, authored-spawn restoration and swordfish fracture checks.
var failures: Array[String] = []
var checks := 0
var room: Node2D
var snapshots: Array[String] = []
const OUT := "res://work/lakeside-ui-rock"

func _initialize() -> void:
	# CLI scripts bypass the editor's filesystem scan for these new imports.
	for folder: String in ["res://Assets/BlueBiome/Art/LakesideMap", "res://Assets/BlueBiome/Art/Lakeside3D/Models", "res://Assets/BlueBiome/Art/Lakeside3D/Textures"]:
		for filename in DirAccess.get_files_at(folder):
			if not filename.ends_with(".import"):
				continue
			var config := ConfigFile.new()
			if config.load(folder.path_join(filename)) == OK:
				var uid := ResourceUID.text_to_id(config.get_value("remap", "uid", ""))
				if uid != -1 and not ResourceUID.has_id(uid):
					ResourceUID.add_id(uid, folder.path_join(filename.trim_suffix(".import")))
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for index in count:
		await physics_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var file := OUT.path_join(label + ".png")
	check(root.get_texture().get_image().save_png(file) == OK, "Save rendered capture")
	snapshots.append(file)

func run() -> void:
	room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(12)
	var player = room.get_node("Player")
	var hud = room.get_node("HUD/CombatHUD")
	check(get_first_node_in_group("combat_hud") == hud, "The established HUD is in the scene")
	check(room._enemy_spawns.size() == 3 and room._wall_spawns.size() == 3, "Capture three authored enemies and walls before runtime changes")
	check(hud.current_health == player.health_component.current_health, "Initial HUD health matches player")
	check(hud.current_action_points == player.current_action_points, "Initial HUD AP matches player")
	player.health_component.current_health = 63
	player.health_component.health_changed.emit(63, player.health_component.max_health)
	check(hud.current_health == 63, "Health signal updates HUD without another player action")
	player.set_action_points(2)
	check(hud.current_action_points == 2, "AP spending updates HUD without another player action")
	player.momentum = 37
	player._sync_hud()
	check(hud.current_health == 63 and hud.current_action_points == 2 and is_equal_approx(hud.momentum, 37), "Health, AP and momentum update from real player state")
	check(room.get_node("HUD/VitalsReadout").text.contains("HP 63") and room.get_node("HUD/VitalsReadout").text.contains("AP 2"), "Numeric readout matches live bars and orbs")
	for enemy: Node in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var before_shortcut_id := room.get_node("TideDuelist").get_instance_id()
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_F2
	key_event.pressed = true
	Input.parse_input_event(key_event)
	await frames(3)
	check(room.get_node("TideDuelist").get_instance_id() != before_shortcut_id, "F2 key dispatch really invokes enemy respawn")
	for enemy: Node in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	await frames(18)
	await capture("lakeside_hud")
	player.health_component.configure(player.health_component.max_health)
	player.set_action_points(player.max_action_points)
	player.momentum = 0

	# Death can leave an await timer running. Replacing the old instance prevents
	# that timer hiding the freshly respawned enemy after the button is pressed.
	var originals: Dictionary = {}
	for key: String in ["TideDuelist", "Reedhook", "Bellstriker"]:
		var enemy = room.get_node(key)
		originals[key] = {"id": enemy.get_instance_id(), "position": enemy.home_position, "facing": enemy.start_facing, "health": enemy.health_component.max_health}
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.global_position += Vector2(80, 0)
		enemy.die()
	room.respawn_enemies()
	for key: String in originals:
		var enemy = room.get_node(key)
		check(enemy.get_instance_id() != originals[key].id, key + " is a fresh instance")
		check(enemy.global_position.is_equal_approx(originals[key].position), key + " returns to its authored spawn")
		check(not enemy.is_dead and enemy.health_component.current_health == originals[key].health, key + " respawns alive at full health")
		check(enemy.start_facing == originals[key].facing, key + " preserves its authored facing")
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	check(is_equal_approx(room.get_node("TideDuelist").maximum_dash_distance, 2400) and is_equal_approx(room.get_node("Bellstriker").strike_speed, 760), "Respawn retains scene-specific enemy tuning")
	await frames(60)
	for key: String in originals:
		check(room.get_node(key).visible, "Old death timers cannot hide the new " + key)
	room.get_node("Reedhook").free()
	room.respawn_enemies()
	check(get_nodes_in_group("enemies").size() == 3, "Respawn recreates a removed enemy without duplicates")
	for index in 3:
		room.respawn_enemies()
		check(get_nodes_in_group("enemies").size() == 3, "Repeated respawn keeps exactly three enemies")
	for enemy: Node in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED

	# Independent water fixture exercises the real dash movement and collision.
	var fixture := Node2D.new()
	fixture.position = Vector2(16000, 16000)
	root.add_child(fixture)
	var water = load("res://Src/Environment/Greybox/greybox_polygon_water.tscn").instantiate()
	water.points = PackedVector2Array([Vector2.ZERO, Vector2(2400, 0), Vector2(2400, 1800), Vector2(0, 1800)])
	fixture.add_child(water)
	var target := Node2D.new()
	target.position = Vector2(850, 600)
	fixture.add_child(target)
	var fish = load("res://Src/Enemies/TideDuelist/tide_duelist.tscn").instantiate()
	fish.position = Vector2(600, 600)
	fixture.add_child(fish)
	fish.set_physics_process(false)
	fish.state_machine.set_physics_process(false)
	var wall_scene = load("res://Src/Environment/BlueBiome/Prototypes/blue_breakable_rock.tscn")
	var wall = wall_scene.instantiate()
	wall.position = Vector2(1000, 600)
	wall.hits_to_break = 4
	fixture.add_child(wall)
	var single = wall_scene.instantiate()
	single.position = Vector2(1300, 600)
	fixture.add_child(single)
	var solid = load("res://Src/Environment/Greybox/greybox_block.tscn").instantiate()
	solid.position = Vector2(1800, 600)
	solid.size = Vector2(128, 512)
	fixture.add_child(solid)
	await frames(3)
	check(wall.get_damage_stage() == 0 and wall._cells.size() == 15, "Intact wall has subtle cracks and fifteen textured fracture pieces")
	check(not wall.fracture_from_swordfish(player) and wall.hits_taken == 0, "Player contact and normal attacks cannot damage swordfish terrain")
	check(not fish._move_in_water(Vector2(700, 0)) and wall.hits_taken == 0, "Ordinary swimming stops at intact stone")
	for strike in range(1, 5):
		fish.position = Vector2(600, 600)
		fish.target = target
		fish.begin_attack()
		check(not wall.fracture_from_swordfish(fish), "Windup cannot damage stone")
		fish.activate_attack_hitbox()
		check(not wall.fracture_from_swordfish(fish), "Unsheathed but inactive blade cannot damage stone")
		if strike == 1:
			fish.attack_hitbox.enable()
			check(not wall.fracture_from_swordfish(fish) and wall.hits_taken == 1, "A partial hit leaves the wall solid")
			for repeated_probe in 5:
				wall.fracture_from_swordfish(fish)
			check(wall.hits_taken == 1, "Five further probes in the same dash do not consume extra hits")
		fish.update_attack_motion(1.5)
		check(wall.hits_taken == strike, "One damage hit per committed swordfish dash")
		if strike < 4:
			check(wall.get_damage_stage() == strike and wall.collision_layer != 0, "Damage stage increases while collision stays solid")
			check(fish.dash_blocked and fish.attack_phase == &"recover", "A reinforced wall stops the dash in recovery")
		else:
			check(wall.is_queued_for_deletion() and single.is_queued_for_deletion(), "Final hit opens this wall and a one-hit wall behind it")
			check(wall.collision_layer == 0 and single.collision_layer == 0, "Fracture releases collision in the same dash")
			check(fish.position.x > 1400 and fish.position.x < 1740, "Dash travels through both openings and stops at ordinary terrain")
			check(fixture.find_children("BlueRockShatter*", "", false, false).size() == 2, "Both broken walls leave independent shatter effects")
		fish.end_attack()
	await frames(125)
	check(fixture.find_children("BlueRockShatter*", "", false, false).is_empty(), "Shards and glints dissolve and clean themselves up")
	check(not is_instance_valid(wall) and not is_instance_valid(single) and is_instance_valid(solid), "Broken terrain disappears; ordinary rock remains")
	fixture.queue_free()

	var wall_path := "Geometry/BreakableWall"
	room.get_node(wall_path).queue_free()
	room.get_node("BreakableWall").hits_taken = 3
	await frames(2)
	var position_before: Vector2 = player.global_position
	room.restore_breakable_rocks()
	for key: String in [wall_path, "Volumes/BreakableWall", "BreakableWall"]:
		check(room.get_node(key).hits_taken == 0 and room.get_node(key).collision_layer != 0, "Restore resets each wall and collision")
	check(room.get_node(wall_path).hits_to_break == 2 and room.get_node("Volumes/BreakableWall").hits_to_break == 1 and room.get_node("BreakableWall").hits_to_break == 4, "Wall restore preserves authored hit counts")
	check(player.global_position == position_before, "Debug reset preserves the player's location")
	var before_wall_id := room.get_node("BreakableWall").get_instance_id()
	key_event = InputEventKey.new()
	key_event.keycode = KEY_F1
	key_event.pressed = true
	Input.parse_input_event(key_event)
	await frames(3)
	check(room.get_node("BreakableWall").get_instance_id() != before_wall_id, "F1 key dispatch really restores breakable rocks")
	var button: Button
	for control: Node in room.get_node("PlaytestControls").find_children("*", "Button", true, false):
		if control.text.begins_with("Respawn enemies"):
			button = control
	var before_button_id := room.get_node("Bellstriker").get_instance_id()
	if button:
		button.pressed.emit()
	check(button != null and room.get_node("Bellstriker").get_instance_id() != before_button_id, "Visible respawn button invokes the same reset")
	for enemy: Node in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	if DisplayServer.get_name() != "headless":
		room.focus_landmark("Breakable rock")
		player.process_mode = Node.PROCESS_MODE_DISABLED
		await frames(28)
		await capture("breakable_rock_in_game")
		room.get_node("BreakableWall").hits_taken = 3
		await frames(20)
		await capture("breakable_rock_critical_in_game")
		await render_gallery(wall_scene)
	var report := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "rendered_images": snapshots, "godot": Engine.get_version_info().string, "display": DisplayServer.get_name()}
	FileAccess.open(OUT.path_join("verification_" + DisplayServer.get_name() + ".json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("LAKESIDE_HUD_AND_BREAKABLES ", JSON.stringify(report))
	room.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)

func label_at(parent: Node, text_value: String, at: Vector2, font_size := 24) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.85, 0.91, 0.97))
	parent.add_child(label)
	return label

func render_gallery(wall_scene: PackedScene) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	root.add_child(canvas)
	var background := ColorRect.new()
	background.size = root.get_visible_rect().size
	background.color = Color(0.027, 0.05, 0.075)
	canvas.add_child(background)
	label_at(canvas, "CAVE SEALS  /  BLUE FRACTURE", Vector2(70, 35), 44)
	label_at(canvas, "Original cave stone  ·  Four damage states  ·  Adjustable hits to break", Vector2(72, 96), 24)
	var last: Node2D
	for index in 5:
		var rock = wall_scene.instantiate()
		rock.position = Vector2(230 + index * 360, 520)
		rock.size = Vector2(205, 615)
		rock.hits_to_break = 4
		rock.hits_taken = mini(index, 3)
		rock.collision_layer = 0
		canvas.add_child(rock)
		last = rock
		label_at(canvas, ["01  HAIRLINE", "02  AWAKENING", "03  SPLITTING", "04  CRITICAL", "05  SHATTER"][index], Vector2(95 + index * 360, 882), 25)
		label_at(canvas, ["Intact · first blue glints", "1 / 4 hits · branching glow", "2 / 4 hits · widening seams", "3 / 4 hits · bright fracture", "Final hit · shards dissolve"][index], Vector2(95 + index * 360, 923), 18)
	label_at(canvas, "Lakeside playtest: F2 respawns enemies    /    F1 restores rocks", Vector2(72, 1025), 22)
	await frames(18)
	last._spawn_fracture_effect(room.get_node("TideDuelist"))
	last.hide()
	await frames(12)
	await capture("blue_rock_damage_stages")
	# Render a second, complete fracture cycle for the animation preview.
	await frames(110)
	for index in 42:
		if index == 12:
			last._spawn_fracture_effect(room.get_node("TideDuelist"))
			last.hide()
		if index == 0:
			last.show()
		await frames(4)
		await capture("fracture_%02d" % index)
	canvas.queue_free()
