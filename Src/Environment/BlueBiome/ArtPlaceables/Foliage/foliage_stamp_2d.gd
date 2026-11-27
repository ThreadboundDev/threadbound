@tool
extends MeshInstance2D
## A movable foliage clump whose pivot is planted at the bottom of the texture.

const MESH_BUILDER := preload("res://Src/Environment/BlueBiome/ArtPlaceables/Foliage/grass_patch_2d.gd")
const WIND_SHADER := preload("res://Src/Environment/BlueBiome/ArtPlaceables/Foliage/foliage_stamp.gdshader")
const CONTACT_RADIUS := 84.0
const CONTACT_HEIGHT := 58.0

static var _meshes: Dictionary[Vector2, ArrayMesh] = {}
static var _wind_material: ShaderMaterial

@export var stamp_size := Vector2(100, 44):
	set(value):
		stamp_size = value.max(Vector2.ONE)
		if is_node_ready():
			_update_mesh()

@export var flip_horizontal := false:
	set(value):
		flip_horizontal = value
		if is_node_ready():
			set_instance_shader_parameter(&"flip_horizontal", value)

var _player: CharacterBody2D
var _feet: CollisionShape2D
var _bend := 0.0


func _enter_tree() -> void:
	if _wind_material == null:
		_wind_material = ShaderMaterial.new()
		_wind_material.shader = WIND_SHADER
	var layer := get_parent() as CanvasItem
	var layer_material := layer.material as ShaderMaterial if layer else null
	material = layer_material if layer_material and layer_material.shader == WIND_SHADER else _wind_material


func _ready() -> void:
	_update_mesh()
	set_instance_shader_parameter(&"flip_horizontal", flip_horizontal)
	set_physics_process(not Engine.is_editor_hint())


func _validate_property(property: Dictionary) -> void:
	if property.name in [&"mesh", &"material", &"instance_shader_parameters/flip_horizontal",
			&"instance_shader_parameters/contact_bend", &"instance_shader_parameters/stamp_width",
			&"instance_shader_parameters/stamp_height"]:
		property.usage &= ~(PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR)


func _update_mesh() -> void:
	if not _meshes.has(stamp_size):
		_meshes[stamp_size] = MESH_BUILDER.make_mesh(stamp_size)
	mesh = _meshes[stamp_size]
	set_instance_shader_parameter(&"stamp_width", stamp_size.x)
	set_instance_shader_parameter(&"stamp_height", stamp_size.y)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as CharacterBody2D
		_feet = _player.get_node_or_null("CollisionShape2D") as CollisionShape2D if _player else null
	if not is_instance_valid(_feet):
		return
	var foot_position := _feet.global_position
	var capsule := _feet.shape as CapsuleShape2D
	if capsule:
		foot_position.y += capsule.height * _feet.global_scale.y * 0.5
	var distance := (foot_position - global_position).abs()
	if _bend == 0.0 and (distance.x >= CONTACT_RADIUS or distance.y >= CONTACT_HEIGHT):
		return
	var horizontal := 1.0 - smoothstep(16.0, CONTACT_RADIUS, distance.x)
	var vertical := 1.0 - smoothstep(18.0, CONTACT_HEIGHT, distance.y)
	var direction := clampf(_player.velocity.x / 420.0, -1.0, 1.0)
	var target := direction * horizontal * vertical
	var damping := 14.0 if absf(target) > absf(_bend) else 6.5
	var bend := lerpf(_bend, target, 1.0 - exp(-damping * delta))
	if absf(bend) < 0.002:
		bend = 0.0
	if bend != _bend:
		_bend = bend
		set_instance_shader_parameter(&"contact_bend", _bend)
