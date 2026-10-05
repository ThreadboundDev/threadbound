@tool
extends Node2D
## Isolated 2D-controller/3D-art traversal test. No project-wide behavior changes.
const KIT_PATH := "res://Assets/BlueBiome/Prototype/Placeables/Buildings/Pavilion3D_V2/"
const MODEL := preload(KIT_PATH + "blue_pavilion.glb")
const PLAYER := preload("res://Src/Characters/Player/player.tscn")
const FOOT_OFFSET := 69.245
const PPM := 80.0
const TILT := 0.13962634016
const TARGET_HEIGHT := 6.5
const VIEW_SIZE := Vector2i(2880, 1440)

var routes: Dictionary
var player: CharacterBody2D
var geometry: Node2D
var far_view: SubViewport
var near_view: SubViewport
var near_sprite: Sprite2D
var show_surfaces := false
var status: Label
var checkpoint := 1

func point(x: float, height: float) -> Vector2:
	return Vector2(x * PPM, -height * PPM * cos(TILT))

func _ready() -> void:
	routes = JSON.parse_string(FileAccess.get_file_as_string(KIT_PATH + "routes.json")) as Dictionary
	_build_backdrop()
	_build_art()
	_build_geometry()
	var camera := Camera2D.new()
	camera.name = "PavilionCamera"
	camera.position = point(-2.8, 6.1)
	camera.zoom = Vector2(0.70, 0.70)
	add_child(camera)
	if Engine.is_editor_hint():
		return
	player = PLAYER.instantiate() as CharacterBody2D
	player.name = "Player"
	add_child(player)
	player.z_index = 0
	set_checkpoint(1)
	_build_ui()

func _build_backdrop() -> void:
	var sky := Polygon2D.new()
	sky.name = "CoastalBackdrop"
	sky.polygon = PackedVector2Array([Vector2(-3000,-2300),Vector2(3000,-2300),Vector2(3000,1800),Vector2(-3000,1800)])
	sky.color = Color("619bb0")
	sky.z_index = -50
	add_child(sky)
	var gradient := Gradient.new()
	gradient.set_color(0, Color("adc8d2"))
	gradient.set_color(1, Color("4c8292"))
	var sky_texture := GradientTexture2D.new()
	sky_texture.gradient = gradient
	sky_texture.width = 32
	sky_texture.height = 1024
	sky_texture.fill_from = Vector2(0.0, 0.0)
	sky_texture.fill_to = Vector2(0.0, 1.0)
	var soft_sky := Sprite2D.new()
	soft_sky.name = "SoftCoastalSky"
	soft_sky.texture = sky_texture
	soft_sky.scale = Vector2(6000.0 / 32.0, 4100.0 / 1024.0)
	soft_sky.position = Vector2(0.0, -250.0)
	soft_sky.z_index = -45
	add_child(soft_sky)
	var water := Polygon2D.new()
	water.name = "Waterline"
	water.polygon = PackedVector2Array([Vector2(-3000,65),Vector2(3000,65),Vector2(3000,1800),Vector2(-3000,1800)])
	water.color = Color("286473")
	water.z_index = -30
	add_child(water)

func _viewport(name_text: String) -> SubViewport:
	var vp := SubViewport.new()
	vp.name = name_text
	vp.size = VIEW_SIZE
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	return vp

func _stage_camera(vp: SubViewport, layers: int) -> void:
	var camera := Camera3D.new()
	camera.name = "SideView3DCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = float(VIEW_SIZE.y) / PPM
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.cull_mask = layers
	vp.add_child(camera)
	camera.position = Vector3(0, TARGET_HEIGHT + 30.0 * tan(TILT), 30)
	camera.look_at(Vector3(0, TARGET_HEIGHT, 0))
	camera.current = true

func _layer_meshes(node: Node, layer: int) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).layers = layer
	for child in node.get_children():
		_layer_meshes(child, layer)

