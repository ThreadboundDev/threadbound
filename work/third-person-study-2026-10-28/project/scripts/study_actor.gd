extends CharacterBody3D
## Independent movement study. Does not load the production player or its globals.

const MODEL = preload("res://assets/threadborne_study.glb")
const COMBAT = preload("res://scripts/study_combat.gd")
const GRAPPLE = preload("res://scripts/study_grapple.gd")
const MOMENTUM = preload("res://scripts/study_momentum.gd")
const AUTHORED_ATTACKS = preload("res://assets/threadborne_authored_attacks.glb")
const LOWER_BODY_BONES: Array[StringName] = [&"pelvis", &"thigh.L", &"thigh.R", &"shin.L", &"shin.R", &"foot.L", &"foot.R", &"toe.L", &"toe.R"]
var momentum = MOMENTUM.new()
var air_jump_available := true
var wall_normal := Vector3.ZERO
var wall_hold := 0.0
var mantling := false
var mantle_time := 0.0
var mantle_from := Vector3.ZERO
var mantle_to := Vector3.ZERO
var swimming := false
var water_attack_leg_motion_strength := 0.65
var water_attack_swim_leg_blend := 0.75
var previous_position := Vector3.ZERO
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
	install_authored_attacks()
	install_water_combo(animation, skeleton)
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
	add_child(preload("res://scripts/study_flow_visual.gd").new())
	for mesh_node in model.find_children("*", "MeshInstance3D", true, false):
		if mesh_node.name in ["Study_Sword", "Threadborne_Sword"]: get_parent().fx.watch_blade(self, mesh_node)

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
	momentum.reset()
	air_jump_available = true
	mantling = false
	previous_position = global_position

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
		report_momentum("swap")
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
		var cancel_vertical := not is_on_floor() or mantling or current_clip in ["roll_1", "hanging_idle_1", "get_up_from_hang_1", "swimming_1", "water_idle_1"]
		model.position = model_origin - Vector3(displacement.x, displacement.y if cancel_vertical else 0.0, displacement.z)

