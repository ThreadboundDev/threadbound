extends SceneTree
const OUT := "res://work/water-delivery-2026-10-22"
var room
var failures: Array[String] = []
var checks := 0
var camera: Camera2D
var captures: Array[String] = []

func _initialize() -> void:
	call_deferred("verify")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("WATER_DELIVERY_FAIL " + message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func capture(label: String, center: Vector2, zoom: float) -> void:
	camera.global_position = center
	camera.zoom = Vector2.ONE * zoom
	camera.force_update_scroll()
	for frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT.path_join(label+".png")) == OK, "Saved GPU view: "+label)
	captures.append(label)

func verify() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(5)
	var rims = room.get_node("Geometry/TerrainArtwork/RockContactRims")
	check(rims.z_index == 3 and not rims.z_as_relative, "Contact rims draw in front of player")
	check(room.get_node("Geometry/TerrainArtwork/rear_cave").z_index == -5, "Broad cave back wall remains behind player")
	check(rims.edge_count > 0 and rims.triangle_count > 0 and rims.get_child_count() <= 32, "Contact strips generated in batched texture meshes")
	check(rims.find_children("*","CollisionObject2D",true,false).is_empty(), "Rims add no physics")
	var source = room.get_node("Geometry/TerrainArtwork/rear_cave").get_child(0)
	var original_position: Vector2 = source.position
	var original_signature: int = rims._signature
	source.position += Vector2(1,0)
	rims.rebuild()
	check(rims._signature != original_signature, "Moving painted art rebuilds contact registration")
	source.position = original_position
	rims.rebuild()
	check(rims._signature == original_signature, "Restored painted art restores contact registration")
	var lake = room.get_node("Volumes/Lake")
	check(lake._fill.z_index == -4 and not lake._fill.z_as_relative, "Reflection body is behind player and contact rims")
	check(lake._immersion_fill.z_index == 2 and not lake._immersion_fill.z_as_relative, "Light immersion tint is above actors but below contact art")
	for parameter: String in ["surface_y","water_opacity","air_counts","pocket_count"]:
		check(lake._fill.material.get_shader_parameter(parameter) == lake._immersion_fill.material.get_shader_parameter(parameter), "Both water passes share "+parameter)
	for pocket in get_nodes_in_group("lake_air_pockets"):
		check(pocket.lake_presentation and pocket.pocket_caustic_intensity <= .06, "Every dry pocket uses the same restrained presentation")
	var stage = room.get_node("LakesideArtStage")
	check(stage.near_sprite.material is ShaderMaterial, "Exterior facade has its own submerged grade")
	check(int(stage.near_sprite.material.get_shader_parameter("lake_count")) == lake.points.size(), "Exterior wet mask follows lake geometry independently of dry pockets")
	check(bool(lake._fill.material.get_shader_parameter("has_facade_reflection")), "Rear reflection includes the separate foreground facade texture")
	for rim: MeshInstance2D in rims.get_children():
		check(rim.texture != null and rim.texture.resource_path.begins_with("res://Assets/BlueBiome/Art/LakesideMap/rear_cave_"), "Rim reuses original painted alpha")
		var arrays := rim.mesh.surface_get_arrays(0)
		var valid := true
		for uv: Vector2 in arrays[Mesh.ARRAY_TEX_UV]:
			valid = valid and uv.is_finite() and uv.x >= -.001 and uv.y >= -.001 and uv.x <= 1.001 and uv.y <= 1.001
		check(valid, "Rim UVs preserve original chunk registration")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		for enemy in get_nodes_in_group("enemies"):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
		for ui in root.find_children("*","CanvasLayer",true,false):
			ui.visible = false
		room.get_node("Player/Camera2D").enabled = false
		room.get_node("OverviewCamera").enabled = false
		camera = Camera2D.new()
		room.add_child(camera)
		camera.make_current()
		var player = room.get_node("Player")
		room.focus_landmark("Cave")
		room.get_node("Player/Camera2D").enabled = false
		camera.make_current()
		await frames(45)
		player.set_physics_process(false)
		await capture("cave_contact",player.global_position+Vector2(35,-15),2.0)
		player.visible = false
		await capture("shore",Vector2(2816,420),1.0)
		player.global_position = Vector2(2200,1200)
		player.reset_physics_interpolation()
		await frames(20)
		check(player.is_in_prototype_water(), "Exterior inspection remains physically wet")
		await capture("tower_wet_exterior",Vector2(1472,1150),.48)
		player.visible = true
		player.set_physics_process(true)
		await frames(20)
		player.set_physics_process(false)
		await capture("swimmer",player.global_position,1.5)
		player.visible = false
		player.global_position = Vector2(1472,1037.955)
		player.reset_physics_interpolation()
		await frames(20)
		check(not player.is_in_prototype_water(), "Dry cutaway retains dry movement classification")
		await capture("tower_dry_cutaway",Vector2(1472,1150),.48)
		room.lighting_preset = 1
		await capture("tower_dusk",Vector2(1472,1150),.48)
		room.lighting_preset = 0
		for label: String in ["Fisher house", "Workshop"]:
			room.focus_landmark(label)
			room.get_node("Player/Camera2D").enabled = false
			camera.make_current()
			var house = room.get_landmark_house(label)
			player.visible = true
			player.set_physics_process(true)
			house._enter_house(player)
			await frames(30)
			check(house.is_player_inside(player) and player.is_on_floor(), label+": standing inside for contact inspection")
			player.set_physics_process(false)
			await capture("fisher_interior" if label == "Fisher house" else "workshop_interior",house.floor_bounds().get_center()+Vector2(0,-120),1.5)
			house.leave_house()
	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"display":DisplayServer.get_name(),"rim_meshes":rims.get_child_count(),"rim_edges":rims.edge_count,"rim_triangles":rims.triangle_count,"captures":captures}
	FileAccess.open(OUT.path_join("verification.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("WATER_DELIVERY_CHECK ",JSON.stringify(result))
	room.queue_free()
	await frames(3)
	call_deferred("quit",0 if failures.is_empty() else 1)
