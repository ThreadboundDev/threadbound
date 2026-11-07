extends SceneTree
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	root.add_child(player)
	for frame in 4:
		await physics_frame
	player.set_physics_process(false)
	var visual = player.get_node("Live3DVisual")
	visual.set_process(false)
	var manager := root.get_node("EquipManager")
	for outfit in [0, 3]:
		for slot in 3:
			if manager.current_equip[slot] != outfit+slot:
				manager.equip_item(outfit+slot)
		for node in visual._model_root.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh.get_meta("outline_only", false):
				continue
			var shell := mesh.get_node_or_null("ObjectOutline") as MeshInstance3D
			check(shell != null, "Each model part has an independent outline")
			if shell:
				check(shell.skin == mesh.skin, "Outline keeps its parent skin")
				var detail := .22 if String(mesh.name).begins_with("Shared_Wooden_Hands") else (.35 if "Grapple" in String(mesh.name) else 1.0)
				check(is_equal_approx(shell.material_override.get_shader_parameter("outline_source_pixels"), detail*2.0/visual.display_scale.x), "Outline width follows its stable object profile")
			for surface in mesh.mesh.get_surface_count():
				var mat := mesh.get_active_material(surface) as StandardMaterial3D
				if mat:
					check(mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "Opaque model front occludes outline shell")
		for action: StringName in [&"idle_4", &"idle_2", &"run_1", &"casting_2"]:
			visual._play_action(action, &"", 0, true, 1, 0)
			visual._animation_player.seek(.35, true)
			visual._animation_player.advance(0)
			visual._animation_player.pause()
			if DisplayServer.get_name() != "headless":
				await process_frame
				await RenderingServer.frame_post_draw
				visual._viewport.get_texture().get_image().save_png("res://LocalOnly/Equipment/FeedbackReview2026_11_07/outline_%d_%s.png" % [outfit, action])
	var cached: int = visual._outline_mesh_cache.size()
	for repeat in 3:
		for outfit in [0,3]:
			for slot in 3:
				if manager.current_equip[slot] != outfit+slot:
					manager.equip_item(outfit+slot)
			await process_frame
	check(visual._outline_mesh_cache.size()==cached,"Repeated swaps reuse cached outline geometry")
	if DisplayServer.get_name() != "headless":
		await verify_depth_and_width(visual)
	for property: StringName in [&"current_boots", &"current_chest"]:
		var ability: Node = player.get(property)
		if is_instance_valid(ability) and ability.get_parent() == null:
			ability.free()
		player.set(property, null)
	print("OBJECT_OUTLINES ", JSON.stringify({"checks":checks,"failures":failures}))
	player.queue_free()
	await process_frame
	await process_frame
	call_deferred("quit", 0 if failures.is_empty() else 1)


func verify_depth_and_width(visual: Node) -> void:
	# A controlled blade/body crossing makes depth and pixel widths measurable.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256,256)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.0
	camera.position.z = 5
	viewport.add_child(camera)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.WHITE
	viewport.add_child(environment)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6,.8,.05)
	body.mesh = box
	viewport.add_child(body)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(.2,.5,.8)
	body.material_override = material
	var blade := MeshInstance3D.new()
	box = BoxMesh.new()
	box.size = Vector3(.4,1.5,.05)
	blade.mesh = box
	blade.position.z = .2
	viewport.add_child(blade)
	material = material.duplicate()
	material.albedo_color = Color(.9,.8,.5)
	blade.material_override = material
	visual._install_object_outline(body,3.0)
	visual._install_object_outline(blade,3.0)
	for size in [2.0,1.6]:
		camera.size = size
		blade.position.z = .2
		await process_frame
		await RenderingServer.frame_post_draw
		var front := viewport.get_texture().get_image()
		var edge := roundi(128+.2*256/size)
		var inside := roundi(128-.2*256/size)
		var outside := roundi(128-.6*256/size)
		var a := count_ink(front,edge,inside)
		var b := count_ink(front,edge,outside)
		check(a>0 and absi(a-b)<=1,"Blade ink keeps its width across/away from body at camera size %.1f: %d/%d" % [size,a,b])
		blade.position.z = -.2
		await process_frame
		await RenderingServer.frame_post_draw
		var behind := viewport.get_texture().get_image()
		check(count_ink(behind,edge,inside)==0,"Body depth hides the blade outline behind it")
		check(count_ink(behind,edge,outside)>0,"Exposed portion of a behind-body blade retains its outline")
		behind.save_png("res://LocalOnly/Equipment/FeedbackReview2026_11_07/outline_depth_%.1f.png" % size)
	viewport.queue_free()
	await process_frame


func count_ink(frame: Image, edge: int, row: int) -> int:
	var count := 0
	for x in range(edge-4,edge+7):
		var color := frame.get_pixel(x,row)
		if maxf(color.r,maxf(color.g,color.b)) < .08:
			count += 1
	return count