func _physics_process(delta: float) -> void:
	momentum.tick(delta, global_position.distance_to(previous_position), not combat.dead and combat.action != "hurt")
	previous_position = global_position
	var in_water: bool = get_parent().has_method("is_swimming") and get_parent().is_swimming(global_position)
	if in_water and not swimming: grapple.detach()
	swimming = in_water
	if mantling:
		mantle_time += delta
		var phase := clampf(mantle_time/0.32, 0, 1)
		global_position = mantle_from.lerp(mantle_to, phase*phase*(3-2*phase)) + Vector3.UP*sin(phase*PI)*0.28
		velocity = Vector3.ZERO
		if phase >= 1: mantling = false
		return
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
		if Input.is_action_just_pressed("grapple"):
			if grapple.active: grapple.detach()
			else: grapple.fire()
	combat.tick(delta)
	grapple.tick(delta)
	var was_grounded := is_on_floor()
	if is_on_floor() or swimming: air_jump_available = true
	if not is_on_floor() and not swimming and not grapple.connected:
		var jump_cut := 2.25 if velocity.y > 0 and not Input.is_action_pressed("jump") and combat.pogo_grace <= 0 else 1.0
		velocity.y -= 19.0 * jump_cut * delta
	if jump_buffer > 0 and grapple.active:
		grapple.jump_release()
		jump_buffer = 0
	elif jump_buffer > 0 and coyote > 0 and combat.action == "":
		velocity.y = 7.3 * momentum_multiplier("jump")
		jump_buffer = 0
		coyote = 0
		get_parent().audio.play("jump", global_position, -18)
		report_momentum("jump",0.55)
	elif jump_buffer > 0 and wall_normal.length() > 0.5:
		velocity = wall_normal*6.2 + Vector3.UP*6.8*momentum_multiplier("jump")
		jump_buffer = 0
		wall_hold = 0
		report_momentum("jump",0.7)
	elif jump_buffer > 0 and air_jump_available and not swimming and combat.action == "" and combat.spend_ap(1):
		velocity.y = 7.3 * momentum_multiplier("jump")
		air_jump_available = false
		jump_buffer = 0
		report_momentum("jump",1.35)
		get_parent().audio.play("jump", global_position, -19, 1.12)
	if grapple.active and grapple.connected:
		pass
	elif swimming:
		var vertical := Input.get_action_strength("jump")-Input.get_action_strength("descend")
		var swim_direction := input_direction + Vector3.UP*vertical
		if input_direction.length() > 0.1: swim_direction += Vector3.UP*sin(pitch)*0.65
		var swim_speed := 4.8 * momentum_multiplier("move")
		velocity = velocity.move_toward(swim_direction.limit_length()*swim_speed, delta*22)
		if dash_time > 0: velocity = dash_direction*13*momentum_multiplier("dash")
		if vertical > 0 and global_position.y > -1.15:
			velocity.y = 10.4
			swimming = false
		if input_direction.length() > 0.1: visual.rotation.y = lerp_angle(visual.rotation.y, atan2(input_direction.x, input_direction.z), delta*8)
	elif dash_time > 0:
		velocity.x = dash_direction.x*13*momentum_multiplier("dash")
		velocity.z = dash_direction.z*13*momentum_multiplier("dash")
		velocity.y = maxf(velocity.y, -1.0)
	elif combat.action == "spin" and combat.elapsed >= combat.active_start and combat.elapsed < combat.active_end:
		velocity.x = combat.strike_direction.x*7
		velocity.z = combat.strike_direction.z*7
	else:
		var speed := 5.2 if Input.is_action_pressed("sprint") else 3.1
		speed *= momentum_multiplier("move")
		if combat.guarding: speed = 1.4
		if combat.action in ["light", "air"]: speed *= 0.3
		if combat.action in ["neutral", "hurt", "dead"]: speed = 0
		if combat.meditating: speed = 0
		var acceleration := 22.0 if is_on_floor() else 5.0
		velocity.x = move_toward(velocity.x, input_direction.x*speed, acceleration*delta)
		velocity.z = move_toward(velocity.z, input_direction.z*speed, acceleration*delta)
		if combat.action == "" and input_direction.length() > 0.05:
			var direction := input_direction
			if is_instance_valid(lock_target): direction = lock_target.global_position-global_position
			visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), 1-exp(-delta*12))
		if wall_normal.length() > 0.5 and velocity.y < 0 and input_direction.dot(-wall_normal) > 0.2:
			wall_hold += delta
			velocity.y = 0 if wall_hold < 0.32 else maxf(velocity.y, -3.2)
			play_clip("hanging_idle_1")
			if Input.is_action_pressed("jump"): try_mantle()
	move_and_slide()
	wall_normal = get_wall_normal() if is_on_wall() and not is_on_floor() else Vector3.ZERO
	if wall_normal.length() < 0.5: wall_hold = 0
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
		if combat.meditating: play_clip("stand_to_sit_1")
		elif swimming: play_clip("swimming_1" if velocity.length() > 0.3 else "water_idle_1")
		elif wall_hold > 0: play_clip("hanging_idle_1")
		elif combat.guarding: play_clip("block_idle_1")
		elif not is_on_floor(): play_clip("jump_1")
		elif input.length() > 0.05:
			play_clip("run_1" if Input.is_action_pressed("sprint") else "walk_1")
			animation.speed_scale = momentum_multiplier("move")
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
	if not combat.spend_ap(1): return false
	combat.action = ""
	combat.guarding = false
	grapple.detach()
	dash_direction = direction.normalized() if direction.length() > 0.1 else facing()
	if swimming:
		var vertical := Input.get_action_strength("jump")-Input.get_action_strength("descend")
		if absf(vertical)>0.1: dash_direction = (direction+Vector3.UP*vertical).normalized()
	dash_time = 0.30
	dash_cooldown = 0.65
	combat.invulnerable = maxf(combat.invulnerable, 0.36*maxf(1, momentum_multiplier("iframe")))
	play_clip("roll_1", true)
	animation.speed_scale = 4.2
	get_parent().audio.play("dash", global_position, -13)
	get_parent().fx.burst(global_position+Vector3.UP, Color("a4c0bb"))
	report_momentum("dash")
	return true

func momentum_multiplier(key: String) -> float:
	return momentum.multiplier(key)

