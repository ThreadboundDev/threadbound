extends SceneTree
## Observe the physical and rendered handoff, rather than waiting for it to settle.
var failures: Array[String] = []
var cases: Array[Dictionary] = []
var checks := 0
var baseline := false
const OUT := "res://work/house-handoff-2026-10-27"

func _initialize() -> void:
	baseline = "--baseline" in OS.get_cmdline_user_args()
	call_deferred("run")

func frames(count: int) -> void:
	for i in count: await physics_frame

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("HOUSE_HANDOFF_FAIL "+message)

func sole_y(visual: Node) -> float:
	var bottom := -INF
	for probe: Dictionary in visual._sole_probes:
		var point: Vector3 = visual._skeleton.to_global(visual._skeleton.get_bone_global_pose(probe.bone)*probe.point)
		var pixel: Vector2 = visual._camera.unproject_position(point)
		var world: Vector2 = visual._display.to_global(pixel-Vector2(visual._viewport.size)*.5+visual._display.offset)
		bottom = maxf(bottom,world.y)
	return bottom

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	# Keep the extra verification renderer small beside an open game/editor.
	# Player model resolution and world-space sole measurements are unchanged.
	room.get_node("LakesideArtStage").render_scale = .5
	var art = load("res://Src/Environment/BlueBiome/Comparison/lakeside_painted_comparison.gd").new()
	room.add_child(art)
	await frames(30)
	for enemy in get_nodes_in_group("enemies"): enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var player: CharacterBody2D = room.get_node("Player")
	var visual = player.get_node("Live3DVisual")
	for painted: bool in [true,false]:
		art.set_all(painted)
		for label: String in ["Fisher house","Workshop"]:
			room.focus_landmark(label)
			await frames(35)
			var house = room.get_landmark_house(label)
			check(house.can_use_door(player),label+": grounded at usable door")
			house.request_door(player)
			var trace: Array[Dictionary] = []
			var released := false
			var after := 0
			var ungrounded := 0
			var falling := 0
			var max_pop := 0.0
			var previous_sole := NAN
			for tick in 85:
				await physics_frame
				await process_frame
				var active: bool = is_instance_valid(player.house_door_transition_owner)
				if not active and house.is_player_inside(player): released = true
				var sole := sole_y(visual)
				if released:
					if not player.is_on_floor(): ungrounded += 1
					if visual._logical_animation == &"Fall": falling += 1
					if is_finite(previous_sole): max_pop = maxf(max_pop,absf(sole-previous_sole))
					after += 1
				trace.append({"tick":tick,"active":active,"grounded":player.is_on_floor(),"y":player.position.y,"sole_y":sole,"animation":visual._logical_animation})
				previous_sole = sole
				if after >= 12: break
			check(released,label+": door entry completes")
			check(ungrounded==0,label+": no airborne frames after release (%d)" % ungrounded)
			check(falling==0,label+": no falling pose after release (%d)" % falling)
			check(max_pop<2.5,label+": sole handoff has no visible jump (%.3f px)" % max_pop)
			cases.append({"house":label,"painted":painted,"ungrounded_frames":ungrounded,"fall_frames":falling,"maximum_sole_step":max_pop,"trace":trace})
			house.leave_house()
			await frames(20)
	var result := {"checks":checks,"failures":failures,"cases":cases,"display":DisplayServer.get_name()}
	FileAccess.open(OUT.path_join("before.json" if baseline else "verification.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("HOUSE_HANDOFF ",JSON.stringify({"checks":checks,"failures":failures}))
	room.queue_free()
	await frames(2)
	quit(1 if failures.size() else 0)
