extends SceneTree
## Render damage stages behind a cave face; cracks must not bleed through it.
var failures: Array[String] = []
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 512)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var parent := Node2D.new()
	parent.z_index = 40 # Parent depth must not lift stamps over the cave.
	viewport.add_child(parent)
	var wall = load("res://Src/Environment/BlueBiome/Prototypes/blue_breakable_rock.tscn").instantiate()
	wall.position = Vector2(256, 256)
	wall.size = Vector2(256, 384)
	wall.hits_to_break = 4
	parent.add_child(wall)
	var cave := Polygon2D.new()
	cave.polygon = PackedVector2Array([Vector2(256, 0), Vector2(512, 0), Vector2(512, 512), Vector2(256, 512)])
	cave.color = Color(0.4, 0.2, 0.1, 1)
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	cave.material = unlit # Isolate draw order from the intended nearby crack light.
	cave.z_index = -5
	viewport.add_child(cave)
	await process_frame
	check(not wall.z_as_relative and wall.z_index == -6, "Stone stays immediately behind cave depth -5 regardless of parent")
	check(wall._crack_overlay.z_as_relative and wall._crack_overlay.z_index == 0, "Cracks inherit the stone depth")
	check(wall.collision_layer == 1 and wall.hits_to_break == 4, "Collision and durability remain unchanged")
	for stage in 4:
		wall.hits_taken = stage
		wall.queue_redraw()
		await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var image := viewport.get_texture().get_image()
			var leaking := 0
			for y in range(64, 448):
				for x in range(260, 390):
					var pixel := image.get_pixel(x, y)
					if absf(pixel.r - 0.4) > 0.02 or absf(pixel.g - 0.2) > 0.02 or absf(pixel.b - 0.1) > 0.02:
						leaking += 1
			check(leaking == 0, "Cave fully occludes stone and emissive cracks at damage stage %d" % stage)
		check(wall.get_damage_stage() == stage, "Existing damage stages remain usable")
	wall._spawn_fracture_effect(null)
	var effect := parent.get_child(parent.get_child_count() - 1)
	check(effect.name.begins_with("BlueRockShatter") and not effect.z_as_relative and effect.z_index == -6, "Debris stays at the stamp depth under a shifted parent")
	viewport.queue_free()
	await process_frame
	print("BREAKABLE_CAVE_DEPTH: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() else 0)
