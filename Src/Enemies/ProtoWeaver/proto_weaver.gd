class_name ProtoWeaver
extends EnemyBase

enum AttackMode {
	STAB,
	THREADBURST,
	HANGING_LASER,
}

@export var walk_texture: Texture2D
@export var stab_texture: Texture2D
@export var threadburst_texture: Texture2D
@export var hang_texture: Texture2D
@export var beam_texture: Texture2D
@export var hang_thread_texture: Texture2D
@export var thread_missile_scene: PackedScene
@export var armor_link_scene: PackedScene
@export var armor_link_stats: EnemyStats
@export var boss_health_bar_scene: PackedScene

@export var walk_columns := 6
@export var walk_rows := 8
@export var walk_frame_count := 48
@export var walk_fps := 8.0
@export var chase_fps_multiplier := 1.25

@export var attack_columns := 6
@export var attack_rows := 8
@export var attack_frame_count := 48
@export var hang_columns := 5
@export var hang_rows := 10
@export var hang_frame_count := 48
@export var hang_fps := 18.0
@export var hang_scale_multiplier := 1.38
@export var threadburst_every_n_attacks := 3
@export var hanging_laser_every_n_attacks := 5
@export var threadburst_min_missile_count := 3
@export var threadburst_max_missile_count := 5
@export var threadburst_low_health_max_missile_count := 8
@export var threadburst_spawn_offset := Vector2(0.0, -10.0)
@export var threadburst_horizontal_spread := 600.0
@export var threadburst_min_lane_spacing := 72.0
@export var threadburst_min_launch_speed := 760.0
@export var threadburst_max_launch_speed := 900.0
@export var threadburst_horizontal_force := 300.0
@export var threadburst_lane_jitter := 18.0
@export var threadburst_velocity_jitter := 55.0
@export var armor_link_left_offset := Vector2(-420.0, -48.0)
@export var armor_link_right_offset := Vector2(420.0, -48.0)
@export var armor_link_respawn_time := 12.0
@export var armor_link_pulse_warning_time := 3.0
@export var hang_rise_offset := Vector2(0.0, -360.0)
@export var hang_ceiling_offset := Vector2(0.0, -620.0)
@export var hang_thread_body_offset := Vector2(0.0, -185.0)
@export var hang_thread_cast_distance := 1800.0
@export var hang_thread_anchor_search_width := 220.0
@export var hang_thread_grow_time := 0.24
@export_flags_2d_physics var hang_thread_collision_mask := 1
@export var hang_arena_half_width := 390.0
@export var hang_return_to_home := true
@export var hang_rise_time := 0.45
@export var hang_return_time := 0.5
@export var hang_sway_pixels := 24.0
@export var hang_sway_speed := 2.2
@export var laser_shot_count := 3
@export var laser_tracking_time := 0.9
@export var laser_lock_time := 0.32
@export var laser_fire_time := 0.22
@export var laser_damage := 1
@export var laser_hit_width := 42.0
@export var laser_max_distance := 980.0
@export var laser_head_offset := Vector2(0.0, -90.0)
@export var use_detached_head := false
@export var detached_head_source_rect := Rect2(430.0, 90.0, 420.0, 420.0)
@export var detached_head_scale := Vector2(0.26, 0.26)

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D
@onready var hanging_thread_line: Line2D = $HangingThreadLine as Line2D
@onready var detached_head: Sprite2D = $DetachedHead as Sprite2D
@onready var laser_line: Line2D = $LaserLine as Line2D
@onready var boss_health_layer: CanvasLayer = $BossHealthLayer as CanvasLayer
@onready var boss_health_bar: BossHealthBar = $BossHealthLayer/BossHealthBar as BossHealthBar
@onready var boss_music_area: Area2D = $BossMusicArea as Area2D

var _animation_timer := 0.0
var _current_frame := 0
var _playing_attack := false
var _current_attack_mode := AttackMode.STAB
var _attack_count := 0
var _base_sprite_scale := Vector2.ONE
var _base_cell_size := Vector2.ONE
var _armor_links: Array[EnemyBase] = [null, null]
var _armor_link_respawn_timers := [0.0, 0.0]
var _hanging_laser_busy := false
var _hanging_laser_active := false
var _hanging_laser_landing := false
var _hang_origin := Vector2.ZERO
var _hang_position := Vector2.ZERO
var _hang_anchor := Vector2.ZERO
var _hang_thread_attach := Vector2.ZERO
var _hang_thread_draw_ratio := 0.0
var _hang_sway_timer := 0.0
var _laser_target_position := Vector2.ZERO
var _laser_firing := false
var _laser_hit_this_shot := false
var _player_in_boss_music_area := false
var _boss_music_latched := false

