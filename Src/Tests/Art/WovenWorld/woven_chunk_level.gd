extends "res://Src/Tests/Art/WovenWorld/woven_world_review.gd"
## Reuses the previous audition's player, backdrop, lighting and review helpers.
## Geometry and decorations are native authored placeables in the companion scene.

const CHUNKS := "res://Assets/BlueBiome/Art/WovenWorldChunks/"
const CHUNK_DELIVERY := "res://ArtSource/Deliveries/WovenWorldChunks/shore_finish/"
const REVIEW_SPAWNS := [Vector2(720, 720), Vector2(2450, 624), Vector2(4540, 688)]
const REVIEW_NAMES := ["LAKESIDE APPROACH", "GREEN CANOPY", "UPPER SHELF"]
const CONTACT_SHADOW := preload("res://Src/Tests/Art/WovenWorld/woven_contact_shadow.gd")
const REFINEMENT := "res://Assets/BlueBiome/Art/WovenWorldChunks/GroundingRefinement/"
const OUTLINE_COMPARISON := preload("res://Src/Tests/Art/WovenWorld/woven_outline_comparison.gd")

@export var preview_swimming := true
@export var recovery_y := 1600.0

var asset_records: Dictionary
var surfaces: Array[Dictionary] = []
var fall_resets := 0
var contact_shadow: Node2D
var refinement_records: Dictionary
var foliage_preview: Sprite2D
var foliage_original_texture: Texture2D
var foliage_original_offset := Vector2.ZERO
var foliage_mode := 2
var outline_comparison: RefCounted
var camera_manual := false


func _ready() -> void:
	asset_records = JSON.parse_string(FileAccess.get_file_as_string(CHUNKS + "asset_metadata.json"))["assets"]
	super._ready()
	_apply_grounding_refinement()
	player.debug_blue_water_power_unlocked = preview_swimming
	outline_comparison = OUTLINE_COMPARISON.new()
	outline_comparison.initialize(player.live_3d_visual)
	contact_shadow = CONTACT_SHADOW.new()
	contact_shadow.name = "PlayerContactShadow"
	contact_shadow.target = player
	contact_shadow.receivers = surfaces
	add_child(contact_shadow)
	get_window().title = "Threadbound — Woven Shore"
	var help := status_label.get_parent().get_child(1) as Label
	help.text = "1 / 2 / 3: islands    C: collision    R: chamber entry\nO: outlines    V: foliage    Normal movement / swimming controls."
	_go_chamber_entry()
	_resume_shore_route()
	if OS.get_cmdline_user_args().has("--verify-woven-chunks"):
		# Traversal checks and matched art captures need repeatable poses.
		$ShoreFinish/Encounters.queue_free()
		_verify.call_deferred()


func _apply_grounding_refinement() -> void:
	refinement_records = JSON.parse_string(FileAccess.get_file_as_string(REFINEMENT + "asset_metadata.json"))
	# Default art and registration are saved in the scene for editor parity.
	foliage_preview = get_node_or_null("Planting/LeafClusterMiddle") as Sprite2D
	if foliage_preview:
		foliage_original_texture = load(KIT + "foliage_green.png")
		foliage_original_offset = Vector2(0, -140)
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
	pass # Native saved Backdrop is visible and editable before running.


func _build_terrain() -> void:
	for piece in $Geometry.get_children():
		var id: String = piece.get_meta("asset_id")
		var data: Dictionary = asset_records[id]
		var shape := piece.get_node("Body/Shape") as CollisionShape2D
		var cap := shape.shape.get_rect()
		var left := to_local(shape.to_global(cap.position))
		var right := to_local(shape.to_global(Vector2(cap.end.x, cap.position.y)))
		surfaces.append({"id": id, "node": piece, "kind": data.kind,
			"left": left.x, "right": right.x, "y": left.y})
	var entry_shape := $ChamberMouth/Floor/Shape as CollisionShape2D
	var entry_cap := entry_shape.shape.get_rect()
	var entry_left := entry_shape.global_position + entry_cap.position
	surfaces.append({"id": "chamber_landing", "node": $ChamberMouth, "kind": "entry",
		"left": entry_left.x, "right": entry_left.x + entry_cap.size.x, "y": entry_left.y})