func report_momentum(category: String, strength := 1.0) -> void:
	var was_flow: bool = momentum.flow
	momentum.report(category,strength)
	if momentum.flow and not was_flow:
		get_parent().notice("FLOW · keep weaving movement and attacks")
		get_parent().audio.play("grapple_connect", global_position, -13, 0.65)

func try_mantle() -> bool:
	if mantling or combat.dead: return false
	var forward := input_direction.normalized() if input_direction.length() > 0.1 else facing()
	var space := get_world_3d().direct_space_state
	var start := global_position+Vector3.UP*2.1+forward*0.72
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(start, start-Vector3.UP*1.65, 1, [get_rid()]))
	if hit.is_empty() or hit.normal.y < 0.7: return false
	var destination: Vector3 = hit.position+forward*0.12+Vector3.UP*0.06
	if destination.y < global_position.y+0.35: return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = get_child(0).shape
	query.transform = Transform3D(Basis.IDENTITY, destination+Vector3.UP*0.96)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	if not space.intersect_shape(query, 1).is_empty(): return false
	mantling = true
	mantle_from = global_position
	mantle_to = destination
	mantle_time = 0
	grapple.detach()
	combat.action = ""
	play_clip("get_up_from_hang_1", true)
	animation.speed_scale = animation.current_animation_length/0.32
	report_momentum("utility")
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

func install_authored_attacks() -> void:
	var donor := AUTHORED_ATTACKS.instantiate()
	var animations: AnimationPlayer = donor.find_children("*", "AnimationPlayer", true, false)[0]
	var library := AnimationLibrary.new()
	var skeleton_path := animation.get_node(animation.root_node).get_path_to(skeleton)
	for clip in animations.get_animation_list():
		if clip == &"RESET":
			continue
		var animation := animations.get_animation(clip).duplicate(true) as Animation
		for track in range(animation.get_track_count()-1, -1, -1):
			var path := animation.track_get_path(track)
			if path.get_subname_count() != 1 or skeleton.find_bone(path.get_subname(0)) < 0:
				animation.remove_track(track)
				continue
			animation.track_set_path(track, NodePath(String(skeleton_path)+":"+String(path.get_subname(0))))
		if String(clip) in ["air_attack_up", "air_attack_down"]:
			# Map the baked poses to quick extension, held contact, quick withdrawal.
			var old_times := [0.0, 4.0/30.0, 7.0/30.0, 9.0/30.0, 11.0/30.0, 17.0/30.0, 0.8]
			var new_times := [0.0, 0.017, 1.0/30.0, 0.17, 0.19, 0.27, 0.32]
			for track in animation.get_track_count():
				for key in animation.track_get_key_count(track):
					var time := animation.track_get_key_time(track, key)
					for segment in range(old_times.size()-1):
						if time <= old_times[segment+1] + 0.00001:
							var weight := inverse_lerp(old_times[segment], old_times[segment+1], time)
							animation.track_set_key_time(track, key, lerpf(new_times[segment], new_times[segment+1], weight))
							break
			animation.length = 0.32
		if String(clip) == "air_attack_forward":
			# Preserve windup/contact; compress only the recovery after frame 12.
			var recovery_start := 11.0/30.0
			for track in animation.get_track_count():
				for key in animation.track_get_key_count(track):
					var time := animation.track_get_key_time(track, key)
					if time > recovery_start:
						animation.track_set_key_time(track, key, recovery_start + (time-recovery_start)*0.35)
			animation.length = recovery_start + (animation.length-recovery_start)*0.35
		library.add_animation(clip, animation)
	animation.add_animation_library(&"authored", library)
	donor.free()

