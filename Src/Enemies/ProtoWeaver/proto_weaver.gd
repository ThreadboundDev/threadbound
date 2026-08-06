class_name ProtoWeaver
extends EnemyBase

enum AttackMode {
	STAB,
	THREADBURST,
	GROUND_SWEEP,
	HANGING_LASER,
}

# Hand-mapped glowing-eye socket in each 1405x1405 hanging-animation cell.
# Values are Sprite2D-local offsets from the center of the active frame.
const HANG_HEAD_SOCKET_FRAMES := [
	Vector2(-3.2, -195.0),
	Vector2(-3.2, -189.6),
	Vector2(-3.4, -190.7),
	Vector2(-5.8, -145.8),
	Vector2(-8.3, -112.1),
	Vector2(-8.3, -89.6),
	Vector2(-9.0, -90.2),
	Vector2(12.5, -403.5),
	Vector2(20.5, -468.9),
	Vector2(41.9, -563.4),
	Vector2(57.8, -589.7),
	Vector2(98.7, -623.3),
	Vector2(152.6, -614.3),
	Vector2(200.5, -570.5),
	Vector2(245.0, -475.2),
	Vector2(250.3, -394.2),
	Vector2(170.4, -199.4),
	Vector2(93.1, -92.7),
	Vector2(14.6, 22.3),
	Vector2(0.0, 74.1),
	Vector2(16.6, 119.6),
	Vector2(51.3, 126.3),
	Vector2(65.5, 119.3),
	Vector2(79.8, 93.1),
	Vector2(80.9, 68.8),
	Vector2(67.6, 43.9),
	Vector2(45.3, 29.5),
	Vector2(28.7, 25.7),
	Vector2(2.9, 23.9),
	Vector2(-12.5, 27.5),
	Vector2(-25.8, 36.7),
	Vector2(-31.7, 46.2),
	Vector2(-29.8, 64.1),
	Vector2(-16.9, 84.8),
	Vector2(-3.5, 94.2),
	Vector2(20.2, 100.2),
	Vector2(38.0, 98.2),
	Vector2(60.7, 86.7),
	Vector2(71.6, 76.4),
	Vector2(84.2, 55.7),
	Vector2(85.7, 44.8),
	Vector2(80.8, 32.9),
	Vector2(74.3, 28.3),
	Vector2(61.9, 29.2),
	Vector2(47.0, 37.7),
	Vector2(38.2, 45.2),
	Vector2(26.3, 61.2),
	Vector2(19.4, 71.0),
]

@export var walk_texture: Texture2D
@export var stab_texture: Texture2D
@export var threadburst_texture: Texture2D
@export var hang_texture: Texture2D
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
@export var hang_scale_multiplier := 1.4
@export var threadburst_every_n_attacks := 3
@export var ground_sweep_every_n_attacks := 4
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
@export var phase_one_health_ratio := 0.6667
@export var phase_two_health_ratio := 0.3333
@export var phase_one_laser_shot_count := 5
@export var phase_two_laser_shot_count := 7
@export var laser_tracking_time := 0.46
@export var laser_lock_time := 0.24
@export var laser_fire_time := 0.28
@export var phase_two_timing_multiplier := 0.82
@export var phase_intershot_delay := 0.08
@export var phase_landing_punish_time := 0.85
@export var laser_damage := 30
@export var laser_hit_width := 42.0
@export var laser_max_distance := 980.0
@export var laser_head_offset := Vector2(0.0, -90.0)
@export var use_detached_head := false
@export var detached_head_source_rect := Rect2(430.0, 90.0, 420.0, 420.0)
@export var detached_head_scale := Vector2(0.26, 0.26)

@export_group("Ground Sweep")
@export var ground_sweep_spawn_offset := Vector2(170.0, -4.0)
@export var ground_sweep_damage := 30
@export var ground_sweep_speed := 820.0
@export var ground_sweep_pose_depth := 34.0
@export var ground_sweep_pose_lean := 0.075

@export_group("Boss Behavior")
@export var chase_freely_after_aggro := true

