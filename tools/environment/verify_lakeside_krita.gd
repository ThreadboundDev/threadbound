extends SceneTree
## Integration check of the authored map, physics, water, shared 3D art and cutaway.
const ROOM := "res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn"
var failures: Array[String] = []
var room: Node2D
var captured: Array[String] = []

func _initialize() -> void:
	for folder: String in ["res://Assets/BlueBiome/Art/LakesideMap", "res://Assets/BlueBiome/Art/Lakeside3D/Models", "res://Assets/BlueBiome/Art/Lakeside3D/Textures", "res://Assets/BlueBiome/Villagers/Models", "res://Assets/BlueBiome/Villagers/Textures"]:
		for filename in DirAccess.get_files_at(folder):
			if not filename.ends_with(".import"):
				continue
			var config := ConfigFile.new()
			if config.load(folder.path_join(filename)) == OK:
				var uid := ResourceUID.text_to_id(config.get_value("remap", "uid", ""))
				if uid != -1 and not ResourceUID.has_id(uid):
					ResourceUID.add_id(uid, folder.path_join(filename.trim_suffix(".import")))
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func effective_z(item: CanvasItem) -> int:
	var value := item.z_index
	if item.z_as_relative and item.get_parent() is CanvasItem:
		value += effective_z(item.get_parent())
	return value

