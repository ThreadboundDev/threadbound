extends Node

const ROOM := preload("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_bulb_choice_room.tscn")
const BULB := preload("res://Src/Environment/Greybox/greybox_bumper.tscn")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func fresh_bulb() -> GreyboxBumper2D:
	var bulb := BULB.instantiate() as GreyboxBumper2D
	bulb.position = Vector2(-8000, -8000)
	bulb.regeneration_delay = 0.0
	add_child(bulb)
	return bulb

func _ready() -> void:
	var room := ROOM.instantiate()
	add_child(room)
	var player = room.get_node("Player")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().physics_frame
	await get_tree().physics_frame
	var floor_shape = room.get_node("Geometry/RecoveryFloor/CollisionShape2D").shape
	check(floor_shape.size == Vector2(5120, 128), "Room block instances must keep independent collision sizes.")
	check(room.get_node("Bulbs/DashChoice/ContactReceiver/CollisionShape2D").shape.size == Vector2(128, 128), "Bulb sizes must stay independent.")
	check(room.get_node("Bulbs/RemoteChoice/ContactReceiver/CollisionShape2D").shape.size == Vector2(160, 160), "Large remote bulb must retain its size.")
	for direction in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
		var bulb := fresh_bulb()
		var damage: DamageData = player.call("_build_attack_damage")
		check(damage.is_melee, "Player melee attacks must identify their delivery type.")
		damage.source = player
		damage.knockback = direction * 250.0
		bulb.get_node("HitReceiver").receive_hit(damage)
		await get_tree().process_frame
		check(bulb.is_broken(), "Melee must pop bulb.")
		check(player.velocity.normalized().is_equal_approx(-direction), "Melee recoil must oppose strike direction.")
		check(is_equal_approx(player.velocity.length(), player.current_boots.base_jump_force * sqrt(2.0)), "Melee launch strength must use authored jump height.")
		bulb.queue_free()
	for direction in [-1.0, 1.0]:
		var bulb := fresh_bulb()
		player.current_chest.is_dashing = true
		player.velocity = Vector2(direction * 1150.0, 0.0)
		var original_position: Vector2 = player.position
		bulb.call("_on_body_entered", player)
		await get_tree().process_frame
		check(bulb.is_broken(), "Dash must pop bulb.")
		check(is_equal_approx(player.velocity.x, direction * 1380.0), "Dash must retain direction and add speed.")
		check(is_equal_approx(player.velocity.y, -1000.0), "Horizontal dash must gain height.")
		check(player.position == original_position, "Dash pop must never teleport the player across geometry.")
		check(not player.is_dash_active(), "Dash controller must release ownership after bulb boost.")
		check(player._traversal_launch_control_lock_timer > 0, "Movement input must not erase boost immediately.")
		bulb.queue_free()
	var ranged := fresh_bulb()
	var remote_damage := DamageData.new()
	remote_damage.source = player
	remote_damage.knockback = Vector2.RIGHT * 500.0
	player.velocity = Vector2(317, -193)
	ranged.get_node("HitReceiver").receive_hit(remote_damage)
	await get_tree().process_frame
	check(ranged.is_broken(), "Ranged damage must pop bulb even when player owns the hit.")
	check(player.velocity == Vector2(317, -193), "Ranged pop must preserve player velocity.")
	var grapple := fresh_bulb()
	check(grapple.get_node("GrappleTarget").collision_layer == 4, "Grapple must be able to detect bulb.")
	check(player.current_gloves.call("_notify_grapple_collider", grapple.get_node("GrappleTarget")), "Existing grapple dispatch must consume bulb contact.")
	await get_tree().process_frame
	check(grapple.is_broken(), "Grapple must pop bulb.")
	check(player.velocity == Vector2(317, -193), "Grapple pop must preserve velocity.")
	check(not grapple.activate_from_grapple(player), "Spent bulb must reject duplicate activation.")
	var contact := fresh_bulb()
	player.global_position = contact.global_position
	player.velocity = Vector2(2000, 0)
	contact.call("_on_body_entered", player)
	check(not contact.is_broken(), "High speed alone must never activate a bulb.")
	check(player.global_position != contact.global_position, "Ordinary overlap must gently eject.")
	var regenerating := fresh_bulb()
	regenerating.regeneration_delay = 0.05
	regenerating.activate_from_grapple(player)
	await get_tree().create_timer(0.1).timeout
	await get_tree().physics_frame
	check(not regenerating.is_broken(), "Bulb must regenerate for return routes.")
	check(not regenerating.get_node("GrappleTarget/CollisionShape2D").disabled, "Regeneration must restore grapple target.")
	# Exercise real movement and Area2D detection through the first room gap.
	player.global_position = Vector2(608, 512 - player.call("_get_player_collision_bottom_offset") - 1)
	player.velocity = Vector2.ZERO
	player._traversal_launch_control_lock_timer = 0.0
	player._traversal_launch_control_recovery_timer = 0.0
	player.process_mode = Node.PROCESS_MODE_INHERIT
	for frame in 12:
		await get_tree().physics_frame
	player.last_direction = 1
	player.current_action_points = 4
	check(player.current_chest.call("_start_dash"), "Room dash must start from the deck.")
	Input.action_press("move_right")
	var landed_upper := false
	for frame in 100:
		await get_tree().physics_frame
		if player.is_on_floor() and player.position.x > 1088 and player.position.x < 1728 and player.position.y < 384:
			landed_upper = true
			break
	Input.action_release("move_right")
	check(room.get_node("Bulbs/DashChoice").is_broken(), "Live dash must trigger bulb through physics overlap.")
	check(landed_upper, "First dash route must reach the raised landing without holding Jump.")
	print("First route end: ", player.position, " upper landing: ", landed_upper)
	player.position = Vector2(1744, 180)
	player.velocity = Vector2.ZERO
	player._traversal_launch_control_lock_timer = 0.0
	player._traversal_launch_control_recovery_timer = 0.0
	await get_tree().physics_frame
	player.call("_begin_air_double_attack", Vector2.DOWN)
	var landed_perch := false
	for frame in 120:
		await get_tree().physics_frame
		if room.get_node("Bulbs/DownAttackChoice").is_broken() and player.position.x < 1930:
			Input.action_press("move_right")
		else:
			Input.action_release("move_right")
		if player.is_on_floor() and player.position.x > 1792 and player.position.y < 136:
			landed_perch = true
			break
	Input.action_release("move_right")
	check(landed_perch, "Live downward attack must pop bulb and reach recoil perch.")
	print("Recoil route end: ", player.position, " upper perch: ", landed_perch)
	player.position = Vector2(2110, 136 - player.call("_get_player_collision_bottom_offset") - 1)
	player.velocity = Vector2.ZERO
	for frame in 12:
		await get_tree().physics_frame
	player.current_action_points = 4
	player.last_direction = 1
	check(player.current_chest.call("_start_dash"), "Upper chain dash must start.")
	Input.action_press("move_right")
	var landed_chain := false
	for frame in 110:
		await get_tree().physics_frame
		if player.is_on_floor() and player.position.x > 2624 and player.position.y < 104:
			landed_chain = true
			break
	Input.action_release("move_right")
	check(landed_chain, "Live dash must reach upper chain landing.")
	print("Chain route end: ", player.position, " upper landing: ", landed_chain)
	print("BULB CHOICES: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	get_tree().quit(0 if failures == 0 else 1)
