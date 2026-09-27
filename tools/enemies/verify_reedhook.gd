extends Node2D
const ENEMY = preload("res://Src/Enemies/Reedhook/reedhook.tscn")
var enemy: EnemyBase
var player: CharacterBody2D
var health: HealthComponent

func _ready() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error("REEDHOOK_FAIL " + message)
		get_tree().quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func run() -> void:
	var ground := StaticBody2D.new()
	ground.position = Vector2(300,520)
	var ground_shape := CollisionShape2D.new()
	ground_shape.shape = RectangleShape2D.new()
	ground_shape.shape.size = Vector2(600,40)
	ground.add_child(ground_shape)
	add_child(ground)
	player = CharacterBody2D.new()
	player.position = Vector2(1500,500)
	player.collision_layer = 1
	player.collision_mask = 0
	player.add_to_group("player")
	var body := CollisionShape2D.new()
	body.position.y = -65
	body.shape = RectangleShape2D.new()
	body.shape.size = Vector2(34,130)
	player.add_child(body)
	health = HealthComponent.new()
	health.name = "Health"
	health.invincible_after_hit = 0
	player.add_child(health)
	var box := HurtboxComponent.new()
	box.position.y = -65
	box.collision_layer = 2
	box.collision_mask = 4
	box.health_component_path = NodePath("../Health")
	box.hurtbox_owner_path = NodePath("..")
	var shape := CollisionShape2D.new()
	shape.shape = body.shape
	box.add_child(shape)
	player.add_child(box)
	add_child(player)
	enemy = ENEMY.instantiate()
	enemy.position = Vector2(300,490)
	enemy.start_facing = 1
	enemy.patrol_distance = 1000
	add_child(enemy)
	await frames(25)
	check(enemy.is_on_floor(), "Settles onto ground")
	var start := enemy.position
	await frames(35)
	check(enemy.position.x > start.x + 15, "Walk moves right")
	check(enemy.model.animator.current_animation == "walk", "Walk animation follows movement")
	await frames(280)
	check(enemy.position.x < 575 and enemy.position.y < 501, "Patrol turns before ledge")
	print("PASS walk / grounded placement / patrol ledges")
	for side in [1,-1]:
		enemy.reset_for_save_point()
		enemy.position = Vector2(300,499)
		player.position = Vector2(300+side*108,500)
		health.configure(100)
		await frames(12)
		check(enemy.attack_phase == &"windup", "Draw stance starts")
		check(not enemy.attack_hitbox.active and health.current_health == 100, "Windup harmless")
		check(enemy.facing == side, "Faces victim")
		await frames(55)
		check(health.current_health == 82, "One hit per sweep in each direction")
		check(not enemy.attack_hitbox.active, "Recovery harmless")
	print("PASS left/right attacks / single hit / recovery")
	enemy.reset_for_save_point()
	enemy.position = Vector2(300,499)
	player.position = Vector2(405,500)
	await frames(12)
	var damage := DamageData.new()
	damage.amount = 10
	damage.knockback = Vector2(-100,0)
	damage.source = player
	damage.hit_pause = 0
	damage.use_receiver_screen_shake_fallback = false
	check(enemy.hurtbox.receive_hit(damage), "Accepts player damage")
	check(enemy.state_machine.current_state_name == &"Hurt" and not enemy.attack_hitbox.active, "Hit interrupts attack")
	check(enemy.model.animator.current_animation == "hurt", "Hurt animation")
	check(enemy.velocity.x < 0, "Recoil retained")
	await frames(27)
	check(enemy.state_machine.current_state_name != &"Hurt", "Hurt recovers")
	print("PASS hurt / interruption / recoil")
	enemy.state_machine.set_physics_process(false)
	enemy.set_physics_process(false)
	enemy.end_attack()
	enemy.position = Vector2(556,499)
	player.position = Vector2(660,500)
	for i in 40:
		enemy.velocity.x = 105
		enemy.apply_gravity(1.0/60)
		enemy._guard_edge(1.0/60)
		enemy.move_and_slide()
		await get_tree().physics_frame
	check(enemy.position.x < 576 and enemy.position.y < 501, "Forward attack step cannot leave ledge")
	var wall := StaticBody2D.new()
	wall.position = Vector2(400,400)
	var wall_shape := CollisionShape2D.new()
	wall_shape.shape = RectangleShape2D.new()
	wall_shape.shape.size = Vector2(16,200)
	wall.add_child(wall_shape)
	add_child(wall)
	enemy.position = Vector2(300,499)
	player.position = Vector2(450,500)
	await frames(3)
	check(not enemy._can_target_player(player), "Walls occlude acquisition")
	for clip in [&"idle",&"walk",&"windup",&"sweep",&"recover",&"hurt"]:
		check(enemy.model.animator.has_animation(clip), "Imported clip " + clip)
	damage.amount = 1000
	enemy.health_component.configure(100)
	enemy.hurtbox.receive_hit(damage)
	await frames(40)
	check(enemy.is_dead and not enemy.attack_hitbox.active, "Death disables attack")
	enemy.reset_for_save_point()
	check(not enemy.is_dead and enemy.visible and enemy.health_component.current_health == 100, "Save point resets enemy")
	print("PASS ledge step / wall occlusion / clips / death / reset")
	print("REEDHOOK_ALL_CHECKS_PASS")
	get_tree().quit()
