extends Node3D
## Authored composition using retained CC0 assets; isolated from production scenes.

const ACTOR = preload("res://scripts/study_actor.gd")
const WORKSHOP = preload("res://assets/workshop.glb")
const TREE = preload("res://assets/foliage/tree_pineTallA_detailed.glb")
const BROADLEAF = preload("res://assets/foliage/tree_detailed.glb")
const SHRUB = preload("res://assets/foliage/plant_bushLarge.glb")
const ROCK = preload("res://assets/foliage/rock_largeD.glb")
const PATH_STONE = preload("res://assets/foliage/rock_smallFlatA.glb")
var actor: CharacterBody3D
var rng := RandomNumberGenerator.new()
var palette := {}
var worker_players: Array[AnimationPlayer] = []

func _ready() -> void:
	rng.seed = 281026
	configure_inputs()
	for item in [["grass", "526c61"], ["stone", "6a7775"], ["wood", "534a40"],
		["planks", "927e62"], ["flax", "c0b18b"], ["indigo", "405965"], ["path", "a29577"]]:
		palette[item[0]] = material(Color(item[1]))
	lighting()
	terrain(-24, 10, -24, 24)
	terrain(15, 28, -24, 24)
	water()
	var workshop: Node3D = WORKSHOP.instantiate()
	workshop.name = "WorkingVillageWorkshop"
	add_child(workshop)
	workshop.position = Vector3(0, 0.12, -7)
	for player in workshop.find_children("*", "AnimationPlayer", true, false):
		worker_players.append(player)
		for clip in player.get_animation_list():
			if clip != "RESET":
				player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				player.play(clip)
				break
	box("HouseInterior", Vector3(0, 1.3, -9.4), Vector3(4.1, 2.6, 3.3), palette.stone, true, false)
	box("PorchFloor", Vector3(0, 0.06, -8.5), Vector3(4.4, 0.24, 6), palette.wood, true, false)
	box("WorkbenchContact", Vector3(0.65, 0.7, -6.02), Vector3(1.3, 1.25, 0.75), palette.wood, true, false)
	# A broad footpath leads to the worker and the bridge without concealing the ground.
	for i in range(15):
		var z := 6.0 - i * 0.77
		var x := sin(i * 0.26) * 0.6
		var slab: Node3D = PATH_STONE.instantiate()
		add_child(slab)
		var bound := model_bounds(slab)
		slab.scale = Vector3(rng.randf_range(0.8, 1.4), 0.07, 0.65) / bound.size
		slab.position = Vector3(x, 0.0, z) - bound.position * slab.scale
		slab.rotation.y = rng.randf_range(-0.15, 0.15)
		for mesh in slab.find_children("*", "MeshInstance3D", true, false):
			mesh.material_override = palette.stone
	bridge()
	foliage()
	for i in range(24):
		rock(Vector3(9.5 + rng.randf_range(-0.4, 0.3), -0.12, -22 + i * 2), Vector3(rng.randf_range(0.7, 1.5), rng.randf_range(0.4, 0.9), rng.randf_range(0.7, 1.4)))
		rock(Vector3(15.5 + rng.randf_range(-0.3, 0.4), -0.12, -22 + i * 2), Vector3(1.3, rng.randf_range(0.5, 1.0), 1.2))
	# Three modest, reachable elevations for jump depth and landing judgments.
	for i in range(3):
		var h := 0.45 + 0.45 * i
		box("JumpStone" + str(i), Vector3(-6.5 - i * 1.5, h / 2, -1.5 - i * 1.9), Vector3(1.6, h, 1.7), palette.stone, true)
	for i in range(11):
		rock(Vector3(rng.randf_range(-23, 26), -0.2, -27), Vector3(rng.randf_range(3.0, 7.0), rng.randf_range(3.0, 7.0), 4.0))
	actor = ACTOR.new()
	add_child(actor)
	hud()
	if "--capture-study" in OS.get_cmdline_user_args() or "--capture-review" in OS.get_cmdline_user_args():
		capture()

func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	return mat

func lighting() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("5d7d88")
	sky_material.sky_horizon_color = Color("b2c1b9")
	sky_material.ground_bottom_color = Color("435758")
	sky_material.ground_horizon_color = Color("b2c1b9")
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a6b8c0")
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color("9cbbb9")
	env.fog_density = 0.009
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -35, 0)
	sun.light_color = Color("ffdfb1")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 75
	add_child(sun)

