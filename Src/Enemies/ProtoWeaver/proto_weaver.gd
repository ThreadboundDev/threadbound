class_name ProtoWeaver
extends EnemyBase

enum AttackMode {
	STAB,
	THREADBURST,
}

@export var walk_texture: Texture2D
@export var stab_texture: Texture2D
@export var threadburst_texture: Texture2D
@export var thread_missile_scene: PackedScene

@export var walk_columns := 6
@export var walk_rows := 8
@export var walk_frame_count := 48
@export var walk_fps := 8.0
@export var chase_fps_multiplier := 1.25

@export var attack_columns := 6
@export var attack_rows := 8
@export var attack_frame_count := 48
@export var threadburst_every_n_attacks := 3
@export var threadburst_missile_count := 5
@export var threadburst_spawn_offset := Vector2(0.0, -8.0)
@export var threadburst_horizontal_spread := 360.0
@export var threadburst_min_launch_speed := 470.0
@export var threadburst_max_launch_speed := 670.0
@export var threadburst_upward_bias := 520.0

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D

var _animation_timer := 0.0
var _current_frame := 0
var _playing_attack := false
var _current_attack_mode := AttackMode.STAB
var _attack_count := 0
var _base_sprite_scale := Vector2.ONE
var _base_cell_size := Vector2.ONE

func _ready() -> void:
	super._ready()
	add_to_group("proto_weaver")

	if visuals.has_node("Body"):
		visuals.get_node("Body").visible = false

	if sprite:
		_base_sprite_scale = sprite.scale
		if walk_texture:
			_base_cell_size = _get_sheet_cell_size(walk_texture, walk_columns, walk_rows)
		_play_walk_animation()

	update_facing(facing)

func _process(delta: float) -> void:
	_update_sprite_animation(delta)

func update_facing(direction: int) -> void:
	super.update_facing(direction)
	if visuals:
		visuals.scale.x = -abs(visuals.scale.x) * float(facing)

func begin_attack() -> void:
	_attack_count += 1
	if threadburst_every_n_attacks > 0 and _attack_count % threadburst_every_n_attacks == 0:
		_current_attack_mode = AttackMode.THREADBURST
	else:
		_current_attack_mode = AttackMode.STAB

	super.begin_attack()
	_play_attack_animation()

func end_attack() -> void:
	super.end_attack()
	if sprite and walk_texture:
		_play_walk_animation()

func activate_attack_hitbox() -> void:
	if _current_attack_mode == AttackMode.THREADBURST:
		_spawn_threadburst_missiles()
		return

	super.activate_attack_hitbox()

func deactivate_attack_hitbox() -> void:
	if _current_attack_mode == AttackMode.STAB:
		super.deactivate_attack_hitbox()

func _play_walk_animation() -> void:
	_playing_attack = false
	_animation_timer = 0.0
	_current_frame = 0
	_configure_sprite_sheet(walk_texture, walk_columns, walk_rows)

func _play_attack_animation() -> void:
	_playing_attack = true
	_animation_timer = 0.0
	_current_frame = 0
	var texture := stab_texture
	if _current_attack_mode == AttackMode.THREADBURST:
		texture = threadburst_texture
	_configure_sprite_sheet(texture, attack_columns, attack_rows)

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

func _spawn_threadburst_missiles() -> void:
	if not thread_missile_scene:
		return

	var parent := get_parent()
	if not parent:
		parent = self

	for i in range(threadburst_missile_count):
		var missile := thread_missile_scene.instantiate() as ThreadMissile
		if not missile:
			continue

		parent.add_child(missile)
		var centered_index := float(i) - float(threadburst_missile_count - 1) * 0.5
		var x_offset: float = centered_index * (threadburst_horizontal_spread / max(1.0, float(threadburst_missile_count - 1)))
		x_offset += randf_range(-28.0, 28.0)
		missile.global_position = global_position + threadburst_spawn_offset + Vector2(x_offset, 0.0)

		var launch_x: float = x_offset * 1.65 + randf_range(-80.0, 80.0)
		var launch_y: float = -randf_range(threadburst_min_launch_speed, threadburst_max_launch_speed) - threadburst_upward_bias * 0.25
		missile.launch(Vector2(launch_x, launch_y), self)
