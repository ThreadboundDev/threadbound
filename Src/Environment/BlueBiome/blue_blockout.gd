extends Node2D
## Blue playtest room.

@onready var player: CharacterBody2D = $Player
@onready var spawn: Marker2D = $Spawn
@onready var follow_camera: Camera2D = $Player/Camera2D
@onready var terrain_ink: Sprite2D = $Geometry/TerrainInk
@onready var east_house: Sprite2D = $Geometry/EastTerraceHouse

var _foot_ink_material: ShaderMaterial
var _foot_ink_enabled := false


func _ready() -> void:
	$HUD.visible = true
	return_to_spawn()
	# The live player queues its composite as a deferred child.
	_configure_foot_ink.call_deferred()


func _configure_foot_ink() -> void:
	var composite := player.get_node_or_null("Live3DComposite") as Sprite2D
	if composite == null or terrain_ink.texture == null:
		return
	_foot_ink_material = composite.material as ShaderMaterial
	if _foot_ink_material == null:
		return
	var bounds := terrain_ink.get_rect()
	var inverse := terrain_ink.global_transform.affine_inverse()
	_foot_ink_material.set_shader_parameter(&"terrain_ink", terrain_ink.texture)
	_foot_ink_material.set_shader_parameter(&"ink_uv_x", inverse.x / bounds.size)
	_foot_ink_material.set_shader_parameter(&"ink_uv_y", inverse.y / bounds.size)
	_foot_ink_material.set_shader_parameter(&"ink_uv_origin", (inverse.origin - bounds.position) / bounds.size)


func _process(_delta: float) -> void:
	if _foot_ink_material == null:
		return
	var enabled: bool = player.is_on_floor() and not player.is_in_prototype_water() and terrain_ink.is_visible_in_tree()
	if enabled != _foot_ink_enabled:
		_foot_ink_enabled = enabled
		_foot_ink_material.set_shader_parameter(&"clip_ground_ink", enabled)


func _physics_process(_delta: float) -> void:
	if player.global_position.y > spawn.global_position.y + 3200.0:
		return_to_spawn()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		return_to_spawn()
		get_viewport().set_input_as_handled()


func return_to_spawn() -> void:
	east_house.reset_entry()
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
	follow_camera.reset_smoothing()
