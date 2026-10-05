extends SceneTree

func _initialize() -> void:
	call_deferred("render_review")

func render_review() -> void:
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	var visual = player.live_3d_visual
	visual.set_process(false)
	visual._logical_animation = &"Air_Double_Attack"
	player.last_direction = 1
	await process_frame
	var sheet := Image.create(1600, 1440, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.035, 0.10, 0.16))
	var actions: Array[StringName] = [&"slash_1", &"slash_2", &"attack_1", &"water_idle_1"]
	for row in actions.size():
		visual._current_action = actions[row]
		visual._animation_player.play(visual._clips[actions[row]], 0.0)
		visual._animation_player.pause()
		var duration: float = 1.15 if row == 1 else visual.get_action_duration(actions[row])
		for sample in 5:
			visual._animation_player.seek(float(sample) / 4.0 * duration, true)
			visual._process(0.016)
			await process_frame
			await RenderingServer.frame_post_draw
			var frame: Image = visual._viewport.get_texture().get_image()
			frame.convert(Image.FORMAT_RGBA8)
			frame.resize(320, 360, Image.INTERPOLATE_LANCZOS)
			sheet.blend_rect(frame, Rect2i(0, 0, 320, 360), Vector2i(sample * 320, row * 360))
	assert(sheet.save_png(OS.get_cmdline_user_args()[0]) == OK)
	quit()
