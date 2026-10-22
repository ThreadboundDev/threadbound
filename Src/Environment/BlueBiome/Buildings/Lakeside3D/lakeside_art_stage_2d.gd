@tool
extends Node2D
## Established shared-World3D / two-pass art pattern, at the new models' 128 px/u.
## The 2D room continues to own movement, collisions, water and camera limits.
const LIGHTING := preload("res://Src/Environment/BlueBiome/Buildings/Lakeside3D/lakeside_lighting_3d.tscn")
const PPU := 128.0
# SSAO creates a five-level depth mip chain at half resolution. During editor
# scene loading the host viewport can briefly be 2x2; retain valid buffers until
# it is large enough, rather than resizing both lit passes to 3x3.
const MIN_RENDER_DIMENSION := 64
@export_enum("Soft daylight", "Blue dusk") var lighting_preset := 0:
	set(value):
		lighting_preset = value
		if is_instance_valid(lighting):
			lighting.lighting_preset = value
## Supersample the buildings before compositing them into the 2D scene.
@export_range(0.5, 2.0, 0.05) var render_scale := 2.0
@export var preview_center := Vector2(600, -1750)
@export_range(0.15, 2.0, 0.01) var preview_zoom := 0.22

var far_view: SubViewport
var near_view: SubViewport
var world_stage: Node3D
var lighting: Node3D
var far_camera: Camera3D
var near_camera: Camera3D
var far_sprite: Sprite2D
var near_sprite: Sprite2D
var placements: Array[Node2D] = []

func _ready() -> void:
	add_to_group("lakeside_3d_stage")
	far_view = _make_view("BuildingsBehindPlayer")
	far_view.world_3d = World3D.new()
	world_stage = Node3D.new()
	world_stage.name = "SharedLakesideWorld"
	far_view.add_child(world_stage)
	lighting = LIGHTING.instantiate() as Node3D
	world_stage.add_child(lighting)
	lighting.lighting_preset = lighting_preset
	far_camera = _make_camera(far_view, 1)
	far_sprite = _make_sprite(far_view, -10)
	near_view = _make_view("FacadesInFrontOfPlayer")
	near_view.world_3d = far_view.world_3d
	near_camera = _make_camera(near_view, 2)
	near_sprite = _make_sprite(near_view, 10)
	for existing in get_tree().get_nodes_in_group("lakeside_model_2d"):
		if existing.get_viewport() == get_viewport():
			register_placement(existing)
	_sync_camera()

func _make_view(label: String) -> SubViewport:
	var view := SubViewport.new()
	view.name = label
	view.size = Vector2i(1280, 720)
	view.transparent_bg = true
	view.handle_input_locally = false
	view.gui_disable_input = true
	view.msaa_3d = Viewport.MSAA_4X
	view.positional_shadow_atlas_size = 2048
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	return view

func _make_camera(view: SubViewport, mask: int) -> Camera3D:
	var camera := Camera3D.new()
	camera.name = "SideViewCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.cull_mask = mask
	camera.near = 0.1
	camera.far = 85.0
	camera.current = true
	view.add_child(camera)
	return camera

func _make_sprite(view: SubViewport, depth: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "LitBackgroundArt" if depth < 0 else "RemovableForegroundArt"
	sprite.texture = view.get_texture()
	sprite.z_index = depth
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# The 3D surface is already lit. Avoid multiplying a second ambient grade.
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = unshaded
	if depth > 0:
		var wet_facade := ShaderMaterial.new()
		wet_facade.shader = load("res://Src/Environment/BlueBiome/Water/submerged_facade.gdshader")
		sprite.material = wet_facade
	add_child(sprite)
	return sprite

func register_placement(placement: Node2D) -> void:
	if placement in placements or not is_instance_valid(world_stage):
		return
	if placement.model_scene == null:
		return
	placements.append(placement)
	placement.stage = self
	placement.render_model = placement.model_scene.instantiate() as Node3D
	if placement.render_model == null:
		push_error("Lakeside model scene must have a Node3D root: " + str(placement.name))
		return
	placement.render_model.name = placement.name
	world_stage.add_child(placement.render_model)
	placement._process(0.0)
	placement._update_cutaway()

func _process(_delta: float) -> void:
	if is_instance_valid(far_view):
		_sync_camera()

func _sync_camera() -> void:
	var screen := get_viewport_rect().size
	var target_size := Vector2i(roundi(screen.x * render_scale), roundi(screen.y * render_scale))
	if target_size.x < MIN_RENDER_DIMENSION or target_size.y < MIN_RENDER_DIMENSION:
		return
	var center := preview_center
	var zoom := Vector2.ONE * preview_zoom
	if not Engine.is_editor_hint():
		# Inverse canvas transform keeps the art registered to the 2D camera,
		# including smoothing/zoom and the player's existing camera offset.
		var canvas := get_viewport().get_canvas_transform()
		center = canvas.affine_inverse() * (screen * 0.5)
		zoom = canvas.get_scale().abs()
	if far_view.size != target_size:
		far_view.size = target_size
		near_view.size = target_size
	var world_center := Vector3(center.x / PPU, -center.y / PPU, 0)
	for camera in [far_camera, near_camera]:
		camera.size = screen.y / (PPU * maxf(zoom.y, 0.001))
		camera.position = world_center + Vector3(0, 0, 40)
		camera.rotation = Vector3.ZERO
	for sprite in [far_sprite, near_sprite]:
		sprite.global_position = center
		sprite.global_scale = screen / Vector2(target_size) / zoom
	var lake := get_parent().get_node_or_null("Volumes/Lake")
	var wet_material := near_sprite.material as ShaderMaterial
	if lake != null and wet_material != null:
		var points := PackedVector2Array()
		for point: Vector2 in lake.points:
			points.append(lake.to_global(point))
		var count := mini(points.size(),256)
		points.resize(256)
		wet_material.set_shader_parameter("lake_points",points)
		wet_material.set_shader_parameter("lake_count",count)
		wet_material.set_shader_parameter("surface_y",lake.get_surface_global_y())
		wet_material.set_shader_parameter("water_opacity",lake.get_presentation_opacity())
		wet_material.set_shader_parameter("shallow_color",Color(lake.water_color.r,lake.water_color.g,lake.water_color.b,1))
		wet_material.set_shader_parameter("deep_color",lake.deep_water_color)
		if is_instance_valid(lake._fill):
			lake._fill.material.set_shader_parameter("facade_reflection_texture",near_view.get_texture())
			lake._fill.material.set_shader_parameter("has_facade_reflection",true)
