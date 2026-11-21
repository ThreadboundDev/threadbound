extends "res://Src/Tests/Art/WovenWorld/woven_world_review.gd"
## Reuses the previous audition's player, backdrop, lighting and review helpers.
## Geometry and decorations are native authored placeables in the companion scene.

const CHUNKS := "res://Assets/BlueBiome/Art/WovenWorldChunks/"
const CHUNK_DELIVERY := "res://ArtSource/Deliveries/WovenWorldChunks/"
const ROUTE_WIDTH := 5504.0
const REVIEW_SPAWNS := [Vector2(720, 720), Vector2(2450, 624), Vector2(4540, 688)]
const REVIEW_NAMES := ["LAKESIDE APPROACH", "GREEN CANOPY", "UPPER SHELF"]
const CONTACT_SHADOW := preload("res://Src/Tests/Art/WovenWorld/woven_contact_shadow.gd")
const REFINEMENT := "res://Assets/BlueBiome/Art/WovenWorldChunks/GroundingRefinement/"

var asset_records: Dictionary
var surfaces: Array[Dictionary] = []
var fall_resets := 0
var contact_shadow: Node2D
var refinement_records: Dictionary
var foliage_preview: Sprite2D
var foliage_original_texture: Texture2D
var foliage_original_offset := Vector2.ZERO
var foliage_mode := 2


func _ready() -> void:
	asset_records = JSON.parse_string(FileAccess.get_file_as_string(CHUNKS + "asset_metadata.json"))["assets"]
	super._ready()
	_apply_grounding_refinement()
	contact_shadow = CONTACT_SHADOW.new()
	contact_shadow.name = "PlayerContactShadow"
	contact_shadow.target = player
	contact_shadow.receivers = surfaces
	add_child(contact_shadow)
	get_window().title = "Threadbound — Woven Chunk Level"
	var help := status_label.get_parent().get_child(1) as Label
	help.text = "1 / 2 / 3: review positions    C: collision    R: return to start\nV: compare foliage bases    Normal movement and jump controls."
	_switch_layout(0)
	if OS.get_cmdline_user_args().has("--verify-woven-chunks"):
		_verify.call_deferred()


func _apply_grounding_refinement() -> void:
	refinement_records = JSON.parse_string(FileAccess.get_file_as_string(REFINEMENT + "asset_metadata.json"))
	# Keep physics surfaces fixed; register artwork so the standing line falls
	# inside the visible top plane instead of on its rear edge.
	for surface in surfaces:
		if surface.kind == "ground":
			var art := surface.node.get_node("Art") as Sprite2D
			art.position.y -= 12
	var platform_art := $Geometry/BridgeA/Art as Sprite2D
	platform_art.texture = load(REFINEMENT + "platform_integrated_top.png")
	platform_art.position.y = -float(refinement_records.platform_integrated_top.anchor_y)
	foliage_preview = get_node_or_null("Planting/LeafClusterMiddle") as Sprite2D
	if foliage_preview:
		foliage_original_texture = foliage_preview.texture
		foliage_original_offset = foliage_preview.offset
		_update_foliage_preview()


func _update_foliage_preview() -> void:
	if not foliage_preview:
		return
	if foliage_mode == 0:
		foliage_preview.texture = foliage_original_texture
		foliage_preview.offset = foliage_original_offset
	else:
		var id := "foliage_soft_base" if foliage_mode == 1 else "foliage_rim"
		var data: Dictionary = refinement_records[id]
		foliage_preview.texture = load(REFINEMENT + id + ".png")
		foliage_preview.offset = Vector2(0, float(data.height) * 0.5 - float(data.anchor_y))


func _build_backdrop() -> void:
	# Deep gaps expose more water than the previous flat-ground audition.
	# Extend the existing lake pixels through that view instead of ending the
	# backdrop at y=850 and exposing a flat-color horizontal boundary.
	var layer := CanvasLayer.new()
	layer.layer = -20
	add_child(layer)
	var source_horizon := int(FAR.get_height() * 0.884)
	for slice in [
		{"region": Rect2(0, 0, FAR.get_width(), source_horizon), "y": 0.0, "height": 704.0},
		{"region": Rect2(0, source_horizon, FAR.get_width(), FAR.get_height() - source_horizon), "y": 704.0, "height": 376.0},
	]:
		var atlas := AtlasTexture.new()
		atlas.atlas = FAR
		atlas.region = slice.region
		atlas.filter_clip = true
		var sprite := Sprite2D.new()
		sprite.texture = atlas
		sprite.centered = false
		sprite.position.y = slice.y
		sprite.scale = Vector2(1920.0 / atlas.get_width(), float(slice.height) / atlas.get_height())
		layer.add_child(sprite)
	var village := Sprite2D.new()
	village.texture = VILLAGE
	village.centered = false
	village.position = Vector2(0, 470)
	village.scale = Vector2(1920.0 / VILLAGE.get_width(), 400.0 / VILLAGE.get_height())
	layer.add_child(village)