func _sprite(vp: SubViewport, layer: int, name_text: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = name_text
	sprite.texture = vp.get_texture()
	sprite.position = point(0, TARGET_HEIGHT)
	sprite.z_index = layer
	add_child(sprite)
	return sprite

func _build_art() -> void:
	far_view = _viewport("Background3DRender")
	far_view.world_3d = World3D.new()
	var stage := Node3D.new()
	stage.name = "Pavilion3DStage"
	far_view.add_child(stage)
	var model := MODEL.instantiate() as Node3D
	stage.add_child(model)
	for child in model.get_children():
		var is_near: bool = str(child.name) in routes["foreground_groups"]
		_layer_meshes(child, 2 if is_near else 1)
	var world_environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("619bb0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.61,0.73,0.81)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_radius = 0.65
	env.ssao_intensity = 1.40
	env.ssao_power = 1.15
	env.ssao_detail = 0.60
	world_environment.environment = env
	stage.add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "WarmMorningLight"
	sun.layers = 3
	sun.rotation_degrees = Vector3(-35,-25,0)
	sun.light_color = Color(1.0,0.86,0.68)
	sun.light_energy = 1.20
	sun.shadow_enabled = true
	stage.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.layers = 3
	fill.rotation_degrees = Vector3(-25,150,0)
	fill.light_color = Color(0.65,0.79,1.0)
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
	_stage_camera(far_view, 1)
	_sprite(far_view, -10, "PavilionBehindPlayer")
	near_view = _viewport("Foreground3DRender")
	near_view.world_3d = far_view.world_3d
	_stage_camera(near_view, 2)
	near_sprite = _sprite(near_view, 20, "RailingsInFrontOfPlayer")

func _build_geometry() -> void:
	geometry = Node2D.new()
	geometry.name = "PavilionTraversal"
	add_child(geometry)
	for entry: Dictionary in routes["walk_surfaces"]:
		var a := point(float(entry["a"][0]), float(entry["a"][1]))
		var b := point(float(entry["b"][0]), float(entry["b"][1]))
		var thickness := float(entry["thickness"]) * PPM
		var body := StaticBody2D.new()
		body.name = str(entry["name"]).replace(" ", "_")
		body.collision_layer = 1
		body.collision_mask = 0
		geometry.add_child(body)
		var shape := CollisionPolygon2D.new()
		shape.polygon = PackedVector2Array([a,b,b+Vector2(0,thickness),a+Vector2(0,thickness)])
		shape.one_way_collision = bool(entry["one_way"])
		shape.one_way_collision_margin = 8.0
		body.add_child(shape)

func set_checkpoint(index: int) -> void:
	checkpoint = index
	var keys := ["underneath", "stairs", "deck", "roof"]
	var at: Array = routes["checkpoints"][keys[index-1]]
	player.global_position = point(float(at[0]), float(at[1])) - Vector2(0, FOOT_OFFSET + 2.0)
	player.velocity = Vector2.ZERO

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PrototypeControls"
	layer.layer = 30
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.035,0.060,0.083,0.94)
	panel.size = Vector2(1920,94)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	var title := Label.new()
	title.position = Vector2(28,14)
	title.text = "BLUE BIOME  /  OPEN PAVILION V2"
	title.add_theme_font_size_override("font_size",24)
	layer.add_child(title)
	status = Label.new()
	status.position = Vector2(28,49)
	status.text = "A / D: move   Space: jump   1: underneath   2: stairs   3: deck   4: roof   F: foreground   C: surfaces   R: reset"
	status.add_theme_font_size_override("font_size",19)
	layer.add_child(status)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).physical_keycode
	if key >= KEY_1 and key <= KEY_4:
		set_checkpoint(key - KEY_1 + 1)
	elif key == KEY_R:
		set_checkpoint(checkpoint)
	elif key == KEY_F:
		near_sprite.visible = not near_sprite.visible
	elif key == KEY_C:
		show_surfaces = not show_surfaces
		queue_redraw()

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not is_instance_valid(player):
		return
	if player.position.y > 550 or absf(player.position.x) > 1500:
		set_checkpoint(checkpoint)

func _draw() -> void:
	if not show_surfaces or routes.is_empty():
		return
	for entry: Dictionary in routes["walk_surfaces"]:
		var a := point(float(entry["a"][0]),float(entry["a"][1]))
		var b := point(float(entry["b"][0]),float(entry["b"][1]))
		draw_line(a,b,Color(0.35,1.0,0.62,0.9),3.0)
