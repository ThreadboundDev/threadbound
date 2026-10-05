extends SceneTree

func _initialize() -> void:
	call_deferred("render_review")

func render_review() -> void:
	var player = load("res://Src/Characters/Player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	var visual = player.live_3d_visual
	visual.set_process(false)
	var water := Node2D.new()
	root.add_child(water)
	player._prototype_water_surfaces[water] = -1000.0
	player._begin_air_double_attack(Vector2.RIGHT, 2)
	visual._animation_player.play(visual._clips[visual._current_action], 0.0)
	visual._animation_player.pause()
	visual._animation_player.seek(7.0 / 30.0, true)
	visual._process(0.016)
	await process_frame
	await RenderingServer.frame_post_draw
	var path := OS.get_cmdline_user_args()[0]
	assert(visual._viewport.get_texture().get_image().save_png(path) == OK)
	quit()
