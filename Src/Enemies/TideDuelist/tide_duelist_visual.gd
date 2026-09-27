@tool
extends Node2D
## A live 3D fish in the 2D world, including a static editor preview.

const MODEL = preload("res://Assets/BlueBiome/Enemies/Models/TideDuelist_Rigged_v2.glb")
var animator: AnimationPlayer
var eye_materials: Array[StandardMaterial3D] = []
var tell_intensity := 0.0

func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.name = "FishRender"
	viewport.size = Vector2i(512, 320)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var model := MODEL.instantiate()
	viewport.add_child(model)
	animator = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	animator.get_animation(&"still").loop_mode = Animation.LOOP_LINEAR
	for node in model.find_children("EyeTell*", "MeshInstance3D", true, false):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		node.material_override = material
		eye_materials.append(material)
	set_attack_tell(0.0)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.3
	camera.position = Vector3(0, -0.2, 8)
	viewport.add_child(camera)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.TRANSPARENT
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.65, 0.8, 1.0)
	environment.environment.ambient_light_energy = 0.65
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_energy = 1.25
	viewport.add_child(light)
	var sprite := Sprite2D.new()
	sprite.name = "FishImage"
	sprite.texture = viewport.get_texture()
	sprite.scale = Vector2.ONE * 0.44
	add_child(sprite)
	play_clip(&"still")
	if Engine.is_editor_hint():
		animator.seek(0.0, true)
		animator.pause()

func play_clip(clip: StringName, duration := 0.0) -> void:
	if not animator or not animator.has_animation(clip):
		return
	var speed := animator.get_animation(clip).length / duration if duration > 0.0 else 1.0
	animator.play(clip, 0.04, speed)

func set_attack_tell(intensity: float) -> void:
	tell_intensity = clampf(intensity, 0.0, 1.0)
	# Amber awareness becomes an ivory-hot flash for the final held draw pose.
	var color := Color(0.28, 0.23, 0.15).lerp(Color(1.0, 0.35, 0.04), minf(tell_intensity * 2.0, 1.0))
	if tell_intensity > 0.8:
		color = color.lerp(Color(1.0, 0.94, 0.68), (tell_intensity - 0.8) / 0.2)
	for material in eye_materials:
		material.albedo_color = color
		material.emission = color
		material.emission_energy_multiplier = 0.1 + tell_intensity * 3.0
