extends CharacterBody3D
## Independent movement study. Does not load the production player or its globals.

const MODEL = preload("res://assets/threadborne_study.glb")
const COMBAT = preload("res://scripts/study_combat.gd")
const GRAPPLE = preload("res://scripts/study_grapple.gd")
var combat
var grapple
var lock_target
var checkpoint := Vector3(0, 0.5, 4)
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_direction := Vector3.FORWARD
var camera_kick := 0.0
var step_clock := 0.0
var step_index := 0
var coyote := 0.0
var jump_buffer := 0.0
var capture_grace := 0.0
var input_direction := Vector3.ZERO
var visual: Node3D
var model: Node3D
var animation: AnimationPlayer
var skeleton: Skeleton3D
var camera_pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var yaw := 0.0
var pitch := -0.23
var distance := 5.4
var use_new_weapons := true
var current_clip := ""
var pelvis := -1
var pelvis_rest := Vector3.ZERO
var model_origin := Vector3.ZERO
var spawn := Vector3(0, 0.5, 4)
var reset_count := 0

func _ready() -> void:
	name = "Threadborne"
	collision_layer = 2
	collision_mask = 1 | 4
	floor_snap_length = 0.3
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.29
	shape.height = 1.9
	capsule.shape = shape
	capsule.position.y = 0.95
	add_child(capsule)
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	model = MODEL.instantiate()
	visual.add_child(model)
	for node in model.find_children("*", "AnimationPlayer", true, false):
		animation = node
	for node in model.find_children("*", "Skeleton3D", true, false):
		skeleton = node
	if skeleton:
		pelvis = skeleton.find_bone("pelvis")
		if pelvis >= 0:
			pelvis_rest = skeleton.get_bone_global_rest(pelvis).origin
		var foot := skeleton.find_bone("foot.L")
		if foot >= 0:
			model.position.y = 0.09 - skeleton.get_bone_global_rest(foot).origin.y
	model_origin = model.position
	visual.rotation.y = PI
	set_weapons(true)
	for clip in animation.get_animation_list():
		if clip in ["idle_4", "run_1", "walk_1", "block_idle_1", "grapple_swinging_1"]:
			animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	play_clip("idle_4")
	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.4
	add_child(camera_pivot)
	arm = SpringArm3D.new()
	arm.spring_length = distance
	arm.margin = 0.18
	arm.collision_mask = 1 | 8
	var camera_shape := SphereShape3D.new()
	camera_shape.radius = 0.18
	arm.shape = camera_shape
	arm.add_excluded_object(get_rid())
	camera_pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 62
	camera.near = 0.08
	camera.far = 180
	arm.add_child(camera)
	camera.current = true
	combat = COMBAT.new()
	add_child(combat)
	grapple = GRAPPLE.new()
	add_child(grapple)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	reset_to_spawn()

func play_clip(key: String, restart := false) -> void:
	if not animation or (current_clip == key and not restart):
		return
	for clip in animation.get_animation_list():
		if clip == key or clip.ends_with("/" + key) or clip.ends_with("_" + key):
			if restart: animation.stop()
			animation.play(clip, 0.16)
			current_clip = key
			return

func set_weapons(alternate: bool) -> void:
	use_new_weapons = alternate
	for node in model.find_children("*", "MeshInstance3D", true, false):
		if node.name in ["Threadborne_Sword", "Threadborne_Shield_Combined_Test"]:
			node.visible = not alternate
		elif node.name in ["Study_Sword", "Study_Shield"]:
			node.visible = alternate