func install_water_combo(target: AnimationPlayer, skeleton: Skeleton3D) -> void:
	# Keep the grounded pelvis/upper body/flip. Leg joints use a swim-idle base
	# with authored attack articulation layered over it, not a frozen replacement.
	# Root compensation still lets physics own travel; source assets stay intact.
	var ground: Animation
	var idle: Animation
	var neutral: Animation
	var spin: Animation
	for clip in target.get_animation_list():
		if String(clip).to_lower().ends_with("slash_2"):
			ground = target.get_animation(clip)
		if String(clip).to_lower().ends_with("water_idle_1"):
			idle = target.get_animation(clip)
		if String(clip).to_lower().ends_with("power_up_1"):
			neutral = target.get_animation(clip)
		if String(clip).to_lower().ends_with("attack_2"):
			spin = target.get_animation(clip)
	if not ground or not idle:
		push_error("Swimming combo requires grounded slash_2 and water_idle_1")
		return
	var library := AnimationLibrary.new()
	var path := target.get_node(target.root_node).get_path_to(skeleton)
	var starts := [0.0, 1.15, 2.33, ground.length]
	var definitions: Array[Dictionary] = []
	for step in range(3):
		definitions.append({"name": StringName("water_combo_%d" % (step + 1)), "source": ground, "start": starts[step], "end": starts[step + 1], "special": false})
	if neutral:
		definitions.append({"name": &"water_neutral_special", "source": neutral, "start": 0.0, "end": neutral.length, "special": true})
	if spin:
		definitions.append({"name": &"water_spin_special", "source": spin, "start": 0.0, "end": spin.length, "special": true})
	for definition in definitions:
		var authored: Animation = definition.source
		var start: float = definition.start
		var animation := Animation.new()
		animation.length = definition.end - start
		animation.step = 1.0 / 30.0
		for track in authored.get_track_count():
			var bone_path := authored.track_get_path(track)
			var type := authored.track_get_type(track)
			if bone_path.get_subname_count() != 1 or type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
				continue
			var bone := StringName(bone_path.get_subname(0))
			if skeleton.find_bone(bone) < 0:
				continue
			var idle_track := -1
			for candidate in idle.get_track_count():
				var candidate_path := idle.track_get_path(candidate)
				if idle.track_get_type(candidate) == type and candidate_path.get_subname_count() == 1 and candidate_path.get_subname(0) == bone:
					idle_track = candidate
					break
			var destination := animation.add_track(type)
			animation.track_set_path(destination, NodePath(String(path) + ":" + String(bone)))
			for frame in range(ceili(animation.length * 30.0) + 1):
				var time := minf(float(frame) / 30.0, animation.length)
				var sample_time: float = start + time
				var source := authored
				var source_track := track
				if definition.special and idle_track >= 0 and (bone in LOWER_BODY_BONES or bone == &"root"):
					source = idle
					source_track = idle_track
					# Keep the pelvis anchored; swimming translation is owned by physics.
					sample_time = 0.0 if bone in [&"pelvis", &"root"] else fmod(start + time, idle.length)
				var value: Variant
				match type:
					Animation.TYPE_POSITION_3D: value = source.position_track_interpolate(source_track, sample_time)
					Animation.TYPE_ROTATION_3D: value = source.rotation_track_interpolate(source_track, sample_time)
					Animation.TYPE_SCALE_3D: value = source.scale_track_interpolate(source_track, sample_time)
				if definition.special and idle_track >= 0 and bone in [&"pelvis", &"root"] and type == Animation.TYPE_ROTATION_3D:
					# Retain the authored spin/body lean as a delta from swim idle,
					# while root translation remains physics-owned.
					value = authored.rotation_track_interpolate(track, start + time) * authored.rotation_track_interpolate(track, start).inverse() * idle.rotation_track_interpolate(idle_track, 0.0)
				elif not definition.special and idle_track >= 0 and bone in LOWER_BODY_BONES and bone != &"pelvis" and type == Animation.TYPE_ROTATION_3D:
					# A shared whole-combo reference and swim phase preserve handoffs.
					# Keep attack flexion relative to its initial leg pose, recentered
					# on swimming legs. The pelvis rotation still carries the full flip.
					var attack_pose: Quaternion = value
					var reference := authored.rotation_track_interpolate(track, 0.0)
					var swim_pose := idle.rotation_track_interpolate(idle_track, fmod(start + time, idle.length))
					var motion := Quaternion.IDENTITY.slerp(reference.inverse() * attack_pose, water_attack_leg_motion_strength)
					value = attack_pose.slerp(swim_pose * motion, water_attack_swim_leg_blend).normalized()
				animation.track_insert_key(destination, time, value)
		library.add_animation(definition.name, animation)
	target.add_animation_library(&"water_combo", library)