func _build_layouts() -> void:
	pass # Artwork is authored in the scene; no repeated tiles or procedural fill.


func _update_label() -> void:
	status_label.text = "WOVEN SHORE  /  " + REVIEW_NAMES[active_layout]
	if outline_comparison:
		status_label.text += "  /  " + OUTLINE_COMPARISON.LABELS[outline_comparison.mode]
	if join_overlay:
		status_label.text += "  /  COLLISION"


func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return
	if camera.get_script() == null and not camera_manual:
		camera.position = Vector2(player.position.x, clampf(player.position.y - 190, 500, 950))
	var zone := 0 if player.position.x < 1800 else (1 if player.position.x < 3500 else 2)
	if active_layout != zone:
		active_layout = zone
		_update_label()
	if player.position.y > recovery_y:
		fall_resets += 1
		_switch_layout(active_layout)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: _switch_layout(0)
		KEY_2: _switch_layout(1)
		KEY_3: _switch_layout(2)
		KEY_R: _go_chamber_entry()
		KEY_O:
			outline_comparison.set_mode(outline_comparison.mode + 1)
			_update_label()
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


func _go_chamber_entry() -> void:
	_switch_layout(0)
	player.global_position = $ChamberMouth/ChamberEntrySpawn.global_position
	player.reset_physics_interpolation()


func _resume_shore_route() -> void:
	if not get_tree().has_meta(&"woven_shore_return"):
		return
	var saved: Dictionary = get_tree().get_meta(&"woven_shore_return")
	get_tree().remove_meta(&"woven_shore_return")
	var route: StringName = saved.anchor
	var portal := $ShoreFinish.get_node_or_null(NodePath(String(route))) as Area2D
	if not portal:
		return
	player.global_position = portal.global_position + Vector2(-90 if route != &"FloodedCulvert" else 0, 0)
	player.reset_physics_interpolation()
	if saved.sluices[0]:
		$ShoreFinish/WestSluice.open_sluice()
	if saved.sluices[1]:
		$ShoreFinish/EastSluice.open_sluice()


