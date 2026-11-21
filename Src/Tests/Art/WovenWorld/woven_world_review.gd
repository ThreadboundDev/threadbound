extends Node2D
## Standalone art audition. Reuses production player and existing lake backdrops.
## No production scenes, collision systems, equipment or saves are authored here.

const KIT := "res://Assets/BlueBiome/Art/WovenWorldTestKit/"
const DELIVERY := "res://ArtSource/Deliveries/WovenWorldTestKit/"
const PLAYER := preload("res://Src/Characters/Player/player.tscn")
const TILESET := preload("res://Assets/BlueBiome/Art/WovenWorldTestKit/terrain_tileset.tres")
const FAR := preload("res://Assets/BlueBiome/StillVillage/Backgrounds/far_sky_cliffs.png")
const VILLAGE := preload("res://Assets/BlueBiome/StillVillage/Backgrounds/near_lake_village.png")
const STAMPS := ["tree", "foliage_green", "foliage_blossom", "rock_low", "rock_wide", "rock_tall"]
const WORLD_WIDTH := 5120.0
const FLOOR_Y := 800.0
const SPAWNS := [Vector2(760, 720), Vector2(3520, 720)]
const LAYOUT_NAMES := ["01  |  LAKESIDE GROVE", "02  |  ROCK GARDEN"]

var player: CharacterBody2D
var camera: Camera2D
var terrain: TileMapLayer
var status_label: Label
var join_overlay := false
var active_layout := 0
var stamp_usage: Array[Dictionary] = [{}, {}]
var failures: Array[String] = []
var check_count := 0


func _ready() -> void:
	get_window().title = "Threadbound — Woven World Test Kit"
	if DebugUI.debug_label:
		DebugUI.debug_label.hide()
	# The production composite reserves exposure for additive level lights.
	# This daylight fixture lights only its layer, leaving generated art unchanged.
	# DirectionalLight2D ignores item masks; a uniform point-light texture
	# preserves the source colors on scenery while lighting the actor composite.
	var daylight := PointLight2D.new()
	daylight.name = "ReviewDaylight"
	daylight.range_item_cull_mask = 2
	daylight.energy = 0.65
	daylight.position = Vector2(WORLD_WIDTH * 0.5, 540)
	var white := Gradient.new()
	white.colors = PackedColorArray([Color.WHITE, Color.WHITE])
	var light_texture := GradientTexture2D.new()
	light_texture.gradient = white
	light_texture.width = 64
	light_texture.height = 64
	daylight.texture = light_texture
	daylight.texture_scale = 128
	add_child(daylight)
	_build_backdrop()
	_build_terrain()
	_build_layouts()
	# A reviewer may place the real player/camera in the editable scene.
	# Reuse those saved instances and their visual/camera settings.
	player = get_node_or_null("Player") as CharacterBody2D
	if player == null:
		player = PLAYER.instantiate()
		player.name = "Player"
		player.position = SPAWNS[0]
		player.z_index = 2
		add_child(player)
	camera = get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.position = Vector2(960, 540)
		camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		camera.position_smoothing_enabled = false
		add_child(camera)
	_build_review_labels()
	if OS.get_cmdline_user_args().has("--verify-woven-kit"):
		_verify.call_deferred()


func _build_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -20
	add_child(layer)
	var water := ColorRect.new()
	water.color = Color("88cbd3")
	water.size = Vector2(1920, 1080)
	layer.add_child(water)
	var far := Sprite2D.new()
	far.texture = FAR
	far.centered = false
	far.scale = Vector2(1920.0 / FAR.get_width(), 850.0 / FAR.get_height())
	layer.add_child(far)
	var village := Sprite2D.new()
	village.texture = VILLAGE
	village.centered = false
	village.position = Vector2(0, 470)
	village.scale = Vector2(1920.0 / VILLAGE.get_width(), 400.0 / VILLAGE.get_height())
	layer.add_child(village)


