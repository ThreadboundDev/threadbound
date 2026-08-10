class_name ProtoWeaver
extends EnemyBase

enum AttackMode {
	STAB,
	THREADBURST,
	GROUND_SWEEP,
	THREAD_REPULSE,
	ESSENCE_ECHO,
	HANGING_LASER,
}

enum ThreadburstPattern {
	WIDE_FAN,
	PLAYER_SIDE,
	SPLIT_FLANKS,
}

enum HangingEvent {
	AIMED_LASER,
	LASER_SWEEP,
	RED_VOLLEY,
	YELLOW_ECHO,
	BLUE_WALL_SHEAR,
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
@export var repulse_texture: Texture2D
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
@export var essence_echo_every_n_attacks := 5
@export var threadburst_min_missile_count := 3
@export var threadburst_max_missile_count := 5
@export var threadburst_low_health_max_missile_count := 8
@export var threadburst_horizontal_spread := 920.0
@export var threadburst_min_lane_spacing := 100.0
@export var threadburst_max_lane_spacing := 180.0
@export var threadburst_lane_jitter := 18.0
@export var threadburst_flight_time := 1.16
@export var threadburst_launch_height := 70.0
@export var threadburst_far_lane_time_bonus := 0.14
@export var threadburst_target_lead_time := 0.28
@export var threadburst_max_target_lead := 140.0

@export_group("Thread Repulse")
@export var repulse_trigger_distance := 190.0
@export var repulse_trigger_hold_time := 0.7
@export var repulse_internal_cooldown := 5.0
@export var repulse_damage := 12
@export var repulse_radius := 200.0
@export var repulse_backstep_speed := 310.0
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
@export_group("Wall Intermissions")
@export_node_path("Marker2D") var wall_left_marker_path: NodePath
@export_node_path("Marker2D") var wall_right_marker_path: NodePath
@export_node_path("Marker2D") var center_hang_marker_path: NodePath
@export_node_path("Marker2D") var recovery_floor_marker_path: NodePath
@export var wall_hang_foot_offset := Vector2(0.0, -426.0)
@export var wall_left_offset := Vector2(-720.0, -330.0)
@export var wall_right_offset := Vector2(720.0, -330.0)
@export var wall_thread_anchor_distance := 150.0
@export var wall_phase_break_distance := 260.0
@export var wall_phase_one_max_duration := 8.0
@export var wall_phase_two_max_duration := 11.0
@export var wall_phase_one_break_damage := 55.0
@export var wall_phase_two_break_damage := 80.0
@export var wall_knockdown_duration := 1.8
@export var wall_timeout_recovery_duration := 0.65
@export var wall_phase_event_delay := 0.18
@export var wall_phase_one_timing_multiplier := 1.0
@export var wall_phase_two_timing_multiplier := 0.78
@export var wall_blue_wave_speed := 720.0
@export var wall_blue_wave_lifetime := 1.55
@export var wall_blue_wave_surface_offset := 18.0
@export_group("")
@export var phase_one_health_ratio := 0.75
@export var phase_two_health_ratio := 0.5
@export var phase_three_health_ratio := 0.25
@export var phase_one_laser_shot_count := 4
@export var phase_two_laser_shot_count := 3
@export var phase_three_laser_event_count := 6
@export var phase_three_sweep_count := 2
@export var laser_tracking_time := 0.46
@export var laser_lock_time := 0.24
@export var laser_fire_time := 0.28
@export var phase_two_timing_multiplier := 0.82
@export var phase_three_timing_multiplier := 0.74
@export var phase_intershot_delay := 0.08
@export var phase_landing_punish_time := 0.85
@export var laser_aim_offset := 112.0
@export var phase_one_sweep_lock_time := 0.48
@export var phase_one_sweep_time := 0.95
@export var phase_two_sweep_lock_time := 0.34
@export var phase_two_sweep_time := 0.72
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

@export_group("Essence Echo")
@export var essence_echo_cross_distance := 220.0
@export var essence_echo_edge_padding := 72.0
@export var essence_echo_delay := 0.50
@export var essence_echo_floor_probe_up := 96.0
@export var essence_echo_floor_probe_down := 360.0

@export_group("Grounded Attack Poses")
@export var stab_pose_drawback := 24.0
@export var threadburst_pose_lift := 22.0
@export var threadburst_pose_stretch := 1.09
@export var repulse_pose_width := 1.12

@export_group("Boss Behavior")
@export var chase_freely_after_aggro := true
@export var vertical_response_height := 150.0
@export var vertical_response_hold_time := 0.6
@export var vertical_response_cooldown := 4.0

@export_group("Debug Attack Lab")
@export var debug_attack_lab_enabled := false
@export_enum("Stab:0", "Red Threadburst:1", "Blue Ground Wave:2", "Blue Repulse:3", "Yellow Essence Echo:4")
var debug_forced_attack_mode: int = AttackMode.THREADBURST

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
@export var repulse_telegraph_hold_frame := 20
@export var repulse_telegraph_hold_time := 0.42
@export var essence_echo_telegraph_hold_frame := 22
@export var essence_echo_telegraph_hold_time := 0.34
@export var cleaned_threadburst_frame_count := 26
@export var repulse_frame_count := 26
@export var stagger_pose_frame := 25

@export_group("Boss SFX")
@export var boss_sfx_volume_offset_db := 1.5
@export_range(0.25, 1.25, 0.01) var boss_stab_pitch := 0.78
@export_range(0.25, 1.25, 0.01) var boss_threadburst_pitch := 0.72
@export_range(0.25, 1.25, 0.01) var boss_laser_pitch := 0.68
@export_range(0.25, 1.25, 0.01) var boss_subtone_pitch := 0.48
@export var boss_subtone_volume_offset_db := -10.0

@onready var sprite: Sprite2D = $Visuals/Sprite2D as Sprite2D
@onready var flow_aura: ProtoWeaverFlowAura = $Visuals/FlowAura as ProtoWeaverFlowAura
@onready var hanging_thread_line: Line2D = $HangingThreadLine as Line2D
@onready var detached_head: Sprite2D = $DetachedHead as Sprite2D
@onready var laser_beam: ProtoWeaverBeam = $AnimatedBeam as ProtoWeaverBeam
@onready var boss_health_layer: CanvasLayer = $BossHealthLayer as CanvasLayer
@onready var boss_health_bar: BossHealthBar = $BossHealthLayer/BossHealthBar as BossHealthBar
@onready var boss_music_area: Area2D = $BossMusicArea as Area2D
@onready var body_collision_shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D
@onready var hurtbox_collision_shape: CollisionShape2D = $Hurtbox/CollisionShape2D as CollisionShape2D
@onready var contact_collision_shape: CollisionShape2D = $ContactHitbox/CollisionShape2D as CollisionShape2D
@onready var upper_body_grapple_target: Area2D = $UpperBodyGrappleTarget as Area2D

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
var _hang_rotation := 0.0
var _wall_hanging := false
var _wall_side := 0
var _wall_break_requested := false
var _wall_broken_by_player := false
var _wall_phase_timed_out := false
var _wall_phase_elapsed := 0.0
var _wall_break_damage := 0.0
var _wall_event_bag: Array[int] = []
var _last_wall_event := -1
var _laser_target_position := Vector2.ZERO
var _laser_firing := false
var _laser_hit_this_shot := false
var _laser_aim_offset := 0.0
var _laser_pattern_bag: Array[float] = []
var _last_laser_aim_offset := INF
var _laser_recharge_active := false
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
var _repulse_close_time := 0.0
var _repulse_cooldown_remaining := 0.0
var _vertical_response_hold := 0.0
var _vertical_response_cooldown_remaining := 0.0
var _vertical_response_use_echo_next := false
var _threadburst_pattern_bag: Array[int] = []
var _last_threadburst_pattern := -1
var _pending_essence_destination := Vector2.ZERO
var _essence_echo_vfx: ProtoWeaverEssenceEchoVFX
var _base_visuals_rotation := 0.0
var _base_body_collision_position := Vector2.ZERO
var _base_body_collision_rotation := 0.0
var _base_hurtbox_collision_position := Vector2.ZERO
var _base_hurtbox_collision_rotation := 0.0
var _base_contact_collision_position := Vector2.ZERO
var _base_contact_collision_rotation := 0.0
var _base_grapple_position := Vector2.ZERO
var _base_grapple_rotation := 0.0

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
	_capture_hanging_presentation_defaults()

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
	_update_repulse_opportunity(delta)
	_update_vertical_response_opportunity(delta)
	_update_wall_phase_timeout(delta)

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


func _update_repulse_opportunity(delta: float) -> void:
	_repulse_cooldown_remaining = maxf(0.0, _repulse_cooldown_remaining - delta)
	if (
		not target
		or is_dead
		or _hanging_laser_busy
		or _encounter_intro_active
	):
		_repulse_close_time = 0.0
		return

