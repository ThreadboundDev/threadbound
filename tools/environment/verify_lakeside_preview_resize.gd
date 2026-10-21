extends SceneTree
## Rendered regression: editor-size viewports must not create invalid SSAO mips.
## Run with Forward+ (not --headless) to exercise actual rendering allocations.
var failures: Array[String] = []
var checks := 0
var host: SubViewport
var stage: Node2D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func rendered_frames(count: int) -> void:
	for index in count:
		await RenderingServer.frame_post_draw

func registered_point(camera: Camera3D, sprite: Sprite2D, viewport: SubViewport, point: Vector3) -> Vector2:
	return sprite.to_global(camera.unproject_position(point) - Vector2(viewport.size) * 0.5)

func run() -> void:
	check(DisplayServer.get_name() != "headless", "Use real Forward+ rendering for the mipmap regression")
	host = SubViewport.new()
	host.name = "EditorSizedHost"
	host.size = Vector2i(2, 2)
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	stage = load("res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_art_stage_2d.tscn").instantiate()
	host.add_child(stage)
	# Retain a real depth/normal pass even without the complete imported village.
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.layers = 3
	mesh.position = Vector3(0.5, 0.5, 0)
	stage.world_stage.add_child(mesh)
	await rendered_frames(3)
	check(stage.far_view.size == Vector2i(1280, 720), "Tiny startup keeps the initial valid render target")
	check(stage.far_view.size == stage.near_view.size, "Both passes keep valid matching startup sizes")
	var env: Environment = stage.lighting.get_node("WorldEnvironment").environment
	check(env.ssao_enabled and env.glow_enabled, "Contact shading and glow remain enabled")
	var samples: Array[Dictionary] = []
	for render_scale: float in [0.5, 1.25, 2.0]:
		stage.render_scale = render_scale
		for dimensions: Vector2i in [Vector2i(2, 2), Vector2i(2, 1080), Vector2i(1920, 2), Vector2i(16, 16), Vector2i(32, 32), Vector2i(64, 64), Vector2i(128, 128), Vector2i(320, 180), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2, 2), Vector2i(1280, 720)]:
			var previous: Vector2i = stage.far_view.size
			host.size = dimensions
			stage._sync_camera()
			var requested := Vector2i(roundi(dimensions.x * render_scale), roundi(dimensions.y * render_scale))
			var usable: bool = requested.x >= stage.MIN_RENDER_DIMENSION and requested.y >= stage.MIN_RENDER_DIMENSION
			await rendered_frames(2)
			check(stage.far_view.size == (requested if usable else previous), "Resize keeps valid buffers or adopts the usable requested size: %s at %.2f" % [dimensions, render_scale])
			check(stage.near_view.size == stage.far_view.size, "Foreground and background keep matching sizes")
			check(stage.far_view.size.x >= 64 and stage.far_view.size.y >= 64, "Neither SSAO pass receives an undersized texture")
			if usable:
				var point := Vector3(2, 1, 0)
				for pass_data: Array in [[stage.far_camera, stage.far_sprite, stage.far_view], [stage.near_camera, stage.near_sprite, stage.near_view]]:
					var projected := registered_point(pass_data[0], pass_data[1], pass_data[2], point)
					check(projected.distance_to(Vector2(256, -128)) < 0.5, "Resizing retains art/collision registration in each pass")
			samples.append({"host": str(dimensions), "scale": render_scale, "render": str(stage.far_view.size), "usable": usable})
	check(env.ssao_enabled and env.glow_enabled and stage.far_view.msaa_3d == Viewport.MSAA_4X, "Quality settings survive all resize transitions")
	var report := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "display": DisplayServer.get_name(), "godot": Engine.get_version_info().string, "samples": samples}
	FileAccess.open("res://work/lakeside-preview-error/verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("LAKESIDE_PREVIEW_RESIZE ", JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures}))
	host.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