func _ready() -> void:
	super._ready()
	add_to_group("proto_weaver")
	hurtbox.health_component = null
	health_component.health_changed.connect(_on_boss_health_changed)
	health_component.died.connect(_on_boss_died)
	if boss_music_area:
		boss_music_area.body_entered.connect(_on_boss_music_area_body_entered)
		boss_music_area.body_exited.connect(_on_boss_music_area_body_exited)
	if boss_health_layer:
		boss_health_layer.visible = false
	if hanging_thread_line:
		hanging_thread_line.top_level = true
		hanging_thread_line.visible = false
		hanging_thread_line.texture = hang_thread_texture
	if detached_head:
		detached_head.top_level = true
		detached_head.visible = false
		detached_head.texture = hang_texture
		detached_head.region_enabled = true
		detached_head.region_rect = detached_head_source_rect
		detached_head.scale = detached_head_scale
	if laser_line:
		laser_line.top_level = true
		laser_line.visible = false
		laser_line.texture = beam_texture

	if visuals.has_node("Body"):
		visuals.get_node("Body").visible = false

	if sprite:
		_base_sprite_scale = sprite.scale
		if walk_texture:
			_base_cell_size = _get_sheet_cell_size(walk_texture, walk_columns, walk_rows)
		_play_walk_animation()

	update_facing(facing)
	_update_boss_health_bar()
	call_deferred("_spawn_all_armor_links")

func _process(delta: float) -> void:
	_update_sprite_animation(delta)
	_update_hanging_laser_visuals(delta)
	_update_armor_links(delta)
	_update_boss_health_bar()
	_update_boss_health_visibility()

func update_facing(direction: int) -> void:
	super.update_facing(direction)
	if visuals:
		visuals.scale.x = -abs(visuals.scale.x) * float(facing)

func chase_target(delta: float) -> void:
	if _try_return_inside_hang_arena():
		return

	super.chase_target(delta)
	_prevent_moving_outside_hang_arena()

func patrol(delta: float) -> void:
	if _try_return_inside_hang_arena():
		return

	super.patrol(delta)
	_prevent_moving_outside_hang_arena()

func begin_attack() -> void:
	_attack_count += 1
	if hanging_laser_every_n_attacks > 0 and _attack_count % hanging_laser_every_n_attacks == 0:
		_current_attack_mode = AttackMode.HANGING_LASER
	elif threadburst_every_n_attacks > 0 and _attack_count % threadburst_every_n_attacks == 0:
		_current_attack_mode = AttackMode.THREADBURST
	else:
		_current_attack_mode = AttackMode.STAB

	super.begin_attack()
	_play_attack_animation()

func end_attack() -> void:
	super.end_attack()
	if _current_attack_mode == AttackMode.HANGING_LASER and _hanging_laser_busy:
		return
	if sprite and walk_texture:
		_play_walk_animation()

func activate_attack_hitbox() -> void:
	if _current_attack_mode == AttackMode.HANGING_LASER:
		if not _hanging_laser_busy:
			_start_hanging_laser_sequence()
		return

	if _current_attack_mode == AttackMode.THREADBURST:
		_spawn_threadburst_missiles()
		return

	super.activate_attack_hitbox()

func deactivate_attack_hitbox() -> void:
	if _current_attack_mode == AttackMode.STAB:
		super.deactivate_attack_hitbox()

func update_attack_motion(_delta: float) -> void:
	if _current_attack_mode == AttackMode.HANGING_LASER:
		set_horizontal_target_speed(0.0)
		velocity = Vector2.ZERO
		return

	super.update_attack_motion(_delta)

func is_attack_sequence_busy() -> bool:
	return _hanging_laser_busy

func _on_detection_body_entered(body: Node2D) -> void:
	super._on_detection_body_entered(body)
	if body.is_in_group("player"):
		_boss_music_latched = true
	_update_boss_music_state()
	_update_boss_health_visibility()

func _on_detection_body_exited(body: Node2D) -> void:
	super._on_detection_body_exited(body)
	if not is_dead and target == null:
		_update_boss_music_state()
	_update_boss_health_visibility()

func _on_boss_music_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_boss_music_area = true
	_update_boss_music_state()

func _on_boss_music_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_boss_music_area = false
	_update_boss_music_state()

