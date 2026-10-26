extends SceneTree
## Actual player interaction, imported skeletal animation and furnished houses.
var failures: Array[String] = []
var checks := 0
var room: Node2D
var captured: Array[String] = []

func _initialize() -> void:
	for folder: String in ["res://Assets/BlueBiome/Characters/SharedTexturesV2", "res://Assets/BlueBiome/Enemies/LoomHeron/Textures", "res://Assets/BlueBiome/Art/LakesideMap", "res://Assets/BlueBiome/Art/Lakeside3D/Models", "res://Assets/BlueBiome/Art/Lakeside3D/Textures", "res://Assets/BlueBiome/Villagers/Models", "res://Assets/BlueBiome/Villagers/Textures"]:
		for filename in DirAccess.get_files_at(folder):
			if not filename.ends_with(".import"):
				continue
			var config := ConfigFile.new()
			if config.load(folder.path_join(filename)) == OK:
				var uid := ResourceUID.text_to_id(config.get_value("remap", "uid", ""))
				if uid != -1 and not ResourceUID.has_id(uid):
					ResourceUID.add_id(uid, folder.path_join(filename.trim_suffix(".import")))
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for index in count:
		await physics_frame

func press_interact() -> void:
	# Captures finish after drawing, when _process has already polled this frame.
	# Inject at the next idle-frame boundary so just_pressed is still current.
	await process_frame
	Input.action_press("interact")
	# Player interaction is polled in _process. Keep the press across idle frames
	# as rendering may advance several physics ticks between visible frames.
	await process_frame
	await process_frame
	Input.action_release("interact")
	await process_frame
	await frames(2)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var file := "res://work/lakeside-villagers/renders/" + label + ".png"
	check(root.get_texture().get_image().save_png(file) == OK, "Save actual rendered villager view")
	captured.append(file)

func focus_resident(label: String) -> void:
	room.focus_landmark(label)
	await frames(25)
	await press_interact()
	await frames(65) # Wait for the approved door walk before placing the NPC fixture.
	var house := room.get_landmark_house(label) as Node2D
	var player := room.get_node("Player") as CharacterBody2D
	check(house.is_player_inside(player), "Enter the house before greeting its resident")
	player.global_position = room.get_interior_landmark_position(label)
	# Door-centered entry no longer deposits the player beyond the exit range.
	# Stand just past that range on the resident's side before testing greetings.
	var door := house.get_node("Door") as Area2D
	var range_shape := door.get_node("Range") as CollisionShape2D
	var player_shape := player.get_node("CollisionShape2D") as CollisionShape2D
	var clearance := range_shape.shape.get_rect().size.x*0.5+player_shape.shape.get_rect().size.x*0.5+4.0
	if absf(player.global_position.x-door.global_position.x)<clearance:
		player.global_position.x = door.global_position.x+clearance
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await frames(35)