func reset_to_spawn() -> void:
	global_position = spawn
	checkpoint = spawn
	velocity = Vector3.ZERO
	yaw = 0.0
	pitch = -0.23
	visual.rotation.y = PI
	reset_count += 1
	if grapple: grapple.detach()
	if combat: combat.reset()
	dash_time = 0
	dash_cooldown = 0
	lock_target = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0028
		pitch = clampf(pitch - event.relative.y * 0.0025, -1.05, 0.75)
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			capture_grace = 0.15
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(2.4, distance - 0.45)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(9.5, distance + 0.45)
	if event.is_action_pressed("reset"):
		get_parent().reset_playtest()
	if event.is_action_pressed("weapons"):
		set_weapons(not use_new_weapons)
	if event.is_action_pressed("lock"): toggle_lock()

func _process(delta: float) -> void:
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down", 0.18)
	yaw -= stick.x * delta * 2.4
	pitch = clampf(pitch - stick.y * delta * 1.8, -1.05, 0.75)
	if is_instance_valid(lock_target):
		if lock_target.dead or global_position.distance_to(lock_target.global_position) > 28:
			lock_target = null
		else:
			var direction: Vector3 = lock_target.global_position-global_position
			yaw = lerp_angle(yaw, atan2(-direction.x, -direction.z), 1-exp(-delta*5))
			pitch = lerpf(pitch, -0.15, delta*2)
	camera_pivot.rotation = Vector3(pitch, yaw, 0)
	arm.spring_length = lerpf(arm.spring_length, distance, 1.0 - exp(-delta * 12.0))
	camera_kick = maxf(0, camera_kick-delta)
	camera.h_offset = sin(Time.get_ticks_msec()*0.08)*camera_kick*0.18
	camera.v_offset = cos(Time.get_ticks_msec()*0.1)*camera_kick*0.18
	if skeleton and pelvis >= 0:
		var displacement := skeleton.get_bone_global_pose(pelvis).origin - pelvis_rest
		# Retained actions have authored root travel; movement belongs to the capsule.
		model.position = model_origin - Vector3(displacement.x, 0, displacement.z)

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("left", "right", "forward", "back", 0.18)
	input_direction = Basis(Vector3.UP, yaw) * Vector3(input.x, 0, input.y)
	capture_grace = maxf(0, capture_grace-delta)
	dash_cooldown = maxf(0, dash_cooldown-delta)
	dash_time = maxf(0, dash_time-delta)
	coyote = 0.12 if is_on_floor() else maxf(0, coyote-delta)
	jump_buffer = maxf(0, jump_buffer-delta)
	if not combat.dead:
		if Input.is_action_just_pressed("jump"): jump_buffer = 0.13
		if Input.is_action_just_pressed("dash"): request_dash(input_direction)
		if Input.is_action_just_pressed("attack") and capture_grace <= 0: combat.attack()
		if Input.is_action_just_pressed("special"):
			if input_direction.length() > 0.1 and not is_instance_valid(lock_target): visual.rotation.y = atan2(input_direction.x, input_direction.z)
			combat.special(input.length() > 0.1)
		if Input.is_action_just_pressed("grapple"): grapple.fire()
		if Input.is_action_just_released("grapple"): grapple.detach()
	combat.tick(delta)
	grapple.tick(delta)
	var was_grounded := is_on_floor()
	if not is_on_floor():
		velocity.y -= 19.0 * delta
	if jump_buffer > 0 and grapple.active:
		grapple.jump_release()
		jump_buffer = 0
	elif jump_buffer > 0 and coyote > 0 and combat.action == "":
		velocity.y = 7.3
		jump_buffer = 0
		coyote = 0
		get_parent().audio.play("jump", global_position, -18)
	if grapple.active and grapple.elapsed >= grapple.launch_time:
		pass
	elif dash_time > 0:
		velocity.x = dash_direction.x*13
		velocity.z = dash_direction.z*13
		velocity.y = maxf(velocity.y, -1.0)
	elif combat.action == "spin" and combat.elapsed >= combat.active_start and combat.elapsed < combat.active_end:
		velocity.x = combat.strike_direction.x*7
		velocity.z = combat.strike_direction.z*7
	else:
		var speed := 5.2 if Input.is_action_pressed("sprint") else 3.1
		if combat.guarding: speed = 1.4
		if combat.action in ["light", "air"]: speed *= 0.3
		if combat.action in ["neutral", "hurt", "dead"]: speed = 0
		var acceleration := 22.0 if is_on_floor() else 5.0
		velocity.x = move_toward(velocity.x, input_direction.x*speed, acceleration*delta)
		velocity.z = move_toward(velocity.z, input_direction.z*speed, acceleration*delta)
		if combat.action == "" and input_direction.length() > 0.05:
			var direction := input_direction
			if is_instance_valid(lock_target): direction = lock_target.global_position-global_position
			visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), 1-exp(-delta*12))
	move_and_slide()
	if not was_grounded and is_on_floor(): get_parent().audio.play("land", global_position, -21)
	if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 1 and dash_time <= 0:
		step_clock -= delta
		if step_clock <= 0:
			step_clock = 0.28 if Input.is_action_pressed("sprint") else 0.43
			var wood := global_position.x > 9 and global_position.x < 16 and absf(global_position.z-2.5) < 1.5
			wood = wood or (absf(global_position.x)<2.5 and global_position.z < -5.4 and global_position.z > -12)
			get_parent().audio.play(("step_wood_" if wood else "step_grass_") + str(1+step_index%2), global_position, -23)
			step_index += 1
	if combat.action == "" and dash_time <= 0 and not grapple.active:
		animation.speed_scale = 1
		if combat.guarding: play_clip("block_idle_1")
		elif not is_on_floor(): play_clip("jump_1")
		elif input.length() > 0.05: play_clip("run_1" if Input.is_action_pressed("sprint") else "walk_1")
		else: play_clip("idle_4")
	if combat.action == "hurt": play_clip("impact_1")
	if combat.dead: play_clip("death_1")
	if not combat.dead:
		for node in get_tree().get_nodes_in_group("study_checkpoints"):
			if global_position.distance_to(node.global_position) < 1.4: checkpoint = node.global_position+Vector3.UP*0.15
	if global_position.y < -6 or absf(global_position.x)>45 or absf(global_position.z)>45:
		grapple.detach()
		global_position = checkpoint
		velocity = Vector3.ZERO
		combat.invulnerable = 0.8
		combat.action = ""
		animation.speed_scale = 1
		reset_count += 1
		get_parent().notice("Thread caught — returned to the last landing")

