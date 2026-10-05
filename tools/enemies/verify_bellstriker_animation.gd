extends SceneTree
## Presentation regression: imported rig, not gameplay/collision approximations.
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("BELL_POSE_FAIL " + label)
	else:
		print("PASS " + label)
func run() -> void:
	var model = load("res://Assets/BlueBiome/Enemies/Models/Bellstriker_Boxing_v4.glb").instantiate()
	root.add_child(model)
	await process_frame
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var animator: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
	check(skeleton.get_bone_count() == 44, "Full spine and articulated limbs imported")
	var tail_names := [&"abdomen", &"tail.01", &"tail.02", &"tail.03", &"tail.04", &"tail_fan"]
	for index in tail_names.size():
		var bone := skeleton.find_bone(tail_names[index])
		var parent := skeleton.find_bone(&"body" if index == 0 else tail_names[index - 1])
		check(bone >= 0 and skeleton.get_bone_parent(bone) == parent, "Connected lower-body chain " + tail_names[index])
	var guard: Array[Vector3] = []
	for clip in [&"box_idle", &"water_charge_3", &"water_jab", &"water_cross", &"water_smash"]:
		animator.play(clip, 0.0)
		animator.pause()
		animator.seek(animator.get_animation(clip).length, true)
		var body := skeleton.get_bone_global_pose(skeleton.find_bone("body"))
		var head := skeleton.get_bone_global_pose(skeleton.find_bone("head"))
		var left := skeleton.get_bone_global_pose(skeleton.find_bone("claw.L")).origin
		var right := skeleton.get_bone_global_pose(skeleton.find_bone("claw.R")).origin
		check(head.basis.y.normalized().dot(Vector3.RIGHT) > 0.99, "Focused forward head " + clip)
		if clip == &"box_idle":
			guard.assign([left, right])
			check(body.basis.y.normalized().dot(Vector3.UP) > 0.98, "Guard trunk is fully vertical")
			check(left.x > head.origin.x + 0.45 and right.x > head.origin.x + 0.4 and minf(left.y, right.y) > head.origin.y - 0.35, "Both fists are forward and raised")
			var fan := skeleton.get_bone_global_pose(skeleton.find_bone("tail_fan")).origin
			check(fan.y < body.origin.y - 0.65 and fan.x > body.origin.x + 0.12, "Lower spine curls inward below the vertical trunk")
		elif clip == &"water_charge_3":
			check(minf(left.y, right.y) > head.origin.y + 0.55 and left.distance_to(right) < 0.70, "Both fists gather above the head for the finisher")
		elif clip == &"water_jab":
			check(left.x > guard[0].x + 0.55 and right.distance_to(guard[1]) < 0.03, "Jab extends the lead arm while the other guards")
		elif clip == &"water_cross":
			check(right.x > guard[1].x + 0.55 and left.distance_to(guard[0]) < 0.03, "Cross extends the rear arm while the other guards")
		elif clip == &"water_smash":
			check(minf(left.x, right.x) > 1.0 and maxf(left.y, right.y) < 1.0 and left.distance_to(right) < 0.7, "Finisher throws both fists down and forward together")
	for clip in [&"swim", &"swim_idle", &"box_idle"]:
		animator.play(clip, 0.0)
		animator.pause()
		var animation := animator.get_animation(clip)
		animator.seek(0.0, true)
		var first: Array[Transform3D] = []
		for bone in skeleton.get_bone_count():
			first.append(skeleton.get_bone_global_pose(bone))
		animator.seek(animation.length, true)
		var seamless := true
		for bone in skeleton.get_bone_count():
			var pose := skeleton.get_bone_global_pose(bone)
			seamless = seamless and pose.origin.distance_to(first[bone].origin) < 0.001 and absf(pose.basis.get_rotation_quaternion().dot(first[bone].basis.get_rotation_quaternion())) > 0.9999
		check(seamless, "Loop endpoints match " + clip)
		animator.seek(animation.length * 0.25, true)
		var lively := 0
		for name in tail_names:
			var index := skeleton.find_bone(name)
			if skeleton.get_bone_global_pose(index).basis.get_rotation_quaternion().angle_to(first[index].basis.get_rotation_quaternion()) > deg_to_rad(0.1):
				lively += 1
		check(lively == 6, "Every lower-body segment participates in " + clip)
	print("BELL_POSE_CHECKS failures=", failures)
	quit(1 if failures else 0)
