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
@export var tether_return_radius := 680.0
@export var tether_break_radius := 860.0
@export var tether_player_engage_radius := 520.0
@export var tether_return_speed_multiplier := 1.25
@export var tether_orbit_radius_x := 560.0
@export var tether_orbit_radius_y := 280.0
@export var tether_orbit_center_offset := Vector2(0.0, -130.0)
@export var tether_orbit_speed_min := 0.35
@export var tether_orbit_speed_max := 0.62
@export var tether_vertical_speed_multiplier := 1.65
@export var tether_neighbor_spacing := 170.0
@export var tether_boss_keepout_radius := Vector2(320.0, 260.0)
@export var tether_boss_keepout_offset := Vector2(0.0, -125.0)
@export var tether_line_width := 3.0
@export var tether_line_anchor_offset := Vector2(0.0, -230.0)

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D

var _flight_target_y := 0.0
var _animation_timer := 0.0
var _current_frame := 0
var _playing_attack := false
var _base_sprite_scale := Vector2.ONE
var _base_cell_size := Vector2.ONE
var _tether_anchor: Node2D = null
var _tether_offset := Vector2.ZERO
var _tether_slot_index := 0
var _tether_angle := 0.0
var _tether_orbit_speed := 0.0
var _tether_bob_phase := 0.0
var _tether_line: Line2D = null

func _ready() -> void:
	super._ready()
	add_to_group("threadlings")
	_flight_target_y = home_position.y

	if visuals.has_node("Body"):
		visuals.get_node("Body").visible = false
	if sprite:
		_base_sprite_scale = sprite.scale
		if idle_texture:
			_base_cell_size = _get_sheet_cell_size(idle_texture, idle_columns, idle_rows)
		_play_idle_animation()

func _process(delta: float) -> void:
	_update_sprite_animation(delta)
	_update_tether_home(delta)
	_update_tether_line()

func configure_boss_tether(anchor: Node2D, offset: Vector2, slot_index := 0) -> void:
	_tether_anchor = anchor
	_tether_offset = offset
	_tether_slot_index = slot_index
	_tether_angle = PI if offset.x < 0.0 else 0.0
	_tether_angle += randf_range(-0.8, 0.8)
	_tether_orbit_speed = randf_range(tether_orbit_speed_min, tether_orbit_speed_max)
	if slot_index % 2 == 1:
		_tether_orbit_speed *= -1.0
	_tether_bob_phase = randf_range(0.0, TAU)
	_ensure_tether_line()
	_update_tether_home(0.0)
	global_position = home_position
	_flight_target_y = home_position.y

func begin_attack() -> void:
	super.begin_attack()
	if sprite and attack_texture:
		_play_attack_animation()

func end_attack() -> void:
	super.end_attack()
	if sprite and idle_texture:
		_play_idle_animation()

func deactivate_attack_hitbox() -> void:
	super.deactivate_attack_hitbox()
	if sprite and idle_texture:
		_play_idle_animation()

func reset_for_save_point() -> void:
	if _has_tether_anchor():
		return

	super.reset_for_save_point()
	_flight_target_y = home_position.y
	if sprite and idle_texture:
		_play_idle_animation()

func apply_gravity(_delta: float) -> void:
	pass

func update_attack_motion(_delta: float) -> void:
	set_horizontal_target_speed(0.0)
	velocity = Vector2.ZERO

func patrol(_delta: float) -> void:
	_update_tether_home(_delta)
	if _has_tether_anchor():
		var home_delta := home_position - global_position
		if home_delta.length() > 12.0:
			var direction := int(sign(home_delta.x))
			if direction != 0:
				update_facing(direction)
			set_horizontal_target_speed(sign(home_delta.x) * stats.move_speed * tether_return_speed_multiplier)
			_flight_target_y = _get_tether_bob_y()
			return

	var distance_from_home := global_position.x - home_position.x
	var is_moving_past_right_edge := distance_from_home >= patrol_distance and facing > 0
	var is_moving_past_left_edge := distance_from_home <= -patrol_distance and facing < 0
	if is_moving_past_right_edge or is_moving_past_left_edge:
		facing *= -1
		update_facing(facing)

	set_horizontal_target_speed(float(facing) * stats.move_speed)
	_flight_target_y = _get_tether_bob_y()

func chase_target(_delta: float) -> void:
	_update_tether_home(_delta)
	if not target:
		set_horizontal_target_speed(0.0)
		_flight_target_y = home_position.y
		return

	if _should_return_to_tether():
		_return_to_tether_home()
		return

	var target_delta_x := target.global_position.x - global_position.x
	var direction := facing
	if abs(target_delta_x) > facing_dead_zone:
		direction = int(sign(target_delta_x))
	else:
		set_horizontal_target_speed(0.0)
		_flight_target_y = target.global_position.y + hover_offset
		return

	if direction == 0:
		direction = facing

	update_facing(direction)
	set_horizontal_target_speed(float(direction) * stats.chase_speed)
	_flight_target_y = target.global_position.y + hover_offset