@export_group("Boss Stagger")
@export var stagger_initial_threshold := 105.0
@export var stagger_threshold_increase := 30.0
@export var stagger_threshold_cap := 195.0
@export var stagger_per_damage := 1.0
@export var stagger_hitstun_weight := 80.0
@export var stagger_decay_delay := 0.0
@export var stagger_decay_per_second := 0.0
@export var stagger_duration := 0.58
@export var stagger_immunity_time := 1.35
@export var committed_attack_stagger_multiplier := 0.35
@export var heavy_interrupt_damage := 45
@export var heavy_interrupt_hitstun := 0.24

@export_group("Attack Telegraph Holds")
@export var stab_telegraph_hold_frame := 22
@export var stab_telegraph_hold_time := 0.2
@export var threadburst_telegraph_hold_frame := 23
@export var threadburst_telegraph_hold_time := 0.28
@export var ground_sweep_telegraph_hold_frame := 16
@export var ground_sweep_telegraph_hold_time := 0.42
@export var cleaned_threadburst_frame_count := 26
@export var stagger_pose_frame := 25

@export_group("Boss SFX")
@export var boss_sfx_volume_offset_db := 1.5
@export_range(0.25, 1.25, 0.01) var boss_stab_pitch := 0.78
@export_range(0.25, 1.25, 0.01) var boss_threadburst_pitch := 0.72
@export_range(0.25, 1.25, 0.01) var boss_laser_pitch := 0.68
@export_range(0.25, 1.25, 0.01) var boss_subtone_pitch := 0.48
@export var boss_subtone_volume_offset_db := -10.0

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D
@onready var hanging_thread_line: Line2D = $HangingThreadLine as Line2D
@onready var detached_head: Sprite2D = $DetachedHead as Sprite2D
@onready var laser_beam: ProtoWeaverBeam = $AnimatedBeam as ProtoWeaverBeam
@onready var boss_health_layer: CanvasLayer = $BossHealthLayer as CanvasLayer
@onready var boss_health_bar: BossHealthBar = $BossHealthLayer/BossHealthBar as BossHealthBar
@onready var boss_music_area: Area2D = $BossMusicArea as Area2D

var _animation_timer := 0.0
var _current_frame := 0
var _playing_attack := false
var _current_attack_mode := AttackMode.STAB
var _attack_count := 0
var _base_sprite_scale := Vector2.ONE
var _base_sprite_position := Vector2.ZERO
var _base_cell_size := Vector2.ONE
var _configured_sprite_scale := Vector2.ONE
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
var _boss_aggro_latched := false
var _pending_hanging_phase := -1
var _next_hanging_phase := 0
var _active_hanging_phase := -1
var _phase_state_machine_process_mode := Node.PROCESS_MODE_INHERIT
var _phase_contact_was_monitoring := true
var _stagger_value := 0.0
var _stagger_count := 0
var _stagger_decay_delay_remaining := 0.0
var _stagger_immunity_remaining := 0.0
var _pending_stagger_interrupt := false
var _attack_hold_started := false
var _attack_hold_complete := false
var _attack_hold_remaining := 0.0
var _stagger_visual_tween: Tween
var _stagger_visual_active := false
var _stagger_pose_scale := Vector2.ONE
var _encounter_intro_active := false
var _intro_hud_revealed := false
var _intro_state_machine_process_mode := Node.PROCESS_MODE_INHERIT

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
	if laser_beam:
		laser_beam.hide_beam()

	if visuals.has_node("Body"):
		visuals.get_node("Body").visible = false

	if sprite:
		_base_sprite_scale = sprite.scale
		_base_sprite_position = sprite.position
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
	_update_stagger(delta)
	_try_start_pending_hanging_phase()
	_update_boss_health_bar()
	_update_boss_health_visibility()

func update_facing(direction: int) -> void:
	super.update_facing(direction)
	if visuals:
		visuals.scale.x = -abs(visuals.scale.x) * float(facing)

func chase_target(delta: float) -> void:
	if not _should_chase_freely() and _try_return_inside_hang_arena():
		return

	super.chase_target(delta)
	if not _should_chase_freely():
		_prevent_moving_outside_hang_arena()

func patrol(delta: float) -> void:
	if not _should_chase_freely() and _try_return_inside_hang_arena():
		return

	super.patrol(delta)
	if not _should_chase_freely():
		_prevent_moving_outside_hang_arena()

