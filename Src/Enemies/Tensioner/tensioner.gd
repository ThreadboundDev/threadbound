class_name Tensioner
extends EnemyBase

@export var walk_texture: Texture2D
@export var attack_texture: Texture2D
@export var walk_columns := 6
@export var walk_rows := 4
@export var walk_frame_count := 24
@export var walk_fps := 8.0
@export var chase_fps_multiplier := 1.35
@export var attack_columns := 5
@export var attack_rows := 8
@export var attack_frame_count := 36
@export var walk_visual_offset := Vector2.ZERO
@export var attack_visual_offset := Vector2(5.0, 0.0)
@export var thread_missile_scene: PackedScene
@export var thread_smash_min_missile_count := 2
@export var thread_smash_max_missile_count := 4
@export var thread_smash_horizontal_spread := 360.0
@export var thread_smash_spawn_offset := Vector2(0.0, -12.0)
@export var thread_smash_min_launch_speed := 650.0
@export var thread_smash_max_launch_speed := 800.0
@export var thread_smash_horizontal_force := 240.0
@export var thread_smash_velocity_jitter := 45.0

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D

var _animation_timer := 0.0
var _current_frame := 0
var _playing_attack := false
var _base_sprite_scale := Vector2.ONE
var _base_sprite_position := Vector2.ZERO
var _base_cell_size := Vector2.ONE
var _thread_smash_spawned := false

func _ready() -> void:
	super._ready()
	add_to_group("tensioners")

	if visuals.has_node("Body"):
		visuals.get_node("Body").visible = false

	if sprite:
		_base_sprite_scale = sprite.scale
		_base_sprite_position = sprite.position
		if walk_texture:
			_base_cell_size = _get_sheet_cell_size(walk_texture, walk_columns, walk_rows)
		_play_walk_animation()

func _process(delta: float) -> void:
	_update_sprite_animation(delta)

func begin_attack() -> void:
	super.begin_attack()
	_thread_smash_spawned = false
	if sprite and attack_texture:
		_play_attack_animation()

func activate_attack_hitbox() -> void:
	super.activate_attack_hitbox()
	if not _thread_smash_spawned:
		_thread_smash_spawned = true
		_spawn_thread_smash_missiles()

func end_attack() -> void:
	super.end_attack()
	if sprite and walk_texture:
		_play_walk_animation()

func _play_walk_animation() -> void:
	_playing_attack = false
	_animation_timer = 0.0
	_current_frame = 0
	_configure_sprite_sheet(walk_texture, walk_columns, walk_rows)
	if sprite:
		sprite.position = _base_sprite_position + walk_visual_offset

func _play_attack_animation() -> void:
	_playing_attack = true
	_animation_timer = 0.0
	_current_frame = 0
	_configure_sprite_sheet(attack_texture, attack_columns, attack_rows)
	if sprite:
		sprite.position = _base_sprite_position + attack_visual_offset

func _configure_sprite_sheet(texture: Texture2D, columns: int, rows: int) -> void:
	if not sprite or not texture:
		return

	sprite.texture = texture
	sprite.hframes = max(1, columns)
	sprite.vframes = max(1, rows)
	sprite.frame = 0
	sprite.scale = _get_scale_for_sheet(texture, sprite.hframes, sprite.vframes)

func _get_sheet_cell_size(texture: Texture2D, columns: int, rows: int) -> Vector2:
	if not texture:
		return Vector2.ONE

	return Vector2(
		float(texture.get_width()) / float(max(1, columns)),
		float(texture.get_height()) / float(max(1, rows))
	)

func _get_scale_for_sheet(texture: Texture2D, columns: int, rows: int) -> Vector2:
	var cell_size := _get_sheet_cell_size(texture, columns, rows)
	if cell_size.x <= 0.0 or cell_size.y <= 0.0:
		return _base_sprite_scale

	return Vector2(
		_base_sprite_scale.x * (_base_cell_size.x / cell_size.x),
		_base_sprite_scale.y * (_base_cell_size.y / cell_size.y)
	)

func _update_sprite_animation(delta: float) -> void:
	if not sprite:
		return

	var frame_count := attack_frame_count if _playing_attack else walk_frame_count
	frame_count = clampi(frame_count, 1, max(1, sprite.hframes * sprite.vframes))

	var fps := _get_attack_fps() if _playing_attack else _get_walk_fps()
	if fps <= 0.0:
		return

	_animation_timer += delta
	var next_frame := int(floor(_animation_timer * fps))
	if _playing_attack:
		_current_frame = mini(next_frame, frame_count - 1)
	else:
		_current_frame = next_frame % frame_count

	sprite.frame = _current_frame

func _get_walk_fps() -> float:
	if state_machine and state_machine.current_state_name == &"Chase":
		return walk_fps * chase_fps_multiplier
	return walk_fps

func _get_attack_fps() -> float:
	if not stats:
		return 24.0

	var attack_duration := stats.attack_windup + stats.attack_active_time + stats.attack_recovery
	if attack_duration <= 0.0:
		return 24.0

	return float(max(1, attack_frame_count)) / attack_duration

func _spawn_thread_smash_missiles() -> void:
	if not thread_missile_scene:
		return

	var parent := get_parent()
	if not parent:
		parent = self

	var missile_count := randi_range(thread_smash_min_missile_count, thread_smash_max_missile_count)
	var half_spread := thread_smash_horizontal_spread * 0.5
	for index in range(missile_count):
		var missile := thread_missile_scene.instantiate() as ThreadMissile
		if not missile:
			continue

		var ratio: float = 0.5
		if missile_count > 1:
			ratio = float(index) / float(missile_count - 1)
		var lane_offset: float = lerpf(-half_spread, half_spread, ratio) + randf_range(-24.0, 24.0)

		parent.add_child(missile)
		missile.global_position = global_position + thread_smash_spawn_offset + Vector2(lane_offset * 0.25, 0.0)

		var outward_direction: float = sign(lane_offset)
		if outward_direction == 0.0:
			outward_direction = float(facing)
		var launch_x: float = outward_direction * thread_smash_horizontal_force + randf_range(-thread_smash_velocity_jitter, thread_smash_velocity_jitter)
		var launch_y: float = -randf_range(thread_smash_min_launch_speed, thread_smash_max_launch_speed)
		missile.launch(Vector2(launch_x, launch_y), self)
