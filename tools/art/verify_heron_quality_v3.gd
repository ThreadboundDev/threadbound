extends SceneTree
## Bird-only imported asset checks. Headless mode verifies data, not rendered pixels.
const MODEL_PATH := "res://Assets/BlueBiome/Enemies/LoomHeron/Models/LoomHeron_v3.glb"
const PREFAB_PATH := "res://Src/Enemies/LoomHeron/loom_heron.tscn"
const WORK_PATH := "res://work/loom-heron-v3"
const CLIPS := ["idle", "flight", "perch", "dive_windup", "dive", "brake", "hurt", "death", "needle_aim", "needle_fire", "low_recover"]
var checks := 0
var failures: Array[String] = []
var arena: Node2D

func _initialize() -> void:
	# The CLI resource UID cache may not yet contain newly imported external maps.
	for folder in ["res://Assets/BlueBiome/Characters/SharedTexturesV2", "res://Assets/BlueBiome/Enemies/LoomHeron/Models", "res://Assets/BlueBiome/Enemies/LoomHeron/Textures", "res://Assets/BlueBiome/Enemies/LoomHeron/TexturesV3"]:
		register_uids(folder)
	call_deferred("run")

func register_uids(folder: String) -> void:
	for file in DirAccess.get_files_at(folder):
		if not file.ends_with(".import"):
			continue
		var config := ConfigFile.new()
		if config.load(folder.path_join(file)) != OK:
			continue
		var uid := ResourceUID.text_to_id(config.get_value("remap", "uid", ""))
		if uid != -1 and not ResourceUID.has_id(uid):
			ResourceUID.add_id(uid, folder.path_join(file.trim_suffix(".import")))

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("HERON_V3_FAIL " + message)

func frames(count: int) -> void:
	for i in count:
		await process_frame

func expected_triangles() -> int:
	var path := WORK_PATH.path_join("manifest.json")
	if not FileAccess.file_exists(path):
		check(false, "Export manifest exists for topology comparison")
		return -1
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		check(false, "Export manifest contains valid JSON")
		return -1
	if data.has("triangles"):
		return int(data.triangles)
	if data.has("LoomHeron_v3.glb") and data["LoomHeron_v3.glb"].has("triangles"):
		return int(data["LoomHeron_v3.glb"].triangles)
	check(false, "Export manifest declares the exported triangle count")
	return -1

