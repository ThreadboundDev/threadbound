class_name Threadling
extends EnemyBase

@export var hover_offset := -36.0
@export var bob_amplitude := 18.0
@export var bob_speed := 3.2
@export var vertical_speed := 120.0
@export var idle_texture: Texture2D
@export var attack_texture: Texture2D
@export var idle_columns := 6
@export var idle_rows := 6
@export var idle_frame_count := 36
@export var idle_fps := 8.0
@export var attack_columns := 5
@export var attack_rows := 8
@export var attack_frame_count := 36

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D

var _flight_target_y := 0.0
var _animation_timer := 0.0
var _current_frame := 0
var _playing_attack := false

func _ready() -> void:
	super._ready()
	add_to_group("threadlings")
	_flight_target_y = home_position.y

	if visuals.has_node("Body"):
		visuals.get_node("Body").visible = false
	if sprite and idle_texture:
		_play_idle_animation()

func _process(delta: float) -> void:
	_update_sprite_animation(delta)

func begin_attack() -> void:
	super.begin_attack()
	if sprite and attack_texture:
		_play_attack_animation()

func end_attack() -> void:
	super.end_attack()
	if sprite and idle_texture:
		_play_idle_animation()

func apply_gravity(_delta: float) -> void:
	pass

func update_attack_motion(_delta: float) -> void:
	set_horizontal_target_speed(0.0)
	velocity = Vector2.ZERO

func patrol(_delta: float) -> void:
	var distance_from_home := global_position.x - home_position.x
	if abs(distance_from_home) >= patrol_distance:
		facing *= -1
		update_facing(facing)

	set_horizontal_target_speed(float(facing) * stats.move_speed)
	_flight_target_y = home_position.y + sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_amplitude

func chase_target(_delta: float) -> void:
	if not target:
		set_horizontal_target_speed(0.0)
		_flight_target_y = home_position.y
		return

	var direction := int(sign(target.global_position.x - global_position.x))
	if direction == 0:
		direction = facing

	update_facing(direction)
	set_horizontal_target_speed(float(direction) * stats.chase_speed)
	_flight_target_y = target.global_position.y + hover_offset

func move_enemy(delta: float) -> void:
	velocity.x = move_toward(velocity.x, _target_speed, stats.acceleration * delta)

	var y_delta := _flight_target_y - global_position.y
	var target_y_speed := clampf(y_delta * 3.0, -vertical_speed, vertical_speed)
	velocity.y = move_toward(velocity.y, target_y_speed, stats.acceleration * delta)

	move_and_slide()

func _play_idle_animation() -> void:
	_playing_attack = false
	_animation_timer = 0.0
	_current_frame = 0
	_configure_sprite_sheet(idle_texture, idle_columns, idle_rows)

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

func _update_sprite_animation(delta: float) -> void:
	if not sprite:
		return

	var frame_count := attack_frame_count if _playing_attack else idle_frame_count
	frame_count = clampi(frame_count, 1, max(1, sprite.hframes * sprite.vframes))

	var fps := _get_attack_fps() if _playing_attack else idle_fps
	if fps <= 0.0:
		return

	_animation_timer += delta
	var next_frame := int(floor(_animation_timer * fps))
	if _playing_attack:
		_current_frame = mini(next_frame, frame_count - 1)
	else:
		_current_frame = next_frame % frame_count

	sprite.frame = _current_frame

func _get_attack_fps() -> float:
	if not stats:
		return 24.0

	var attack_duration := stats.attack_windup + stats.attack_active_time + stats.attack_recovery
	if attack_duration <= 0.0:
		return 24.0

	return float(max(1, attack_frame_count)) / attack_duration
