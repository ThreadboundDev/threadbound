extends Node2D
class_name FlowMultiMeshTrail

const TRAIL_SHADER := preload("res://Src/VFX/Flow/flow_multimesh_trail.gdshader")

@export_range(8, 48, 1) var capacity := 22
@export var stamp_spacing := 24.0
@export var stamp_lifetime := 0.58
@export var minimum_speed := 175.0
@export var maximum_speed := 900.0
@export_range(0.0, 1.0, 0.01) var maximum_opacity := 0.38
@export var upward_drift := 0.0
@export var fade_distance := 280.0

var _write_index := 0
var _last_stamp_position := Vector2.ZERO
var _has_last_position := false
var _enabled := false
var _trail_color := Color(0.96, 0.67, 0.24, 1.0)
var _sprites: Array[Sprite2D] = []
var _ages: Array[float] = []
var _lifetimes: Array[float] = []
var _drift: Array[Vector2] = []
var _materials: Array[ShaderMaterial] = []
var _source_visual: AnimatedSprite2D

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = -2
	_build_pool()
	set_process(false)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	for index in _sprites.size():
		var sprite := _sprites[index]
		if not sprite.visible:
			continue
		_ages[index] += delta
		var progress := clampf(_ages[index] / maxf(_lifetimes[index], 0.001), 0.0, 1.0)
		if progress >= 1.0:
			sprite.visible = false
			continue
		sprite.position += _drift[index] * delta
		var age_fade := pow(1.0 - progress, 1.35)
		var distance_fade := 1.0
		if is_instance_valid(_source_visual):
			distance_fade = 1.0 - clampf(
				sprite.global_position.distance_to(_source_visual.global_position) / maxf(fade_distance, 1.0),
				0.0,
				1.0
			)
		sprite.modulate.a = maximum_opacity * age_fade * distance_fade
		_materials[index].set_shader_parameter(&"progress", progress)

func set_trail_active(is_active: bool) -> void:
	_enabled = is_active
	if not is_active:
		_has_last_position = false

func set_trail_color(color: Color) -> void:
	_trail_color = color
	_trail_color.a = 1.0

func sample_motion(player_visual: AnimatedSprite2D, velocity: Vector2, strength: float) -> void:
	_source_visual = player_visual
	if not _enabled or not is_instance_valid(player_visual):
		_has_last_position = false
		return
	var speed := velocity.length()
	if speed < minimum_speed or speed > maximum_speed:
		_has_last_position = false
		return
	var world_position := player_visual.global_position
	if not _has_last_position:
		_last_stamp_position = world_position
		_has_last_position = true
		_emit_stamp(player_visual, velocity, strength)
		return
	var distance := _last_stamp_position.distance_to(world_position)
	if distance < stamp_spacing:
		return
	var steps := mini(int(floor(distance / stamp_spacing)), 4)
	var direction := _last_stamp_position.direction_to(world_position)
	for step in range(steps):
		_last_stamp_position += direction * stamp_spacing
		_emit_stamp(player_visual, velocity, strength, _last_stamp_position)

func _build_pool() -> void:
	for index in capacity:
		var sprite := Sprite2D.new()
		sprite.name = "BodyStamp%02d" % (index + 1)
		sprite.visible = false
		var stamp_material := ShaderMaterial.new()
		stamp_material.shader = TRAIL_SHADER
		stamp_material.set_shader_parameter(&"noise_seed", randf() * 100.0)
		sprite.material = stamp_material
		add_child(sprite)
		_sprites.append(sprite)
		_materials.append(stamp_material)
		_ages.append(stamp_lifetime)
		_lifetimes.append(stamp_lifetime)
		_drift.append(Vector2.ZERO)

func _emit_stamp(
	player_visual: AnimatedSprite2D,
	_velocity: Vector2,
	strength: float,
	position_override := Vector2.INF
) -> void:
	if player_visual.sprite_frames == null:
		return
	var frame_texture := player_visual.sprite_frames.get_frame_texture(
		player_visual.animation,
		player_visual.frame
	)
	if frame_texture == null:
		return
	var sprite := _sprites[_write_index]
	sprite.texture = frame_texture
	sprite.position = player_visual.global_position if position_override == Vector2.INF else position_override
	sprite.rotation = player_visual.global_rotation
	sprite.scale = player_visual.global_scale
	sprite.offset = player_visual.offset
	sprite.centered = player_visual.centered
	sprite.flip_h = player_visual.flip_h
	sprite.flip_v = player_visual.flip_v
	sprite.modulate = _trail_color
	sprite.modulate.a = maximum_opacity * clampf(strength, 0.45, 1.0)
	sprite.visible = true
	_ages[_write_index] = 0.0
	_lifetimes[_write_index] = stamp_lifetime * randf_range(0.9, 1.1)
	# Full-body echoes should remain registered to the sampled physics pose.
	# Atmospheric motion belongs to the surrounding motes; drifting the body
	# stamps creates a visible shimmer against a smoothing Camera2D.
	_drift[_write_index] = Vector2(0.0, -upward_drift)
	_materials[_write_index].set_shader_parameter(&"progress", 0.0)
	_materials[_write_index].set_shader_parameter(&"noise_seed", randf() * 100.0)
	_write_index = (_write_index + 1) % capacity