func get_sluice_state() -> Array[bool]:
	return [$ShoreFinish/WestSluice.opened, $ShoreFinish/EastSluice.opened]


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
	_check(surfaces.size() == 12, "Three islands, six platforms, two water recovery shelves and the chamber landing are present.")
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
			camera_manual = true
			var old_zoom := camera.zoom
			var old_y := camera.position.y
			camera.zoom = Vector2(2, 2)
			camera.position.y = 280
			await _physics_frames(3)
			await _capture_view("integrated_top_review.png")
			camera.zoom = old_zoom
			camera.position.y = old_y
			await _physics_frames(3)
			camera_manual = false
	# Shadow remains on ground during flight and clips at unsupported edges.
	await _put_player_at(Vector2(720, 730))
	# Allow the landing pose to finish before judging planted sole contact.
	await _physics_frames(45)
	var grounded_opacity: float = contact_shadow.main.modulate.a
	_check(grounded_opacity > 0.4, "Grounded shadow has the stronger contact opacity.")
	_check(contact_shadow._foot_points().size() == 2, "Contact marks use both animated feet.")
	var foot_offsets: Array[float] = []
	var ground_a := _surface_named("GroundA")
	var visible_contacts := 0
	var points: PackedVector2Array = contact_shadow._foot_points()
	for index in points.size():
		foot_offsets.append(points[index].y - float(ground_a.y))
		if contact_shadow.contacts[index].visible:
			visible_contacts += 1
			_check(absf(contact_shadow.contacts[index].global_position.y - points[index].y - 2) < 0.1, "Dense contact follows sole depth inside the top plane.")
	_check(visible_contacts >= 1 and contact_shadow.spread.visible, "Dense sole contact and soft spread both render.")
	print("GROUNDING_FOOT_OFFSETS ", JSON.stringify(foot_offsets))
	await _put_player_at(Vector2(720, 550))
	await _physics_frames(3)
	_check(contact_shadow.main.visible and contact_shadow.main.modulate.a < grounded_opacity, "Airborne shadow fades while remaining on the ground.")
	_check(absf(contact_shadow.main.global_position.y - float(ground_a.y) - 2) < 0.5, "Airborne shadow does not rise with the character.")
	await _capture_view("contact_shadow_airborne.png")
	await _put_player_at(Vector2(1516, 730))
	await _physics_frames(15)
	_check(contact_shadow.receiver.node.name == &"GroundA", "Shadow ignores a platform above the character.")
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
	var reset_before := fall_resets
	await _put_player_at(Vector2(1800, recovery_y + 100))
	await _physics_frames(45)
	_check(fall_resets > reset_before and not player.is_dead, "Gap fall safely returns the real player.")
	await _verify_shore_transition()
	await _verify_outline_comparison()
	for zone in 3:
		_switch_layout(zone)
		await _physics_frames(45)
		_check(player.is_on_floor(), "Review position %d is grounded." % (zone + 1))
		await _capture_view("route_%d.png" % (zone + 1))
	if DisplayServer.get_name() != "headless":
		camera_manual = true
		await _put_player_at(Vector2(2270, 634))
		await _physics_frames(30)
		var old_zoom := camera.zoom
		var old_position := camera.position
		camera.zoom = Vector2(2, 2)
		camera.position = Vector2(player.position.x, 700)
		await _physics_frames(3)
		await _capture_view("foliage_edge_review.png")
		camera.zoom = old_zoom
		camera.position = old_position
		await _physics_frames(3)
		camera_manual = false
	join_overlay = true
	queue_redraw()
	await get_tree().process_frame
	await _capture_view("grounding_collision_review.png")
	outline_comparison.release()
	_check(outline_comparison.originals.is_empty(), "Verification releases temporary outline materials after restoring originals.")
	var result := {"checks": check_count, "failures": failures, "renderer": RenderingServer.get_current_rendering_method(), "surface_count": surfaces.size(), "platform_sizes": platform_widths.keys(), "player_model": player.live_3d_visual.model_scene.resource_path}
	var file := FileAccess.open(CHUNK_DELIVERY + "godot_checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ") + "\n")
	file.close()
	print("WOVEN_CHUNK_CHECKS ", JSON.stringify(result))
	player.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)


