extends SceneTree
## Read-only runtime audit. Never saves a scene or changes project resources.
const OUT := "res://tmp/scale-vfx-study"
const PLAYER := "res://Src/Characters/Player/player.tscn"
var report := {}

func _initialize() -> void:
	call_deferred("run")

func settle(count := 8) -> void:
	for i in count: await process_frame
	await RenderingServer.frame_post_draw

func rect_array(r: Rect2) -> Array:
	return [r.position.x, r.position.y, r.size.x, r.size.y]

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var mode := "fixture"
	for arg in OS.get_cmdline_user_args():
		if arg in ["blue", "demo"]: mode = arg
	var stage: Node2D
	var player
	if mode == "fixture":
		stage = Node2D.new()
		root.add_child(stage)
		player = load(PLAYER).instantiate()
		stage.add_child(player)
		var cam := Camera2D.new()
		cam.position = Vector2(0, -70)
		stage.add_child(cam)
		cam.make_current()
	else:
		var path := "res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn" if mode == "blue" else "res://Src/Environment/World/Chamber Of The First Weave.tscn"
		stage = load(path).instantiate()
		stage.tree_entered.connect(func(): current_scene = stage, CONNECT_ONE_SHOT)
		root.add_child(stage)
		player = stage.get_node("Player")
	current_scene = stage
	player.set_physics_process(false)
	if mode == "demo":
		var welcome = stage.get_node_or_null("PlaytestWelcome")
		if is_instance_valid(welcome) and not welcome.is_queued_for_deletion():
			await welcome._begin_demo()
	await settle(20)
	for layer in root.find_children("*","CanvasLayer",true,false):
		if layer.get_script() and String(layer.get_script().resource_path).ends_with("tutorial_prompt_overlay.gd"):
			layer.hide()
	player.set_process(false)
	var visual = player.live_3d_visual
	visual.set_process(false)
	var animator: AnimationPlayer = visual._animation_player
	for other in player.find_children("*", "AnimationPlayer", true, false):
		if other != animator: other.pause()
	var meshes := []
	for mesh in visual._model_root.find_children("*", "MeshInstance3D", true, false):
		meshes.append(String(mesh.name))
	var camera := root.get_camera_2d()
	report = {"mode":mode, "viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "zoom":[camera.zoom.x,camera.zoom.y], "meshes":meshes, "poses":{}, "display_scale":[visual._display.scale.x,visual._display.scale.y], "display_position":[visual._display.position.x,visual._display.position.y]}
	for action in ["Idle", "Run"]:
		var action_key: StringName = &"idle_4" if action == "Idle" else &"run_1"
		visual._play_action(action_key, &"", 0.0, true, 1.0, 0.0)
		animator.seek(0.2, true)
		animator.advance(0.0)
		animator.pause()
		visual._process(0.0)
		await settle()
		var image: Image = visual._viewport.get_texture().get_image()
		image.save_png(OUT + "/" + mode + "_" + action.to_lower() + "_all.png")
		var hidden := []
		for mesh in visual._model_root.find_children("*", "MeshInstance3D", true, false):
			if mesh.name != &"Threadborne_Character":
				hidden.append(mesh)
				mesh.hide()
		await settle()
		image = visual._viewport.get_texture().get_image()
		var used := image.get_used_rect()
		image.save_png(OUT + "/" + mode + "_" + action.to_lower() + "_body.png")
		var world_height: float = used.size.y * visual._display.scale.y
		var corner: Vector2 = visual._display.get_global_transform_with_canvas()*(visual._display.get_rect().position+Vector2(used.position))
		var end: Vector2 = visual._display.get_global_transform_with_canvas()*(visual._display.get_rect().position+Vector2(used.end))
		report.poses[action] = {"body_used_rect":rect_array(Rect2(used)), "screen_body_rect":rect_array(Rect2(corner,end-corner).abs()), "world_height":world_height, "screen_height":world_height*camera.zoom.y, "screen_fraction":world_height*camera.zoom.y/root.get_visible_rect().size.y, "clip":String(animator.assigned_animation), "time":animator.current_animation_position}
		for mesh in hidden: mesh.show()
		await settle()
		root.get_texture().get_image().save_png(OUT + "/" + mode + "_" + action.to_lower() + "_screen.png")
		if mode == "blue" and action == "Idle":
			camera.zoom = Vector2(0.83,0.83)
			await settle()
			root.get_texture().get_image().save_png(OUT + "/blue_idle_zoom_083.png")
			camera.zoom = Vector2(0.9,0.9)
	if mode == "blue":
		var house = stage.get_node("Buildings/FisherHouse")
		var data := []
		for mesh: MeshInstance3D in house.render_model.find_children("*", "MeshInstance3D", true, false):
			if "door" in String(mesh.name).to_lower():
				data.append({"name":String(mesh.name), "aabb_size":[mesh.get_aabb().size.x,mesh.get_aabb().size.y,mesh.get_aabb().size.z], "global_scale":[mesh.global_basis.get_scale().x,mesh.global_basis.get_scale().y,mesh.global_basis.get_scale().z]})
		report.house_door_meshes = data
		visual._play_action(&"idle_4", &"", 0.0, true, 1.0, 0.0)
		animator.seek(0.2, true)
		animator.advance(0.0)
		animator.pause()
		visual._process(0.0)
		player.global_position = house.get_node("Door").global_position - Vector2(100,visual._display.position.y)
		camera.enabled = false
		var house_camera := Camera2D.new()
		house_camera.position = house.global_position + Vector2(0,-400)
		house_camera.zoom = Vector2(0.9,0.9)
		stage.add_child(house_camera)
		house_camera.make_current()
		await settle(20)
		root.get_texture().get_image().save_png(OUT + "/blue_house_screen.png")
	if mode == "fixture":
		animator.stop()
		visual._skeleton.clear_bones_global_pose_override()
		visual._skeleton.reset_bone_poses()
		visual._model_root.position.y = 0.0
		for mesh in visual._model_root.find_children("*", "MeshInstance3D", true, false):
			if mesh.name != &"Threadborne_Character": mesh.hide()
		await settle()
		var rest_image: Image = visual._viewport.get_texture().get_image()
		rest_image.save_png(OUT+"/fixture_rest_body.png")
		report.rest_body_used_rect = rect_array(Rect2(rest_image.get_used_rect()))
	FileAccess.open(OUT + "/" + mode + "_measurement.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SCALE_AUDIT ", JSON.stringify(report))
	stage.queue_free()
	await process_frame
	await process_frame
	quit()
