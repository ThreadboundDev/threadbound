extends Node
## 3D study adaptation: original six AP / parallel ten-second recharge, neutral and spin.
var actor: CharacterBody3D
var world: Node3D
var health := 100
var ap_timers: Array[float] = [0, 0, 0, 0, 0, 0]
var action := ""
var elapsed := 0.0
var duration := 0.0
var active_start := 0.0
var active_end := 0.0
var strike_direction := Vector3.FORWARD
var hit_targets: Dictionary = {}
var combo := 0
var buffered := false
var invulnerable := 0.0
var guard_time := 0.0
var guarding := false
var dead := false
var respawn_time := 0.0
var special_cooldown := 0.0
var total_hits := 0
var parries := 0
var air_used := false
var air_direction := "forward"
var pogo_grace := 0.0
var meditating := false
var meditate_time := 0.0
var heal_time := 0.0
var clip_speed := 1.0

func _ready() -> void:
	actor = get_parent()
	world = actor.get_parent()

func available_ap() -> int:
	return ap_timers.filter(func(t): return t <= 0).size()

func spend_ap(count: int) -> bool:
	if available_ap() < count: return false
	for i in range(ap_timers.size()-1, -1, -1):
		if ap_timers[i] <= 0 and count > 0:
			ap_timers[i] = 10.0
			count -= 1
	return true

func face_attack() -> void:
	strike_direction = actor.facing()
	if is_instance_valid(actor.lock_target) and not actor.lock_target.dead:
		var difference: Vector3 = actor.lock_target.global_position - actor.global_position
		difference.y = 0
		if difference.length() > 0.1:
			strike_direction = difference.normalized()
	actor.visual.rotation.y = atan2(strike_direction.x, strike_direction.z)

func attack() -> bool:
	if dead: return false
	if actor.grapple.active: actor.grapple.detach()
	if action in ["light", "water"] and elapsed > 0.09:
		buffered = true
		return true
	if action != "" or actor.dash_time > 0: return false
	if not actor.is_on_floor() and not actor.swimming and air_used: return false
	combo = 0
	start_light()
	return true

func start_light() -> void:
	face_attack()
	action = "water" if actor.swimming else ("light" if actor.is_on_floor() else "air")
	elapsed = 0
	duration = [0.46, 0.47, 0.50][combo] if action != "air" else 0.52
	active_start = [0.19, 0.04, 0.13][combo] if action != "air" else 7.0/30.0
	active_end = active_start + 0.13
	hit_targets.clear()
	buffered = false
	actor.play_clip("slash_2" if action != "air" else "air_attack_forward", true)
	if action != "air":
		if action == "water": actor.play_clip("water_combo_%d" % (combo+1), true)
		else: actor.animation.seek([0.0, 1.15, 2.33][combo], true)
		actor.animation.speed_scale = 2.5
	else:
		air_used = true
		air_direction = "down" if Input.is_action_pressed("descend") else ("up" if Input.is_action_pressed("jump") else "forward")
		if air_direction != "forward":
			actor.play_clip("air_attack_"+air_direction, true)
			duration = 0.32
			active_start = 0.017
			active_end = 0.167
		actor.animation.speed_scale = 1.0
	actor.report_momentum("attack")
	clip_speed = actor.animation.speed_scale
	world.audio.play("sword", actor.global_position, -13, 0.95 + combo * 0.08)

func special(directional: bool) -> bool:
	if dead or action != "" or (not actor.is_on_floor() and not actor.swimming) or actor.grapple.active or special_cooldown > 0: return false
	if not spend_ap(2):
		world.notice("Need 2 AP — each spent point recharges in 10 seconds")
		return false
	face_attack()
	action = "spin" if directional else "neutral"
	elapsed = 0
	duration = 0.85 if directional else 1.2
	active_start = 0.25 if directional else 0.45
	active_end = 0.68 if directional else 0.60
	hit_targets.clear()
	special_cooldown = duration + 0.25
	actor.play_clip("attack_2" if directional else "power_up_1", true)
	if actor.swimming: actor.play_clip("water_spin_special" if directional else "water_neutral_special", true)
	actor.animation.speed_scale = 1.3333/0.85 if directional else 2.0
	clip_speed = actor.animation.speed_scale
	world.fx.ring(actor.global_position + Vector3.UP * 0.05, 0.55, Color("93bfc2"), active_start)
	world.audio.play("grapple_connect", actor.global_position, -16, 0.7)
	actor.report_momentum("utility")
	return true

func damage_targets(radius: float, damage: int, radial := false, push := 2.0) -> void:
	for enemy in get_tree().get_nodes_in_group("study_enemies"):
		if enemy.dead or hit_targets.has(enemy.get_instance_id()): continue
		var difference: Vector3 = enemy.global_position - actor.global_position
		if action == "air" and air_direction != "forward":
			var vertical_center := 1.6 if air_direction == "up" else -0.5
			if absf(difference.y+enemy.target_height-vertical_center) > 1.65 or Vector2(difference.x,difference.z).length() > 1.1+enemy.body_radius: continue
		elif absf(difference.y) > 2.0 or Vector2(difference.x, difference.z).length() > radius + enemy.body_radius: continue
		var horizontal := Vector3(difference.x, 0, difference.z)
		if not radial and not (action == "air" and air_direction != "forward") and horizontal.normalized().dot(strike_direction) < 0.25: continue
		if not world.clear_sight(actor.global_position + Vector3.UP, enemy.global_position + Vector3.UP): continue
		hit_targets[enemy.get_instance_id()] = true
		var amount := roundi(damage*actor.momentum_multiplier("damage"))
		if action == "neutral" and difference.length() > radius * 0.45:
			amount = roundi(damage * 0.55)
		enemy.receive_hit(amount, horizontal.normalized() * push, false)
		total_hits += 1
		actor.camera_kick = maxf(actor.camera_kick, 0.06)
		if action == "air" and air_direction == "down": pogo_bounce()