func begin_attack() -> void:
	_attack_count += 1
	if threadburst_every_n_attacks > 0 and _attack_count % threadburst_every_n_attacks == 0:
		_current_attack_mode = AttackMode.THREADBURST
	elif ground_sweep_every_n_attacks > 0 and _attack_count % ground_sweep_every_n_attacks == 0:
		_current_attack_mode = AttackMode.GROUND_SWEEP
	else:
		_current_attack_mode = AttackMode.STAB
	if _current_attack_mode == AttackMode.GROUND_SWEEP:
		_spawn_ground_sweep_charge()

	super.begin_attack()
	_play_attack_animation()

func get_attack_windup() -> float:
	var base_windup := stats.attack_windup if stats else 0.18
	if _current_attack_mode == AttackMode.STAB:
		return base_windup + maxf(0.0, stab_telegraph_hold_time)
	if _current_attack_mode == AttackMode.THREADBURST:
		return base_windup + maxf(0.0, threadburst_telegraph_hold_time)
	if _current_attack_mode == AttackMode.GROUND_SWEEP:
		return base_windup + maxf(0.0, ground_sweep_telegraph_hold_time)
	return base_windup

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
		_spawn_smash_vfx()
		return

	if _current_attack_mode == AttackMode.GROUND_SWEEP:
		_spawn_ground_sweep()
		return

	_play_boss_sfx(&"enemy_sword_attack", boss_stab_pitch)
	super.activate_attack_hitbox()

func deactivate_attack_hitbox() -> void:
	if _current_attack_mode == AttackMode.STAB:
		super.deactivate_attack_hitbox()

func update_attack_motion(_delta: float) -> void:
	if _current_attack_mode == AttackMode.HANGING_LASER or _hanging_laser_busy:
		set_horizontal_target_speed(0.0)
		velocity = Vector2.ZERO
		return

	super.update_attack_motion(_delta)

func is_player_in_attack_range() -> bool:
	return super.is_player_in_attack_range()

func is_attack_sequence_busy() -> bool:
	return _hanging_laser_busy

func _on_detection_body_entered(body: Node2D) -> void:
	if _encounter_intro_active:
		return
	super._on_detection_body_entered(body)
	if body.is_in_group("player"):
		_boss_aggro_latched = true
		_boss_music_latched = true
	_update_boss_music_state()
	_update_boss_health_visibility()

func _on_detection_body_exited(body: Node2D) -> void:
	if _encounter_intro_active:
		return
	super._on_detection_body_exited(body)
	if body.is_in_group("player") and _boss_aggro_latched and not is_dead:
		target = body
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
	if _hanging_laser_busy:
		if hit_flash:
			hit_flash.flash(Color(1.0, 0.86, 0.62, 1.0), 0.045)
		return

	if _is_armored():
		if hit_flash:
			hit_flash.flash(Color(0.82, 0.9, 0.96, 1.0), 0.07)
		var blocked_sound := AudioManager.play_sfx(&"enemy_hit", 2.0, 0.0)
		if blocked_sound:
			blocked_sound.pitch_scale *= 0.58
		CombatFeedback.hit_pause(self, 0.025)
		return

	var next_stagger := _stagger_value
	var should_stagger := false
	if _stagger_immunity_remaining <= 0.0:
		var contribution := (
			float(damage.amount) * stagger_per_damage
			+ maxf(0.0, damage.hitstun) * stagger_hitstun_weight
		)
		if _is_committed_to_attack():
			contribution *= committed_attack_stagger_multiplier
		var current_threshold := _get_current_stagger_threshold()
		next_stagger = minf(current_threshold, _stagger_value + contribution)
		var is_heavy_interrupt := (
			damage.amount >= heavy_interrupt_damage
			or damage.hitstun >= heavy_interrupt_hitstun
		)
		should_stagger = (
			next_stagger >= current_threshold
			and (not _is_committed_to_attack() or is_heavy_interrupt)
		)

	_pending_stagger_interrupt = should_stagger
	var damage_applied := health_component.apply_damage(damage)
	if damage_applied:
		_stagger_decay_delay_remaining = stagger_decay_delay
		if should_stagger:
			_stagger_value = 0.0
			_stagger_count += 1
			_stagger_immunity_remaining = stagger_immunity_time
		else:
			_stagger_value = next_stagger
	_pending_stagger_interrupt = false

