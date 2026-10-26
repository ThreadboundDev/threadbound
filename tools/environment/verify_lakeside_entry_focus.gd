extends SceneTree
const OUT := "res://work/lakeside-door-exit-2026-10-26"
var room: Node2D
var failures: Array[String] = []
var checks := 0
var captures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("ENTRY_FOCUS_FAIL "+message)
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count: await physics_frame
func camera_state(camera: Camera2D) -> Array:
	return [camera.position,camera.zoom,camera.limit_left,camera.limit_top,camera.limit_right,camera.limit_bottom]
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT.path_join(label+".png"))==OK,"Saved "+label)
	captures.append(label)
func press() -> void:
	await process_frame
	Input.action_press("interact")
	await process_frame
	Input.action_release("interact")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	room = load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(30)
	var player: CharacterBody2D = room.get_node("Player")
	var visual = player.get_node("Live3DVisual")
	var camera: Camera2D = player.get_node("Camera2D")
	var art = room.get_node("ArtComparison")
	for enemy in get_nodes_in_group("enemies"): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for painted in [true,false]:
		art.set_all(painted)
		for label: String in ["Fisher house","Workshop"]:
			room.focus_landmark(label)
			await frames(35)
			var house = room.get_landmark_house(label)
			var initial := camera_state(camera)
			var health: float = player.health_component.current_health
			var outside := player.global_position
			var entering_x: float = house.get_node("Door").global_position.x
			await press()
			await frames(5)
			check(house._transition_locked and player.house_door_transition_owner==house,"Actual Interact starts owned door transition")
			check(not house.is_player_inside(player),"Turn/walk precedes cutaway reveal")
			Input.action_press("move_right")
			Input.action_press("Jump")
			await frames(10)
			check(absf(player.global_position.x-entering_x)<0.1,"Door transition blocks movement/jump and retains actual door x")
			check(absf(visual._model_root.rotation.y)>0.5,"Live model turns away from camera")
			check(house.door_visual.opening>0.25,"Door panels open during walk")
			await capture(("painted_" if painted else "models_")+label.to_snake_case()+"_entering")
			Input.action_release("move_right")
			Input.action_release("Jump")
			await frames(60)
			check(house.is_player_inside(player) and player.is_on_floor(),"Animated entry settles inside")
			check(absf(player.global_position.x-entering_x)<0.1,"Inside position stays at door, not offset InsideSpawn")
			check(not is_instance_valid(player.house_door_transition_owner) and not visual._door_active,"Input and normal visuals resume after door animation")
			check(house.door_visual.indoors and is_equal_approx(house.door_visual.threshold,house.floor_bounds().position.y-house.get_node("Door").global_position.y),"Amber exit marker sits at active door and floor")
			check(camera.zoom.x>initial[1].x and house.interior_focus.weight==1.0,"Camera smoothly reaches house focus")
			check(player.health_component.current_health==health,"Door transition preserves health")
			await capture(("painted_" if painted else "models_")+label.to_snake_case()+"_inside")
			if painted and label=="Fisher house" and DisplayServer.get_name()!="headless":
				house.interior_focus.set_process(false)
				house.interior_focus.effect.material.set_shader_parameter("focus_strength",0.0)
				await process_frame
				await RenderingServer.frame_post_draw
				var unmasked := root.get_texture().get_image()
				house.interior_focus.effect.material.set_shader_parameter("focus_strength",1.0)
				await process_frame
				await RenderingServer.frame_post_draw
				var masked := root.get_texture().get_image()
				var before := unmasked.get_pixel(40,500)
				var after := masked.get_pixel(40,500)
				check(after.get_luminance()<before.get_luminance()*.65,"Rendered exterior dims outside occupied room")
				check(room.get_node("HUD").layer>house.interior_focus.overlay.layer,"HUD renders after house focus")
				var hud_before := unmasked.get_pixel(400,158)
				var hud_after := masked.get_pixel(400,158)
				check(absf(hud_after.r-hud_before.r)<.02 and absf(hud_after.g-hud_before.g)<.02 and absf(hud_after.b-hud_before.b)<.02,"Opaque health-bar pixels remain outside focus treatment")
				house.interior_focus.set_process(true)
			var scale_before := root.content_scale_size
			root.content_scale_size = Vector2i(1280,720)
			await frames(12)
			check(camera.zoom.is_finite() and camera.limit_left<camera.limit_right,"House framing survives window content resize")
			root.content_scale_size = scale_before
			await frames(12)
			await press()
			await frames(15)
			check(visual._door_active and not visual._door_entering,"Exit uses outward door travel")
			# Frontal yaw must oppose entry in every house/art mode.
			check(is_equal_approx(sin(visual._model_root.rotation.y),-1.0),"Exiting model faces toward camera instead of repeating entry")
			await capture(("painted_" if painted else "models_")+label.to_snake_case()+"_exiting")
			await frames(65)
			check(not house.is_player_inside(player) and not house._transition_locked,"Animated exit completes once")
			check(player.global_position.distance_to(outside)<1.0,"Exit returns to the same exterior doorway")
			check(camera_state(camera)==initial,"Outdoor camera position, zoom and limits restore exactly")
			check(not house.door_visual.indoors and not visual._door_active,"Exit cue/visual transition are released outdoors")
	# Interrupt before the interior switch: an external debug teleport must win.
	room.focus_landmark("Fisher house")
	await frames(35)
	var house = room.get_landmark_house("Fisher house")
	await press()
	await frames(8)
	room.focus_landmark("Shore")
	var at := player.global_position
	await frames(3)
	check(not house._transition_locked and not is_instance_valid(player.house_door_transition_owner),"Mid-entry teleport releases the input lock")
	# The normal controller may depenetrate against shore terrain after release.
	check(absf(player.global_position.x-at.x)<2.0 and not house.is_player_inside(player),"Interrupted animation cannot pull a teleported player back (x error %.3f)" % absf(player.global_position.x-at.x))
	room.focus_landmark("Workshop")
	await frames(35)
	house = room.get_landmark_house("Workshop")
	await press()
	await frames(8)
	player.set("is_dead",true)
	await frames(3)
	check(not house._transition_locked and not is_instance_valid(player.house_door_transition_owner),"Death during entry releases transition and input ownership")
	player.set("is_dead",false)
	room.focus_landmark("Fisher house")
	await frames(35)
	house = room.get_landmark_house("Fisher house")
	await press()
	await frames(8)
	house.get_parent().remove_child(house)
	house.queue_free()
	await frames(3)
	check(not is_instance_valid(player.house_door_transition_owner) and not visual._door_active,"Removing a house during entry releases player/visual locks")
	var report := {"checks":checks,"failures":failures,"captures":captures,"display":DisplayServer.get_name()}
	FileAccess.open(OUT.path_join("house_focus.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("LAKESIDE_ENTRY_FOCUS ",JSON.stringify(report))
	room.queue_free()
	await frames(2)
	quit(1 if failures.size() else 0)