	var horizontal_distance := absf(target.global_position.x - global_position.x)
	if horizontal_distance <= repulse_trigger_distance:
		_repulse_close_time = minf(repulse_trigger_hold_time, _repulse_close_time + delta)
	else:
		_repulse_close_time = maxf(0.0, _repulse_close_time - delta * 2.0)


func _can_use_thread_repulse() -> bool:
	return (
		_repulse_cooldown_remaining <= 0.0
		and _repulse_close_time >= repulse_trigger_hold_time
	)


func _update_vertical_response_opportunity(delta: float) -> void:
	_vertical_response_cooldown_remaining = maxf(
		0.0,
		_vertical_response_cooldown_remaining - delta
	)
	if (
		not target
		or is_dead
		or _hanging_laser_busy
		or _encounter_intro_active
	):
		_vertical_response_hold = 0.0
		return
	if _is_target_elevated():
		_vertical_response_hold = minf(
			vertical_response_hold_time,
			_vertical_response_hold + delta
		)
	else:
		_vertical_response_hold = maxf(0.0, _vertical_response_hold - delta * 2.0)


func _is_target_elevated() -> bool:
	return (
		is_instance_valid(target)
		and target.global_position.y <= global_position.y - vertical_response_height
	)


func _can_use_vertical_response() -> bool:
	return (
		_vertical_response_cooldown_remaining <= 0.0
		and _vertical_response_hold >= vertical_response_hold_time
		and _is_target_elevated()
	)


func _take_next_vertical_response_attack() -> int:
	var attack_mode := AttackMode.ESSENCE_ECHO if _vertical_response_use_echo_next else AttackMode.THREADBURST
	_vertical_response_use_echo_next = not _vertical_response_use_echo_next
	return attack_mode


func _capture_hanging_presentation_defaults() -> void:
	if visuals:
		_base_visuals_rotation = visuals.rotation
	if body_collision_shape:
		_base_body_collision_position = body_collision_shape.position
		_base_body_collision_rotation = body_collision_shape.rotation
	if hurtbox_collision_shape:
		_base_hurtbox_collision_position = hurtbox_collision_shape.position
		_base_hurtbox_collision_rotation = hurtbox_collision_shape.rotation
	if contact_collision_shape:
		_base_contact_collision_position = contact_collision_shape.position
		_base_contact_collision_rotation = contact_collision_shape.rotation
	if upper_body_grapple_target:
		_base_grapple_position = upper_body_grapple_target.position
		_base_grapple_rotation = upper_body_grapple_target.rotation


func _update_wall_phase_timeout(delta: float) -> void:
	if not _wall_hanging or _wall_break_requested or _hanging_laser_landing:
		return
	_wall_phase_elapsed += delta
	var maximum_duration := _get_wall_phase_max_duration()
	if maximum_duration > 0.0 and _wall_phase_elapsed >= maximum_duration:
		_wall_phase_timed_out = true
		_request_wall_phase_break(false)


func _request_wall_phase_break(player_success: bool) -> void:
	if not _wall_hanging or _wall_break_requested:
		return
	_wall_break_requested = true
	_wall_broken_by_player = player_success
	_laser_firing = false
	if laser_beam:
		laser_beam.hide_beam()
	if hanging_thread_line:
		hanging_thread_line.visible = false
	if player_success:
		CombatFeedback.screen_shake(self, 6.0, 0.14)
		CombatFeedback.hit_pause(self, 0.075)


func _is_wall_event_cancelled() -> bool:
	return _wall_hanging and (_wall_break_requested or _hanging_laser_landing)


func _get_wall_phase_max_duration() -> float:
	return wall_phase_one_max_duration if _active_hanging_phase <= 0 else wall_phase_two_max_duration


func _get_wall_break_damage_threshold() -> float:
	return wall_phase_one_break_damage if _active_hanging_phase <= 0 else wall_phase_two_break_damage

func begin_attack() -> void:
	_attack_count += 1
	if debug_attack_lab_enabled:
		_current_attack_mode = clampi(
			debug_forced_attack_mode,
			AttackMode.STAB,
			AttackMode.ESSENCE_ECHO
		)
	elif _can_use_vertical_response():
		_current_attack_mode = _take_next_vertical_response_attack()
		_vertical_response_hold = 0.0
		_vertical_response_cooldown_remaining = vertical_response_cooldown
	elif _can_use_thread_repulse():
		_current_attack_mode = AttackMode.THREAD_REPULSE
		_repulse_close_time = 0.0
		_repulse_cooldown_remaining = repulse_internal_cooldown
	elif threadburst_every_n_attacks > 0 and _attack_count % threadburst_every_n_attacks == 0:
		_current_attack_mode = AttackMode.THREADBURST
	elif ground_sweep_every_n_attacks > 0 and _attack_count % ground_sweep_every_n_attacks == 0:
		_current_attack_mode = AttackMode.GROUND_SWEEP
	elif essence_echo_every_n_attacks > 0 and _attack_count % essence_echo_every_n_attacks == 0:
		_current_attack_mode = AttackMode.ESSENCE_ECHO
	else:
		_current_attack_mode = AttackMode.STAB
	if _current_attack_mode == AttackMode.GROUND_SWEEP:
		_spawn_ground_sweep_charge()
	elif _current_attack_mode == AttackMode.ESSENCE_ECHO:
		_spawn_essence_echo_telegraph()
	_show_current_attack_aura()

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
	if _current_attack_mode == AttackMode.THREAD_REPULSE:
		return base_windup + maxf(0.0, repulse_telegraph_hold_time)
	if _current_attack_mode == AttackMode.ESSENCE_ECHO:
		return base_windup + maxf(0.0, essence_echo_telegraph_hold_time)
	return base_windup

func end_attack() -> void:
	super.end_attack()
	if _current_attack_mode == AttackMode.HANGING_LASER and _hanging_laser_busy:
		return
	_hide_attack_aura()
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

