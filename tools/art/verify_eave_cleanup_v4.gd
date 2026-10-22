extends SceneTree
## Isolated candidate import only. Never loads or replaces the gameplay prefab.
## Copy this script into the sandbox with EaveRunner_v4.glb and expected.json.
const MODEL := "res://EaveRunner_v4.glb"
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

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("EAVE_V4_IMPORT_FAIL " + message)

func finite_transform(value: Transform3D) -> bool:
	return value.origin.is_finite() and value.basis.x.is_finite() and value.basis.y.is_finite() and value.basis.z.is_finite()

func verify() -> void:
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://expected.json"))
	check(expected is Dictionary and int(expected.get("triangles", 0)) > 0, "Expected source triangle count supplied")
	if not expected is Dictionary:
		await finish({})
		return
	var packed := load(MODEL) as PackedScene
	check(packed != null, "Candidate GLB loads in the isolated sandbox")
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
	await finish({"triangles": triangles, "vertices": vertices, "surfaces": surfaces, "meshes": meshes.size(), "bones": skeleton.get_bone_count(), "clips": clips})

func finish(asset: Dictionary) -> void:
	var result := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "display": DisplayServer.get_name(), "asset": asset, "scope": "Isolated imported candidate geometry and actions only; no active replacement or visual acceptance."}
	print("EAVE_V4_GODOT_CHECK " + JSON.stringify(result))
	if actor != null:
		actor.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
