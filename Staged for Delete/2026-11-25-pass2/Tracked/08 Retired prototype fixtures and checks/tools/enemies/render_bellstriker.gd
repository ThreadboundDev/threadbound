extends Node2D
## Optional GPU presentation check. -- --output=<absolute directory>
const VISUAL = preload("res://Src/Enemies/Bellstriker/bellstriker_visual.gd")
func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var output := "user://bellstriker_preview"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	if "--arena" in OS.get_cmdline_user_args():
		var arena := load("res://Src/Enemies/Bellstriker/bellstriker_test.tscn").instantiate() as Node2D
		add_child(arena)
		for i in range(25):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join("arena.png"))
		print("BELL_ARENA_RENDER_OK")
		get_tree().quit()
		return
	var visual := Node2D.new()
	visual.set_script(VISUAL)
	visual.position = Vector2(400,340)
	add_child(visual)
	var viewport := visual.get_child(0) as SubViewport
	if "--markers" in OS.get_cmdline_user_args():
		for side in [-1.0, 1.0]:
			var marker := MeshInstance3D.new()
			marker.mesh = SphereMesh.new()
			marker.mesh.radius = 0.10
			marker.mesh.height = 0.20
			var material := StandardMaterial3D.new()
			material.albedo_color = Color.RED if side > 0 else Color.GREEN
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			marker.material_override = material
			viewport.add_child(marker)
			marker.position = Vector3(side, 0.85, 1.4)
	for clip in [&"swim", &"box_idle", &"water_charge_1", &"water_charge_2", &"water_charge_3", &"water_jab", &"water_cross", &"water_smash", &"water_box_recover", &"walk"]:
		visual.animator.play(clip)
		visual.animator.seek(visual.animator.get_animation(clip).length * 0.75, true)
		visual.animator.pause()
		for i in range(8):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(output.path_join(str(clip) + ".png"))
		assert(error == OK)
	if "--combo-frames" in OS.get_cmdline_user_args():
		for clip in [&"water_charge_1", &"water_jab", &"water_charge_2", &"water_cross", &"water_charge_3", &"water_smash", &"water_box_recover", &"swim"]:
			for sample in range(6):
				visual.animator.play(clip, 0.0)
				visual.animator.seek(visual.animator.get_animation(clip).length * sample / 5.0, true)
				visual.animator.pause()
				for i in range(3):
					await get_tree().process_frame
				await RenderingServer.frame_post_draw
				assert(viewport.get_texture().get_image().save_png(output.path_join(str(clip) + "_%d.png" % sample)) == OK)
	if "--part-check" in OS.get_cmdline_user_args():
		visual.animator.play(&"water_cross", 0.0)
		visual.animator.seek(visual.animator.get_animation(&"water_cross").length, true)
		visual.animator.pause()
		var meshes := viewport.find_children("*", "MeshInstance3D", true, false)
		for mesh in meshes:
			if str(mesh.name).begins_with("Bellstriker_"):
				for other in meshes:
					other.visible = other == mesh
				for i in range(3):
					await get_tree().process_frame
				await RenderingServer.frame_post_draw
				viewport.get_texture().get_image().save_png(output.path_join("part_" + str(mesh.name) + ".png"))
				print("BELL_PART ", mesh.name)
	print("BELL_RENDER_OK ", output)
	get_tree().quit()
