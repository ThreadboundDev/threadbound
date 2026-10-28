extends CharacterBody3D
## Distinct existing Threadbound silhouettes with readable, interruptible 3D attack states.
var kind := "reedhook"
var world
var actor
var model: Node3D
var visual: Node3D
var animation: AnimationPlayer
var state := "idle"
var timer := 0.0
var health := 100
var max_health := 100
var dead := false
var home := Vector3.ZERO
var body_radius := 0.45
var target_height := 1.1
var attack_direction := Vector3.FORWARD
var hit_delivered := false
var combo := 0
var ai_enabled := true
var hits_received := 0
var attacks_connected := 0
var tell: MeshInstance3D
var tell_material: StandardMaterial3D
var health_label: Label3D
var display_name := "Reedhook"
var death_time := 0.0

func _ready() -> void:
	world = get_parent()
	actor = world.actor
	add_to_group("study_enemies")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	home = global_position
	max_health = 95 if kind == "reedhook" else (75 if kind == "eave" else 420)
	health = max_health
	body_radius = 0.4 if kind == "reedhook" else (0.45 if kind == "eave" else 0.95)
	target_height = 1.1 if kind != "boss" else 1.65
	display_name = "Reedhook" if kind == "reedhook" else ("Eave Runner" if kind == "eave" else "Bellstriker · Arena Champion")
	var shape := CapsuleShape3D.new()
	shape.radius = body_radius
	shape.height = 2.0 if kind == "reedhook" else (1.25 if kind == "eave" else 2.8)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = shape.height * 0.5
	add_child(collider)
	visual = Node3D.new()
	add_child(visual)
	var path := "res://assets/enemies/" + ("eave_runner" if kind == "eave" else ("bellstriker" if kind == "boss" else "reedhook")) + ".glb"
	model = load(path).instantiate()
	visual.add_child(model)
	for node in model.find_children("*", "AnimationPlayer", true, false): animation = node
	var bound: AABB = world.model_bounds(model)
	var height := 2.15 if kind == "reedhook" else (1.55 if kind == "eave" else 3.0)
	var factor := height / maxf(0.1, bound.size.y)
	model.scale *= factor
	model.position.y -= bound.position.y * factor
	# Existing side-view rigs face +X; normalize their forward axis to +Z.
	model.rotation.y = -PI/2
	for clip in animation.get_animation_list():
		if clip in ["idle", "walk", "run", "box_idle"]: animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	play("box_idle" if kind == "boss" else "idle")
	var mesh := CylinderMesh.new()
	mesh.top_radius = attack_range()
	mesh.bottom_radius = attack_range()
	mesh.height = 0.018
	mesh.radial_segments = 40
	tell = MeshInstance3D.new()
	tell.mesh = mesh
	tell.position.y = 0.035
	tell_material = world.fx.glow(Color(0.85, 0.53, 0.22, 0.25))
	tell_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tell.material_override = tell_material
	tell.visible = false
	add_child(tell)
	health_label = Label3D.new()
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 28
	health_label.pixel_size = 0.007
	health_label.position.y = height + 0.4
	add_child(health_label)
	update_label()

func play(clip: String) -> void:
	if animation and animation.has_animation(clip):
		animation.play(clip, 0.08)

func attack_range() -> float:
	return 2.45 if kind == "reedhook" else (1.65 if kind == "eave" else 3.3)

func update_label() -> void:
	health_label.text = display_name + "\n" + str(health) + " / " + str(max_health)
	health_label.modulate = Color("d3c6a3")

func stagger(length: float) -> void:
	if dead: return
	state = "hurt"
	timer = length
	tell.visible = false
	play("hurt")

func receive_hit(amount: int, push: Vector3, _heavy := false) -> void:
	if dead: return
	health = maxi(0, health-amount)
	hits_received += 1
	velocity += push * (0.35 if kind == "boss" else 1)
	world.fx.number_at(global_position + Vector3.UP * target_height, amount, Color("e2d0a2"))
	world.fx.burst(global_position + Vector3.UP * target_height, Color("c3b291"))
	world.audio.play("hurt", global_position, -17, 0.8 if kind == "boss" else 1.1)
	update_label()
	if health == 0:
		dead = true
		state = "dead"
		death_time = 1.2
		tell.visible = false
		collision_layer = 0
		collision_mask = 1
		play("dead" if kind == "boss" else ("death" if kind == "eave" else "hurt"))
		world.fx.burst(global_position + Vector3.UP * target_height, Color("c4b89b"), true)
		if kind == "boss": world.notice("Champion unraveled · R resets all encounters")
	else:
		stagger(0.16 if kind == "boss" else 0.38)

func reset_enemy() -> void:
	dead = false
	health = max_health
	global_position = home
	velocity = Vector3.ZERO
	state = "idle"
	timer = 0.5
	combo = 0
	visible = true
	visual.rotation.z = 0
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	tell.visible = false
	play("box_idle" if kind == "boss" else "idle")
	update_label()

