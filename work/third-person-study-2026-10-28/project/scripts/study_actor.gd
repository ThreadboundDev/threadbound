extends CharacterBody3D
## Independent movement study. Does not load the production player or its globals.

const MODEL = preload("res://assets/threadborne_study.glb")
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
	collision_mask = 1
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
		if "idle" in clip or "run" in clip or "walk" in clip:
			animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	play_clip("idle_4")
	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.4
	add_child(camera_pivot)
	arm = SpringArm3D.new()
	arm.spring_length = distance
	arm.margin = 0.18
	arm.collision_mask = 1
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
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	reset_to_spawn()

func play_clip(key: String) -> void:
	if not animation or current_clip == key:
		return
	for clip in animation.get_animation_list():
		if clip == key or clip.ends_with("/" + key) or clip.ends_with("_" + key):
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
	velocity = Vector3.ZERO
	yaw = 0.0
	pitch = -0.23
	visual.rotation.y = PI
	reset_count += 1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0028
		pitch = clampf(pitch - event.relative.y * 0.0025, -0.95, 0.3)
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(2.4, distance - 0.45)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(9.5, distance + 0.45)
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("reset"):
		reset_to_spawn()
	if event.is_action_pressed("weapons"):
		set_weapons(not use_new_weapons)

func _process(delta: float) -> void:
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down", 0.18)
	yaw -= stick.x * delta * 2.4
	pitch = clampf(pitch - stick.y * delta * 1.8, -0.95, 0.3)
	camera_pivot.rotation = Vector3(pitch, yaw, 0)
	arm.spring_length = lerpf(arm.spring_length, distance, 1.0 - exp(-delta * 12.0))
	if skeleton and pelvis >= 0:
		var displacement := skeleton.get_bone_global_pose(pelvis).origin - pelvis_rest
		# Retained actions have authored root travel; movement belongs to the capsule.
		model.position = model_origin - Vector3(displacement.x, 0, displacement.z)

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("left", "right", "forward", "back", 0.18)
	var direction := Basis(Vector3.UP, yaw) * Vector3(input.x, 0, input.y)
	var speed := 5.2 if Input.is_action_pressed("sprint") else 3.1
	velocity.x = move_toward(velocity.x, direction.x * speed, 22.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 22.0 * delta)
	if not is_on_floor():
		velocity.y -= 19.0 * delta
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = 7.3
	if direction.length() > 0.05:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-delta * 12.0))
	move_and_slide()
	if not is_on_floor():
		play_clip("jump_1")
	elif direction.length() > 0.05:
		play_clip("run_1" if speed > 4 else "walk_1")
	else:
		play_clip("idle_4")
	if global_position.y < -6.0 or absf(global_position.x) > 45 or absf(global_position.z) > 45:
		reset_to_spawn()
