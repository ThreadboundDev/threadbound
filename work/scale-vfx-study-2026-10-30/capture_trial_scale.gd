extends SceneTree
## Run against the preserved, separate 3D project. No scene/resource writes.
var out := ""
func _initialize() -> void: call_deferred("run")
func settle(n := 8) -> void:
	for i in n: await physics_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	out = OS.get_environment("THREADBOUND_SCALE_OUT")
	if out.is_empty():
		push_error("Set THREADBOUND_SCALE_OUT to the repository's tmp/scale-vfx-study directory")
		quit(1)
		return
	var world = load("res://scenes/loom_crossing_trial.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	world.hud_layer.close_dialogue()
	for enemy in get_nodes_in_group("study_enemies"): enemy.ai_enabled = false
	await settle(45)
	world.actor.set_physics_process(false)
	world.actor.animation.pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await settle()
	root.get_texture().get_image().save_png(out + "/trial_spawn_screen.png")
	var report := {"viewport":[root.size.x,root.size.y],"camera_fov":world.actor.camera.fov, "camera_spring_length":world.actor.arm.get_hit_length(),"capsule_height":1.9,"props":[]}
	for node in world.get_children():
		if node is Node3D and (String(node.name) == "WorkingVillageWorkshop" or node.position.distance_to(Vector3(-15,0,13)) < 0.1):
			var bounds: AABB = world.model_bounds(node)
			report.props.append({"name":String(node.name),"world_height":bounds.size.y*node.scale.y,"scale":[node.scale.x,node.scale.y,node.scale.z]})
	var body: MeshInstance3D = world.actor.model.find_child("Threadborne_Character",true,false)
	if body:
		report.body_rest_aabb_height = body.get_aabb().size.y*body.global_basis.get_scale().y
	var view := SubViewport.new()
	view.size = root.size
	view.own_world_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var copy: Node3D = world.actor.visual.duplicate()
	view.add_child(copy)
	copy.global_transform = world.actor.visual.global_transform
	for mesh in copy.find_children("*","MeshInstance3D",true,false):
		if mesh.name != &"Threadborne_Character": mesh.hide()
	var cam := Camera3D.new()
	view.add_child(cam)
	cam.global_transform = world.actor.camera.global_transform
	cam.fov = world.actor.camera.fov
	cam.current = true
	var light := DirectionalLight3D.new()
	view.add_child(light)
	light.rotation_degrees = Vector3(-35,-30,0)
	await settle(8)
	var image := view.get_texture().get_image()
	var used := image.get_used_rect()
	image.save_png(out + "/trial_spawn_body.png")
	report.projected_body_rect = [used.position.x,used.position.y,used.size.x,used.size.y]
	report.body_screen_fraction = float(used.size.y)/view.size.y
	FileAccess.open(out + "/trial_measurement.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("TRIAL_SCALE ",JSON.stringify(report))
	view.queue_free()
	world.queue_free()
	await process_frame
	quit()
