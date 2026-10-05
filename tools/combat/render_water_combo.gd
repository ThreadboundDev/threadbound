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
	var sheet := Image.create(1680, 900, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.035, 0.10, 0.16))
	for step in 3:
		player._begin_air_double_attack(Vector2.RIGHT, step)
		visual._animation_player.play(visual._clips[visual._current_action], 0.0)
		visual._animation_player.pause()
		for sample in 7:
			visual._animation_player.seek(float(sample)/6.0*visual.get_action_duration(visual._current_action), true)
			visual._process(0.016)
			await process_frame
			await RenderingServer.frame_post_draw
			var frame: Image = visual._viewport.get_texture().get_image()
			frame.convert(Image.FORMAT_RGBA8)
			frame.resize(240, 270, Image.INTERPOLATE_LANCZOS)
			sheet.blend_rect(frame, Rect2i(0, 0, 240, 270), Vector2i(sample*240, step*300))
	var args := OS.get_cmdline_user_args()
	var path := args[0] if not args.is_empty() else "user://water_combo_review.png"
	assert(sheet.save_png(path) == OK)
	print("WATER_COMBO_RENDERED ", path)
	quit()
