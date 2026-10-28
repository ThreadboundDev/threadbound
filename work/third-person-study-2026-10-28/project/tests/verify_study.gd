extends SceneTree

var checks: Array[Dictionary] = []

func check(label: String, passed: bool, detail = null) -> void:
	checks.append({"check": label, "passed": passed, "detail": detail})
	print("PASS " if passed else "FAIL ", label, " ", detail)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/workshop_study.tscn").instantiate()
	root.add_child(scene)
	await frames(35)
	var actor = scene.actor
	check("Separate project name", ProjectSettings.get_setting("application/config/name") == "Threadbound — Third-person Study")
	check("Original named Threadborne skeleton", actor.skeleton != null and actor.skeleton.find_bone("hand.R") >= 0)
	check("Floor contact at spawn", actor.is_on_floor(), str(actor.global_position))
	check("Third-person camera current", actor.camera.current and actor.camera.projection == Camera3D.PROJECTION_PERSPECTIVE)
	check("Existing movement clips imported", actor.animation.get_animation_list().size() >= 4, actor.animation.get_animation_list())
	check("Worker animation playing", scene.worker_players.size() > 0 and scene.worker_players[0].is_playing())
	var workshop = scene.get_node("WorkingVillageWorkshop")
	var worker = workshop.find_children("*", "Skeleton3D", true, false)[0]
	var wrist: int = worker.find_bone("hand_l")
	check("Worker wrist bone available", wrist >= 0)
	if wrist >= 0:
		var first: Vector3 = worker.get_bone_global_pose(wrist).origin
		await frames(30)
		check("Imported work loop moves wrist", first.distance_to(worker.get_bone_global_pose(wrist).origin) > 0.005)
	check("New sword visible by default", actor.model.find_child("Study_Sword", true, false).visible)
	actor.set_weapons(false)
	check("Original sword comparison", actor.model.find_child("Threadborne_Sword", true, false).visible and not actor.model.find_child("Study_Sword", true, false).visible)
	actor.set_weapons(true)
	var start: Vector3 = actor.global_position
	Input.action_press("right")
	await frames(35)
	Input.action_release("right")
	await frames(12)
	check("3D horizontal movement", actor.global_position.x - start.x > 1.2, str(actor.global_position))
	actor.reset_to_spawn()
	await frames(30)
	start = actor.global_position
	Input.action_press("forward")
	await frames(35)
	Input.action_release("forward")
	await frames(12)
	check("3D depth movement", start.z - actor.global_position.z > 1.2, str(actor.global_position))
	actor.reset_to_spawn()
	await frames(30)
	start = actor.global_position
	Input.action_press("jump")
	await frames(15)
	Input.action_release("jump")
	check("Jump rises above ground", actor.global_position.y - start.y > 0.5, actor.global_position.y)
	await frames(80)
	check("Jump lands safely", actor.is_on_floor() and absf(actor.global_position.y - start.y) < 0.1)
	actor.global_position = Vector3(0, 0.3, -5.1)
	await frames(20)
	Input.action_press("forward")
	await frames(130)
	Input.action_release("forward")
	check("House/bench collision stops entry", actor.global_position.z > -8.0, str(actor.global_position))
	actor.global_position = Vector3(12.5, 1, 2.5)
	await frames(45)
	check("Bridge has a walkable surface", actor.is_on_floor() and actor.global_position.y > 0.15, str(actor.global_position))
	var resets: int = actor.reset_count
	actor.global_position = Vector3(0, -7, 0)
	await frames(20)
	check("Fall recovery returns to clearing", actor.reset_count == resets + 1 and actor.global_position.distance_to(actor.spawn) < 1)
	actor.yaw = PI / 2
	await frames(3)
	start = actor.global_position
	Input.action_press("forward")
	await frames(30)
	Input.action_release("forward")
	check("Movement relative to rotated camera", actor.global_position.x < start.x - 0.8)
	check("Camera spring arm bounded", actor.arm.get_hit_length() > 0 and actor.arm.get_hit_length() <= actor.arm.spring_length + 0.01, actor.arm.get_hit_length())
	actor.global_position = Vector3(0, 0.25, -5.0)
	actor.yaw = PI
	await frames(15)
	check("Camera retracts against house", actor.arm.get_hit_length() < actor.arm.spring_length - 0.3, actor.arm.get_hit_length())
	var failed := checks.filter(func(item): return not item.passed).size()
	var file := FileAccess.open("res://test_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failed": failed, "engine": Engine.get_version_info()}, "\t"))
	print("STUDY_CHECKS ", checks.size(), " FAILED ", failed)
	scene.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(150)
	quit(1 if failed else 0)
