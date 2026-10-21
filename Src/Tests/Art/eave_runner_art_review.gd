extends Node3D
## F6 art review: imported geometry, actual skeletal clips and two camera views.

const MODEL := preload("res://Src/Enemies/EaveRunner/eave_runner_model_3d.tscn")
const CLIPS: Array[StringName] = [&"idle", &"run", &"wall_attach", &"wall_perch", &"wall_windup", &"wall_launch", &"jump_slash", &"land_recover", &"throw_windup", &"throw_release", &"hurt", &"death"]
var model: Node3D
var camera: Camera3D
var wall: MeshInstance3D
var selector: OptionButton
var cycle := false
var cycle_left := 0.0
var selected := 0
var view_side := false

func _ready() -> void:
	model = MODEL.instantiate()
	add_child(model)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.065, 0.085, 0.105)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.55, 0.67, 0.79)
	environment.environment.ambient_light_energy = 0.45
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	for spec in [[Vector3(-2, 4, 3), Color(1, 0.88, 0.72), 1.1], [Vector3(3, 2, -2), Color(0.56, 0.75, 1), 0.85]]:
		var light := DirectionalLight3D.new()
		add_child(light)
		light.position = spec[0]
		light.light_color = spec[1]
		light.light_energy = spec[2]
		light.shadow_enabled = true
		light.look_at(Vector3(0, 1, 0))
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.01
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.17, 0.19, 0.21)
	floor_material.roughness = 0.9
	floor_mesh.material_override = floor_material
	add_child(floor_mesh)
	wall = MeshInstance3D.new()
	var wall_box := BoxMesh.new()
	wall_box.size = Vector3(1.25, 2.4, 0.06)
	wall.mesh = wall_box
	wall.position = Vector3(0, 1.2, -0.435)
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.16, 0.11, 0.07)
	wall_material.roughness = 0.86
	wall.material_override = wall_material
	add_child(wall)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.5
	camera.current = true
	add_child(camera)
	_update_camera()
	_make_controls()
	get_viewport().msaa_3d = Viewport.MSAA_4X
	play(0)

func _make_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(22, 22)
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 14)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = "WOVEN EAVE RUNNER / ART REVIEW"
	heading.add_theme_font_size_override("font_size", 22)
	box.add_child(heading)
	var note := Label.new()
	note.text = "Imported mesh + twelve skeletal clips\n60 bones; short cloth tails; packed Blender source"
	box.add_child(note)
	selector = OptionButton.new()
	for clip in CLIPS:
		selector.add_item(String(clip).replace("_", " ").capitalize())
	selector.item_selected.connect(play)
	box.add_child(selector)
	var restart := Button.new()
	restart.text = "Replay clip"
	restart.pressed.connect(func(): play(selected))
	box.add_child(restart)
	var cycle_button := CheckButton.new()
	cycle_button.text = "Cycle all clips"
	cycle_button.toggled.connect(func(enabled: bool): cycle = enabled)
	box.add_child(cycle_button)
	var side := CheckButton.new()
	side.text = "Gameplay side view"
	side.toggled.connect(func(enabled: bool): view_side = enabled; _update_camera())
	box.add_child(side)

func _update_camera() -> void:
	camera.position = Vector3(5, 1.12, 0) if view_side else Vector3(2.6, 2.2, 5.8)
	camera.look_at(Vector3(0, 0.94, 0))

func play(index: int) -> void:
	selected = index
	if selector:
		selector.select(index)
	model.play_clip(CLIPS[index], 0, 0)
	model.animator.seek(0.0, true)
	wall.visible = String(CLIPS[index]).begins_with("wall_")
	cycle_left = maxf(1.0, model.animator.current_animation_length + 0.4)

func _process(delta: float) -> void:
	if not cycle:
		return
	cycle_left -= delta
	if cycle_left <= 0:
		play((selected + 1) % CLIPS.size())