func _verify_shore_transition() -> void:
	var lake := $ShoreWater/Lake
	_check($Backdrop.get_child_count() == 2, "Backdrop parallax layers are authored in the saved scene.")
	_check(find_children("ReviewDaylight", "PointLight2D", true, false).size() == 1, "Authored daylight is reused without a duplicate.")
	_check(lake.lake_presentation and not lake.air_pocket, "Existing polygon lake supplies the shoreline water.")
	_check(lake.contains_global_point(Vector2(camera.limit_left, lake.get_surface_global_y() + 64)), "Lake extends past the left camera edge without an exposed rectangular cut.")
	var entry := _surface_named("ChamberMouth")
	var boundary_shape := $LeftBoundary/Shape as CollisionShape2D
	_check(float(entry.left) <= boundary_shape.global_position.x + boundary_shape.shape.get_rect().end.x, "Chamber floor meets the left boundary without a hidden drop.")
	_check(player.debug_blue_water_power_unlocked == preview_swimming, "Swimming preview is local to this level's player instance.")
	_check($Geometry/BridgeA/Art.texture.resource_path.ends_with("platform_integrated_top.png"), "Integrated platform is saved and visible in the editor.")
	var original_scene := load("res://Src/Tests/Art/WovenWorld/woven_chunk_level.tscn") as PackedScene
	var scene_state := original_scene.get_state()
	var saved_player := false
	for index in scene_state.get_node_count():
		saved_player = saved_player or scene_state.get_node_name(index) == &"Player"
	_check(saved_player, "The actual player is authored once in the saved scene.")
	_go_chamber_entry()
	await _physics_frames(45)
	_check(player.is_on_floor() and not player.is_in_prototype_water(), "Chamber entry is supported and dry.")
	await _capture_view("chamber_entry.png")
	Input.action_press("move_right")
	await _physics_frames(105)
	Input.action_release("move_right")
	await _physics_frames(15)
	_check(player.position.x > 50 and player.is_on_floor(), "Player walks from the chamber mouth onto Ground A.")
	for pair in [["GroundA", "GroundB"], ["GroundB", "GroundC"]]:
		var left := _surface_named(pair[0])
		var right := _surface_named(pair[1])
		var gap_center := (float(left.right) + float(right.left)) * 0.5
		var resets := fall_resets
		await _put_player_at(Vector2(gap_center, lake.get_surface_global_y() + 100))
		await _physics_frames(12)
		_check(player.is_in_prototype_water(), "Swimmable water in gap after " + pair[0])
		var start_y := player.position.y
		Input.action_press("move_up")
		await _physics_frames(7)
		Input.action_release("move_up")
		_check(player.position.y < start_y, "Existing swimming moves upward in gap after " + pair[0])
		_check(fall_resets == resets, "Valid swimming does not trigger gap recovery after " + pair[0])
		await _capture_view("water_after_%s.png" % pair[0])
		Input.action_press("move_up")
		for frame in 120:
			await get_tree().physics_frame
			if not player.is_in_prototype_water() and player.is_on_floor():
				break
		Input.action_release("move_up")
		_check(not player.is_in_prototype_water() and player.is_on_floor(), "Swimming upward reaches dry footing on the recovery shelf after " + pair[0])
		if player.is_on_floor() and player.position.y + 69.245 > float(left.y) + 5:
			Input.action_press("Jump")
			Input.action_press("move_left")
			await _physics_frames(30)
			Input.action_release("Jump")
			Input.action_release("move_left")
			for frame in 150:
				await get_tree().physics_frame
				if player.is_on_floor() and not player.is_in_prototype_water():
					break
		print("SHORE_RECOVERY ", pair[0], " ", player.position, " velocity=", player.velocity)
		_check(not player.is_in_prototype_water() and player.is_on_floor() and player.position.x < float(left.right), "Swimmer can breach and return to the left island after " + pair[0])
	for name in ["GroundA", "GroundB", "GroundC"]:
		var island := _surface_named(name)
		_check(float(island.y) < lake.get_surface_global_y(), "Dry island cap above the adjustable waterline: " + name)
	await _put_player_at(Vector2(1810, 1170))
	await _physics_frames(45)
	_check(player.is_in_prototype_water() and lake.underwater_view > 0.9, "Diving opens the existing underwater presentation.")
	await _capture_view("submerged.png")
	_switch_layout(2)
	await _physics_frames(45)
	await _capture_view("rooftop_approach.png")


