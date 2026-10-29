extends "res://scripts/study_world.gd"
const FX = preload("res://scripts/study_fx.gd")
const AUDIO = preload("res://scripts/study_audio.gd")
const ENEMY = preload("res://scripts/study_enemy.gd")
const HUD = preload("res://scripts/study_hud.gd")
var fx
var audio
var boss
var hud_layer
var notification_text := ""
var notification_time := 0.0
var anchors: Array[Node3D] = []
var reset_serial := 0
var shutting_down := false
var navigation: NavigationRegion3D
var feedback_hits := 0

func hit_feedback(point: Vector3, direction: Vector3, heavy: bool, armor := false) -> void:
	feedback_hits+=1
	fx.burst(point,Color("aacbd3") if armor else Color("f3dfad"),heavy and not armor)
	var mark: Node3D=fx.ring(point,0.16 if not heavy else 0.28,Color("e9d7ac"),0.14)
	if direction.length()>0.1: mark.quaternion=Quaternion(Vector3.UP,direction.normalized())
	audio.play("armor" if armor else "contact",point,-14 if armor else (-10 if heavy else -14),.9 if heavy else 1.08)
	if heavy and not armor: audio.play("stomp",point,-21,.78)
	for device in Input.get_connected_joypads(): Input.start_joy_vibration(device,0.15,0.35 if heavy else 0.2,0.08)

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(shutdown)
	fx = FX.new()
	add_child(fx)
	audio = AUDIO.new()
	add_child(audio)
	super._ready()
	platform_route()
	arena()
	spawn_enemy("reedhook", Vector3(-6.5, 0.2, 10))
	spawn_enemy("eave", Vector3(4, 0.2, 14))
	spawn_enemy("reedhook", Vector3(-19,0.1,-11),true)
	spawn_enemy("eave", Vector3(23,0.1,-1))
	boss = spawn_enemy("boss", Vector3(22, 0.3, 12))
	# Low approach ramps remove accidental porch/bridge lips from the movement test.
	ramp(Vector3(0, 0.03, -4.5), Vector3(0, 0.23, -5.7), 2.0)
	ramp(Vector3(8.3, 0.03, 2.5), Vector3(9.6, 0.26, 2.5), 2.4)
	ramp(Vector3(15.4, 0.26, 2.5), Vector3(16.7, 0.03, 2.5), 2.4)
	build_navigation()
	sign_at("Training clearing\nWoven sentinels", Vector3(-1, 1.4, 9.0))
	sign_at("Guardian clearing\nAcross the stream", Vector3(7.3, 1.5, 4.4))
	notice("H for controls · R resets all encounters · E grapples any solid surface")
	if "--capture-action" in OS.get_cmdline_user_args(): call_deferred("capture_playtest")

func configure_inputs() -> void:
	super.configure_inputs()
	for item in [["dash", KEY_CTRL], ["special", KEY_Q], ["grapple", KEY_E], ["lock", KEY_TAB], ["help", KEY_H], ["mute", KEY_M], ["descend", KEY_C], ["meditate", KEY_F], ["air_up", KEY_X]]:
		if not InputMap.has_action(item[0]): InputMap.add_action(item[0])
		var event := InputEventKey.new()
		event.physical_keycode = item[1]
		InputMap.action_add_event(item[0], event)
	var up_event:=InputEventJoypadButton.new()
	up_event.button_index=JOY_BUTTON_DPAD_LEFT
	InputMap.action_add_event("air_up",up_event)
	for item in [["attack", MOUSE_BUTTON_LEFT], ["block", MOUSE_BUTTON_RIGHT]]:
		if not InputMap.has_action(item[0]): InputMap.add_action(item[0])
		var event := InputEventMouseButton.new()
		event.button_index = item[1]
		InputMap.action_add_event(item[0], event)
	for item in [["dash", JOY_BUTTON_B], ["special", JOY_BUTTON_X], ["grapple", JOY_BUTTON_RIGHT_SHOULDER], ["lock", JOY_BUTTON_RIGHT_STICK], ["release_mouse", JOY_BUTTON_START], ["descend", JOY_BUTTON_LEFT_STICK], ["meditate", JOY_BUTTON_DPAD_DOWN]]:
		var event := InputEventJoypadButton.new()
		event.button_index = item[1]
		InputMap.action_add_event(item[0], event)
	for item in [["attack", JOY_AXIS_TRIGGER_RIGHT], ["block", JOY_AXIS_TRIGGER_LEFT]]:
		var event := InputEventJoypadMotion.new()
		event.axis = item[1]
		event.axis_value = 1
		InputMap.action_add_event(item[0], event)

func hud() -> void:
	hud_layer = HUD.new()
	add_child(hud_layer)

func foliage() -> void:
	super.foliage()
	for plant in get_tree().get_nodes_in_group("study_foliage"):
		var point: Vector3 = plant.global_position
		point.y = 0
		if plant.has_meta("is_tree"):
			box("TreeTrunkContact", point+Vector3.UP*0.85, Vector3(0.3, 1.7, 0.3), palette.wood, true, false)
			for mesh in plant.find_children("*", "MeshInstance3D", true, false):
				mesh.create_trimesh_collision()
				for child in mesh.get_children():
					if child is StaticBody3D:
						child.collision_layer = 1
						child.collision_mask = 0

