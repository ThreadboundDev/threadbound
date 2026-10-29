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
var downloaded := true
var skeleton: Skeleton3D
var root_rest := Vector3.ZERO
var model_origin := Vector3.ZERO
var pelvis_index := -1
var navigator: NavigationAgent3D
var navigation_clock := 0.0
const MOTION = preload("res://scripts/study_motion.gd")
var safe_velocity := Vector3.ZERO
var impact_time := 0.0
var impact_animation_speed := 1.0
var reaction_cooldown := 0.0
var impulse := Vector3.ZERO
var desired_motion := Vector3.ZERO
var path_target := Vector3.ZERO
var locomotion_velocity := Vector3.ZERO

func _ready() -> void:
	world = get_parent()
	actor = world.actor
	add_to_group("study_enemies")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_snap_length=0.35
	safe_margin=0.015
	home = global_position
	navigator = NavigationAgent3D.new()
	navigator.path_desired_distance = 0.35
	# Recast's two-cell surface offset must not strand agents at a point above their feet.
	navigator.path_height_offset = 0.5
	navigator.target_desired_distance = 0.6
	navigator.avoidance_enabled=true
	navigator.radius=body_radius+0.1
	navigator.neighbor_distance=4.0
	navigator.time_horizon_agents=0.65
	navigator.max_speed=5.5
	navigator.velocity_computed.connect(func(value: Vector3): safe_velocity=value)
	add_child(navigator)
	max_health = 95 if kind == "reedhook" else (75 if kind == "eave" else 420)
	health = max_health
	body_radius = 0.4 if kind == "reedhook" else (0.45 if kind == "eave" else 0.95)
	navigator.radius=body_radius+0.1
	target_height = 1.1 if kind != "boss" else 1.65
	display_name = "Woven Swordsman" if kind == "reedhook" else ("Spindle Runner" if kind == "eave" else "Armored Guardian")
	var shape := CapsuleShape3D.new()
	shape.radius = body_radius
	shape.height = 1.9 if kind != "boss" else 3.0
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = shape.height * 0.5
	add_child(collider)
	var path := "res://assets/enemies/woven_swordsman.glb" if kind == "reedhook" else ("res://assets/enemies/woven_pikewarden.glb" if kind == "eave" else "res://assets/local_licensed/armored_golem.glb")
	if not ResourceLoader.exists(path):
		path = "res://assets/enemies/bellstriker.glb"
		downloaded = false
	visual = Node3D.new()
	add_child(visual)
	model = load(path).instantiate()
	visual.add_child(model)
	for node in model.find_children("*", "AnimationPlayer", true, false): animation = node
	for node in model.find_children("*", "Skeleton3D", true, false): skeleton = node
	var bound: AABB = world.model_bounds(model)
	var height := 1.95 if kind != "boss" else 3.15
	var factor := height / maxf(0.1, bound.size.y)
	model.scale *= factor
	model.position.y -= bound.position.y * factor
	# Existing side-view rigs face +X; normalize their forward axis to +Z.
	model.rotation.y = 0 if downloaded else -PI/2
	model_origin = model.position
	if skeleton:
		pelvis_index = skeleton.find_bone("pelvis")
		if pelvis_index >= 0: root_rest = skeleton.get_bone_global_rest(pelvis_index).origin
	for clip in animation.get_animation_list():
		if clip in ["idle", "walk", "run", "box_idle", "Idle", "Sword_Idle", "Walk", "Jog_Fwd", "Jog_Armed", "idle1", "walkF", "jogF"]: animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
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
	apply_woven_accents()
	for mesh_node in model.find_children("*", "MeshInstance3D", true, false):
		if String(mesh_node.name).begins_with("Downloaded_"): world.fx.watch_blade(self, mesh_node)

func play(clip: String) -> void:
	if downloaded:
		var mapping := {"idle":"Sword_Idle", "box_idle":"idle1", "walk":"Walk", "run":"Jog_Armed", "hurt":"Hit_Chest", "death":"Death01", "dead":"death1"}
		if kind == "boss": mapping.merge({"walk":"walkF", "run":"jogF", "hurt":"gethit1", "charge_1":"attack1", "charge_2":"attack2", "charge_3":"attack3", "jab":"attack1", "cross":"attack2", "smash":"attack3"}, true)
		else: mapping.merge({"windup":"Sword_Regular_A", "sweep":"Sword_Regular_A", "throw_windup":"Sword_Dash", "jump_slash":"Sword_Dash"}, true)
		if clip=="recover": clip="Sword_Regular_A_Rec"
		if clip in ["land_recover","box_recover"]: return
		clip = mapping.get(clip, clip)
	if animation and animation.has_animation(clip):
		if animation.current_animation == clip and animation.is_playing(): return
		animation.speed_scale = 1
		animation.play(clip, 0.12)