func _update_boss_music_state() -> void:
	if is_dead:
		AudioManager.stop_boss_music()
		return
	if _boss_music_latched or target != null or _player_in_boss_music_area:
		AudioManager.play_boss_music()

func _on_hurtbox_hit_received(damage: DamageData) -> void:
	if boss_health_layer:
		boss_health_layer.visible = true

	if _is_armored():
		if hit_flash:
			hit_flash.flash(Color(1.0, 0.08, 0.03, 1.0), 0.06)
		CombatFeedback.hit_pause(self, 0.025)
		return

	health_component.apply_damage(damage)

func _on_boss_health_changed(_current: int, _maximum: int) -> void:
	_update_boss_health_bar()

func _on_boss_died(_damage: DamageData) -> void:
	for index in range(_armor_links.size()):
		_clear_armor_link(index)
	AudioManager.stop_boss_music()
	_update_boss_health_bar()
	_update_boss_health_visibility()

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
	elif _current_attack_mode == AttackMode.HANGING_LASER:
		_configure_hang_sprite_sheet()
	else:
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

	var frame_count := _get_current_animation_frame_count()
	frame_count = clampi(frame_count, 1, max(1, sprite.hframes * sprite.vframes))

	var fps := _get_current_animation_fps()
	if fps <= 0.0:
		return

	_animation_timer += delta
	var next_frame := int(floor(_animation_timer * fps))
	if _playing_attack:
		if _current_attack_mode == AttackMode.HANGING_LASER and _hanging_laser_landing:
			_current_frame = maxi(frame_count - 1 - next_frame, 0)
		else:
			_current_frame = mini(next_frame, frame_count - 1)
	else:
		_current_frame = next_frame % frame_count

	sprite.frame = _current_frame

func _get_current_animation_frame_count() -> int:
	if not _playing_attack:
		return walk_frame_count
	if _current_attack_mode == AttackMode.HANGING_LASER:
		return hang_frame_count
	return attack_frame_count

func _get_current_animation_fps() -> float:
	if not _playing_attack:
		return _get_walk_fps()
	if _current_attack_mode == AttackMode.HANGING_LASER:
		return hang_fps
	return _get_attack_fps()

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

	var lane_offsets := _get_threadburst_lane_offsets()
	for x_offset in lane_offsets:
		var missile := thread_missile_scene.instantiate() as ThreadMissile
		if not missile:
			continue

		parent.add_child(missile)
		missile.global_position = global_position + threadburst_spawn_offset + Vector2(x_offset, 0.0)

		var outward_direction: float = sign(x_offset)
		if outward_direction == 0.0:
			outward_direction = randf_range(-0.25, 0.25)

		var launch_x: float = outward_direction * threadburst_horizontal_force + randf_range(-threadburst_velocity_jitter, threadburst_velocity_jitter)
		var launch_y: float = -randf_range(threadburst_min_launch_speed, threadburst_max_launch_speed)
		missile.launch(Vector2(launch_x, launch_y), self)

func _get_threadburst_lane_offsets() -> Array[float]:
	var missile_count := _get_threadburst_missile_count()
	var offsets: Array[float] = []
	var half_spread := threadburst_horizontal_spread * 0.5

	for _i in range(missile_count):
		var chosen_offset := randf_range(-half_spread, half_spread)
		for _attempt in range(8):
			chosen_offset = randf_range(-half_spread, half_spread)
			if _has_enough_lane_spacing(chosen_offset, offsets):
				break
		offsets.append(chosen_offset)

	offsets.sort()
	return offsets

func _get_threadburst_missile_count() -> int:
	var health_ratio := 1.0
	if health_component and health_component.max_health > 0:
		health_ratio = float(health_component.current_health) / float(health_component.max_health)

	var pressure := 1.0 - clampf(health_ratio, 0.0, 1.0)
	var max_count := roundi(lerpf(float(threadburst_max_missile_count), float(threadburst_low_health_max_missile_count), pressure))
	var min_count := threadburst_min_missile_count
	if health_ratio <= 0.5:
		min_count += 1
	if health_ratio <= 0.25:
		min_count += 1

	max_count = maxi(min_count, max_count)
	return randi_range(min_count, max_count)

func _has_enough_lane_spacing(candidate: float, existing_offsets: Array[float]) -> bool:
	for offset in existing_offsets:
		if abs(candidate - offset) < threadburst_min_lane_spacing:
			return false
	return true

