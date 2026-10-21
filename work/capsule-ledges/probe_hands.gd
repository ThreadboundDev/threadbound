extends SceneTree
func _initialize() -> void:
	call_deferred("probe")
func probe() -> void:
	var p = load("res://Src/Characters/Player/player.tscn").instantiate()
	root.add_child(p)
	p.set_physics_process(false)
	await process_frame
	await process_frame
	p.process_mode = Node.PROCESS_MODE_DISABLED
	var v = p.live_3d_visual
	var samples := {}
	for key: String in ["hanging_idle_1","jump_into_wall_hang_1","grab_ledge_from_water_1","jump_3"]:
		if not v._clips.has(key):
			continue
		var clip: String = v._clips[key]
		v._animation_player.play(clip)
		v._animation_player.seek(0.0,true)
		v._animation_player.pause()
		v._process(0.0)
		var offsets := []
		for bone: String in ["hand.L","hand.R"]:
			var index: int = v._skeleton.find_bone(bone)
			var world: Vector3 = v._skeleton.to_global(v._skeleton.get_bone_global_pose(index).origin)
			var pixel: Vector2 = v._camera.unproject_position(world) - Vector2(v._viewport.size)*0.5 + v._display.offset
			offsets.append(str(v._display.transform*pixel))
		samples[key] = offsets
	print("HAND_PROBE ",JSON.stringify(samples))
	p.queue_free()
	await process_frame
	quit()
