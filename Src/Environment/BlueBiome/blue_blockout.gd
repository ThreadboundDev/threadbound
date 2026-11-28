extends Node2D
## Blue playtest room.

@onready var player: CharacterBody2D = $Player
@onready var spawn: Marker2D = $Spawn
@onready var follow_camera: Camera2D = $Player/Camera2D
@onready var terrain_ink: Sprite2D = $Geometry/TerrainInk
@onready var terrain_fill: Sprite2D = $Geometry/PaintedMaterials
@onready var east_house: Sprite2D = $Geometry/EastTerraceHouse

var _terrain_mask_material: ShaderMaterial
var _terrain_mask_state := Vector3i.ZERO


func _ready() -> void:
	$HUD.visible = true
	return_to_spawn()
	# The live player queues its composite as a deferred child.
	_configure_terrain_masks.call_deferred()


func _configure_terrain_masks() -> void:
	var composite := player.get_node_or_null("Live3DComposite") as Sprite2D
	if composite == null:
		return
	_terrain_mask_material = composite.material as ShaderMaterial
	if _terrain_mask_material == null:
		return
	_bind_terrain_mask(terrain_ink, &"terrain_ink", "ink_uv_")
	_bind_terrain_mask(terrain_fill, &"terrain_fill", "fill_uv_")


func _bind_terrain_mask(sprite: Sprite2D, sampler: StringName, uv_prefix: String) -> void:
	if sprite.texture == null:
		return
	var bounds := sprite.get_rect()
	var inverse := sprite.global_transform.affine_inverse()
	_terrain_mask_material.set_shader_parameter(sampler, sprite.texture)
	_terrain_mask_material.set_shader_parameter(uv_prefix + "x", inverse.x / bounds.size)
	_terrain_mask_material.set_shader_parameter(uv_prefix + "y", inverse.y / bounds.size)
	_terrain_mask_material.set_shader_parameter(uv_prefix + "origin", (inverse.origin - bounds.position) / bounds.size)


func _process(_delta: float) -> void:
	if _terrain_mask_material == null:
		return
	var swimming: bool = player.is_in_prototype_water()
	var has_ink := terrain_ink.texture != null and terrain_ink.is_visible_in_tree()
	var has_fill := terrain_fill.texture != null and terrain_fill.is_visible_in_tree()
	var state := Vector3i(int(not swimming and has_ink and player.is_on_floor()),
		int(swimming and has_ink), int(swimming and has_fill))
	if state != _terrain_mask_state:
		_terrain_mask_state = state
		_terrain_mask_material.set_shader_parameter(&"clip_ground_ink", state.x != 0)
		_terrain_mask_material.set_shader_parameter(&"clip_swim_ink", state.y != 0)
		_terrain_mask_material.set_shader_parameter(&"clip_swim_terrain", state.z != 0)


func _physics_process(_delta: float) -> void:
	if player.global_position.y > spawn.global_position.y + 3200.0:
		return_to_spawn()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		return_to_spawn()
		get_viewport().set_input_as_handled()


func has_wet_footing(point: Vector2) -> bool:
	return $Atmosphere.rain_amount > 0.18 and $Atmosphere.is_exposed(point, true)


func return_to_spawn() -> void:
	east_house.reset_entry()
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
	follow_camera.reset_smoothing()