func _on_damaged(damage: DamageData) -> void:
	AudioManager.play_sfx(&"enemy_hit")
	if hit_flash:
		hit_flash.flash(Color(1.0, 0.72, 0.66, 1.0), 0.065)
	if health_component.current_health > 0:
		_spawn_enemy_damage_vfx(damage)

	if damage.screen_shake_strength > 0.0:
		CombatFeedback.screen_shake(
			self,
			damage.screen_shake_strength,
			damage.screen_shake_duration
		)
	elif damage.use_receiver_screen_shake_fallback:
		CombatFeedback.screen_shake(self, stats.screen_shake_strength, 0.08)
	CombatFeedback.hit_pause(self, damage.hit_pause)

	# Ordinary hits retain impact feedback without cancelling committed actions.
	_play_hurt_visual_recoil(damage)
	if not _pending_stagger_interrupt or health_component.current_health <= 0:
		return

	var knockback := damage.knockback
	if knockback == Vector2.ZERO and damage.source is Node2D:
		var source_node := damage.source as Node2D
		knockback = Vector2(
			sign(global_position.x - source_node.global_position.x) * stats.knockback_strength,
			-70.0
		) * stats.incoming_knockback_multiplier
	velocity = knockback
	start_attack_cooldown(0.45)
	_pending_hurt_duration = stagger_duration
	if state_machine.current_state_name != &"Dead":
		state_machine.transition_to(&"Hurt")
	_play_stagger_animation()

func _update_stagger(delta: float) -> void:
	if _stagger_immunity_remaining > 0.0:
		_stagger_immunity_remaining = maxf(0.0, _stagger_immunity_remaining - delta)
		return
	if (
		_stagger_value >= _get_current_stagger_threshold()
		and not _is_committed_to_attack()
		and state_machine.current_state_name != &"Hurt"
		and state_machine.current_state_name != &"Dead"
	):
		_trigger_deferred_stagger()
		return
	if _stagger_decay_delay_remaining > 0.0:
		_stagger_decay_delay_remaining = maxf(0.0, _stagger_decay_delay_remaining - delta)
		return
	if _stagger_value > 0.0:
		_stagger_value = maxf(0.0, _stagger_value - stagger_decay_per_second * delta)

func _trigger_deferred_stagger() -> void:
	_stagger_value = 0.0
	_stagger_count += 1
	_stagger_immunity_remaining = stagger_immunity_time
	_stagger_decay_delay_remaining = 0.0
	velocity = Vector2.ZERO
	set_horizontal_target_speed(0.0)
	start_attack_cooldown(0.45)
	_pending_hurt_duration = stagger_duration
	if hit_flash:
		hit_flash.flash(Color(1.0, 0.9, 0.48, 1.0), 0.1)
	CombatFeedback.hit_pause(self, 0.055)
	state_machine.transition_to(&"Hurt")
	_play_stagger_animation()

func _is_committed_to_attack() -> bool:
	return (
		_hanging_laser_busy
		or _pending_hanging_phase >= 0
		or (state_machine and state_machine.current_state_name == &"Attack")
	)

func _get_current_stagger_threshold() -> float:
	return minf(
		stagger_initial_threshold + stagger_threshold_increase * float(_stagger_count),
		stagger_threshold_cap
	)

func _queue_health_threshold_phase(current: int, maximum: int) -> void:
	if maximum <= 0 or current <= 0 or _next_hanging_phase >= 2:
		return
	var health_ratio := float(current) / float(maximum)
	var threshold := phase_one_health_ratio if _next_hanging_phase == 0 else phase_two_health_ratio
	if health_ratio <= threshold:
		_pending_hanging_phase = _next_hanging_phase

func _try_start_pending_hanging_phase() -> void:
	if _pending_hanging_phase < 0 or _hanging_laser_busy or _encounter_intro_active or is_dead:
		return
	if not target or not state_machine:
		return
	if state_machine.current_state_name in [&"Attack", &"Hurt", &"Dead"]:
		return

	_active_hanging_phase = _pending_hanging_phase
	_pending_hanging_phase = -1
	_next_hanging_phase = maxi(_next_hanging_phase, _active_hanging_phase + 1)
	_current_attack_mode = AttackMode.HANGING_LASER
	_phase_state_machine_process_mode = state_machine.process_mode
	state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	if contact_hitbox:
		_phase_contact_was_monitoring = contact_hitbox.monitoring
		contact_hitbox.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	set_horizontal_target_speed(0.0)
	deactivate_attack_hitbox()
	_start_hanging_laser_sequence()

