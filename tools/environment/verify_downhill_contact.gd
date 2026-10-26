extends SceneTree
## Real player controller on mirrored slopes; catches Run/Fall flicker downhill.
const OUT := "res://work/downhill-contact-2026-10-26"
var checks := 0
var failures: Array[String] = []
var rows: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("DOWNHILL_FAIL " + message)

func tick(player: CharacterBody2D, count: int) -> void:
	for i in count:
		await physics_frame
		player._physics_process(1.0 / Engine.physics_ticks_per_second)

func run() -> void:
	for ratio: float in [0.25, 0.5, 0.9]:
		for direction: int in [-1, 1]:
			for travel_speed: float in [500.0, 1500.0]:
				await slope_case(ratio, direction, travel_speed)
	check(rows.size() == 12 and checks == 60, "All 12 controller cases completed")
	DirAccess.make_dir_recursive_absolute(OUT)
	var report := {"checks": checks, "failures": failures, "slopes": rows}
	FileAccess.open(OUT.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	print("DOWNHILL_CONTACT ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func slope_case(ratio: float, direction: int, travel_speed: float) -> void:
	var rig := Node2D.new()
	root.add_child(rig)
	var floor_body := StaticBody2D.new()
	var polygon := CollisionPolygon2D.new()
	var rise := ratio * direction * 2048.0
	polygon.polygon = PackedVector2Array([Vector2(-2048, -rise), Vector2(2048, rise), Vector2(2048, 4096), Vector2(-2048, 4096)])
	floor_body.add_child(polygon)
	rig.add_child(floor_body)
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	player.get_node("Live3DVisual").enabled = false
	rig.add_child(player)
	player.set_physics_process(false)
	player.speed = travel_speed
	player.position = Vector2(0, -player._get_player_collision_bottom_offset() - 80)
	await tick(player, 45)
	check(player.is_on_floor(), "Settled on slope %s direction %s speed %s" % [ratio, direction, travel_speed])
	var action := "move_right" if direction > 0 else "move_left"
	Input.action_press(action)
	var airborne := 0
	var falling_poses := 0
	var start: Vector2 = player.position
	for i in 40:
		await tick(player, 1)
		if not player.is_on_floor(): airborne += 1
		if player.player_animation.animation in [&"Jump_Descent", &"Jump_Apex"]: falling_poses += 1
	Input.action_release(action)
	check(airborne == 0, "Continuous downhill ground contact %s/%s/%s (%s airborne frames)" % [ratio, direction, travel_speed, airborne])
	check(falling_poses == 0, "No falling pose during downhill travel %s/%s/%s" % [ratio, direction, travel_speed])
	check((player.position.x-start.x)*direction > 100 and player.position.y > start.y, "Travels down slope rather than sticking")
	Input.action_press("Jump")
	await tick(player, 1)
	Input.action_release("Jump")
	check(not player.is_on_floor() and player.velocity.y < 0, "Jump detaches from slope")
	rows.append({"slope": ratio, "direction": direction, "speed": travel_speed, "airborne_frames": airborne, "falling_poses": falling_poses})
	rig.queue_free()
	await physics_frame
	await physics_frame