func _verify_outline_comparison() -> void:
	var visual: Node = player.live_3d_visual
	var original_width: float = visual.object_outline_width
	outline_comparison.set_mode(0)
	_check(not outline_comparison.originals.is_empty(), "Comparison found the actual character's outline shells.")
	var source_widths: Dictionary = {}
	for id in outline_comparison.originals:
		var record: Dictionary = outline_comparison.originals[id]
		source_widths[id] = record.material.get_shader_parameter("outline_source_pixels")
	for mode in [1, 2, 0]:
		outline_comparison.set_mode(mode)
		var widths_ok := true
		var colors_ok := true
		var sources_ok := true
		for id in source_widths:
			var record: Dictionary = outline_comparison.originals[id]
			var shell: MeshInstance3D = record.shell.get_ref()
			var material := shell.material_override as ShaderMaterial
			var width: float = material.get_shader_parameter("outline_source_pixels")
			widths_ok = widths_ok and is_equal_approx(width, float(source_widths[id]) * (1.0 if mode == 0 else OUTLINE_COMPARISON.WIDTH_SCALE))
			sources_ok = sources_ok and is_equal_approx(float(record.material.get_shader_parameter("outline_source_pixels")), float(source_widths[id]))
			if mode == 0:
				sources_ok = sources_ok and material == record.material
			elif mode == 2:
				colors_ok = colors_ok and material.get_shader_parameter("outline_color") == record.color
		_check(widths_ok, "Outline mode %d preserves relative detail widths." % mode)
		_check(sources_ok, "Outline mode %d leaves originals intact and restores them exactly." % mode)
		_check(colors_ok, "Outline mode %d uses its selected ink treatment." % mode)
	_check(is_equal_approx(visual.object_outline_width, original_width), "Comparison keeps the production renderer's width setting unchanged.")
	outline_comparison.set_mode(2)
	_switch_layout(0)
	await _physics_frames(45)
	_check(player.is_on_floor(), "Outline comparison retains Ground A floor contact.")
	_check(absf(contact_shadow.main.global_position.y - float(_surface_named("GroundA").y) - 2) < 0.5, "Contact shadow follows the edited collider cap.")
	if DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHUNK_DELIVERY + "outline_review"))
	# Freeze the entire live pose for matched comparisons; only shell materials
	# and the explanatory label change between images.
	var old_camera_mode := camera.process_mode
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var old_zoom := camera.zoom
	var old_position := camera.position
	var ink_metrics: Array[Dictionary] = []
	for zoom in [1.0, 2.0]:
		camera.zoom = Vector2.ONE * zoom
		camera.position.y = 540 if zoom == 1 else 760
		if zoom == 2:
			camera.position.x = player.position.x
		camera.reset_physics_interpolation()
		await _physics_frames(3)
		camera.force_update_scroll()
		_check(is_equal_approx(get_viewport().canvas_transform.get_scale().x, zoom), "Comparison capture uses the requested %.1fx camera zoom." % zoom)
		for mode in 3:
			outline_comparison.set_mode(mode)
			_update_label()
			await get_tree().process_frame
			await _capture_view("outline_review/%s_%d.png" % ["gameplay" if zoom == 1 else "close", mode])
			if zoom == 1:
				ink_metrics.append(_outline_ink_metrics())
	_check(int(ink_metrics[0].opaque_pixels) > int(ink_metrics[1].opaque_pixels), "Rendered thin outline reduces the expanded silhouette area.")
	_check(int(ink_metrics[2].near_black_pixels) < int(ink_metrics[1].near_black_pixels), "Rendered material ink reduces near-black pixels at the same thin width.")
	var metrics_file := FileAccess.open(CHUNK_DELIVERY + "outline_review/metrics.json", FileAccess.WRITE)
	metrics_file.store_string(JSON.stringify(ink_metrics, "  ") + "\n")
	metrics_file.close()
	camera.zoom = old_zoom
	camera.position = old_position
	camera.force_update_scroll()
	get_tree().paused = false
	camera.process_mode = old_camera_mode
	outline_comparison.set_mode(2)
	_update_label()


func _outline_ink_metrics() -> Dictionary:
	var viewport: SubViewport = player.live_3d_visual.get("_viewport")
	var image := viewport.get_texture().get_image()
	image.resize(400, 300, Image.INTERPOLATE_NEAREST)
	var opaque := 0
	var near_black := 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.8:
				opaque += 1
				if maxf(pixel.r, maxf(pixel.g, pixel.b)) < 0.1:
					near_black += 1
	return {"mode": OUTLINE_COMPARISON.LABELS[outline_comparison.mode], "sample_size": [400, 300], "opaque_pixels": opaque, "near_black_pixels": near_black}