func _play_stagger_animation() -> void:
	if not sprite or not threadburst_texture or is_dead:
		return
	if _stagger_visual_tween and _stagger_visual_tween.is_valid():
		_stagger_visual_tween.kill()
	_stagger_visual_active = true
	_configure_sprite_sheet(threadburst_texture, attack_columns, attack_rows)
	_stagger_pose_scale = sprite.scale
	_set_sprite_cleanup_enabled(true)
	sprite.frame = clampi(stagger_pose_frame, 0, max(0, attack_columns * attack_rows - 1))
	sprite.position = _base_sprite_position
	sprite.rotation = 0.0

	var duration := maxf(0.32, stagger_duration)
	_stagger_visual_tween = create_tween()
	_stagger_visual_tween.set_trans(Tween.TRANS_CUBIC)
	_stagger_visual_tween.set_ease(Tween.EASE_OUT)
	_stagger_visual_tween.tween_property(
		sprite,
		"position",
		_base_sprite_position + Vector2(-float(facing) * 30.0, 22.0),
		duration * 0.18
	)
	_stagger_visual_tween.parallel().tween_property(
		sprite,
		"rotation",
		-float(facing) * 0.095,
		duration * 0.18
	)
	_stagger_visual_tween.parallel().tween_property(
		sprite,
		"scale",
		Vector2(_stagger_pose_scale.x * 1.06, _stagger_pose_scale.y * 0.91),
		duration * 0.18
	)
	_stagger_visual_tween.tween_interval(duration * 0.43)
	_stagger_visual_tween.tween_property(sprite, "position", _base_sprite_position, duration * 0.39)
	_stagger_visual_tween.parallel().tween_property(sprite, "rotation", 0.0, duration * 0.39)
	_stagger_visual_tween.parallel().tween_property(sprite, "scale", _stagger_pose_scale, duration * 0.39)
	_stagger_visual_tween.tween_callback(_finish_stagger_animation)

func _finish_stagger_animation() -> void:
	_stagger_visual_active = false
	if sprite:
		sprite.position = _base_sprite_position
		sprite.rotation = 0.0
	_set_sprite_cleanup_enabled(false)
	if not is_dead and not _hanging_laser_busy:
		_play_walk_animation()

func _on_boss_health_changed(_current: int, _maximum: int) -> void:
	_queue_health_threshold_phase(_current, _maximum)
	_update_boss_health_bar()

func _on_boss_died(_damage: DamageData) -> void:
	for index in range(_armor_links.size()):
		_clear_armor_link(index)
	AudioManager.stop_boss_music()
	_update_boss_health_bar()
	_update_boss_health_visibility()

func _play_walk_animation() -> void:
	if _stagger_visual_active:
		return
	_playing_attack = false
	_animation_timer = 0.0
	_current_frame = 0
	_set_sprite_cleanup_enabled(false)
	_configure_sprite_sheet(walk_texture, walk_columns, walk_rows)
	_reset_sprite_attack_pose()

func _play_attack_animation() -> void:
	_playing_attack = true
	_animation_timer = 0.0
	_current_frame = 0
	_attack_hold_started = false
	_attack_hold_complete = false
	_attack_hold_remaining = 0.0
	_reset_sprite_attack_pose()
	var texture := stab_texture
	if _current_attack_mode == AttackMode.THREADBURST:
		texture = threadburst_texture
		_set_sprite_cleanup_enabled(true)
		_configure_sprite_sheet(texture, attack_columns, attack_rows)
	elif _current_attack_mode == AttackMode.HANGING_LASER:
		_set_sprite_cleanup_enabled(false)
		_configure_hang_sprite_sheet()
	else:
		_set_sprite_cleanup_enabled(false)
		_configure_sprite_sheet(texture, attack_columns, attack_rows)

func _set_sprite_cleanup_enabled(enabled: bool) -> void:
	if sprite and sprite.material is ShaderMaterial:
		(sprite.material as ShaderMaterial).set_shader_parameter("clean_threadburst", enabled)