func _start_hanging_laser_sequence() -> void:
	_hanging_laser_busy = true
	_hanging_laser_active = true
	_hanging_laser_landing = false
	_laser_firing = false
	_laser_hit_this_shot = false
	_hang_origin = global_position
	_hang_position = _clamp_to_hang_arena(_hang_origin + hang_rise_offset)
	_hang_anchor = _find_hang_anchor(_hang_position)
	_hang_thread_attach = _hang_position + hang_thread_body_offset
	_hang_thread_draw_ratio = 0.0
	_hang_sway_timer = 0.0
	deactivate_attack_hitbox()
	_play_hang_animation_forward()
	call_deferred("_run_hanging_laser_sequence")

func _run_hanging_laser_sequence() -> void:
	if not is_inside_tree() or is_dead:
		_finish_hanging_laser_sequence()
		return

	await _tween_global_position(_hang_position, hang_rise_time)

	if not is_inside_tree() or is_dead:
		_finish_hanging_laser_sequence()
		return

	if hanging_thread_line:
		hanging_thread_line.visible = true
	await _grow_hanging_thread()

	if detached_head and use_detached_head:
		detached_head.visible = true

	for _shot in range(laser_shot_count):
		await _track_hanging_laser(laser_tracking_time)
		await _lock_hanging_laser(laser_lock_time)
		await _fire_hanging_laser(laser_fire_time)
		if not is_inside_tree() or is_dead:
			_finish_hanging_laser_sequence()
			return

	_hanging_laser_landing = true
	_animation_timer = 0.0
	await _tween_global_position(_hang_origin, hang_return_time)
	_finish_hanging_laser_sequence()

func _track_hanging_laser(duration: float) -> void:
	var timer := 0.0
	while timer < duration and is_inside_tree() and not is_dead:
		_update_laser_target_from_player()
		await get_tree().process_frame
		timer += get_process_delta_time()

func _lock_hanging_laser(duration: float) -> void:
	_laser_firing = false
	_laser_hit_this_shot = false
	if laser_line:
		laser_line.visible = true
		laser_line.modulate = Color(1.0, 0.95, 0.78, 0.42)
		_update_laser_line()

	var timer := 0.0
	while timer < duration and is_inside_tree() and not is_dead:
		await get_tree().process_frame
		timer += get_process_delta_time()

func _fire_hanging_laser(duration: float) -> void:
	_laser_firing = true
	_laser_hit_this_shot = false
	if laser_line:
		laser_line.visible = true
		laser_line.width = 22.0
		laser_line.modulate = Color(1.0, 1.0, 1.0, 0.96)
		_update_laser_line()

	var timer := 0.0
	while timer < duration and is_inside_tree() and not is_dead:
		_try_damage_player_with_laser()
		await get_tree().process_frame
		timer += get_process_delta_time()

	_laser_firing = false
	if laser_line:
		laser_line.width = 9.0
		laser_line.visible = false

func _finish_hanging_laser_sequence() -> void:
	_hanging_laser_busy = false
	_hanging_laser_active = false
	_hanging_laser_landing = false
	_laser_firing = false
	global_position = _hang_origin if _hang_origin != Vector2.ZERO else global_position
	if hanging_thread_line:
		hanging_thread_line.visible = false
	if detached_head:
		detached_head.visible = false
	if laser_line:
		laser_line.visible = false
	if visuals:
		visuals.position.x = 0.0
	if sprite and walk_texture:
		_play_walk_animation()

func _get_hang_home_position() -> Vector2:
	if home_position != Vector2.ZERO:
		return home_position
	return global_position

func _get_hang_arena_left() -> float:
	return _get_hang_home_position().x - hang_arena_half_width

func _get_hang_arena_right() -> float:
	return _get_hang_home_position().x + hang_arena_half_width

func _clamp_to_hang_arena(position: Vector2) -> Vector2:
	position.x = clampf(position.x, _get_hang_arena_left(), _get_hang_arena_right())
	return position

func _try_return_inside_hang_arena() -> bool:
	if hang_arena_half_width <= 0.0:
		return false

	var left := _get_hang_arena_left()
	var right := _get_hang_arena_right()
	if global_position.x >= left and global_position.x <= right:
		return false

	var direction := 1 if global_position.x < left else -1
	update_facing(direction)
	set_horizontal_target_speed(float(direction) * stats.chase_speed)
	return true

func _prevent_moving_outside_hang_arena() -> void:
	if hang_arena_half_width <= 0.0:
		return

	var left := _get_hang_arena_left()
	var right := _get_hang_arena_right()
	if global_position.x <= left and _target_speed < 0.0:
		set_horizontal_target_speed(0.0)
	elif global_position.x >= right and _target_speed > 0.0:
		set_horizontal_target_speed(0.0)

