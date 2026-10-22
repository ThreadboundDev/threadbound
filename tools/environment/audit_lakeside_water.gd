extends SceneTree
## Read-only source review. Preview variations change disposable instances only.
## Run on the real project with --headless for data, or -- --capture for GPU views.
const OUT := "res://work/water-review-2026-10-22"
var room: Node2D
var lake
var player
var camera: Camera2D
var report := {}

func _initialize() -> void:
	call_deferred("audit")

func frames(count: int) -> void:
	for index in count:
		await physics_frame

func depth(item: CanvasItem) -> int:
	var value := item.z_index
	while item.z_as_relative and item.get_parent() is CanvasItem:
		item = item.get_parent()
		value += item.z_index
	return value

func upper_edge(x: float) -> float:
	var result := INF
	for index in lake.points.size():
		var a: Vector2 = lake.to_global(lake.points[index])
		var b: Vector2 = lake.to_global(lake.points[(index + 1) % lake.points.size()])
		if absf(a.x - b.x) < 0.001 or x < minf(a.x, b.x) or x > maxf(a.x, b.x):
			continue
		result = minf(result, lerpf(a.y, b.y, (x-a.x)/(b.x-a.x)))
	return result

func layer(path: String) -> Dictionary:
	var item := room.get_node(path) as CanvasItem
	return {"path": path, "effective_z": depth(item), "children": item.get_child_count()}

func wet_state(point: Vector2) -> Dictionary:
	var pockets: Array[String] = []
	for pocket in get_nodes_in_group("lake_air_pockets"):
		if pocket.contains_global_point(point):
			pockets.append(str(room.get_path_to(pocket)))
	return {"point": str(point), "in_lake_polygon": lake.contains_global_point(point), "dry_pockets": pockets, "wet": lake.contains_global_point(point) and pockets.is_empty()}

func capture(label: String, center: Vector2, zoom: float) -> void:
	camera.global_position = center
	camera.zoom = Vector2.ONE * zoom
	camera.reset_smoothing()
	camera.force_update_scroll()
	# Physics catch-up frames can all precede one GPU frame. Let both shared 3D
	# building passes render at the new camera before comparing shoreline images.
	for frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var output := OUT.path_join(label + ".png")
	var code := root.get_texture().get_image().save_png(output)
	if code != OK:
		push_error("WATER_REVIEW_CAPTURE_FAILED " + output)
	print("WATER_REVIEW_CAPTURE ", label)

func audit() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.content_scale_size = Vector2i(1280, 720)
	room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(8)
	lake = room.get_node("Volumes/Lake")
	player = room.get_node("Player")
	var plane: float = lake.get_surface_global_y()
	var samples: Array[Dictionary] = []
	for x: float in [-1000, 0, 128, 1472, 2816, 4096, 5400]:
		var upper := upper_edge(x)
		samples.append({"x": x, "polygon_top_y": upper, "mirror_backdrop_plane_y": plane, "uncovered_band_world_pixels": upper-plane})
	var layers: Array[Dictionary] = []
	for path: String in ["LakePresentation/UnderwaterDepth", "LakesideArtStage/LitBackgroundArt", "Geometry/TerrainArtwork/rear_supports", "Geometry/BridgeLandings/Deck08", "Geometry/TerrainArtwork/rear_cave", "Volumes/AirPocket/WaterPreviewFill", "Volumes/Lake/WaterMovementRipples", "Player", "Geometry/TerrainArtwork/terrain", "FrontFoliage", "LakesideArtStage/RemovableForegroundArt", "Volumes/Lake/WaterPreviewFill"]:
		layers.append(layer(path))
	var pocket_rows: Array[Dictionary] = []
	for pocket in get_nodes_in_group("lake_air_pockets"):
		pocket_rows.append({"path": str(room.get_path_to(pocket)), "lake_presentation": pocket.lake_presentation, "points": pocket.points.size(), "fill_visible": pocket._fill.visible, "fill_shader": pocket._fill.material.shader.resource_path, "fill_z": depth(pocket._fill)})
	report = {"revision": "14710d84", "engine": Engine.get_version_info().string, "display": DisplayServer.get_name(), "scope": "Source review and disposable runtime previews; no saved gameplay/asset edits.", "water_shader": lake._fill.material.shader.resource_path, "surface_y": plane, "shoreline_samples": samples, "draw_order": layers, "air_pockets": pocket_rows, "representative_points": [wet_state(Vector2(2200,1200)), wet_state(Vector2(1472,1200)), wet_state(Vector2(2816,430)), wet_state(Vector2(128,400))], "normal_alpha": 0.58, "submerged_alpha": 0.23}
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		for enemy in get_nodes_in_group("enemies"):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
		for ui in root.find_children("*", "CanvasLayer", true, false):
			ui.visible = false
		room.get_node("Player/Camera2D").enabled = false
		room.get_node("OverviewCamera").enabled = false
		camera = Camera2D.new()
		camera.position_smoothing_enabled = false
		room.add_child(camera)
		camera.make_current()
		player.set_physics_process(false)
		player.visible = false
		await capture("shore_current", Vector2(2816,420), 1.0)
		var original: PackedVector2Array = lake.points.duplicate()
		var flat := original.duplicate()
		for index in flat.size():
			if lake.to_global(flat[index]).y < 500:
				flat[index].y = lake.to_local(Vector2(0,411)).y
		lake.points = flat
		room.get_node("LakePresentation")._update_waterline()
		await capture("shore_flat_plane_preview", Vector2(2816,420), 1.0)
		report["flat_plane_preview_y"] = 411
		lake.points = original
		room.get_node("LakePresentation")._update_waterline()
		player.global_position = Vector2(2200,1200)
		player.reset_physics_interpolation()
		await capture("tower_outside_submerged", Vector2(1472,1150), 0.48)
		player.global_position = Vector2(1472,1037.955)
		player.reset_physics_interpolation()
		await capture("tower_inside_dry", Vector2(1472,1150), 0.48)
		room.focus_landmark("Cave")
		room.get_node("Player/Camera2D").enabled = false
		camera.make_current()
		player.visible = true
		player.set_physics_process(true)
		await frames(45)
		player.set_physics_process(false)
		await capture("cave_contact_current", player.global_position + Vector2(35,-15), 2.0)
		var rear := room.get_node("Geometry/TerrainArtwork/rear_cave") as Node2D
		var old_z := rear.z_index
		rear.z_index = 3
		await capture("cave_all_rock_front_preview", player.global_position + Vector2(35,-15), 2.0)
		rear.z_index = old_z
		report["preview_variations_installed"] = false
	FileAccess.open(OUT.path_join("audit.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	print("WATER_REVIEW_AUDIT ", JSON.stringify(report))
	room.queue_free()
	await frames(3)
	call_deferred("quit", 0)
