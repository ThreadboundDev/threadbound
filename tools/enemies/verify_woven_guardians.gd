extends SceneTree
var checks := 0
var failures: Array[String] = []
var world: Node2D
var player: CharacterBody2D
var health
var box

func _initialize() -> void:
	for folder in ["res://Assets/BlueBiome/Characters/SharedTexturesV2", "res://Assets/BlueBiome/Enemies/EaveRunner/Models", "res://Assets/BlueBiome/Enemies/EaveRunner/Textures", "res://Assets/BlueBiome/Enemies/LoomHeron/Models", "res://Assets/BlueBiome/Enemies/LoomHeron/Textures"]:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".import"):
				var config := ConfigFile.new()
				if config.load(folder.path_join(file)) == OK:
					var uid := ResourceUID.text_to_id(config.get_value("remap", "uid", ""))
					if uid != -1 and not ResourceUID.has_id(uid):
						ResourceUID.add_id(uid, folder.path_join(file.trim_suffix(".import")))
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("GUARDIAN_FAIL " + message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func solid(at: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = at
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = size
	body.add_child(shape)
	world.add_child(body)
	return body

func make_player() -> void:
	player = CharacterBody2D.new()
	player.position = Vector2(2000, 500)
	player.collision_layer = 1
	player.collision_mask = 0
	player.add_to_group("player")
	var shape := CollisionShape2D.new()
	shape.position.y = -70
	shape.shape = CapsuleShape2D.new()
	shape.shape.radius = 20
	shape.shape.height = 140
	player.add_child(shape)
	health = load("res://Src/Components/health_component.gd").new()
	health.name = "Health"
	health.invincible_after_hit = 0
	player.add_child(health)
	box = load("res://Src/Components/hurtbox_component.gd").new()
	box.position.y = -70
	box.collision_layer = 2
	box.collision_mask = 4
	box.health_component_path = NodePath("../Health")
	box.hurtbox_owner_path = NodePath("..")
	var hit_shape := CollisionShape2D.new()
	hit_shape.shape = shape.shape
	box.add_child(hit_shape)
	player.add_child(box)
	world.add_child(player)
	health.configure(1000)

func run() -> void:
	world = Node2D.new()
	root.add_child(world)
	current_scene = world
	solid(Vector2(500, 520), Vector2(2000, 40))
	var wall := solid(Vector2(720, 250), Vector2(40, 500))
	make_player()
	var eave = load("res://Src/Enemies/EaveRunner/eave_runner.tscn").instantiate()
	eave.position = Vector2(679, 500)
	eave.patrol_distance = 0
	world.add_child(eave)
	await frames(3)
	check(eave.wall_contact(1), "Three real wall contacts validate brace")
	var corner := solid(Vector2(1200, 480), Vector2(40, 40))
	eave.position = Vector2(1159, 500)
	await frames(2)
	check(not eave.wall_contact(1), "Knee/foot corner cannot act as a full-height perch")
	eave.position = Vector2(679, 500)
	player.position = Vector2(400, 500)
	health.configure(1000)
	var saw_attach := false
	var saw_perch := false
	var saw_launch := false
	var saw_slash := false
	var saw_recover := false
	var damaged_windup := false
	var min_y := 500.0
	for i in 200:
		await frames(1)
		saw_attach = saw_attach or eave.wall_mode == &"attach"
		saw_perch = saw_perch or eave.wall_mode == &"perch"
		saw_launch = saw_launch or eave.attack_phase == &"launch"
		saw_slash = saw_slash or eave.attack_phase == &"slash"
		saw_recover = saw_recover or eave.attack_phase == &"recover"
		if eave.attack_phase == &"windup" and not saw_launch and health.current_health < 1000:
			damaged_windup = true
		min_y = minf(min_y, eave.position.y)
	check(saw_attach and saw_perch and min_y < 400, "Climbs real wall and reaches perch")
	check(saw_launch and saw_slash and saw_recover, "Wall windup launches slash and lands into recovery")
	check(not damaged_windup, "Wall windup never damages")
	check(health.current_health <= 980, "Wall slash crosses victim and deals damage")
	check(eave.position.x > 0 and eave.position.x < 700 and eave.position.y < 501, "Leap respects wall and floor")
	print("EAVE_NATURAL ", saw_attach, saw_perch, saw_launch, saw_slash, saw_recover, " hp=",health.current_health," y=",min_y)
	# Isolate ground throw from automatic movement and check release / aim lock.
	eave.reset_for_save_point()
	eave.prefer_wall = false
	eave.position = Vector2(200, 500)
	player.position = Vector2(450, 500)
	health.configure(1000)
	await frames(16)
	check(eave.attack_phase == &"windup", "Ground fallback starts throwing windup")
	check(get_nodes_in_group("woven_pins").is_empty(), "No projectile during windup")
	await frames(31)
	check(not get_nodes_in_group("woven_pins").is_empty(), "Pin releases with skeletal release clip")
	await frames(35)
	check(health.current_health == 988, "Pin hits once for 12 damage")
	# Existing Hurt state must cancel the pending release, not just the animation.
	eave.reset_for_save_point()
	eave.position = Vector2(200, 500)
	player.position = Vector2(450, 500)
	await frames(8)
	var damage := DamageData.new()
	damage.amount = 5
	damage.source = player
	damage.knockback = Vector2(-80, -30)
	damage.hit_pause = 0
	damage.use_receiver_screen_shake_fallback = false
	check(eave.hurtbox.receive_hit(damage), "Guardian uses normal hurtbox damage")
	check(eave.state_machine.current_state_name == &"Hurt" and eave.attack_phase == &"" and not eave.attack_hitbox.active, "Hurt cancels windup and active slash")
	await frames(15)
	check(get_nodes_in_group("woven_pins").is_empty(), "Interrupted windup cannot spawn delayed pin")
	# A pin travels continuously through area queries, but a thin terrain wall
	# must win before a victim behind it. Its owner may be elsewhere entirely.
	eave.state_machine.set_physics_process(false)
	eave.set_physics_process(false)
	eave.end_attack()
	var blocker := solid(Vector2(330, 420), Vector2(6, 160))
	health.configure(1000)
	var pin = load("res://Src/Enemies/EaveRunner/woven_pin.gd").new()
	pin.source = eave
	pin.position = Vector2(250, 430)
	pin.velocity = Vector2(2000, 0)
	world.add_child(pin)
	await frames(15)
	check(health.current_health == 1000 and not is_instance_valid(pin), "Thin wall stops even a fast pin before the victim")
	check(not eave._can_target_player(player), "Terrain blocks acquiring a player")
	blocker.queue_free()
	await frames(2)
	pin = load("res://Src/Enemies/EaveRunner/woven_pin.gd").new()
	pin.source = eave
	pin.position = Vector2(250, 430)
	pin.velocity = Vector2(560, 0)
	world.add_child(pin)
	eave.reset_for_save_point()
	await frames(2)
	check(not is_instance_valid(pin), "Save reset removes owned projectiles")
	eave.queue_free()
	wall.queue_free()
	corner.queue_free()
	player.position = Vector2(550, 500)
	await frames(3)
	var heron = load("res://Src/Enemies/LoomHeron/loom_heron.tscn").instantiate()
	heron.position = Vector2(280, 280)
	world.add_child(heron)
	health.configure(1000)
	await frames(12)
	check(heron.attack_phase == &"windup" and not heron.attack_hitbox.active, "Heron telegraphs harmlessly above target")
	await frames(32)
	var locked: Vector2 = heron._locked_aim
	player.position.x += 120
	await frames(8)
	check(heron._aim_locked and heron._locked_aim.is_equal_approx(locked), "Needle aim locks before release; no homing")
	player.position.x -= 120
	var saw_fire := false
	var saw_heron_recover := false
	var max_needles := 0
	var brake_y := 0.0
	for i in 100:
		await frames(1)
		saw_fire = saw_fire or heron.attack_phase == &"fire"
		max_needles = maxi(max_needles, get_nodes_in_group("heron_needles").size())
		check(not heron.attack_hitbox.active, "Ranged heron never enables a body attack hitbox")
		if heron.attack_phase == &"recover":
			saw_heron_recover = true
			brake_y = heron.position.y
	check(saw_fire and saw_heron_recover and max_needles == 1, "Heron emits exactly one needle then recovers")
	check(brake_y > 420 and brake_y < 470, "Heron descends into low reachable recovery")
	check(health.current_health == 982, "Heron needle hits once for 18 damage")
	check(heron.position.is_finite(), "Flight remains finite")
	check(heron.model._view.size == Vector2i(1536,1536), "Enemy renders at doubled linear resolution")
	check(heron.model.bone_world_position(&"beak_tip") is Vector2, "Projectile muzzle follows real beak-tip bone")
	# A wall inserted after the aim locks still stops the fired needle.
	heron.reset_for_save_point()
	heron.state_machine.set_physics_process(false)
	heron.set_physics_process(false)
	heron.position = Vector2(280, 280)
	heron.target = player
	heron.begin_attack()
	heron._lock_aim()
	blocker = solid(Vector2(410, 250), Vector2(8, 500))
	await frames(2)
	heron.activate_attack_hitbox()
	health.configure(1000)
	for i in 45:
		heron.update_attack_motion(1.0 / 60)
		await frames(1)
	check(heron.position.x < 400 and health.current_health == 1000, "Fired needle cannot tunnel or damage through wall")
	check(heron.attack_phase == &"recover" and not heron.attack_hitbox.active, "Blocked shot still enters vulnerable recovery")
	blocker.queue_free()
	await frames(2)
	heron.reset_for_save_point()
	heron.position = Vector2(280,280)
	heron.target = player
	heron.begin_attack()
	heron._lock_aim()
	heron.activate_attack_hitbox()
	damage.amount = 5
	check(heron.hurtbox.receive_hit(damage), "Ranged heron accepts interruption")
	await frames(12)
	check(get_nodes_in_group("heron_needles").is_empty(), "Hurt before release cancels pending needle")
	check(heron.velocity.x < 0, "Heron retains its incoming hurt recoil")
	heron.state_machine.set_physics_process(true)
	heron.set_physics_process(true)
	damage.amount = 1000
	check(heron.hurtbox.receive_hit(damage), "Heron receives lethal hit")
	await frames(90)
	check(heron.is_dead and not heron.visible and not heron.attack_hitbox.active, "Death animation completes and disables damage")
	heron.reset_for_save_point()
	check(not heron.is_dead and heron.visible and heron.health_component.current_health == root.get_node("EnemyScaling").scale_health(65), "Save reset restores heron")
	heron.hurtbox.receive_hit(damage)
	await frames(2)
	heron.reset_for_save_point()
	await frames(90)
	check(not heron.is_dead and heron.visible, "An immediate save reset cannot be hidden by an old death timer")
	print("WOVEN_GUARDIANS_CHECKS ", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