func move_enemy(delta: float) -> void:
	if state_machine and state_machine.current_state_name == &"Hurt":
		velocity = velocity.move_toward(Vector2.ZERO, stats.acceleration * delta)
		move_and_slide()
		_resolve_tether_overlaps()
		return

	velocity.x = move_toward(velocity.x, _target_speed, stats.acceleration * delta)

	var y_delta := _flight_target_y - global_position.y
	var max_vertical_speed := vertical_speed * (tether_vertical_speed_multiplier if _has_tether_anchor() else 1.0)
	var target_y_speed := clampf(y_delta * 3.0, -max_vertical_speed, max_vertical_speed)
	velocity.y = move_toward(velocity.y, target_y_speed, stats.acceleration * delta)

	move_and_slide()
	_resolve_tether_overlaps()

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

func _has_tether_anchor() -> bool:
	return _tether_anchor != null and is_instance_valid(_tether_anchor)

func _update_tether_home(delta: float = 0.0) -> void:
	if not _has_tether_anchor():
		return

	_tether_angle = wrapf(_tether_angle + _tether_orbit_speed * delta, 0.0, TAU)
	home_position = _tether_anchor.global_position + _get_tether_orbit_offset()

func _get_tether_orbit_offset() -> Vector2:
	var x: float = cos(_tether_angle) * tether_orbit_radius_x
	var y: float = -abs(sin(_tether_angle)) * tether_orbit_radius_y
	y += sin(_tether_angle * 2.0 + _tether_bob_phase) * bob_amplitude
	return tether_orbit_center_offset + Vector2(x, y)

func _get_tether_bob_y() -> float:
	return home_position.y + sin(Time.get_ticks_msec() * 0.001 * bob_speed + _tether_bob_phase) * bob_amplitude

func _should_return_to_tether() -> bool:
	if not _has_tether_anchor():
		return false

	var distance_from_home := global_position.distance_to(home_position)
	if distance_from_home > tether_break_radius:
		return true

	if not target:
		return distance_from_home > tether_return_radius

	var target_distance_from_home := target.global_position.distance_to(home_position)
	if target_distance_from_home <= tether_player_engage_radius:
		return false

	return distance_from_home > tether_return_radius

func _return_to_tether_home() -> void:
	var home_delta := home_position - global_position
	if home_delta.length() <= 8.0:
		set_horizontal_target_speed(0.0)
		_flight_target_y = home_position.y
		return

	var direction := int(sign(home_delta.x))
	if direction != 0:
		update_facing(direction)

	set_horizontal_target_speed(sign(home_delta.x) * stats.chase_speed * tether_return_speed_multiplier)
	_flight_target_y = home_position.y

func _resolve_tether_overlaps() -> void:
	if not _has_tether_anchor():
		return

	_push_out_of_boss_keepout()
	_separate_from_tether_neighbors()

func _push_out_of_boss_keepout() -> void:
	var keepout_center := _tether_anchor.global_position + tether_boss_keepout_offset
	var local := global_position - keepout_center
	if abs(local.x) <= 0.01 and abs(local.y) <= 0.01:
		local = Vector2(-1.0 if _tether_slot_index == 0 else 1.0, -0.35)

	var radius_x: float = maxf(1.0, tether_boss_keepout_radius.x)
	var radius_y: float = maxf(1.0, tether_boss_keepout_radius.y)
	var ellipse_distance: float = sqrt(pow(local.x / radius_x, 2.0) + pow(local.y / radius_y, 2.0))
	if ellipse_distance >= 1.0:
		return

	var safe_local := local / maxf(ellipse_distance, 0.001)
	if safe_local.y > tether_boss_keepout_radius.y * 0.45:
		safe_local.y = tether_boss_keepout_radius.y * 0.45
	global_position = keepout_center + safe_local

func _separate_from_tether_neighbors() -> void:
	for node in get_tree().get_nodes_in_group("threadlings"):
		var other := node as Threadling
		if not other or other == self or not other._has_tether_anchor():
			continue
		if other._tether_anchor != _tether_anchor:
			continue

		var delta := global_position - other.global_position
		var distance := delta.length()
		if distance >= tether_neighbor_spacing:
			continue

		var direction := delta.normalized()
		if direction.length() <= 0.01:
			direction = Vector2(-1.0 if _tether_slot_index < other._tether_slot_index else 1.0, -0.2).normalized()

		var push_distance := (tether_neighbor_spacing - distance) * 0.5
		global_position += direction * push_distance

func _ensure_tether_line() -> void:
	if _tether_line and is_instance_valid(_tether_line):
		return

	_tether_line = Line2D.new()
	_tether_line.top_level = true
	_tether_line.z_index = 1
	_tether_line.width = tether_line_width
	_tether_line.default_color = Color(1.0, 1.0, 1.0, 0.72)
	_tether_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_tether_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var parent := get_parent()
	if parent:
		parent.add_child(_tether_line)
	else:
		add_child(_tether_line)

func _update_tether_line() -> void:
	if not _has_tether_anchor():
		if _tether_line and is_instance_valid(_tether_line):
			_tether_line.visible = false
		return

	_ensure_tether_line()
	if not _tether_line:
		return

	_tether_line.visible = not is_dead
	_tether_line.global_position = Vector2.ZERO
	_tether_line.points = PackedVector2Array([
		_tether_anchor.global_position + tether_line_anchor_offset,
		global_position + Vector2(0.0, -18.0)
	])

func _exit_tree() -> void:
	if _tether_line and is_instance_valid(_tether_line):
		_tether_line.queue_free()