func _build_terrain() -> void:
	for piece in $Geometry.get_children():
		var id: String = piece.get_meta("asset_id")
		var data: Dictionary = asset_records[id]
		surfaces.append({"id": id, "node": piece, "kind": data.kind,
			"left": piece.position.x + float(data.surface_left),
			"right": piece.position.x + float(data.surface_right), "y": piece.position.y})
	_collision_rect(Rect2(-64, -200, 64, 1600))
	_collision_rect(Rect2(5304, -200, 64, 1600))


func _build_layouts() -> void:
	pass # Artwork is authored in the scene; no repeated tiles or procedural fill.


func _update_label() -> void:
	status_label.text = "WOVEN CHUNKS  /  " + REVIEW_NAMES[active_layout]
	if join_overlay:
		status_label.text += "  /  COLLISION"


func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	if camera.get_script() == null:
		camera.position.x = clampf(player.position.x, 960, ROUTE_WIDTH - 960)
	var zone := 0 if player.position.x < 1800 else (1 if player.position.x < 3500 else 2)
	if active_layout != zone:
		active_layout = zone
		_update_label()
	if player.position.y > 1280:
		fall_resets += 1
		_switch_layout(active_layout)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: _switch_layout(0)
		KEY_2: _switch_layout(1)
		KEY_3: _switch_layout(2)
		KEY_R: _switch_layout(0)
		KEY_V:
			foliage_mode = (foliage_mode + 1) % 3
			_update_foliage_preview()
		KEY_C:
			join_overlay = not join_overlay
			get_tree().debug_collisions_hint = join_overlay
			_update_label()
			queue_redraw()
		_: return
	get_viewport().set_input_as_handled()


func _switch_layout(index: int) -> void:
	active_layout = index
	player.position = REVIEW_SPAWNS[index]
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	_update_label()


func _draw() -> void:
	if not join_overlay:
		return
	for surface in surfaces:
		draw_line(Vector2(surface.left, surface.y), Vector2(surface.right, surface.y), Color(0.1, 1, 0.7, 0.95), 3)


func _surface_named(piece_name: String) -> Dictionary:
	for surface in surfaces:
		if surface.node.name == piece_name:
			return surface
	return {}


func _put_player_at(position: Vector2) -> void:
	player.position = position
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await _physics_frames(3)


