extends SceneTree
## Local comparison of native-resolution rendered movement frames in the Chamber.

var output_dir := ""
var player
var live: Sprite2D
var sprite: AnimatedSprite2D
var show_baked := true
var toggle_was_down := false
var status: Label
var anchor_offset: Vector2

func _initialize() -> void:
	call_deferred("run")

func wait_physics(count: int) -> void:
	for i in count:
		await physics_frame

func update_visual() -> void:
	if not is_instance_valid(player) or not is_instance_valid(live):
		return
	var down := Input.is_physical_key_pressed(KEY_F7)
	if down and not toggle_was_down:
		show_baked = not show_baked
	toggle_was_down = down
	live.visible = not show_baked
	sprite.visible = show_baked
	sprite.position = live.position
	sprite.flip_h = live.flip_h
	sprite.offset = Vector2(-anchor_offset.x if sprite.flip_h else anchor_offset.x, anchor_offset.y)
	var clip := &"idle"
	if not player.is_on_floor():
		clip = &"jump"
	elif absf(player.velocity.x) > 20:
		clip = &"run"
	if sprite.animation != clip:
		sprite.play(clip)
	status.text = "F7  |  " + ("Baked sprite study" if show_baked else "Current live player")

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output_dir.path_join(name + ".png")) == OK)

func run() -> void:
	assert(OS.get_user_data_dir().contains("Threadbound Sprite Study"))
	var repository := ProjectSettings.globalize_path("res://").path_join("../../..").simplify_path()
	output_dir = repository.path_join("LocalOnly/OG_Material_Review")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(output_dir.path_join("og_baked_manifest.json")))
	assert(manifest is Dictionary and manifest.frames.size() > 0)
	anchor_offset = Vector2(manifest.offset[0], manifest.offset[1])
	var library := SpriteFrames.new()
	library.remove_animation(&"default")
	for clip in [&"idle", &"run", &"jump"]:
		var atlas_image := Image.load_from_file(output_dir.path_join("OG_" + String(clip) + "_atlas.png"))
		assert(atlas_image != null and not atlas_image.is_empty())
		var atlas := ImageTexture.create_from_image(atlas_image)
		library.add_animation(clip)
		library.set_animation_speed(clip, 12.0)
		library.set_animation_loop(clip, clip != &"jump")
		for frame in manifest.frames:
			if frame.clip != String(clip):
				continue
			var texture := AtlasTexture.new()
			texture.atlas = atlas
			texture.region = Rect2(frame.region[0],frame.region[1],frame.region[2],frame.region[3])
			texture.filter_clip = true
			library.add_frame(clip,texture,frame.duration_ms * 0.012)
	var room: Node = load("res://Src/Environment/World/Chamber Of The First Weave.tscn").instantiate()
	room.get_node("TutorialController").tutorial_enabled = false
	var welcome := room.get_node_or_null("PlaytestWelcome")
	if welcome != null:
		welcome.free()
	root.add_child(room)
	current_scene = room
	player = room.get_node("Player")
	await wait_physics(100)
	live = player.live_3d_visual._display
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = library
	sprite.scale = Vector2.ONE * float(manifest.game_scale)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = unshaded
	player.add_child(sprite)
	sprite.play(&"idle")
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	status = Label.new()
	status.position = Vector2(24, 325)
	status.add_theme_font_size_override("font_size",20)
	status.add_theme_color_override("font_shadow_color",Color.BLACK)
	status.add_theme_constant_override("shadow_offset_x",2)
	status.add_theme_constant_override("shadow_offset_y",2)
	overlay.add_child(status)
	process_frame.connect(update_visual)
	await wait_physics(3)
	print("OG_BAKED_PREVIEW_READY frames=",manifest.frames.size())
	if "--verify" in OS.get_cmdline_user_args():
		assert(player.is_on_floor() and sprite.animation == &"idle")
		await capture("Chamber_OG_Idle")
		var start: float = player.position.x
		Input.action_press("move_right")
		await wait_physics(26)
		assert(player.position.x > start + 20 and sprite.animation == &"run")
		await capture("Chamber_OG_Run")
		Input.action_release("move_right")
		await wait_physics(30)
		Input.action_press("Jump")
		await wait_physics(10)
		Input.action_release("Jump")
		assert(not player.is_on_floor() and sprite.animation == &"jump")
		await capture("Chamber_OG_Jump")
		await wait_physics(90)
		assert(player.is_on_floor())
		Input.action_press("move_left")
		await wait_physics(12)
		Input.action_release("move_left")
		assert(sprite.flip_h)
		show_baked = false
		await wait_physics(2)
		assert(live.visible and not sprite.visible)
		await capture("Chamber_Current_Player")
		print("OG_BAKED_PREVIEW_VERIFIED movement, jump, landing, facing, live toggle")
		quit()
