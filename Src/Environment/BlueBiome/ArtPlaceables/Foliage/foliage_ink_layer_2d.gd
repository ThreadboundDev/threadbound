@tool
extends Node2D
## Clips this layer's foliage stamps against a painted ink sprite.

const WIND_SHADER := preload("res://Src/Environment/BlueBiome/ArtPlaceables/Foliage/foliage_stamp.gdshader")

@export var terrain_ink: Sprite2D

var _mask_material: ShaderMaterial
var _mask_texture: Texture2D
var _mask_uv := Transform2D.IDENTITY


func _enter_tree() -> void:
	if _mask_material == null:
		_mask_material = ShaderMaterial.new()
		_mask_material.shader = WIND_SHADER
		material = _mask_material
	_process(0.0)


func _validate_property(property: Dictionary) -> void:
	if property.name == &"material":
		property.usage &= ~(PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR)


func _process(_delta: float) -> void:
	var texture: Texture2D
	if is_instance_valid(terrain_ink) and terrain_ink.is_visible_in_tree() \
			and not is_zero_approx(terrain_ink.global_transform.determinant()):
		texture = terrain_ink.texture
	if texture != _mask_texture:
		_mask_texture = texture
		_mask_material.set_shader_parameter(&"terrain_ink", texture)
		_mask_material.set_shader_parameter(&"clip_terrain_ink", texture != null)
	if texture == null:
		return

	var bounds := terrain_ink.get_rect()
	var inverse := terrain_ink.global_transform.affine_inverse()
	var uv := Transform2D(inverse.x / bounds.size, inverse.y / bounds.size,
		(inverse.origin - bounds.position) / bounds.size)
	if uv != _mask_uv:
		_mask_uv = uv
		_mask_material.set_shader_parameter(&"ink_uv_x", uv.x)
		_mask_material.set_shader_parameter(&"ink_uv_y", uv.y)
		_mask_material.set_shader_parameter(&"ink_uv_origin", uv.origin)
