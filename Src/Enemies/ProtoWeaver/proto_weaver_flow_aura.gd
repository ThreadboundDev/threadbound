extends Node2D
class_name ProtoWeaverFlowAura

const AURA_SHADER: Shader = preload(
	"res://Src/Enemies/ProtoWeaver/proto_weaver_flow_aura.gdshader"
)
const LIGHT_TEXTURE: Texture2D = preload(
	"res://Src/Environment/World/lighting/player_light.png"
)

const POWER_RED := Color(0.94, 0.2, 0.17, 1.0)
const BALANCE_BLUE := Color(0.035, 0.30, 1.0, 1.0)
const ESSENCE_YELLOW := Color(1.0, 0.79, 0.2, 1.0)
const IVORY := Color(1.0, 0.965, 0.82, 1.0)

@export var source_sprite_path := NodePath("../Sprite2D")
@export var fade_in_speed := 9.0
@export var fade_out_speed := 7.0
@export var pulse_speed := 3.4
@export var outline_distance_px := 21.0
@export var outline_feather_px := 9.0
@export var flame_height_px := 27.0
@export var jaggedness_px := 6.5
@export var background_light_scale := 3.8

var _source_sprite: Sprite2D
var _silhouette_shell: Sprite2D
var _background_light: PointLight2D
var _material: ShaderMaterial
var _target_visibility := 0.0
var _visibility := 0.0
var _time := 0.0


func _ready() -> void:
	z_index = -2
	_source_sprite = get_node_or_null(source_sprite_path) as Sprite2D
	_create_visuals()
	visible = false
	set_process(false)


func show_power() -> void:
	show_channels([POWER_RED])


func show_balance() -> void:
	show_channels([BALANCE_BLUE])


func show_essence() -> void:
	show_channels([ESSENCE_YELLOW])


func show_all_channels() -> void:
	show_channels([POWER_RED, BALANCE_BLUE, ESSENCE_YELLOW])


func show_channels(channels: Array[Color]) -> void:
	_apply_channels(channels)
	_target_visibility = 1.0
	visible = true
	set_process(true)


func hide_aura(immediate := false) -> void:
	_target_visibility = 0.0
	if immediate:
		_visibility = 0.0
		_update_visuals()
		visible = false
		set_process(false)


func _process(delta: float) -> void:
	_time += delta
	_sync_source_sprite()
	var fade_speed := fade_in_speed if _target_visibility > _visibility else fade_out_speed
	_visibility = move_toward(_visibility, _target_visibility, fade_speed * delta)
	_update_visuals()
	if _target_visibility <= 0.0 and _visibility <= 0.001:
		visible = false
		set_process(false)


func _create_visuals() -> void:
	_silhouette_shell = Sprite2D.new()
	_silhouette_shell.name = "SilhouetteShell"
	_silhouette_shell.z_index = -1
	add_child(_silhouette_shell)

	_material = ShaderMaterial.new()
	_material.shader = AURA_SHADER
	_material.set_shader_parameter(&"ivory_color", IVORY)
	_silhouette_shell.material = _material

	_background_light = PointLight2D.new()
	_background_light.name = "BackgroundAura"
	_background_light.texture = LIGHT_TEXTURE
	_background_light.texture_scale = background_light_scale
	_background_light.energy = 0.0
	_background_light.range_z_min = -4096
	_background_light.range_z_max = 4096
	add_child(_background_light)
	_apply_channels([POWER_RED])


func _sync_source_sprite() -> void:
	if not is_instance_valid(_source_sprite):
		_source_sprite = get_node_or_null(source_sprite_path) as Sprite2D
	if not is_instance_valid(_source_sprite) or not _source_sprite.texture:
		_silhouette_shell.visible = false
		return

	_silhouette_shell.texture = _source_sprite.texture
	_silhouette_shell.hframes = _source_sprite.hframes
	_silhouette_shell.vframes = _source_sprite.vframes
	_silhouette_shell.frame = _source_sprite.frame
	_silhouette_shell.position = _source_sprite.position
	_silhouette_shell.rotation = _source_sprite.rotation
	_silhouette_shell.scale = _source_sprite.scale
	_silhouette_shell.offset = _source_sprite.offset
	_silhouette_shell.centered = _source_sprite.centered
	_silhouette_shell.flip_h = _source_sprite.flip_h
	_silhouette_shell.flip_v = _source_sprite.flip_v
	_background_light.position = _source_sprite.position

	var texture_size := Vector2(_source_sprite.texture.get_size())
	var columns := maxi(1, _source_sprite.hframes)
	var rows := maxi(1, _source_sprite.vframes)
	var cell_size := texture_size / Vector2(columns, rows)
	var frame_index := clampi(_source_sprite.frame, 0, columns * rows - 1)
	var frame_column := frame_index % columns
	var frame_row := frame_index / columns
	var source_uv_rect := Rect2(
		(Vector2(frame_column, frame_row) * cell_size + Vector2(0.5, 0.5)) / texture_size,
		(cell_size - Vector2.ONE) / texture_size
	)
	_material.set_shader_parameter(&"silhouette_texture", _source_sprite.texture)
	_material.set_shader_parameter(&"source_texture_size", cell_size)
	_material.set_shader_parameter(
		&"source_uv_rect",
		Color(
			source_uv_rect.position.x,
			source_uv_rect.position.y,
			source_uv_rect.size.x,
			source_uv_rect.size.y
		)
	)


func _apply_channels(channels: Array[Color]) -> void:
	var colors: Array[Color] = [POWER_RED, POWER_RED, POWER_RED]
	var weights := Vector3.ZERO
	for index in mini(channels.size(), 3):
		colors[index] = channels[index]
		match index:
			0:
				weights.x = 1.0
			1:
				weights.y = 1.0
			2:
				weights.z = 1.0
	if weights.length_squared() <= 0.001:
		weights.x = 1.0
	_material.set_shader_parameter(&"channel_1", colors[0])
	_material.set_shader_parameter(&"channel_2", colors[1])
	_material.set_shader_parameter(&"channel_3", colors[2])
	_material.set_shader_parameter(&"channel_weights", weights)
	var ivory_mix_strength := 0.72
	if channels.size() == 1 and channels[0].is_equal_approx(BALANCE_BLUE):
		ivory_mix_strength = 0.30
	_material.set_shader_parameter(&"ivory_mix_strength", ivory_mix_strength)
	var light_color := colors[0]
	if channels.size() > 1:
		light_color = Color(0.78, 0.7, 0.74, 1.0)
	_background_light.color = light_color


func _update_visuals() -> void:
	if not _material:
		return
	var pulse := 0.5 + sin(_time * pulse_speed) * 0.5
	_silhouette_shell.visible = _visibility > 0.001 and _silhouette_shell.texture != null
	_material.set_shader_parameter(&"time_seconds", _time)
	_material.set_shader_parameter(&"aura_visibility", _visibility)
	_material.set_shader_parameter(&"outline_distance_px", outline_distance_px)
	_material.set_shader_parameter(&"outline_feather_px", outline_feather_px)
	_material.set_shader_parameter(&"flame_height_px", flame_height_px)
	_material.set_shader_parameter(&"jaggedness_px", jaggedness_px)
	_material.set_shader_parameter(&"energy", 1.3 + pulse * 0.48)
	_background_light.energy = _visibility * (0.6 + pulse * 0.22)
	_background_light.texture_scale = background_light_scale + pulse * 0.24
