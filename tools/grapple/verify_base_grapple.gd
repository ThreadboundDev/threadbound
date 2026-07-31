extends Node

const BASE_GLOVES_SCENE := preload("res://Src/Equipment/base_gloves.tscn")
const BLUE_GLOVES_SCENE := preload("res://Src/Equipment/blue_gloves.tscn")
const RED_GLOVES_SCENE := preload("res://Src/Equipment/red_gloves.tscn")
const PLAYER_SCENE := preload("res://Src/Characters/Player/player.tscn")
const GRAPPLE_EQUIPMENT_SCENES := [
	{"label": "base", "scene": BASE_GLOVES_SCENE},
	{"label": "blue", "scene": preload("res://Src/Equipment/blue_gloves.tscn")},
	{"label": "red", "scene": preload("res://Src/Equipment/red_gloves.tscn")},
	{"label": "yellow", "scene": preload("res://Src/Equipment/yellow_gloves.tscn")},
]

var failures: Array[String] = []

func _ready() -> void:
	var player := _create_player()
	add_child(player)
	if not is_equal_approx(
		float(player.grapple_strike_visual_scale_multiplier),
		0.82
	):
		failures.append(
			"Grapple strike body animation is not normalized to the approved 0.82 scale."
		)

	for equipment in GRAPPLE_EQUIPMENT_SCENES:
		_verify_serialized_grapple_visibility(
			equipment["scene"] as PackedScene,
			String(equipment["label"])
		)

	var gloves := BASE_GLOVES_SCENE.instantiate() as BaseGloves
	player.add_child(gloves)
	gloves.player = player
	gloves.on_equipped()
	if gloves.forces_dash_animation():
		failures.append("Idle grapple gloves forced the player into a dash animation.")
	if gloves.get_forced_dash_direction() != Vector2.ZERO:
		failures.append("Idle grapple gloves retained a stale forced dash direction.")
	gloves.grapple_strike_launch_range_ratio = 0.0
	if not is_equal_approx(
		gloves.get_grapple_strike_range_damage_multiplier(),
		1.0
	):
		failures.append("A close grapple strike received a range damage bonus.")
	gloves.grapple_strike_launch_range_ratio = 1.0
	if not is_equal_approx(
		gloves.get_grapple_strike_range_damage_multiplier(),
		1.25
	):
		failures.append("A full-range grapple strike did not receive its 1.25 multiplier.")
	gloves.grapple_strike_launch_range_ratio = 0.0
	if gloves.active_grapple_root.visible:
		failures.append("Active grapple root became visible during equipment startup.")
	if not gloves.active_rope_line.points.is_empty():
		failures.append("Active grapple rope retained stale points during equipment startup.")
	gloves.active_grapple_root.visible = true
	gloves.active_needle_sprite.visible = true
	gloves.grapple_tip_position = Vector2(INF, 0.0)
	var invalid_visuals_accepted := bool(gloves.call("_update_active_grapple_visuals"))
	if (
		invalid_visuals_accepted
		or gloves.active_grapple_root.visible
		or gloves.active_needle_sprite.visible
		or not gloves.active_rope_line.points.is_empty()
	):
		failures.append("Invalid grapple endpoints exposed startup visuals.")

	var ignored_interaction_area := _create_area(Vector2(70.0, 0.0), 2)
	add_child(ignored_interaction_area)
	var wall := _create_body(Vector2(120.0, 0.0), 1)
	add_child(wall)
	await get_tree().physics_frame

	_prepare_active_shot(gloves)
	var launch_origin := gloves.get_grapple_origin_global_position()
	gloves.grapple_tip_position = launch_origin + Vector2(24.0, 0.0)
	var preextended_rope: Array[Vector2] = [
		launch_origin,
		launch_origin + Vector2(gloves.active_rope_total_length, 0.0),
	]
	gloves.active_rope_points = preextended_rope
	gloves.call("_update_active_grapple_visuals")
	if gloves.active_rope_line.points.size() != 2:
		failures.append("A firing grapple exposed its pre-extended simulation chain.")
	elif not is_equal_approx(
		gloves.active_rope_line.points[0].distance_to(gloves.active_rope_line.points[1]),
		24.0
	):
		failures.append("A firing grapple line extended beyond the needle's travelled distance.")

	_prepare_active_shot(gloves)
	gloves.call("_check_grapple_collision", Vector2.ZERO, Vector2(160.0, 0.0))
	if gloves.grapple_state != BaseGloves.GrappleState.ATTACHED:
		failures.append("Hookshot did not attach after crossing player/interaction areas.")
	elif gloves.grapple_target != wall:
		failures.append("Hookshot attached to an invisible area instead of solid environment geometry.")

	var upward_clearance: float = gloves.call("_get_hookshot_surface_clearance", Vector2.UP)
	if upward_clearance < 65.0:
		failures.append(
			"Upward surface clearance %.2f does not clear the player's full collision shape." %
			upward_clearance
		)

	var tile_layer := TileMapLayer.new()
	if not gloves.call("_is_valid_hookshot_collider", tile_layer):
		failures.append("TileMapLayer collision was not recognized as valid level geometry.")
	tile_layer.free()

	var enemy := Node2D.new()
	enemy.add_to_group("enemies")
	var enemy_hurtbox := Area2D.new()
	enemy.add_child(enemy_hurtbox)
	if not gloves.call("_is_valid_hookshot_collider", enemy_hurtbox):
		failures.append("Enemy collision area was not recognized as a valid hookshot target.")
	enemy.free()

	gloves.call("_reset_active_grapple_visuals")
	gloves.grapple_state = BaseGloves.GrappleState.ATTACHED
	gloves.grapple_attached = true
	gloves.grapple_attach_position = Vector2(200.0, 0.0)
	gloves.grapple_collision_normal = Vector2.ZERO
	gloves.grapple_target = null
	for _frame in range(12):
		gloves.call("_apply_hookshot_pull", 0.02)
	if gloves.grapple_state != BaseGloves.GrappleState.RETRACTING:
		failures.append("A blocked hookshot did not release after its no-progress timeout.")

	await _verify_enemy_grapple_strike(player, gloves)

	player.queue_free()
	ignored_interaction_area.queue_free()
	wall.queue_free()
	await get_tree().process_frame

	await _verify_player_grapple_strike_integration()
	await get_tree().process_frame
	await _verify_red_grapple_damage_separation()
	await get_tree().process_frame

	if failures.is_empty():
		print(
			"Base grapple verification passed: hidden startup visuals, travelled-distance "
			+ "firing line, self/trigger filtering, collider-sized surface clearance, "
			+ "stalled-pull release, and full player grapple-strike integration are valid."
		)
		get_tree().quit(0)
		return

	for failure in failures:
		push_error(failure)
	get_tree().quit(1)

