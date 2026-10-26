extends SceneTree
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("verify")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("WATER_SURFACE_FAIL " + message)

func verify() -> void:
	var room = load("res://Src/Environment/BlueBiome/Prototypes/Rooms/blue_lakeside_krita_playtest.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	for frame in 5:
		await physics_frame
	var lake = room.get_node("Volumes/Lake")
	var player = room.get_node("Player")
	player.set_physics_process(false)
	var surface: float = lake.get_surface_global_y()
	check(is_equal_approx(surface, 411), "Shared lake plane is y=411")
	for point: Vector2 in lake.points:
		if lake.to_global(point).y < 500:
			check(is_equal_approx(lake.to_global(point).y, surface), "Every top vertex meets the mirror plane")
	var backdrop: ShaderMaterial = room.get_node("LakePresentation/UnderwaterDepth").material
	check(is_equal_approx(float(backdrop.get_shader_parameter("water_surface_y")), surface), "Backdrop cutoff shares the lake plane")
	lake.water_color = Color(.17, .43, .51, .29)
	lake.deep_water_color = Color(.02, .04, .08, 1)
	lake.underwater_opacity = .071
	lake.immersion_opacity = .19
	var material: ShaderMaterial = lake._fill.material
	for wet: bool in [false, true]:
		var target := Vector2(2816, surface + (1 if wet else -1))
		player.global_position += target - player.get_water_sample_position()
		player.reset_physics_interpolation()
		for frame in 3:
			await physics_frame
		check(player.is_in_prototype_water() == wet, "Physical wet state agrees at the actual surface")
		lake._update_water_preview(.5)
		check(is_equal_approx(lake.get_presentation_opacity(),.29), "Scenery opacity stays steady across the physical wet-state boundary")
		check(is_equal_approx(float(material.get_shader_parameter("water_opacity")), .29), "Inspector scenery opacity reaches the rear material in both observer states")
		check(is_equal_approx(float(lake._immersion_fill.material.get_shader_parameter("immersion_opacity")),.19), "Foreground immersion has an independent inspector opacity")
	check((material.get_shader_parameter("shallow_color") as Color).is_equal_approx(Color(.17,.43,.51,1)), "Shallow color reaches shader")
	check((material.get_shader_parameter("deep_color") as Color).is_equal_approx(lake.deep_water_color), "Deep color reaches shader")
	lake.water_color.a = .071
	player.global_position += Vector2(2816, surface-1) - player.get_water_sample_position()
	for frame in 3:
		await physics_frame
	lake._update_water_preview(.5)
	check(not player.is_in_prototype_water(), "Matching legacy/scenery opacity cannot affect physical wet-state classification")
	print("LAKESIDE_WATER_SURFACE_CHECK ", JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	room.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