func _build_terrain() -> void:
	terrain = TileMapLayer.new()
	terrain.name = "WovenTerrainArt"
	terrain.tile_set = TILESET
	terrain.collision_enabled = false
	terrain.position.y = FLOOR_Y - 28.0
	terrain.z_index = -5
	add_child(terrain)
	for x in 20:
		terrain.set_cell(Vector2i(x, 0), 0, Vector2i(x % 2, 0))
		terrain.set_cell(Vector2i(x, 1), 0, Vector2i(2, 0))
	_collision_rect(Rect2(0, FLOOR_Y, WORLD_WIDTH, 64))
	_collision_rect(Rect2(-64, -200, 64, 1600))
	_collision_rect(Rect2(WORLD_WIDTH, -200, 64, 1600))


func _build_layouts() -> void:
	_stamp(0, "tree", Vector2(310, 810), 760, -8)
	_stamp(0, "foliage_blossom", Vector2(1840, 270), 240, -7).flip_h = true
	_stamp(0, "rock_tall", Vector2(1730, 817), 360, -4)
	_stamp(0, "rock_low", Vector2(1050, 808), 105, -4)
	_stamp(0, "foliage_green", Vector2(220, 812), 90, 3)
	_stamp(0, "foliage_green", Vector2(1510, 811), 65, 3)
	_platform(0, Rect2(1152, 584, 512, 18))
	_stamp(1, "tree", Vector2(4370, 812), 680, -8)
	_stamp(1, "foliage_blossom", Vector2(2500, 320), 250, -7)
	_stamp(1, "rock_low", Vector2(2740, 808), 155, -4)
	_stamp(1, "rock_tall", Vector2(3080, 812), 410, -4)
	_stamp(1, "foliage_green", Vector2(3030, 813), 85, 3)
	_stamp(1, "foliage_green", Vector2(4610, 811), 60, 3)
	_platform(1, Rect2(3712, 610, 576, 18))
	_platform(1, Rect2(4352, 450, 448, 18))


func _stamp(layout: int, id: String, base: Vector2, height: float, depth: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(KIT + id + ".png") as Texture2D
	sprite.scale = Vector2.ONE * height / sprite.texture.get_height()
	sprite.offset.y = -sprite.texture.get_height() * 0.5
	sprite.position = base
	sprite.z_index = depth
	sprite.name = id.capitalize().replace(" ", "") + str(layout)
	add_child(sprite)
	stamp_usage[layout][id] = int(stamp_usage[layout].get(id, 0)) + 1
	return sprite


func _platform(layout: int, rectangle: Rect2) -> void:
	var texture := load(KIT + "rock_wide.png") as Texture2D
	var art_height := rectangle.size.x / texture.get_width() * texture.get_height()
	_stamp(layout, "rock_wide", Vector2(rectangle.get_center().x, rectangle.position.y - 10 + art_height), art_height, -3)
	_collision_rect(rectangle, true)


func _collision_rect(rectangle: Rect2, one_way := false) -> void:
	var body := StaticBody2D.new()
	body.position = rectangle.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rectangle.size
	collider.shape = shape
	collider.one_way_collision = one_way
	body.add_child(collider)
	add_child(body)


func _build_review_labels() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.08, 0.85)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 22)
	rows.add_child(status_label)
	var help := Label.new()
	help.text = "1 / 2: switch views    T: terrain joins    R: reset\nUse your normal movement and jump controls."
	help.add_theme_font_size_override("font_size", 17)
	help.modulate = Color("cbdcdd")
	rows.add_child(help)
	_update_label()


func _update_label() -> void:
	status_label.text = "WOVEN WORLD  /  " + LAYOUT_NAMES[active_layout]
	if join_overlay:
		status_label.text += "  /  JOINS VISIBLE"


func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	if camera.get_script() == null:
		camera.position.x = clampf(player.position.x, 960, WORLD_WIDTH - 960)
	var layout := 0 if player.position.x < 2560 else 1
	if active_layout != layout:
		active_layout = layout
		_update_label()
	if player.position.y > 1250:
		_switch_layout(active_layout)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: _switch_layout(0)
		KEY_2: _switch_layout(1)
		KEY_R: _switch_layout(active_layout)
		KEY_T:
			join_overlay = not join_overlay
			get_tree().debug_collisions_hint = join_overlay
			_update_label()
			queue_redraw()
		_: return
	get_viewport().set_input_as_handled()


func _switch_layout(index: int) -> void:
	active_layout = index
	player.position = SPAWNS[index]
	player.velocity = Vector2.ZERO
	_update_label()