func _configure_sprite_sheet(texture: Texture2D, columns: int, rows: int) -> void:
	if not sprite or not texture:
		return

	sprite.texture = texture
	sprite.hframes = max(1, columns)
	sprite.vframes = max(1, rows)
	sprite.frame = 0
	sprite.scale = _get_scale_for_sheet(texture, sprite.hframes, sprite.vframes)
	_configured_sprite_scale = sprite.scale

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
	if _stagger_visual_active:
		return

	var frame_count := _get_current_animation_frame_count()
	frame_count = clampi(frame_count, 1, max(1, sprite.hframes * sprite.vframes))

	var fps := _get_current_animation_fps()
	if fps <= 0.0:
		return
	if _update_attack_telegraph_hold(delta, fps):
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
	_update_ground_sweep_pose()

func _update_attack_telegraph_hold(delta: float, fps: float) -> bool:
	if not _playing_attack or _current_attack_mode == AttackMode.HANGING_LASER:
		return false
	if _attack_hold_complete:
		return false

	var hold_frame := stab_telegraph_hold_frame
	var hold_time := stab_telegraph_hold_time
	if _current_attack_mode == AttackMode.THREADBURST:
		hold_frame = threadburst_telegraph_hold_frame
		hold_time = threadburst_telegraph_hold_time
	elif _current_attack_mode == AttackMode.GROUND_SWEEP:
		hold_frame = ground_sweep_telegraph_hold_frame
		hold_time = ground_sweep_telegraph_hold_time
	hold_frame = clampi(hold_frame, 0, max(0, attack_frame_count - 1))

	if not _attack_hold_started:
		var next_frame := int(floor((_animation_timer + delta) * fps))
		if next_frame < hold_frame:
			return false
		_attack_hold_started = true
		_attack_hold_remaining = maxf(0.0, hold_time)

	_current_frame = hold_frame
	sprite.frame = _current_frame
	_update_ground_sweep_pose()
	_attack_hold_remaining = maxf(0.0, _attack_hold_remaining - delta)
	if _attack_hold_remaining <= 0.0:
		_attack_hold_complete = true
	return true

func _update_ground_sweep_pose() -> void:
	if not sprite:
		return
	if not _playing_attack or _current_attack_mode != AttackMode.GROUND_SWEEP:
		_reset_sprite_attack_pose()
		return

	var frame_ratio := float(_current_frame) / float(maxi(1, attack_frame_count - 1))
	var lower := smoothstep(0.04, 0.42, frame_ratio)
	var recover := 1.0 - smoothstep(0.62, 1.0, frame_ratio)
	var pose_weight := lower * recover
	if _attack_hold_started and not _attack_hold_complete:
		pose_weight = 1.0
	sprite.position = _base_sprite_position + Vector2(18.0, ground_sweep_pose_depth) * pose_weight
	sprite.rotation = -ground_sweep_pose_lean * pose_weight
	sprite.scale = Vector2(
		_configured_sprite_scale.x * lerpf(1.0, 1.07, pose_weight),
		_configured_sprite_scale.y * lerpf(1.0, 0.91, pose_weight)
	)

func _reset_sprite_attack_pose() -> void:
	if not sprite or _stagger_visual_active:
		return
	sprite.position = _base_sprite_position
	sprite.rotation = 0.0
	if _configured_sprite_scale != Vector2.ONE:
		sprite.scale = _configured_sprite_scale

func _get_current_animation_frame_count() -> int:
	if not _playing_attack:
		return walk_frame_count
	if _current_attack_mode == AttackMode.HANGING_LASER:
		return hang_frame_count
	if _current_attack_mode == AttackMode.THREADBURST:
		return mini(attack_frame_count, cleaned_threadburst_frame_count)
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

	_play_boss_sfx(&"enemy_stomp_attack", boss_threadburst_pitch)
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

func _spawn_ground_sweep() -> void:
	var parent := get_parent()
	if not parent:
		return
	var wave := ProtoWeaverGroundWave.new()
	wave.damage_amount = ground_sweep_damage
	wave.travel_speed = ground_sweep_speed
	parent.add_child(wave)
	wave.global_position = global_position + Vector2(
		absf(ground_sweep_spawn_offset.x) * float(facing),
		ground_sweep_spawn_offset.y
	)
	wave.launch(facing, self)
	_play_boss_sfx(&"enemy_sword_attack", boss_stab_pitch * 0.82)

