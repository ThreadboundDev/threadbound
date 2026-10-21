extends SceneTree
## Exercise the authored map with the real player, HUD, geometry and F2 respawn.
var failures: Array[String] = []
var checks := 0
var room: Node2D
var capture_count := 0
var render := false

func _initialize() -> void:
	for folder in ["res://Assets/BlueBiome/Characters/SharedTexturesV2", "res://Assets/BlueBiome/Art/LakesideMap", "res://Assets/BlueBiome/Art/Lakeside3D/Models", "res://Assets/BlueBiome/Art/Lakeside3D/Textures", "res://Assets/BlueBiome/Villagers/Models", "res://Assets/BlueBiome/Villagers/Textures", "res://Assets/BlueBiome/Enemies/EaveRunner/Models", "res://Assets/BlueBiome/Enemies/EaveRunner/Textures", "res://Assets/BlueBiome/Enemies/LoomHeron/Models", "res://Assets/BlueBiome/Enemies/LoomHeron/Textures"]:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".import"):
				var config := ConfigFile.new()
				if config.load(folder.path_join(file)) == OK:
					var uid := ResourceUID.text_to_id(config.get_value("remap", "uid", ""))
					if uid != -1 and not ResourceUID.has_id(uid):
						ResourceUID.add_id(uid, folder.path_join(file.trim_suffix(".import")))
	render = DisplayServer.get_name() != "headless"
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("LAKESIDE_GUARDIAN_FAIL " + message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func capture(label: String) -> void:
	if not render:
		return
	await RenderingServer.frame_post_draw
	var path := "res://work/woven-guardians/renders/" + label + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "Captured " + label)
	capture_count += 1

func run() -> void:
	room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(20)
	var player = room.get_node("Player")
	check(room._enemy_spawns.size() == 5, "F2 records both guardians and all three previous enemies")
	check(get_nodes_in_group("hermit_guardians").size() == 2, "Both live guardians belong to Hermit group")
	check(room.get_node("LakesideArtStage").placements.size() == 10, "Village and furnishings retained")
	for enemy in get_nodes_in_group("enemies"):
		if enemy.name not in ["EaveRunner", "LoomHeron"]:
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for label in ["Eave Runner", "Loom Heron"]:
		var enemy = room.get_node("EaveRunner" if label == "Eave Runner" else "LoomHeron")
		room.focus_landmark(label)
		await frames(12)
		check(player.is_on_floor(), label + " landmark places player on actual floor")
		print(label, " player=",player.position," feet=",enemy.target_feet(player), " enemy=",enemy.position," dry=",enemy.dry_at(enemy.target_feet(player)))
		player.set_physics_process(false)
		player.health_component.configure(1000)
		var phases: Array[StringName] = []
		var lowest_y: float = enemy.position.y
		var highest_y: float = enemy.position.y
		for i in 240:
			await frames(1)
			if not phases.has(enemy.attack_phase):
				phases.append(enemy.attack_phase)
			lowest_y = maxf(lowest_y, enemy.position.y)
			highest_y = minf(highest_y, enemy.position.y)
			if render and i % 6 == 0:
				await capture(("Eave" if label == "Eave Runner" else "Heron") + "_%03d" % (i / 6))
		check(phases.has(&"windup") and phases.has(&"recover"), label + " naturally attacks and recovers against real player")
		check(player.health_component.current_health < 1000, label + " can hit actual player's hurtbox")
		check(enemy.position.distance_to(enemy.home_position) < enemy.home_leash, label + " stays in encounter")
		check(enemy.model.animator != null, label + " renders imported skeletal animations")
		print("LAKESIDE_PHASES ",label," ",phases," hp=",player.health_component.current_health," y=",highest_y,"..",lowest_y)
		if label == "Eave Runner" and not render:
			var launches := 0
			var previous: StringName = enemy.attack_phase
			for i in 600:
				await frames(1)
				if enemy.attack_phase == &"launch" and previous != &"launch":
					launches += 1
				previous = enemy.attack_phase
			check(launches >= 1, "Runner finds another wall and repeats its leap after landing")
		player.set_physics_process(true)
	# Restore must replace both controllers and remove any pins owned by old instances.
	var old_eave = room.get_node("EaveRunner")
	var old_heron = room.get_node("LoomHeron")
	room.respawn_enemies()
	await frames(4)
	check(not is_instance_valid(old_eave) and not is_instance_valid(old_heron), "F2 disposes old enemy instances")
	check(room.get_node("EaveRunner").health_component.current_health == root.get_node("EnemyScaling").scale_health(90), "F2 restores Eave Runner HP")
	check(room.get_node("LoomHeron").health_component.current_health == root.get_node("EnemyScaling").scale_health(65), "F2 restores heron HP")
	check(room._feedback.text.begins_with("5 enemies"), "Respawn count includes new guardians")
	for pin in get_nodes_in_group("woven_pins"):
		check(is_instance_valid(pin.source) and pin.source == room.get_node("EaveRunner"), "F2 leaves no orphan pins")
	room.focus_landmark("Shore")
	await frames(3)
	player.set_physics_process(false)
	player.health_component.configure(1000)
	player.last_direction = -1
	player.is_blocking = true
	var eave = room.get_node("EaveRunner")
	eave.process_mode = Node.PROCESS_MODE_DISABLED
	# The original thrower stands to the right; the travelling pin comes from
	# the left. Blocking must use the pin's current incoming side.
	eave.global_position = player.global_position + Vector2(500, 0)
	var pin = load("res://Src/Enemies/EaveRunner/woven_pin.gd").new()
	pin.source = eave
	pin.position = player.get_node("Hurtbox/CollisionShape2D").global_position - Vector2(100, 0)
	pin.velocity = Vector2(560, 0)
	room.add_child(pin)
	await frames(20)
	check(player.health_component.current_health > 988 and player.health_component.current_health < 1000, "Existing shield block reduces projectile damage from correct incoming side")
	player.is_blocking = false
	player.set_physics_process(true)
	print("WOVEN_LAKESIDE_CHECKS ",checks," captures=",capture_count," failures=",failures)
	quit(0 if failures.is_empty() else 1)