func _process(_delta: float) -> void:
	if skeleton and pelvis_index >= 0:
		var shift := skeleton.get_bone_global_pose(pelvis_index).origin-root_rest
		var local_shift := model.global_basis.inverse()*(skeleton.global_basis*shift)
		model.position = model_origin-Vector3(local_shift.x,0,local_shift.z)
	health_label.visible = not dead and (actor.lock_target == self or (health < max_health and global_position.distance_to(actor.global_position)<12))

func attack_range() -> float:
	return 2.45 if kind == "reedhook" else (1.65 if kind == "eave" else 3.3)

func apply_woven_accents() -> void:
	var cloth := ShaderMaterial.new()
	cloth.shader = preload("res://scripts/study_weave.gdshader")
	cloth.set_shader_parameter("cloth_color",Color("344c51") if kind != "boss" else Color("3d5358"))
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if "head and neck" in String(mesh.name).to_lower(): mesh.material_override = cloth
		for surface in range(mesh.mesh.get_surface_count()):
			var mat: Material = mesh.get_active_material(surface)
			if kind == "boss" and mat and "Body" in mat.resource_name: mesh.set_surface_override_material(surface,cloth)
	if not skeleton: return
	var unit := skeleton.global_basis.get_scale().length()/sqrt(3.0)
	for name_part in ["lowerarm_l","lowerarm_r","calf_l","calf_r"]:
		if skeleton.find_bone(name_part)<0: continue
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = name_part
		skeleton.add_child(attachment)
		var wrap := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = (0.105 if kind != "boss" else 0.17)/unit
		cylinder.bottom_radius = cylinder.top_radius*0.92
		cylinder.height = (0.18 if kind != "boss" else 0.28)/unit
		cylinder.radial_segments = 12
		wrap.mesh = cylinder
		wrap.material_override = cloth
		wrap.position.y = cylinder.height*0.65
		attachment.add_child(wrap)

func update_label() -> void:
	health_label.text = display_name + "\n" + str(health) + " / " + str(max_health)
	health_label.modulate = Color("d3c6a3")

func stagger(length: float) -> void:
	if dead: return
	state = "hurt"
	timer = length
	tell.visible = false
	play("hurt")

func receive_hit(amount: int, push: Vector3, heavy := false) -> void:
	if dead: return
	health = maxi(0, health-amount)
	hits_received += 1
	impulse += push * (0.35 if kind == "boss" else 1)
	world.fx.number_at(global_position + Vector3.UP * target_height, amount, Color("e2d0a2"))
	world.hit_feedback(global_position+Vector3.UP*target_height, push.normalized(),heavy)
	update_label()
	if health == 0:
		dead = true
		state = "dead"
		death_time = 3.0
		tell.visible = false
		collision_layer = 0
		collision_mask = 1
		play("dead" if kind == "boss" else "death")
		world.fx.burst(global_position + Vector3.UP * target_height, Color("c4b89b"), true)
		if kind == "boss":
			world.notice("Champion unraveled · R resets all encounters")
			if world.has_method("boss_defeated"): world.boss_defeated()
	elif heavy or (reaction_cooldown<=0 and not (kind=="boss" and state in ["windup","active"])):
		stagger(0.18 if kind=="boss" else 0.32)
		reaction_cooldown=1.4 if kind=="boss" else 0.75

func reset_enemy() -> void:
	dead = false
	health = max_health
	global_position = home
	velocity = Vector3.ZERO
	impulse=Vector3.ZERO
	locomotion_velocity=Vector3.ZERO
	impact_time=0
	reaction_cooldown=0
	safe_velocity=Vector3.ZERO
	navigation_clock=0
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
	timer = (0.6 if kind == "reedhook" else 0.55) if kind != "boss" else [0.85, 0.7, 0.8][combo]
	if kind == "boss" and health < max_health*0.5: timer *= 0.85
	tell.visible = true
	play(("windup" if kind == "reedhook" else "throw_windup") if kind != "boss" else "charge_" + str(combo+1))
	if downloaded:
		var total: float = timer+(0.267 if kind == "reedhook" else (0.32 if kind == "eave" else [0.23,0.23,0.33][combo]))+(0.65 if kind != "boss" else (0.55 if combo < 2 else 1.0))
		animation.speed_scale = animation.current_animation_length/total
	world.audio.play("enemy_swing" if kind != "boss" else "grapple_connect", global_position, -22, 0.75)

func release_attack() -> void:
	state = "active"
	timer = 0.267 if kind == "reedhook" else (0.32 if kind == "eave" else [0.23, 0.23, 0.33][combo])
	hit_delivered = false
	tell.visible = false
	play(("sweep" if kind == "reedhook" else "jump_slash") if kind != "boss" else ["jab", "cross", "smash"][combo])
	world.fx.ring(global_position + Vector3.UP * 0.1, attack_range(), Color("d7996d"), 0.2, 1.6, visual.rotation.y)
	world.audio.play("stomp" if kind == "boss" and combo == 2 else "enemy_swing", global_position, -15, 0.8 if kind == "boss" else 1.1)

func freeze_impact(length: float) -> void:
	if impact_time<=0: impact_animation_speed=animation.speed_scale
	impact_time=maxf(impact_time,length)
	animation.speed_scale=0