func run() -> void:
	room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(20)
	var player = room.get_node("Player")
	for enemy: Node in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	check(get_nodes_in_group("lakeside_villagers").size() == 2, "Both approved villagers are present")
	check(room.get_node("LakesideArtStage").placements.size() == 10, "Villagers share the existing building and lantern render stage")
	for key: String in ["NetMender", "Boatwright"]:
		var npc = room.get_node("Residents/" + key)
		var worker = npc.render_model
		check(is_instance_valid(worker) and worker.animation_player != null, key + " has a real imported animated model")
		check(worker.animation_player.has_animation("worker/WorkIdle") and worker.animation_player.has_animation("worker/TalkIdle"), key + " has both authored clips")
		check(worker.animation_player.current_animation == "worker/WorkIdle", key + " starts at work")
		check(worker.animation_player.get_animation("worker/WorkIdle").loop_mode == Animation.LOOP_LINEAR, key + " work loops")
		check(worker.find_children("*", "CollisionObject3D", true, false).is_empty(), "3D art adds no alternate physics system")
		var painted_skin := false
		var tinted_trousers := false
		for mesh_node: MeshInstance3D in worker.get_node("ActorPivot").find_children("*", "MeshInstance3D", true, false):
			for surface in mesh_node.mesh.get_surface_count():
				var material := mesh_node.get_active_material(surface) as StandardMaterial3D
				if material and material.resource_name.contains("warm skin"):
					painted_skin = material.albedo_texture != null and material.albedo_texture.get_width() == 4096 and not material.vertex_color_use_as_albedo
				if material and material.resource_name.contains("charcoal trouser"):
					tinted_trousers = material.albedo_color.r < .6
		check(painted_skin, key + " preserves authored skin paint in a real 4K imported UV map")
		check(tinted_trousers, key + " preserves the dark trouser tint after export")
		var skeleton := worker.find_child("Skeleton3D", true, false) as Skeleton3D
		if skeleton == null:
			for candidate: Node in worker.find_children("*", "Skeleton3D", true, false):
				skeleton = candidate
		check(skeleton != null and skeleton.get_bone_count() >= 100, key + " retains the humanoid/finger rig")
		if skeleton:
			var wrist := skeleton.find_bone("wrist.R")
			var initial := skeleton.get_bone_global_pose(wrist)
			await frames(22)
			check(not initial.is_equal_approx(skeleton.get_bone_global_pose(wrist)), key + " work animation really moves the hand bones")
		var fixture_transform: Transform3D = worker.get_node("Workstation").global_transform
		await focus_resident("Net mender" if key == "NetMender" else "Boatwright")
		check(player.is_on_floor(), "Player stands on the existing house floor near " + key)
		check(npc._registered and player.current_selector == npc and npc._prompt.visible, "Existing interaction callbacks and prompt select " + key)
		await capture(key + "_in_house_work")
		await press_interact()
		check(worker.interacting and npc._greeting_left > 0, "Normal interact input starts greeting " + key)
		check(worker.animation_player.current_animation == "worker/TalkIdle", key + " lowers the work tool into talk idle")
		await frames(50)
		check(worker.get_node("ActorPivot").rotation.y < -1.4, key + " turns toward a player on the left")
		check(worker.get_node("Workstation").global_transform.is_equal_approx(fixture_transform), key + " leaves its station fixed while turning")
		await capture(key + "_in_house_talk_left")
		player.global_position.x = npc.global_position.x + 90
		player.velocity = Vector2.ZERO
		player.reset_physics_interpolation()
		await frames(60)
		check(worker.get_node("ActorPivot").rotation.y > 1.4, key + " can turn toward a player on the right")
		await press_interact()
		await frames(75)
		check(not worker.interacting and worker.animation_player.current_animation == "worker/WorkIdle", key + " returns to work after a second interaction")
		check(absf(worker.get_node("ActorPivot").rotation.y) < .05, key + " returns to the work orientation")
		npc.greeting_seconds = 1.0
		await press_interact()
		await frames(135)
		check(not worker.interacting and worker.animation_player.current_animation == "worker/WorkIdle", key + " also resumes after the greeting timer")
		npc.greeting_seconds = 6.0
		await press_interact()
		room.focus_landmark("Shore")
		await frames(70)
		check(not npc._prompt.visible and not worker.interacting and not npc._registered, "Leaving " + key + " releases interaction and resumes work")
		npc.show_workstation = false
		await frames(2)
		check(not worker.get_node("Workstation").visible, key + " can be used as a standalone villager")
		npc.show_workstation = true

	# A wall between player and NPC prevents greeting through the wall.
	await focus_resident("Net mender")
	var mender = room.get_node("Residents/NetMender")
	# Use the spacious right-hand approach for this independent wall-ray test.
	player.global_position.x = mender.global_position.x+90
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await frames(5)
	var blocker := StaticBody2D.new()
	blocker.position = mender.global_position + Vector2(45, -65)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(5, 125)
	collider.shape = shape
	blocker.add_child(collider)
	room.add_child(blocker)
	await frames(5)
	check(not mender._prompt.visible and not mender._registered, "House walls block interaction prompts and selection")
	blocker.queue_free()
	await frames(5)
	check(mender._prompt.visible and mender._registered, "Interaction becomes available when the obstruction clears")

	# Separate furniture prefabs can be instanced without another NPC.
	for scene_path: String in ["net_mending_station_2d.tscn", "boatwright_bench_2d.tscn"]:
		var prop = load("res://Src/Environment/BlueBiome/Villagers/" + scene_path).instantiate()
		prop.position = Vector2(20000, 20000)
		room.add_child(prop)
		await frames(3)
		check(is_instance_valid(prop.render_model), "Standalone furniture prefab registers with the shared stage")
		prop.queue_free()
		await frames(2)

	if DisplayServer.get_name() != "headless":
		var camera := player.get_node("Camera2D") as Camera2D
		camera.zoom = Vector2.ONE * 2.5
		await focus_resident("Net mender")
		for index in 7:
			await frames(8)
			await capture("greeting_%02d" % index)
		await press_interact()
		for index in range(7, 20):
			await frames(7)
			await capture("greeting_%02d" % index)
		await press_interact()
		for index in range(20, 31):
			await frames(7)
			await capture("greeting_%02d" % index)
		camera.zoom = Vector2.ONE * .9

	var report := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "display": DisplayServer.get_name(), "godot": Engine.get_version_info().string, "rendered": captured}
	FileAccess.open("res://work/lakeside-villagers/verification_" + DisplayServer.get_name() + ".json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("LAKESIDE_VILLAGERS ", JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures}))
	room.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
