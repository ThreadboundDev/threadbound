extends SceneTree
var checks: Array[Dictionary] = []
var world
var actor
var enemies: Array

func check(label: String, passed: bool, detail = null) -> void:
	checks.append({"check": label, "passed": passed, "detail": detail})
	print("PASS " if passed else "FAIL ", label, " ", detail)

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func fixture(point := Vector3(0, 0.2, 4)) -> void:
	for action in ["attack", "block", "grapple", "jump", "left", "right", "forward", "back", "dash", "special"]:
		Input.action_release(action)
	world.reset_playtest()
	actor.global_position = point
	actor.combat.invulnerable = 0
	for enemy in enemies:
		enemy.ai_enabled = false
		enemy.global_position = enemy.home
	await frames(30)

func _initialize() -> void:
	create_timer(90).timeout.connect(func(): push_error("Playtest verification timed out"); quit(99))
	call_deferred("run")

func run() -> void:
	world = load("res://scenes/workshop_study.tscn").instantiate()
	root.add_child(world)
	actor = world.actor
	enemies = get_nodes_in_group("study_enemies")
	for enemy in enemies: enemy.ai_enabled = false
	await frames(40)
	check("Four field enemies plus distinct boss", enemies.size() == 5 and world.boss.kind == "boss")
	check("Six usable thread anchors", get_nodes_in_group("study_anchors").size() == 6)
	check("AP starts full", actor.combat.available_ap() == 6)
	check("Audio ambience playing", world.audio.wind.playing and world.audio.river.playing and world.audio.music.playing)
	check("Attack and grapple controller mappings", InputMap.action_get_events("attack").size() >= 2 and InputMap.action_get_events("grapple").size() >= 2)
	check("Combat animation clips", actor.animation.has_animation("slash_2") and actor.animation.has_animation("power_up_1") and actor.animation.has_animation("attack_2") and actor.animation.has_animation("roll_1"))
	for enemy in enemies:
		check(enemy.kind + " rig and animation available", enemy.animation != null and enemy.animation.has_animation("gethit1" if enemy.kind=="boss" else "Hit_Chest"))
		print("ENEMY_MODEL ", enemy.kind, " ", world.model_bounds(enemy.visual))
	await fixture()
	var reed = enemies.filter(func(e):return e.kind == "reedhook")[0]
	reed.global_position = actor.global_position + Vector3(0, 0, -1.7)
	actor.visual.rotation.y = PI
	actor.combat.attack()
	await frames(8)
	check("Light windup harmless", reed.health == reed.max_health)
	await frames(15)
	check("Basic sword connects", reed.health == reed.max_health-25, reed.health)
	await frames(12)
	check("No repeated damage within strike", reed.health == reed.max_health-25)
	await fixture()
	reed.global_position = actor.global_position + Vector3(0, 0, -1.65)
	actor.visual.rotation.y = PI
	actor.combat.attack()
	await frames(24)
	check("Late attack tap accepted",actor.combat.attack())
	await frames(12)
	check("Tap buffering starts second combo strike", actor.combat.combo == 1)
	await frames(25)
	check("Buffered combo deals one hit per segment", reed.health == reed.max_health-50, reed.health)
	await fixture()
	reed.global_position = actor.global_position + Vector3(0, 0, 2.0)
	actor.visual.rotation.y = PI
	check("Neutral special starts on ground", actor.combat.special(false))
	check("Special spends exactly two AP", actor.combat.available_ap() == 4)
	await frames(23)
	check("Neutral charge harmless", reed.health == reed.max_health)
	await frames(18)
	check("Neutral burst hits behind player", reed.health < reed.max_health)
	var after: int = reed.health
	await frames(12)
	check("Burst cannot repeatedly hit same enemy", reed.health == after)
	await fixture()
	reed.global_position = actor.global_position + Vector3(0, 0, -2)
	actor.visual.rotation.y = PI
	actor.combat.special(true)
	var start: Vector3 = actor.global_position
	await frames(35)
	check("Directional spin moves player", actor.global_position.z < start.z-1.0)
	check("Spin damages nearby enemy", reed.health == reed.max_health-45, reed.health)
	await fixture()
	actor.combat.spend_ap(6)
	check("Insufficient AP rejects special", not actor.combat.special(false) and actor.combat.available_ap() == 0)
	for i in range(6): actor.combat.ap_timers[i] = 0.05
	await frames(6)
	check("Spent AP recharge independently", actor.combat.available_ap() == 6)
	await fixture()
	Input.action_press("block")
	await frames(3)
	var health: int = actor.combat.health
	actor.combat.receive_hit(20, actor.global_position+Vector3(0,0,-1))
	check("Fresh frontal guard parries", actor.combat.health == health and actor.combat.parries > 0)
	await frames(20)
	actor.combat.invulnerable = 0
	actor.combat.receive_hit(20, actor.global_position+Vector3(0,0,-1))
	check("Held frontal guard reduces damage", actor.combat.health == health-4, actor.combat.health)
	await fixture()
	Input.action_press("block")
	await frames(20)
	actor.combat.receive_hit(20, actor.global_position+Vector3(0,0,1))
	check("Guard does not block rear attack", actor.combat.health == 80)
	await fixture()
	start = actor.global_position
	actor.request_dash(Vector3.RIGHT)
	actor.combat.receive_hit(30, actor.global_position+Vector3.LEFT)
	check("Dash has initial invulnerability", actor.combat.health == 100)
	await frames(10)
	check("Dash traverses substantial distance", actor.global_position.x > start.x+1.5)
	check("Dash cooldown prevents spam", not actor.request_dash(Vector3.RIGHT))
	await fixture()
	reed.global_position = actor.global_position+Vector3(0,0,-1.6)
	reed.ai_enabled = true
	reed.begin_attack()
	await frames(25)
	check("Enemy windup deals no contact damage", actor.combat.health == 100)
	await frames(35)
	check("Reedhook sweep delivers one hit", actor.combat.health == 82 and reed.attacks_connected == 1, actor.combat.health)
	await fixture()
	reed.global_position = actor.global_position+Vector3(0,0,-1.6)
	reed.ai_enabled = true
	reed.begin_attack()
	await frames(6)
	reed.receive_hit(1, Vector3.ZERO)
	await frames(18)
	check("Hurt interrupts enemy attack", actor.combat.health == 100 and reed.state == "hurt")
	await fixture()
	world.boss.receive_hit(999, Vector3.ZERO, true)
	check("Boss death disables damage and collision", world.boss.dead and world.boss.collision_layer == 0)
	world.reset_playtest()
	for enemy in enemies: enemy.ai_enabled = false
	check("Reset restores every enemy and player", enemies.all(func(e):return not e.dead and e.health == e.max_health) and actor.combat.health == 100 and actor.combat.available_ap() == 6)
	await fixture(Vector3(0, 0.2, -5.0))
	actor.yaw = PI
	await frames(15)
	check("Camera collision still retracts", actor.arm.get_hit_length() < actor.arm.spring_length-0.3)
	await fixture()
	var marker: Node3D = get_nodes_in_group("study_anchors")[0]
	actor.yaw = atan2(-(marker.global_position.x-actor.global_position.x), -(marker.global_position.z-actor.global_position.z))
	actor.pitch = -0.3
	await frames(4)
	actor.grapple.update_candidate()
	check("Visible anchor can be selected", actor.grapple.candidate != null)
	check("Hookshot fires", actor.grapple.fire())
	start = actor.global_position
	await frames(75)
	check("Hookshot pulls through 3D space", actor.global_position.distance_to(start)>4.0, str(actor.global_position))
	check("Hookshot connection feedback fired", actor.grapple.connections > 0)
	actor.grapple.detach()
	check("Grapple release clears all rope strands", not actor.grapple.active and actor.grapple.rope.all(func(n):return not n.visible))
	await fixture()
	reed.global_position = actor.global_position+Vector3(0,0,-6)
	actor.lock_target = reed
	actor.yaw = 0
	actor.pitch = -0.1
	await frames(8)
	actor.grapple.fire()
	await frames(75)
	check("Enemy grapple strike deals 30 once", reed.health == reed.max_health-30 and actor.grapple.strikes > 0, reed.health)
	await fixture(Vector3(0,0.2,-5.0))
	var hidden := Marker3D.new()
	hidden.position = Vector3(0,1.3,-10)
	hidden.add_to_group("study_anchors")
	world.add_child(hidden)
	actor.yaw = 0
	actor.pitch = 0
	await frames(5)
	actor.grapple.update_candidate()
	check("Grapple ignores occluded target", actor.grapple.candidate != hidden)
	hidden.queue_free()
	await fixture()
	# Aim at each real deck surface; free collision grappling does not teleport to marker metadata.
	for i in range(world.anchors.size()):
		var ring: Node3D = world.anchors[i]
		var landing: Vector3 = ring.get_meta("landing")-Vector3.UP*0.45
		# Independent approach fixtures keep AP recharges and intervening rooftops out of this collision test.
		await fixture(landing+Vector3(0,1.0,3.0))
		actor.global_position.y = landing.y+1.0
		actor.velocity = Vector3.ZERO
		var aim: Vector3 = landing+Vector3.UP*0.02-(actor.global_position+Vector3.UP*1.4)
		actor.yaw = atan2(-aim.x,-aim.z)
		actor.pitch = atan2(aim.y,Vector2(aim.x,aim.z).length())
		await frames(2)
		actor.grapple.cooldown = 0
		var fired: bool = actor.grapple.fire()
		print("DECK_AIM ",i," FIRED ",fired," POINT ",actor.grapple.candidate_point," ACTOR ",actor.global_position)
		await frames(130)
		print("DECK_END ",i," ACTIVE ",actor.grapple.active," MANTLE ",actor.mantling," COLLIDER ",actor.grapple.candidate)
		check("Traversal deck collision landing "+str(i+1),actor.global_position.distance_to(landing)<2.0 and not actor.grapple.active,str(actor.global_position))
		actor.grapple.detach()
	await fixture(Vector3(4,0.2,17))
	var eave = enemies.filter(func(e):return e.kind == "eave")[0]
	eave.ai_enabled = true
	eave.begin_attack()
	start = eave.global_position
	await frames(75)
	check("Eave Runner commits a forward lunge", eave.global_position.distance_to(start) > 0.8)
	print("EAVE_END ",eave.global_position," ACTOR ",actor.global_position," STATE ",eave.state)
	check("Eave lunge hits once", actor.combat.health == 87, actor.combat.health)
	await fixture(Vector3(22,0.3,14.8))
	actor.combat.invulnerable = 99
	world.boss.ai_enabled = true
	world.boss.begin_attack()
	var seen := {}
	for i in range(360):
		await frames(1)
		seen[str(world.boss.animation.current_animation)] = true
	check("Boss plays all three downloaded attack clips", seen.has("attack1") and seen.has("attack2") and seen.has("attack3"), seen.keys())
	await fixture()
	start = actor.global_position
	world.hud_layer.set_pause(true)
	await frames(12)
	check("Pause freezes gameplay and releases cursor", actor.global_position.distance_to(start)<0.01 and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	world.hud_layer.set_pause(false)
	Input.action_press("right")
	await frames(15)
	Input.action_release("right")
	check("Resume restarts gameplay", not paused and actor.global_position.distance_to(start)>0.3)
	world.audio.toggle_mute()
	check("Mute control affects master sound", AudioServer.is_bus_mute(0))
	world.audio.toggle_mute()
	await fixture()
	actor.checkpoint = Vector3(-9, 1.0, -1)
	actor.global_position.y = -8
	await frames(2)
	check("Falls recover to last safe landing", actor.global_position.distance_to(actor.checkpoint) < 0.5 and not actor.grapple.active)
	await fixture()
	actor.combat.receive_hit(999, actor.global_position+Vector3.FORWARD)
	check("Player can die", actor.combat.dead)
	await frames(120)
	check("Death resets to playable clearing", not actor.combat.dead and actor.combat.health == 100 and actor.global_position.distance_to(actor.spawn)<1)
	var failed := checks.filter(func(item):return not item.passed).size()
	var file := FileAccess.open("res://combat_test_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed,"engine":Engine.get_version_info()},"\t"))
	print("COMBAT_PLAYTEST_CHECKS ", checks.size(), " FAILED ",failed)
	world.queue_free()
	await process_frame
	await process_frame
	# Fixed-FPS headless simulation can outrun the audio mix thread at shutdown.
	OS.delay_msec(100)
	quit(1 if failed else 0)
