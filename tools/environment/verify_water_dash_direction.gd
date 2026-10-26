extends SceneTree
## Actual player input/physics, including both facings and water-to-air handoff.
const OUT := "res://work/water-dash-direction-2026-10-26"
const INPUTS := [&"move_left", &"move_right", &"move_up", &"move_down", &"Jump", &"Dash"]
var checks := 0
var failures: Array[String] = []
var rows: Array[Dictionary] = []
var world: Node2D
var player
var water: Node2D
var starting_dash_speed := -1.0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("WATER_DASH_FAIL " + message)

func release_inputs() -> void:
	for action in INPUTS: Input.action_release(action)

func aim(direction: Vector2, jump := false) -> void:
	release_inputs()
	if direction.x < 0: Input.action_press("move_left")
	if direction.x > 0: Input.action_press("move_right")
	if direction.y < 0: Input.action_press("Jump" if jump else "move_up")
	if direction.y > 0: Input.action_press("move_down")

func tick(count := 1) -> void:
	for i in count:
		await physics_frame
		player._physics_process(1.0 / Engine.physics_ticks_per_second)

func fixture(facing: int, wet := true, with_visual := false) -> void:
	release_inputs()
	if is_instance_valid(world):
		world.queue_free()
		await physics_frame
		await physics_frame
	world = Node2D.new()
	root.add_child(world)
	player = load("res://Src/Characters/Player/player.tscn").instantiate()
	player.get_node("Live3DVisual").enabled = with_visual
	world.add_child(player)
	player.set_physics_process(false)
	player.last_direction = facing
	player.debug_blue_water_power_unlocked = true
	water = Node2D.new()
	world.add_child(water)
	if wet: player.enter_prototype_water(water, -1000.0)
	await physics_frame

func run() -> void:
	for facing: int in [-1, 1]:
		for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1), Vector2(1,1), Vector2.ZERO]:
			await direction_case(facing, direction)
		await direction_case(facing, Vector2.UP, true)
	await breach_case()
	await cancellation_case()
	await land_case()
	await wall_case()
	check(rows.size() == 20, "All 20 direction/input cases completed")
	release_inputs()
	DirAccess.make_dir_recursive_absolute(OUT)
	var report := {"checks": checks, "failures": failures, "directions": rows, "engine": Engine.get_version_info().string}
	FileAccess.open(OUT.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	print("WATER_DASH_DIRECTION ", JSON.stringify(report))
	world.queue_free()
	await physics_frame
	quit(0 if failures.is_empty() else 1)

func start_dash() -> void:
	Input.action_press("Dash")
	await tick()
	Input.action_release("Dash")
	check(player.current_chest.is_dashing, "Actual Dash input starts movement")

func direction_case(facing: int, input: Vector2, jump := false) -> void:
	await fixture(facing)
	# Stale horizontal intent and incoming momentum must not bias vertical input
	# or the explicitly approved neutral-facing fallback.
	player._dash_direction_intent = -facing
	player._dash_direction_intent_timer = 0.2
	player.velocity = Vector2(320, 190)
	aim(input, jump)
	var expected := input.normalized() if input != Vector2.ZERO else Vector2(facing, 0)
	var start: Vector2 = player.position
	await start_dash()
	check(player.velocity.normalized().dot(expected) > 0.99999, "Dash follows held swim direction %s facing %s" % [input, facing])
	if starting_dash_speed < 0: starting_dash_speed = player.velocity.length()
	check(absf(player.velocity.length() - starting_dash_speed) < 0.01, "All directions use equal total dash speed at the same initial momentum")
	check(player.current_action_points == 5, "Dash spends exactly one AP")
	check(is_equal_approx(player.current_chest.dash_cooldown_timer, 0.65 - 1.0 / Engine.physics_ticks_per_second), "Existing cooldown starts once")
	check(player.should_ignore_health_damage(DamageData.new()) and player.is_dash_contact_phasing(), "Water dash retains immunity and contact phasing")
	if is_zero_approx(expected.x): check(player.last_direction == facing, "Vertical dash preserves facing")
	aim(-expected)
	await tick(6)
	release_inputs()
	await tick(6)
	check(player.velocity.normalized().dot(expected) > 0.99999, "Changing/releasing input cannot steer an active dash")
	check((player.position-start).normalized().dot(expected) > 0.999, "Actual displacement follows dash direction")
	check(player.current_action_points == 5, "Holding dash movement does not repeat AP spend")
	rows.append({"facing": facing, "input": str(input), "jump_as_up": jump, "velocity": str(player.velocity), "displacement": str(player.position-start)})
	await tick(35)
	check(not player.current_chest.is_dashing and player.velocity.length() < 1.0, "Dash expires and ordinary swim braking resumes")
	check(not player.should_ignore_health_damage(DamageData.new()), "Dash immunity expires normally")

func breach_case() -> void:
	await fixture(1)
	aim(Vector2.UP)
	await start_dash()
	player.exit_prototype_water(water)
	var breach: Vector2 = player.velocity
	check(breach.x == 0 and breach.y < -player.lake_swim_speed, "Upward breach retains vertical earned speed")
	check(player._traversal_launch_control_lock_timer > 0, "Existing breach control lock remains")
	release_inputs()
	await tick(4)
	check(absf(player.velocity.x) < 0.001 and player.velocity.y < 0, "Chest cannot inject sideways speed after leaving water")
	check(player.velocity.length() <= breach.length() + 0.01, "Airborne dash does not add a second launch boost")

func cancellation_case() -> void:
	await fixture(-1)
	aim(Vector2.UP)
	await start_dash()
	player.current_chest.stop_dash_on_enemy_contact()
	check(not player.current_chest.is_dashing and player.velocity.is_zero_approx(), "Contact cancellation stops both water-dash axes")
	player.current_chest.dash_cooldown_timer = 0
	player.set_action_points(6)
	await tick()
	await start_dash()
	var speed: float = player.velocity.length()
	player.apply_water_bulb_boost(Vector2(1,-1), 1.2, 1000)
	check(not player.is_dash_active(), "Bulb launch cancels water dash")
	check(player.velocity.normalized().is_equal_approx(Vector2(1,-1).normalized()) and player.velocity.length() >= speed, "Bulb installs its full new velocity after cancellation")
	player.current_chest.dash_cooldown_timer = 0
	player.set_action_points(0)
	check(not player.current_chest._start_dash(), "No AP still blocks dash")

func land_case() -> void:
	await fixture(1, false)
	player._dash_direction_intent = -1
	player._dash_direction_intent_timer = 0.2
	aim(Vector2.UP)
	await start_dash()
	check(player.current_chest.dash_direction == -1 and player.velocity.x < -1000, "Land dash retains buffered horizontal escape")
	check(player.velocity.y >= 0, "Holding Up does not create vertical land dash")
	player.velocity.y = 123
	player.current_chest.process_passive(0.01)
	check(player.velocity.y == 123, "Land chest still leaves vertical velocity to gravity/jump")
	player.current_chest.stop_dash_on_enemy_contact()
	check(player.velocity.x == 0 and player.velocity.y == 123, "Land cancellation retains existing vertical motion")

func wall_case() -> void:
	await fixture(1)
	var wall := StaticBody2D.new()
	wall.position = Vector2(150, 0)
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40, 2000)
	collider.shape = rectangle
	wall.add_child(collider)
	world.add_child(wall)
	await physics_frame
	aim(Vector2.RIGHT)
	await start_dash()
	await tick(12)
	check(player.position.x < 130, "Directional water dash still respects solid walls")