func _verify_serialized_grapple_visibility(scene: PackedScene, label: String) -> void:
	var equipment := scene.instantiate()
	var active_root := equipment.get_node("Equipment/ActiveGrappleRoot") as Node2D
	var active_needle := equipment.get_node(
		"Equipment/ActiveGrappleRoot/ActiveNeedleSprite"
	) as Sprite2D
	if active_root.visible:
		failures.append("%s grapple root is visible before initialization." % label)
	if active_needle.visible:
		failures.append("%s grapple needle is visible before initialization." % label)
	if label in ["blue", "yellow", "red"]:
		if int(equipment.get("grapple_collision_mask")) != 3:
			failures.append(
				"%s grapple cannot target both world geometry and enemy hurtboxes." % label
			)
	if label == "yellow":
		equipment.set("_snap_pending", true)
		equipment.set("_snap_platform_phase_requested", true)
		equipment.call("_on_enemy_grapple_strike_started")
		if (
			bool(equipment.get("_snap_pending"))
			or bool(equipment.get("_snap_platform_phase_requested"))
		):
			failures.append(
				"Yellow enemy grapple strike retained its teleport/snap branch."
			)
	if label == "red":
		var target_owner := Node2D.new()
		var target_health := HealthComponent.new()
		var target_hurtbox := HurtboxComponent.new()
		target_health.max_health = 100
		target_health.invincible_after_hit = 0.0
		target_owner.add_child(target_health)
		target_owner.add_child(target_hurtbox)
		add_child(target_owner)
		target_hurtbox.health_component = target_health
		target_hurtbox.hurtbox_owner = target_owner
		equipment.set("_released_charge_curve", 0.0)
		equipment.call("_apply_red_grapple_damage", target_hurtbox)
		if target_health.current_health != 88:
			failures.append(
				"Red charged attach damage is not preserved as its separate setup hit."
			)
		target_owner.free()
	equipment.free()

