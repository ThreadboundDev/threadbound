extends SceneTree
## Ninja-only imported art checks. Headless mode inspects data, not GPU pixels.
const MODEL_PATH := "res://Assets/BlueBiome/Enemies/EaveRunner/Models/EaveRunner_v3.glb"
const PREFAB_PATH := "res://Src/Enemies/EaveRunner/eave_runner.tscn"
const WORK_PATH := "res://work/eave-runner-v3"
const CLIPS := ["idle", "run", "wall_attach", "wall_perch", "wall_windup", "wall_launch", "jump_slash", "land_recover", "throw_windup", "throw_release", "hurt", "death"]
var checks := 0
var failures: Array[String] = []
var arena: Node2D

func _initialize() -> void:
	# A fresh CLI process may not yet know the external texture UIDs.
	for folder in ["res://Assets/BlueBiome/Characters/SharedTexturesV2", "res://Assets/BlueBiome/Enemies/LoomHeron/Textures", "res://Assets/BlueBiome/Enemies/EaveRunner/Models", "res://Assets/BlueBiome/Enemies/EaveRunner/Textures", "res://Assets/BlueBiome/Enemies/EaveRunner/TexturesV3"]:
		register_uids(folder)
	call_deferred("run")

func register_uids(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
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
		push_error("EAVE_V3_FAIL " + message)

func frames(count: int) -> void:
	for index in count:
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
	if data.has("EaveRunner_v3.glb") and data["EaveRunner_v3.glb"].has("triangles"):
		return int(data["EaveRunner_v3.glb"].triangles)
	if data.has("asset") and data.asset.has("triangles"):
		return int(data.asset.triangles)
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
	var eave = packed.instantiate()
	eave.process_mode = Node.PROCESS_MODE_DISABLED
	arena.add_child(eave)
	await frames(3)
	var model = eave.model
	check(model.model_scene.resource_path == MODEL_PATH, "Actual gameplay prefab uses the v3 Eave Runner")
	check(model.actor != null and model.animator != null and model._skeleton != null, "Imported model, animator and skeleton instantiate")
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
		check(mesh_node.mesh is ArrayMesh, mesh_node.name + ": Imported mesh has inspectable arrays")
		check(mesh_node.skin != null, mesh_node.name + ": Imported geometry remains skinned")
		check(mesh_node.lod_bias >= 8, mesh_node.name + ": Fine geometry stays visible at gameplay distance")
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
			check(geometry_valid, mesh_node.name + ": Surface positions, normals and UVs are finite and usable")
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
			check(weights_valid, mesh_node.name + ": Imported vertices retain 1–4 normalized influences")
			var material := mesh_node.get_active_material(surface) as StandardMaterial3D
			check(material != null, mesh_node.name + ": Surface material survives import")
			if material:
				material_names.append(material.resource_name)
				check(material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, material.resource_name + ": Anisotropic filtering enabled")
				if material.albedo_texture and material.albedo_texture.get_width() >= 4096:
					detailed_surfaces += 1
				if material.normal_enabled and material.normal_texture:
					normal_surfaces += 1
	check(triangles == expected_triangles(), "Full exported topology survives Godot import")
	check(detailed_surfaces >= 4 and normal_surfaces >= 4, "Major components retain high-resolution color and normal maps")
	check(model.actor.find_children("*", "CollisionObject3D", true, false).is_empty(), "Art preserves the existing 2D physics")
	var skeleton: Skeleton3D = model._skeleton
	check(skeleton.get_bone_count() == 60, "All 60 skeletal bones survive import")
	var cloth_bones := 0
	for bone in skeleton.get_bone_count():
		if skeleton.get_bone_name(bone).begins_with("tail_"):
			cloth_bones += 1
	check(cloth_bones == 6, "Both cloth tails retain their three-joint chains")
	var blade := skeleton.find_bone("blade")
	var hand := skeleton.find_bone("hand.R")
	var pin := skeleton.find_bone("held_pin")
	check(blade >= 0 and hand >= 0 and pin >= 0, "Weapon, hand and held-pin attachments survive")
	if blade >= 0 and hand >= 0:
		check(skeleton.get_bone_parent(blade) == hand, "Weapon remains parented to the wrist")
	var sidecar := ConfigFile.new()
	check(sidecar.load(MODEL_PATH + ".import") == OK and not sidecar.get_value("params", "meshes/generate_lods", true), "Automatic geometry simplification is disabled")
	check(model._view.size == Vector2i(1536, 1536), "Ninja retains its 1536-square render target")
	check(model._view.msaa_3d == Viewport.MSAA_4X, "Ninja retains 4x MSAA")
	check(is_equal_approx(model.image.scale.x * 1536, model.camera_span * 96), "Existing 96 pixels per metre scale is preserved")
	check(is_equal_approx(model.camera_span, 3.8) and is_equal_approx(model.camera_height, 1.05) and is_equal_approx(model.model_yaw, 72), "Existing gameplay camera framing is preserved")
	var body := eave.get_node("CollisionShape2D") as CollisionShape2D
	check(body.shape is CapsuleShape2D and is_equal_approx(body.shape.radius, 20) and is_equal_approx(body.shape.height, 148) and body.position == Vector2(0, -74), "Existing gameplay capsule is unchanged")
	var hurtbox := eave.get_node("Hurtbox/CollisionShape2D") as CollisionShape2D
	check(hurtbox.shape == body.shape and hurtbox.position == body.position, "Existing hurtbox remains aligned to the gameplay capsule")
	var clip_rows: Array[Dictionary] = []
	for clip: String in CLIPS:
		check(model.animator.has_animation(clip), clip + ": Existing animation survives import")
		if not model.animator.has_animation(clip):
			continue
		var animation: Animation = model.animator.get_animation(clip)
		check(animation.length > 0, clip + ": Animation has a positive duration")
		check(animation.loop_mode == (Animation.LOOP_LINEAR if clip in ["idle", "run", "wall_perch"] else Animation.LOOP_NONE), clip + ": Loop mode matches gameplay use")
		model.animator.play(clip)
		model.animator.pause()
		var finite_pose := true
		var attached_weapon := true
		var initial: Array[Transform3D] = []
		var maximum_motion := 0.0
		for fraction in [0.0, .25, .5, .75, 1.0]:
			model.animator.seek(animation.length * fraction, true)
			skeleton.force_update_all_bone_transforms()
			for bone in skeleton.get_bone_count():
				var pose := skeleton.get_bone_global_pose(bone)
				finite_pose = finite_pose and pose.origin.is_finite() and pose.basis.x.is_finite() and pose.basis.y.is_finite() and pose.basis.z.is_finite()
				if fraction == 0:
					initial.append(pose)
				else:
					maximum_motion = maxf(maximum_motion, pose.origin.distance_to(initial[bone].origin))
			if blade >= 0 and hand >= 0:
				attached_weapon = attached_weapon and skeleton.get_bone_global_pose(blade).origin.distance_to(skeleton.get_bone_global_pose(hand).origin) < .001
		check(finite_pose, clip + ": Sampled imported bone poses remain finite")
		check(maximum_motion > .001, clip + ": Imported skeleton actually animates")
		check(attached_weapon, clip + ": Modeled weapon stays attached to the wrist")
		if clip in ["idle", "run", "wall_perch"]:
			var loop_error := 0.0
			for bone in skeleton.get_bone_count():
				var ending := skeleton.get_bone_global_pose(bone)
				loop_error = maxf(loop_error, ending.origin.distance_to(initial[bone].origin))
			check(loop_error < .001, clip + ": Imported loop endpoints have no position snap")
		if pin >= 0:
			model.animator.seek(animation.length * .45, true)
			check(skeleton.get_bone_pose_scale(pin).length() > 1.7 if clip == "throw_windup" else skeleton.get_bone_pose_scale(pin).length() < .02, clip + ": Pin is visible only during throw preparation")
		clip_rows.append({"name": clip, "seconds": animation.length, "maximum_bone_motion": maximum_motion})
	finish({"triangles": triangles, "vertices": vertices, "detailed_surfaces": detailed_surfaces, "normal_surfaces": normal_surfaces, "materials": material_names, "clips": clip_rows})

func finish(asset: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(WORK_PATH)
	var result := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "display": DisplayServer.get_name(), "asset": asset, "scope": "Imported art, animation and retained gameplay framing; not a GPU render test."}
	FileAccess.open(WORK_PATH.path_join("godot_art_verification.json"), FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print("EAVE_V3_GODOT_CHECKS ", checks, " failures=", failures)
	if arena:
		arena.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
