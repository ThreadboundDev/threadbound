extends SceneTree
## Run headless with dummy audio. Checks actual imported assets and 2D gameplay.
const ROOM := "res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_art_prep.tscn"
var failures: Array[String] = []
var room: Node2D

func _initialize() -> void:
	# New asset UIDs are normally indexed by the editor's filesystem scan.
	# This isolated CLI check registers their sidecars without opening the editor.
	for folder: String in ["Textures", "Models"]:
		var directory := "res://Assets/BlueBiome/Art/Lakeside3D/" + folder
		for filename in DirAccess.get_files_at(directory):
			if not filename.ends_with(".import"):
				continue
			var config := ConfigFile.new()
			if config.load(directory.path_join(filename)) == OK:
				var uid := ResourceUID.text_to_id(config.get_value("remap", "uid", ""))
				if uid != -1 and not ResourceUID.has_id(uid):
					ResourceUID.add_id(uid, directory.path_join(filename.trim_suffix(".import")))
	call_deferred("verify")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func bounds(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var local := model.global_transform.affine_inverse() * mesh.global_transform
		var box: AABB = local * mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func verify() -> void:
	check(DisplayServer.get_name() == "headless", "Verification must never open a window")
	room = load(ROOM).instantiate() as Node2D
	root.add_child(room)
	current_scene = room
	await frames(25)
	var stage: Node2D = room.get_node("LakesideArtStage")
	check(stage.far_view.world_3d != null and stage.far_view.world_3d == stage.near_view.world_3d, "Both passes must share the lit 3D world")
	check(stage.far_view.find_children("*", "CollisionObject3D", true, false).is_empty(), "Art must not introduce a 3D collision system")
	check(stage.far_sprite.z_index < 0 and stage.near_sprite.z_index > 4, "Art passes must bracket the existing player artwork layer")
	check(stage.far_sprite.material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED, "3D lighting must not get multiplied by the 2D ambient grade")
	var expected := {"BoatSlip":Vector3(8.08, 7.600945, 5.08), "Workshop":Vector3(7.82, 4.975945, 6.065), "FisherHouse":Vector3(5.82, 6.525945, 5.965), "Tower":Vector3(9.375, 32.03125, 6.0)}
	var actual := {}
	var shared_colors := {}
	for key in expected:
		var marker: Node2D = room.get_node("Buildings/" + str(key))
		check(is_instance_valid(marker.render_model), "Imported 3D instance missing: " + str(key))
		if not is_instance_valid(marker.render_model):
			continue
		var b := bounds(marker.render_model)
		actual[key] = [b.size.x, b.size.y, b.size.z]
		check(b.size.distance_to(expected[key]) < 0.025, "Imported dimensions must match approved source: " + str(key) + " " + str(b.size))
		check(marker.render_model.position.is_equal_approx(Vector3(marker.global_position.x / 128, -marker.global_position.y / 128, 0)), "128 px/unit anchor mismatch: " + str(key))
		check(marker.render_model.find_children("*", "Camera3D", true, false).is_empty(), "Source preview cameras cannot enter runtime models")
		for mesh: MeshInstance3D in marker.render_model.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var material := mesh.mesh.surface_get_material(surface) as BaseMaterial3D
				if material and material.albedo_texture:
					var texture := material.albedo_texture
					var path := texture.resource_path
					if shared_colors.has(path):
						check(shared_colors[path] == texture.get_instance_id(), "Shared tower texture must load once: " + path)
					shared_colors[path] = texture.get_instance_id()
	check(shared_colors.size() == 4, "Buildings must share exactly four original color maps")
	# Direct Godot projection verifies pixel registration through viewport + sprite.
	var point := Vector3(2.0, 1.0, 0)
	var pixel: Vector2 = stage.far_camera.unproject_position(point)
	var reconstructed: Vector2 = stage.far_sprite.to_global(pixel - Vector2(stage.far_view.size) * 0.5)
	check(reconstructed.distance_to(Vector2(256, -128)) < 1.0, "3D art must stay registered with 2D geometry when camera zooms")
	room.set_overview(true)
	await frames(6)
	var overview_pixel: Vector2 = stage.far_camera.unproject_position(point)
	var overview_registered: Vector2 = stage.far_sprite.to_global(overview_pixel - Vector2(stage.far_view.size) * 0.5)
	check(overview_registered.distance_to(Vector2(256, -128)) < 1.0, "Overview zoom must preserve the same art/physics registration")
	room.set_overview(false)
	await frames(6)
	# Real existing player, settled on the temporary 2D floor, enters each sensor.
	for index in [1, 2]:
		room.focus_building(index)
		await frames(20)
		var key := "Workshop" if index == 1 else "FisherHouse"
		var marker: Node2D = room.get_node("Buildings/" + key)
		check(room.get_node("Player").is_on_floor(), "Existing player must stand on the 2D test floor: " + key)
		check(marker.render_model.is_cutaway and not marker.occupants.is_empty(), "Player entry must open the real facade: " + key)
		for part in marker.render_model.facade_parts:
			check(not part.visible, "Facade must be hidden inside: " + str(part.name))
		var limit := 3.035 if index == 1 else 2.035
		for mesh: MeshInstance3D in marker.render_model.find_children("*Roof_Sides_Fixed*", "MeshInstance3D", true, false):
			if "HideWithFacade" in str(mesh.name):
				continue
			check(mesh.is_visible_in_tree(), "Fixed corners must stay connected when facade hides")
			var transform: Transform3D = marker.render_model.global_transform.affine_inverse() * mesh.global_transform
			var minimum := INF
			for surface in mesh.mesh.get_surface_count():
				for vertex: Vector3 in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
					minimum = minf(minimum, absf((transform * vertex).x))
			check(minimum >= limit - 0.01, "Roof must remain outside the interior wall faces: " + str(mesh.name))
		room.get_node("Player").position = Vector2(-650, -69.245)
		await frames(12)
		check(not marker.render_model.is_cutaway, "Facade must return after player exits: " + key)
	var rig: Node3D = stage.lighting
	var day: float = rig.get_node("Sun").light_energy
	room.lighting_preset = 1
	check(rig.get_node("Sun").light_energy < day, "Dusk must update the actual sun")
	check(rig.get_node("Sun").shadow_enabled, "Directional shadow casting must be enabled")
	room.lighting_preset = 0
	check(is_equal_approx(rig.get_node("Sun").light_energy, day), "Daylight preset must restore cleanly")
	for marker in room.get_node("Lanterns").get_children():
		check(marker.has_node("ActorWarmth"), "Lantern must light the existing 2D actors")
		check(is_instance_valid(marker.render_model), "Lantern 3D source must share the art world")
		if is_instance_valid(marker.render_model):
			var light := marker.render_model.get_node("WarmLight") as OmniLight3D
			check(light.shadow_enabled and light.light_cull_mask == 3, "Lantern shadows must reach both 3D passes")
	var report := {"checks_passed":failures.is_empty(), "failures":failures, "godot_version":Engine.get_version_info()["string"], "display":DisplayServer.get_name(), "imported_dimensions":actual, "shared_world":stage.far_view.world_3d == stage.near_view.world_3d, "projection_error_pixels":reconstructed.distance_to(Vector2(256, -128)), "visual_review":"Headless validation only; rendered lighting review awaits the user's playtest."}
	var file := FileAccess.open("res://work/lakeside-godot/verification.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
	print("LAKESIDE_3D_VERIFICATION ", JSON.stringify(report))
	room.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
