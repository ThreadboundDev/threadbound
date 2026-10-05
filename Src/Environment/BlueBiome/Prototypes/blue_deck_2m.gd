@tool
extends Node2D
## Repeat at 160 px intervals. The origin is the left walking-surface endpoint.
const MODEL_PATH := "res://Assets/BlueBiome/Prototype/Placeables/Buildings/Pavilion3D_V2/Modules/blue_deck_2m.glb"
const PPM := 80.0
const LENGTH_M := 2.0
const LENGTH_PX := 160.0
const TILT := 0.13962634016
const VIEW_SIZE := Vector2i(400, 400)

@export var one_way := false:
	set(value):
		one_way = value
		if is_instance_valid(collision_shape):
			collision_shape.one_way_collision = value

var far_view: SubViewport
var near_view: SubViewport
var collision_shape: CollisionPolygon2D

func _ready() -> void:
	add_to_group("blue_biome_deck")
	_build_collision()
	_build_art()

func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "DeckCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	collision_shape = CollisionPolygon2D.new()
	collision_shape.name = "WalkingSurface"
	collision_shape.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(LENGTH_PX, 0),
		Vector2(LENGTH_PX, 24), Vector2(0, 24)
	])
	collision_shape.one_way_collision = one_way
	collision_shape.one_way_collision_margin = 8.0
	body.add_child(collision_shape)

func _viewport(node_name: String) -> SubViewport:
	var view := SubViewport.new()
	view.name = node_name
	view.size = VIEW_SIZE
	view.transparent_bg = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	return view

func _camera(view: SubViewport, render_layers: int) -> void:
	var camera := Camera3D.new()
	camera.name = "SideViewCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = float(VIEW_SIZE.y) / PPM
	camera.cull_mask = render_layers
	view.add_child(camera)
	camera.position = Vector3(1, 30.0 * tan(TILT), 30)
	camera.look_at(Vector3(1, 0, 0))
	camera.current = true

func _layer_meshes(node: Node, render_layers: int) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).layers = render_layers
	for child in node.get_children():
		_layer_meshes(child, render_layers)

func _art_sprite(view: SubViewport, node_name: String, draw_layer: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = view.get_texture()
	sprite.position = Vector2(LENGTH_PX / 2.0, 0)
	sprite.z_index = draw_layer
	add_child(sprite)

func _build_art() -> void:
	far_view = _viewport("FarRender")
	far_view.world_3d = World3D.new()
	var stage := Node3D.new()
	stage.name = "DeckStage"
	far_view.add_child(stage)
	var packed_model := load(MODEL_PATH) as PackedScene
	if packed_model == null:
		push_error("Blue deck module model missing: " + MODEL_PATH)
		return
	var model := packed_model.instantiate() as Node3D
	model.name = "DeckModel"
	stage.add_child(model)
	_layer_meshes(model, 1)
	for trim in model.find_children("Foreground_Trim", "", true, false):
		_layer_meshes(trim, 2)
	var world_environment := WorldEnvironment.new()
	world_environment.name = "DeckEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.61, 0.73, 0.81)
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ssao_enabled = true
	environment.ssao_radius = 0.65
	environment.ssao_intensity = 1.40
	environment.ssao_power = 1.15
	environment.ssao_detail = 0.60
	world_environment.environment = environment
	stage.add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "WarmMorningLight"
	sun.layers = 3
	sun.rotation_degrees = Vector3(-35, -25, 0)
	sun.light_color = Color(1.0, 0.86, 0.68)
	sun.light_energy = 1.20
	sun.shadow_enabled = true
	stage.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.name = "SkyFill"
	fill.layers = 3
	fill.rotation_degrees = Vector3(-25, 150, 0)
	fill.light_color = Color(0.65, 0.79, 1.0)
	fill.light_energy = 0.25
	stage.add_child(fill)
	var near_fill := DirectionalLight3D.new()
	near_fill.name = "WarmReflectedLightOnTimber"
	near_fill.layers = 3
	near_fill.rotation_degrees = Vector3(-12, 0, 0)
	near_fill.light_color = Color(1.0, 0.88, 0.72)
	near_fill.light_energy = 0.18
	near_fill.light_cull_mask = 2
	stage.add_child(near_fill)
	_camera(far_view, 1)
	_art_sprite(far_view, "FarArtwork", -10)
	near_view = _viewport("NearRender")
	near_view.world_3d = far_view.world_3d
	_camera(near_view, 2)
	_art_sprite(near_view, "NearArtwork", 20)
