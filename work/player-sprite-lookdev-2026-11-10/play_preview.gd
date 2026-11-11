extends SceneTree
## Isolated visual trial. Production controller and equipment code are untouched.
const OUT := "res://review"
var room: Node
var player
var sprite: AnimatedSprite2D

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func update_visual() -> void:
	if not is_instance_valid(player) or not is_instance_valid(sprite):
		return
	sprite.global_position = player.global_position + Vector2(0, 69.245)
	sprite.flip_h = player.get_presentation_facing() < 0
	var clip := "idle"
	if not player.is_on_floor():
		clip = "jump"
	elif absf(player.velocity.x) > 20:
		clip = "run"
	if sprite.animation != clip:
		sprite.play(clip)

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUT + "/play_" + name + ".png") == OK)

func run() -> void:
	assert(OS.get_user_data_dir().contains("Threadbound Sprite Study"))
	room = load("res://Src/Environment/World/Chamber Of The First Weave.tscn").instantiate()
	room.get_node("TutorialController").tutorial_enabled = false
	var welcome := room.get_node_or_null("PlaytestWelcome")
	if welcome != null:
		welcome.free()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	await frames(100)
	player.hide()
	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-120, -296)
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = material
	var library := SpriteFrames.new()
	library.remove_animation("default")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(OUT + "/sprite_manifest.json"))
	for clip in ["idle", "run", "jump"]:
		var image := Image.load_from_file(OUT + "/sprites/" + clip + ".png")
		assert(image != null)
		var atlas := ImageTexture.create_from_image(image)
		library.add_animation(clip)
		library.set_animation_loop(clip, clip != "jump")
		library.set_animation_speed(clip, 12.0)
		for record in manifest.frames:
			if record.clip != clip:
				continue
			var frame := AtlasTexture.new()
			frame.atlas = atlas
			frame.region = Rect2(record.region[0], record.region[1], 240, 320)
			library.add_frame(clip, frame)
	sprite.sprite_frames = library
	room.add_child(sprite)
	sprite.play("idle")
	process_frame.connect(update_visual)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	var label := Label.new()
	label.text = "SPRITE VISUAL TRIAL | normal movement controls | idle / run / jump only"
	label.position = Vector2(24, 18)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(label)
	print("SPRITE_PLAY_PREVIEW_READY")
	if "--verify" in OS.get_cmdline_user_args():
		assert(player.is_on_floor())
		await shot("idle")
		var start: float = player.position.x
		Input.action_press("move_right")
		await frames(30)
		assert(player.position.x > start + 20)
		assert(sprite.animation == "run")
		await shot("run")
		Input.action_release("move_right")
		await frames(30)
		Input.action_press("Jump")
		await frames(10)
		Input.action_release("Jump")
		assert(not player.is_on_floor())
		assert(sprite.animation == "jump")
		await shot("jump")
		await frames(90)
		assert(player.is_on_floor())
		var report := {"checks": 6, "movement_and_jump": "passed", "production_controller_modified": false, "visual_clips": ["idle", "run", "jump"], "combat_and_equipment_animation": "unsupported in this visual trial", "user_data": OS.get_user_data_dir()}
		FileAccess.open(OUT + "/play_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
		print("SPRITE_PLAY_VERIFIED ", JSON.stringify(report))
		quit()