func path_direction(destination: Vector3, delta: float) -> Vector3:
	var flat := destination-global_position
	flat.y=0
	if NavigationServer3D.map_get_iteration_id(get_world_3d().navigation_map)==0: return flat.normalized()
	if navigation_clock<=0 or destination.distance_to(path_target)>1.0:
		navigator.target_position=destination
		path_target=destination
		navigation_clock=0.45
	var next := navigator.get_next_path_position()-global_position
	next.y=0
	if navigator.is_navigation_finished(): return Vector3.ZERO
	return next.normalized() if next.length()>0.12 else Vector3.ZERO

func _physics_process(delta: float) -> void:
	if impact_time>0:
		impact_time=maxf(0,impact_time-delta)
		animation.speed_scale=0
		if impact_time<=0: animation.speed_scale=impact_animation_speed
		return
	navigation_clock-=delta
	reaction_cooldown=maxf(0,reaction_cooldown-delta)
	if not is_on_floor(): velocity.y-=delta*19
	desired_motion=Vector3.ZERO
	if dead:
		death_time-=delta
		if death_time<=0: visible=false
	elif ai_enabled:
		timer-=delta
		var difference: Vector3=actor.global_position-global_position
		var flat := Vector3(difference.x,0,difference.z)
		var distance := flat.length()
		match state:
			"idle":
				if not actor.combat.dead and distance<(12 if kind=="boss" else 8.5) and absf(difference.y)<2.5 and world.clear_sight(global_position+Vector3.UP,actor.global_position+Vector3.UP): state="chase"
			"chase":
				if actor.combat.dead or distance>20 or global_position.distance_to(home)>17: state="return"
				elif distance<=attack_range() and absf(difference.y)<1.6 and world.clear_sight(global_position+Vector3.UP,actor.global_position+Vector3.UP):
					combo=0
					begin_attack()
				else:
					desired_motion=path_direction(actor.global_position,delta)*(2.6 if kind=="reedhook" else (3.7 if kind=="eave" else 2.0))
			"windup":
				tell_material.albedo_color.a=0.22
				if timer<=0: release_attack()
			"active":
				var speed := 1.0 if kind=="reedhook" else (5.5 if kind=="eave" else 0.6)
				var ahead := global_position+attack_direction*(body_radius+0.5)
				if not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ahead+Vector3.UP,ahead-Vector3.UP*2,1)).is_empty(): desired_motion=attack_direction*speed
				if not hit_delivered and distance<=attack_range()+0.25 and absf(difference.y)<1.6 and flat.normalized().dot(attack_direction)>0.25 and world.clear_sight(global_position+Vector3.UP,actor.global_position+Vector3.UP):
					hit_delivered=true
					var amount: int=18 if kind=="reedhook" else (13 if kind=="eave" else [16,21,32][combo])
					if actor.combat.receive_hit(amount,global_position,kind=="boss" and combo==2): attacks_connected+=1
				if timer<=0:
					state="recover"
					timer=0.65 if kind!="boss" else (0.55 if combo<2 else 1.0)
					play(("recover" if kind=="reedhook" else "land_recover") if kind!="boss" else "box_recover")
			"recover":
				if timer<=0:
					if kind=="boss" and combo<2 and distance<attack_range()+1.3:
						combo+=1
						begin_attack()
					else: state="chase"
			"hurt":
				if timer<=0: state="chase"
			"return":
				if global_position.distance_to(home)<0.6:
					state="idle"
					play("box_idle" if kind=="boss" else "idle")
				else: desired_motion=path_direction(home,delta)*2.3
	# RVO separates nearby agents; physics remains authoritative at walls and ledges.
	if desired_motion.length()>0.1:
		var probe := global_position+desired_motion.normalized()*(body_radius+0.35)
		if get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(probe+Vector3.UP,probe-Vector3.UP*1.5,1)).is_empty(): desired_motion=Vector3.ZERO
	navigator.velocity=desired_motion
	var wanted := safe_velocity if desired_motion.length()>0.05 and ai_enabled and not dead else Vector3.ZERO
	if state=="active": wanted=desired_motion
	impulse=impulse.move_toward(Vector3.ZERO,delta*8)
	locomotion_velocity=wanted if state=="active" else locomotion_velocity.move_toward(wanted,delta*9)
	velocity.x=locomotion_velocity.x+impulse.x
	velocity.z=locomotion_velocity.z+impulse.z
	if desired_motion.length()>0.1 and state in ["chase","return"]:
		visual.rotation.y=lerp_angle(visual.rotation.y,atan2(desired_motion.x,desired_motion.z),1-exp(-delta*8))
		play("run" if kind!="boss" else "walk")
		animation.speed_scale=clampf(Vector2(velocity.x,velocity.z).length()/(2.8 if kind!="boss" else 2.0),0.65,1.5)
	elif state in ["chase","return"]: play("box_idle" if kind=="boss" else "idle")
	MOTION.move(self,delta)
	if global_position.y< -4: reset_enemy()