func facing() -> Vector3:
	return Vector3(sin(visual.rotation.y), 0, cos(visual.rotation.y))

func grapple_origin() -> Vector3:
	if skeleton:
		var hand := skeleton.find_bone("hand.R")
		if hand >= 0: return skeleton.global_transform*skeleton.get_bone_global_pose(hand).origin
	return global_position+Vector3.UP*1.05

func request_dash(direction: Vector3) -> bool:
	if dash_cooldown > 0 or combat.dead: return false
	if combat.action in ["light", "air", "spin", "neutral"] and combat.elapsed >= 0.22 and combat.elapsed < combat.active_end: return false
	combat.action = ""
	combat.guarding = false
	grapple.detach()
	dash_direction = direction.normalized() if direction.length() > 0.1 else facing()
	dash_time = 0.24
	dash_cooldown = 0.55
	combat.invulnerable = maxf(combat.invulnerable, 0.2)
	play_clip("roll_1", true)
	animation.speed_scale = 4.2
	get_parent().audio.play("dash", global_position, -13)
	get_parent().fx.burst(global_position+Vector3.UP, Color("a4c0bb"))
	return true

func toggle_lock() -> void:
	if is_instance_valid(lock_target):
		lock_target = null
		return
	var nearest := 24.0
	for enemy in get_tree().get_nodes_in_group("study_enemies"):
		var d := global_position.distance_to(enemy.global_position)
		if not enemy.dead and d < nearest and get_parent().clear_sight(global_position+Vector3.UP, enemy.global_position+Vector3.UP):
			nearest = d
			lock_target = enemy