	if _current_attack_mode == AttackMode.THREAD_REPULSE:
		_spawn_thread_repulse()
		return

	if _current_attack_mode == AttackMode.ESSENCE_ECHO:
		_activate_essence_echo()
		return

	_play_boss_sfx(&"enemy_sword_attack", boss_stab_pitch)
	super.activate_attack_hitbox()

func deactivate_attack_hitbox() -> void:
	if _current_attack_mode in [AttackMode.STAB, AttackMode.ESSENCE_ECHO]:
		super.deactivate_attack_hitbox()

func update_attack_motion(_delta: float) -> void:
	if _current_attack_mode == AttackMode.HANGING_LASER or _hanging_laser_busy:
		set_horizontal_target_speed(0.0)
		velocity = Vector2.ZERO
		return
	if _current_attack_mode == AttackMode.THREAD_REPULSE:
		apply_gravity(_delta)
		move_enemy(_delta)
		return

	super.update_attack_motion(_delta)

func is_player_in_attack_range() -> bool:
	return super.is_player_in_attack_range() or _can_use_vertical_response()

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
	if _hanging_laser_busy and not _laser_recharge_active:
		if not _wall_hanging or not _is_player_close_enough_to_break_wall_phase():
			if hit_flash:
				hit_flash.flash(Color(1.0, 0.86, 0.62, 1.0), 0.045)
			return
		_receive_wall_break_hit(damage)
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


func _receive_wall_break_hit(damage: DamageData) -> void:
	var threshold := maxf(1.0, _get_wall_break_damage_threshold())
	_wall_break_damage = minf(threshold, _wall_break_damage + maxf(1.0, float(damage.amount)))
	if _is_armored():
		if hit_flash:
			hit_flash.flash(Color(0.92, 0.92, 1.0, 1.0), 0.07)
		var blocked_sound := AudioManager.play_sfx(&"enemy_hit", 2.0, 0.0)
		if blocked_sound:
			blocked_sound.pitch_scale *= 0.64
		CombatFeedback.hit_pause(self, 0.03)
	else:
		health_component.apply_damage(damage)
	_update_boss_health_bar()
	if _wall_break_damage >= threshold and health_component.current_health > 0:
		_request_wall_phase_break(true)


func _is_player_close_enough_to_break_wall_phase() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		player = target
	return (
		is_instance_valid(player)
		and player.global_position.distance_to(global_position) <= wall_phase_break_distance
	)

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
		(_hanging_laser_busy and not _laser_recharge_active)
		or _pending_hanging_phase >= 0
		or (state_machine and state_machine.current_state_name == &"Attack")
	)

func _get_current_stagger_threshold() -> float:
	return minf(
		stagger_initial_threshold + stagger_threshold_increase * float(_stagger_count),
		stagger_threshold_cap
	)

func _queue_health_threshold_phase(current: int, maximum: int) -> void:
	if debug_attack_lab_enabled:
		return
	if maximum <= 0 or current <= 0 or _next_hanging_phase >= 3:
		return
	var health_ratio := float(current) / float(maximum)
	var threshold := phase_one_health_ratio
	match _next_hanging_phase:
		1:
			threshold = phase_two_health_ratio
		2:
			threshold = phase_three_health_ratio
	if health_ratio <= threshold:
		_pending_hanging_phase = _next_hanging_phase


func configure_debug_attack_lab(attack_mode: int) -> void:
	debug_attack_lab_enabled = true
	debug_forced_attack_mode = clampi(
		attack_mode,
		AttackMode.STAB,
		AttackMode.ESSENCE_ECHO
	)
	_pending_hanging_phase = -1
	_repulse_close_time = 0.0
	_repulse_cooldown_remaining = 0.0
	_attack_cooldown_timer = 0.0


func disable_debug_attack_lab() -> void:
	debug_attack_lab_enabled = false
	_attack_cooldown_timer = 0.0


func trigger_debug_hanging_phase(phase_index: int) -> void:
	debug_attack_lab_enabled = false
	_pending_hanging_phase = clampi(phase_index, 0, 2)
	_attack_cooldown_timer = 0.0
	_try_start_pending_hanging_phase()


