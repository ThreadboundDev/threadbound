extends SceneTree

func _initialize() -> void:
	call_deferred("render_review")

func render_review() -> void:
	var output := OS.get_cmdline_user_args()[0]
	var detail := OS.get_cmdline_user_args().size() > 1 and OS.get_cmdline_user_args()[1] == "detail"
	DirAccess.make_dir_recursive_absolute(output)
	var world := Node2D.new()
	root.add_child(world)
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	var visual = player.live_3d_visual
	visual.set_process(false)
	var water := Node2D.new()
	world.add_child(water)
	player._prototype_water_surfaces[water] = -1000.0
	player.last_direction = 1
	await process_frame
	var default_camera: Transform3D = visual._camera.transform
	var default_size: float = visual._camera.size
	var hand: int = visual._skeleton.find_bone("hand.R")
	var upper_arm: int = visual._skeleton.find_bone("upper_arm.R")
	var index := 0
	for step in 3:
		player._begin_air_double_attack(Vector2.RIGHT, step)
		visual._animation_player.play(visual._clips[visual._current_action], 0.0)
		visual._animation_player.pause()
		var duration: float = visual.get_action_duration(visual._current_action)
		for sample in int(round(duration * 30.0)) + 1:
			visual._animation_player.seek(minf(sample / 30.0, duration), true)
			visual._process(0.0)
			visual._camera.transform = default_camera
			visual._camera.size = default_size * (0.85 if detail else 1.0)
			await process_frame
			await RenderingServer.frame_post_draw
			var frame: Image = visual._viewport.get_texture().get_image()
			frame.convert(Image.FORMAT_RGBA8)
			if detail:
				var pair := Image.create(1024, 512, false, Image.FORMAT_RGBA8)
				pair.fill(Color(0.035, 0.10, 0.16))
				frame.resize(512, 512, Image.INTERPOLATE_LANCZOS)
				pair.blend_rect(frame, Rect2i(0, 0, 512, 512), Vector2i.ZERO)
				var hand_pos: Vector3 = visual._skeleton.global_transform * visual._skeleton.get_bone_global_pose(hand).origin
				var arm_pos: Vector3 = visual._skeleton.global_transform * visual._skeleton.get_bone_global_pose(upper_arm).origin
				var target := hand_pos.lerp(arm_pos, 0.35)
				visual._camera.size = 1.3
				visual._camera.position = target + Vector3(-1, 1, 7)
				visual._camera.look_at(target, Vector3.UP)
				await process_frame
				await RenderingServer.frame_post_draw
				var closeup: Image = visual._viewport.get_texture().get_image()
				closeup.convert(Image.FORMAT_RGBA8)
				closeup.resize(512, 512, Image.INTERPOLATE_LANCZOS)
				pair.blend_rect(closeup, Rect2i(0, 0, 512, 512), Vector2i(512, 0))
				frame = pair
			assert(frame.save_png(output.path_join("frame_%03d.png" % index)) == OK)
			index += 1
	print("WATER_COMBO_MOTION_RENDERED ", index, " frames: ", output)
	quit()