func solid_at(at: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = at
	query.collision_mask = 1
	query.collide_with_areas = false
	return not room.get_world_2d().direct_space_state.intersect_point(query).is_empty()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await frames(18)
	await RenderingServer.frame_post_draw
	var file := "res://work/krita-map-import/" + label + ".png"
	check(root.get_texture().get_image().save_png(file) == OK, "Rendered image must save")
	captured.append(file)

func verify() -> void:
	room = load(ROOM).instantiate() as Node2D
	check(room != null, "Playtest scene must load")
	if room == null:
		quit(1)
		return
	root.add_child(room)
	current_scene = room
	await frames(30)
	var player: CharacterBody2D = room.get_node("Player")
	# Existing enemies are retained in the room; freeze only this automated fixture.
	for enemy in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	check(player.is_on_floor(), "Original shore spawn must stand on the painted route")
	check(room.get_node("Geometry/GreyboxTerrain").self_modulate.a == 0.0, "Greybox guides must stay hidden while physics remains")
	check(not room.get_node("Geometry/GreyboxTerrain").collision_enabled, "Old tile collision must be completely disabled")
	check(not room.has_node("Geometry/Water"), "Obsolete floating test-water rectangle must be excluded")
	var rocks: StaticBody2D = room.get_node("Geometry/RockCollision")
	check(rocks.get_child_count() > 0, "Painted terrain must have editable collision polygons")
	var mask := Image.load_from_file("res://work/krita-map-import/rock_mask.png")
	var physics_mismatch := 0
	var physics_samples := 0
	for y in range(32,mask.get_height(),64):
		for x in range(32,mask.get_width(),64):
			var expected := mask.get_pixel(x,y).a > 0.5
			var near_edge := false
			for offset: Vector2i in [Vector2i(4,0),Vector2i(-4,0),Vector2i(0,4),Vector2i(0,-4)]:
				near_edge = near_edge or (mask.get_pixel(x+offset.x,y+offset.y).a > 0.5) != expected
			if near_edge:
				continue
			var query := PhysicsPointQueryParameters2D.new()
			query.position = Vector2(x-1408,y-2560)
			query.collision_mask = 1
			query.collide_with_areas = false
			var actual := false
			for hit: Dictionary in room.get_world_2d().direct_space_state.intersect_point(query):
				actual = actual or hit.collider == rocks
			if actual != expected:
				physics_mismatch += 1
			physics_samples += 1
	check(physics_mismatch <= 12, "Physics must follow the inset, smoothed rock mask across the map")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Assets/BlueBiome/Art/LakesideMap/map_manifest.json"))
	var artwork: Node2D = room.get_node("Geometry/TerrainArtwork")
	var rear_wood := artwork.get_node("rear_supports") as Node2D
	var rear_rocks := artwork.get_node("rear_cave") as Node2D
	var bulb_count := 0
	for item in room.find_children("*", "Node2D", true, false):
		if item is not GreyboxBumper2D:
			continue
		bulb_count += 1
		var art := item.get_node("BulbArt") as AnimatedSprite2D
		check(not item.z_as_relative and effective_z(item) > effective_z(rear_wood) and effective_z(item) < effective_z(rear_rocks), "Placed bulb stays between rear supports and rocks, including nested bulbs")
		check(effective_z(art) == effective_z(item) and effective_z(art) > effective_z(room.get_node("Backdrop")), "Runtime bulb follows its editor depth above the backdrop")
	check(bulb_count == 4, "All four authored bulbs retain runtime artwork")
	check(rear_wood.z_index < rear_rocks.z_index and rear_rocks.z_index < player.z_index, "Non-solid wood must sit behind the combined cave rocks and player")
	check(rear_wood.get_child_count() == 15 and rear_rocks.get_child_count() == 32, "Original support layer and combined rock layer must remain independent")
	check(rear_wood.material is ShaderMaterial and rear_rocks.material == null and artwork.material == null, "Depth material belongs only to background timber")
	check(rear_wood.find_children("*", "CollisionObject2D", true, false).is_empty(), "Rear wood artwork must never add collision")
	if rear_wood.material is ShaderMaterial:
		var depth_material := rear_wood.material as ShaderMaterial
		check(depth_material.shader.resource_path.ends_with("rear_support_depth.gdshader"), "Rear timber uses the shared tunable depth filter")
		check(depth_material.get_shader_parameter("saturation") < 1.0 and depth_material.get_shader_parameter("contrast") < 1.0 and depth_material.get_shader_parameter("haze_amount") > 0.0, "Rear timber must have a visible depth treatment")
	check(manifest.rear_layer_sources.rear_supports == ["STAMP REAR SUPPORTS"] and manifest.rear_layer_sources.rear_cave == ["Under Cave Mouth", "Cave Walls"], "Restore original wood layer while keeping both rock layers together")
	check(manifest.rear_layer_split_check.pixels_over_two == 0, "Unfiltered separated art must reconstruct the source projection")
	check(artwork.find_children("*", "Sprite2D", true, false).size() == manifest.chunks.size(), "All saved painted chunks must be present")
	for chunk: Dictionary in manifest.chunks:
		var found := false
		for sprite: Sprite2D in artwork.get_node(chunk.group).get_children():
			if sprite.texture.resource_path.ends_with(chunk.path):
				found = true
				check(sprite.global_position.is_equal_approx(Vector2(chunk.position[0], chunk.position[1])) and sprite.scale == Vector2.ONE and not sprite.centered, "Krita pixel coordinates must remain exact")
				check(sprite.use_parent_material == (chunk.group == "rear_supports") and sprite.material == null, "Only rear timber chunks inherit the depth filter: " + str(chunk.path))
		check(found, "Missing art chunk: " + str(chunk.path))
	var stage: Node2D = room.get_node("LakesideArtStage")
	check(stage.placements.size() == 10, "Four buildings, four lanterns and two villagers must register")
	check(stage.far_view.world_3d == stage.near_view.world_3d, "Both building passes must share one 3D world")
	check(stage.far_view.size.x > root.get_visible_rect().size.x, "3D houses must render above display resolution")
	check(stage.far_view.msaa_3d == Viewport.MSAA_4X, "House edges must use 4x MSAA")
	check(stage.far_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "Supersampled house output must use linear filtering")
	var pbr_maps := {}
	for marker: Node2D in room.get_node("Buildings").get_children():
		for mesh: MeshInstance3D in marker.render_model.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var material := mesh.get_active_material(surface) as BaseMaterial3D
				if material == null:
					continue
				check(material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, "Oblique roof texture sampling must stay smooth")
				for texture: Texture2D in [material.albedo_texture,material.normal_texture,material.roughness_texture]:
					if texture == null:
						continue
					check(texture.get_size() == Vector2(4096,4096), "Loaded PBR maps must preserve Blender 4K detail: " + texture.resource_path)
					pbr_maps[texture.resource_path] = str(texture.get_size())
	check(not solid_at(Vector2(-1000,-800)), "Painted upper cave opening must be clear")
	check(solid_at(Vector2(-1230,-800)), "Cave back wall must remain solid")
	check(not solid_at(Vector2(2816,420)), "Boat slip lower center must stay open")
	check(not solid_at(Vector2(1472,1916)), "Tower basin bottom must have no permanent slab")
	check(room.get_node("Volumes/Lake").contains_global_point(Vector2(2200,1200)), "Authored lake volume must be retained")
	check(room.get_node("Volumes/AirPocket").contains_global_point(Vector2(1472,1200)), "Tower air pocket must remain aligned")
	for key: String in ["Geometry/BreakableWall", "Volumes/BreakableWall", "BreakableWall"]:
		check(room.get_node(key).get("stone_texture") != null and room.get_node(key).collision_layer != 0, "Breakable rocks must retain painted stone and solid collision")
	var floor_results := {}
	for landmark: String in ["Fisher house", "Workshop", "Tower"]:
		room.focus_landmark(landmark)
		await frames(25)
		var house := room.get_landmark_house(landmark) as Node2D
		if is_instance_valid(house):
			check(not house.render_model.is_cutaway, "Walking outside must not open the house: " + landmark)
			await process_frame
			Input.action_press("interact")
			await process_frame
			await process_frame
			Input.action_release("interact")
			await frames(25)
			check(house.is_player_inside(player), "Interact must enter the house: " + landmark)
		var building := "FisherHouse" if landmark == "Fisher house" else landmark
		var marker: Node2D = room.get_node("Buildings/" + building)
		check(player.is_on_floor(), "Real player must stand on the rendered model floor: " + landmark)
		check(marker.render_model.is_cutaway, "Entry must open the facade: " + landmark)
		floor_results[landmark] = {"position":str(player.position), "on_floor":player.is_on_floor(), "cutaway":marker.render_model.is_cutaway}
	room.focus_landmark("Shore")
	await frames(12)
	check(not room.get_node("Buildings/Tower").render_model.is_cutaway, "Tower facade must restore on exit")
	room.focus_landmark("Cave")
	await frames(25)
	check(player.is_on_floor(), "Player must stand on the traced painted cave floor")
	player.set_physics_process(false)
	player.global_position = Vector2(2200,1200)
	await frames(8)
	check(player.is_in_prototype_water(), "Existing swimming must activate outside the air pocket")
	player.global_position = Vector2(1472,1200)
	await frames(8)
	check(not player.is_in_prototype_water(), "Existing air pocket must keep tower interior dry")
	room.set_overview(true)
	await capture("playtest_overview")
	room.all_cutaways = true
	await capture("playtest_overview_cutaway")
	room.all_cutaways = false
	room.focus_landmark("Shore")
	await capture("playtest_shore")
	room.focus_landmark("Tower")
	await capture("playtest_tower_inside")
	room.focus_landmark("Cave")
	await capture("playtest_cave")
	room.focus_landmark("Workshop")
	await capture("playtest_workshop")
	var report := {"passed":failures.is_empty(), "failures":failures,"godot":Engine.get_version_info().string,"display":DisplayServer.get_name(),"canvas":manifest.canvas,"origin":manifest.world_origin,"painted_chunks":manifest.chunks.size(),"rear_wood_chunks":rear_wood.get_child_count(),"rear_rock_chunks":rear_rocks.get_child_count(),"old_tile_collision_enabled":false,"rock_polygons":rocks.get_child_count(),"physics_alpha_samples":physics_samples,"physics_alpha_mismatches":physics_mismatch,"model_surfaces":manifest.assembly.surfaces.size(),"floors":floor_results,"render_scale":stage.render_scale,"house_viewport_size":str(stage.far_view.size),"loaded_pbr_maps":pbr_maps,"rendered_images":captured}
	FileAccess.open("res://work/krita-map-import/verification.json", FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("KRITA_PLAYTEST_CHECK ", JSON.stringify(report))
	room.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