func begin_attack() -> void:
	var difference: Vector3 = actor.global_position-global_position
	difference.y = 0
	attack_direction = difference.normalized()
	visual.rotation.y = atan2(attack_direction.x, attack_direction.z)
	state = "windup"
	timer = (0.6 if kind == "reedhook" else 0.55) if kind != "boss" else [0.36, 0.33, 0.66][combo]
	if kind == "boss" and health < max_health*0.5: timer *= 0.85
	tell.visible = true
	play(("windup" if kind == "reedhook" else "throw_windup") if kind != "boss" else "charge_" + str(combo+1))
	world.audio.play("enemy_swing" if kind != "boss" else "grapple_connect", global_position, -22, 0.75)

func release_attack() -> void:
	state = "active"
	timer = 0.267 if kind == "reedhook" else (0.32 if kind == "eave" else [0.23, 0.23, 0.33][combo])
	hit_delivered = false
	tell.visible = false
	play(("sweep" if kind == "reedhook" else "jump_slash") if kind != "boss" else ["jab", "cross", "smash"][combo])
	world.fx.ring(global_position + Vector3.UP * 0.1, attack_range(), Color("d7996d"), 0.2, 1.6, visual.rotation.y)
	world.audio.play("stomp" if kind == "boss" and combo == 2 else "enemy_swing", global_position, -15, 0.8 if kind == "boss" else 1.1)

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y -= delta * 19
	velocity.x = move_toward(velocity.x, 0, 16*delta)
	velocity.z = move_toward(velocity.z, 0, 16*delta)
	if dead:
		death_time -= delta
		if kind == "reedhook": visual.rotation.z = lerpf(visual.rotation.z, 1.45, delta*6)
		if death_time <= 0: visible = false
		move_and_slide()
		return
	if not ai_enabled:
		move_and_slide()
		return
	timer -= delta
	var difference: Vector3 = actor.global_position-global_position
	var flat := Vector3(difference.x, 0, difference.z)
	var distance := flat.length()
	match state:
		"idle":
			if not actor.combat.dead and distance < (12 if kind == "boss" else 8.5) and absf(difference.y) < 2.5 and world.clear_sight(global_position+Vector3.UP, actor.global_position+Vector3.UP):
				state = "chase"
		"chase":
			if actor.combat.dead or distance > 18 or global_position.distance_to(home) > 14:
				state = "return"
			elif distance <= attack_range() and absf(difference.y) < 1.6:
				combo = 0
				begin_attack()
			else:
				var direction := flat.normalized()
				var ahead := global_position + direction * 0.9
				var probe := PhysicsRayQueryParameters3D.create(ahead+Vector3.UP, ahead-Vector3.UP*2, 1)
				if not get_world_3d().direct_space_state.intersect_ray(probe).is_empty():
					var speed := 2.0 if kind == "reedhook" else (3.8 if kind == "eave" else 2.0)
					velocity.x = direction.x * speed
					velocity.z = direction.z * speed
					visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), delta*9)
					if not animation.is_playing() or not animation.current_animation in ["walk", "run"]: play("run" if kind == "eave" else "walk")
		"windup":
			tell_material.albedo_color.a = 0.18 + 0.12*sin(Time.get_ticks_msec()*0.02)
			if timer <= 0: release_attack()
		"active":
			var forward_step := 1.0 if kind == "reedhook" else (5.5 if kind == "eave" else 0.6)
			var ahead := global_position+attack_direction*(body_radius+0.5)
			var floor_probe := PhysicsRayQueryParameters3D.create(ahead+Vector3.UP, ahead-Vector3.UP*2, 1)
			if get_world_3d().direct_space_state.intersect_ray(floor_probe).is_empty(): forward_step = 0
			velocity.x = attack_direction.x * forward_step
			velocity.z = attack_direction.z * forward_step
			if not hit_delivered and distance <= attack_range()+0.25 and absf(difference.y) < 1.6 and flat.normalized().dot(attack_direction) > 0.25 and world.clear_sight(global_position+Vector3.UP, actor.global_position+Vector3.UP):
				hit_delivered = true
				var amount: int = 18 if kind == "reedhook" else (13 if kind == "eave" else [16, 21, 32][combo])
				if actor.combat.receive_hit(amount, global_position, kind == "boss" and combo == 2): attacks_connected += 1
			if timer <= 0:
				state = "recover"
				timer = 0.65 if kind != "boss" else (0.24 if combo < 2 else 1.15)
				play(("recover" if kind == "reedhook" else "land_recover") if kind != "boss" else "box_recover")
		"recover":
			if timer <= 0:
				if kind == "boss" and combo < 2 and distance < attack_range()+1.3:
					combo += 1
					begin_attack()
				else: state = "chase"
		"hurt":
			if timer <= 0: state = "chase"
		"return":
			var homeward := home-global_position
			homeward.y = 0
			if homeward.length() < 0.3:
				state = "idle"
				play("box_idle" if kind == "boss" else "idle")
			else:
				velocity.x = homeward.normalized().x * 2
				velocity.z = homeward.normalized().z * 2
	move_and_slide()
	if global_position.y < -4: reset_enemy()