func pogo_bounce() -> void:
	actor.velocity.y = 7.3*actor.momentum_multiplier("jump")
	pogo_grace = 0.18
	air_used = false
	action = ""
	actor.report_momentum("pogo")
	world.audio.play("sword", actor.global_position, -17, 1.2)

func receive_hit(amount: int, from: Vector3, heavy := false) -> bool:
	if dead or invulnerable > 0: return false
	var to_source := from - actor.global_position
	to_source.y = 0
	var front := to_source.normalized().dot(actor.facing()) > 0.15
	if guarding and front and action == "":
		if guard_time < 0.18:
			parries += 1
			world.fx.burst(actor.global_position + Vector3.UP, Color("f4d89c"), true)
			world.audio.play("grapple_connect", actor.global_position, -10, 1.5)
			for enemy in get_tree().get_nodes_in_group("study_enemies"):
				if enemy.global_position.distance_to(from) < 2.0: enemy.stagger(0.7)
			return false
		amount = roundi(amount * (0.35 if heavy else 0.2))
	health = maxi(0, health - amount)
	var resistance := 0.2 if actor.momentum.flow else (0.12 if actor.momentum.amount >= 70 else (0.05 if actor.momentum.amount >= 30 else 0.0))
	actor.momentum.change(-(amount*8.0+actor.momentum.amount*0.06*amount)*(1-resistance))
	invulnerable = 0.55
	actor.grapple.detach()
	actor.velocity += -to_source.normalized() * (4.0 if heavy else 2.2)
	actor.camera_kick = 0.18
	world.audio.play("hurt", actor.global_position, -11)
	world.fx.burst(actor.global_position + Vector3.UP, Color("d5aa91"))
	if health == 0:
		dead = true
		action = "dead"
		respawn_time = 1.8
		world.notice("Thread loosened — returning to the clearing…")
		world.fx.burst(actor.global_position + Vector3.UP, Color("c6b898"), true)
	else:
		action = "hurt"
		elapsed = 0
		duration = 0.22
	return true

func reset() -> void:
	health = 100
	dead = false
	action = ""
	elapsed = 0
	guarding = false
	guard_time = 0
	invulnerable = 0.6
	special_cooldown = 0
	air_used = false
	pogo_grace = 0
	meditating = false
	meditate_time = 0
	heal_time = 0
	for i in range(6): ap_timers[i] = 0
	actor.animation.speed_scale = 1

func tick(delta: float) -> void:
	meditating = not dead and action == "" and actor.is_on_floor() and actor.input_direction.length() < 0.1 and Input.is_action_pressed("meditate") and not actor.grapple.active
	meditate_time = meditate_time+delta if meditating else 0.0
	var recharge: float = actor.momentum_multiplier("ap") * (2.0 if meditate_time >= 0.3 else 1.0)
	for i in range(6): ap_timers[i] = maxf(0, ap_timers[i] - delta*recharge)
	if meditating and meditate_time >= 0.3:
		heal_time += delta
		if heal_time >= (0.6 if actor.momentum.flow else 0.8):
			heal_time = 0
			if actor.momentum.amount >= 10 and health < 75:
				actor.momentum.change(-10)
				health = mini(75, health+(5 if health <= 35 else (4 if health <= 55 else 3)))
	else: heal_time = 0
	if actor.is_on_floor() or actor.swimming: air_used = false
	pogo_grace = maxf(0, pogo_grace-delta)
	invulnerable = maxf(0, invulnerable-delta)
	special_cooldown = maxf(0, special_cooldown-delta)
	if dead:
		respawn_time -= delta
		if respawn_time <= 0: world.reset_playtest()
		return
	var previous_guard := guarding
	guarding = Input.is_action_pressed("block") and action == "" and not actor.grapple.active
	guard_time = guard_time + delta if guarding and previous_guard else 0.0
	if action == "": return
	var before := elapsed
	if action in ["light","air","water","spin","neutral"]: actor.animation.speed_scale = clip_speed*actor.momentum_multiplier("attack_speed")
	elapsed += delta*actor.momentum_multiplier("attack_speed") if action in ["light", "air", "water", "spin", "neutral"] else delta
	if before < active_start and elapsed >= active_start and action in ["light", "air", "water", "spin", "neutral"]:
		var radial := action in ["spin", "neutral"]
		if radial: world.fx.ring(actor.global_position+Vector3.UP*0.08, 3.2 if action == "neutral" else 2.5, Color("e1cd9a"), 0.35)
		if action == "neutral":
			world.fx.neutral(actor.global_position, 3.2)
			world.audio.play("stomp", actor.global_position, -13, 0.8)
			actor.camera_kick = 0.15
	if elapsed >= active_start and elapsed <= active_end:
		match action:
			"light", "air", "water": damage_targets(2.05, 25 if combo < 2 else 32)
			"spin": damage_targets(2.5, 45, true, 4)
			"neutral": damage_targets(3.2, 70, true, 6)
		if action == "air" and air_direction == "down" and actor.velocity.y < 0:
			var query := PhysicsRayQueryParameters3D.create(actor.global_position+Vector3.UP*0.4, actor.global_position-Vector3.UP*0.32, 1, [actor.get_rid()])
			if not actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): pogo_bounce()
	if elapsed >= duration:
		if action in ["light", "water"] and buffered and combo < 2:
			combo += 1
			start_light()
		else:
			action = ""
			actor.animation.speed_scale = 1
