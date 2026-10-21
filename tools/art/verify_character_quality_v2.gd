extends SceneTree
## Headless validation of the actual imported art and its compositing settings.
var checks := 0
var failures: Array[String] = []
var room: Node2D

func _initialize() -> void:
	for folder in ["res://Assets/BlueBiome/Characters/SharedTexturesV2", "res://Assets/BlueBiome/Art/LakesideMap", "res://Assets/BlueBiome/Art/Lakeside3D/Models", "res://Assets/BlueBiome/Art/Lakeside3D/Textures", "res://Assets/BlueBiome/Villagers/Models", "res://Assets/BlueBiome/Villagers/Textures", "res://Assets/BlueBiome/Enemies/EaveRunner/Models", "res://Assets/BlueBiome/Enemies/EaveRunner/Textures", "res://Assets/BlueBiome/Enemies/LoomHeron/Models", "res://Assets/BlueBiome/Enemies/LoomHeron/Textures"]:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".import"):
				var config := ConfigFile.new()
				if config.load(folder.path_join(file)) == OK:
					var uid := ResourceUID.text_to_id(config.get_value("remap", "uid", ""))
					if uid != -1 and not ResourceUID.has_id(uid):
						ResourceUID.add_id(uid, folder.path_join(file.trim_suffix(".import")))
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("CHARACTER_V2_FAIL " + message)

func frames(count: int) -> void:
	for i in count:
		await process_frame

func run() -> void:
	room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(6)
	room.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	for enemy in get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var stage = room.get_node("LakesideArtStage")
	check(stage.render_scale == 2.0, "Shared villager/building stage renders at twice screen resolution")
	check(stage.far_view.size == Vector2i(stage.get_viewport_rect().size * 2), "Composited render target has four times the screen pixel count")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://work/character-quality-v2/runtime_manifest.json"))
	var actors: Dictionary = {
		"NetMender": room.get_node("Residents/NetMender").render_model.get_node("ActorPivot"),
		"Boatwright": room.get_node("Residents/Boatwright").render_model.get_node("ActorPivot"),
		"EaveRunner": room.get_node("EaveRunner").model.actor,
		"LoomHeron": room.get_node("LoomHeron").model.actor,
	}
	for name: String in actors:
		var actor: Node3D = actors[name]
		var triangles := 0
		var detail_maps := 0
		var normal_maps := 0
		for mesh_node: MeshInstance3D in actor.find_children("*", "MeshInstance3D", true, false):
			check(mesh_node.lod_bias >= 8.0, name + " retains fine geometry at gameplay distance")
			for surface in mesh_node.mesh.get_surface_count():
				triangles += (mesh_node.mesh as ArrayMesh).surface_get_array_index_len(surface) / 3
				var material := mesh_node.get_active_material(surface) as StandardMaterial3D
				if material:
					check(material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, name + " uses anisotropic mipmap filtering")
					if material.albedo_texture and material.albedo_texture.get_width() == 4096:
						detail_maps += 1
					if material.normal_enabled:
						normal_maps += 1
		check(triangles == int(manifest[name + "_v2.glb"].triangles), name + " full refined topology survives import")
		check(detail_maps >= 5 and normal_maps >= 5, name + " has real 4K color and normal-mapped surfaces")
		check(actor.find_children("*", "CollisionObject3D", true, false).is_empty(), name + " retains existing 2D physics")
		var sidecar := ConfigFile.new()
		var path: String = "res://Assets/BlueBiome/" + ("Villagers" if name in ["NetMender", "Boatwright"] else "Enemies/" + name) + "/Models/" + name + "_v2.glb.import"
		check(sidecar.load(path) == OK and not sidecar.get_value("params", "meshes/generate_lods", true), name + " automatic mesh simplification disabled")
		print("CHARACTER_V2_RUNTIME ", name, " triangles=",triangles," detailed_surfaces=",detail_maps)
	for name in ["EaveRunner", "LoomHeron"]:
		var model = room.get_node(name).model
		check(model._view.size == Vector2i(1536,1536), name + " uses 1536-square render target")
		check(is_equal_approx(model.image.scale.x * 1536, model.camera_span * 96), name + " screen/world proportions preserved")
		check(model._view.msaa_3d == Viewport.MSAA_4X, name + " retains 4x MSAA")
	var heron = room.get_node("LoomHeron")
	check(heron.model._skeleton.find_bone("beak_tip") >= 0, "Heron muzzle bone survives glTF import")
	for clip in [&"needle_aim", &"needle_fire", &"low_recover"]:
		check(heron.model.animator.has_animation(clip), "Dedicated ranged clip imported: " + String(clip))
		check(heron.model.animator.get_animation(clip).loop_mode == Animation.LOOP_NONE, "Ranged clip finishes once: " + String(clip))
	for facing in [-1,1]:
		heron.update_facing(facing)
		var origin: Vector2 = heron._needle_origin() - heron.global_position
		check(origin.x * facing > 45 and origin.x * facing < 155 and origin.y < -70 and origin.y > -200, "Needle originates at visible beak in each facing")
	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"display":DisplayServer.get_name()}
	FileAccess.open("res://work/character-quality-v2/godot_art_verification.json", FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("CHARACTER_V2_GODOT_CHECKS ",checks," failures=",failures)
	room.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
