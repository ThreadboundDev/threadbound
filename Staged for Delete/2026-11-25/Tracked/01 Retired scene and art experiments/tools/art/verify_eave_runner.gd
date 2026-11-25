extends SceneTree
## Imported-art checks and real Forward+ captures; does not create combat AI.

var checks := 0
var failures: Array[String] = []
var captures: Array[String] = []
var review: Node3D

func _initialize() -> void:
	for folder: String in ["res://Assets/BlueBiome/Characters/SharedTexturesV2", "res://Assets/BlueBiome/Enemies/LoomHeron/Textures", "res://Assets/BlueBiome/Enemies/EaveRunner/Models", "res://Assets/BlueBiome/Enemies/EaveRunner/Textures"]:
		for filename in DirAccess.get_files_at(folder):
			if filename.ends_with(".import"):
				var config := ConfigFile.new()
				if config.load(folder.path_join(filename)) == OK:
					var uid := ResourceUID.text_to_id(config.get_value("remap", "uid", ""))
					if uid != -1 and not ResourceUID.has_id(uid):
						ResourceUID.add_id(uid, folder.path_join(filename.trim_suffix(".import")))
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for index in count:
		await process_frame

func seek(seconds: float) -> void:
	review.model.animator.seek(seconds, true)
	review.model.animator.pause()
	await frames(2)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var file := "res://work/eave-runner/renders/" + label + ".png"
	check(root.get_texture().get_image().save_png(file) == OK, "Save rendered " + label)
	captures.append(file)

func run() -> void:
	review = load("res://Src/Tests/Art/eave_runner_art_review.tscn").instantiate()
	root.add_child(review)
	current_scene = review
	await frames(6)
	var animator: AnimationPlayer = review.model.animator
	var skeleton := review.model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		for candidate: Node in review.model.find_children("*", "Skeleton3D", true, false):
			skeleton = candidate as Skeleton3D
	check(skeleton != null and skeleton.get_bone_count() == 60, "Imported model retains the sixty-bone rig")
	check(animator != null and animator.get_animation_list().size() >= 12, "Twelve skeletal clips import")
	var cloth_bones := 0
	for index in skeleton.get_bone_count():
		if skeleton.get_bone_name(index).begins_with("tail_"):
			cloth_bones += 1
	check(cloth_bones == 6, "Both cloth tails retain three bones")
	check(review.model.find_children("*", "CollisionObject3D", true, false).is_empty(), "Art prefab introduces no physics or combat controller")
	var surfaces := 0
	var indigo_tint := false
	var normal_maps := 0
	for mesh_node: MeshInstance3D in review.model.find_children("*", "MeshInstance3D", true, false):
		for index in mesh_node.mesh.get_surface_count():
			surfaces += 1
			var material := mesh_node.get_active_material(index) as StandardMaterial3D
			if material:
				if material.resource_name.contains("indigo hood"):
					indigo_tint = material.albedo_color.r < 0.5
				if material.normal_enabled:
					normal_maps += 1
	check(surfaces >= 8 and surfaces <= 12, "Material surfaces retain differentiated fabric, cord, ceramic and iron")
	check(indigo_tint and normal_maps >= 5, "Authored indigo tint and textured surface normals survive import")
	for index in review.CLIPS.size():
		var clip: StringName = review.CLIPS[index]
		check(animator.has_animation(clip), String(clip) + " imported")
		review.play(index)
		var length := animator.get_animation(clip).length
		await seek(0)
		var initial: Array[Transform3D] = []
		for bone in skeleton.get_bone_count():
			initial.append(skeleton.get_bone_global_pose(bone))
		await seek(length * 0.5)
		var maximum := 0.0
		var finite_pose := true
		for bone in skeleton.get_bone_count():
			var pose := skeleton.get_bone_global_pose(bone)
			finite_pose = finite_pose and pose.origin.is_finite() and pose.basis.x.is_finite()
			maximum = maxf(maximum, pose.origin.distance_to(initial[bone].origin))
		check(finite_pose, String(clip) + " finite imported pose")
		check(maximum > 0.001, String(clip) + " really animates the imported skeleton")
		if clip in [&"idle", &"run", &"wall_perch"]:
			await seek(length)
			var loop_error := 0.0
			for bone in skeleton.get_bone_count():
				loop_error = maxf(loop_error, skeleton.get_bone_global_pose(bone).origin.distance_to(initial[bone].origin))
			check(loop_error < 0.001, String(clip) + " loops without a position jump")
			check(animator.get_animation(clip).loop_mode == Animation.LOOP_LINEAR, String(clip) + " is configured as looping")
		else:
			check(animator.get_animation(clip).loop_mode == Animation.LOOP_NONE, String(clip) + " holds its end pose")
		await seek(length * 0.45)
		var pin_scale := skeleton.get_bone_pose_scale(skeleton.find_bone("held_pin")).length()
		check(pin_scale > 1.7 if clip == &"throw_windup" else pin_scale < 0.02, String(clip) + " shows the pin only during its throw preparation")
		await capture("godot_" + String(clip))
		review.view_side = true
		review._update_camera()
		await frames(2)
		if clip in [&"idle", &"wall_perch", &"jump_slash"]:
			await capture("side_" + String(clip))
		review.view_side = false
		review._update_camera()
		var blade := skeleton.find_bone("blade")
		var hand := skeleton.find_bone("hand.R")
		check(skeleton.get_bone_global_pose(blade).origin.distance_to(skeleton.get_bone_global_pose(hand).origin) < 0.001, String(clip) + " keeps the weapon attached to the wrist")
		if clip == &"throw_release":
			await seek(length * 0.8)
			check(skeleton.get_bone_pose_scale(skeleton.find_bone("held_pin")).length() < 0.02, "Throw releases the held pin")

	if DisplayServer.get_name() != "headless":
		var sequence: Array[StringName] = [&"idle", &"run", &"wall_attach", &"wall_perch", &"wall_windup", &"wall_launch", &"jump_slash", &"land_recover", &"throw_windup", &"throw_release", &"hurt", &"death"]
		var frame := 0
		for clip: StringName in sequence:
			review.play(review.CLIPS.find(clip))
			var length := animator.current_animation_length
			var samples := maxi(5, roundi(length * 10))
			for sample in samples:
				await seek(length * sample / maxf(1, samples - 1))
				await capture("motion_%03d" % frame)
				frame += 1
	var report := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "display": DisplayServer.get_name(), "captures": captures}
	FileAccess.open("res://work/eave-runner/godot_verification_" + DisplayServer.get_name() + ".json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("EAVE_RUNNER_GODOT_VERIFIED ", JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures}))
	review.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