func _spawn_ground_sweep_charge() -> void:
	var charge := ProtoWeaverGroundCharge.new()
	add_child(charge)
	charge.configure(facing, get_attack_windup())

func _spawn_smash_vfx() -> void:
	var parent := get_parent()
	if not parent:
		return
	var smash_vfx := ProtoWeaverSmashVFX.new()
	parent.add_child(smash_vfx)
	smash_vfx.global_position = global_position + Vector2(0.0, -4.0)
	CombatFeedback.screen_shake(self, 5.0, 0.12)

func _start_hanging_laser_sequence() -> void:
	_hanging_laser_busy = true
	_hanging_laser_active = true
	_hanging_laser_landing = false
	_laser_firing = false
	_laser_hit_this_shot = false
	_hang_origin = _get_hang_home_position() if hang_return_to_home else global_position
	_hang_position = _clamp_to_hang_arena(_get_hang_home_position() + hang_rise_offset)
	_hang_anchor = _find_hang_anchor(_hang_position)
	_hang_thread_attach = _hang_position + hang_thread_body_offset
	_hang_thread_draw_ratio = 0.0
	_hang_sway_timer = 0.0
	deactivate_attack_hitbox()
	_play_hang_animation_forward()
	if hanging_thread_line:
		hanging_thread_line.visible = true
	call_deferred("_run_hanging_laser_sequence")

func _run_hanging_laser_sequence() -> void:
	if not is_inside_tree() or is_dead:
		_finish_hanging_laser_sequence()
		return

	await _grow_hanging_thread()
	await _tween_global_position(_hang_position, hang_rise_time)

	if not is_inside_tree() or is_dead:
		_finish_hanging_laser_sequence()
		return

	if detached_head and use_detached_head:
		detached_head.visible = true

	var shot_count := phase_one_laser_shot_count
	var timing_multiplier := 1.0
	if _active_hanging_phase >= 1:
		shot_count = phase_two_laser_shot_count
		timing_multiplier = phase_two_timing_multiplier
	for shot in range(shot_count):
		await _track_hanging_laser(laser_tracking_time * timing_multiplier)
		await _lock_hanging_laser(laser_lock_time * timing_multiplier)
		await _fire_hanging_laser(laser_fire_time)
		if not is_inside_tree() or is_dead:
			_finish_hanging_laser_sequence()
			return
		if shot < shot_count - 1 and phase_intershot_delay > 0.0:
			await get_tree().create_timer(phase_intershot_delay).timeout

	_hanging_laser_landing = true
	_animation_timer = 0.0
	await _tween_global_position(_hang_origin, hang_return_time)
	_finish_hanging_laser_sequence()

func _track_hanging_laser(duration: float) -> void:
	if laser_beam:
		laser_beam.show_tracking()
	var timer := 0.0
	while timer < duration and is_inside_tree() and not is_dead:
		_update_laser_target_from_player()
		_update_laser_line()
		await get_tree().process_frame
		timer += get_process_delta_time()

func _lock_hanging_laser(duration: float) -> void:
	_laser_firing = false
	_laser_hit_this_shot = false
	if laser_beam:
		laser_beam.show_locked()
		_update_laser_line()

	var timer := 0.0
	while timer < duration and is_inside_tree() and not is_dead:
		await get_tree().process_frame
		timer += get_process_delta_time()

func _fire_hanging_laser(duration: float) -> void:
	_laser_firing = true
	_laser_hit_this_shot = false
	_play_boss_sfx(&"enemy_laser_attack", boss_laser_pitch)
	if laser_beam:
		laser_beam.show_firing()
		_update_laser_line()

	var timer := 0.0
	while timer < duration and is_inside_tree() and not is_dead:
		_try_damage_player_with_laser()
		await get_tree().process_frame
		timer += get_process_delta_time()

	_laser_firing = false
	if laser_beam:
		laser_beam.hide_beam()

func _play_boss_sfx(sound_name: StringName, pitch_scale: float) -> void:
	var primary := AudioManager.play_sfx(sound_name, boss_sfx_volume_offset_db, 0.015)
	if primary:
		primary.pitch_scale *= pitch_scale

	var subtone := AudioManager.play_sfx(sound_name, boss_subtone_volume_offset_db, 0.0)
	if subtone:
		subtone.pitch_scale *= boss_subtone_pitch

