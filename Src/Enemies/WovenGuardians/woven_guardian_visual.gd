@tool
extends Node2D
## Live skinned 3D art on the existing 2D enemy body, at 96 game pixels per metre.
@export var model_scene: PackedScene
@export var camera_height := 1.15
@export var camera_span := 4.0
@export var model_yaw := 72.0
@export var starting_clip: StringName = &"idle"
@export_range(768, 2048, 128) var render_resolution := 1536
var animator: AnimationPlayer
var actor: Node3D
var image: Sprite2D
var tell := 0.0
var _view: SubViewport
var _camera: Camera3D
var _skeleton: Skeleton3D
var _charge_materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	if not model_scene:
		return
	_view = SubViewport.new()
	_view.name = "GuardianRender"
	_view.size = Vector2i(render_resolution, render_resolution)
	_view.own_world_3d = true
	_view.transparent_bg = true
	_view.msaa_3d = Viewport.MSAA_4X
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	actor = model_scene.instantiate()
	actor.rotation_degrees.y = model_yaw
	_view.add_child(actor)
	for mesh_node: MeshInstance3D in actor.find_children("*", "MeshInstance3D", true, false):
		mesh_node.lod_bias = 8.0
		for index in mesh_node.mesh.get_surface_count():
			var material := mesh_node.get_active_material(index) as StandardMaterial3D
			if material:
				material = material.duplicate()
				material.cull_mode = BaseMaterial3D.CULL_DISABLED
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				mesh_node.set_surface_override_material(index, material)
				if material.resource_name.contains("charged thread"):
					_charge_materials.append(material)
	for skeleton in actor.find_children("*", "Skeleton3D", true, false):
		_skeleton = skeleton as Skeleton3D
		break
	var players := actor.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		animator = players[0] as AnimationPlayer
		for clip in animator.get_animation_list():
			animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if clip in ["idle", "run", "flight", "perch", "wall_perch"] else Animation.LOOP_NONE
	var camera := Camera3D.new()
	_camera = camera
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = camera_span
	camera.position = Vector3(0, camera_height, 8)
	_view.add_child(camera)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.TRANSPARENT
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.74, 0.84, 1.0)
	environment.environment.ambient_light_energy = 0.75
	_view.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_energy = 1.45
	_view.add_child(light)
	image = Sprite2D.new()
	image.name = "GuardianImage"
	image.texture = _view.get_texture()
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.scale = Vector2.ONE * camera_span * 96.0 / float(render_resolution)
	image.position.y = -camera_height * 96.0
	add_child(image)
	play_clip(starting_clip)
	if Engine.is_editor_hint() and animator:
		animator.seek(0, true)
		animator.pause()

func _process(_delta: float) -> void:
	if _view and not Engine.is_editor_hint():
		_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() and image and image.get_global_transform_with_canvas().origin.distance_to(get_viewport_rect().get_center()) < 1600 else SubViewport.UPDATE_DISABLED

func play_clip(clip: StringName, duration := 0.0) -> void:
	if not animator or not animator.has_animation(clip):
		return
	var speed := animator.get_animation(clip).length / duration if duration > 0 else 1.0
	animator.play(clip, 0.06, speed)

func set_tell(value: float) -> void:
	tell = value
	for material in _charge_materials:
		material.emission_energy_multiplier = .15 + value * value * 4.0
	queue_redraw()

func bone_world_position(bone: StringName) -> Variant:
	if not _skeleton or not _camera or not image:
		return null
	var index := _skeleton.find_bone(bone)
	if index < 0:
		return null
	var point := _skeleton.to_global(_skeleton.get_bone_global_pose(index).origin)
	var pixel := _camera.unproject_position(point) - Vector2(_view.size) * .5
	return image.to_global(pixel)

func _draw() -> void:
	if tell > 0.0:
		var center := Vector2(0, -105)
		draw_arc(center, 32 + tell * 12, 0, TAU * tell, 28, Color(0.3, 0.83, 1.0, .75), 2.0, true)
		draw_line(center + Vector2(30, 0), center + Vector2(49, 0), Color(0.6, .9, 1.0, tell), 2.0, true)