func _draw() -> void:
	if not join_overlay:
		return
	for x in 21:
		draw_line(Vector2(x * 256, terrain.position.y), Vector2(x * 256, 1080), Color(1, 0.65, 0.1, 0.8), 2)
	draw_line(Vector2(0, FLOOR_Y), Vector2(WORLD_WIDTH, FLOOR_Y), Color(0.1, 0.9, 0.5, 0.9), 2)
	draw_line(Vector2(0, terrain.position.y + 256), Vector2(WORLD_WIDTH, terrain.position.y + 256), Color(1, 0.65, 0.1, 0.8), 2)


func _check(ok: bool, message: String) -> void:
	check_count += 1
	if not ok:
		failures.append(message)
		push_error("WOVEN_KIT_FAIL: " + message)


func _physics_frames(count: int) -> void:
	for frame in count:
		await get_tree().physics_frame


func _verify() -> void:
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1920, 1080)
	for id in STAMPS:
		_check(stamp_usage[0].has(id) and stamp_usage[1].has(id), "Both arrangements reuse stamp: " + id)
		var image := Image.load_from_file(ProjectSettings.globalize_path(KIT + id + ".png"))
		_check(image != null and not image.is_empty(), "Readable stamp: " + id)
		_check(image.get_pixel(0, 0).a < 0.1, "Transparent stamp corner: " + id)
		image = null
	_check(not terrain.collision_enabled, "Terrain art remains separate from collision.")
	_check($ReviewDaylight is PointLight2D and $ReviewDaylight.range_item_cull_mask == 2, "Daylight uses actor-only light masking.")
	_check((terrain.light_mask & 2) == 0, "Terrain does not receive additive actor daylight.")
	var atlas := Image.load_from_file(ProjectSettings.globalize_path(KIT + "terrain_atlas.png"))
	for left in 2:
		for right in 2:
			var errors := 0
			for y in 256:
				if atlas.get_pixel(left * 256 + 255, y) != atlas.get_pixel(right * 256, y):
					errors += 1
			_check(errors == 0, "Top tile border %d -> %d" % [left, right])
	for top in 3:
		var errors := 0
		for x in 256:
			if atlas.get_pixel(top * 256 + x, 255) != atlas.get_pixel(512 + x, 0):
				errors += 1
		_check(errors == 0, "Vertical fill border below tile %d" % top)
	atlas = null
	var live_visual: Node = player.get_node("Live3DVisual")
	_check(live_visual.get("model_scene").resource_path.ends_with("threadborne_doll_modular.glb"), "Actual modular wooden doll is loaded.")
	for layout in 2:
		_switch_layout(layout)
		await _physics_frames(45)
		_check(player.is_on_floor(), "Player stands on terrain in view %d" % layout)
		var start := player.position
		Input.action_press("move_right")
		await _physics_frames(30)
		Input.action_release("move_right")
		_check(player.position.x > start.x + 70, "Player can traverse terrain joins in view %d" % layout)
		await _physics_frames(25)
		var ground_y := player.position.y
		Input.action_press("Jump")
		await _physics_frames(3)
		Input.action_release("Jump")
		await _physics_frames(12)
		_check(player.position.y < ground_y - 30, "Player can jump in view %d" % layout)
		await _physics_frames(90)
		_check(player.is_on_floor(), "Player lands after jump in view %d" % layout)
		_switch_layout(layout)
		await _physics_frames(45)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var capture := get_viewport().get_texture().get_image()
			_check(capture.save_png(DELIVERY + "layout_%s.png" % ("a" if layout == 0 else "b")) == OK, "Saved native-size view %d" % layout)
			capture = null
	if DisplayServer.get_name() != "headless":
		join_overlay = true
		queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var capture := get_viewport().get_texture().get_image()
		_check(capture.save_png(DELIVERY + "terrain_join_view.png") == OK, "Saved exposed terrain joins.")
		capture = null
	var result := {"checks": check_count, "failures": failures, "renderer": RenderingServer.get_current_rendering_method(), "player_model": live_visual.get("model_scene").resource_path}
	var file := FileAccess.open(DELIVERY + "godot_checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ") + "\n")
	file.close()
	print("WOVEN_KIT_CHECKS ", JSON.stringify(result))
	player.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
