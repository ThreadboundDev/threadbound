extends Node2D
## Headless integration checks with real water polygons and combat components.
const FISH = preload("res://Src/Enemies/TideDuelist/tide_duelist.tscn")
const WATER = preload("res://Src/Environment/Greybox/greybox_polygon_water.tscn")
var fish: EnemyBase
var player: CharacterBody2D
var player_health: HealthComponent
var world: Node2D

func _ready() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("TIDE_FAIL: " + message)
		get_tree().quit(1)
		assert(condition, message)

func frames(count: int) -> void:
	for index in range(count):
		await get_tree().physics_frame

func run() -> void:
	world = Node2D.new()
	add_child(world)
	var water := WATER.instantiate()
	water.points = PackedVector2Array([Vector2.ZERO, Vector2(1800,0), Vector2(1800,1200), Vector2(0,1200)])
	world.add_child(water)
	player = CharacterBody2D.new()
	player.name = "TestPlayer"
	player.position = Vector2(1600,500)
	player.collision_layer = 1
	player.collision_mask = 0
	player.add_to_group("player")
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 20
	player.add_child(shape)
	player_health = HealthComponent.new()
	player_health.name = "Health"
	player_health.invincible_after_hit = 0.0
	player.add_child(player_health)
	var box := HurtboxComponent.new()
	box.name = "Hurtbox"
	box.collision_layer = 2
	box.collision_mask = 4
	box.health_component_path = NodePath("../Health")
	box.hurtbox_owner_path = NodePath("..")
	var box_shape := CollisionShape2D.new()
	box_shape.shape = shape.shape
	box.add_child(box_shape)
	player.add_child(box)
	world.add_child(player)
	fish = FISH.instantiate()
	fish.position = Vector2(500,500)
	fish.start_facing = 1
	world.add_child(fish)
	await frames(5)
	var origin := fish.position
	var bob_min := INF
	var bob_max := -INF
	for frame in 90:
		await frames(1)
		bob_min = minf(bob_min, fish.fish_visual.position.y)
		bob_max = maxf(bob_max, fish.fish_visual.position.y)
	check(fish.position.distance_to(origin) < 0.1, "Still fish must not patrol")
	check(bob_max - bob_min > 0.5 and maxf(absf(bob_min), absf(bob_max)) <= 3.01, "Living hover is visible but bounded to three pixels")
	check(fish.fish_visual.animator.current_animation == "life/hover", "Living idle loops")
	var hover: Animation = fish.fish_visual.animator.get_animation(&"life/hover")
	var glide: Animation = fish.fish_visual.animator.get_animation(&"life/dash_glide")
	for clip in [hover, glide]:
		check(clip.loop_mode == Animation.LOOP_LINEAR, "Living motion loops seamlessly")
		var flexible_bones := 0
		for track in clip.get_track_count():
			if clip.track_get_type(track) != Animation.TYPE_ROTATION_3D:
				continue
			var first: Quaternion = clip.rotation_track_interpolate(track, 0.0)
			var last: Quaternion = clip.rotation_track_interpolate(track, clip.length)
			check(absf(first.dot(last)) > 0.99999, "Tail wave loop endpoints match")
			if first.angle_to(clip.rotation_track_interpolate(track, clip.length * 0.25)) > deg_to_rad(0.1):
				flexible_bones += 1
		check(flexible_bones >= 4, "Idle and glide animate the body/head/tail chain, not just the image")
	check(fish._footprint_fits(fish.position), "Idle must stay in water")
	# Inside awareness but outside the deliberately widened dash trigger.
	player.position = fish.position + Vector2(950,0)
	await frames(12)
	check(fish.position.distance_to(origin) < 0.1, "Detected target must not cause swimming")
	check(fish.fish_visual.tell_intensity > 0.0, "Awareness lights the eye")
	check(fish.fish_visual.animator.current_animation == "life/hover", "Awareness retains the living idle")
	check(fish.fish_visual.eye_materials.size() == 2, "Both skinned eyes have tell materials")
	var fish_image := fish.fish_visual.get_node("FishImage") as Sprite2D
	check(fish_image.scale.x >= 0.6, "Fish visual is large enough to read in combat")
	check(fish_image.material is ShaderMaterial, "Fish silhouette uses an outline material")
	check((fish.get_node("CollisionShape2D") as CollisionShape2D).shape.radius >= 58.0, "Body collision matches the larger fish")
	print("PASS still idle / stationary awareness / eye materials")
	fish.reset_for_save_point()
	player.position = fish.position + Vector2(260,0)
	await frames(8)
	check(fish.attack_phase == &"windup", "Player triggers curl")
	check(not fish.attack_hitbox.active, "Windup cannot hurt")
	check(player_health.current_health == 100, "Windup is harmless")
	var direction: Vector2 = fish.dash_direction
	player.position.y += 100
	await frames(8)
	check(fish.dash_direction.is_equal_approx(direction), "Draw stance locks aim")
	player.position.y -= 100
	var saw_flash := false
	var saw_glide := false
	var dash_start := fish.position
	for index in range(180):
		await frames(1)
		if fish.attack_phase == &"dash" and fish.fish_visual.animator.current_animation == "life/dash_glide":
			saw_glide = true
		if fish.attack_phase == &"windup" and fish.fish_visual.tell_intensity > 0.9:
			saw_flash = true
			check(not fish.attack_hitbox.active, "Prestrike flash must be harmless")
		if fish.attack_phase == &"recover":
			break
	check(saw_flash, "Final windup must flash before striking")
	check(saw_glide, "Long committed dash keeps the tail moving after blade release")
	check(player_health.current_health == 82, "One 18-damage hit per dash")
	check(not fish.attack_hitbox.active, "Recovery disables blade")
	check(fish.position.distance_to(dash_start) > 600.0, "Committed dash travels until the lake boundary")
	check(fish.dash_blocked, "Lake boundary ends the committed dash")
	player.position = fish.position + Vector2(-260,0)
	fish.target = player
	var saw_recovery_shake := false
	for index in range(26):
		await frames(1)
		saw_recovery_shake = saw_recovery_shake or absf(fish.fish_visual.rotation) > deg_to_rad(2.0)
	check(saw_recovery_shake, "Recovery visibly shakes off the wall impact")
	check(fish.facing == -1, "Late recovery reacquires and faces the player")
	check(fish.fish_visual.tell_intensity > 0.0, "Reacquiring the player restores the awareness tell")
	print("PASS curl / wall-terminated dash / head shake / player reacquisition")

	# An actual received melee hit must interrupt an active dash and retain recoil.
	fish.reset_for_save_point()
	player.position = fish.position + Vector2(260,0)
	await frames(4)
	fish.target = player
	fish.state_machine.transition_to(&"Attack")
	await frames(48)
	check(fish.attack_phase == &"dash", "Reach dash phase before interrupt")
	var damage := DamageData.new()
	damage.amount = 10
	damage.source = player
	damage.hit_pause = 0
	damage.hitstun = 0.12
	damage.use_receiver_screen_shake_fallback = false
	damage.knockback = Vector2(-120,0)
	check(fish.hurtbox.receive_hit(damage), "Fish accepts melee damage")
	check(fish.state_machine.current_state_name == &"Hurt", "Damage interrupts attack")
	check(not fish.attack_hitbox.active, "Hurt cancels blade immediately")
	check(fish.velocity.x < 0, "Hurt preserves knockback")
	check(fish.fish_visual.animator.current_animation == "hurt", "Hurt animation plays")
	check(fish.fish_visual.position.is_equal_approx(Vector2.ZERO), "Hover immediately clears on hurt")
	await frames(28)
	check(fish.state_machine.current_state_name != &"Hurt", "Hurt recovers")
	print("PASS damage / interrupt / hurt animation / recoil")

	# Direct movement checks include high-speed crossing of narrow dry pockets.
	fish.state_machine.set_physics_process(false)
	fish.set_physics_process(false)
	fish.end_attack()
	fish.position = Vector2(500,500)
	var pocket := WATER.instantiate()
	pocket.air_pocket = true
	pocket.points = PackedVector2Array([Vector2(750,350),Vector2(756,350),Vector2(756,650),Vector2(750,650)])
	world.add_child(pocket)
	await frames(3)
	check(not fish._move_in_water(Vector2(700,0), true), "Dash cannot cross a six-pixel air pocket")
	check(fish.position.x <= 650, "Entire fish stops before pocket")
	player.position = Vector2(900,500)
	check(not fish._can_target_player(player), "No attack through dry pocket")
	fish.position = Vector2(500,500)
	check(not fish._move_in_water(Vector2(0,-900)), "Cannot leave water surface")
	check(fish.position.y >= 100, "Surface preserves clearance")
	print("PASS narrow air pocket / shoreline / target rejection")

	pocket.queue_free()
	var wall := StaticBody2D.new()
	wall.position = Vector2(800,500)
	var wall_shape := CollisionShape2D.new()
	wall_shape.shape = RectangleShape2D.new()
	wall_shape.shape.size = Vector2(16,600)
	wall.add_child(wall_shape)
	world.add_child(wall)
	fish.position = Vector2(500,500)
	await frames(3)
	check(not fish._move_in_water(Vector2(800,0)), "Dash stops at solid wall")
	check(fish.position.x < 760, "Body remains before wall")
	check(not fish._can_target_player(player), "No target acquisition through wall")
	print("PASS terrain collision / occlusion")

	var animator: AnimationPlayer = fish.fish_visual.animator
	for clip in [&"still", &"draw_curl", &"dash", &"recover", &"hurt"]:
		check(animator.has_animation(clip), "Missing clip " + clip)
		check(animator.get_animation(clip).get_track_count() > 0, "Empty clip " + clip)
	damage.amount = 1000
	fish.health_component.configure(100)
	fish.hurtbox.receive_hit(damage)
	await frames(2)
	check(fish.is_dead, "Lethal hit kills fish")
	check(not fish.attack_hitbox.active, "Death cancels blade")
	await frames(2)
	check(not fish.fish_visual.animator.is_playing(), "Death stops living motion")
	await frames(40)
	fish.reset_for_save_point()
	check(not fish.is_dead and fish.visible and fish.health_component.current_health == 100, "Save point restores fish")
	check(fish.position.is_equal_approx(fish.home_position), "Respawn returns home")
	check(fish.fish_visual.animator.current_animation == "life/hover" and fish.fish_visual.animator.is_playing(), "Save point restarts living idle")
	print("PASS all clips / death / save-point reset")
	print("TIDE_DUELIST_ALL_CHECKS_PASS")
	get_tree().quit()