func _verify_enemy_grapple_strike(
	player: CharacterBody2D,
	gloves: BaseGloves
) -> void:
	var enemy := Node2D.new()
	enemy.name = "GrappleStrikeTarget"
	enemy.position = Vector2(300.0, 0.0)
	enemy.add_to_group("enemies")
	add_child(enemy)

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100
	health.invincible_after_hit = 0.0
	enemy.add_child(health)

	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 4
	hurtbox.health_component_path = NodePath("../HealthComponent")
	hurtbox.hurtbox_owner_path = NodePath("..")
	var enemy_shape := CollisionShape2D.new()
	enemy_shape.name = "CollisionShape2D"
	enemy_shape.position = Vector2(0.0, -50.0)
	var enemy_rectangle := RectangleShape2D.new()
	enemy_rectangle.size = Vector2(100.0, 100.0)
	enemy_shape.shape = enemy_rectangle
	hurtbox.add_child(enemy_shape)
	enemy.add_child(hurtbox)
	await get_tree().process_frame

	gloves.call("_reset_active_grapple_visuals")
	player.global_position = Vector2.ZERO
	player.velocity = Vector2.ZERO
	gloves.grapple_state = BaseGloves.GrappleState.ATTACHED
	gloves.grapple_attached = true
	gloves.grapple_target = hurtbox
	gloves.grapple_target_local_position = hurtbox.to_local(enemy_shape.global_position)
	gloves.grapple_attach_position = enemy_shape.global_position
	gloves.grapple_tip_position = gloves.grapple_attach_position
	gloves.hookshot_enemy_hurtbox = hurtbox

	if not gloves.has_enemy_grapple_target():
		failures.append("An attached enemy hurtbox was not exposed as a grapple-combat target.")
		enemy.queue_free()
		return

	var desired_position := gloves.call("_get_enemy_grapple_standoff_position") as Vector2
	var target_center := enemy_shape.global_position
	var combined_clearance := gloves.get_enemy_grapple_safe_center_distance()
	var player_center_offset := gloves.call("_get_player_collision_center_offset") as Vector2
	var desired_center := desired_position + player_center_offset
	if desired_center.distance_to(target_center) + 0.5 < combined_clearance:
		failures.append("Enemy grapple stand-off overlaps the combined player/enemy shapes.")

	if not gloves.try_start_grapple_strike():
		failures.append("Attack could not arm a valid enemy grapple strike.")
		enemy.queue_free()
		return
	if not gloves.is_grapple_strike_contact_guard_active():
		failures.append("Grapple strike did not expose its contact-only approach guard.")

	player.global_position = desired_position
	var accepted := gloves.resolve_grapple_strike()
	if not accepted:
		failures.append("A clear, in-range enemy grapple strike was not accepted.")
	if health.current_health != 100 - gloves.grapple_strike_damage:
		failures.append(
			"Enemy grapple strike did not apply exactly one dedicated damage event."
		)
	if gloves.grapple_state != BaseGloves.GrappleState.RETRACTING:
		failures.append("Confirmed enemy grapple strike did not retract the grapple.")
	if player.velocity.x >= 0.0 or player.velocity.y >= 0.0:
		failures.append("Confirmed enemy grapple strike did not recoil the player away/upward.")

	enemy.queue_free()

