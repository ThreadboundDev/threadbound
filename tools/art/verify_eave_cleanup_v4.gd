extends SceneTree
## Default: isolated candidate import. --runtime checks approved active resources.
## Optional --render-preview saves real GPU views; headless checks never claim pixels.
const MODEL := "res://EaveRunner_v4.glb"
const LIVE_MODEL := "res://Assets/BlueBiome/Enemies/EaveRunner/Models/EaveRunner_v4.glb"
const CLIPS := {
	"idle": 2.4, "run": 0.8, "wall_attach": 10.0 / 30.0,
	"wall_perch": 1.6, "wall_windup": 14.0 / 30.0, "wall_launch": 0.3,
	"jump_slash": 20.0 / 30.0, "land_recover": 0.6,
	"throw_windup": 14.0 / 30.0, "throw_release": 10.0 / 30.0,
	"hurt": 0.4, "death": 1.2,
}
var checks := 0
var failures: Array[String] = []
var actor: Node3D
var arena: Node2D
var runtime := false

func _initialize() -> void:
	runtime = "--runtime" in OS.get_cmdline_user_args()
	if runtime:
		for folder in ["res://Assets/BlueBiome/Characters/SharedTexturesV2", "res://Assets/BlueBiome/Enemies/EaveRunner/Models", "res://Assets/BlueBiome/Enemies/EaveRunner/Textures"]:
			for file in DirAccess.get_files_at(folder):
				if not file.ends_with(".import"):
					continue
				var config := ConfigFile.new()
				if config.load(folder.path_join(file)) == OK:
					var uid := ResourceUID.text_to_id(config.get_value("remap", "uid", ""))
					if uid != -1 and not ResourceUID.has_id(uid):
						ResourceUID.add_id(uid, folder.path_join(file.trim_suffix(".import")))
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("EAVE_V4_IMPORT_FAIL " + message)

func finite_transform(value: Transform3D) -> bool:
	return value.origin.is_finite() and value.basis.x.is_finite() and value.basis.y.is_finite() and value.basis.z.is_finite()