func run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	current_scene = arena
	var packed: PackedScene = load(PREFAB_PATH)
	check(packed != null, "Actual gameplay prefab loads")
	if not packed:
		finish({})
		return
	var heron = packed.instantiate()
	heron.process_mode = Node.PROCESS_MODE_DISABLED
	arena.add_child(heron)
	await frames(3)
	var model = heron.model
	check(model.model_scene.resource_path == MODEL_PATH, "Actual gameplay prefab uses the v3 bird")
	check(model.actor != null and model.animator != null and model._skeleton != null, "Imported model, animator and skeleton are instantiated")
	if not model.actor or not model.animator or not model._skeleton:
		finish({})
		return
	model.animator.pause()
	var triangles := 0
	var vertices := 0
	var detailed_surfaces := 0
	var normal_surfaces := 0
	var material_names: Array[String] = []
	for mesh_node: MeshInstance3D in model.actor.find_children("*", "MeshInstance3D", true, false):
		check(mesh_node.mesh is ArrayMesh, mesh_node.name + ": Imported mesh has inspectable surface arrays")
		check(mesh_node.skin != null, mesh_node.name + ": Imported mesh remains skinned")
		check(mesh_node.lod_bias >= 8, mesh_node.name + ": Fine geometry remains visible at gameplay distance")
		if not mesh_node.mesh is ArrayMesh:
			continue
		for surface in mesh_node.mesh.get_surface_count():
			var arrays := mesh_node.mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var index_count: int = mesh_node.mesh.surface_get_array_index_len(surface)
			triangles += (index_count if index_count > 0 else positions.size()) / 3
			vertices += positions.size()
			var geometry_valid := not positions.is_empty() and normals.size() == positions.size() and uv.size() == positions.size()
			for index in positions.size():
				geometry_valid = geometry_valid and positions[index].is_finite()
				if index < normals.size():
					geometry_valid = geometry_valid and normals[index].is_finite() and normals[index].length() > .8
				if index < uv.size():
					geometry_valid = geometry_valid and uv[index].is_finite()
			check(geometry_valid, mesh_node.name + ": Surface has finite positions, nonzero normals and UVs")
			var influence_count := weights.size() / maxi(positions.size(), 1)
			var weights_valid := influence_count in [4, 8]
			for index in positions.size():
				var total := 0.0
				var nonzero := 0
				for offset in influence_count:
					var weight: float = weights[index * influence_count + offset]
					weights_valid = weights_valid and is_finite(weight) and weight >= 0
					total += weight
					if weight > .000001:
						nonzero += 1
				weights_valid = weights_valid and nonzero >= 1 and nonzero <= 4 and absf(total - 1) < .0002
			check(weights_valid, mesh_node.name + ": Imported vertices have 1–4 normalized bone weights")
			var material := mesh_node.get_active_material(surface) as StandardMaterial3D
			check(material != null, mesh_node.name + ": Surface material survives import")
			if material:
				material_names.append(material.resource_name)
				check(material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, material.resource_name + ": Anisotropic filtering is enabled")
				if material.albedo_texture and material.albedo_texture.get_width() >= 4096:
					detailed_surfaces += 1
				if material.normal_enabled and material.normal_texture:
					normal_surfaces += 1
	check(triangles == expected_triangles(), "Full exported topology survives Godot import")
	check(detailed_surfaces >= 4 and normal_surfaces >= 4, "Major component surfaces retain high-resolution color and normal maps")
	check(model.actor.find_children("*", "CollisionObject3D", true, false).is_empty(), "Art asset preserves existing 2D physics")
	check(model._skeleton.get_bone_count() == 18, "All 18 rig bones survive import")
	check(model._skeleton.find_bone("beak_tip") >= 0, "Projectile marker survives import")
	var sidecar := ConfigFile.new()
	check(sidecar.load(MODEL_PATH + ".import") == OK and not sidecar.get_value("params", "meshes/generate_lods", true), "Automatic geometry simplification is disabled")
	check(model._view.size == Vector2i(1536, 1536), "Bird retains its 1536-square render target")
	check(model._view.msaa_3d == Viewport.MSAA_4X, "Bird retains 4x MSAA")
	check(is_equal_approx(model.image.scale.x * 1536, model.camera_span * 96), "Existing 96 pixels per metre scale is preserved")
	check(is_equal_approx(model.camera_span, 4.6) and is_equal_approx(model.camera_height, 1.05), "Existing camera framing is preserved")
	var body_shape := heron.get_node("CollisionShape2D") as CollisionShape2D
	check(body_shape.shape is CapsuleShape2D and is_equal_approx(body_shape.shape.radius, 28) and is_equal_approx(body_shape.shape.height, 110) and body_shape.position == Vector2(0, -70), "Existing gameplay capsule is unchanged")
	for clip: String in CLIPS:
		check(model.animator.has_animation(clip), clip + ": Existing animation survives import")
		if not model.animator.has_animation(clip):
			continue
		var animation: Animation = model.animator.get_animation(clip)
		check(animation.length > 0, clip + ": Animation has a positive length")
		check(animation.loop_mode == (Animation.LOOP_LINEAR if clip in ["idle", "flight", "perch"] else Animation.LOOP_NONE), clip + ": Loop mode matches gameplay use")
		model.animator.play(clip)
		model.animator.pause()
		var finite_pose := true
		for fraction in [0.0, .25, .5, .75, 1.0]:
			model.animator.seek(animation.length * fraction, true)
			model._skeleton.force_update_all_bone_transforms()
			for bone in model._skeleton.get_bone_count():
				var pose: Transform3D = model._skeleton.get_bone_global_pose(bone)
				finite_pose = finite_pose and pose.origin.is_finite() and pose.basis.x.is_finite() and pose.basis.y.is_finite() and pose.basis.z.is_finite()
		check(finite_pose, clip + ": Sampled imported bone poses remain finite")
	model.animator.play("idle")
	model.animator.seek(0, true)
	model.animator.pause()
	model._skeleton.force_update_all_bone_transforms()
	for facing in [-1, 1]:
		heron.update_facing(facing)
		var origin: Vector2 = heron._needle_origin() - heron.global_position
		check(origin.is_finite() and origin.x * facing > 45 and origin.x * facing < 165 and origin.y < -70 and origin.y > -220, "Needle projects from visible beak in facing " + str(facing))
	check(not model._charge_materials.is_empty(), "Charged thread retains the named telegraph material")
	model.set_tell(1)
	for material: StandardMaterial3D in model._charge_materials:
		check(material.emission_enabled and material.emission_energy_multiplier >= 4, "Ranged charge visibly raises thread emission")
	model.set_tell(0)
	finish({"triangles": triangles, "vertices": vertices, "detailed_surfaces": detailed_surfaces, "normal_surfaces": normal_surfaces, "materials": material_names})

func finish(asset: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(WORK_PATH)
	var result := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "display": DisplayServer.get_name(), "asset": asset, "scope": "Imported asset data and gameplay framing; this is not a GPU render test."}
	FileAccess.open(WORK_PATH.path_join("godot_art_verification.json"), FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print("HERON_V3_GODOT_CHECKS ", checks, " failures=", failures)
	if arena:
		arena.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