func _verify_player_grapple_strike_integration() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect_integration(player != null, "Player scene did not instantiate for grapple integration.")
	if not player:
		return

	add_child(player)
	await get_tree().process_frame
	player.set_physics_process(false)
	player.equip_gloves(BLUE_GLOVES_SCENE)
	var gloves := player.current_gloves as BlueGloves
	_expect_integration(gloves != null, "Player could not equip Blue gloves for grapple integration.")
	if not gloves:
		player.queue_free()
		return

	var target_data := _create_grapple_strike_target(Vector2(-900.0, 0.0))
	var enemy := target_data["enemy"] as Node2D
	var health := target_data["health"] as HealthComponent
	var hurtbox := target_data["hurtbox"] as HurtboxComponent
	var enemy_shape := target_data["shape"] as CollisionShape2D
	add_child(enemy)
	await get_tree().process_frame

	player.global_position = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.last_direction = 1
	player.attack_cooldown_timer = 0.0
	player.is_attacking = false
	_attach_gloves_to_enemy(gloves, hurtbox, enemy_shape)
	gloves.grapple_strike_launch_range_ratio = 1.0
	player.set("_flow_state_active", true)

	player.start_attack()
	_expect_integration(
		bool(player.current_attack_uses_grapple_strike),
		"Attack did not dispatch into the dedicated grapple strike."
	)
	_expect_integration(
		gloves.is_grapple_strike_active(),
		"Player grapple dispatch did not arm the glove strike state."
	)
	_expect_integration(
		player.last_direction == -1 and player.player_animation.flip_h,
		"Grapple strike did not face an enemy behind the player."
	)
	_expect_integration(
		player.should_ignore_enemy_contact(enemy),
		"Grapple approach did not enable contact-only protection."
	)
	var authored_attack := DamageData.new()
	_expect_integration(
		not player.should_ignore_health_damage(authored_attack),
		"Grapple contact protection incorrectly ignored authored attack damage."
	)

	var health_before := health.current_health
	var simulation_delta := 1.0 / 60.0
	for _step in range(70):
		player.update_combat_timers(simulation_delta)
		gloves.apply_grapple_strike_velocity(simulation_delta)
		player.global_position += player.velocity * simulation_delta
		if health.current_health < health_before:
			break

	var expected_full_range_flow_damage := roundi(
		float(gloves.grapple_strike_damage)
		* gloves.grapple_strike_max_range_damage_multiplier
		* player.get_momentum_attack_damage_multiplier()
	)
	_expect_integration(
		health.current_health == health_before - expected_full_range_flow_damage,
		"Full-range Flow grapple strike did not combine range and momentum damage."
	)
	_expect_integration(
		player.current_grapple_strike_landed and player.is_attacking,
		"Grapple impact did not enter its own recovery window."
	)
	_expect_integration(
		gloves.grapple_state == BaseGloves.GrappleState.RETRACTING,
		"Full player grapple strike did not retract after impact."
	)
	_expect_integration(
		player.velocity.x > 0.0 and player.velocity.y < 0.0,
		"Full player grapple strike did not preserve away/up recoil."
	)
	_expect_integration(
		not player.should_ignore_enemy_contact(enemy),
		"Contact-only protection remained active after grapple impact."
	)

	var health_after_impact := health.current_health
	gloves.resolve_grapple_strike()
	_expect_integration(
		health.current_health == health_after_impact,
		"A second grapple resolve changed health after the confirmed strike."
	)

	var impact_time: float = float(player.current_grapple_strike_impact_time)
	var recovery: float = (
		player.player_stats.attack_recovery
		/ maxf(0.1, player.get_momentum_attack_speed_multiplier())
	)
	player.update_combat_timers(maxf(0.0, recovery - 0.01))
	_expect_integration(
		player.is_attacking,
		"Grapple strike recovery ended before impact-relative recovery elapsed."
	)
	player.update_combat_timers(0.02)
	_expect_integration(
		not player.is_attacking
		and impact_time >= 0.0,
		"Grapple strike did not end after its impact-relative recovery."
	)

	_attach_gloves_to_enemy(gloves, hurtbox, enemy_shape)
	gloves.mark_enemy_grapple_ready()
	var incoming := DamageData.new()
	incoming.amount = 1
	incoming.source = enemy
	incoming.knockback = Vector2(240.0, -90.0)
	incoming.hit_pause = 0.0
	incoming.use_receiver_screen_shake_fallback = false
	player.hurtbox.receive_hit(incoming)
	gloves.process_passive(simulation_delta)
	gloves.apply_grapple_velocity(simulation_delta)
	_expect_integration(
		gloves.grapple_state == BaseGloves.GrappleState.RETRACTING,
		"Authored damage did not cancel an enemy grapple hold."
	)
	_expect_integration(
		player.velocity.is_equal_approx(incoming.knockback),
		"Enemy grapple cleanup overwrote authored hurt knockback."
	)
	_expect_integration(
		is_zero_approx(float(gloves.get("_release_jump_buffer_timer"))),
		"Blue combat-forced release retained its manual swing jump buffer."
	)

	player.unequip_gloves()
	player.queue_free()
	enemy.queue_free()

func _verify_red_grapple_damage_separation() -> void:
	var player := PLAYER_SCENE.instantiate()
	_expect_integration(
		player != null,
		"Player scene did not instantiate for Red grapple separation."
	)
	if not player:
		return

	add_child(player)
	await get_tree().process_frame
	player.set_physics_process(false)
	player.equip_gloves(RED_GLOVES_SCENE)
	var gloves := player.current_gloves as RedGloves
	_expect_integration(
		gloves != null,
		"Player could not equip Red gloves for grapple separation."
	)
	if not gloves:
		player.queue_free()
		return

	var target_data := _create_grapple_strike_target(Vector2(300.0, 0.0))
	var enemy := target_data["enemy"] as Node2D
	var health := target_data["health"] as HealthComponent
	var hurtbox := target_data["hurtbox"] as HurtboxComponent
	var enemy_shape := target_data["shape"] as CollisionShape2D
	add_child(enemy)
	await get_tree().process_frame

	var damage_events := {"count": 0}
	health.damaged.connect(
		func(_damage: DamageData) -> void:
			damage_events["count"] = int(damage_events["count"]) + 1
	)
	gloves.set("_released_charge_curve", 0.0)
	gloves.grapple_attach_position = enemy_shape.global_position
	gloves.call("_apply_red_grapple_damage", hurtbox)
	_expect_integration(
		health.current_health == 88 and int(damage_events["count"]) == 1,
		"Red charged attach applies exactly one separate 12-damage setup hit."
	)

	player.global_position = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.attack_cooldown_timer = 0.0
	player.is_attacking = false
	_attach_gloves_to_enemy(gloves, hurtbox, enemy_shape)
	player.global_position = gloves.call(
		"_get_enemy_grapple_standoff_position"
	) as Vector2
	player.start_attack()
	var red_strike_windup: float = (
		float(player.player_stats.attack_windup)
		/ maxf(0.1, player.get_momentum_attack_speed_multiplier())
	)
	player.update_combat_timers(red_strike_windup + 0.01)
	_expect_integration(
		health.current_health == 58 and int(damage_events["count"]) == 2,
		"Red setup plus grapple strike produce exactly two distinct damage events."
	)

	var health_after_strike := health.current_health
	gloves.resolve_grapple_strike()
	_expect_integration(
		health.current_health == health_after_strike
		and int(damage_events["count"]) == 2,
		"Red grapple strike cannot double-resolve after its confirmed impact."
	)

	player.unequip_gloves()
	player.queue_free()
	enemy.queue_free()