func _tween_global_position(destination: Vector2, duration: float) -> void:
	if duration <= 0.0:
		global_position = destination
		return

	var tween := create_tween()
	tween.tween_property(self, "global_position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

func _play_hang_animation_forward() -> void:
	_playing_attack = true
	_hanging_laser_landing = false
	_animation_timer = 0.0
	_current_frame = 0
	_configure_hang_sprite_sheet()

func _configure_hang_sprite_sheet() -> void:
	var texture := hang_texture if hang_texture else walk_texture
	var columns := hang_columns if hang_texture else walk_columns
	var rows := hang_rows if hang_texture else walk_rows
	_configure_sprite_sheet(texture, columns, rows)
	if sprite and texture:
		sprite.scale = _get_scale_for_sheet(texture, columns, rows) * hang_scale_multiplier

func _update_hanging_laser_visuals(delta: float) -> void:
	if not _hanging_laser_active:
		return

	_hang_sway_timer += delta
	var sway := sin(_hang_sway_timer * hang_sway_speed) * hang_sway_pixels
	if visuals:
		visuals.position.x = sway

	_update_hanging_thread_line()
	_update_detached_head()
	if laser_line and laser_line.visible:
		_update_laser_line()

func _update_hanging_thread_line() -> void:
	if not hanging_thread_line:
		return

	var visual_offset := Vector2.ZERO
	if visuals:
		visual_offset.x = visuals.position.x
	var body_attach := global_position + visual_offset + hang_thread_body_offset
	_hang_thread_attach = body_attach
	var end := body_attach.lerp(_hang_anchor, _hang_thread_draw_ratio)
	hanging_thread_line.global_position = Vector2.ZERO
	hanging_thread_line.points = PackedVector2Array([body_attach, end])

func _update_detached_head() -> void:
	if not detached_head:
		return

	var head_position := global_position + laser_head_offset
	if _laser_target_position != Vector2.ZERO:
		var to_target := _laser_target_position - head_position
		if to_target.length() > 1.0:
			head_position += to_target.normalized() * 42.0
			detached_head.rotation = to_target.angle()

	detached_head.global_position = head_position

func _grow_hanging_thread() -> void:
	var timer := 0.0
	while timer < hang_thread_grow_time and is_inside_tree() and not is_dead:
		_hang_thread_draw_ratio = clampf(timer / maxf(hang_thread_grow_time, 0.001), 0.0, 1.0)
		_update_hanging_thread_line()
		await get_tree().process_frame
		timer += get_process_delta_time()

	_hang_thread_draw_ratio = 1.0
	_update_hanging_thread_line()

func _find_hang_anchor(body_position: Vector2) -> Vector2:
	var from := body_position + hang_thread_body_offset
	var best_anchor := Vector2.ZERO
	var best_distance := INF
	var search_offsets: Array[float] = [0.0]
	if hang_thread_anchor_search_width > 0.0:
		search_offsets.append(-hang_thread_anchor_search_width * 0.5)
		search_offsets.append(hang_thread_anchor_search_width * 0.5)
		search_offsets.append(-hang_thread_anchor_search_width)
		search_offsets.append(hang_thread_anchor_search_width)

	for x_offset in search_offsets:
		var ray_from := from + Vector2(x_offset, 0.0)
		var ray_to := ray_from + Vector2.UP * hang_thread_cast_distance
		var result := _cast_hang_anchor_ray(ray_from, ray_to)
		if not result.has("position"):
			continue

		var anchor := result["position"] as Vector2
		var distance := ray_from.distance_to(anchor)
		if distance < best_distance:
			best_distance = distance
			best_anchor = anchor

	if best_anchor != Vector2.ZERO:
		return best_anchor

	return from + Vector2.UP * hang_thread_cast_distance

func _cast_hang_anchor_ray(from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = hang_thread_collision_mask
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query)

func _update_laser_target_from_player() -> void:
	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if player_node:
		_laser_target_position = player_node.global_position + Vector2(0.0, -42.0)
	elif _laser_target_position == Vector2.ZERO:
		_laser_target_position = global_position + Vector2(float(facing) * laser_max_distance, -80.0)

func _update_laser_line() -> void:
	if not laser_line:
		return

	var start := _get_laser_start_position()
	var direction := (_laser_target_position - start).normalized()
	if direction.length() <= 0.01:
		direction = Vector2(float(facing), 0.0)
	var end := start + direction * laser_max_distance

	laser_line.global_position = Vector2.ZERO
	laser_line.points = PackedVector2Array([start, end])

func _try_damage_player_with_laser() -> void:
	if _laser_hit_this_shot:
		return

	var player_node := get_tree().get_first_node_in_group("player") as Node2D
	if not player_node:
		return

	var start := _get_laser_start_position()
	var direction := (_laser_target_position - start).normalized()
	if direction.length() <= 0.01:
		return

	var end := start + direction * laser_max_distance
	var hit_distance := _distance_to_segment(player_node.global_position + Vector2(0.0, -42.0), start, end)
	if hit_distance > laser_hit_width:
		return

	var hurtbox := player_node.get_node_or_null("Hurtbox") as HurtboxComponent
	if not hurtbox:
		return

	var damage := DamageData.new()
	damage.amount = laser_damage
	damage.source = self
	damage.hit_position = player_node.global_position
	damage.knockback = direction * 220.0 + Vector2(0.0, -70.0)
	damage.hitstun = stats.hurt_time if stats else 0.18
	damage.hit_pause = stats.hit_pause if stats else 0.04

	if hurtbox.receive_hit(damage):
		_laser_hit_this_shot = true

func _get_laser_start_position() -> Vector2:
	if detached_head and detached_head.visible:
		return detached_head.global_position
	return global_position + laser_head_offset

func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment := segment_end - segment_start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(segment_start)

	var t := clampf((point - segment_start).dot(segment) / length_squared, 0.0, 1.0)
	var closest := segment_start + segment * t
	return point.distance_to(closest)

func _spawn_all_armor_links() -> void:
	_spawn_armor_link(0)
	_spawn_armor_link(1)
	_update_boss_health_bar()

func _update_armor_links(delta: float) -> void:
	if is_dead:
		return

	for index in range(_armor_links.size()):
		if _is_armor_link_alive(index):
			continue

		if _armor_link_respawn_timers[index] > 0.0:
			_armor_link_respawn_timers[index] = maxf(0.0, _armor_link_respawn_timers[index] - delta)
			if _armor_link_respawn_timers[index] <= 0.0:
				_spawn_armor_link(index)

func _spawn_armor_link(index: int) -> void:
	if not armor_link_scene or is_dead:
		return

	_clear_armor_link(index)

	var link := armor_link_scene.instantiate() as EnemyBase
	if not link:
		return

	if armor_link_stats:
		link.stats = armor_link_stats

	var parent := get_parent()
	if not parent:
		parent = self

	parent.add_child(link)
	var link_offset := _get_armor_link_offset(index)
	link.global_position = global_position + link_offset
	link.home_position = link.global_position
	if link.has_method("configure_boss_tether"):
		link.configure_boss_tether(self, link_offset, index)
	link.health_component.died.connect(_on_armor_link_died.bind(index))
	_armor_links[index] = link
	_armor_link_respawn_timers[index] = 0.0
	_update_boss_health_bar()

func _clear_armor_link(index: int) -> void:
	if index < 0 or index >= _armor_links.size():
		return

	var link := _armor_links[index]
	if link and is_instance_valid(link):
		link.queue_free()
	_armor_links[index] = null

func _on_armor_link_died(_damage: DamageData, index: int) -> void:
	if index < 0 or index >= _armor_links.size():
		return

	_armor_links[index] = null
	_armor_link_respawn_timers[index] = armor_link_respawn_time
	_update_boss_health_bar()

func _is_armored() -> bool:
	return _is_armor_link_alive(0) or _is_armor_link_alive(1)

func _is_armor_link_alive(index: int) -> bool:
	if index < 0 or index >= _armor_links.size():
		return false

	var link := _armor_links[index]
	return link != null and is_instance_valid(link) and not link.is_dead

func _get_armor_link_offset(index: int) -> Vector2:
	if index == 0:
		return armor_link_left_offset
	return armor_link_right_offset

func _update_boss_health_bar() -> void:
	if not boss_health_bar or not health_component:
		return

	boss_health_bar.set_health(health_component.current_health, health_component.max_health)
	for index in range(_armor_links.size()):
		boss_health_bar.set_armor_link_state(
			index,
			_is_armor_link_alive(index),
			_armor_link_respawn_timers[index],
			armor_link_respawn_time,
			armor_link_pulse_warning_time
		)

func _update_boss_health_visibility() -> void:
	if not boss_health_layer:
		return

	boss_health_layer.visible = target != null and not is_dead
