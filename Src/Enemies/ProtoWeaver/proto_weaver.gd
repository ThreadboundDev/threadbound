class_name ProtoWeaver
extends EnemyBase

enum AttackMode {
	STAB,
	THREADBURST,
}

@export var walk_texture: Texture2D
@export var stab_texture: Texture2D
@export var threadburst_texture: Texture2D
@export var beam_texture: Texture2D
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
@export var threadburst_every_n_attacks := 3
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

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D
@onready var boss_health_layer: CanvasLayer = $BossHealthLayer as CanvasLayer
@onready var boss_health_bar: BossHealthBar = $BossHealthLayer/BossHealthBar as BossHealthBar

var _animation_timer := 0.0
var _current_frame := 0
var _playing_attack := false
var _current_attack_mode := AttackMode.STAB
var _attack_count := 0
var _base_sprite_scale := Vector2.ONE
var _base_cell_size := Vector2.ONE
var _armor_links: Array[EnemyBase] = [null, null]
var _armor_link_respawn_timers := [0.0, 0.0]

func _ready() -> void:
	super._ready()
	add_to_group("proto_weaver")
	hurtbox.health_component = null
	health_component.health_changed.connect(_on_boss_health_changed)
	health_component.died.connect(_on_boss_died)
	if boss_health_layer:
		boss_health_layer.visible = false

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
	_update_armor_links(delta)
	_update_boss_health_bar()
	_update_boss_health_visibility()

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

func _on_detection_body_entered(body: Node2D) -> void:
	super._on_detection_body_entered(body)
	_update_boss_health_visibility()

func _on_detection_body_exited(body: Node2D) -> void:
	super._on_detection_body_exited(body)
	_update_boss_health_visibility()

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
	link.global_position = global_position + _get_armor_link_offset(index)
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