func box(label: String, pos: Vector3, size: Vector3, mat: Material, collision := false, visible_mesh := true) -> Node3D:
	var parent: Node3D = StaticBody3D.new() if collision else Node3D.new()
	parent.name = label
	parent.position = pos
	add_child(parent)
	if visible_mesh:
		var instance := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = size
		instance.mesh = mesh
		instance.material_override = mat
		parent.add_child(instance)
	if collision:
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		parent.add_child(collider)
	return parent

func terrain(x0: int, x1: int, z0: int, z1: int) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(x0, x1, 2):
		for z in range(z0, z1, 2):
			for vertex in [Vector3(x, 0, z), Vector3(x+2, 0, z), Vector3(x, 0, z+2), Vector3(x+2, 0, z), Vector3(x+2, 0, z+2), Vector3(x, 0, z+2)]:
				var variation := 0.5 + 0.2 * sin(vertex.x * 0.2) + 0.2 * cos(vertex.z * 0.25)
				tool.set_color(Color("52695b").lerp(Color("495f55"), variation))
				tool.add_vertex(vertex)
	tool.generate_normals()
	var mesh := tool.commit()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var mat := material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = mat
	add_child(instance)
	instance.create_trimesh_collision()

func rock(pos: Vector3, size: Vector3) -> void:
	var instance: Node3D = ROCK.instantiate()
	add_child(instance)
	var bound := model_bounds(instance)
	instance.scale = size / bound.size
	instance.position = pos - bound.position * instance.scale
	instance.rotation.y = rng.randf_range(0, TAU)
	for mesh in instance.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = palette.stone
		mesh.create_trimesh_collision()

func water() -> void:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
uniform vec4 water_color : source_color = vec4(0.15, 0.34, 0.38, 1.0);
void fragment() {
float ripple = sin(UV.x * 180.0 + TIME * 1.2) * sin(UV.y * 155.0 - TIME * 0.8);
ALBEDO = water_color.rgb + vec3(ripple * 0.018);
ROUGHNESS = 0.32;
METALLIC = 0.1;
NORMAL_MAP = vec3(0.5 + ripple * 0.045, 0.5, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var instance := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(190, 190)
	instance.mesh = mesh
	instance.material_override = mat
	instance.position.y = -0.33
	add_child(instance)

func bridge() -> void:
	for i in range(13):
		box("BridgePlank", Vector3(9.5 + i * 0.5, 0.15, 2.5), Vector3(0.46, 0.2, 2.5), palette.planks, true)
	for x in [9.5, 12.5, 15.5]:
		for z in [1.17, 3.83]:
			box("BridgePost", Vector3(x, 0.65, z), Vector3(0.14, 1.3, 0.14), palette.wood, true)
	for z in [1.17, 3.83]:
		box("BridgeRail", Vector3(12.5, 1.08, z), Vector3(6.2, 0.075, 0.075), palette.flax, true)
	# Small cloth pennants connect the structure to the indigo/flax workshop palette.
	for i in range(6):
		box("ClothTie", Vector3(10 + i, 0.93, 1.17), Vector3(0.24, 0.32, 0.025), palette.indigo)

func model_bounds(root: Node3D) -> AABB:
	var total := AABB()
	var first := true
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		var local: Transform3D = root.global_transform.affine_inverse() * mesh.global_transform
		var bound: AABB = local * mesh.get_aabb()
		total = bound if first else total.merge(bound)
		first = false
	return total

func foliage() -> void:
	for i in range(55):
		var x := rng.randf_range(-22, 25)
		var z := rng.randf_range(-22, 20)
		if (x > 7 and x < 17) or (absf(x) < 5 and z > -14 and z < 10) or (x < -5 and x > -12 and z > -8 and z < 1):
			continue
		var tree: Node3D = BROADLEAF.instantiate() if i % 4 == 0 else TREE.instantiate()
		add_child(tree)
		tint_foliage(tree)
		var bound := model_bounds(tree)
		var factor := rng.randf_range(4.5, 7.0) / bound.size.y
		tree.scale *= factor
		tree.position = Vector3(x, -bound.position.y * factor, z)
		tree.rotation.y = rng.randf_range(0, TAU)
	for i in range(35):
		var x := rng.randf_range(-20, 25)
		var z := rng.randf_range(-20, 19)
		if (x > 8 and x < 17) or (absf(x) < 4 and z > -13 and z < 9):
			continue
		var shrub: Node3D = SHRUB.instantiate()
		add_child(shrub)
		tint_foliage(shrub)
		var bound := model_bounds(shrub)
		var factor := rng.randf_range(0.65, 1.1) / bound.size.y
		shrub.scale *= factor
		shrub.position = Vector3(x, -bound.position.y * factor, z)

func tint_foliage(root: Node3D) -> void:
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var source: Material = mesh.get_active_material(surface)
			if source is StandardMaterial3D:
				var mat: StandardMaterial3D = source.duplicate()
				if "leaf" in source.resource_name.to_lower() or "grass" in source.resource_name.to_lower():
					mat.albedo_color = Color("34554b")
				elif "wood" in source.resource_name.to_lower():
					mat.albedo_color = Color("615346")
				mat.roughness = 0.95
				mesh.set_surface_override_material(surface, mat)

func configure_inputs() -> void:
	for item in [["left", KEY_A], ["right", KEY_D], ["forward", KEY_W], ["back", KEY_S],
		["jump", KEY_SPACE], ["sprint", KEY_SHIFT], ["reset", KEY_R], ["weapons", KEY_V], ["release_mouse", KEY_ESCAPE]]:
		if not InputMap.has_action(item[0]):
			InputMap.add_action(item[0])
		var event := InputEventKey.new()
		event.physical_keycode = item[1]
		InputMap.action_add_event(item[0], event)
	for item in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0],
		["forward", JOY_AXIS_LEFT_Y, -1.0], ["back", JOY_AXIS_LEFT_Y, 1.0],
		["look_left", JOY_AXIS_RIGHT_X, -1.0], ["look_right", JOY_AXIS_RIGHT_X, 1.0],
		["look_up", JOY_AXIS_RIGHT_Y, -1.0], ["look_down", JOY_AXIS_RIGHT_Y, 1.0]]:
		if not InputMap.has_action(item[0]):
			InputMap.add_action(item[0], 0.18)
		var event := InputEventJoypadMotion.new()
		event.axis = item[1]
		event.axis_value = item[2]
		InputMap.action_add_event(item[0], event)
	for item in [["jump", JOY_BUTTON_A], ["sprint", JOY_BUTTON_LEFT_SHOULDER], ["reset", JOY_BUTTON_BACK], ["weapons", JOY_BUTTON_Y]]:
		var event := InputEventJoypadButton.new()
		event.button_index = item[1]
		InputMap.action_add_event(item[0], event)

func hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "THREADBOUND  /  A THIRD-PERSON STUDY"
	title.position = Vector2(30, 24)
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("eee4ca"))
	layer.add_child(title)
	var hint := Label.new()
	hint.text = "Workshop clearing   ·   Walk the path, visit the worker, cross the stream"
	hint.position = Vector2(30, 51)
	hint.add_theme_font_size_override("font_size", 14)
	layer.add_child(hint)
	var controls := Label.new()
	controls.text = "WASD  move     MOUSE  look     SPACE  jump     SHIFT  run     WHEEL  zoom\nV  compare weapons     R  return     ESC  release cursor     CLICK  resume\nController: left/right sticks · A jump · LB run · Y weapons · Back return"
	controls.position = Vector2(30, 804)
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_shadow_color", Color(0.05, 0.09, 0.1, 1))
	controls.add_theme_constant_override("shadow_offset_x", 1)
	controls.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(controls)

func capture() -> void:
	var review := "--capture-review" in OS.get_cmdline_user_args()
	if review:
		actor.global_position = Vector3(0, 0.3, -2)
		actor.visual.rotation.y = 0
		actor.yaw = -0.14
		actor.distance = 4.1
	for i in range(50):
		await get_tree().process_frame
	var frame_times: Array[float] = []
	for i in range(120):
		await get_tree().process_frame
		frame_times.append(get_process_delta_time() * 1000.0)
	frame_times.sort()
	await RenderingServer.frame_post_draw
	var stem := "third_person_character" if review else "third_person_gameplay"
	DirAccess.make_dir_recursive_absolute("res://captures")
	get_viewport().get_texture().get_image().save_png("res://captures/" + stem + ".png")
	var report := FileAccess.open("res://captures/" + stem + "_metrics.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"adapter": RenderingServer.get_video_adapter_name(),
		"renderer": "GL Compatibility", "resolution": str(get_viewport().get_visible_rect().size),
		"sample_frames": frame_times.size(), "median_frame_ms": frame_times[60],
		"p95_frame_ms": frame_times[114], "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}, "\t"))
	print("STUDY_CAPTURE_SAVED")
	get_tree().quit()