func _should_chase_freely() -> bool:
	return chase_freely_after_aggro and _boss_aggro_latched

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
	if laser_beam:
		laser_beam.hide_beam()
	if visuals:
		visuals.position.x = 0.0
	if sprite and walk_texture:
		_play_walk_animation()
	if state_machine and not is_dead:
		state_machine.process_mode = _phase_state_machine_process_mode
		if target:
			state_machine.transition_to(&"Chase")
		else:
			state_machine.transition_to(&"Idle")
	if contact_hitbox and not is_dead:
		contact_hitbox.set_deferred("monitoring", _phase_contact_was_monitoring)
	_active_hanging_phase = -1
	start_attack_cooldown(maxf(1.0, phase_landing_punish_time / maxf(stats.attack_cooldown, 0.01)))
	if health_component:
		_queue_health_threshold_phase(health_component.current_health, health_component.max_health)

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
		_configured_sprite_scale = sprite.scale

func _update_hanging_laser_visuals(delta: float) -> void:
	if not _hanging_laser_active:
		return

	_hang_sway_timer += delta
	var sway := sin(_hang_sway_timer * hang_sway_speed) * hang_sway_pixels
	if visuals:
		visuals.position.x = sway

	_update_hanging_thread_line()
	_update_detached_head()
	if laser_beam and laser_beam.is_presenting():
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
	if not laser_beam:
		return

	var start := _get_laser_start_position()
	var direction := (_laser_target_position - start).normalized()
	if direction.length() <= 0.01:
		direction = Vector2(float(facing), 0.0)
	var end := start + direction * laser_max_distance

	laser_beam.set_beam(start, end)

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
	damage.amount = EnemyScaling.scale_damage(laser_damage)
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
	if _hanging_laser_active and sprite and not HANG_HEAD_SOCKET_FRAMES.is_empty():
		var socket_frame := clampi(sprite.frame, 0, HANG_HEAD_SOCKET_FRAMES.size() - 1)
		var socket_position := sprite.to_global(HANG_HEAD_SOCKET_FRAMES[socket_frame])
		if _laser_target_position != Vector2.ZERO:
			var outward := (_laser_target_position - socket_position).normalized()
			socket_position += outward * 10.0
		return socket_position
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
	boss_health_bar.set_stagger(
		_stagger_value,
		_get_current_stagger_threshold(),
		_stagger_immunity_remaining,
		stagger_immunity_time
	)
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

	if _encounter_intro_active:
		boss_health_layer.visible = _intro_hud_revealed and not is_dead
		return
	boss_health_layer.visible = target != null and not is_dead

func begin_encounter_intro() -> void:
	if is_dead or _encounter_intro_active:
		return

	_encounter_intro_active = true
	_intro_hud_revealed = false
	_boss_music_latched = true
	_update_boss_music_state()
	target = null
	velocity = Vector2.ZERO
	set_horizontal_target_speed(0.0)
	deactivate_attack_hitbox()
	if state_machine:
		_intro_state_machine_process_mode = state_machine.process_mode
		state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	if detection_area:
		detection_area.set_deferred("monitoring", false)
	if contact_hitbox:
		contact_hitbox.set_deferred("monitoring", false)
	if boss_health_bar:
		boss_health_bar.prepare_intro()
	if boss_health_layer:
		boss_health_layer.visible = false

func reveal_encounter_intro_hud(duration: float = 0.4) -> void:
	if is_dead:
		return
	_intro_hud_revealed = true
	if boss_health_layer:
		boss_health_layer.visible = true
	if boss_health_bar:
		boss_health_bar.reveal_intro(duration)

func complete_encounter_intro(player: Node2D) -> void:
	if is_dead:
		return

	_encounter_intro_active = false
	if state_machine:
		state_machine.process_mode = _intro_state_machine_process_mode
	if detection_area:
		detection_area.set_deferred("monitoring", true)
	if contact_hitbox:
		contact_hitbox.set_deferred("monitoring", true)
	if not _intro_hud_revealed:
		reveal_encounter_intro_hud(0.01)
	if is_instance_valid(player):
		target = player
		_boss_aggro_latched = true
		_boss_music_latched = true
		target_acquired.emit(target)
	_update_boss_music_state()
	_update_boss_health_visibility()

func is_encounter_intro_active() -> bool:
	return _encounter_intro_active