func foliage_position_allowed(point: Vector3) -> bool:
	if point.distance_to(Vector3(22,0,12)) < 12 or point.distance_to(Vector3(-6.5,0,10)) < 4 or point.distance_to(Vector3(4,0,14)) < 4: return false
	for house in [Vector3(-17,0,4),Vector3(-9,0,-16),Vector3(22,0,-12)]:
		if point.distance_to(house)<6.5: return false
	for landing in [Vector3(-9,0,-1), Vector3(-13,0,-5), Vector3(-16,0,-10), Vector3(-9,0,-16), Vector3(1,0,-17), Vector3(19,0,-10)]:
		if point.distance_to(landing) < 7.0: return false
	return true

func notice(text: String) -> void:
	notification_text = text
	notification_time = 4.0

func clear_sight(a: Vector3, b: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(a, b, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func spawn_enemy(kind: String, point: Vector3, armored := false):
	var enemy = ENEMY.new()
	enemy.kind = kind
	enemy.armored=armored
	enemy.position = point
	enemy.name = kind.capitalize()
	add_child(enemy)
	return enemy

func reset_playtest() -> void:
	reset_serial += 1
	actor.reset_to_spawn()
	for enemy in get_tree().get_nodes_in_group("study_enemies"): enemy.reset_enemy()
	fx.clear()
	notice("Clearing reset · Health and AP restored · All enemies returned")

func shutdown() -> void:
	if shutting_down: return
	shutting_down = true
	var tree := get_tree()
	tree.paused = false
	tree.create_timer(0.05).timeout.connect(tree.quit)
	queue_free()

func sign_at(text: String, at: Vector3) -> void:
	box("SignPost",Vector3(at.x,at.y*0.5,at.z),Vector3(0.08,at.y,0.08),palette.wood,true)
	box("CarvedWaymarker",at,Vector3(2.15,0.56,0.08),palette.wood,true)
	var label := Label3D.new()
	label.text = text
	label.position = at+Vector3(0,0,0.05)
	label.font_size = 26
	label.pixel_size = 0.003
	label.modulate = Color("d9c8a1")
	add_child(label)

func ramp(a: Vector3, b: Vector3, width: float) -> void:
	var node := box("ApproachRamp", (a+b)*0.5-Vector3.UP*0.05, Vector3(width, 0.1, a.distance_to(b)), palette.planks, true)
	node.look_at(b, Vector3.UP)

func thread_ring(at: Vector3, radius: float, vertical := false) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = at
	for i in range(3):
		var instance := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = radius-0.025
		mesh.outer_radius = radius+0.025
		mesh.rings = 32
		mesh.ring_segments = 6
		instance.mesh = mesh
		instance.material_override = fx.glow(Color("c6b78b") if i != 1 else Color("6f9fa9"))
		instance.position.y = (i-1)*0.035
		root.add_child(instance)
	if vertical: root.rotation.x = PI/2
	return root

func anchor(label: String, point: Vector3, landing: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = label
	marker.position = point
	marker.set_meta("landing", landing+Vector3.UP*0.45)
	marker.add_to_group("study_anchors")
	add_child(marker)
	thread_ring(point, 0.43, true)
	anchors.append(marker)
	var thread: MeshInstance3D = fx.strand(point+Vector3.UP*0.45, point+Vector3.UP*0.8, Color("bdae88"), 0.018)
	thread.name = "AnchorSuspension"
	var landing_marker := Marker3D.new()
	landing_marker.position = landing
	landing_marker.add_to_group("study_checkpoints")
	add_child(landing_marker)
	thread_ring(landing+Vector3.UP*0.025, 0.6)
	box("ThreadPost", landing+Vector3(1.3, 1.8, 0), Vector3(0.15, 3.6, 0.15), palette.wood)
	box("AnchorCrossbeam",landing+Vector3(0.65,3.6,0),Vector3(1.6,0.14,0.15),palette.wood,true)
	var knot := StaticBody3D.new()
	knot.position = point
	add_child(knot)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.16
	shape.shape = sphere
	knot.add_child(shape)
	box("IndigoWaymarker", landing+Vector3(1.3, 1.75, 0), Vector3(0.7, 0.65, 0.05), palette.indigo)
	for i in range(3):
		box("WaymarkerStitch", landing+Vector3(1.3, 1.58+i*0.13, 0.032), Vector3(0.25, 0.025, 0.012), palette.flax)

func platform_route() -> void:
	var route := [Vector3(-9, 0.7, -1), Vector3(-13, 1.9, -5), Vector3(-16, 3.1, -10), Vector3(-9, 4.6, -16), Vector3(1, 4.4, -17), Vector3(19, 3.5, -10)]
	for i in range(route.size()):
		var point: Vector3 = route[i]
		var platform := box("ThreadmarkedPlatform"+str(i), Vector3(point.x, point.y/2, point.z), Vector3(3.3, point.y, 3.4), palette.stone, true, false)
		for x in [-1.45,1.45]:
			for z in [-1.45,1.45]: box("ScaffoldUpright",Vector3(point.x+x,point.y/2,point.z+z),Vector3(0.15,point.y,0.15),palette.wood,true)
		for j in range(9): box("ScaffoldDeck",point+Vector3(-1.45+j*0.36,-0.07,0),Vector3(0.33,0.14,3.4),palette.planks)
		box("WovenLanding", point+Vector3.UP*0.035, Vector3(2.4, 0.07, 2.5), palette.indigo)
		for j in range(7):
			box("LandingWeft", point+Vector3(-1.05+j*0.35, 0.077, 0), Vector3(0.025, 0.008, 2.3), palette.flax)
		anchor("Thread Ring " + str(i+1), point+Vector3.UP*2.8, point+Vector3.UP*0.08)
	sign_at("THREADMARKED RISE\nJump · Dash · Grapple", Vector3(-6.3, 1.6, -1.2))
	# Intermediate jumping stones make the first rise usable without a grapple.
	box("FirstStep", Vector3(-6.7, 0.2, -0.1), Vector3(1.3, 0.4, 1.4), palette.stone, true)

func arena() -> void:
	var fill := OmniLight3D.new()
	fill.position = Vector3(22, 4.5, 11)
	fill.omni_range = 11
	fill.light_color = Color("b6c7c4")
	fill.light_energy = 0.5
	add_child(fill)
	var stage := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 5.0
	mesh.bottom_radius = 5.2
	mesh.height = 0.14
	mesh.radial_segments = 48
	stage.mesh = mesh
	stage.material_override = palette.stone
	stage.position = Vector3(22, 0.02, 12)
	add_child(stage)
	stage.create_trimesh_collision()
	thread_ring(Vector3(22, 0.1, 12), 4.85)
	for i in range(4):
		var angle := i*TAU/4+PI/4
		var point := Vector3(22+cos(angle)*5.2, 0, 12+sin(angle)*5.2)
		box("ArenaLoomPost", point+Vector3.UP*1.4, Vector3(0.18, 2.8, 0.18), palette.wood)
		box("ArenaBanner", point+Vector3(0, 2.0, 0), Vector3(0.7, 0.9, 0.06), palette.indigo)
		for j in range(3):
			box("BannerStitch", point+Vector3(0, 1.75+j*0.2, 0.04), Vector3(0.4, 0.025, 0.015), palette.flax)

func capture() -> void:
	call_deferred("capture_playtest")

func capture_playtest() -> void:
	for enemy in get_tree().get_nodes_in_group("study_enemies"): enemy.ai_enabled = false
	for i in range(40): await get_tree().process_frame
	var mode := "action" if "--capture-action" in OS.get_cmdline_user_args() else ("combat" if "--capture-study" in OS.get_cmdline_user_args() else "traversal")
	if mode == "combat":
		actor.global_position = Vector3(21, 0.2, 7)
		actor.yaw = PI
		actor.visual.rotation.y = 0
		actor.distance = 6.4
		actor.lock_target = boss
		boss.visual.rotation.y = PI
	elif mode == "traversal":
		actor.global_position = Vector3(-5, 0.3, 3)
		actor.yaw = 0.35
		actor.pitch = -0.25
		actor.distance = 7.0
	else:
		actor.global_position = Vector3(-5, 0.15, 10)
		actor.yaw = PI
		actor.visual.rotation.y = 0
		actor.pitch = -0.3
		actor.distance = 6.5
		for enemy in get_tree().get_nodes_in_group("study_enemies"):
			if enemy.kind == "reedhook": enemy.global_position = Vector3(-5,0.2,12.3)
			if enemy.kind == "eave": enemy.global_position = Vector3(-3,0.2,12.3)
			var direction: Vector3 = actor.global_position-enemy.global_position
			enemy.visual.rotation.y = atan2(direction.x,direction.z)
	for i in range(40): await get_tree().process_frame
	if mode == "action":
		actor.combat.special(false)
		for i in range(30): await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://captures")
	get_viewport().get_texture().get_image().save_png("res://captures/playtest_"+mode+".png")
	print("PLAYTEST_CAPTURE_SAVED ", mode)
	shutdown()

func is_swimming(point: Vector3) -> bool:
	return point.x > 10 and point.x < 15 and absf(point.z) < 28 and point.y < -0.65

func build_navigation() -> void:
	add_to_group("study_nav_geometry")
	if is_instance_valid(navigation):
		remove_child(navigation)
		navigation.queue_free()
	navigation = NavigationRegion3D.new()
	var nav := NavigationMesh.new()
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = 1
	nav.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav.geometry_source_group_name = "study_nav_geometry"
	nav.cell_size = 0.25
	nav.cell_height = 0.25
	nav.agent_height = 2.0
	nav.agent_radius = 1.0
	nav.agent_max_climb = 0.25
	nav.filter_baking_aabb = AABB(Vector3(-30,-4,-26),Vector3(64,13,54))
	navigation.navigation_mesh = nav
	add_child(navigation)
	navigation.bake_navigation_mesh(false)