func _capture_view(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	_check(image.save_png(CHUNK_DELIVERY + filename) == OK, "Captured " + filename)
	image = null


func _verify() -> void:
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1920, 1080)
	_check(find_children("*", "TileMapLayer", true, false).is_empty(), "Chunk level has no TileMap or repeated terrain fill.")
	_check(surfaces.size() == 9, "Three ground pieces and six platform placements are present.")
	var players_in_scene := 0
	for actor in get_tree().get_nodes_in_group("player"):
		if is_ancestor_of(actor):
			players_in_scene += 1
	_check(players_in_scene == 1, "The saved scene player is reused without a duplicate actor.")
	_check(find_children("*", "Camera2D", true, false).size() == 1, "The saved camera is reused without a duplicate camera.")
	var top_plane: Dictionary = refinement_records.platform_integrated_top
	_check(int(top_plane.anchor_y) - int(top_plane.standing_back_y) >= 8 and int(top_plane.standing_front_y) - int(top_plane.anchor_y) >= 8, "Standing datum has depth on both sides inside the integrated top plane.")
	for id in ["foliage_soft_base", "foliage_rim"]:
		var image := Image.load_from_file(ProjectSettings.globalize_path(REFINEMENT + id + ".png"))
		var ends: Array[int] = []
		for x in range(20, image.get_width() - 20, 16):
			for y in range(image.get_height() - 1, -1, -1):
				if image.get_pixel(x, y).a > 0.35:
					ends.append(y)
					break
		_check(not ends.is_empty() and ends.max() - ends.min() >= 20, "Foliage lower edge has staggered leaf tips: " + id)
		image = null
	if foliage_preview:
		for mode in 3:
			foliage_mode = mode
			_update_foliage_preview()
			_check(foliage_preview.texture != null, "Foliage comparison mode %d is available." % mode)
		foliage_mode = 2
		_update_foliage_preview()
	var platform_widths: Dictionary = {}
	for id in asset_records:
		var data: Dictionary = asset_records[id]
		var image := Image.load_from_file(ProjectSettings.globalize_path(CHUNKS + id + ".png"))
		_check(image.get_width() == int(data.width) and image.get_height() == int(data.height), "Whole stamp dimensions: " + id)
		_check(image.get_pixel(0, 0).a < 0.1, "Transparent stamp margin: " + id)
		_check(ResourceLoader.exists(CHUNKS + "placeables/" + id + ".tscn"), "Reusable native placeable: " + id)
		if data.kind == "ground":
			_check(int(data.depth_below_surface) >= 800, "Full-depth cliff body: " + id)
			_check(float(data.opaque_body_fraction) >= 0.95, "Continuous opaque cliff body: " + id)
		if data.kind == "platform":
			platform_widths[int(data.width)] = true
		if data.kind != "decoration":
			for fraction in [0.05, 0.25, 0.5, 0.75, 0.95]:
				var x := int(lerpf(float(data.surface_left), float(data.surface_right), fraction))
				_check(image.get_pixel(x, int(data.surface_y)).a > 0.85, "Collider cap is on visible opaque artwork: %s at %s" % [id, fraction])
		image = null
	_check(platform_widths.size() == 4, "Four independently drawn platform sizes are available.")
	_check(player.live_3d_visual.model_scene.resource_path.ends_with("threadborne_doll_modular.glb"), "Actual modular player is active.")
	# Every authored cap must support the unmodified player's capsule.
	for surface in surfaces:
		var start := Vector2((surface.left + surface.right) * 0.5, surface.y - 100)
		await _put_player_at(start)
		await _physics_frames(30)
		_check(player.is_on_floor(), "Supported floor contact: " + String(surface.node.name))
		_check(absf(player.position.y + 69.245 - float(surface.y)) < 1.5, "Physical cap matches authored surface: " + String(surface.node.name))
		_check(contact_shadow.main.visible and absf(contact_shadow.main.global_position.y - float(surface.y) - 2) < 0.5, "Shadow follows the receiving cap: " + String(surface.node.name))
		if surface.node.name == &"BridgeA" and DisplayServer.get_name() != "headless":
			var old_zoom := camera.zoom
			var old_y := camera.position.y
			camera.zoom = Vector2(2, 2)
			camera.position.y = 280
			await _physics_frames(3)
			await _capture_view("integrated_top_review.png")
			camera.zoom = old_zoom
			camera.position.y = old_y
			await _physics_frames(3)
	# Shadow remains on ground during flight and clips at unsupported edges.
	await _put_player_at(Vector2(720, 730))
	await _physics_frames(15)
	var grounded_opacity: float = contact_shadow.main.modulate.a
	_check(grounded_opacity > 0.4, "Grounded shadow has the stronger contact opacity.")
	_check(contact_shadow._foot_points().size() == 2, "Contact marks use both animated feet.")
	var foot_offsets: Array[float] = []
	var visible_contacts := 0
	var points: PackedVector2Array = contact_shadow._foot_points()
	for index in points.size():
		foot_offsets.append(points[index].y - 800)
		if contact_shadow.contacts[index].visible:
			visible_contacts += 1
			_check(absf(contact_shadow.contacts[index].global_position.y - points[index].y - 2) < 0.1, "Dense contact follows sole depth inside the top plane.")
	_check(visible_contacts >= 1 and contact_shadow.spread.visible, "Dense sole contact and soft spread both render.")
	print("GROUNDING_FOOT_OFFSETS ", JSON.stringify(foot_offsets))
	await _put_player_at(Vector2(720, 550))
	await _physics_frames(3)
	_check(contact_shadow.main.visible and contact_shadow.main.modulate.a < grounded_opacity, "Airborne shadow fades while remaining on the ground.")
	_check(absf(contact_shadow.main.global_position.y - 802) < 0.5, "Airborne shadow does not rise with the character.")
	await _capture_view("contact_shadow_airborne.png")
	await _put_player_at(Vector2(1516, 730))
	await _physics_frames(15)
	_check(contact_shadow.receiver.node.name == &"GroundA", "Shadow ignores a platform above the character.")
	var ground_a := _surface_named("GroundA")
	await _put_player_at(Vector2(ground_a.right - 4, ground_a.y - 70))
	await _physics_frames(5)
	_check(contact_shadow.main.visible and contact_shadow.clipped_right <= float(ground_a.right), "Shadow clips to the cliff edge.")
	await _put_player_at(Vector2(1800, 930))
	await _physics_frames(3)
	_check(not contact_shadow.main.visible, "No ground shadow is drawn over the empty gap.")
	# Traverse each actual ground gap with ordinary movement and a held jump.
	for pair in [["GroundA", "GroundB"], ["GroundB", "GroundC"]]:
		var from := _surface_named(pair[0])
		var to := _surface_named(pair[1])
		await _put_player_at(Vector2(from.right - 30, from.y - 70))
		await _physics_frames(10)
		var reset_before := fall_resets
		Input.action_press("move_right")
		Input.action_press("Jump")
		await _physics_frames(46)
		Input.action_release("Jump")
		Input.action_release("move_right")
		await _physics_frames(35)
		_check(fall_resets == reset_before and player.is_on_floor() and player.position.x > float(to.left), "Playable ground gap: %s to %s" % [pair[0], pair[1]])
	# Enter the optional upper path using the existing ground and air jump.
	var first_step := _surface_named("StepA")
	await _put_player_at(Vector2((first_step.left + first_step.right) * 0.5, 730))
	await _physics_frames(10)
	Input.action_press("Jump")
	await _physics_frames(23)
	Input.action_release("Jump")
	await _physics_frames(1)
	Input.action_press("Jump")
	await _physics_frames(30)
	Input.action_release("Jump")
	await _physics_frames(30)
	_check(player.is_on_floor() and absf(player.position.y + 69.245 - float(first_step.y)) < 1.5, "Existing double jump reaches the optional upper route.")
	for pair in [["StepA", "BridgeA"], ["BridgeA", "ShelfB"], ["ShelfB", "StepB"], ["StepB", "BridgeB"], ["BridgeB", "ShelfC"]]:
		var from := _surface_named(pair[0])
		var to := _surface_named(pair[1])
		await _put_player_at(Vector2(from.right - 35, from.y - 70))
		await _physics_frames(10)
		Input.action_press("move_right")
		Input.action_press("Jump")
		var landed := false
		for frame in 85:
			await get_tree().physics_frame
			if player.is_on_floor() and player.position.x > float(to.left) and absf(player.position.y + 69.245 - float(to.y)) < 1.5:
				landed = true
				break
			if player.position.x > float(to.right) - 35:
				Input.action_release("move_right")
		Input.action_release("Jump")
		Input.action_release("move_right")
		_check(landed, "Playable upper link: %s to %s" % [pair[0], pair[1]])
	# A missed jump returns control without damage, death or save changes.
	await _put_player_at(Vector2(1800, 1150))
	var reset_before := fall_resets
	await _physics_frames(45)
	_check(fall_resets > reset_before and not player.is_dead, "Gap fall safely returns the real player.")
	for zone in 3:
		_switch_layout(zone)
		await _physics_frames(45)
		_check(player.is_on_floor(), "Review position %d is grounded." % (zone + 1))
		await _capture_view("route_%d.png" % (zone + 1))
	if DisplayServer.get_name() != "headless":
		await _put_player_at(Vector2(2270, 634))
		await _physics_frames(30)
		var old_zoom := camera.zoom
		var old_y := camera.position.y
		camera.zoom = Vector2(2, 2)
		camera.position.y = 700
		await _physics_frames(3)
		await _capture_view("foliage_edge_review.png")
		camera.zoom = old_zoom
		camera.position.y = old_y
		await _physics_frames(3)
	join_overlay = true
	queue_redraw()
	await get_tree().process_frame
	await _capture_view("grounding_collision_review.png")
	var result := {"checks": check_count, "failures": failures, "renderer": RenderingServer.get_current_rendering_method(), "surface_count": surfaces.size(), "platform_sizes": platform_widths.keys(), "player_model": player.live_3d_visual.model_scene.resource_path}
	var file := FileAccess.open(CHUNK_DELIVERY + "godot_checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ") + "\n")
	file.close()
	print("WOVEN_CHUNK_CHECKS ", JSON.stringify(result))
	player.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