func _create_grapple_strike_target(world_position: Vector2) -> Dictionary:
	var enemy := Node2D.new()
	enemy.name = "IntegratedGrappleStrikeTarget"
	enemy.position = world_position
	enemy.add_to_group("enemies")

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100
	health.invincible_after_hit = 0.0
	enemy.add_child(health)

	var hurtbox := HurtboxComponent.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 4
	hurtbox.health_component_path = NodePath("../HealthComponent")
	hurtbox.hurtbox_owner_path = NodePath("..")
	var enemy_shape := CollisionShape2D.new()
	enemy_shape.name = "CollisionShape2D"
	enemy_shape.position = Vector2(0.0, -50.0)
	var enemy_rectangle := RectangleShape2D.new()
	enemy_rectangle.size = Vector2(100.0, 100.0)
	enemy_shape.shape = enemy_rectangle
	hurtbox.add_child(enemy_shape)
	enemy.add_child(hurtbox)

	return {
		"enemy": enemy,
		"health": health,
		"hurtbox": hurtbox,
		"shape": enemy_shape,
	}

func _attach_gloves_to_enemy(
	gloves: BaseGloves,
	hurtbox: HurtboxComponent,
	enemy_shape: CollisionShape2D
) -> void:
	gloves.call("_reset_active_grapple_visuals")
	gloves.grapple_state = BaseGloves.GrappleState.ATTACHED
	gloves.grapple_attached = true
	gloves.grapple_target = hurtbox
	gloves.grapple_target_local_position = hurtbox.to_local(enemy_shape.global_position)
	gloves.grapple_attach_position = enemy_shape.global_position
	gloves.grapple_tip_position = gloves.grapple_attach_position
	gloves.hookshot_enemy_hurtbox = hurtbox

func _expect_integration(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _create_player() -> CharacterBody2D:
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group("player")

	var body_shape := CollisionShape2D.new()
	body_shape.name = "CollisionShape2D"
	body_shape.position = Vector2(0.0, 6.0)
	var body_rectangle := RectangleShape2D.new()
	body_rectangle.size = Vector2(37.0, 126.0)
	body_shape.shape = body_rectangle
	player.add_child(body_shape)

	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.position = Vector2(40.0, 0.0)
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 0
	var hurtbox_shape := CollisionShape2D.new()
	var hurtbox_rectangle := RectangleShape2D.new()
	hurtbox_rectangle.size = Vector2(20.0, 40.0)
	hurtbox_shape.shape = hurtbox_rectangle
	hurtbox.add_child(hurtbox_shape)
	player.add_child(hurtbox)
	return player

func _create_area(position: Vector2, layer: int) -> Area2D:
	var area := Area2D.new()
	area.position = position
	area.collision_layer = layer
	area.collision_mask = 0
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20.0, 40.0)
	collision_shape.shape = rectangle
	area.add_child(collision_shape)
	return area

func _create_body(position: Vector2, layer: int) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = position
	body.collision_layer = layer
	body.collision_mask = 0
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20.0, 80.0)
	collision_shape.shape = rectangle
	body.add_child(collision_shape)
	return body

func _prepare_active_shot(gloves: BaseGloves) -> void:
	gloves.call("_reset_grapple_raycast_exceptions")
	gloves.grapple_state = BaseGloves.GrappleState.FIRING
	gloves.grapple_attachment_state = BaseGloves.GrappleAttachmentState.ACTIVE
	gloves.grapple_attached = false
