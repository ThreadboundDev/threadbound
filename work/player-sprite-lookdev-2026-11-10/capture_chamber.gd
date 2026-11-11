extends SceneTree
## Visual study in the real Chamber scene, using a separate user-data project.
## This does not install a player replacement or certify gameplay integration.

const OUT := "res://review"
var scene: Node
var camera: Camera2D
var title: Label

func _initialize() -> void:
	call_deferred("run")

func wait_frames(count: int) -> void:
	for i in count:
		await physics_frame

func screenshot(filename: String, caption: String) -> void:
	title.text = caption
	camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUT + "/" + filename)
	assert(error == OK, "Screenshot writes successfully")

func image_texture(path: String) -> ImageTexture:
	var image := Image.load_from_file(path)
	assert(image != null and not image.is_empty(), "Review image loads: " + path)
	return ImageTexture.create_from_image(image)

func run() -> void:
	assert(OS.get_user_data_dir().contains("Threadbound Sprite Study"), "Use prepare_preview.ps1, never the production save directory")
	assert(DisplayServer.get_name() != "headless", "Visual capture requires a rendering window")
	for action in InputMap.get_actions():
		InputMap.action_erase_events(action)
	scene = load("res://Src/Environment/World/Chamber Of The First Weave.tscn").instantiate()
	scene.get_node("TutorialController").tutorial_enabled = false
	var welcome := scene.get_node_or_null("PlaytestWelcome")
	if welcome != null:
		welcome.free()
	root.add_child(scene)
	current_scene = scene
	await wait_frames(100)
	var player = scene.get_node("Player")
	assert(player.is_on_floor(), "Existing controller settles on the Chamber floor")
	var feet: Vector2 = player.global_position + Vector2(0, 69.245)
	# Freeze game logic for matched framing and side-by-side presentation only.
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	for layer in root.find_children("*", "CanvasLayer", true, false):
		layer.hide()
	for old in scene.find_children("*", "Camera2D", true, false):
		old.enabled = false
	camera = Camera2D.new()
	camera.position = player.global_position + Vector2(0, -35)
	camera.zoom = Vector2.ONE
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	scene.add_child(camera)
	camera.make_current()
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.03, 0.04, 0.05, 0.88)
	backdrop.position = Vector2(18, 16)
	backdrop.size = Vector2(1235, 66)
	overlay.add_child(backdrop)
	title = Label.new()
	title.position = Vector2(34, 31)
	title.add_theme_font_size_override("font_size", 22)
	overlay.add_child(title)
	await screenshot("chamber_current.png", "CURRENT PLAYER / matched Chamber camera / visual comparison")
	player.hide()
	var sprite := Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = false
	sprite.texture = image_texture(OUT + "/illustrated_equipped.png")
	sprite.scale = Vector2(0.4, 0.4)
	sprite.offset = Vector2(-300, -740)
	sprite.position = feet
	sprite.z_index = player.z_index
	scene.add_child(sprite)
	await screenshot("chamber_rendered_lit.png", "RENDERED SPRITE STUDY / receives the Chamber's 2D lighting")
	var baked_color_material := CanvasItemMaterial.new()
	baked_color_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = baked_color_material
	await screenshot("chamber_rendered.png", "RENDERED SPRITE STUDY / baked colors preserved / actual Chamber scene")
	# Original reference and study at equal 180 px standing height, placed on the same floor.
	var reference_image := Image.load_from_file(OUT + "/reference_for_engine.png")
	assert(reference_image != null)
	var old_sprite := Sprite2D.new()
	old_sprite.centered = false
	old_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	old_sprite.texture = ImageTexture.create_from_image(reference_image)
	old_sprite.material = baked_color_material
	old_sprite.position = feet + Vector2(-220, 0)
	old_sprite.offset = Vector2(-reference_image.get_width() / 2.0, -reference_image.get_height())
	scene.add_child(old_sprite)
	sprite.texture = image_texture(OUT + "/reference_study_for_engine.png")
	sprite.scale = Vector2.ONE
	sprite.offset = Vector2(-sprite.texture.get_width() / 2.0, -sprite.texture.get_height())
	sprite.position = feet + Vector2(220, 0)
	await screenshot("chamber_reference_pair.png", "OLD 2D REFERENCE (left) / RENDERED STUDY (right) / both 180 px / actual Chamber scene")
	var report := {"scene": scene.scene_file_path, "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "user_data": OS.get_user_data_dir(), "player_on_floor": player.is_on_floor(), "feet": str(feet), "production_files_modified": false, "controller_integrated": false, "sprite_material": "Unshaded for baked-color comparison; lit variant also saved", "purpose": "Frozen-scene visual comparison only"}
	FileAccess.open(OUT + "/chamber_capture_report.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("SPRITE_CHAMBER_CAPTURE ", JSON.stringify(report))
	scene.queue_free()
	overlay.queue_free()
	await process_frame
	await process_frame
	scene = null
	camera = null
	title = null
	player = null
	sprite = null
	old_sprite = null
	reference_image = null
	baked_color_material = null
	quit()