func verify() -> void:
	var expected_path := "res://work/eave-runner-v4/build_report.json" if runtime else "res://expected.json"
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
	check(expected is Dictionary and int(expected.get("triangles", 0)) > 0, "Expected source triangle count supplied")
	if not expected is Dictionary:
		await finish({})
		return
	var packed := load(LIVE_MODEL if runtime else MODEL) as PackedScene
	check(packed != null, "Approved model GLB loads")
	if packed == null:
		await finish({})
		return
	actor = packed.instantiate() as Node3D
	check(actor != null, "Candidate instantiates as 3D artwork")
	if actor == null:
		await finish({})
		return
	root.add_child(actor)
	await process_frame
	var skeletons := actor.find_children("*", "Skeleton3D", true, false)
	var animators := actor.find_children("*", "AnimationPlayer", true, false)
	check(skeletons.size() == 1 and animators.size() == 1, "Exactly one imported skeleton and animator")
	if skeletons.size() != 1 or animators.size() != 1:
		await finish({})
		return
	var skeleton := skeletons[0] as Skeleton3D
	var animator := animators[0] as AnimationPlayer
	check(skeleton.get_bone_count() == 60, "All sixty bones survive import")
	var names: Array[String] = []
	for bone in skeleton.get_bone_count():
		names.append(skeleton.get_bone_name(bone))
	var expected_names: Array[String] = ["root", "pelvis", "spine", "chest", "neck", "head", "blade", "held_pin"]
	for side: String in ["L", "R"]:
		for stem: String in ["clavicle", "upper_arm", "forearm", "hand", "thigh", "shin", "foot", "toe"]:
			expected_names.append(stem + "." + side)
		for digit in range(1, 6):
			for segment in range(1, 4):
				expected_names.append("finger%d-%d.%s" % [digit, segment, side])
		for segment in range(1, 4):
			expected_names.append("tail_%s_%d" % [side, segment])
	names.sort()
	expected_names.sort()
	check(names == expected_names, "Imported bone names retain the existing rig contract")
	var imported_clips: Array[String] = []
	for name: String in animator.get_animation_list():
		if name != "RESET":
			imported_clips.append(name)
	var expected_clips: Array[String] = []
	for name: String in CLIPS:
		expected_clips.append(name)
	imported_clips.sort()
	expected_clips.sort()
	check(imported_clips == expected_clips, "Exactly the twelve existing named actions survive")
	var triangles := 0
	var vertices := 0
	var surfaces := 0
	var meshes := actor.find_children("*", "MeshInstance3D", true, false)
	check(not meshes.is_empty(), "Imported candidate has render meshes")
	for node: MeshInstance3D in meshes:
		check(node.mesh is ArrayMesh and node.skin != null, node.name + ": imported mesh remains skinned")
		if not node.mesh is ArrayMesh:
			continue
		var bounds := node.get_aabb()
		check(bounds.position.is_finite() and bounds.size.is_finite() and bounds.size.length() < 4.0, node.name + ": rest mesh bounds finite and bounded")
		for surface in node.mesh.get_surface_count():
			surfaces += 1
			var arrays := node.mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var count: int = node.mesh.surface_get_array_index_len(surface)
			triangles += int((count if count > 0 else positions.size()) / 3)
			vertices += positions.size()
			var valid := not positions.is_empty() and normals.size() == positions.size() and uv.size() == positions.size()
			var influences := int(weights.size() / maxi(positions.size(), 1))
			valid = valid and influences in [4, 8]
			for index in positions.size():
				valid = valid and positions[index].is_finite() and normals[index].is_finite() and uv[index].is_finite()
				var total := 0.0
				var nonzero := 0
				for offset in influences:
					var weight := weights[index * influences + offset]
					valid = valid and is_finite(weight) and weight >= 0
					total += weight
					if weight > 0.000001:
						nonzero += 1
				valid = valid and nonzero >= 1 and nonzero <= 4 and absf(total - 1.0) < 0.0002
			check(valid, node.name + ": finite geometry, UVs and normalized skin weights")
	check(triangles == int(expected.get("triangles", 0)), "Primary imported topology matches the exported candidate")
	check(triangles > 0 and triangles <= 800000, "Imported candidate stays below 800k triangles")
	var root_bone := skeleton.find_bone("root")
	var blade := skeleton.find_bone("blade")
	var hand := skeleton.find_bone("hand.R")
	check(root_bone >= 0 and blade >= 0 and hand >= 0, "Root and weapon attachment bones exist")
	if root_bone < 0 or blade < 0 or hand < 0:
		await finish({"triangles": triangles, "vertices": vertices})
		return
	check(skeleton.get_bone_parent(blade) == hand, "Blade remains parented to the right wrist")
	var clips: Array[Dictionary] = []
	for name: String in CLIPS:
		check(animator.has_animation(name), name + ": animation exists")
		if not animator.has_animation(name):
			continue
		var animation := animator.get_animation(name)
		check(absf(animation.length - CLIPS[name]) < 0.0002, name + ": duration retained")
		animator.play(name)
		animator.pause()
		var initial: Array[Transform3D] = []
		var maximum_motion := 0.0
		var maximum_span := 0.0
		var root_drift := 0.0
		var finite := true
		var attached := true
		for fraction: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
			animator.seek(animation.length * fraction, true)
			skeleton.force_update_all_bone_transforms()
			var bounds := AABB(skeleton.get_bone_global_pose(0).origin, Vector3.ZERO)
			for bone in skeleton.get_bone_count():
				var pose := skeleton.get_bone_global_pose(bone)
				finite = finite and finite_transform(pose)
				bounds = bounds.expand(pose.origin)
				if fraction == 0.0:
					initial.append(pose)
				else:
					maximum_motion = maxf(maximum_motion, pose.origin.distance_to(initial[bone].origin))
			maximum_span = maxf(maximum_span, maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)))
			root_drift = maxf(root_drift, skeleton.get_bone_global_pose(root_bone).origin.distance_to(initial[root_bone].origin))
			attached = attached and skeleton.get_bone_global_pose(blade).origin.distance_to(skeleton.get_bone_global_pose(hand).origin) < 0.001
		check(finite and maximum_span < 3.5, name + ": sampled imported rig poses remain finite and bounded")
		check(maximum_motion > 0.001, name + ": imported bones actually animate")
		check(root_drift < 0.001 and attached, name + ": in-place root and wrist attachment retained")
		clips.append({"name": name, "seconds": animation.length, "maximum_bone_motion": maximum_motion, "rig_span": maximum_span, "root_drift": root_drift})
	if runtime:
		await verify_live()
	await finish({"triangles": triangles, "vertices": vertices, "surfaces": surfaces, "meshes": meshes.size(), "bones": skeleton.get_bone_count(), "clips": clips})

