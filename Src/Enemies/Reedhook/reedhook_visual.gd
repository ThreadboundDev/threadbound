@tool
extends Node2D
## A live 3D Reedhook in the 2D world, including a static editor preview.

const MODEL = preload("res://Assets/BlueBiome/Enemies/Models/Reedhook_animated.glb")
var animator: AnimationPlayer

func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.name = "ReedhookRender"
	viewport.size = Vector2i(512, 384)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var model := MODEL.instantiate()
	viewport.add_child(model)
	animator = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	animator.get_animation(&"idle").loop_mode = Animation.LOOP_LINEAR
	animator.get_animation(&"walk").loop_mode = Animation.LOOP_LINEAR
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.3
	camera.position = Vector3(0.3, 1.4, 8)
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
	sprite.name = "ReedhookImage"
	sprite.texture = viewport.get_texture()
	sprite.scale = Vector2.ONE * 0.56
	sprite.position = Vector2(19.55, -91.23)
	add_child(sprite)
	play_clip(&"idle")
	if Engine.is_editor_hint():
		animator.seek(0.0, true)
		animator.pause()

func play_clip(clip: StringName, duration := 0.0) -> void:
	if not animator or not animator.has_animation(clip):
		return
	var speed := animator.get_animation(clip).length / duration if duration > 0.0 else 1.0
	animator.play(clip, 0.04, speed)


