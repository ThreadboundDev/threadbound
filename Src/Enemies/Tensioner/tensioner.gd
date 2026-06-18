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
@export var attack_frame_count := 40

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D

var _animation_timer := 0.0
var _current_frame := 0
var _playing_attack := false
var _base_sprite_scale := Vector2.ONE
var _base_cell_size := Vector2.ONE

func _ready() -> void:
	super._ready()
	add_to_group("tensioners")

	if visuals.has_node("Body"):
		visuals.get_node("Body").visible = false

	if sprite:
		_base_sprite_scale = sprite.scale
		if walk_texture:
			_base_cell_size = _get_sheet_cell_size(walk_texture, walk_columns, walk_rows)
		_play_walk_animation()

func _process(delta: float) -> void:
	_update_sprite_animation(delta)

func begin_attack() -> void:
	super.begin_attack()
	if sprite and attack_texture:
		_play_attack_animation()

func end_attack() -> void:
	super.end_attack()
	if sprite and walk_texture:
		_play_walk_animation()

func _play_walk_animation() -> void:
	_playing_attack = false
	_animation_timer = 0.0
	_current_frame = 0
	_configure_sprite_sheet(walk_texture, walk_columns, walk_rows)

func _play_attack_animation() -> void:
	_playing_attack = true
	_animation_timer = 0.0
	_current_frame = 0
	_configure_sprite_sheet(attack_texture, attack_columns, attack_rows)

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
