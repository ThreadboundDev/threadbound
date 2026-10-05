extends SceneTree

func _initialize() -> void:
	call_deferred("render_review")

func render_review() -> void:
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
	var sheet := Image.create(2100, 800, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.035, 0.10, 0.16))
	var frames := [8, 11, 14, 18, 22, 26, 31]
	player._begin_air_double_attack(Vector2.RIGHT, 2)
	visual._animation_player.play(visual._clips[visual._current_action], 0.0)
	visual._animation_player.pause()
	var hand: int = visual._skeleton.find_bone("hand.R")
	var arm: int = visual._skeleton.find_bone("upper_arm.R")
	for row in 2:
		for column in frames.size():
			visual._animation_player.seek(float(frames[column]-1)/30.0, true)
			visual._process(0.0)
			var hand_pos: Vector3 = visual._skeleton.global_transform * visual._skeleton.get_bone_global_pose(hand).origin
			var arm_pos: Vector3 = visual._skeleton.global_transform * visual._skeleton.get_bone_global_pose(arm).origin
			var target := hand_pos.lerp(arm_pos, 0.35)
			visual._camera.size = 1.25
			visual._camera.position = target + (Vector3(-7, 1, 1) if row == 0 else Vector3(-1, 1, 7))
			visual._camera.look_at(target, Vector3.UP)
			await process_frame
			await RenderingServer.frame_post_draw
			var frame: Image = visual._viewport.get_texture().get_image()
			frame.convert(Image.FORMAT_RGBA8)
			frame.resize(300, 400, Image.INTERPOLATE_LANCZOS)
			sheet.blend_rect(frame, Rect2i(0, 0, 300, 400), Vector2i(column*300, row*400))
	assert(sheet.save_png(OS.get_cmdline_user_args()[0]) == OK)
	print("ARM_DETAIL_RENDERED")
	quit()
