@tool
extends Node2D

@export var light_paths: Array[NodePath] = []
@export var sprite_paths: Array[NodePath] = []
@export var animated_sprite_paths: Array[NodePath] = []

@export_range(0.0, 8.0, 0.01) var base_energy := 1.0
@export_range(0.0, 8.0, 0.01) var pulse_energy := 0.18
@export_range(0.01, 10.0, 0.01) var pulse_speed := 1.25
@export_range(0.0, 1.0, 0.01) var base_alpha := 0.62
@export_range(0.0, 1.0, 0.01) var pulse_alpha := 0.16
@export var pulse_sprite_alpha := false
@export_range(0.0, 60.0, 0.1) var sprite_fps := 24.0
@export_range(0, 255, 1) var animation_start_frame := 0
@export_range(0, 256, 1) var animation_frame_count := 0
@export var animation_ping_pong := false
@export var drift_enabled := false
@export var drift_radius := Vector2.ZERO
@export var drift_velocity := Vector2.ZERO

var _elapsed := 0.0
var _drift_origin := Vector2.ZERO
var _drift_offset := Vector2.ZERO
var _drift_current_velocity := Vector2.ZERO


func _ready() -> void:
	_drift_origin = position
	_drift_current_velocity = drift_velocity


func _process(delta: float) -> void:
	_elapsed += delta
	_update_drift(delta)

	var pulse: float = (sin(_elapsed * TAU * pulse_speed) + 1.0) * 0.5
	var energy: float = base_energy + (pulse_energy * pulse)
	var alpha: float = clampf(base_alpha, 0.0, 1.0)
	if pulse_sprite_alpha:
		alpha = clampf(base_alpha + (pulse_alpha * pulse), 0.0, 1.0)

	for path in light_paths:
		var light := get_node_or_null(path) as PointLight2D
		if light != null:
			light.energy = energy

	for path in sprite_paths:
		var item := get_node_or_null(path) as CanvasItem
		if item != null:
			var color := item.modulate
			color.a = alpha
			item.modulate = color

	if sprite_fps <= 0.0:
		return

	for path in animated_sprite_paths:
		var sprite := get_node_or_null(path) as Sprite2D
		if sprite == null:
			continue
		var total_frames: int = max(sprite.hframes * sprite.vframes, 1)
		var start_frame: int = clampi(animation_start_frame, 0, total_frames - 1)
		var available_frames: int = max(total_frames - start_frame, 1)
		var loop_frames: int = available_frames
		if animation_frame_count > 0:
			loop_frames = clampi(animation_frame_count, 1, available_frames)
		var elapsed_frame: int = _get_animation_loop_frame(loop_frames)
		sprite.frame = start_frame + elapsed_frame


func _update_drift(delta: float) -> void:
	if Engine.is_editor_hint() or not drift_enabled:
		return
	if drift_radius == Vector2.ZERO or drift_velocity == Vector2.ZERO:
		return

	_drift_offset += _drift_current_velocity * delta
	if absf(_drift_offset.x) > drift_radius.x:
		_drift_offset.x = signf(_drift_offset.x) * drift_radius.x
		_drift_current_velocity.x *= -1.0
	if absf(_drift_offset.y) > drift_radius.y:
		_drift_offset.y = signf(_drift_offset.y) * drift_radius.y
		_drift_current_velocity.y *= -1.0
	position = _drift_origin + _drift_offset


func _get_animation_loop_frame(loop_frames: int) -> int:
	if loop_frames <= 1:
		return 0
	var raw_frame: int = int(floor(_elapsed * sprite_fps))
	if not animation_ping_pong:
		return raw_frame % loop_frames
	var ping_pong_length: int = (loop_frames * 2) - 2
	var ping_pong_frame: int = raw_frame % ping_pong_length
	if ping_pong_frame >= loop_frames:
		ping_pong_frame = ping_pong_length - ping_pong_frame
	return ping_pong_frame
