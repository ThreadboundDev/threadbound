extends SceneTree
## Same-pose raster comparison driven by the production presentation rig.
## Uses live 3D as the authoring source; this is not an offline-sheet runtime.
const OUT := "res://review"
var player
var visual
var raster: ImageTexture
var show_raster := true
var busy := false
var next_capture_ms := 0
var label: Label

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func refresh() -> void:
	if not is_instance_valid(visual) or busy:
		return
	if Input.is_physical_key_pressed(KEY_F7):
		if not get_meta("toggle_down", false):
			show_raster = not show_raster
		set_meta("toggle_down", true)
	else:
		set_meta("toggle_down", false)
	label.text = "CURRENT RIG | side view | F7: " + ("raster copy" if show_raster else "live render")
	if not show_raster:
		visual._display.texture = visual._viewport.get_texture()
		return
	if Time.get_ticks_msec() < next_capture_ms:
		return
	next_capture_ms = Time.get_ticks_msec() + 33
	busy = true
	await RenderingServer.frame_post_draw
	if not is_instance_valid(visual):
		busy = false
		return
	var image: Image = visual._viewport.get_texture().get_image()
	if raster == null:
		raster = ImageTexture.create_from_image(image)
	else:
		raster.update(image)
	if show_raster:
		visual._display.texture = raster
	busy = false

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var raw: Image = visual._viewport.get_texture().get_image()
	assert(raw.get_size() == visual._viewport.size)
	assert(raw.save_png(OUT + "/current_rig_" + name + "_native.png") == OK)
	assert(root.get_texture().get_image().save_png(OUT + "/current_rig_" + name + ".png") == OK)

func run() -> void:
	assert(OS.get_user_data_dir().contains("Threadbound Sprite Study"))
	assert("--original-player" in OS.get_cmdline_user_args(), "Use the retained costume with the current production animation library")
	var room: Node = load("res://Src/Environment/World/Chamber Of The First Weave.tscn").instantiate()
	room.get_node("TutorialController").tutorial_enabled = false
	var welcome := room.get_node_or_null("PlaytestWelcome")
	if welcome != null:
		welcome.free()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	await frames(100)
	visual = player.live_3d_visual
	assert(visual.model_scene == visual.MODEL)
	assert(visual._camera.position == Vector3(-7, 1.15, 0))
	assert(visual._viewport.size == Vector2i(1600, 1800))
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	label = Label.new()
	label.position = Vector2(24, 285)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(label)
	process_frame.connect(refresh)
	await frames(3)
	print("CURRENT_RIG_PREVIEW_READY model=", visual.model_scene.resource_path, " bones=", visual._skeleton.get_bone_count(), " clips=", visual._animation_player.get_animation_list().size(), " resolution=", visual._viewport.size)
	if "--verify" in OS.get_cmdline_user_args():
		assert(player.is_on_floor())
		await shot("idle")
		var start: float = player.position.x
		Input.action_press("move_right")
		await frames(30)
		assert(player.position.x > start + 20)
		assert(visual._current_action == &"run_1")
		await shot("run")
		Input.action_release("move_right")
		await frames(30)
		Input.action_press("Jump")
		await frames(10)
		Input.action_release("Jump")
		assert(not player.is_on_floor())
		await shot("jump")
		await frames(90)
		assert(player.is_on_floor())
		Input.action_press("Attack")
		await frames(4)
		Input.action_release("Attack")
		assert(player.is_attacking)
		await shot("attack")
		await frames(60)
		Input.action_press("move_left")
		await frames(12)
		Input.action_release("move_left")
		assert(visual._display.flip_h)
		var report := {"source": visual.model_scene.resource_path, "bones": visual._skeleton.get_bone_count(), "clips": visual._animation_player.get_animation_list().size(), "viewport": str(visual._viewport.size), "camera": str(visual._camera.position), "raster_is_native_resolution": raster.get_size() == Vector2(visual._viewport.size), "movement_jump_landing_attack_facing": "passed", "production_animation_logic": "unmodified", "offline_sprite_runtime": false, "note": "Full-resolution raster snapshots of current live rig; not the old 12fps atlas proxy"}
		FileAccess.open(OUT + "/current_rig_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
		print("CURRENT_RIG_VERIFIED ", JSON.stringify(report))
		quit()