func get_debug_attack_lab_name() -> String:
	if not debug_attack_lab_enabled:
		return "Normal Encounter"
	match debug_forced_attack_mode:
		AttackMode.STAB:
			return "Neutral Stab"
		AttackMode.THREADBURST:
			return "RED — Threadburst"
		AttackMode.GROUND_SWEEP:
			return "BLUE — Ground Wave"
		AttackMode.THREAD_REPULSE:
			return "BLUE — Thread Repulse"
		AttackMode.ESSENCE_ECHO:
			return "YELLOW — Essence Echo"
	return "Unknown"

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
		_base_sprite_position + Vector2(-float(facing) * 42.0, 30.0),
		duration * 0.18
	)
	_stagger_visual_tween.parallel().tween_property(
		sprite,
		"rotation",
		-float(facing) * 0.13,
		duration * 0.18
	)
	_stagger_visual_tween.parallel().tween_property(
		sprite,
		"scale",
		Vector2(_stagger_pose_scale.x * 1.08, _stagger_pose_scale.y * 0.86),
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
	_hide_attack_aura(true)
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
	elif _current_attack_mode == AttackMode.THREAD_REPULSE:
		texture = repulse_texture if repulse_texture else threadburst_texture
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
	if _stagger_visual_active or _laser_recharge_active:
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
	_update_grounded_attack_pose()

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
	elif _current_attack_mode == AttackMode.THREAD_REPULSE:
		hold_frame = repulse_telegraph_hold_frame
		hold_time = repulse_telegraph_hold_time
	elif _current_attack_mode == AttackMode.ESSENCE_ECHO:
		hold_frame = essence_echo_telegraph_hold_frame
		hold_time = essence_echo_telegraph_hold_time
	hold_frame = clampi(hold_frame, 0, max(0, attack_frame_count - 1))

	if not _attack_hold_started:
		var next_frame := int(floor((_animation_timer + delta) * fps))
		if next_frame < hold_frame:
			return false
		_attack_hold_started = true
		_attack_hold_remaining = maxf(0.0, hold_time)

	_current_frame = hold_frame
	sprite.frame = _current_frame
	_update_grounded_attack_pose()
	_attack_hold_remaining = maxf(0.0, _attack_hold_remaining - delta)
	if _attack_hold_remaining <= 0.0:
		_attack_hold_complete = true
	return true

func _update_grounded_attack_pose() -> void:
	if not sprite:
		return
	if not _playing_attack or _current_attack_mode == AttackMode.HANGING_LASER:
		_reset_sprite_attack_pose()
		return

	var frame_ratio := float(_current_frame) / float(maxi(1, attack_frame_count - 1))
	var lower := smoothstep(0.04, 0.42, frame_ratio)
	var recover := 1.0 - smoothstep(0.62, 1.0, frame_ratio)
	var pose_weight := lower * recover
	if _attack_hold_started and not _attack_hold_complete:
		pose_weight = 1.0

	match _current_attack_mode:
		AttackMode.STAB, AttackMode.ESSENCE_ECHO:
			sprite.position = _base_sprite_position + Vector2(-float(facing) * stab_pose_drawback, 0.0) * pose_weight
			sprite.rotation = -float(facing) * 0.035 * pose_weight
			sprite.scale = Vector2(
				_configured_sprite_scale.x * lerpf(1.0, 1.04, pose_weight),
				_configured_sprite_scale.y * lerpf(1.0, 0.98, pose_weight)
			)
		AttackMode.THREADBURST:
			sprite.position = _base_sprite_position + Vector2(0.0, -threadburst_pose_lift) * pose_weight
			sprite.rotation = float(facing) * 0.028 * pose_weight
			sprite.scale = Vector2(
				_configured_sprite_scale.x * lerpf(1.0, 0.94, pose_weight),
				_configured_sprite_scale.y * lerpf(1.0, threadburst_pose_stretch, pose_weight)
			)
		AttackMode.GROUND_SWEEP:
			sprite.position = _base_sprite_position + Vector2(18.0 * float(facing), ground_sweep_pose_depth) * pose_weight
			sprite.rotation = -float(facing) * ground_sweep_pose_lean * pose_weight
			sprite.scale = Vector2(
				_configured_sprite_scale.x * lerpf(1.0, 1.07, pose_weight),
				_configured_sprite_scale.y * lerpf(1.0, 0.91, pose_weight)
			)
		AttackMode.THREAD_REPULSE:
			sprite.position = _base_sprite_position + Vector2(0.0, 10.0) * pose_weight
			sprite.rotation = 0.0
			sprite.scale = Vector2(
				_configured_sprite_scale.x * lerpf(1.0, repulse_pose_width, pose_weight),
				_configured_sprite_scale.y * lerpf(1.0, 0.94, pose_weight)
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
	if _current_attack_mode == AttackMode.THREAD_REPULSE:
		return mini(attack_frame_count, repulse_frame_count)
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
	var landing_y := _get_threadburst_target_y()
	# Snapshot the player at release. The old implementation anchored every
	# lane to the boss's original spawn point, so a freely chasing boss could
	# fire an entire volley into an empty side of the room.
	var target_center_x := _get_threadburst_target_x()
	var half_spread := maxf(1.0, threadburst_horizontal_spread * 0.5)
	for lane_index in range(lane_offsets.size()):
		var x_offset := lane_offsets[lane_index]
		var missile := thread_missile_scene.instantiate() as ThreadMissile
		if not missile:
			continue

		parent.add_child(missile)
		var fan_ratio := 0.5
		if lane_offsets.size() > 1:
			fan_ratio = float(lane_index) / float(lane_offsets.size() - 1)
		var fan_offset := lerpf(-62.0, 62.0, fan_ratio)
		missile.global_position = global_position + Vector2(fan_offset, -threadburst_launch_height)
		var landing_position := Vector2(target_center_x + x_offset, landing_y)
		var distance_ratio := clampf(absf(x_offset) / half_spread, 0.0, 1.0)
		var flight_variation := randf_range(-0.055, 0.055)
		var flight_time := threadburst_flight_time + distance_ratio * threadburst_far_lane_time_bonus + flight_variation
		missile.launch_to_landing(landing_position, flight_time, self)

func _get_threadburst_lane_offsets() -> Array[float]:
	var pattern := _take_next_threadburst_pattern()
	var missile_count := _get_threadburst_missile_count()
	# Odd volleys preserve a true center threat and balanced flanking pairs.
	if missile_count % 2 == 0:
		missile_count += 1
	if pattern == ThreadburstPattern.PLAYER_SIDE:
		missile_count = mini(missile_count, 5)
	var offsets: Array[float] = []
	var lane_spacing := randf_range(
		threadburst_min_lane_spacing,
		maxf(threadburst_min_lane_spacing, threadburst_max_lane_spacing)
	)
	# Every pattern owns a center lane. A stationary player must always have
	# one real dodge check rather than being able to stand between the spread.
	offsets.append(0.0)

	match pattern:
		ThreadburstPattern.WIDE_FAN:
			for lane_index in range(1, missile_count):
				var rank := ceili(float(lane_index) * 0.5)
				var side := -1.0 if lane_index % 2 == 1 else 1.0
				offsets.append(side * float(rank) * lane_spacing)
		ThreadburstPattern.PLAYER_SIDE:
			var target_side := signf(_get_threadburst_target_x() - global_position.x)
			if target_side == 0.0:
				target_side = float(facing) if facing != 0 else 1.0
			# A one-sided rake leaves the player lane at its edge, so its dodge
			# direction differs clearly from the centered fan.
			for lane_index in range(1, missile_count):
				offsets.append(target_side * float(lane_index) * lane_spacing)
		ThreadburstPattern.SPLIT_FLANKS:
			for lane_index in range(1, missile_count):
				var rank := ceili(float(lane_index) * 0.5)
				var side := -1.0 if lane_index % 2 == 1 else 1.0
				var split_distance := lane_spacing * (1.3 if rank == 1 else 2.75 + float(rank - 2) * 1.25)
				offsets.append(side * split_distance)

	offsets.sort()
	return offsets


func _get_player_side_threadburst_offsets(missile_count: int, half_spread: float) -> Array[float]:
	var offsets: Array[float] = [0.0]
	var target_side := signf(_get_threadburst_target_x() - global_position.x)
	if target_side == 0.0:
		target_side = float(facing) if facing != 0 else 1.0
	var maximum_distance := maxf(half_spread, float(maxi(0, missile_count - 1)) * threadburst_min_lane_spacing)
	for lane_index in range(1, maxi(1, missile_count)):
		offsets.append(target_side * minf(float(lane_index) * threadburst_min_lane_spacing, maximum_distance))
	offsets.sort()
	return offsets


func _get_threadburst_target_x() -> float:
	if is_instance_valid(target):
		var target_x := target.global_position.x
		if target is CharacterBody2D:
			var target_body := target as CharacterBody2D
			target_x += clampf(
				target_body.velocity.x * threadburst_target_lead_time,
				-threadburst_max_target_lead,
				threadburst_max_target_lead
			)
		return target_x
	return global_position.x + float(facing) * minf(120.0, threadburst_horizontal_spread * 0.25)


func _get_threadburst_target_y() -> float:
	if (_wall_hanging and is_instance_valid(target)) or _is_target_elevated():
		# Character origins sit at their feet, so this places the needle knot on
		# the occupied platform lane instead of harmlessly returning to ground.
		return target.global_position.y - 8.0
	return global_position.y - 8.0


func _fit_threadburst_offsets_to_arena(offsets: Array[float], half_spread: float) -> void:
	if offsets.is_empty():
		return
	offsets.sort()
	var minimum_bound := -half_spread + 10.0
	var maximum_bound := half_spread - 10.0
	var minimum_shift: float = minimum_bound - float(offsets.front())
	var maximum_shift: float = maximum_bound - float(offsets.back())
	var shift := clampf(0.0, minimum_shift, maximum_shift)
	for index in range(offsets.size()):
		offsets[index] += shift


func _take_next_threadburst_pattern() -> int:
	if _threadburst_pattern_bag.is_empty():
		_threadburst_pattern_bag = [
			ThreadburstPattern.WIDE_FAN,
			ThreadburstPattern.PLAYER_SIDE,
			ThreadburstPattern.SPLIT_FLANKS,
		]
		_threadburst_pattern_bag.shuffle()
		if _threadburst_pattern_bag.size() > 1 and _threadburst_pattern_bag.back() == _last_threadburst_pattern:
			var swap_value := _threadburst_pattern_bag[0]
			_threadburst_pattern_bag[0] = _threadburst_pattern_bag.back()
			_threadburst_pattern_bag[_threadburst_pattern_bag.size() - 1] = swap_value
	_last_threadburst_pattern = _threadburst_pattern_bag.pop_back()
	return _last_threadburst_pattern

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


func _spawn_thread_repulse() -> void:
	var parent := get_parent()
	if not parent:
		return
	var repulse := ProtoWeaverSpacingVFX.new()
	repulse.configure(self, repulse_damage, repulse_radius)
	parent.add_child(repulse)
	repulse.global_position = global_position + Vector2(0.0, -112.0)
	velocity.x = -float(facing) * repulse_backstep_speed
	set_horizontal_target_speed(0.0)
	_play_boss_sfx(&"enemy_stomp_attack", boss_threadburst_pitch * 1.18)
	CombatFeedback.screen_shake(self, 4.5, 0.1)


func _spawn_smash_charge() -> void:
	var charge := ProtoWeaverSmashVFX.new()
	charge.configure_charge(get_attack_windup(), facing, 5)
	add_child(charge)
	charge.position = Vector2.ZERO


func _spawn_essence_echo_telegraph() -> void:
	var parent := get_parent()
	if not parent:
		return
	var cross_direction := float(facing)
	if is_instance_valid(target):
		cross_direction = signf(target.global_position.x - global_position.x)
	if cross_direction == 0.0:
		cross_direction = float(facing) if facing != 0 else 1.0
	var target_position := global_position + Vector2(cross_direction * essence_echo_cross_distance * 2.0, 0.0)
	if is_instance_valid(target):
		target_position = target.global_position
	var home_x := _get_hang_home_position().x
	var edge := maxf(40.0, hang_arena_half_width - essence_echo_edge_padding)
	target_position.x = clampf(target_position.x, home_x - edge, home_x + edge)
	_pending_essence_destination = _resolve_essence_blink_destination(target_position)

	_essence_echo_vfx = ProtoWeaverEssenceEchoVFX.new()
	var echo_scale := _get_scale_for_sheet(stab_texture, attack_columns, attack_rows)
	_essence_echo_vfx.configure(
		self,
		_pending_essence_destination,
		int(cross_direction),
		stab_texture,
		attack_columns,
		attack_rows,
		essence_echo_telegraph_hold_frame,
		echo_scale,
		_base_sprite_position,
		stats.attack_damage if stats else 24,
		get_attack_windup(),
		true
	)
	parent.add_child(_essence_echo_vfx)
	_essence_echo_vfx.global_position = _pending_essence_destination


func _resolve_essence_blink_destination(snapshot: Vector2) -> Vector2:
	if not is_inside_tree():
		return snapshot
	var query := PhysicsRayQueryParameters2D.create(
		snapshot + Vector2.UP * essence_echo_floor_probe_up,
		snapshot + Vector2.DOWN * essence_echo_floor_probe_down,
		1
	)
	query.exclude = [get_rid()]
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result.has("position"):
		var floor_position: Vector2 = result["position"]
		return Vector2(snapshot.x, floor_position.y)
	return snapshot


func _activate_essence_echo() -> void:
	global_position = _pending_essence_destination
	velocity = Vector2.ZERO
	if is_instance_valid(target):
		var target_direction := signi(roundi(target.global_position.x - global_position.x))
		if target_direction != 0:
			update_facing(target_direction)
	if is_instance_valid(_essence_echo_vfx):
		_essence_echo_vfx.complete_destination()
	_play_boss_sfx(&"enemy_sword_attack", boss_stab_pitch * 1.08)
	CombatFeedback.screen_shake(self, 3.0, 0.08)
	super.activate_attack_hitbox()

func _spawn_smash_vfx() -> void:
	var parent := get_parent()
	if not parent:
		return
	var smash_vfx := ProtoWeaverSmashVFX.new()
	smash_vfx.configure_impact()
	parent.add_child(smash_vfx)
	smash_vfx.global_position = global_position + Vector2(0.0, -4.0)
	CombatFeedback.screen_shake(self, 5.0, 0.12)


func _show_current_attack_aura() -> void:
	if not flow_aura:
		return
	match _current_attack_mode:
		AttackMode.THREADBURST:
			flow_aura.show_power()
		AttackMode.GROUND_SWEEP, AttackMode.THREAD_REPULSE:
			flow_aura.show_balance()
		AttackMode.ESSENCE_ECHO:
			flow_aura.show_essence()
		AttackMode.HANGING_LASER:
			flow_aura.show_all_channels()
		_:
			flow_aura.hide_aura()


func _hide_attack_aura(immediate := false) -> void:
	if flow_aura:
		flow_aura.hide_aura(immediate)

func _start_hanging_laser_sequence() -> void:
	if flow_aura:
		flow_aura.show_all_channels()
	_hanging_laser_busy = true
	_hanging_laser_active = true
	_hanging_laser_landing = false
	_laser_firing = false
	_laser_hit_this_shot = false
	_wall_hanging = _active_hanging_phase in [0, 1]
	_hang_origin = _get_recovery_floor_position() if _wall_hanging else (_get_hang_home_position() if hang_return_to_home else global_position)
	_wall_break_requested = false
	_wall_broken_by_player = false
	_wall_break_damage = 0.0
	_wall_phase_timed_out = false
	_wall_phase_elapsed = 0.0
	_wall_event_bag.clear()
	_last_wall_event = -1
	if _wall_hanging:
		_configure_wall_hang_destination()
	else:
		_wall_side = 0
		var center_marker := _get_phase_marker(center_hang_marker_path)
		_hang_rotation = center_marker.global_rotation if center_marker else 0.0
		_hang_position = _get_body_position_from_hang_foot_marker(center_marker) if center_marker else _clamp_to_hang_arena(_get_hang_home_position() + hang_rise_offset)
		_hang_anchor = center_marker.global_position if center_marker else _find_hang_anchor(_hang_position)
	_hang_thread_attach = _get_hanging_body_attach(_hang_position)
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
	if _wall_hanging and visuals:
		var rotation_tween := create_tween()
		rotation_tween.tween_property(
			visuals,
			"rotation",
			_hang_rotation,
			hang_rise_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _tween_global_position(_hang_position, hang_rise_time)
	if _wall_hanging:
		_apply_wall_collision_rotation(_hang_rotation)

	if not is_inside_tree() or is_dead:
		_finish_hanging_laser_sequence()
		return

	if detached_head and use_detached_head:
		detached_head.visible = true

	if _wall_hanging:
		await _run_wall_intermission_deck()
	else:
		await _run_final_hanging_laser_mix()
	if not is_inside_tree() or is_dead:
		_finish_hanging_laser_sequence()
		return

	_hanging_laser_landing = true
	_animation_timer = 0.0
	if _wall_hanging:
		_apply_wall_collision_rotation(0.0)
		if visuals:
			var return_rotation_tween := create_tween()
			return_rotation_tween.tween_property(
				visuals,
				"rotation",
				_base_visuals_rotation,
				hang_return_time
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tween_global_position(_hang_origin, hang_return_time)
	if _wall_hanging:
		await _run_laser_recharge(
			wall_knockdown_duration if _wall_broken_by_player else wall_timeout_recovery_duration
		)
	else:
		await _run_laser_recharge()
	_finish_hanging_laser_sequence()


func _configure_wall_hang_destination() -> void:
	var preferred_side := -1 if _active_hanging_phase == 0 else 1
	if is_instance_valid(target):
		preferred_side = -1 if target.global_position.x >= _get_hang_home_position().x else 1
	_wall_side = preferred_side
	var marker_path := wall_left_marker_path if _wall_side < 0 else wall_right_marker_path
	var wall_marker := _get_phase_marker(marker_path)
	if wall_marker:
		_hang_position = _get_body_position_from_hang_foot_marker(wall_marker)
		_hang_rotation = wall_marker.global_rotation
		_hang_anchor = wall_marker.global_position
	else:
		var offset := wall_left_offset if _wall_side < 0 else wall_right_offset
		_hang_position = _get_hang_home_position() + offset
		_hang_rotation = float(_wall_side) * PI * 0.5
	_hang_thread_attach = _get_hanging_body_attach(_hang_position)
	if not wall_marker:
		_hang_anchor = _hang_thread_attach + Vector2.UP.rotated(_hang_rotation) * wall_thread_anchor_distance


func _get_phase_marker(marker_path: NodePath) -> Marker2D:
	if marker_path.is_empty():
		return null
	return get_node_or_null(marker_path) as Marker2D


func _get_body_position_from_hang_foot_marker(marker: Marker2D) -> Vector2:
	if not marker:
		return global_position
	return marker.global_position - wall_hang_foot_offset.rotated(marker.global_rotation)


func _get_recovery_floor_position() -> Vector2:
	var recovery_marker := _get_phase_marker(recovery_floor_marker_path)
	return recovery_marker.global_position if recovery_marker else _get_hang_home_position()


func _get_hanging_body_attach(body_position: Vector2) -> Vector2:
	return body_position + hang_thread_body_offset.rotated(_hang_rotation)


func _apply_wall_collision_rotation(angle: float) -> void:
	_apply_rotated_node_transform(
		body_collision_shape,
		_base_body_collision_position,
		_base_body_collision_rotation,
		angle
	)
	_apply_rotated_node_transform(
		hurtbox_collision_shape,
		_base_hurtbox_collision_position,
		_base_hurtbox_collision_rotation,
		angle
	)
	_apply_rotated_node_transform(
		contact_collision_shape,
		_base_contact_collision_position,
		_base_contact_collision_rotation,
		angle
	)
	_apply_rotated_node_transform(
		upper_body_grapple_target,
		_base_grapple_position,
		_base_grapple_rotation,
		angle
	)


func _apply_rotated_node_transform(
	node: Node2D,
	base_position: Vector2,
	base_rotation: float,
	angle: float
) -> void:
	if not node:
		return
	node.position = base_position.rotated(angle)
	node.rotation = base_rotation + angle


func _run_wall_intermission_deck() -> void:
	while is_inside_tree() and not is_dead and not _wall_break_requested:
		var event := _take_next_wall_event()
		await _run_wall_event(event)
		if _wall_break_requested or not is_inside_tree() or is_dead:
			break
		await _wait_with_wall_cancel(wall_phase_event_delay)


func _take_next_wall_event() -> int:
	if _wall_event_bag.is_empty():
		if _active_hanging_phase <= 0:
			_wall_event_bag = [
				HangingEvent.AIMED_LASER,
				HangingEvent.AIMED_LASER,
				HangingEvent.RED_VOLLEY,
				HangingEvent.YELLOW_ECHO,
				HangingEvent.BLUE_WALL_SHEAR,
			]
		else:
			_wall_event_bag = [
				HangingEvent.AIMED_LASER,
				HangingEvent.LASER_SWEEP,
				HangingEvent.RED_VOLLEY,
				HangingEvent.RED_VOLLEY,
				HangingEvent.YELLOW_ECHO,
				HangingEvent.BLUE_WALL_SHEAR,
			]
		_wall_event_bag.shuffle()
		if _wall_event_bag.size() > 1 and _wall_event_bag.back() == _last_wall_event:
			var swap_value := _wall_event_bag[0]
			_wall_event_bag[0] = _wall_event_bag.back()
			_wall_event_bag[_wall_event_bag.size() - 1] = swap_value
	_last_wall_event = _wall_event_bag.pop_back()
	return _last_wall_event


func _get_wall_timing_multiplier() -> float:
	return (
		wall_phase_one_timing_multiplier
		if _active_hanging_phase <= 0
		else wall_phase_two_timing_multiplier
	)


func _run_wall_event(event: int) -> void:
	var timing := _get_wall_timing_multiplier()
	match event:
		HangingEvent.AIMED_LASER:
			_laser_aim_offset = _take_next_laser_aim_offset()
			await _track_hanging_laser(laser_tracking_time * timing)
			await _lock_hanging_laser(laser_lock_time * timing)
			await _fire_hanging_laser(laser_fire_time)
		HangingEvent.LASER_SWEEP:
			await _fire_hanging_laser_sweep(
				bool(randi() % 2),
				phase_two_sweep_lock_time * timing,
				phase_two_sweep_time * timing
			)
		HangingEvent.RED_VOLLEY:
			_spawn_threadburst_missiles()
			await _wait_with_wall_cancel(0.72 * timing)
		HangingEvent.YELLOW_ECHO:
			_spawn_wall_essence_echo()
			await _wait_with_wall_cancel(0.95 * timing)
		HangingEvent.BLUE_WALL_SHEAR:
			_spawn_blue_wall_shear()
			await _wait_with_wall_cancel(0.72 * timing)


func _wait_with_wall_cancel(duration: float) -> void:
	var timer := 0.0
	while (
		timer < duration
		and is_inside_tree()
		and not is_dead
		and not _wall_break_requested
	):
		await get_tree().process_frame
		timer += get_process_delta_time()


func _spawn_wall_essence_echo() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		player = target
	if not is_instance_valid(player):
		return
	var parent := get_parent()
	if not parent:
		return
	var attack_direction := signi(roundi(player.global_position.x - global_position.x))
	if attack_direction == 0:
		attack_direction = -_wall_side if _wall_side != 0 else facing
	var echo := ProtoWeaverEssenceEchoVFX.new()
	echo.echo_delay = essence_echo_delay
	var echo_scale := _get_scale_for_sheet(stab_texture, attack_columns, attack_rows)
	var echo_origin := player.global_position - Vector2(float(attack_direction) * 210.0, 0.0)
	echo.configure(
		self,
		player.global_position + Vector2(float(attack_direction) * 130.0, 0.0),
		attack_direction,
		stab_texture,
		attack_columns,
		attack_rows,
		essence_echo_telegraph_hold_frame,
		echo_scale,
		_base_sprite_position,
		stats.attack_damage if stats else 24,
		maxf(0.35, essence_echo_delay)
	)
	parent.add_child(echo)
	echo.global_position = echo_origin
	echo.mark_arrival()
	echo.trigger_echo()


func _spawn_blue_wall_shear() -> void:
	if _wall_side == 0:
		return
	var parent := get_parent()
	if not parent:
		return
	var wave := ProtoWeaverGroundWave.new()
	wave.damage_amount = ground_sweep_damage
	wave.travel_speed = wall_blue_wave_speed
	wave.lifetime = wall_blue_wave_lifetime
	parent.add_child(wave)
	wave.global_position = _hang_anchor + Vector2(
		-float(_wall_side) * wall_blue_wave_surface_offset,
		72.0
	)
	wave.launch_surface(Vector2.DOWN, _wall_side, self)


func _run_aimed_laser_volley(shot_count: int, timing_multiplier: float) -> void:
	for shot in range(maxi(0, shot_count)):
		if _is_wall_event_cancelled():
			return
		_laser_aim_offset = _take_next_laser_aim_offset()
		await _track_hanging_laser(laser_tracking_time * timing_multiplier)
		await _lock_hanging_laser(laser_lock_time * timing_multiplier)
		await _fire_hanging_laser(laser_fire_time)
		if not is_inside_tree() or is_dead:
			return
		if shot < shot_count - 1 and phase_intershot_delay > 0.0:
			await get_tree().create_timer(phase_intershot_delay).timeout


func _run_final_hanging_laser_mix() -> void:
	var events := _build_final_laser_events()
	var reverse_sweep := bool(randi() % 2)
	for event_index in range(events.size()):
		if _is_wall_event_cancelled():
			return
		if events[event_index]:
			_laser_aim_offset = 0.0
			await _fire_hanging_laser_sweep(
				reverse_sweep,
				phase_two_sweep_lock_time,
				phase_two_sweep_time
			)
			reverse_sweep = not reverse_sweep
		else:
			_laser_aim_offset = _take_next_laser_aim_offset()
			await _track_hanging_laser(laser_tracking_time * phase_three_timing_multiplier)
			await _lock_hanging_laser(laser_lock_time * phase_three_timing_multiplier)
			await _fire_hanging_laser(laser_fire_time)
		if not is_inside_tree() or is_dead:
			return
		if event_index < events.size() - 1 and phase_intershot_delay > 0.0:
			await get_tree().create_timer(phase_intershot_delay).timeout


func _build_final_laser_events() -> Array[bool]:
	var event_count := maxi(1, phase_three_laser_event_count)
	var sweep_count := clampi(phase_three_sweep_count, 0, maxi(0, event_count - 1))
	var aimed_count := event_count - sweep_count
	var available_gaps: Array[int] = []
	for gap in range(aimed_count + 1):
		available_gaps.append(gap)
	available_gaps.shuffle()
	var sweep_gaps: Array[int] = available_gaps.slice(0, sweep_count)
	var events: Array[bool] = []
	for gap in range(aimed_count + 1):
		if gap in sweep_gaps:
			events.append(true)
		if gap < aimed_count:
			events.append(false)
	return events


func _take_next_laser_aim_offset() -> float:
	if _laser_pattern_bag.is_empty():
		_laser_pattern_bag = [-laser_aim_offset, 0.0, laser_aim_offset]
		_laser_pattern_bag.shuffle()
		if _laser_pattern_bag.size() > 1 and is_equal_approx(_laser_pattern_bag.back(), _last_laser_aim_offset):
			var swap_value := _laser_pattern_bag[0]
			_laser_pattern_bag[0] = _laser_pattern_bag.back()
			_laser_pattern_bag[_laser_pattern_bag.size() - 1] = swap_value
	_last_laser_aim_offset = _laser_pattern_bag.pop_back()
	return _last_laser_aim_offset

func _track_hanging_laser(duration: float) -> void:
	if laser_beam:
		laser_beam.show_tracking()
	var timer := 0.0
	while timer < duration and is_inside_tree() and not is_dead and not _is_wall_event_cancelled():
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
	while timer < duration and is_inside_tree() and not is_dead and not _is_wall_event_cancelled():
		await get_tree().process_frame
		timer += get_process_delta_time()

func _fire_hanging_laser(duration: float) -> void:
	if _is_wall_event_cancelled():
		return
	_laser_firing = true
	_laser_hit_this_shot = false
	_play_boss_sfx(&"enemy_laser_attack", boss_laser_pitch)
	if laser_beam:
		laser_beam.show_firing()
		_update_laser_line()

	var timer := 0.0
	while timer < duration and is_inside_tree() and not is_dead and not _is_wall_event_cancelled():
		_try_damage_player_with_laser()
		await get_tree().process_frame
		timer += get_process_delta_time()

	_laser_firing = false
	if laser_beam:
		laser_beam.hide_beam()


func _fire_hanging_laser_sweep(reverse: bool, lock_duration: float, sweep_duration: float) -> void:
	if _is_wall_event_cancelled():
		return
	var sweep_y := _hang_origin.y - 52.0
	var left_target := Vector2(_get_hang_arena_left() - 70.0, sweep_y)
	var right_target := Vector2(_get_hang_arena_right() + 70.0, sweep_y)
	var start_target := right_target if reverse else left_target
	var end_target := left_target if reverse else right_target

	_laser_target_position = start_target
	_laser_firing = false
	_laser_hit_this_shot = false
	if laser_beam:
		laser_beam.show_tracking()
		_update_laser_line()
	await _wait_with_laser_presented(lock_duration * 0.45)
	if not is_inside_tree() or is_dead or _is_wall_event_cancelled():
		return
	if laser_beam:
		laser_beam.show_locked()
		_update_laser_line()
	await _wait_with_laser_presented(lock_duration * 0.55)
	if not is_inside_tree() or is_dead or _is_wall_event_cancelled():
		return

	_laser_firing = true
	_laser_hit_this_shot = false
	_play_boss_sfx(&"enemy_laser_attack", boss_laser_pitch * (1.08 if reverse else 0.94))
	if laser_beam:
		laser_beam.show_firing()

	var timer := 0.0
	while timer < sweep_duration and is_inside_tree() and not is_dead and not _is_wall_event_cancelled():
		var ratio := clampf(timer / maxf(sweep_duration, 0.001), 0.0, 1.0)
		_laser_target_position = start_target.lerp(end_target, smoothstep(0.0, 1.0, ratio))
		_update_laser_line()
		_try_damage_player_with_laser()
		await get_tree().process_frame
		timer += get_process_delta_time()

	_laser_firing = false
	if laser_beam:
		laser_beam.hide_beam()


func _wait_with_laser_presented(duration: float) -> void:
	var timer := 0.0
	while timer < duration and is_inside_tree() and not is_dead and not _is_wall_event_cancelled():
		_update_laser_line()
		await get_tree().process_frame
		timer += get_process_delta_time()


func _run_laser_recharge(duration_override := -1.0) -> void:
	var recharge_duration := duration_override if duration_override >= 0.0 else phase_landing_punish_time
	if recharge_duration <= 0.0 or not sprite:
		return
	_laser_recharge_active = true
	_hanging_laser_landing = false
	_configure_sprite_sheet(threadburst_texture, attack_columns, attack_rows)
	_set_sprite_cleanup_enabled(true)
	sprite.frame = clampi(stagger_pose_frame, 0, max(0, attack_columns * attack_rows - 1))
	sprite.position = _base_sprite_position + Vector2(0.0, 24.0)
	sprite.rotation = -float(facing) * 0.045
	sprite.scale = Vector2(_configured_sprite_scale.x * 1.06, _configured_sprite_scale.y * 0.9)

	var timer := 0.0
	while timer < recharge_duration and is_inside_tree() and not is_dead:
		var ratio := clampf(timer / maxf(recharge_duration, 0.001), 0.0, 1.0)
		var pulse := 0.5 + sin(timer * 15.0) * 0.5
		sprite.modulate = Color(1.0, lerpf(0.58, 0.96, ratio), lerpf(0.38, 0.88, ratio), 0.82 + pulse * 0.18)
		await get_tree().process_frame
		timer += get_process_delta_time()

	_laser_recharge_active = false
	if sprite:
		sprite.modulate = Color.WHITE
		_reset_sprite_attack_pose()

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
	_hide_attack_aura()
	_laser_recharge_active = false
	_hanging_laser_busy = false
	_hanging_laser_active = false
	_hanging_laser_landing = false
	_laser_firing = false
	_wall_hanging = false
	_wall_break_requested = false
	_wall_broken_by_player = false
	_wall_break_damage = 0.0
	_wall_phase_elapsed = 0.0
	_wall_event_bag.clear()
	_hang_rotation = 0.0
	_wall_side = 0
	global_position = _hang_origin if _hang_origin != Vector2.ZERO else global_position
	if hanging_thread_line:
		hanging_thread_line.visible = false
	if detached_head:
		detached_head.visible = false
	if laser_beam:
		laser_beam.hide_beam()
	_apply_wall_collision_rotation(0.0)
	if visuals:
		visuals.position = _base_visuals_position
		visuals.rotation = _base_visuals_rotation
	if sprite and walk_texture:
		sprite.modulate = Color.WHITE
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
		visuals.position = (
			_base_visuals_position + Vector2(0.0, sway)
			if _wall_hanging
			else _base_visuals_position + Vector2(sway, 0.0)
		)

	_update_hanging_thread_line()
	_update_detached_head()
	if laser_beam and laser_beam.is_presenting():
		_update_laser_line()

func _update_hanging_thread_line() -> void:
	if not hanging_thread_line:
		return

	var visual_offset := visuals.position - _base_visuals_position if visuals else Vector2.ZERO
	var body_attach := _get_hanging_body_attach(global_position) + visual_offset
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
		_laser_target_position = player_node.global_position + Vector2(_laser_aim_offset, -42.0)
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
	if _wall_hanging and not _laser_recharge_active:
		boss_health_bar.set_stagger(
			_wall_break_damage,
			_get_wall_break_damage_threshold(),
			0.0,
			wall_knockdown_duration
		)
	else:
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
