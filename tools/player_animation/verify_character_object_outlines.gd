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