func verify_live() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	current_scene = arena
	var eave = load("res://Src/Enemies/EaveRunner/eave_runner.tscn").instantiate()
	eave.process_mode = Node.PROCESS_MODE_DISABLED
	arena.add_child(eave)
	await process_frame
	var visual = eave.get_node("Visuals/Model")
	check(visual.model_scene.resource_path == LIVE_MODEL, "Gameplay prefab uses approved v4")
	check(visual.actor != null and visual.animator != null and visual._skeleton != null, "Real gameplay wrapper initializes model, animator and skeleton")
	if visual.actor == null or visual.animator == null or visual._skeleton == null:
		return
	check(visual._view.size == Vector2i(1536, 1536) and visual._view.msaa_3d == Viewport.MSAA_4X, "Existing render target and MSAA retained")
	check(is_equal_approx(visual.camera_span, 3.8) and is_equal_approx(visual.camera_height, 1.05) and is_equal_approx(visual.model_yaw, 72.0), "Gameplay camera framing retained")
	check(is_equal_approx(visual.image.scale.x * 1536, 3.8 * 96), "Existing 96 pixels/metre scale retained")
	check(visual.actor.find_children("*", "CollisionObject3D", true, false).is_empty(), "Imported art adds no gameplay physics")
	var body := eave.get_node("CollisionShape2D") as CollisionShape2D
	var hurt := eave.get_node("Hurtbox/CollisionShape2D") as CollisionShape2D
	check(body.shape is CapsuleShape2D and body.position == Vector2(0, -74) and is_equal_approx(body.shape.radius, 20) and is_equal_approx(body.shape.height, 148), "Body capsule remains unchanged")
	check(hurt.shape == body.shape and hurt.position == body.position, "Hurtbox retains body alignment")
	var blade := eave.get_node("AttackHitbox/CollisionShape2D") as CollisionShape2D
	check(blade.shape is RectangleShape2D and blade.shape.size == Vector2(100, 92), "Existing attack rectangle retained")
	var sidecar := ConfigFile.new()
	check(sidecar.load(LIVE_MODEL + ".import") == OK and not sidecar.get_value("params", "meshes/generate_lods", true) and sidecar.get_value("params", "meshes/force_disable_compression", false), "Import preserves full geometry and precision")
	for clip: String in CLIPS:
		check(visual.animator.has_animation(clip), clip + ": gameplay wrapper resolves action")
		if visual.animator.has_animation(clip):
			var animation: Animation = visual.animator.get_animation(clip)
			check(animation.loop_mode == (Animation.LOOP_LINEAR if clip in ["idle", "run", "wall_perch"] else Animation.LOOP_NONE), clip + ": gameplay loop mode retained")
	var materials := 0
	var glb_file := FileAccess.open(LIVE_MODEL, FileAccess.READ)
	glb_file.seek(12)
	var json_bytes := glb_file.get_32()
	glb_file.get_32()
	var glb: Dictionary = JSON.parse_string(glb_file.get_buffer(json_bytes).get_string_from_utf8())
	var expected_materials := {}
	for entry: Dictionary in glb["materials"]:
		expected_materials[entry["name"]] = entry
	for node: MeshInstance3D in visual.actor.find_children("*", "MeshInstance3D", true, false):
		for index in node.mesh.get_surface_count():
			var material := node.get_active_material(index) as StandardMaterial3D
			check(material != null, node.name + ": active material resolves")
			if material:
				materials += 1
				# Bronze, blade, crack and glow surfaces intentionally use solid
				# materials. Require maps only where the approved GLB declares them.
				var expected: Dictionary = expected_materials.get(material.resource_name, {})
				check(not expected.is_empty(), material.resource_name + ": material identity retained")
				var color_map: bool = expected.get("pbrMetallicRoughness", {}).has("baseColorTexture")
				var normal_map: bool = expected.has("normalTexture")
				check((material.albedo_texture != null) == color_map, material.resource_name + ": color-map contract retained")
				check(material.normal_enabled == normal_map and (material.normal_texture != null) == normal_map, material.resource_name + ": normal-map contract retained")
				if normal_map:
					check(is_equal_approx(material.normal_scale, float(expected["normalTexture"].get("scale", 1.0))), material.resource_name + ": approved normal-map strength retained")
				check(material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC and material.cull_mode == BaseMaterial3D.CULL_DISABLED, material.resource_name + ": wrapper filtering and cloth visibility retained")
	check(materials == 19, "All nineteen imported material surfaces resolve in gameplay")
	var art = load("res://Src/Enemies/EaveRunner/eave_runner_model_3d.tscn").instantiate()
	art.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(art)
	check(art.get_node("Character").scene_file_path == LIVE_MODEL and art.animator != null, "Art-only scene also uses v4 and initializes its animator")
	art.queue_free()
	if "--render-preview" in OS.get_cmdline_user_args():
		check(DisplayServer.get_name() != "headless", "GPU preview requested with a real rendering device")
		if DisplayServer.get_name() != "headless":
			var folder := "res://work/eave-runner-v4/runtime_renders"
			DirAccess.make_dir_recursive_absolute(folder)
			for clip: String in ["idle", "jump_slash"]:
				visual.animator.play(clip)
				visual.animator.pause()
				visual.animator.seek(0.0 if clip == "idle" else 0.3, true)
				for frame in 3:
					await process_frame
				await RenderingServer.frame_post_draw
				var image: Image = visual._view.get_texture().get_image()
				check(image != null and not image.is_empty(), clip + ": GPU viewport produces pixels")
				if image != null and not image.is_empty():
					check(image.save_png(folder.path_join(clip + ".png")) == OK, clip + ": saved real gameplay-wrapper render")

func finish(asset: Dictionary) -> void:
	var result := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "display": DisplayServer.get_name(), "asset": asset, "scope": "Active v4 references, gameplay wrapper and imported rig data." if runtime else "Isolated imported candidate geometry and actions only; no active replacement or visual acceptance."}
	print("EAVE_V4_GODOT_CHECK " + JSON.stringify(result))
	if arena != null:
		arena.queue_free()
	if actor != null:
		actor.queue_free()
	for frame in 3:
		await process_frame
	# Let the calling verifier unwind its PackedScene/material references before
	# engine teardown; GPU resources must outlive their final scripted references.
	call_deferred("quit", 0 if failures.is_empty() else 1)
