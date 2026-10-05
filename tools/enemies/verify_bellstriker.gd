extends Node2D
const ENEMY = preload("res://Src/Enemies/Bellstriker/bellstriker.tscn")
const WATER = preload("res://Src/Environment/Greybox/greybox_polygon_water.tscn")
var enemy: EnemyBase
var player: CharacterBody2D
var health: HealthComponent
var failures := 0

func _ready() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("BELL_FAIL: " + message)
	else:
		print("PASS " + message)

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame

func run() -> void:
	var water := WATER.instantiate()
	water.points = PackedVector2Array([Vector2(0,250), Vector2(850,250), Vector2(850,650), Vector2(0,650)])
	add_child(water)
	player = CharacterBody2D.new()
	player.collision_layer = 1
	player.collision_mask = 0
	player.add_to_group("player")
	player.position = Vector2(1800, 400)
	health = HealthComponent.new()
	health.name = "Health"
	health.invincible_after_hit = 0
	player.add_child(health)
	var box := HurtboxComponent.new()
	box.collision_layer = 2
	box.collision_mask = 4
	box.health_component_path = NodePath("../Health")
	box.hurtbox_owner_path = NodePath("..")
	var shape := CollisionShape2D.new()
	shape.position.y = -35
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 20
	box.add_child(shape)
	player.add_child(box)
	add_child(player)
	enemy = ENEMY.instantiate()
	enemy.position = Vector2(400,450)
	add_child(enemy)
	await frames(5)
	check(enemy.in_water, "Water classification")
	for clip in [&"idle", &"walk", &"swim", &"swim_idle", &"box_idle", &"leap", &"hurt", &"dead", &"jab", &"cross", &"smash", &"water_charge_1", &"water_charge_2", &"water_charge_3", &"water_jab", &"water_cross", &"water_smash", &"water_box_recover"]:
		check(enemy.bell_visual.animator.has_animation(clip), "Animation " + str(clip))
	player.position = Vector2(800,500)
	var origin := enemy.position
	await frames(25)
	check(enemy.position.x > origin.x + 40 and enemy.position.y > origin.y, "Two-axis aquatic pursuit")
	check(enemy.bell_visual._clip == &"swim", "Water pursuit uses swimming, not walking")
	# Drive the real attack state deterministically, keeping the target in reach.
	enemy.position = Vector2(400,450)
	enemy.velocity = Vector2.ZERO
	player.position = Vector2(570,450)
	enemy.target = player
	enemy.state_machine.transition_to(&"Attack")
	await frames(12)
	check(enemy.attack_phase == &"charge" and not enemy.attack_hitbox.active and health.current_health == 100, "Charge is harmless")
	check(enemy.bell_visual._clip == &"water_charge_1" and enemy.bell_visual.boxing, "Underwater charge uses upright boxing pose")
	check(absf(enemy.bell_visual.image.rotation) < deg_to_rad(3.0), "Boxing presentation stays vertical instead of tilting along pursuit")
	await frames(3)
	var direction: Vector2 = enemy.strike_direction
	player.position.y += 40
	await frames(2)
	check(enemy.strike_direction.is_equal_approx(direction), "Final charge locks aim")
	player.position.y -= 40
	var seen := [false, false, false]
	var punches_before: int = enemy.punches_started
	for i in range(180):
		player.position = enemy.position + Vector2(170,0)
		await frames(1)
		if enemy.attack_phase == &"strike":
			seen[enemy.combo_step] = true
		if enemy.attack_phase in [&"charge", &"between"]:
			if enemy.attack_hitbox.active:
				check(false, "Charge/between punches cannot damage")
		if enemy.attack_phase == &"recover":
			break
	check(seen.all(func(value): return value) and enemy.punches_started - punches_before == 3, "Jab, cross, then double-claw finisher")
	check(health.current_health == 31, "Exactly one hit per punch: 16 + 21 + 32 damage")
	check(enemy.attack_phase == &"recover" and not enemy.attack_hitbox.active, "Recovery disables damage")
	await frames(40)
	check(enemy.attack_phase == &"recover", "Committed recovery gives counterplay")
	# A target can bait the first jab, then escape the remaining sequence.
	box.collision_layer = 0
	enemy.state_machine.transition_to(&"Idle")
	enemy.position = Vector2(400,450)
	enemy.velocity = Vector2.ZERO
	player.position = Vector2(230,450)
	enemy.target = player
	enemy.state_machine.transition_to(&"Attack")
	await frames(15)
	check(enemy.strike_direction.x < -0.9 and enemy.facing == -1, "Boxing aims correctly facing left")
	var released: Vector2 = enemy.strike_direction
	await frames(6)
	player.position = Vector2(800,550)
	await frames(2)
	check(enemy.strike_direction.is_equal_approx(released), "Released jab cannot home toward a moved target")
	player.position = Vector2(1800,600)
	await frames(22)
	check(enemy.attack_phase == &"recover" and enemy.combo_step == 0, "Escaping stops the remaining punches")
	box.collision_layer = 2
	enemy.state_machine.transition_to(&"Idle")
	# Terrain must prevent damaging a target on the other side.
	var wall := StaticBody2D.new()
	wall.position = Vector2(510,420)
	var wall_shape := CollisionShape2D.new()
	wall_shape.shape = RectangleShape2D.new()
	wall_shape.shape.size = Vector2(20,300)
	wall.add_child(wall_shape)
	add_child(wall)
	enemy.position = Vector2(400,450)
	enemy.velocity = Vector2.ZERO
	player.position = Vector2(600,450)
	await frames(3)
	check(not enemy.is_player_in_attack_range(), "Wall blocks attack acquisition")
	enemy.state_machine.transition_to(&"Attack")
	await frames(60)
	check(health.current_health == 31 and enemy.position.x <= 431, "Wall stops strike and damage")
	wall.queue_free()
	await frames(2)
	# A real dock tests the arc, rather than only checking launch velocity.
	var dock := StaticBody2D.new()
	dock.position = Vector2(1450,475)
	var dock_shape := CollisionShape2D.new()
	dock_shape.shape = RectangleShape2D.new()
	dock_shape.shape.size = Vector2(1200,350)
	dock.add_child(dock_shape)
	add_child(dock)
	enemy.state_machine.transition_to(&"Chase")
	enemy.position = Vector2(530,470)
	enemy.velocity = Vector2.ZERO
	enemy._leap_cooldown = 0
	player.position = Vector2(970,300)
	enemy.target = player
	await frames(70)
	check(enemy.leap_count > 0, "Leaps from water toward a land target")
	check(enemy.position.x > 850 and not enemy.in_water and enemy.is_on_floor(), "Lands on dock and becomes terrestrial")
	enemy.state_machine.transition_to(&"Chase")
	player.position = Vector2(1800,300)
	var land_origin := enemy.position
	await frames(30)
	check(enemy.position.x > land_origin.x + 40.0 and enemy.is_on_floor(), "Terrestrial burst pursuit stays grounded")
	check(enemy.bell_visual._clip == &"walk", "Land pursuit uses walking")
	var damage := DamageData.new()
	damage.amount = 10
	damage.hit_pause = 0
	enemy.hurtbox.receive_hit(damage)
	await frames(2)
	check(enemy.state_machine.current_state_name == &"Hurt" and not enemy.attack_hitbox.active, "Hurt interrupts attacks safely")
	enemy.reset_for_save_point()
	await frames(2)
	check(enemy.health_component.current_health == 320 and enemy.in_water and not enemy.is_dead, "Save-point reset restores health and water mode")
	var pocket := WATER.instantiate()
	pocket.air_pocket = true
	pocket.points = PackedVector2Array([Vector2(200,250), Vector2(600,250), Vector2(600,600), Vector2(200,600)])
	add_child(pocket)
	await frames(2)
	check(not enemy.in_water, "Air pockets override lake water")
	pocket.queue_free()
	await frames(2)
	check(enemy.in_water, "Leaving an air pocket restores swimming")
	enemy.stats = enemy.stats.duplicate()
	enemy.stats.thread_knot_drop_count = 0
	damage.amount = 1000
	enemy.hurtbox.receive_hit(damage)
	await frames(60)
	check(enemy.is_dead and not enemy.visible and not enemy.attack_hitbox.active, "Death disables combat and hides resettable enemy")
	enemy.reset_for_save_point()
	await frames(2)
	check(not enemy.is_dead and enemy.visible and enemy.health_component.current_health == 320, "Dead enemy restores at save point")
	# Verify the lake placement is not embedded inside the existing painted terrain.
	var lake := load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lake_greybox.tscn").instantiate() as Node2D
	add_child(lake)
	await frames(3)
	var placed := lake.get_node("Bellstriker") as EnemyBase
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = placed.get_node("CollisionShape2D").shape
	query.transform = placed.get_node("CollisionShape2D").global_transform
	query.collision_mask = 1
	check(get_world_2d().direct_space_state.intersect_shape(query).is_empty() and placed.in_water, "Lake spawn has water and terrain clearance")
	print("BELLSTRIKER verification complete; failures=", failures)
	get_tree().quit(1 if failures else 0)
